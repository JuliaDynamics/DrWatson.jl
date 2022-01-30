function iolock(name; wait_for_semaphore="", path=metadatadir())
    lock_path =  joinpath(path,"$name.lck")
    for _ in 1:max_lock_retries
        if wait_for_semaphore == "" || semaphore_status(wait_for_semaphore) == 0
            try
                mkdir(lock_path)
                return
            catch e
                sleep(0.1)
            end
        end
    end
    error("Could not retriev lock $name")
end

function iounlock(name; path=metadatadir())
    lock_path =  joinpath(path,"$name.lck")
    try
        mkdir(lock_path)
    catch e
        rm(lock_path)
        return
    end
    rm(lock_path)
    error("$name is currently unlocked.")
end

function semaphore_status(name; path=metadatadir())
    sem_path =  joinpath(path,"$name.sem")
    iolock(name, path=path)
    if isfile(sem_path)
        n = parse(Int,read(sem_path,String))
    else
        n = 0
    end
    iounlock(name, path=path)
    return n
end

function semaphore_enter(name; path=metadatadir())
    sem_path =  joinpath(path,"$name.sem")
    iolock(name, path=path)
    if isfile(sem_path)
        n = parse(Int,read(sem_path,String))
    else
        n = 0
    end
    open(sem_path,"w") do f
        write(f, string(n+1))
    end
    iounlock(name, path=path)
end

function semaphore_exit(name; path=metadatadir())
    sem_path =  joinpath(path,"$name.sem")
    iolock(name, path=path)
    if isfile(sem_path)
        n = parse(Int,read(sem_path,String))
        if n == 1
            rm(sem_path)
        else
            open(sem_path,"w") do f
                write(f, string(n-1))
            end
        end
    else
        iounlock(name, path=path)
        error("Semaphore $name is out of balance. Expected a file but there is none")
    end
    iounlock(name, path=path)
end