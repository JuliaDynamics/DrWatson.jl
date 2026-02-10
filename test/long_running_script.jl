using DrWatson
@quickactivate "dummy_project"
using FileIO
using Dates

function long_running_computation(p,output_path)
    sleep(p[:duration])
    result = p[:a]^p[:b]
    save(output_path, Dict("result"=>result))
    return nothing
end

duration = [0.1, 1]
a = [1,3]
b = 1
parameter = @dict duration a b

if in_simulation_mode()
    # Using simid() here is actually better, because then the 
    # no lookup it the index file is need which means, that the 
    # database must not be loked.
    m = Metadata(simdir())
    println("$(simid()): Loaded metadata file")
    m["type"] = "Simple Computation"
    m["started at"] = Dates.now()
    println("$(simid()): Creating new files")
    m_new = Metadata(simdir("newfile"))
    m_new["extra"] = "This should be blocked"
    println("$(simid()): Done creating new file")
end

@runsync x->long_running_computation(x, simdir("output.jld2")) dict_list(parameter) datadir("sims")
