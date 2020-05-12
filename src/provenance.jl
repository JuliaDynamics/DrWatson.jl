using Dates

function add_data_entry!(file::String, pdir = projectdir(), force = false; kwargs...)
    provenance = joinpath(pdr, "Provenance.bson")
    db = isfile(provenance) ? wload(provenance) : Dict{String, Any}()
    date = get(kwargs, :date, Dates.now())
    git = gitdescribe(pdir)
    if haskey(db, file)
        if force
            @warn "Provenance database has existing file. Overwriting..."
        else
            error("Provenance database has existing file.")
        end
    end
    db[file] = Dict{Symbol, Any}(:date => date, :git => git, kwargs...)
    wsave(provenance, db)
    return nothing
end
