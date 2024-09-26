var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": "(Image: DrWatson)DrWatson is a Julia package created to help people \"deal\" with their simulations, simulation parameters, where are files saved, experimental data, scripts, existing simulations, project source code and in general their scientific projects.DrWatson is currently in alpha and under development!"
},

{
    "location": "#Rationale-1",
    "page": "Introduction",
    "title": "Rationale",
    "category": "section",
    "text": "Have you thought things like:Urgh, I moved my folders and now my load commands don\'t work anymore!\nMaaaan, have I run this simulation already?\nDo I have to produce a dataframe of my finished simulations AGAIN?!\nWait, are those experiments already processed?\nPFfffff I am tired of typing savename = \"w=$w_f=$f_x=$x.jld2, can\'t I do it automatically?\nI wish I could just use Parameters.jl and just translate my simulations into a dataframe.\nYeah you\'ve sent me your project but none of the scripts work...DrWatson tries to eradicate such bad thoughts and bedtime nightmares."
},

{
    "location": "#Description-of-DrWatson-1",
    "page": "Introduction",
    "title": "Description of DrWatson",
    "category": "section",
    "text": "DrWatson follows these simple principles:Basic. The functionality offered is something simple, a baseline from where you handle your project as you wish.\nConsistent. The functionality is identical across all projects and DrWatson offers (and parts of it assume) a universal base project structure.\nAllows increments. You didn\'t plan your project well enough? Want to add more folders, more files, more variables to your simulations? It\'s fine.\nHelpful. DrWatson has been beta tested in real-world scientific projects and has matured based on feedback from scientists. The entirety of DrWatson\'s functionality comes from answering questions of the type \"This would be helpful for my science project\".\nReproducible. DrWatson aims to make your projects fully reproducible using Git, Julia\'s package manager and consistent naming schemes.\nFlexible. DrWatson has a modular design (see Functionality) which means you only have to use what fits your project. There are no general rules to follow."
},

{
    "location": "#Functionality-1",
    "page": "Introduction",
    "title": "Functionality",
    "category": "section",
    "text": "The core aspects of DrWatson are completely independent of each other. If you don\'t like the approach of one of them you can just not use it!Project Setup : A universal project structure and functions that allow you to consistently and robustly navigate through your project, no matter where it is located on your hard drive.\nNaming & Saving Simulations : A robust scheme for saving your data, naming files, tagging the Git commit ID to your saved files, and more.\nRunning & Listing Simulations: Tools for producing tables of existing simulations/data, adding runs to such tables, preparing batch parameter containers, and more.Applications of DrWatson are demonstrated the Real World Examples page. All of these examples are directly copied from code of real scientific projects that use DrWatson."
},

{
    "location": "#Inspirations-1",
    "page": "Introduction",
    "title": "Inspirations",
    "category": "section",
    "text": "https://drivendata.github.io/cookiecutter-data-science/#cookiecutter-data-sciencehttps://discourse.julialang.org/t/computational-experiments-organising-different-algorithms-their-parameters-and-results/10774/7http://neuralensemble.org/sumatra/https://github.com/mohamed82008/ComputExp.jlhttps://sacred.readthedocs.io/en/latest/index.htmlhttps://experimentator.readthedocs.io/en/latest/"
},

{
    "location": "project/#",
    "page": "Project Setup",
    "title": "Project Setup",
    "category": "page",
    "text": ""
},

{
    "location": "project/#Project-Setup-1",
    "page": "Project Setup",
    "title": "Project Setup",
    "category": "section",
    "text": "Part of the functionality of DrWatson is creating and navigating through a project setup consistently. This works even if you move your project to a different location/computer and in addition the navigation process is identical across any project that uses DrWatson.For this to work, you only need to follow these rules:Your science project is also a Julia project defined by a Project.toml file.\nYou first activate this project environment before running any code. See Activating a Project for ways to do this.\nYou use the functions scriptdir, datadir, etc. from DrWatson (see Navigating a Project)"
},

