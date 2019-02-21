using DrWatson, Test

@testset "Naming" begin include("naming_tests.jl"); end
@testset "Project Setup" begin include("project_tests.jl"); end
@testset "Saving tools" begin include("stools_tests.jl"); end
@testset "Produce or Save" begin include("savefiles_tests.jl"); end
