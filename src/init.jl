function init_grid!(settings::Dict)

  # read meteo file
  meteo_file = Dataset(settings["file_path"]) # Dataset() ?

  Nx = meteo_file.dim["x"]
  Ny = meteo_file.dim["y"]
  time = meteo_file["time"]

  # set landuse properties
  lus = Dict()
  lus["skyvf"] = Dict("data" => [fill(1.0, Nx);;])           
  lus["x"] = Dict("data" => [meteo_file["LON"];;])
  lus["y"] = Dict("data" => [meteo_file["LAT"];;])
  lus["elevation"] = Dict("data" => [meteo_file["ZS"];;])
  lus["slopemu"] = Dict("data" => [fill(1.0, Nx);;])
  lus["xi"] = Dict("data" => [fill(1.0, Nx);;])
  lus["Ld"] = Dict("data" => [fill(1.0, Nx);;])
  lus["prec_multi"] = Dict("data" => [fill(1.0, Nx);;])
  lus["landcover"] = Dict("data" => [meteo_file["landcover"];;])  

  merge!(settings, Dict("Nx" => Nx, "Ny" => Ny, "x" => meteo_file["x"], "y" => meteo_file["y"]))

  close(meteo_file)

  return lus, Nx, Ny, time
end

function init_poste!(settings::Dict)
    # read meteo file
  meteo_file = Dataset(settings["file_path"]) # Dataset() ?
  station_shapefile = ArchGDAL.read(settings["shapefile"])
  shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame 
  Tinit = Dataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/Tinit_allstations_alpes_1958080106_2024080106.nc")

  Nx = meteo_file.dim["Number_of_points"]
  Ny = 1
  time = meteo_file["time"]

  if  ! (list_id == "all")
    shapefile = shapefile[in.(shapefile.ID, Ref(list_id)),:]
    sort!(shapefile, [:ID])
    mask = [s in list_id for s in Tinit["Number_of_points"][:]]
    Tinit = Tinit["Tair"][:][mask]
    id_point = list_id
  else
    sort!(shapefile, [:ID])
    id_point = shapefile.ID
  end

  # set landuse properties
  lus = Dict()
  lus["skyvf"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])           
  lus["x"] = Dict("data" => [shapefile.Longitude;;])
  lus["y"] = Dict("data" => [shapefile.Latitude;;])
  lus["elevation"] = Dict("data" => [shapefile.Elevation;;])
  lus["slopemu"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
  lus["xi"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
  lus["Ld"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
  lus["prec_multi"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])

  merge!(settings, Dict("Tinit" => Tinit, "Nx" => Nx, "Ny" => Ny, "id_point" => id_point))

  close(meteo_file)
  close(station_shapefile)
  close(shapefile)
  close(Tinit)

  return lus, Nx, Ny, time
end

function init_point!(settings::Dict)
  # read meteo file
  meteo_file = Dataset(settings["file_path"]) # Dataset() ?

  Nx = meteo_file.dim["Number_of_points"]
  Ny = 1
  time = meteo_file["time"][:]

  # set landuse properties
  lus = Dict()
  lus["skyvf"] = Dict("data" => [fill(1.0, Nx);;])           
  lus["x"] = Dict("data" => [meteo_file["LON"];;])
  lus["y"] = Dict("data" => [meteo_file["LAT"];;])
  lus["elevation"] = Dict("data" => [meteo_file["ZS"];;])
  lus["slopemu"] = Dict("data" => [fill(1.0, Nx);;])
  lus["xi"] = Dict("data" => [fill(1.0, Nx);;])
  lus["Ld"] = Dict("data" => [fill(1.0, Nx);;])
  lus["prec_multi"] = Dict("data" => [fill(1.0, Nx);;])
  
  merge!(settings, Dict("Nx" => Nx, "Ny" => Ny, "id_point" => meteo_file["station"][:]))

  close(meteo_file)

  return lus, Nx, Ny, time
end

