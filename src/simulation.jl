using Dates
export simdir, simid, @run, @runsync, @rerun, @rerunsync, in_simulation_mode, @SimulationEnvironment

const ENV_SIM_FOLDER = "SIMULATION_FOLDER"
const ENV_SIM_ID = "SIMULATION_ID"

"""
    AbstractSimulationEnvironment

    # Examples
```julia-repl
julia> 
```
"""
abstract type AbstractSimulationEnvironment end

struct DefaultSimulation <: AbstractSimulationEnvironment end

macro SimulationEnvironment(name::Symbol)
    :(struct $name <: DrWatson.AbstractSimulationEnvironment end)
end

from_folder_name(n::String) = parse(Int, n)
to_folder_name(n) = string(n)

"""
    in_simulation_mode() -> Bool

Return true if called in a file part of the currently
active simulation.

# Examples
To add additional metadata during running a simulation:
```julia
# ...
if in_simulation_mode()
    m = Metadata(simdir())
    m["extra"] = "Some more info here"
end
# ...
```
"""
in_simulation_mode() = ENV_SIM_ID in keys(ENV)

"""
    simdir(args...)

Return the directory of the currently active simulation and
join the path of  with `args` (typically other subfolders).

This only works if the file, this is called from, runs as
part of a simulation.

See also [`in_simulation_mode`](@ref).
"""
function simdir(args...)
    if ENV_SIM_FOLDER in keys(ENV)
        return joinpath(ENV[ENV_SIM_FOLDER],args...)
    end
    error("Not in simulation environment")
end

"""
    simid() -> id

Return the id of the currently active simulation.

This only works if the file, this is called from, runs as
part of a simulation.

See also [`in_simulation_mode`](@ref).
"""
function simid()
    if ENV_SIM_ID in keys(ENV)
        return parse(Int,ENV[ENV_SIM_ID])
    end
    error("Not in simulation environment")
end

"""
    get_next_simulation_id(folder)

Return the next available id for a simulation saved in a directory in `folder`.
Simulation results are stored in folders in `folder`, where the id is an
increasing number (starting at 1).
Metadata for a simulation is always attached to the simulation directory.
"""
function get_next_simulation_id(folder)
    id = 1
    # Here, mkdir acts as kind of a lock for multi-threaded environments.
    # If a folder can't be created, whatever reason, the next id (+1) is
    # tried. This is a save method to determine the next possible simulation
    # id, without using additional locking mechanisms. The alternative of
    # reading all folders in `folder` and then using the length + 1 is can
    # cause race conditions as, without a lock, the number of files could change
    # between `readdir` and `mkdir`.
    for i in 1:100_000_000 # Upper limit
        try
            mkdir(joinpath(folder,to_folder_name(id)))
            return id
        catch e
            if !isa(e, Base.IOError)
                rethrow(e)
            end
            id += 1
        end
    end
    error("Couldn't genereate new id in '$folder'")
end

run_simulation(f,p,args...) = run_simulation(f, [p], args...)

function run_in_simulation_mode(f)
    m = Metadata(simdir())
    f(m["parameters"])
end

"""
    add_simulation_metadata!(::AbstractSimulationEnvironment, m::Metadata;
                                 simulation_id,
                                 simulation_submit_time,
                                 simulation_submit_group,
                                 scriptfile,
                                 command,
                                 env,
                                 source)

Add the metadata that is stored for every simulation run.
By default, the following values are stored:
- "simulation_submit_time": Dates.now() when @run, and others, were called
- "simulation_submit_group": Project directory relative paths to simulation folders of jobs that were started in parallel
- "simulation_id": Unique id of this simulation run. Is equal to the name of the simulation folder
- "mtime_scriptfile": mtime of the sending script file
- "julia_command": Full julia command that was used for calling the script file
- "ENV": Current environment variables
- Current commit info with [`tag!`](@ref)

This can be customized by defining a custom simulation environment (see [`AbstractSimulationEnvironment`](@ref)).
"""
function add_simulation_metadata!(::AbstractSimulationEnvironment,
                                  m::Metadata;
                                 simulation_id,
                                 simulation_submit_time,
                                 simulation_submit_group,
                                 scriptfile,
                                 command,
                                 env,
                                 source
                                )
    m["simulation_submit_time"] = simulation_submit_time
    m["simulation_submit_group"] = simulation_submit_group
    m["simulation_id"] = simulation_id
    m["mtime_scriptfile"] = mtime(scriptfile)
    m["julia_command"] = command
    m["ENV"] = env
    tag!(m, source=source)
