function prepare_landuse(settings::Dict)

    station_shapefile = ArchGDAL.read(settings["shapefile"])
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame

    if  ! (settings["list_id"] == "all")
        shapefile = shapefile[in.(shapefile.ID, Ref(settings["list_id"])),:]
        sort!(shapefile, [:ID])
    else
        sort!(shapefile, [:ID])
    end

    if settings["prec_multi"] isa IGEfsmtools.SchemeSpec{MaxBiasPrecip}
        precip_file = CSV.read("C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/stations/metrics_max_hs.csv", DataFrame;).factor[:]
    else 
        precip_file = shapefile.Elevation[:]
    end

    Nx = size(shapefile.Elevation[:], 1)
    Ny = size(shapefile.Elevation[:], 2)

    # set landuse properties
    lus = Dict()
    lus["skyvf"] = Dict("data" => shapefile.sky_view1[:])
    lus["elevation"] = Dict("data" => shapefile.Elevation[:])
    lus["slopemu"] = Dict("data" => fill(1.0, Nx))
    lus["xi"] = Dict("data" => fill(1.0, Nx))
    lus["Ld"] = Dict("data" => fill(1.0, Nx))
    lus["prec_multi"] = Dict("data" => precip_cor(build_precip(settings["prec_multi"], settings["precision"]), precip_file)) #precip_cor(build_precip(settings["prec_multi"], settings["precision"]), shapefile.Elevation[:]) #fill(1.0, Nx) .*settings["prec_multi"] #settings["prec_multi"]{settings["precision"]}()

    return lus, Nx, Ny
end
