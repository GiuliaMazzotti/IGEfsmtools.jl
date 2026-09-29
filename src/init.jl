# OSHD-tuned (SNOPRP=1) elevation-dependent snow surface properties, matching the
# defaults of the pre-GPU model (FlexibleSnowModelOSHD.jl, giulia-glacier_devs, setup.jl,
# "Tuned snow surface properties" branch). The GPU port's defaults (PrognosticAlbedo's
# adm/adc, and Surface's z0_snow) instead correspond to that model's SNOPRP=0 (untuned)
# branch, so they must be constructed explicitly here to reproduce old behaviour.

# Cold-snow albedo decay time (h): 3000h at/below 1500 m, 6000h at/above 2300 m, linear between.
function tuned_adc(dem::AbstractArray{Tf}) where {Tf<:Real}
  adc = Tf(6000) .+ (Tf(2300) .- dem) ./ (Tf(2300) - Tf(1500)) .* (Tf(3000) - Tf(6000))
  adc[dem .>= Tf(2300)] .= Tf(6000)
  adc[dem .<= Tf(1500)] .= Tf(3000)
  return adc
end

# Open-terrain snow roughness length (m): 0.2 m at/below 1500 m, 0.01 m at/above 2300 m, linear between.
function tuned_z0_snow(dem::AbstractArray{Tf}) where {Tf<:Real}
  z0_snow = fill(Tf(0.2), size(dem))
  mask = dem .>= Tf(1500)
  z0_snow[mask] .= Tf(0.2) .+ (dem[mask] .- Tf(1500)) ./ (Tf(2300) - Tf(1500)) .* (Tf(0.01) - Tf(0.2))
  z0_snow[dem .>= Tf(2300)] .= Tf(0.01)
  return z0_snow
end

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

  dem = Float32.(lus["elevation"]["data"])
  snow_albedo = PrognosticAlbedo{Float32}(grid; adm=Float32(130), adc=tuned_adc(dem))

  fsm = FSM(grid, lus, params=params, snow_albedo=snow_albedo)
  fsm.surface.z0_snow .= tuned_z0_snow(dem)

  # Initial soil temperature: override models defaults using settings["Tinit"] (default 273.15 K).
  Tinit = Float32(get(settings, "Tinit", 273.15))
  fsm.state.Tsoil .= min(Tinit, Float32(273.15))


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

  dem = reshape(Float32.(lus["elevation"]["data"]), Nx, Ny) # Surface/PrognosticAlbedo fields are (Nx, Ny) matrices
  snow_albedo = PrognosticAlbedo{Float32}(grid; adm=Float32(130), adc=tuned_adc(dem))

  fsm = FSM(grid, lus, params=params, snow_albedo=snow_albedo)
  fsm.surface.z0_snow .= tuned_z0_snow(dem)

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

