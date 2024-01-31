using Pkg, Test, DrWatson
using LibGit2
LibGit2.default_signature() = LibGit2.Signature("TEST", "TEST@TEST.COM", round(time(), 0), 0)
global_user_name = LibGit2.getconfig("user.name", "")
global_user_email = LibGit2.getconfig("user.email", "")

cd(@__DIR__)
path = "test_project"
name = "lala"

Pkg.activate()
@show Base.active_project()
@show Base.load_path_expand("@v$(VERSION.major).$(VERSION.minor)")
# @test DrWatson.is_standard_julia_project() # we cant test this on CI

initialize_project(path; force = true)
repo = LibGit2.GitRepo(path)
@test LibGit2.getconfig(repo, "user.name", "") == global_user_name
@test LibGit2.getconfig(repo, "user.email", "") == global_user_email

cd(path) do
    @test DrWatson.default_name_from_path(".") == path
end

@test !DrWatson.is_standard_julia_project()

@test projectname() == path
@test typeof(findproject(@__DIR__)) == String
@test ispath(joinpath(path, "src"))
@test ispath(joinpath(path, "data", "exp_raw"))

@test ispath(projectdir("data"))
@test typeof(projectdir("a")) == String
@test isfile(joinpath(path, ".gitignore"))
@test uperm(joinpath(path, ".gitignore")) == 0x06
@test isfile(joinpath(path, "README.md"))
@test isfile(joinpath(path, "Project.toml"))
@test uperm(joinpath(path, "scripts", "intro.jl")) == 0x06

for dir_type in ("data", "src", "plots", "papers", "scripts")
    fn = Symbol(dir_type * "dir")
    @eval begin
        @test $fn() == joinpath(projectdir(), $dir_type)
        @test endswith($fn("a"), joinpath($dir_type, "a"))
        @test endswith($fn(joinpath("a", "b")), joinpath($dir_type, joinpath("a", "b")))
        @test endswith($fn("a", "b"), joinpath($dir_type, joinpath("a", "b")))
        @test endswith($fn("a", "b", joinpath("c", "d")), joinpath($dir_type, joinpath("a", "b", "c", "d")))
        @test typeof($fn("a", "b")) == String
    end
end

@test_throws ErrorException initialize_project(path, name)

initialize_project(path, name; force = true, authors = ["George", "Nick"])
repo = LibGit2.GitRepo(path)
@test LibGit2.getconfig(repo, "user.name", "") == global_user_name
@test LibGit2.getconfig(repo, "user.email", "") == global_user_email
# test gitdescribe:
com = gitdescribe(path)
@test !occursin('-', com) # no dashes = no git describe

@test projectname() == name
@test ispath(joinpath(path, "src"))
@test ispath(joinpath(path, "data", "exp_raw"))
z = read(joinpath(path, "Project.toml"), String)
@test occursin("[\"George\", \"Nick\"]", z)
z = read(joinpath(path, "scripts", "intro.jl"), String)
@test occursin("@quickactivate", z)

initialize_project(path, name; force = true, authors = "Sophia", git = false)
@test !isdir(joinpath(path, ".git"))
z = read(joinpath(path, "Project.toml"), String)
@test occursin("[\"Sophia\"]", z)

# test whether a DrWatson version is added to compat
@test occursin("DrWatson =", z)


# here we test quickactivate
quickactivate(path)
@test projectname() == name

cd(path)
@test findproject(pwd()) == pwd()
cd()

# Test templates
t1 = ["data", "documents" => ["a", "b"]]
initialize_project(path, name; force=true, git=false, template=t1)

@test ispath(joinpath(path, "data"))
@test ispath(joinpath(path, "documents"))
@test ispath(joinpath(path, "documents", "a"))
@test !ispath(joinpath(path, "src"))

# Test .gitignore templates

initialize_project(path, name; force=true, git=true,
    folders_to_gitignore=["videos"])
gitignore_path = joinpath(path, ".gitignore")
@test ispath(gitignore_path)
gitignore_lines = readlines(gitignore_path)
@test "/videos" ∈ gitignore_lines
@test "/notebooks" ∉ gitignore_lines


rm(joinpath(@__DIR__, path); recursive=true, force=true)
@test !isdir(joinpath(@__DIR__, path))
