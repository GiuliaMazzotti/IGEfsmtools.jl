using Dates
using CSV
using DataFrames
using NCDatasets
using Base: findall
using ArchGDAL
using GeoDataFrames
using DataStructures

list_id = [5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403]

df_meteo = Dataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_alpes_2018080106_2024080106.nc")
station_shapefile = ArchGDAL.read("C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp")
shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame  
shapefile = shapefile[in.(shapefile.ID, Ref(list_id)),:]

Nx = 434

# Selection of stations
selected_stations = sort(list_id)
stations = df_meteo["station"][:]
indices = findall(in(selected_stations), stations)
subset = Dict{String, Any}()
for (name, var) in df_meteo
    if ndims(var) == 2 && size(var, 1) == Nx
        subset[name] = var[indices, :]
        println(name)
        println(size(subset[name]))
    elseif ndims(var) == 1 && size(var, 1) == Nx
        subset[name] = var[indices]
        println(name)
        println(size(subset[name]))
    else
        subset[name] = var
        println(name)
        println(size(subset[name]))
    end
end

NCDataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_s2m_subset.nc", "c") do subset_ds
    n_stations = length(indices)
    n_time = size(df_meteo["time"], 1)
    defDim(subset_ds, "time", n_time)
    defDim(subset_ds, "Number_of_points", n_stations)
    for (name, data) in subset
        if name == "time"
            defVar(subset_ds, name, data, ("time",))
        elseif ndims(data) == 1 && name != "time"
            defVar(subset_ds, name, data, ("Number_of_points",))
        elseif ndims(data) == 2
            defVar(subset_ds, name, data, ("Number_of_points", "time"))
        else
            defVar(subset_ds, name, data)
        end
    end
end