"""
    produce_or_load(sname, f, args...; kwargs...) -> file
If `sname` exists and is a file, load that file using `file = FileIO.load(sname)`
and return it. If however the file does not exist, produce it by calling
```julia
file = f(args...; kwargs...)
```
then save it in `sname` and then return `file`.
"""
function produce_or_load(sname, f, args...; kwargs...)
    if isfile(sname)
        file = FileIO.load(sname)
        return file
    else
        @info "File $sname does not exist. Producing it now..."
        file = f(args...; kwargs...)
        FileIO.save(sname, file)
        return file
    end
end

function addrun! end
