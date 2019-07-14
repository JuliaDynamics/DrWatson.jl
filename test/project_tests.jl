using Test, DrWatson

cd()
path = "test project"
name = "lala"

initialize_project(path, force = true)

@test projectname() == path
@test typeof(findproject(@__DIR__)) == String
for p in DrWatson.DEFAULT_PATHS
    @test ispath(joinpath(path, p))
end

@test ispath(projectdir("data"))
@test isfile(joinpath(path, ".gitignore"))
@test isfile(joinpath(path, "README.md"))
@test isfile(joinpath(path, "Project.toml"))

for dir_type in ("data", "src", "plots", "papers", "test", "scripts")
    fn = Symbol(dir_type * "dir")
    @eval begin
        @test $fn() == projectdir() * $dir_type * "/"
        @test endswith($fn("a"), $dir_type * ("/a/"))
        @test endswith($fn("a/b"), $dir_type * "/a/b/")
        @test endswith($fn("a", "b"), $dir_type * "/a/b/")
        @test endswith($fn("a", "b", "c/d"), $dir_type * "/a/b/c/d/")
    end
end

# backward compatibility (scriptdir == scriptsdir)
@test scriptdir() == projectdir() * "scripts/"
@test scriptdir("a") == projectdir() * "scripts/a/"
@test scriptdir("a/b") == projectdir() * "scripts/a/b/"
@test scriptdir("a", "b") == projectdir() * "scripts/a/b/"
@test scriptdir("a", "b", "c/d") == projectdir() * "scripts/a/b/c/d/"

@test_throws ErrorException initialize_project(path, name)

initialize_project(path, name; force = true, authors = ["George", "Nick"])

@test projectname() == name
for p in DrWatson.DEFAULT_PATHS
    @test ispath(joinpath(path, p))
end
@test isfile(joinpath(path, ".gitignore"))
@test isfile(joinpath(path, "README.md"))
@test isfile(joinpath(path, "Project.toml"))
z = read((path*"/Project.toml"), String)
@test occursin("[\"George\", \"Nick\"]", z)

initialize_project(path, name; force = true, authors = "Sophia", git = false)
@test !isdir(joinpath(path, ".git"))
z = read((path*"/Project.toml"), String)
@test occursin("[\"Sophia\"]", z)

cd(path)
@test findproject(pwd()) == pwd()
cd()

rm(path, recursive = true, force = true)
@test !isdir(path)