end

"""
    submit_command(::AbstractSimulationEnvironment, id, env) -> String

Return the command used for starting simulations. By default, the
command used for starting the main file dispatching the simulations is used.
`id` is the simulation id and `env` are the environmental variables.

This can be customized by defining a custom simulation environment (see [`AbstractSimulationEnvironment`](@ref)).
"""
submit_command(::AbstractSimulationEnvironment, id, env) = `$(Base.julia_cmd()) $(PROGRAM_FILE)`

"""
    run_simulation(t::AbstractSimulationEnvironment, f, param, directory, source; wait_for_finish=false)

Run `f(p)` for all `p ∈ param`. The output is stored in `directory`, where for each `p` a new
simulation folder and id ([`get_next_simulation_id`](@ref)) is created in `directory`.
`source` is the line `run_simulation` was called from and `wait_for_finish` controls if all
`f(p)` calls should run in parallel (`wait_for_finish = false`) or sequentially.

!!! note
    This function is usually nevery directly used.
    Use the macros @run, @runsync
"""
function run_simulation(t::AbstractSimulationEnvironment, f, param, directory, source; wait_for_finish=false)
    if in_simulation_mode()
        run_in_simulation_mode(f)
    else
        simulation_ids = map(param) do _
            get_next_simulation_id(directory)
        end

        simulation_submit_time = Dates.now()
        simulation_submit_group = [standardize_path(joinpath(directory,to_folder_name(i))) for i in simulation_ids]

        tasks = map(zip(param,simulation_ids)) do (p,id)
            folder = joinpath(directory,to_folder_name(id))
            m = Metadata(folder)
            env = copy(ENV)

            env[ENV_SIM_FOLDER] = folder
            env[ENV_SIM_ID] = string(id)

            command = submit_command(t, id, env)

            # Add the metadata for the simulation mode.
            # This is the optional data.
            add_simulation_metadata!(t, m, simulation_id=id, simulation_submit_time=simulation_submit_time,
                                     simulation_submit_group=simulation_submit_group,
                                     scriptfile=PROGRAM_FILE, command=command, env=env, source=source)
            # Add the parameters as metadata.
            # This is the only metadata that is required
            m["parameters"] = p

            return @async begin
                run(setenv(`$command`, env), wait=wait_for_finish)
            end
        end
        print("Starting $(length(simulation_ids)) job(s):")
        for id in simulation_ids
            project_rel_path = standardize_path(joinpath(directory,to_folder_name(id)))
            print("\n  $project_rel_path")
        end
        println()
        wait.(tasks)
    end
end

"""
    rerun_simulation(t::AbstractSimulationEnvironment, f, folder, source; wait_for_finish=false)

Rerun a simulation which was already started (but failed). Basically `f(p)` is called, where `p`
is the parameter set stored in the metadata entry for `folder`.
`source` is the line `rerun_simulation` was called from and `wait_for_finish` controls if
`f(p)` should run in the backround (`wait_for_finish = false`) or foreground.

!!! note
    This function is usually nevery directly used.
    Use the macros @rerun, @rerunsync
"""
function rerun_simulation(t::AbstractSimulationEnvironment, f, folder, source; wait_for_finish=false)
    if in_simulation_mode()
        run_in_simulation_mode(f)
    else
        m_original = Metadata(folder)
        simulation_submit_time = Dates.now()
        simulation_submit_group = "simulation_submit_group" in keys(m_original) ? m_original["simulation_submit_group"] : []
        p = m_original["parameters"]
        id = from_folder_name(basename(folder))
        m = Metadata!(folder)

        env = copy(ENV)
        env[ENV_SIM_FOLDER] = folder
        env[ENV_SIM_ID] = string(id)

        command = submit_command(t, id, env)

        add_simulation_metadata!(t, m, simulation_id=id, simulation_submit_time=simulation_submit_time,
                                 simulation_submit_group=simulation_submit_group,
                                 scriptfile=PROGRAM_FILE, command=command, env=env, source=source)

        m["parameters"] = p
        t = @async run(setenv(`$command`, env), wait=wait_for_finish)
        wait(t)
    end
