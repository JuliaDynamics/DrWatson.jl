using DrWatson, Test

using LibGit2
LibGit2.default_signature() = LibGit2.Signature("TEST", "TEST@TEST.COM", round(time(), 0), 0)

@testset "DrWatson" begin
    @testset "Naming" begin include("naming_tests.jl"); end
    @testset "Parse savename" begin include("parse_tests.jl"); end
    @testset "Project Setup" begin include("project_tests.jl"); end
    @testset "Saving tools" begin include("stools_tests.jl"); end
    @testset "Produce or Save" begin include("savefiles_tests.jl"); end
    @testset "Collect Results" begin include("update_results_tests.jl"); end
    @testset "Parameter Customization" begin include("customize_savename.jl"); end
end
