# DrWatson

*The perfect sidekick to your scientific inquiries*

---

DrWatson is a Julia package created to help people "deal" with their simulations, simulation parameters, where are files saved, experimental data, scripts, existing simulations, project source code and in general their scientific projects.

**DrWatson is currently in alpha and under development!**

## Rationale
Have you thought things like:

* Urgh, I moved my folders and now my `load` commands don't work anymore!
* Maaaan, have I run this simulation already?
* Do I have to produce a dataframe of my finished simulations AGAIN?!
* Wait, are those experiments already processed?
* PFfffff I am tired of typing `savename = "w=$w_f=$f_x=$x.jld2`, can't I do it automatically?
* I wish I could just use Parameters.jl and just translate my simulations into a dataframe.
* Yeah you've sent me your project but none of the scripts work...

DrWatson tries to eradicate such bad thoughts and bedtime nightmares.


## Description of DrWatson

DrWatson follows these simple principles:

1. **Basic.** The functionality offered is something simple, a baseline from where you handle your project as you wish.
2. **Consistent.** The functionality is identical across all projects and DrWatson offers (and parts of it assume) a universal base project structure.
3. **Allows increments.** You didn't plan your project well enough? Want to add more folders, more files, more variables to your simulations? It's fine.
4. **Helpful.** DrWatson has been beta tested in real-world scientific projects and has matured based on feedback from scientists.
5. **Reproducible.** DrWatson aims to make your projects fully reproducible using Git, Julia's package manager and consistent naming schemes.

## Functionality

The functionality of DrWatson is composed of the following core parts, each being independent from each other:

* [Project Setup](@ref) : A universal project structure and functions that allow you to consistently and robustly navigate through your project, no matter where it is located on your hard drive.
* [Handling Simulations](@ref) : A robust scheme for saving your data, naming files, finding out if a simulation already exists, producing tables of existing simulations/data.


## Inspirations

https://drivendata.github.io/cookiecutter-data-science/#cookiecutter-data-science

https://discourse.julialang.org/t/computational-experiments-organising-different-algorithms-their-parameters-and-results/10774/7

http://neuralensemble.org/sumatra/

https://github.com/mohamed82008/ComputExp.jl

https://sacred.readthedocs.io/en/latest/index.html

https://experimentator.readthedocs.io/en/latest/
