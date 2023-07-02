using DrWatson, Test
using BSON, JLD2
cd(@__DIR__)
T = 1000
N = 50 # spatial extent
Δt = 0.05 # resolution of integration
every = 10
seed = 1111

simulation = @ntuple T N Δt every seed

function f(simulation)
    a = rand(10); b = [rand(10) for _ in 1:10]
    return @strdict a b simulation
end

################################################################################
#                                 tagsave                                      #
################################################################################
@testset "Tagsafe ($ending)" for ending ∈ ["bson", "jld2"]
    t = f(simulation)
    tagsave(savename(simulation, ending), t, gitpath=findproject())
    file = load(savename(simulation, ending))
    @test "gitcommit" ∈ keys(file)
    @test file["gitcommit"] |> typeof == String
    rm(savename(simulation, ending))

    t = f(simulation)
    @tagsave(savename(simulation, ending), t; safe=false, gitpath=findproject())
    file = load(savename(simulation, ending))
    @test "gitcommit" ∈ keys(file)
    @test file["gitcommit"] |> typeof == String
    @test "script" ∈ keys(file)
    @test file["script"] |> typeof == String
    @test file["script"] == joinpath("test", "savefiles_tests.jl#29")

    t = f(simulation)
    @tagsave(savename(simulation, ending), t; safe=true, gitpath=findproject())
    sn = savename(simulation, ending)[1:end-5]*"_#1"*"."*ending
    @test isfile(sn)
    rm(sn)

    t = f(simulation)
    tagsave(savename(simulation, ending), t; safe=true, gitpath=findproject())
    sn = savename(simulation, ending)[1:end-5]*"_#1"*"."*ending
    @test isfile(sn)
    rm(sn)

    t = f(simulation)
    t["gitcommit"] = ""
    @test @tagsave(savename(simulation, ending), t, safe=true, gitpath=findproject())["gitcommit"] == ""
    @test isfile(sn)
    rm(sn)
    @test @tagsave(savename(simulation,ending), t, safe=true, force=true, gitpath=findproject())["gitcommit"] != ""
    @test isfile(sn)
    rm(sn)

    rm(savename(simulation, ending))
    @test !isfile(savename(simulation, ending))
end

# Check if kwargs propagation works using the example of compression in JLD2.
# We need to look at the actual file sizes - JLD2 handles compression transparently
# and doesn't provide a way to check if a read dataset was compressed.
# Run twice - once without the `safe` option and once with, to implicitly test `safesave`.
@testset "Tagsafe with compression (safe=$safesave)" for safesave ∈ [false, true]
    # Create some highly compressible data
    data = Dict("data" => fill(1, 10000))
    sn_uncomp = "uncompressed.jld2"
    sn_comp = "compressed.jld2"
    # Save twice - once uncompressed and once compressed
    tagsave(sn_uncomp, data, safe=safesave, gitpath=findproject(), compress=false)
    tagsave(sn_comp, data, safe=safesave, gitpath=findproject(), compress=true)
    # Check if both files exist
    @test isfile(sn_uncomp)
    @test isfile(sn_comp)
    # Test if the compressed file is smaller
    size_uncomp = filesize(sn_uncomp)
    size_comp = filesize(sn_comp)
    @test size_uncomp > size_comp
    # Leave no trace
    rm(sn_uncomp)
    rm(sn_comp)
end

################################################################################
#                              produce or load                                 #
################################################################################