{
    "location": "project/#Default-Project-Setup-1",
    "page": "Project Setup",
    "title": "Default Project Setup",
    "category": "section",
    "text": "Here is the default project setup that DrWatson suggests (and assumes, for the functionality of this page):using DrWatson\nstruct ShowFile\n    file::String\nend\nfunction Base.show(io::IO, ::MIME\"text/plain\", f::ShowFile)\n    write(io, read(f.file))\nendShowFile(dirname(pathof(DrWatson))*\"/defaults/project_structure.txt\") # hide"
},

{
    "location": "project/#src-vs-scripts-1",
    "page": "Project Setup",
    "title": "src vs scripts",
    "category": "section",
    "text": "Seems like src and scripts folders have pretty similar functionality. However there is a distinction between these two. You can follow these mental rules to know where to put file.jl:If upon include(\"file.jl\") there is anything being produced, be it data files, plots or even output to the console, then it should be in scripts.\nIf it is functionality used across multiple files or pipelines, it should be in src.\nsrc should only contain files that define functions or types but not output anything. You can also organize src to be a Julia package, or contain multiple Julia packages."
},

{
    "location": "project/#DrWatson.initialize_project",
    "page": "Project Setup",
    "title": "DrWatson.initialize_project",
    "category": "function",
    "text": "initialize_project(path [, name]; kwargs...)\n\nInitialize a scientific project expected by DrWatson inside the given path. If its name is not given, it is assumed to be the folder\'s name.\n\nThe new project remains activated for you to immidiately add packages.\n\nKeywords\n\nreadme = true : adds a README.md file.\nauthors = nothing : if a string or container of strings, adds the authors in the Project.toml file.\nforce = false : If the path is not empty then throw an error. If however force is true then recursively delete everything in the path and create the project.\ngit = true : Make the project a Git repository.\n\n\n\n\n\n"
},

{
    "location": "project/#Initializing-a-Project-1",
    "page": "Project Setup",
    "title": "Initializing a Project",
    "category": "section",
    "text": "To initialize a project as described in the Default Project Setup section, we provide the following function:initialize_project"
},

{
    "location": "project/#DrWatson.quickactivate",
    "page": "Project Setup",
    "title": "DrWatson.quickactivate",
    "category": "function",
    "text": "quickactivate(path [, name::String])\n\nActivate the project found by findproject of the path, which recursively searches the path and its parents for a valid Julia project file.\n\nOptionally check if name is the same as the activated project\'s name. If it is not, throw an error.\n\nThis function is first activating the project and then checking if it matches the name.\n\nwarning: Warning\nNote that to access quickactivate you need to be using DrWatson. For this to be possible DrWatson must be already added in the existing global environment. The version of DrWatson loaded therefore will be the one of the global environment, and not of the activated project. To avoid unexpected behavior take care so that these two versions coincide.In addition please be very careful to not write:using DrWatson, Package1, Package2\nquickactivate(@__DIR__)\n# do stuffbut instead load packages after activating the project:using DrWatson\nquickactivate(@__DIR__)\nusing Package1, Package2\n# do stuffThis ensures that the packages you use will all have the versions dictated by your activated project (besides DrWatson, since this is impossible to do using quickactivate).\n\n\n\n\n\n"
},

{
    "location": "project/#DrWatson.findproject",
    "page": "Project Setup",
    "title": "DrWatson.findproject",
    "category": "function",
    "text": "findproject(path = pwd()) -> project_path\n\nRecursively search path and its parents for a valid Julia project file (anything in Base.project_names). If it is found return its path, otherwise issue a warning and return nothing.\n\nThe function stops searching if it hits either the home directory or the root directory.\n\n\n\n\n\n"
},

{
    "location": "project/#DrWatson.projectname",
    "page": "Project Setup",
    "title": "DrWatson.projectname",
    "category": "function",
    "text": "projectname()\n\nReturn the name of the currently active project.\n\n\n\n\n\n"
},

