"The perfect sidekick to your scientific inquiries"
module DrWatson
using Pkg

include("project_setup.jl")
include("naming.jl")
include("saving.jl")

# Functionality that requires FileIO:
using Requires
function __init__()
    @require FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" begin
        import .FileIO: load, save
        include("saving_fileio.jl")
    end
end


end
