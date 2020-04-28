# # DrWatson Workflow Tutorial

cd(@__DIR__) #src

# *Disclaimer: DrWatson assumes basic (but only basic) knowledge of how Julia's
# project manager works.*

# This example page demonstrates how DrWatson's functions help a typical scientific
# workflow, as illustrated below:

# ![](workflow.png)

# Blue text comes from DrWatson. Of course, not all of DrWatson's functionality
# will be highlighted in this tutorial nor is shown in the above figure!

# ## 1. Setup the project

# So, let's start a new scientific project. You want your project to be contained
# in a folder. So let's create a new project, located at current working directory
using DrWatson
initialize_project("DrWatson Exaple"; authors="Datseris", force=true)

cd(projectdir()) #src

# Alright now we have a project set up. The project has a default reasonable structure,
# as illustrated in the [Project Setup](@ref) page.
# For example, folders exist for data, plots, scripts, source code, etc.
# Three things are noteworthy:
# * Project.toml: Defines project
# * Manifest.toml: Contains exact list of project dependencies
# * .git (hidden folder): Contains reversible history of the project

# The project we have created is active by default. This means that it has its own
# dedicated dependencies and versions of dependencies. We can start adding packages
# that we will be using in the project. I'll add Statistics and BSON for
# demonstrating.
using Pkg
Pkg.add(["Statistics", "BSON"])

# ## 2. Write some scripts

# We start by writing some script for our project that will do some dummy caclulations.
# Let's create `scripts/example.jl` in our project. The following text is supposed to
# exist in that file (to simulate this we just change directory into the scripts folder)

cd(scriptsdir()) #src

# Let's also reset the Julia projec to the default one.

Pkg.activate()

# Now, every script I ever write starts with the following two lines:
quickactivate(projectdir()) # src
# ```julia
# using DrWatson
# @quickactivate "DrWatson Example" # <- project name
# ```
# This command does something simple: it searches the folder of the script, and its
# parent folders, until it finds a Project.toml. It activates that project, but
# if the project name doesn't match the given name (here `"DrWatson Example"`)
# it throws an error.

# This is **extremely useful** for two reasons. First, it is guaranteed
# that our scripts run within the context of the project and thus use the correct
# package versions.

# Second, DrWatson provides the powerful function [`projectdir`](@reF) and its derivatives
# like `datadir, plotsdir, srcdir`, etc.
projectdir()

# `projectdir` will **always** return the path to the currently active project. It doesn't
# matter where its called from, or where the active project actually is.
# So, by using DrWatson, you don't care anymore where your current script is, you only
# care about the target directory.

datadir()

#

datadir("sims", "electron_gas")

# Giving arguments to `projectdir` and derivatives joins paths.

# ## 3. Prepare simulations

# Let's say we write a simple simulation function, that creates some data
function fakesim(a, b, v, method = "linear")
    if method == "linear"
        r = @. a + b * v
    elseif method == "cubic"
        r = @. a*b*c^3
    end
    y = sqrt(b)
    return r, y
end

# and we create some parameters in our scripts and run the simulation
a, b = 2, 3
v = rand(5)
method = "linear"
r, y = fakesim(a, b, c, method)

# Okay, that is fine, but it is typically the case that in scientific context
# some simulations are done for several different combinations of parameters.
# It is convenient to group all parameters in a dictionary, with the keys
# being the parameters (as symbols or strings). E.g.

params = Dict(:a => 2, :b => 3, :v => rand(5), :method => "linear")

# Now, for every simulation we want to do, we would create such a container.
# We can use the [`dict_list`](@ref) to ease up the process of preparing several
# of these parameter containers

allpars = Dict(
    :a => [1, 2], # it is inside vector. It is expanded.
    :b => [3, 4],
    :v => [rand(5)], # single element inside vector; no expansion
    :method => ["linear", "cubic"],
)

alldicts = dict_list(allpars)

# 4. Run and save
# Alright, we now have to actually save the results, so we first define:

using Parameters: @unpack

function makesim(d::Dict)
    @unpack a, b, v, method = d
    r, y = fakesim(a, b, v, method)
    fulld = copy(d)
    fulld[:r] = r
    fulld[:y] = y
    return fulld
end

# and then we can save the results by doing something as simple as

for (i, d) in enumerate(alldics)
    f = makesim(d)
    save(datadir("simulations", "sim_$(i).bson"), f)
end

# but we can use savename!!! woooo