{
    "location": "project/#Activating-a-Project-1",
    "page": "Project Setup",
    "title": "Activating a Project",
    "category": "section",
    "text": "This part of DrWatson\'s functionality requires you to have your scientific project (and as a consequence, the Julia project) activated. This can be done in multiple ways:doing Pkg.activate(\"path/to/project\") programmatically\nusing the startup flag --project path when starting Julia\nby setting the JULIA_PROJECT environment variable\nusing the functions quickactivate and findproject offered by DrWatson.We recommend the fourth approach, although it does come with a caveat (see the docstring of quickactivate).Here is how it works: the function quickactivate activates a project given some path by recursively searching the path and its parents for a valid Project.toml file. Typically you put this function in your script files like so:using DrWatson # DONT USE OTHER PACKAGES HERE!\nquickactivate(@__DIR__, \"Best project in the WOLLRDD\")\n# Now you should start using other packageswhere the second optional argument can assert if the activated project matches the name you provided. If not the function will throw an error.quickactivate\nfindprojectNotice that to get the current project\'s name you can use:projectname"
},

{
    "location": "project/#DrWatson.projectdir",
    "page": "Project Setup",
    "title": "DrWatson.projectdir",
    "category": "function",
    "text": "projectdir()\n\nReturn the directory of the currently active project. Ends with \"/\".\n\nprojectdir(folder::String) = joinpath(projectdir(), folder)*\"/\"\n\nReturn the directory of the folder in the active project.\n\n\n\n\n\n"
},

{
    "location": "project/#Navigating-a-Project-1",
    "page": "Project Setup",
    "title": "Navigating a Project",
    "category": "section",
    "text": "To be able to navigate the project consistently, DrWatson provides the core functionprojectdirBesides the above, the shortcut functions:datadir()\nsrcdir()\nplotsdir()\nscriptdir()\npapersdir()immediately return the appropriate subdirectory. These are also defined due to the frequent use of these subdirectories.In addition, the return value of all these functions ends with /. This means that you can directly chain them with a file name using just *. E.g. you could dousing DrWatson\nfile = makesimulation()\ntagsave(datadir()*\"sims/test.bson\", file)"
},

{
    "location": "project/#Reproducibility-1",
    "page": "Project Setup",
    "title": "Reproducibility",
    "category": "section",
    "text": "This project setup approach that DrWatson suggests has a very big side-benefit: it is fully reproducible firstly because it uses Julia\'s suggested project structure, secondly because the navigation only uses local directories and lastly because it is a Git repository.If you send your entire project folder to a colleague, they only need to do:julia> cd(\"path/to/project\")\npkg> activate .\npkg> instantiateAll required packages and dependencies will be installed and then any script that was running in your computer will also be running in their computer in the same way!In addition, with DrWatson you have the possibility of \"tagging\" each simulation created with the commit id, see the discussion around current_commit and tag!."
},

{
    "location": "name&save/#",
    "page": "Naming & Saving Simulations",
    "title": "Naming & Saving Simulations",
    "category": "page",
    "text": ""
},

{
    "location": "name&save/#Naming-and-Saving-Simulations-1",
    "page": "Naming & Saving Simulations",
    "title": "Naming & Saving Simulations",
    "category": "section",
    "text": "This page discusses numerous tools that make life easier for handling simulations. Most (if not all) of these tools are also used in the examples demonstrated in the Real World Examples page. After reading the proper documentation here it might be worth it to have a look there as well!"
},

