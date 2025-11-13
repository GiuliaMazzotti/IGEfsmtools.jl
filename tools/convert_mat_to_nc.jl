using MAT
using NCDatasets
using Dates
using ProgressMeter

searchdir(path, key) = filter(x -> occursin(key, x), readdir(path))

folder_matfiles = "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/OUTPUT_GRID_GALE_0100/PROCESSED_ANALYSIS/COSMO_1EFA"

folder_ncfiles = "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/ncfiles"

times = DateTime(2022,9,1,6):Hour(1):DateTime(2023,9,1)

@showprogress for t in times

    # Read matfile
    folder_source = joinpath(folder_matfiles, Dates.format(t, "yyyy.mm"))
    filename_mat = searchdir(folder_source, "COSMODATA_" * Dates.format(t, "yyyymmddHHMM"))
    data = matread(joinpath(folder_source, filename_mat[1]))

    # Prepare ncfile
    folder_target = joinpath(folder_ncfiles, Dates.format(t, "yyyy.mm"))
    isdir(folder_target) || mkpath(folder_target)
    filename_nc = replace(filename_mat[1], ".mat" => ".nc")

    # Create ncfile

    NCDatasets.Dataset(joinpath(folder_target, filename_nc), "c") do ds
        defDim(ds, "easting", Int(data["ncols"]))
        defDim(ds, "northing", Int(data["nrows"]))

        for (var_name, var_data) in data
            if isa(var_data, Dict)
                v = defVar(ds, var_name, Float64, ("northing", "easting"); deflatelevel = 4, shuffle=true)
                v[:, :] = data[var_name]["data"]
            end
        end
    end

end
