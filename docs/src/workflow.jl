# # DrWatson Workflow Tutorial

# ```@setup workflow
# cd(@__DIR__)
# ```

# *Disclaimer: DrWatson assumes basic knowledge of how Julia's
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
initialize_project("DrWatson Example"; authors="Datseris", force=true)

# Alright now we have a project set up. The project has a default reasonable structure,
# as illustrated in the [Default Project Setup](@ref) page.
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
# Let's create `scripts/example.jl` in our project. All following code is supposed to
# exist in that file.

# ```@setup workflow
# cd(joinpath(@__DIR__, "DrWatson Example"))
# ```

pwd()

# Let's also reset the Julia project to the default one.

Pkg.activate()


# Now, every script I ever write starts with the following two lines:
# ```@setup workflow
# quickactivate("DrWatson Example", "DrWatson Example")
# ```


# ```julia
# using DrWatson
# @quickactivate "DrWatson Example" # <- project name
# ```
# This command does something simple: it searches the folder of the script, and its
# parent folders, until it finds a Project.toml. It activates that project, but
# if the project name doesn't match the given name (here `"DrWatson Example"`)
# it throws an error. Let's see the project we activated:
projectname()

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
        r = @. a*b*v^3
    end
    y = sqrt(b)
    return r, y
end

# and we create some parameters in our scripts and run the simulation
a, b = 2, 3
v = rand(5)
method = "linear"
r, y = fakesim(a, b, v, method)

# Okay, that is fine, but it is typically the case that in scientific context
# some simulations are done for several different combinations of parameters.
# It is convenient to group all parameters in a dictionary, with the keys
# being the parameters (as symbols or strings). E.g.

params = Dict(:a => 2, :b => 3, :v => rand(5), :method => "linear")

# Now, for every simulation we want to do, we would create such a container.
# We can use the [`dict_list`](@ref) to ease up the process of preparing several
# of these parameter containers

allparams = Dict(
    :a => [1, 2], # it is inside vector. It is expanded.
    :b => [3, 4],
    :v => [rand(5)], # single element inside vector; no expansion
    :method => ["linear", "cubic"],
)

dicts = dict_list(allparams)

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

# and then we can save the results by once again leveraging [`projectdir`](@ref)
for (i, d) in enumerate(dicts)
    f = makesim(d)
    wsave(datadir("simulations", "sim_$(i).bson"), f)
end

# ```@setup workflow
# for (i, d) in enumerate(dicts)
#     f = makesim(d)
#     rm(datadir("simulations", "sim_$(i).bson"))
# end
# ```

# (`wsave` is a function from DrWatson, that ensures that the directory you try to
# save the data exists. It then calls `FileIO.save`)

# Here each simulation was named according to number.
# But this is not how we do it in science... We typically want the input parameters
# to be part of the file name. E.g. here we would want the file name to be something like
# `a=2_b=3_method=linear.bson`. It would be also nice that such a naming scheme would
# apply to arbitrary input parameters so that we don't have to manually write
# `a=$(a)_b=$(b)_method=$(method)` and change this code every time we change
# a parameter name...

# Enter [`savename`](@ref):

savename(params)

# `savename` takes as an input pretty much *any* Julia composite container with key-value
# pairs and transforms it into such a name. We can even do

savename(dicts[1], "bson")

# `savename` is flexible and smart. As you noticed, even though the vector `r` with
# 5 numbers is part of `params`, it wasn't included in the output name (on purpose).
# See `savename` documentation for more. We now transform our make+save loop into

for (i, d) in enumerate(dicts)
    f = makesim(d)
    wsave(datadir("simulations", savename(d, "bson")), f)
end

readdir(datadir("simulations"))

# That is cool, but we can do better. In fact, **much better**.
# Remember that the project initialized by DrWatson is a git repository.
# So, now go into git and commit the script we have created and all other
# changes (in e.g. the Project.toml).

# Then make+save again, but now instead of `wsave` us [`tagsave`](@ref):

# ```@setup workflow
# for (i, d) in enumerate(dicts)
#     f = makesim(d)
#     tagsave(datadir("simulations", savename(d, "bson")), f; gitpath = "../..")
# end
# ```

# ```julia
# for (i, d) in enumerate(dicts)
#     f = makesim(d)
#     tagsave(datadir("simulations", savename(d, "bson")), f)
# end
# ```

# and let's load the first simulation

firstsim = readdir(datadir("simulations"))[1]

wload(datadir("simulations", firstsim))

# So what happened is that `tagsave` automatically added git-related information
# into the file we saved (the field `:gitcommit`), enabling reproducibility!

# ## 5. Analyze results

# Cool, now we can start analyzing some simulations. The actual analysis is your job,
# but DrWatson can help you get started with the [`collect_results`](@ref) function.

df = collect_results(datadir("simulations"))

# Some things to note:
# * the returned object is a `DataFrame` for further analysis.
# * the input to `collect_result` is a folder, **not** a dataframe!
#   The function does the loading and combining for you.
# * If you create new simulations, you can iteratively (or all from scratch) add them to
#   this dataframe.
# * If you create new simulations that have **new parameters**, that don't exist in the
#   simulations already saved, that's no problem. `collect_results` will appropriately
#   and automatically add `missing` to all parameter values that don't exist in previews
#   and/or current simulations. This is demonstrated explicitly in the example
#   [Adapting to new data/parameters](@ref) real world example, so it is not repeated here.
# * Similarly with e.g. `savename`, `collect_results` is a flexible function. It has
#   several configuration options.

# Great! so now we are doing some analysis and we want to save some results...
# It is very often the case in science that the same analysis may be done again, and again,
# and some times even with the same parameters... And poor scientitists sometimes forget
# to change the name of the output file, and end up overwritting previous work! Devastating!

# To avoid such scenarios, we can use the function [`safesave`](@ref), e.g.

analysis = 42

safesave(datadir("ana", "linear.bson"), @dict analysis)

# If a file `linear.bson` exists in that folder, it is not overwritten. Instead, it is
# renamed to `linear#1.bson`, and a new `linear.bson` file is made!
# Notice also the usage of the ultra-cool [`@dict`](@ref) macro, which creates a
# dictionary from existing variables

@dict a b v analysis

# ## 6. Share your project

# This is already discussed in the [Reproducibility](@ref) section of the docs
# so there is no reason to copy/paste everything here.

# And that's it! Hope that DrWatson will take some stress out of the absurdly stressfull
# scientific life!