{
    "location": "name&save/#DrWatson.savename",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.savename",
    "category": "function",
    "text": "savename([prefix,], c [, suffix]; kwargs...)\n\nCreate a shorthand name, commonly used for saving a file, based on the parameters in the container c (Dict, NamedTuple or any other Julia composite type, e.g. created with Parameters.jl). If provided use the prefix and end the name with .suffix (i.e. you don\'t have to include the . in your suffix).\n\nThe function chains keys and values into a string of the form:\n\nkey1=val1_key2=val2_key3=val3\n\nwhile the keys are always sorted alphabetically. If you provide the prefix/suffix the function will do:\n\nprefix_key1=val1_key2=val2_key3=val3.suffix\n\nassuming you chose the default connector, see below. Notice that prefix can be any path and in addition if it ends as a path (/ or \\) then the connector is ommited.\n\nsavename can be very conveniently combined with @dict or @ntuple.\n\nKeywords\n\nallowedtypes = default_allowed(c) : Only values of type subtyping anything in allowedtypes are used in the name. By default this is (Real, String, Symbol).\naccesses = allaccess(c) : You can also specify which specific keys you want to use with the keyword accesses. By default this is all possible keys c can be accessed with, see allaccess.\ndigits = 3 : Floating point values are rounded to digits. In addition if the following holds:\nround(val; digits = digits) == round(Int, val)\nthen the integer value is used in the name instead.\nconnector = \"_\" : string used to connect the various entries.\n\nExamples\n\nd = (a = 0.153456453, b = 5.0, mode = \"double\")\nsavename(d; digits = 4) == \"a=0.1535_b=5_mode=double\"\nsavename(\"n\", d) == \"n_a=0.153_b=5_mode=double\"\nsavename(\"n/\", d) == \"n/a=0.153_b=5_mode=double\"\nsavename(d, \"n\") == \"a=0.153_b=5_mode=double.n\"\nsavename(\"data/n\", d, \"n\") == \"data/n_a=0.153_b=5_mode=double.n\"\nsavename(\"n\", d, \"n\"; connector = \"-\") == \"n-a=0.153-b=5-mode=double.n\"\nsavename(d, allowedtypes = (String,)) == \"mode=double\"\n\nrick = (never = \"gonna\", give = \"you\", up = \"!\");\nsavename(rick) == \"give=you_never=gonna_up=!\" # keys are sorted!\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.@dict",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.@dict",
    "category": "macro",
    "text": "@dict vars...\n\nCreate a dictionary out of the given variables that has as keys the variable names and as values their values.\n\nExamples\n\njulia> ω = 5; χ = \"test\"; ζ = π/3;\n\njulia> @dict ω χ ζ\nDict{Symbol,Any} with 3 entries:\n  :ω => 5\n  :χ => \"test\"\n  :ζ => 1.0472\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.@strdict",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.@strdict",
    "category": "macro",
    "text": "@strdict vars...\n\nSame as @dict but the key type is String.\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.@ntuple",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.@ntuple",
    "category": "macro",
    "text": "@ntuple vars...\n\nCreate a NamedTuple out of the given variables that has as keys the variable names and as values their values.\n\nExamples\n\njulia> ω = 5; χ = \"test\"; ζ = 3.14;\n\njulia> @ntuple ω χ ζ\n(ω = 5, χ = \"test\", ζ = 3.14)\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.ntuple2dict",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.ntuple2dict",
    "category": "function",
    "text": "ntuple2dict(nt) -> dict\n\nConvert a NamedTuple to a dictionary.\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.dict2ntuple",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.dict2ntuple",
    "category": "function",
    "text": "dict2ntuple(dict) -> ntuple\n\nConvert a dictionary (with Symbol or String as key type) to a NamedTuple.\n\n\n\n\n\n"
},

{
    "location": "name&save/#Naming-Schemes-1",
    "page": "Naming & Saving Simulations",
    "title": "Naming Schemes",
    "category": "section",
    "text": "A robust naming scheme allows you to create quick names for simulations, create lists of simulations, check existing simulations, etc. More importantly it allows you to easily read and write simulations using a consistent naming scheme.savename\n@dict\n@strdict\n@ntupleNotice that this naming scheme integrates perfectly with Parameters.jl.Two convenience functions are also provided to easily switch between named tuples and dictionaries:ntuple2dict\ndict2ntuple"
},

{
    "location": "name&save/#DrWatson.allaccess",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.allaccess",
    "category": "function",
    "text": "allaccess(c)\n\nReturn all the keys c can be accessed using access. For dictionaries/named tuples this is keys(c), for everything else it is fieldnames(typeof(c)).\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.access",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.access",
    "category": "function",
    "text": "access(c, key)\n\nAccess c with given key. For AbstractDict this is getindex, for anything else it is getproperty.\n\naccess(c, keys...)\n\nWhen given multiple keys, access is called recursively, i.e. access(c, key1, key2) = access(access(c, key1), key2) and so on. For example, if c is a NamedTuple then access(c, k1, k2) == ntuple.k1.k2.\n\nnote: Note\nPlease only extend the single key method when customizing access for your own Types.\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.default_allowed",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.default_allowed",
    "category": "function",
    "text": "default_allowed(c) = (Real, String, Symbol)\n\nReturn the (super-)Types that will be used as allowedtypes in savename or other similar functions.\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.default_prefix",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.default_prefix",
    "category": "function",
    "text": "default_prefix(c) = \"\"\n\nReturn the prefix that will be used by default in savename or other similar functions.\n\n\n\n\n\n"
},

