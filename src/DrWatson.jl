"The perfect sidekick to your scientific inquiries"
module DrWatson
import Pkg, LibGit2

include("project_setup.jl")
include("naming.jl")
include("saving_tools.jl")

# Functionality that requires Optional Packages:
using Requires
function __init__()
    # @require BSON = "fbb218c0-5317-5bc6-957e-2ee96dd4b1f0" begin
    #     include("saving_bson.jl")
    # end
    @require FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" begin
        include("saving_jld2.jl")
    end
end


function greet()
    println("DrWatson is currently in alpha. More coolness coming soon!")
end

end
