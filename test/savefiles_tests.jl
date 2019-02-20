using FileIO, JLD2

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

@test !isfile(savename(simulation, "jld2"))

sim = produce_or_load(simulation, f)

@test isfile(savename(simulation, "jld2"))
@test sim["simulation"].T == T

sim = produce_or_load(simulation, f)
@test sim["simulation"].T == T

rm(savename(simulation, "jld2"))

@test !isfile(savename(simulation, "jld2"))
