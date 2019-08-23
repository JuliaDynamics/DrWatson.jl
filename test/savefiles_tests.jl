using DrWatson, Test
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
t = f(simulation)
tagsave(savename(simulation, "bson"), t, findproject())
file = load(savename(simulation, "bson"))
@test "commit" ∈ keys(file)
@test file["commit"] |> typeof == String
rm(savename(simulation, "bson"))

t = f(simulation)
@tagsave(savename(simulation, "bson"), t, false, findproject())
file = load(savename(simulation, "bson"))
@test "commit" ∈ keys(file)
@test file["commit"] |> typeof == String
@test "script" ∈ keys(file)
@test file["script"] |> typeof == String
@test file["script"] == joinpath("test", "savefiles_tests.jl#29")

t = f(simulation)
@tagsave(savename(simulation, "bson"), t, true, findproject())
sn = savename(simulation, "bson")[1:end-5]*"_#1"*".bson"
@test isfile(sn)
rm(savename(simulation, "bson"))
rm(sn)
@test !isfile(savename(simulation, "bson"))

################################################################################
#                              produce or load                                 #
################################################################################
for ending ∈ ("bson", "jld2")
    @test !isfile(savename(simulation, ending))
    sim, path = produce_or_load(simulation, f; suffix = ending)
    @test isfile(savename(simulation, ending))
    @test sim["simulation"].T == T
    @test path == savename(simulation, ending)
    sim, path = produce_or_load(simulation, f; suffix = ending)
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

@test produce_or_load(simulation, f; loadfile = false)[1] == nothing
rm(savename(simulation, "bson"))
@test !isfile(savename(simulation, "bson"))

################################################################################
#                          Backup files before saving                          #
################################################################################
filepath = "test.#backup.jld2"
data = [Dict( "a" => i, "b" => rand(rand(1:10))) for i = 1:3]
for i = 1:3
    safesave(filepath, data[i])
    @test data[i] == load(filepath)
end
@test data[2] == load("test.#backup_#1.jld2")
@test data[1] == load("test.#backup_#2.jld2")
@test data[3] == load("test.#backup.jld2")
rm("test.#backup.jld2")
rm("test.#backup_#1.jld2")
rm("test.#backup_#2.jld2")
