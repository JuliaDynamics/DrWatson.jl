function addrun! end

function commitid(path = projectdir())
    # Here we test if the path is a git repository.
    if !ispath(joinpath(path, ".git"))
        return nothing
    end
    # then we return the current commit
    repo = LibGit2.GitRepo(path)
    return string(LibGit2.head_oid(repo))
end
