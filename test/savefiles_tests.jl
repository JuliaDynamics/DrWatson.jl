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
    @test typeof(simulation.T) <: Real
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
    @tagsave(savename(simulation, ending), t, safe=false, gitpath=findproject())
    file = load(savename(simulation, ending))
    @test "gitcommit" ∈ keys(file)
    @test file["gitcommit"] |> typeof == String
    @test "script" ∈ keys(file)
    @test file["script"] |> typeof == String
    @test file["script"] == joinpath("test", "savefiles_tests.jl#30")

    t = f(simulation)
    @tagsave(savename(simulation, ending), t, safe=true, gitpath=findproject())
    sn = savename(simulation, ending)[1:end-5]*"_#1"*"."*ending
    @test isfile(sn)
    rm(sn)

    t = f(simulation)
    tagsave(savename(simulation, ending), t, safe=true, gitpath=findproject())
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

    ex = @macroexpand @tagsave("testname."*ending, (@dict a b c ), storepatch=false; safe=true)
    ex2 = @macroexpand @tagsave("testname."*ending, @dict a b c; storepatch=false, safe=true)
    @test ex.args[1:end-1] == ex2.args[1:end-1]

    # Remove leftover
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
    @test !isfile(savename(simulation, ending))
    sim, path = produce_or_load(simulation, f; suffix = ending)
    @test isfile(savename(simulation, ending))
    @test sim["simulation"].T == T
    @test path == savename(simulation, ending)
    sim, path = produce_or_load(simulation, f; suffix = ending)
    @test sim["simulation"].T == T
    rm(savename(simulation, ending))
    @test !isfile(savename(simulation, ending))

    @test !isfile(savename(simulation, ending))
    sim, path = produce_or_load("", simulation; suffix = ending) do simulation
        @test typeof(simulation.T) <: Real
        a = rand(10); b = [rand(10) for _ in 1:10]
        return @strdict a b simulation
    end
    @test isfile(savename(simulation, ending))
    @test sim["simulation"].T == T
    @test path == savename(simulation, ending)
    sim, path = produce_or_load("", simulation; suffix = ending) do simulation
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
end

@test produce_or_load(simulation, f; loadfile = false)[1] == nothing
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
