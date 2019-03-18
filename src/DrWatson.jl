"The perfect sidekick to your scientific inquiries"
module DrWatson
import Pkg, LibGit2

# Pure Julia implementation
include("project_setup.jl")
include("naming.jl")
include("saving_tools.jl")

# Functionality that saves/loads
import BSON
wsave = BSON.bson
wload = BSON.load
include("saving_files.jl")

# Functionality that requires Dataframes and other heavy dependencies:
using Requires
function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" begin
        include("result_collection.jl")
    end
end


function greet()
    println(
    """
    DrWatson is currently in beta. Help us make it better by opening
    issues on GitHub or submitting feature requests!

    Have fun with your new project!
    """
    )
end

end
