using DrWatson, Test
using BSON, DataFrames, FileIO, JLD2


@testset "Collect Results ($ending)" for ending ∈ ["bson", "jld2"]

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
mkdir(datadir("results"))
cd(datadir("results"))

d = Dict("a" => 1, "b" => "2", "c" => rand(10))
DrWatson.wsave(savename(d)*"."*ending, d)

d = Dict("a" => 3, "b" => "4", "c" => rand(10), "d" => Float64)
DrWatson.wsave(savename(d)*"."*ending, d)

d = Dict("a" => 3, "c" => rand(10), "d" => Float64)
DrWatson.wsave(savename(d)*"."*ending, d)

mkdir("subfolder")
cd("subfolder")

d = Dict("a" => 4., "b" => "twenty" , "d" => Int)
DrWatson.wsave(savename(d)*"."*ending, d)

###############################################################################
#                           Collect Data Into DataFrame                       #
###############################################################################
using Statistics
special_list = [ :lv_mean => data -> mean(data["c"]),
                :lv_var  => data -> var(data["c"])]

black_list = ["c"]

folder = datadir("results")

defaultname = joinpath(dirname(folder), "results_$(basename(folder))."*ending)
isfile(defaultname) && rm(defaultname)
cres = collect_results!(defaultname, folder;
    subfolders = true, special_list=special_list, black_list = black_list)

@test size(cres) == (4, 6)
for n in ("a", "b", "lv_mean")
    @test n ∈ String.(names(cres))
end
@test "c" ∉ names(cres)
@test all(startswith.(cres[!,"path"], projectdir()))

relpathname = joinpath(dirname(folder), "results_relpath_$(basename(folder))."*ending)
cres_relpath = collect_results!(relpathname, folder;
    subfolders = true, special_list=special_list, black_list = black_list,
    rpath = projectdir())
@info all(startswith.(cres[!,"path"], "data"))

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
#               Test additional syntax for special list                       #
###############################################################################

special_list2 = [ :lv_mean => data -> mean(data["c"]),
                data -> :lv_var  =>  var(data["c"]),
                data -> [:lv_mean2 => mean(data["c"]),
                        :lv_var2  =>  var(data["c"])]]
black_list = ["c"]

folder = datadir("results")
defaultname2 = joinpath(dirname(folder), "results_betterspeciallist."*ending)
isfile(defaultname2) && rm(defaultname2)
cres10 = collect_results!(defaultname2, folder;
    subfolders = true, special_list=special_list2, black_list = black_list)

@test size(cres10) == (6, 9)
for n in ("a", "b", "lv_mean", "lv_var", "lv_mean2", "lv_var2")
    @test n ∈ String.(names(cres10))
end
@test "c" ∉ names(cres10)
###############################################################################
#                           Load and analyze  DataFrame                       #
###############################################################################

df = load(defaultname)["df"]
@test size(df) == size(cres2)
@test sort(names(df)) == sort(names(cres2))

###############################################################################
#                            test empty whitelist                             #
###############################################################################

rm(defaultname)
cres_empty = collect_results!(defaultname, folder;
    subfolders = true, special_list=special_list, white_list=[])

@test dropmissing(cres2[!,[:lv_mean, :lv_var, :path]]) == dropmissing(cres_empty)

###############################################################################
#                           test out-of-place form                            #
###############################################################################
cd(@__DIR__)

cres3 = collect_results(folder;
subfolders = true, special_list=special_list, black_list = black_list)

@test sort(names(cres3)) == sort(names(cres2))
@test size(cres3) == size(cres2)

###############################################################################
#                           test updating feature                             #
###############################################################################

folder = datadir("update_test")
mkdir(folder)

d = Dict("idx" => :keep, "b" => "some_value")
fname_keep = joinpath(folder, savename(d, ending, ignores = ("b",)))
DrWatson.wsave(fname_keep, d)

d = Dict("idx" => :delete, "b" => "some_other_value")
fname_delete = joinpath(folder, savename(d, ending, ignores = ("b",)))
DrWatson.wsave(fname_delete, d)

d = Dict("idx" => :to_modify, "b" => "original_value")
fname_modify = joinpath(folder, savename(d, ending, ignores = ("b",)))
DrWatson.wsave(fname_modify, d)

cres_before = collect_results!(folder; update = true)

d = Dict("idx" => :to_modify, "b" => "modified_value")
DrWatson.wsave(fname_modify, d)
rm(fname_delete)

cres_after = collect_results!(folder; update = true)

@test cres_before != cres_after
@test ((:keep ∈ cres_before.idx) && (:keep ∈ cres_after.idx))
@test ((:delete ∈ cres_before.idx) && (:delete ∉ cres_after.idx))
@test cres_before.b[cres_before.idx .== :to_modify][1] == "original_value"
@test cres_after.b[cres_after.idx .== :to_modify][1] == "modified_value"

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

end
