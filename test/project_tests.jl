using Pkg, Test, DrWatson

cd()
path = "test project"
name = "lala"

Pkg.activate()
@show Base.active_project()
@show Base.load_path_expand("@v$(VERSION.major).$(VERSION.minor)")
# @test DrWatson.is_standard_julia_project() # we cant test this on CI

initialize_project(path, force = true)

@test !DrWatson.is_standard_julia_project()

@test projectname() == path
@test typeof(findproject(@__DIR__)) == String
for p in DrWatson.DEFAULT_PATHS
    @test ispath(joinpath(path, p))
end

@test ispath(projectdir("data"))
@test isfile(joinpath(path, ".gitignore"))
@test isfile(joinpath(path, "README.md"))
@test isfile(joinpath(path, "Project.toml"))

for dir_type in ("data", "src", "plots", "papers", "scripts")
    fn = Symbol(dir_type * "dir")
    @eval begin
        @test $fn() == joinpath(projectdir(), $dir_type)
        @test endswith($fn("a"), joinpath($dir_type, "a"))
        @test endswith($fn(joinpath("a", "b")), joinpath($dir_type, joinpath("a", "b")))
        @test endswith($fn("a", "b"), joinpath($dir_type, joinpath("a", "b")))
        @test endswith($fn("a", "b", joinpath("c", "d")), joinpath($dir_type, joinpath("a", "b", "c", "d")))
    end
end

@test_throws ErrorException initialize_project(path, name)

initialize_project(path, name; force = true, authors = ["George", "Nick"])
# test gitdescribe:
com = gitdescribe(path)
@test !occursin('-', com) # no dashes = no git describe

@test projectname() == name
for p in DrWatson.DEFAULT_PATHS
    @test ispath(joinpath(path, p))
end
@test isfile(joinpath(path, ".gitignore"))
@test isfile(joinpath(path, "README.md"))
@test isfile(joinpath(path, "Project.toml"))
z = read(joinpath(path, "Project.toml"), String)
@test occursin("[\"George\", \"Nick\"]", z)

initialize_project(path, name; force = true, authors = "Sophia", git = false)
@test !isdir(joinpath(path, ".git"))
z = read(joinpath(path, "Project.toml"), String)
@test occursin("[\"Sophia\"]", z)

cd(path)
@test findproject(pwd()) == pwd()
cd()

rm(path, recursive = true, force = true)
@test !isdir(path)
