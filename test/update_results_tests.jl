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
#                           Trailing slash in foldername                      #
###############################################################################

df = collect_results!(datadir("results/"))      # This would produce the incorrect file. (Issue#181)

pathtofile=datadir("results/results_.jld2")     # 
@test !isfile(pathtofile)

if isfile(pathtofile)
    rm(pathtofile)                              # In case this test failed, remove the file to not compromise other tests.
end

###############################################################################
#                           Include or exclude files                          #
###############################################################################

@test_throws AssertionError collect_results(datadir("results"); rinclude=["a=1"])

df = collect_results(datadir("results"); rinclude=[r"a=1", r"b=3"])
@test all(row -> row["a"] == 1 || row["b"] == "2", eachrow(df))

df = collect_results(datadir("results"); rexclude=[r"a=3"])
@test all(df[:,"a"] .!== 3)

df = collect_results(datadir("results"); rinclude=[r"a=3"], rexclude=[r"a=3"])
@test isempty(df)

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

@testset "Test updating feature $(mtime_info)" for mtime_info in ["with mtime", "without initial update", "without mtime", "with corrupt mtime"]
    # Create a temp directory and run the tests, creating files in that folder
    # Julia takes care of removing the folder after the function is done.
    mktempdir(datadir()) do folder
        # Create three data files with slightly different data
        d = Dict("idx" => :keep, "b" => "some_value")
        fname_keep = joinpath(folder, savename(d, ending, ignores = ("b",)))
        DrWatson.wsave(fname_keep, d)

        d = Dict("idx" => :delete, "b" => "some_other_value")
        fname_delete = joinpath(folder, savename(d, ending, ignores = ("b",)))
        DrWatson.wsave(fname_delete, d)

        d = Dict("idx" => :to_modify, "b" => "original_value")
        fname_modify = joinpath(folder, savename(d, ending, ignores = ("b",)))
        DrWatson.wsave(fname_modify, d)

        # Collect our "results"
        if mtime_info == "without initial update"
            # Test this case: https://github.com/JuliaDynamics/DrWatson.jl/pull/286#pullrequestreview-755999610
            cres_before = collect_results!(folder; update = false)
        else
            cres_before = collect_results!(folder; update = true)
        end

        if mtime_info == "without mtime"
            # Leave out the mtime information to simulate old results collection.
            wsave(joinpath(dirname(folder), "results_$(basename(folder)).jld2"), Dict("df" => cres_before))
        elseif mtime_info == "with corrupt mtime"
            # Corrupt mtime information
            wsave(joinpath(dirname(folder), "results_$(basename(folder)).jld2"), Dict("df" => cres_before, "mtime" => Dict{String,Float64}()))
        else
            # Modify one data file
            d = Dict("idx" => :to_modify, "b" => "modified_value")
            DrWatson.wsave(fname_modify, d)

            # Delete another data file
            rm(fname_delete)
        end

        # Collect the "results" again
        if (mtime_info == "without mtime") || (mtime_info == "with corrupt mtime") 
            @test_throws DrWatson.InvalidResultsCollection collect_results!(folder; update = true)
        else
            cres_after = collect_results!(folder; update = true)

            # Compare the before and after - they should differ
            @test cres_before[:,[:idx, :b]] != cres_after[:,[:idx, :b]]
            # The unmodified entry should be the same
            @test ((:keep ∈ cres_before.idx) && (:keep ∈ cres_after.idx))
            # The deleted entry should be gone
            @test ((:delete ∈ cres_before.idx) && (:delete ∉ cres_after.idx))
            # The modified entry should differ between before and after
            @test cres_before.b[cres_before.idx .== :to_modify][1] == "original_value"
            @test cres_after.b[cres_after.idx .== :to_modify][1] == "modified_value"
        end
    end
end

###############################################################################
#                           test jldopen                                      #
###############################################################################

mktempdir(datadir()) do folder
    # Create a data file
    d = Dict("idx" => 1, "value" => rand(100000))
    fname = joinpath(folder, savename(d, ending, ignores = ("value",)))
    DrWatson.wsave(fname, d)

    if ending == "jld2"
        msg_re = r"Opening .* with jldopen."
    else
        msg_re = r"Opening .* with fallback wload."
    end
    @test_logs (:debug, msg_re) min_level=Base.CoreLogging.Debug match_mode=:any cres = collect_results(folder, black_list = ("value",))

    @test cres.idx[1] == 1 # It's what we've saved above.
    @test size(cres,1) == 1 # only one file
    @test size(cres,2) == 2 # idx and path
end

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