{
    "location": "name&save/#Customizing-savename-1",
    "page": "Naming & Saving Simulations",
    "title": "Customizing savename",
    "category": "section",
    "text": "You can customize savename for your own Types. For example you could make it so that it only uses some specific keys instead of all of them, only specific types, or you could make it access data in a different way (maybe even loading files!). You can even make it have a custom prefix!To do that you may extend the following functions:DrWatson.allaccess\nDrWatson.access\nDrWatson.default_allowed\nDrWatson.default_prefix"
},

{
    "location": "name&save/#DrWatson.current_commit",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.current_commit",
    "category": "function",
    "text": "current_commit(path = projectdir()) -> commit\n\nReturn the current active commit id of the Git repository present in path, which by default is the project path. If the repository is dirty when this function is called the string will end with \"_dirty\".\n\nSee also tag!.\n\nExamples\n\njulia> current_commit()\n\"96df587e45b29e7a46348a3d780db1f85f41de04\"\n\njulia> current_commit(path_to_dirty_repo)\n\"3bf684c6a115e3dce484b7f200b66d3ced8b0832_dirty\"\n\n\n\n\n\n"
},

{
    "location": "name&save/#DrWatson.tag!",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.tag!",
    "category": "function",
    "text": "tag!(d::Dict, path = projectdir()) -> d\n\nTag d by adding an extra field commit which will have as value the current_commit of the repository at path (by default the project\'s path). Does not operate if a key commit already exists.\n\nNotice that if String is not a subtype of the value type of d then a new dictionary is created and returned. Otherwise the operation is inplace (and the dictionary is returned again).\n\nExamples\n\njulia> d = Dict(:x => 3, :y => 4)\nDict{Symbol,Int64} with 2 entries:\n  :y => 4\n  :x => 3\n\njulia> tag!(d)\nDict{Symbol,Any} with 3 entries:\n  :y      => 4\n  :commit => \"96df587e45b29e7a46348a3d780db1f85f41de04\"\n  :x      => 3\n\n\n\n\n\n"
},

{
    "location": "name&save/#Tagging-a-run-using-Git-1",
    "page": "Naming & Saving Simulations",
    "title": "Tagging a run using Git",
    "category": "section",
    "text": "For reproducibility reasons (and also to not go insane when asking \"HOW DID I GET THOSE RESUUUULTS\") it is useful to \"tag!\" any simulation/result/process with the Git commit of the repository.To this end there are two functions that can be used to ensure reproducibility:current_commit\ntag!Please notice that tag! will operate in place only when possible. If not possible then a new dictionary is returned. Also (importantly) these functions will never error as they are most commonly used when saving simulations and this could risk data not being saved."
},

{
    "location": "name&save/#DrWatson.tagsave",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.tagsave",
    "category": "function",
    "text": "tagsave(file::String, d::Dict [, path = projectdir()])\n\nFirst tag! dictionary d using the project in path, and then save d in file.\n\n\n\n\n\n"
},

{
    "location": "name&save/#Automatic-Tagging-during-Saving-1",
    "page": "Naming & Saving Simulations",
    "title": "Automatic Tagging during Saving",
    "category": "section",
    "text": "If you don\'t want to always call tag! before saving a file, you can just use the function tagsave:tagsave"
},

{
    "location": "name&save/#DrWatson.produce_or_load",
    "page": "Naming & Saving Simulations",
    "title": "DrWatson.produce_or_load",
    "category": "function",
    "text": "produce_or_load([prefix=\"\",] c, f; kwargs...) -> file\n\nLet s = savename(prefix, c, suffix). If a file named s exists then load it and return it.\n\nIf the file does not exist then call file = f(c), save file as s and then return the file.\n\nTo play well with BSON the function f should return a dictionary with Symbol as key type. The macro @dict can help with that.\n\nKeywords\n\ntag = false : Add the Git commit of the project in the saved file.\nprojectpath = projectdir() : Path to search for a Git repo.\nsuffix = \"bson\" : Used in savename.\nkwargs... : All other keywords are propagated to savename.\n\nSee also savename and tag!.\n\n\n\n\n\n"
},

