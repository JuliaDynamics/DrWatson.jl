function dummy_project(f; keep_files=false)
    folder = joinpath(@__DIR__,"dummy_project")
    isdir(folder) && rm(folder, recursive=true)
    mkdir(folder)
    initialize_project(folder)
    try
        f(folder)
    catch e
        keep_files|| rm(folder,recursive=true)
        rethrow(e)
    end
    keep_files|| rm(folder,recursive=true)
    @quickactivate
end