@testset "Produce or Load ($ending)" for ending ∈ ["bson", "jld2"]
    gitpath = findproject()
    sim, path = produce_or_load(f, simulation, ""; suffix = ending, gitpath = gitpath)
    @test isfile(savename(simulation, ending))
    @test "gitcommit" ∈ keys(sim)
    @test sim["simulation"].T == T
    @test path == savename(simulation, ending)
    rm(savename(simulation, ending))
    @test !isfile(savename(simulation, ending))

    # Produce and save data, preserve source file name and line for test below.
    # Line needs to be saved on the same line as produce_or_load!
    sim, path = @produce_or_load(f, simulation, ""; suffix = ending, force = true, gitpath = gitpath)
    @test isfile(savename(simulation, ending))
    @test sim["simulation"].T == T
    @test path == savename(simulation, ending)
    @test "script" ∈ keys(sim)
    @test "gitcommit" ∈ keys(sim)
    @test sim["script"] |> typeof == String
    @test endswith(sim["script"], "savefiles_tests.jl#102")
    rm(savename(simulation, ending))
    @test !isfile(savename(simulation, ending))

    # Test without keywords as well.
    sim, path = @produce_or_load(f, simulation, ""; suffix = ending)
    @test isfile(savename(simulation, ending))
    rm(savename(simulation, ending))

    # Test if tag = false does not interfere with macro script tagging.
    sim, = @produce_or_load(f, simulation, ""; tag = false, suffix = ending)
    @test endswith(sim["script"], "savefiles_tests.jl#119")
    @test "gitcommit" ∉ keys(sim)
    rm(savename(simulation, ending))

    # Test that the internal function `scripttag!` properly warns if the Dict already has a `script` key.
    # This also tests the case where the `Dict` has a `Symbol` key type.
    @test_logs((:warn, "The dictionary already has a key named `script`. We won't overwrite it with the script name."),
               DrWatson.scripttag!(Dict(:script => "test"), LineNumberNode(1)))

    @test !isfile(savename(simulation, ending))
    sim, path = produce_or_load(simulation, ""; suffix = ending) do simulation
        @test typeof(simulation.T) <: Real
        a = rand(10); b = [rand(10) for _ in 1:10]
        return @strdict a b simulation
    end
    @test isfile(savename(simulation, ending))
    @test sim["simulation"].T == T
    @test path == savename(simulation, ending)
    sim, path = produce_or_load("", simulation; suffix = ending, force=true) do simulation
        @test typeof(simulation.T) <: Real
        a = rand(10); b = [rand(10) for _ in 1:10]
        return @strdict a b simulation
    end
    @test sim["simulation"].T == T
    rm(savename(simulation, ending))
    @test !isfile(savename(simulation, ending))

    p = String(@__DIR__)
    pre = "pre"
    expected = joinpath(p, savename(pre, simulation, ending))
    @test !isfile(expected)
    sim, path = produce_or_load(p, simulation, f; suffix = ending, prefix = pre)
    @test path == expected
    @test isfile(path)
    rm(path)
end

@testset "Produce or Load with manual filename ($ending)" for ending ∈ ["bson", "jld2"]

    # test with empty `path`
    filename = joinpath(mktempdir(), "out")
    @test !isfile(filename)
    sim, file = @produce_or_load(simulation; filename=filename, suffix=ending) do config
        f(config)
    end
    @test file == filename*'.'*ending
    @test isfile(filename*'.'*ending)
    @test sim["simulation"].T == T
    @test "script" ∈ keys(sim)
    rm(file)

    # test with both `path` and filename
    path = mktempdir()
    filename = joinpath("sub", "out")
    @test !isfile(joinpath(path, filename))
    sim, file = @produce_or_load(path, simulation, filename=filename, suffix=ending) do config
        f(config)
    end
    @test file == joinpath(path, filename*'.'*ending)
    @test isfile(file)
    @test sim["simulation"].T == T
    @test "script" ∈ keys(sim)
    rm(file)

end

@testset "Produce or Load wsave keyword pass through" begin
    # Create some highly compressible data
    data = Dict("data" => fill(1, 10000))

    sn_uncomp = savename(Dict("compress" => false), "jld2")
    sn_comp = savename(Dict("compress" => true), "jld2")
    # Files cannot exist yet
    @test !isfile(sn_uncomp)
    @test !isfile(sn_comp)
    for compress in [false, true]
        wsave_kwargs = Dict(:compress => compress)
        produce_or_load("", wsave_kwargs, suffix = "jld2", wsave_kwargs=wsave_kwargs) do c
            data
        end
    end
    # Check if both files exist now
    @test isfile(sn_uncomp)
    @test isfile(sn_comp)
    # Test if the compressed file is smaller
    size_uncomp = filesize(sn_uncomp)
    size_comp = filesize(sn_comp)
    @test size_uncomp > size_comp
    # Leave no trace
    rm(sn_uncomp)
    rm(sn_comp)

    # Check the macro version
    sn_uncomp = savename(Dict("compress" => false), "jld2")
    sn_comp = savename(Dict("compress" => true), "jld2")
    # Files cannot exist yet
    @test !isfile(sn_uncomp)
    @test !isfile(sn_comp)
    for compress in [false, true]
        wsave_kwargs = Dict(:compress => compress)
        @produce_or_load("", wsave_kwargs, suffix = "jld2", wsave_kwargs=wsave_kwargs) do c
            data
        end
    end
    # Check if both files exist now
    @test isfile(sn_uncomp)
    @test isfile(sn_comp)
    # Test if the compressed file is smaller
    size_uncomp = filesize(sn_uncomp)
    size_comp = filesize(sn_comp)
    @test size_uncomp > size_comp
    # Leave no trace
    rm(sn_uncomp)
    rm(sn_comp)

end

@test produce_or_load(simulation, f; loadfile = false)[1] === nothing
rm(savename(simulation, "jld2"))
@test !isfile(savename(simulation, "jld2"))

