function init_grid!(settings::Dict)

  # read meteo file
  meteo_file = Dataset(settings["file_path"]) 

  Nx = meteo_file.dim["x"]
  Ny = meteo_file.dim["y"]
  time = meteo_file["time"][:]

  # set landuse properties
  lus = Dict()
  lus["skyvf"] = Dict("data" => fill(1.0, Nx, Ny))    
  lus["elevation"] = Dict("data" => meteo_file["ZS"][:,:])
  lus["slopemu"] = Dict("data" => fill(1.0, Nx, Ny))
  lus["xi"] = Dict("data" => fill(1.0, Nx, Ny))
  lus["Ld"] = Dict("data" => fill(1.0, Nx, Ny))
  lus["prec_multi"] = Dict("data" => fill(1.0, Nx, Ny))

  merge!(settings, Dict("Nx" => Nx, "Ny" => Ny, "x" => meteo_file["x"][:], "y" => meteo_file["y"][:]))

  grid = Grid(settings["precision"]; Nx = Nx, Ny = Ny)
  params = FlexibleSnowModelOSHD.Parameters{Float32}(zT=1.5, zU=5, zRH=1.5)
  fsm = FSM(grid, lus, params=params)

  met = MET{settings["precision"]}(Nx=Nx, Ny=Ny)

  close(meteo_file)

  return fsm, met, time
end

# function init_glacier_grid!(settings::Dict)

#   # read meteo file
#   meteo_file = Dataset(settings["file_path"]) 

#   Nx = meteo_file.dim["x"]
#   Ny = meteo_file.dim["y"]
#   time = meteo_file["time"][:]

#   # set landuse properties
#   lus = Dict()
#   lus["skyvf"] = Dict("data" => [fill(1.0, Nx);;])           
#   lus["x"] = Dict("data" => [meteo_file["LON"];;])
#   lus["y"] = Dict("data" => [meteo_file["LAT"];;])
#   lus["elevation"] = Dict("data" => [meteo_file["ZS"];;])
#   lus["slopemu"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["xi"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["Ld"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["prec_multi"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["landcover"] = Dict("data" => [meteo_file["landcover"];;])  

#   merge!(settings, Dict("Nx" => Nx, "Ny" => Ny, "x" => meteo_file["x"][:], "y" => meteo_file["y"][:]))

#   grid = Grid(settings["precision"]; Nx = Nx, Ny = Ny)
#   fsm = FSM(grid, lus)
#   fsm.params = IGEfsmtools.FlexibleSnowModelOSHD.reconstruct(fsm.params; zT=1.5, zU=5, zRH=1.5) # , Tprof=Tinit
#   # land_cover ?

#   met = MET{settings["precision"]}(Nx=Nx, Ny=Ny)

#   close(meteo_file)

#   return lus, Nx, Ny, time
# end

function init_poste!(settings::Dict)
  # read meteo file
  meteo_file = Dataset(settings["file_path"]) 
  station_shapefile = ArchGDAL.read(settings["shapefile"])
  shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame 
  Tinit = Dataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/Tinit_allstations_alpes_1958080106_2024080106.nc")

  time = meteo_file["time"][:]

  # selection of stations 
  if  ! (settings["list_id"] == "all")
    shapefile = shapefile[in.(shapefile.ID, Ref(settings["list_id"])),:]
    sort!(shapefile, [:ID])
    mask = [s in settings["list_id"] for s in Tinit["Number_of_points"][:]]
    Tinit = Tinit["Tair"][:][mask]
    id_point = sort!(settings["list_id"])
    mask_met = indexin(settings["list_id"], meteo_file["station"][:])
    mask_met = Int64.(filter(!isnothing, mask_met))

    Nx = size(shapefile)[1]
    Ny = 1

    merge!(settings, Dict("Tinit" => Tinit, "Nx" => Nx, "Ny" => Ny, "id_point" => id_point, "mask" => mask_met))

  else
    sort!(shapefile, [:ID])
    Tinit = Tinit["Tair"][:]
    id_point = shapefile.ID

    Nx = size(shapefile)[1]
    Ny = 1

    merge!(settings, Dict("Tinit" => Tinit, "Nx" => Nx, "Ny" => Ny, "id_point" => id_point))
  end

  # set landuse properties
  lus = Dict()
  lus["skyvf"] = Dict("data" => fill(1.0, Nx))    
  lus["elevation"] = Dict("data" => shapefile.Elevation[:])
  lus["slopemu"] = Dict("data" => fill(1.0, Nx))
  lus["xi"] = Dict("data" => fill(1.0, Nx))
  lus["Ld"] = Dict("data" => fill(1.0, Nx))
  lus["prec_multi"] = Dict("data" => fill(1.0, Nx))

  grid = Grid(settings["precision"]; Nx = Nx, Ny = Ny)
  params = FlexibleSnowModelOSHD.Parameters{Float32}(zT=1.5, zU=5, zRH=1.5)
  fsm = FSM(grid, lus, params=params)

  met = MET{settings["precision"]}(Nx=Nx, Ny=Ny)

  close(meteo_file)

  return fsm, met, time
end

# function init_point!(settings::Dict)
#   # read meteo file
#   meteo_file = Dataset(settings["file_path"]) # Dataset() ?

#   Nx = meteo_file.dim["Number_of_points"][:]
#   Ny = 1
#   time = meteo_file["time"][:]

#   # set landuse properties
#   lus = Dict()
#   lus["skyvf"] = Dict("data" => [fill(1.0, Nx);;])           
#   lus["x"] = Dict("data" => [meteo_file["LON"][:];;])
#   lus["y"] = Dict("data" => [meteo_file["LAT"][:];;])
#   lus["elevation"] = Dict("data" => [meteo_file["ZS"][:];;])
#   lus["slopemu"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["xi"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["Ld"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["prec_multi"] = Dict("data" => [fill(1.0, Nx);;])
#   # lus["glacier"] = Dict("data" => [fill(1.0, Nx);;])
#   lus["landcover"] = Dict("data" => [ones(Int32, Nx, Ny).*settings["landcover"][:];;])
  
#   merge!(settings, Dict("Nx" => Nx, "Ny" => Ny, "id_point" => meteo_file["station"][:]))

#   close(meteo_file)

#   return lus, Nx, Ny, time
# end

