using DrWatson
using Pkg
const ds = DrWatson
using Test
using FileIO
using Dates

include("helper_functions.jl")

@testset "Metadata and Simulation" begin
    @testset "Metadata" begin
        @eval ds max_lock_retries = 10

        dummy_project() do folder
            @testset "Locking functions" begin 
                @test_logs (:info, r"creating") ds.assert_metadata_directory()
                # Check if index file was created
                ds.iolock("metadata")
                @test isdir(ds.metadatadir("metadata.lck"))
                ds.iolock("foo")
                @test isdir(ds.metadatadir("foo.lck"))
                @test_throws ErrorException ds.iolock("foo")
                ds.iounlock("foo")
                ds.iolock("foo")
                ds.iounlock("foo")
                @test_throws ErrorException ds.iolock("metadata")
                @test_throws ErrorException ds.iolock("metadata")
                ds.iounlock("metadata")
                @test_throws ErrorException ds.iounlock("metadata")
                ds.iolock("metadata")
                ds.iounlock("metadata")
                @test ds.semaphore_status("bar") == 0
                ds.semaphore_enter("bar")
                @test isfile(ds.metadatadir("bar.sem"))
                ds.semaphore_enter("bar")
                ds.semaphore_enter("bar")
                @test ds.semaphore_status("bar") == 3
                ds.semaphore_exit("bar")
                @test ds.semaphore_status("bar") == 2
                ds.semaphore_exit("bar")
                @test ds.semaphore_status("bar") == 1
                ds.semaphore_exit("bar")
                @test ds.semaphore_status("bar") == 0
                @test !isfile(ds.metadatadir("bar.sem"))
                @test_throws ErrorException ds.semaphore_exit("bar")
                function sem_test()
                    function blocked_worker(v)
                        ds.iolock("foo", wait_for_semaphore="bar")
                        v[1]=1
                        ds.iounlock("foo")
                    end
                    v = [0]
                    ds.semaphore_enter("bar")
                    @async blocked_worker(v)
                    @test v[1] == 0
                    ds.semaphore_enter("bar")
                    @test v[1] == 0
                    ds.semaphore_exit("bar")
                    ds.semaphore_exit("bar")
                    yield()
                    @test v[1] == 1
                end
                @sync sem_test()
            end
        end

        dummy_project() do folder
            @testset "Identifer Creation" begin
                ds.assert_metadata_directory()
                @test ds.hash_path(datadir("sims","a.jld2")) == hash("data/sims/a.jld2")
            end
        end

        dummy_project() do folder
            @testset "Metadata creation" begin
                m = Metadata(datadir("fileA"))
                @test m.path == datadir("fileA")
                @test isfile(ds.metadatadir(ds.hash_path(m.path)|>ds.to_file_name))
                mb = Metadata(datadir("fileB"))
                @test isfile(ds.metadatadir(ds.hash_path(mb.path)|>ds.to_file_name))
                @test m.mtime == 0
                touch(datadir("fileA"))
                @test_logs (:warn, r"changed") Metadata(datadir("fileA"))
                @test_nowarn m = Metadata!(datadir("fileA"))
                @test m.mtime > 0
                A = rand(3,3)
                m["some_data"] = A
                raw_loaded = load(ds.metadatadir(ds.to_file_name(ds.hash_path(m.path))))
                @test raw_loaded["data"]["some_data"] == A
                ds.rename!(m, datadir("fileC"))
                @test "some_data" in keys(Metadata(datadir("fileC")))
            end
        end

        dummy_project() do folder
            @testset "Metadata Pentest" begin
                ds.assert_metadata_directory()
                @sync for i in 1:500
                    @async begin
                        m = Metadata(datadir("file$i"))
                        s = rand(1:100)
                        m["data"] = rand(s,s)
                        for j in 1:10
                            ds.rename!(m, datadir("file$(i)_$j"))
                        end
                    end
                end
                index = filter(x->endswith(x,".jld2"),readdir(ds.metadatadir()))
                @test length(index) == 500
                files = Set{String}()
                for f in index
                    d = load(ds.metadatadir(f))
                    @test endswith(d["path"],"_10")
                    push!(files,d["path"])
                end
                @test length(files) == 500
            end
        end

    end
    @testset "Simulation" begin
        @eval ds max_lock_retries = 10000

        dummy_project() do folder
            @testset "id generation" begin
                mkdir(datadir("sims2"))
                @test ds.get_next_simulation_id(datadir("sims")) == 1
                @test ds.get_next_simulation_id(datadir("sims2")) == 1
                @test ds.get_next_simulation_id(datadir("sims2")) == 2
                rm(datadir("sims2","1"))
                @test ds.get_next_simulation_id(datadir("sims2")) == 1
                for i in 1:10
                    @test ds.get_next_simulation_id(datadir("sims")) == 1+i
                end
                for i in 1:10
                    rm(datadir("sims","$i"))
                end
                @test ds.get_next_simulation_id(datadir("sims")) == 1
            end
        end

        dummy_project() do folder
            @testset "long running computation" begin
                Pkg.develop(PackageSpec(url=joinpath(@__DIR__,"..")))
                pkg"add JLD2"
                pkg"add Dates"
                file = scriptsdir("long_running_script.jl")
                cp(joinpath(@__DIR__, "long_running_script.jl"), file)
                run(`julia $file`)
                for i in 1:4
                    folder = datadir("sims","$i")
                    file = datadir("sims","$i","output.jld2")
                    @test isfile(file)
                    result = load(file)["result"]
                    m = Metadata(folder)
                    p = m["parameters"]
                    @test p[:a]^p[:b] == result
                    @test m["type"] == "Simple Computation"
                    @test m["started at"] < now()
                    m_new = Metadata(joinpath(folder,"newfile"))
                    @test m_new["extra"] == "This should be blocked"
                    @test m["simulation_submit_group"] == ["data/sims/$j" for j in 1:4]
                end
            end
        end

        dummy_project() do folder
            @testset "Rerun simulation" begin
                Pkg.develop(PackageSpec(url=joinpath(@__DIR__,"..")))
                pkg"add JLD2"
                pkg"add Dates"
                file = scriptsdir("long_re_running_script.jl")
                cp(joinpath(@__DIR__, "long_re_running_script.jl"), file)
                run(`julia $file`)
                for i in 1:4
                    folder = datadir("sims","$i")
                    fileA = datadir("sims","$i","output.jld2")
                    fileB = datadir("sims","$i","output_first_run.jld2")
                    resultA = load(fileA)["result"]
                    resultB = load(fileB)["result"]
                    @test resultA == resultB
                end
            end
        end
    end

    @testset "Searching" begin
        dummy_project() do folder
            @testset "get by path" begin
                ds.assert_metadata_directory()
                m = Metadata(datadir("sims","1"))
                m["Foo"] = "Bar"
                m2 = get_metadata(datadir("sims","1","111"))
                @test m2["Foo"] == m["Foo"]
                @test get_metadata(datadir("sims","1","111"),include_parents=false) === nothing
                m = Metadata(datadir("sims","2"))
                m["Foo"] = "Baz"
                @test length(get_metadata()) == 2
                @test length(get_metadata("Foo","Baz")) == 1
                @test get_metadata("Foo","Baz")[1].path == m.path
            end
        end
    end

end