using DataFrames
@testset "produce_or_load with dataframe" begin
    function makedf(c)
        a = c[:a]
        return DataFrame(A = a, B = rand(3))
    end
    c = (a = 0.5,)
    _, spath = produce_or_load(c, makedf; suffix = "csv")
    @test isfile(spath)
    df = DataFrame(load(spath))
    @test df.A == [0.5, 0.5, 0.5]
    rm(spath)
    @test !isfile(spath)
end

# Regression test for https://github.com/JuliaDynamics/DrWatson.jl/issues/309
@testset "@produce_or_load with value-type widening" begin
    d, spath = @produce_or_load("", Dict("a" => 5.0)) do config
        return Dict("field" => config)
    end
    @test haskey(d, "script")
    rm(spath)
end

@testset "produce_or_load with objectid" begin
    using Random
    path = mktempdir()
    function sim_with_f(config)
        @unpack x, f = config
        r = f(x)
        return @dict(r)
    end

    f1(x) = sum(cos.(x))
    f2(x) = maximum(abs.(x))
    # rng = Random.MersenneTwister(1234)

    configs = Dict(
        "x" => [rand(Random.MersenneTwister(1234), 1000),
                randn(Random.MersenneTwister(1234), 50)],
        # :f => [x -> sum(cos.(x)), x -> maximum(abs.(x))],
        "f" => [f1, f2],
    )
    configs = dict_list(configs)
    pol_kwargs = (prefix = "sims_with_f", verbose = false, tag = false)

    # Test that we get 4 unique files
    for config in configs
        produce_or_load(sim_with_f, config, path; filename = hash, pol_kwargs...)
    end
    o = readdir(path)
    @test length(o) == 4
    # Test tat we if we change the numbers in the vector we have one more file
    config = Dict("x" => rand(Random.MersenneTwister(4321), 1000), "f" => f1)
    produce_or_load(sim_with_f, config, path; filename = hash, pol_kwargs...)
    @test length(readdir(path)) == 5
    # Test that if we do not change the numbers in the vector we do not get
    # a new file
    config = Dict("x" => rand(Random.MersenneTwister(1234), 1000), "f" => f1)
    produce_or_load(sim_with_f, config, path; filename = hash, pol_kwargs...)
    @test length(readdir(path)) == 5
    # also test that hash wouldn't work with anonymous functions that do the same
    config = Dict("x" => rand(Random.MersenneTwister(1234), 1000), "f" => x -> sum(cos.(x)))
    produce_or_load(sim_with_f, config, path; filename = hash, pol_kwargs...)
    @test length(readdir(path)) == 6

    rm(path; recursive = true, force = true)
end

# Testing proper filenames when default_prefix was modified. See https://github.com/JuliaDynamics/DrWatson.jl/issues/392
@testset "@produce_or_load with default_prefix modified" begin
    path = mktempdir()

    struct Dummy
        x
        y
    end
    simulation = Dummy(1,2)
    DrWatson.default_prefix(d::Dummy) = "Prefix_"

    sim, path = produce_or_load(f, simulation, "")
    @test path == savename(simulation, "jld2")
    
    rm(path)
    DrWatson.default_prefix(ntuple::NamedTuple) = ""
end


################################################################################
#                          Backup files before saving                          #
################################################################################

@testset "Backup ($ending)" for ending ∈ ["bson", "jld2"]
    filepath = "test.#backup."*ending
    data = [Dict( "a" => i, "b" => rand(rand(1:10))) for i = 1:3]
    for i = 1:3
        safesave(filepath, data[i])
        @test data[i] == load(filepath)
    end
    @test data[2] == load("test.#backup_#1."*ending)
    @test data[1] == load("test.#backup_#2."*ending)
    @test data[3] == load("test.#backup."*ending)
    rm("test.#backup."*ending)
    rm("test.#backup_#1."*ending)
    rm("test.#backup_#2."*ending)
end

@testset "Backup (dir)" begin
    # Save contents as individual file(s) within a parent directory:
    struct Composite x end
    DrWatson._wsave(dir, data::Composite) = wsave(joinpath(dir, "x.jld2"), data.x)
    load_composite(dir) = load(joinpath(dir, "x.jld2"))

    filepath = "test.#backup.dir"
    data = [Composite(Dict( "a" => i, "b" => rand(rand(1:10)))) for i = 1:3]
    for i = 1:3
        safesave(filepath, data[i])
        @test isdir(filepath)
        @test data[i].x == load_composite(filepath)
    end
    @test data[2].x == load_composite("test.#backup_#1.dir")
    @test data[1].x == load_composite("test.#backup_#2.dir")
    @test data[3].x == load_composite("test.#backup.dir")
    rm("test.#backup.dir"; recursive=true)
    rm("test.#backup_#1.dir"; recursive=true)
    rm("test.#backup_#2.dir"; recursive=true)
end
