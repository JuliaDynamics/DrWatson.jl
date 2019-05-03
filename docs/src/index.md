![DrWatson](https://github.com/JuliaDynamics/JuliaDynamics/blob/master/videos/drwatson/DrWatson-banner-nobg.png?raw=true)

---

DrWatson is a Julia package created to help people "deal" with their simulations, simulation parameters, where are files saved, experimental data, scripts, existing simulations, project source code and in general their scientific projects.
See the [Functionality](@ref) section to get an impression of what you can do with DrWatson.

**DrWatson is currently in beta and under development! Please join us in making this package more useful and more robust!**

!!! info "JuliaDynamics"
    DrWatson is part of [JuliaDynamics](https://juliadynamics.github.io/JuliaDynamics/), check out our [website](https://juliadynamics.github.io/JuliaDynamics/) for more cool stuff!

## Rationale
Have you thought things like:

* Urgh, I moved my folders and now my `load` commands don't work anymore!
* Duuuude, have I run this simulation already?
* Do I have to produce a dataframe of my finished simulations AGAIN?!
* Wait, are those experiments already processed?
* PFfffff I am tired of typing `savename = "w=$w_f=$f_x=$x.jld2"`, can't I do it automatically?
* I wish I could just use Parameters.jl and just translate my simulations into a dataframe.
* Yeah you've sent me your project but none of the scripts work...

DrWatson tries to eradicate such bad thoughts and bedtime nightmares.


## Description of DrWatson

DrWatson follows these simple principles:

1. **Non-Invasive.** DrWatson does not require you to follow strict rules or change the way you work and do science in order to use it. In addition DrWatson is function-based: you only have to call a function and everything else just works; you *do not* have to create additional special `struct` or other data types.
1. **Simple.** The functionality offered is a baseline from where you handle your project as you wish. This makes it more likely to be of general use but also means that you don't have to "study" to learn DrWatson: all concepts are simple, everything is easy to understand.
2. **Consistent.** The functionality is identical across all projects and DrWatson offers a universal base project structure.
3. **Allows increments.** You didn't plan your project well enough? Want to add more folders, more files, more variables to your simulations? It's fine.
5. **Reproducible.** DrWatson aims to make your projects fully reproducible using Git, Julia's package manager and consistent naming schemes.
6. **Modular.** DrWatson has a flexible modular design (see [Functionality](@ref)) which means you only have to use what fits _your project_.
4. **Scientific.** DrWatson has been beta tested in real-world scientific projects and has matured based on feedback from scientists.

What should become clear from the above principles, is that **DrWatson is not a data management system**. Its goal is to help you navigate and use a specific, contained scientific project. Of course, data management is very important, which is why we are currently working on bringing [CaosDB](https://arxiv.org/abs/1801.07653) to Julia. CaosDB is a **research** data management system that was developed by scientists for scientists, for more details please see the arXiv, or be a bit more patient until we bring it to Julia.


## Functionality
* [Project Setup](@ref) : A universal project structure and functions that allow you to consistently and robustly navigate through your project, no matter where it is located on your hard drive.
* [Naming Simulations](@ref) : A robust and deterministic scheme for naming and handling your containers.
* [Saving Tools](@ref) : Tools for safely saving and loading your data, tagging the Git commit ID to your saved files, safety when tagging with dirty repos, and more.
* [Running & Listing Simulations](@ref): Tools for producing tables of existing simulations/data, adding runs to such tables, preparing batch parameter containers, and more.

Think of these core aspects of DrWatson as independent islands connected by bridges. If you don't like the approach of one of the islands, you don't have to use it to take advantage of DrWatson!

Applications of DrWatson are demonstrated the [Real World Examples](@ref) page. All of these examples are taken from code of real scientific projects that use DrWatson.

## Inspirations

https://drivendata.github.io/cookiecutter-data-science/#cookiecutter-data-science

https://discourse.julialang.org/t/computational-experiments-organising-different-algorithms-their-parameters-and-results/10774/7

http://neuralensemble.org/sumatra/

https://github.com/mohamed82008/ComputExp.jl

https://sacred.readthedocs.io/en/latest/index.html

https://experimentator.readthedocs.io/en/latest/