{
    "location": "name&save/#Produce-or-Load-1",
    "page": "Naming & Saving Simulations",
    "title": "Produce or Load",
    "category": "section",
    "text": "produce_or_load is a function that very conveniently integrates with savename to either load a file if it exists, or if it doesn\'t to produce it, save it and then return it!This saves you the effort of checking if a file exists and then loading, or then running some code and saving, or writing a bunch of if clauses in your code! produce_or_load really shines when used in interactive sessions where some results require a couple of minutes to complete.produce_or_load"
},

{
    "location": "run&list/#",
    "page": "Running & Listing Simulations",
    "title": "Running & Listing Simulations",
    "category": "page",
    "text": ""
},

{
    "location": "run&list/#Running-and-Listing-Simulations-1",
    "page": "Running & Listing Simulations",
    "title": "Running & Listing Simulations",
    "category": "section",
    "text": ""
},

{
    "location": "run&list/#DrWatson.dict_list",
    "page": "Running & Listing Simulations",
    "title": "DrWatson.dict_list",
    "category": "function",
    "text": "dict_list(c)\n\nExpand the dictionary c into a vector of dictionaries. Each entry has a unique combination from the product of the Vector values of the dictionary while the non-Vector values are kept constant for all possibilities. The keys of the entries are the same.\n\nWhether the values of c are iterable or not is of no concern; the function considers as \"iterable\" only subtypes of Vector.\n\nUse the function dict_list_count to get the number of dictionaries that dict_list will produce.\n\nExamples\n\njulia> c = Dict(:a => [1, 2], :b => 4);\n\njulia> dict_list(c)\n3-element Array{Dict{Symbol,Int64},1}:\n Dict(:a=>1,:b=>4)\n Dict(:a=>2,:b=>4)\n\njulia> c[:model] = \"linear\"; c[:run] = [\"bi\", \"tri\"];\n\njulia> dict_list(c)\n4-element Array{Dict{Symbol,Any},1}:\n Dict(:a=>1,:b=>4,:run=>\"bi\",:model=>\"linear\")\n Dict(:a=>2,:b=>4,:run=>\"bi\",:model=>\"linear\")\n Dict(:a=>1,:b=>4,:run=>\"tri\",:model=>\"linear\")\n Dict(:a=>2,:b=>4,:run=>\"tri\",:model=>\"linear\")\n\njulia> c[:e] = [[1, 2], [3, 5]];\n\njulia> dict_list(c)\n8-element Array{Dict{Symbol,Any},1}:\n Dict(:a=>1,:b=>4,:run=>\"bi\",:e=>[1, 2],:model=>\"linear\")\n Dict(:a=>2,:b=>4,:run=>\"bi\",:e=>[1, 2],:model=>\"linear\")\n Dict(:a=>1,:b=>4,:run=>\"tri\",:e=>[1, 2],:model=>\"linear\")\n Dict(:a=>2,:b=>4,:run=>\"tri\",:e=>[1, 2],:model=>\"linear\")\n Dict(:a=>1,:b=>4,:run=>\"bi\",:e=>[3, 5],:model=>\"linear\")\n Dict(:a=>2,:b=>4,:run=>\"bi\",:e=>[3, 5],:model=>\"linear\")\n Dict(:a=>1,:b=>4,:run=>\"tri\",:e=>[3, 5],:model=>\"linear\")\n Dict(:a=>2,:b=>4,:run=>\"tri\",:e=>[3, 5],:model=>\"linear\")\n\n\n\n\n\n"
},

{
    "location": "run&list/#DrWatson.dict_list_count",
    "page": "Running & Listing Simulations",
    "title": "DrWatson.dict_list_count",
    "category": "function",
    "text": "dict_list_count(c) -> N\n\nReturn the number of dictionaries that will be created by calling dict_list(c).\n\n\n\n\n\n"
},

