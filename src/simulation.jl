using Dates
export simdir, simid, @run, @runsync, @rerun, @rerunsync, in_simulation_mode, @SimulationEnvironment


const ENV_SIM_FOLDER = "SIMULATION_FOLDER"
const ENV_SIM_ID = "SIMULATION_ID"

abstract type AbstractSimulationEnvironment end

struct DefaultSimulation <: AbstractSimulationEnvironment end

macro SimulationEnvironment(name::Symbol)
    :(struct $name <: DrWatson.AbstractSimulationEnvironment end)
end

from_folder_name(n::String) = parse(Int, n)
to_folder_name(n) = string(n)
in_simulation_mode() = ENV_SIM_ID in keys(ENV)

function simdir(args...)
    if ENV_SIM_FOLDER in keys(ENV)
        return joinpath(ENV[ENV_SIM_FOLDER],args...)
    end
    error("Not in simulation environment")
end

function simid()
    if ENV_SIM_ID in keys(ENV)
        return parse(Int,ENV[ENV_SIM_ID])
    end
    error("Not in simulation environment")
end

function get_next_simulation_id(folder)
    id = 1
    for i in 1:100_000_000
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

submit_command(::AbstractSimulationEnvironment,id,env) = `$(Base.julia_cmd()) $(PROGRAM_FILE)`

function run_simulation(t::AbstractSimulationEnvironment,f,param,directory,source; wait_for_finish=false)
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

function rerun_simulation(t::AbstractSimulationEnvironment,f,folder,source; wait_for_finish=false)
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

macro run(f, p, directory)
    source=QuoteNode(__source__)
    :(run_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(p)), $(esc(directory)), $source))
end

macro runsync(f, p, directory)
    source=QuoteNode(__source__)
    :(run_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(p)), $(esc(directory)), $source, wait_for_finish=true))
end

macro rerun(f, path)
    source=QuoteNode(__source__)
    :(rerun_simulation(DrWatson.DefaultSimulation(),$(esc(f)), $(esc(path)), $source))
end

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