end

"""
    @run f params directory
    @run t::AbstractSimulationEnvironment f params directory

Run `f(p)` for all `p ∈ param` in parallel. The output is stored in `directory`, where for each `p` a new
simulation folder and id ([`get_next_simulation_id`](@ref)) is created in `directory`.

Simulations work as follows:
1. As usual, run the file which defines all parameter configurations and contains the `@run` call.
2. Scan the provided folder `directory` for the next available simulation id and created the simulation directory ([`simdir()`][@ref])
3. Metadata for the generated folder is written containing information about the calling environment and the parameters
4. For every parameter, a new detached Julia process is spawned, with the same calling configuration as in (1), except additional environmental variables are set containing the simulation id of this run.
5. With this variables set, the script now behaves differently. The function [`simdir()`][@ref] is now provided, which gives the path to the assigned simulation directory and instead of looping over all configuration now the one configuration identified by the id runs by loading the associated metadata.

# Examples
```julia
using DrWatson
@quickactivate
using FileIO

function fakesim(a, b, v, method = "linear")
    if method == "linear"
        r = @. a + b * v
    elseif method == "cubic"
        r = @. a*b*v^3
    end
    y = sqrt(b)
    return r, y
end

function makesim(d::Dict)
    @unpack a, b, v, method = d
    r, y = fakesim(a, b, v, method)
    fulld = copy(d)
    fulld[:r] = r
    fulld[:y] = y
    save(simdir("output.jld2"), fulld)
end

allparams = Dict(
    :a => [1, 2],
    :b => [3, 4],
    :v => [rand(5)],
    :method => "linear",
)

dicts = dict_list(allparams)

@run makesim dicts datadir("sims")
```
"""
macro run(f, p, directory)
    source=QuoteNode(__source__)
    :(run_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(p)), $(esc(directory)), $source))
end

"""
    @runsync f params directory
    @runsync t::AbstractSimulationEnvironment f params directory

Run `f(p)` for all `p ∈ param` sequentially. 

See also [`@run`](@ref),
"""
macro runsync(f, p, directory)
    source=QuoteNode(__source__)
    :(run_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(p)), $(esc(directory)), $source, wait_for_finish=true))
end

"""
    @rerun f path
    @rerun t::AbstractSimulationEnvironment f path

Rerun a simulation which was already started (but failed) in the backround. Basically `f(p)` is called, where `p`
is the parameter set stored in the metadata entry for `path`.

See also [`@rerun`](@ref), [`@run`](@ref)
"""
macro rerun(f, path)
    source=QuoteNode(__source__)
    :(rerun_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(path)), $source))
end

"""
    @rerunsync f path
    @rerunsync t::AbstractSimulationEnvironment f path

Rerun a simulation which was already started (but failed) in the foreground. Basically `f(p)` is called, where `p`
is the parameter set stored in the metadata entry for `path`.

See also [`@rerun`](@ref), [`@run`](@ref)
"""
macro rerunsync(f, path)
    source=QuoteNode(__source__)
    :(rerun_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(path)), $source, wait_for_finish=true))
end

macro run(t, f, p, directory)
    source=QuoteNode(__source__)
    :(run_simulation($(esc(t)),$(esc(f)), $(esc(p)), $(esc(directory)), $source))
end

macro runsync(t, f, p, directory)
    source=QuoteNode(__source__)
    :(run_simulation($(esc(t)),$(esc(f)), $(esc(p)), $(esc(directory)), $source, wait_for_finish=true))
end

macro rerun(t, f, path)
    source=QuoteNode(__source__)
    :(rerun_simulation($(esc(t)),$(esc(f)), $(esc(path)), $source))
end

macro rerunsync(t, f, path)
    source=QuoteNode(__source__)
    :(rerun_simulation($(esc(t)),$(esc(f)), $(esc(path)), $source, wait_for_finish=true))
end