{
    "location": "run&list/#Preparing-Simulation-Runs-1",
    "page": "Running & Listing Simulations",
    "title": "Preparing Simulation Runs",
    "category": "section",
    "text": "It is very often the case that you want to run \"batch simulations\", i.e. just submit a bunch of different simulations, all using same algorithms and code but just different parameters. This scenario always requires the user to prepare a set of simulation parameter containers which are then passed into some kind of \"main\" function that starts the simulation.To make the preparation part simpler we provide the following functionality:dict_list\ndict_list_countUsing the above function means that you can write your \"preparation\" step into a single dictionary and then let it automatically expand into many parameter containers. This keeps the code cleaner but also consistent, provided that it follows one rule: Anything that is a Vector has many parameters, otherwise it is one parameter. dict_list considers this true irrespectively of what the Vector contains. This allows users to use any iterable custom type as a single \"parameter\" of a simulation.See the Real World Examples for a very convenient application!"
},

{
    "location": "run&list/#DrWatson.collect_results",
    "page": "Running & Listing Simulations",
    "title": "DrWatson.collect_results",
    "category": "function",
    "text": "collect_results(folder; kwargs...) -> `df`\n\nSearch the folder (and possibly all subfolders) for new result-files and add them to df which is a DataFrame containing all the information from each result-file. BSON is used for both loading and saving, until FileIO interface includes BSON.\n\nIf a result-file is missing keys that are already columns in df, they will be set as missing. If on the other hand new keys are encountered, a new column will be added and filled with missing for all previous entries.\n\nYou can re-use an existing df that has some results already collected. Files already included in df are skipped in subsequent calls to collect_results (see keywords).\n\nwarning: Warning\ndf contains a column :path which is the path where each result-file is saved to. This is used to not re-load and re-process files already present in df when searching for new ones.If you have an entry :path in your saved result-files this will probably break collect_results (untested).\n\nKeyword Arguments\n\nsubfolders::Bool = false : If true also scan all subfolders of folder for result-files.\nfilename = joinpath(dirname(folder), \"results_$(basename(folder)).bson\": Path to load df from and to save it to. If given the empty string \"\" then df is not loaded/saved (it is always returned).\nvalid_filetypes = [\".bson\"]: Only files that have these endings are interpreted as result-files. Other files are skipped.\nwhite_list = keys(data): List of keys to use from result file. By default uses all keys from all loaded result-files.\nblack_list=[]: List of keys not to include from result-file.\nspecial_list=[]: List of additional (derived) key-value pairs to put in df as explained below.\n\nspecial_list is a Vector{Pair{Symbol, Function}} where each entry is a derived quantity to be included in df. The function entry always takes a single argument, which is the loaded the result-file (a dictionary). As an example consider that each result-file contains a field :longvector too large to be included in the df. The quantity of interest is the mean and the variance of said field. To have these values in your results first use black_list = [:longvector] and then define\n\nspecial_list = [ :lv_mean => data -> mean(data[:longvector]),\n                 :lv_lar  => data -> var(data[:longvector]) ]\n\nIn case this operation fails the values will be treated as missing.\n\n\n\n\n\n"
},

{
    "location": "run&list/#Collecting-Results-1",
    "page": "Running & Listing Simulations",
    "title": "Collecting Results",
    "category": "section",
    "text": "note: Requires `DataFrames`\nThe function collect_results is only available if you do using DataFrames in your Julia session.There are cases where you have saved a bunch of simulation results in a bunch of different files in a folder. It is useful to be able to collect all of these results into a single table, in this case a DataFrame. The function collect_results provides this functionality. Importantly, the function is \"future-proof\" which means that it works nicely even if you add new parameters or remove old parameters from your results as your project progresses!collect_resultsFor an example of using this functionality please have a look at the Real World Examples page!"
},

{
    "location": "real_world/#",
    "page": "Real World Examples",
    "title": "Real World Examples",
    "category": "page",
    "text": ""
},

{
    "location": "real_world/#Real-World-Examples-1",
    "page": "Real World Examples",
    "title": "Real World Examples",
    "category": "section",
    "text": "Coming soon."
},

]}
