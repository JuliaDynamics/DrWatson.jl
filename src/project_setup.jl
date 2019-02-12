##########################################################################################
# Project directory and setup management
##########################################################################################
export projectdir, datadir, srcdir, plotsdir
export projectname

projectdir() = dirname(Base.active_project())*"/"
datadir() = projectdir()*"data/"
srcdir() = projectdir()*"src/"
plotsdir() = projectdir()*"plots/"

projectname() = Pkg.REPLMode.promptf()[2:end-7]
