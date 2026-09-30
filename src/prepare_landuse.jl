function prepare_landuse(settings::Dict)

    station_shapefile = ArchGDAL.read(settings["shapefile"])
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame

    if  ! (settings["list_id"] == "all")
        shapefile = shapefile[in.(shapefile.ID, Ref(settings["list_id"])),:]
        sort!(shapefile, [:ID])
    else
        sort!(shapefile, [:ID])
    end

    Nx = size(shapefile.Elevation[:], 1)
    Ny = size(shapefile.Elevation[:], 2)

    # set landuse properties
    lus = Dict()
    lus["skyvf"] = Dict("data" => fill(1.0, Nx))
    lus["elevation"] = Dict("data" => shapefile.Elevation[:])
    lus["slopemu"] = Dict("data" => fill(1.0, Nx))
    lus["xi"] = Dict("data" => fill(1.0, Nx))
    lus["Ld"] = Dict("data" => fill(1.0, Nx))
    lus["prec_multi"] = Dict("data" => fill(1.0, Nx))

    return lus, Nx, Ny
end
