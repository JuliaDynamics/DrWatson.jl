CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
using DrWatson, Documenter
@quickactivate "<NAME-PLACEHOLDER>"

# Here you may include files from the source directory
include(srcdir("dummy_src_file.jl"))

@info "Building Documentation"
makedocs(;
    sitename = "<NAME-PLACEHOLDER>",
    # This argument is only so that the sequence of pages in the sidebar is configured
    # By default all markdown files in `docs/src` are expanded and included.
    pages = [
        "index.md",
    ],
    # Don't worry about what `CI` does in this line.
    format = Documenter.HTML(prettyurls = CI),
)

@info "Deploying Documentation"
if CI
    deploydocs(
        # `repo` MUST be set correctly
        repo = "github.com/PutYourGitHubNameHere/<NAME-PLACEHOLDER>.git",
        target = "build",
        push_preview = true,
        devbranch = "main",
    )
end

@info "Finished with Documentation"
