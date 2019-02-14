using DrWatson, Test

@testset "Naming" begin include("naming_tests.jl"); end
@testset "Project Setup" begin include("project_tests.jl"); end
