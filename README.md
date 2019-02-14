# DrWatson - The perfect sidekick to your scientific inquiries

| **Documentation**   |  **Travis**     | **AppVeyor** | **Gitter** |
|:--------:|:---------------:|:-----:|:-----:|
|[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaDynamics.github.io/DrWatson.jl/dev)| | [![Build Status](https://travis-ci.org/JuliaDynamics/DrWatson.jl.svg?branch=master)](https://travis-ci.org/JuliaDynamics/DrWatson.jl) | [![Build status](https://ci.appveyor.com/api/projects/status/rq7epkxap25nbph1/branch/master?svg=true)](https://ci.appveyor.com/project/JuliaDynamics/drwatson-jl/branch/master) | [![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg)](https://gitter.im/JuliaDynamics/Lobby)

DrWatson is a Julia package created to help people "deal" with their simulations, simulation parameters, where are files saved, experimental data, scripts, existing simulations, project source code and in general their scientific projects.

**DrWatson is in pre-alpha. Wanna help development? Get involed by checking the issues and opening your own feature requests and suggestions.**

Contents:

* [Introduction](#introduction)
* [Part 1](#part-1)
* [Part 2](#part-2)
* [Inspirations](#inspirations)

---

## Introduction

Have you thought things like:

* Urgh, I moved my folders and now my `load` commands don't work anymore!
* Maaaan, have I run this simulation already?
* Do I have to produce a dataframe of my finished simulations AGAIN?!
* Wait, are those experiments already processed?
* PFfffff I am tired of typing `savename = "w=$w_f=$f_x=$x.jld2`, can't I do it automatically?
* I wish I could just use Parameters.jl and just translate my simulations into a dataframe.
* Yeah you've sent me your project but none of the scripts work...

Then DrWatson will make you really happy. :D


DrWatson tries to rely on the following simple principles:

1. **Basic.** The functionality offered is something simple, a baseline from where you handle your project as you wish.
2. **Consistent.** The functionality is identical across all projects and DrWatson offers (and parts of it assume) a universal base project structure.
3. **Allows increments.** You didn't plan your project well enough? Want to add more folders, more files, more variables to your simulations? It's fine.
4. **Helpful.** DrWatson has been beta tested in real-world scientific projects and has matured based on feedback from scientists.
5. **Reproducible.** DrWatson aims to make your projects fully reproducible using Julia's package manager and consistent naming schemes.


The functionality of DrWatson is composed of two main parts that are independent of each other (and you don't have to use both of them).

* Part 1: A universal project structure and functions that allow you to consistently and robustly navigate through your project, no matter where it is located on your hard drive.
* Part 2: A robust scheme for saving your data, naming files, finding out if a simulation already exists, producing tables of existing simulations/data.

## Part 1

DrWatson creates a specific project structure through the function `makeproject(path, projectname)`. This project structure is always the same (see below) and is also a git repository.

You scientific project is a ["Julia Environment"](https://julialang.github.io/Pkg.jl/v1/environments/), in the sense described in the documentation of the package manager. In short, your project is identified uniquely with a `Project.toml` file that contains your project's name and all the dependencies of your project (in the form of Julia packages).

The project created from `makeproject` has the structure described in the `src/project_structure.txt` file of this repository. The #1 issue of this repo is discussing what is the optimal structure of this repository.

**DrWatson's functionality of Part 1 assumes that all work related with your project is done with the project's directory activated.** Then the following functions are of use (exported by DrWatson):

```julia
projectdir() = dirname(Base.active_project())*"/"
datadir() = projectdir()*"data/"
srcdir() = projectdir()*"src/"
projectname() = Pkg.REPLMode.promptf()[1:end-6]
visdir() = projectdir()*"visualizations/"
```

## Part 2
A robust naming scheme allows you to create quick names for simulations, create lists of simulations, check existing simulations, etc. It is currently work in progress, but see the following two functions of the source code:
```julia
savename, @dict
```
The naming scheme integrates perfectly with Parameters.jl.

This scheme also allows incrementing the parameters: Let's say you have a simulation setup but now you want to produce more simulations with one extra parameter. But you want to be able to create a list of the simulations both with and without the extra parameter. *You can.*

THIS IS WIP, MORE STUFF/DOCS INCOMING.

## Inspirations

https://drivendata.github.io/cookiecutter-data-science/#cookiecutter-data-science

https://discourse.julialang.org/t/computational-experiments-organising-different-algorithms-their-parameters-and-results/10774/7

http://neuralensemble.org/sumatra/

https://github.com/mohamed82008/ComputExp.jl

https://sacred.readthedocs.io/en/latest/index.html

https://experimentator.readthedocs.io/en/latest/
