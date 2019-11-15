using DrWatson, Test
using BSON, DataFrames, JLD2
###############################################################################
#                        Setup Folder structure                               #
###############################################################################
# %%
cd(@__DIR__)
isdir("testdir") && rm("testdir", recursive=true)
mkdir("testdir")
initialize_project("testdir"; git = false)
quickactivate("testdir")

###############################################################################
#                           Create Dummy Data                                 #
###############################################################################
mkdir(datadir()*"results")
cd(datadir()*"results")

d = Dict("a" => 1, "b" => "2", "c" => rand(10))
DrWatson.wsave(savename(d)*".bson", d)

d = Dict("a" => 3, "b" => "4", "c" => rand(10), "d" => Float64)
DrWatson.wsave(savename(d)*".bson", d)

d = Dict("a" => 3, "c" => rand(10), "d" => Float64)
DrWatson.wsave(savename(d)*".jld2", d)

mkdir("subfolder")
cd("subfolder")

d = Dict("a" => 4., "b" => "twenty" , "d" => Int)
DrWatson.wsave(savename(d)*".bson", d)

###############################################################################
#                           Collect Data Into DataFrame                       #
###############################################################################
using Statistics
special_list = [ :lv_mean => data -> mean(data["c"]),
                 :lv_lar  => data -> var(data["c"])]

black_list = ["c"]

folder = datadir()*"results"
defaultname = joinpath(dirname(folder), "results_$(basename(folder)).bson")
isfile(defaultname) && rm(defaultname)
cres = collect_results!(defaultname, folder;
    subfolders = true, special_list=special_list, black_list = black_list)

@test size(cres) == (4, 6)
for n in (:a, :b, :lv_mean)
    @test n ∈ names(cres)
end
@test :c ∉ names(cres)

###############################################################################
#                           Add another file in a sub sub folder              #
###############################################################################
@test isfile(defaultname)

mkdir("subsubfolder")
cd("subsubfolder")
d = Dict("b" => 35., "d" => Number, "c" => rand(5), "e" => "new_column")
DrWatson.wsave(savename(d)*".bson", d)
DrWatson.wsave(savename(d)*".jld2", d)

cres2 = collect_results!(defaultname, folder;
    subfolders = true, special_list=special_list, black_list = black_list)

@test size(cres2) == (6, 7)
@test all(names(cres) .∈ Ref(names(cres2)))

###############################################################################
#                           Load and analyze  DataFrame                       #
###############################################################################

df = BSON.load(defaultname)[:df]
@test size(df) == size(cres2)
@test sort(names(df)) == sort(names(cres2))

###############################################################################
#                            test empty whitelist                             #
###############################################################################

rm(defaultname)
cres_empty = collect_results!(defaultname, folder;
    subfolders = true, special_list=special_list, white_list=[]) 

@test dropmissing(cres2[!,[:lv_mean, :lv_lar, :path]]) == dropmissing(cres_empty)

###############################################################################
#                           test out-of-place form                            #
###############################################################################
cd(@__DIR__)

cres3 = collect_results(folder;
subfolders = true, special_list=special_list, black_list = black_list)

@test sort(names(cres3)) == sort(names(cres2))
@test size(cres3) == size(cres2)

###############################################################################
#                              Quickactivate macro                            #
###############################################################################

cd(@__DIR__)
isdir("testdir") && rm("testdir", recursive=true)
initialize_project("testdir"; git = false)
open(joinpath("testdir","testinclude.jl"),"w") do f
    write(f,"@quickactivate\n")
end
include(joinpath("testdir", "testinclude.jl"))
@test Base.active_project() == abspath(joinpath("testdir","Project.toml"))

###############################################################################
#                                 Delete Folders                              #
###############################################################################

cd(@__DIR__)
rm("testdir", recursive=true)