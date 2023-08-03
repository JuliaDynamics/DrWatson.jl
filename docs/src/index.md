![DrWatson](https://github.com/JuliaDynamics/JuliaDynamics/blob/master/videos/drwatson/DrWatson-banner-nobg.png?raw=true)

---

DrWatson is a **scientific project assistant** software.
It helps people manage their scientific projects (or any project for that matter).

Specifically, it is a Julia package created to help people increase the consistency of their scientific projects, navigate them and share them faster and easier, manage scripts, existing simulations as well as project source code.
DrWatson helps establishing reproducibility, and in general it makes managing a scientific project a simple job.

See the [Functionality](@ref) section to get an impression of what you can do with DrWatson or see the [DrWatson Workflow Tutorial](@ref) to get a "crash course" of how DrWatson helps the typical scientific workflow.
The [Description of DrWatson](@ref) section describes the design decisions that make it a unique software that truly helps the scientific workflow.
If you want to see how DrWatson compares with other existing alternatives, please have a look at our paper in [Citation](@ref).

You can also watch this 8-minutes video that introduces DrWatson in JuliaCon2020:

```@raw html
<iframe width="560" height="400" src="https://www.youtube-nocookie.com/embed/jKATlEAu8eE" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
```

DrWatson is part of [JuliaDynamics](https://juliadynamics.github.io/JuliaDynamics/), check out our [website](https://juliadynamics.github.io/JuliaDynamics/) for more cool stuff!

!!! note "Star us on GitHub!"
    If you like DrWatson the please consider starring the [GitHub repository](https://github.com/JuliaDynamics/DrWatson.jl). This gives as an accurate lower bound of the number of people the software has helped!

## Installing and Updating
To install or update DrWatson, simply type `] add DrWatson` or `] up DrWatson`, respectively, in your Julia session.

!!! info "Update messages"
    Upon update DrWatson will display a message highlighting any major changes or major new features. To disable these messages set the environment variable `DRWATSON_UPDATE_MSG` to `0` prior to `using DrWatson`.

## Rationale
Have you thought things like:

* Urgh, I moved my folders and now my `load` commands don't work anymore!
* Hold on, haven't I run this simulation already?
* Do I have to produce a dataframe of my finished simulations AGAIN?!
* Wait, are those experiments already processed?
* PFfffff I am tired of typing `savename = "w=$w_f=$f_x=$x.txt"`, can't I do it automatically?
* I wish I could just make a dataframe out of all my simulations with one command!
* Yeah you've sent me your project but none of the scripts work...
* It would be so nice to automatically integrate `git` information to all the data I save...

DrWatson tries to eradicate such bad thoughts and bedtime nightmares.


## Functionality
DrWatson is a **scientific project assistant software**. Here is what it can do:

* [Project Setup](@ref) : A universal project structure and functions that allow you to consistently and robustly navigate through your project, no matter where it is located.
* [Naming Simulations](@ref) : A robust and deterministic scheme for naming and handling your containers.
* [Saving Tools](@ref) : Tools for safely saving and loading your data, tagging the Git commit ID to your saved files, safety when tagging with dirty repos, and more.
* [Running & Listing Simulations](@ref): Tools for producing tables of existing simulations/data, adding new simulation results to the tables, preparing batch parameter containers, and more.

See the [DrWatson Workflow Tutorial](@ref) page to get a quick overview
over all of these functionalities.

Think of these core aspects of DrWatson as independent islands connected by bridges. If you don't like the approach of one of the islands, you don't have to use it to take advantage of DrWatson!

Applications of DrWatson are demonstrated the [Real World Examples](@ref) page. All of these examples are taken from code of real scientific projects that use DrWatson.

Please note that DrWatson is **not a data management system**.
It is also **not a Julia package creator** like [PkgTemplates.jl](https://github.com/invenia/PkgTemplates.jl) **nor a package development tool**.

## Description of DrWatson

DrWatson follows these simple principles:

1. **Non-Invasive.** DrWatson does not require you to follow strict rules or change the way you work and do science in order to use it. In addition DrWatson is function-based: you only have to call a function and everything else just works; you *do not* have to create additional special `struct` or other data types. In addition, you also do not have to do anything outside of your code (e.g. command line arguments or external software tools).
1. **Simple.** The functionality offered is a baseline from where you handle your project as you wish. This makes it more likely to be of general use but also means that you don't have to "study" to learn DrWatson: all concepts are simple, everything is easy to understand.
2. **Consistent.** The functionality is identical across all projects and DrWatson offers a universal base project structure.
3. **Allows increments.** You didn't plan your project well enough? Want to add more folders, more files, more variables to your simulations? It's fine.
5. **Reproducibility.** DrWatson aims to make your projects fully reproducible using Git, Julia's package manager and consistent naming schemes.
6. **Modular.** DrWatson has a flexible modular design (see [Functionality](@ref)) which means you only have to use what fits _your project_.
1. **General.** DrWatson is completely agnostic to the content of your project. It is not tailored to specific scientific workflows, or specific scientific communities.
4. **Scientific.** DrWatson has been beta tested in many real-world scientific projects and has matured based on feedback from scientists.

This is why we believe DrWatson can help you focus on the science and not worry about project code management.

## Citation
If you have used DrWatson in a scientific project that lead to a publication, we'd appreciate you citing the paper associated with it.
This paper also compares DrWatson to other software that have been used to aid the scientific workflow in one way or another,
and highlights the unique features of DrWatson.

```
@article{Datseris2020,
  doi = {10.21105/joss.02673},
  url = {https://doi.org/10.21105/joss.02673},
  year = {2020},
  publisher = {The Open Journal},
  volume = {5},
  number = {54},
  pages = {2673},
  author = {George Datseris and Jonas Isensee and Sebastian Pech and Tamás Gál},
  title = {DrWatson: the perfect sidekick for your scientific inquiries},
  journal = {Journal of Open Source Software}
}
```

or use the DOI directly:

[![DOI](https://joss.theoj.org/papers/10.21105/joss.02673/status.svg)](https://doi.org/10.21105/joss.02673)

## Other useful packages

### Simulation related
* <https://github.com/baggepinnen/Hyperopt.jl>
* <https://github.com/rafaqz/ModelParameters.jl>

### Efficient code writing
* <https://github.com/docopt/DocOpt.jl>
* <https://github.com/vtjnash/Glob.jl>

### Notebooks
* <https://github.com/JuliaLang/IJulia.jl>
* <https://github.com/JunoLab/Weave.jl>
* <https://github.com/fonsp/Pluto.jl>

### Papers/books and code
* <https://quarto.org/docs/computations/julia.html>
* <https://nextjournal.com/>
* <https://github.com/JuliaBooks/Books.jl>

### Documenting your code
* <https://github.com/JuliaDocs/Documenter.jl>
* <https://github.com/fredrikekre/Literate.jl>
* <https://github.com/caseykneale/Sherlock.jl>
* <https://github.com/miguelraz/DoctorDocstrings.jl>

### Paper-related
* <https://github.com/Humans-of-Julia/Bibliography.jl>
* <https://github.com/SebastianM-C/PkgCite.jl>

### Writing and debugging code
* <https://junolab.org/>
* <https://github.com/timholy/Revise.jl>
* <https://github.com/JuliaDebug/Debugger.jl>
* <https://github.com/MichaelHatherly/InteractiveErrors.jl>

### Performance measures
* <https://github.com/JuliaCI/BenchmarkTools.jl>
* <https://github.com/timholy/ProgressMeter.jl>
* <https://github.com/KristofferC/TimerOutputs.jl>
* <https://github.com/JuliaDebug/Cthulhu.jl>
* ProfileViews.jl (similar available in VSCode with `@profview`)

### Saving Data
* JLD2.jl
* BSON.jl
* CSV.jl

### Data management & data bases
* <https://github.com/helgee/RemoteFiles.jl>
* <https://github.com/JuliaDynamics/CaosDB.jl>
* <https://juliadb.org/>
* <https://github.com/SebastianM-C/StorageGraphs.jl>
* <https://tecosaur.github.io/DataToolkitDocs/>

### Tabular data
* <https://juliadata.github.io/DataFrames.jl/stable/>
* <https://www.queryverse.org/>

### Traversing folders
* Base.Filesystem
* <https://github.com/Keno/AbstractTrees.jl/blob/master/examples/fstree.jl>


### Time management
* <https://github.com/oxinabox/ProjectManagement.jl>

## Support and Contributing
Questions about DrWatson can be asked by directly opening up an Issue on its GitHub page, or asking in the Julia slack channels `#helpdesk, #dynamics-bridged`.

If you wish to contribute, thats great! Please consult the [online guidelines](https://github.com/JuliaDynamics/DrWatson.jl/blob/master/CONTRIBUTING.md).


## Inspirations

Initial inspirations for DrWatson follow below. All inspirations are specific in scope and functionality, and since its original conception DrWatson has moved on to become a whole scientific project assistant.

[https://drivendata.github.io/cookiecutter-data-science/#cookiecutter-data-science](https://drivendata.github.io/cookiecutter-data-science/#cookiecutter-data-science)

[https://discourse.julialang.org/t/computational-experiments-organising-different-algorithms-their-parameters-and-results/10774/7](https://discourse.julialang.org/t/computational-experiments-organising-different-algorithms-their-parameters-and-results/10774/7)

[http://neuralensemble.org/sumatra/](http://neuralensemble.org/sumatra/)

[https://github.com/mohamed82008/ComputExp.jl](https://github.com/mohamed82008/ComputExp.jl
)

[https://sacred.readthedocs.io/en/latest/index.html](https://sacred.readthedocs.io/en/latest/index.html)

[https://experimentator.readthedocs.io/en/latest/](https://experimentator.readthedocs.io/en/latest/)
