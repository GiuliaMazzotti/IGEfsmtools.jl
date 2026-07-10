# IGEfsmtools.jl

FSM running wrappers and example from SLF.

## Structure
The only useful script for users is `script/run.jl`.
This wrapper calls subscripts to:
   - Launch the simulation `run_simu.jl`
   - Initialize the simulation settings `src/init.jl`
   - Read meteo file at each step `meteo_readers.jl`
   - Save the output `output.jl`

## Simulation categories
Different simulations categories are available. 
For now, it is possible to run both 1D and 2D simulations. 
1D simulations are either -> post simulations (directly forced by S2M post reanalysis)
                          -> point simulations (forced by interpolated forcings at chosen sites)
2D simulations are either -> grid simulations (hourly time step)
                          -> daily grid simulations (daily time step)

## Launching FSM
All modifications to launch FSM simulation are done in `script/run.jl`.

1. **Settings definition:**
Definition of the meteorological forcings file => "file_path"
Definition of the output variables desired => "output_vars"
Definition of the output file name => "out_file"

¨¨only for point simulations¨¨
Definition of landcover => "landcover" (glacier:Int32(2), ground:Int32(1)) 

¨¨only for S2M posts simulations¨¨
Definition of selected posts => "list_id"
Definition of the shapefile path => "shapefile"

¨¨others, to leave as it is¨¨
"tile"
"config"
"params"

2. **Simulation type definition:**
Definition of the simulation type :
*run_grid_simulation(settings=settings)
*run_grid_daily_simulation(settings=settings) 
*run_poste_simulation(settings=settings) => list_id, shapefile
*run_point_simulation(settings=settings)

## Examples

A simulation representing ground points :

```julia
const settings = Dict(
    "tile" => "open",
    "config" => Dict(),
    "params" => Dict("dt" => 3600, "zT" => 1.5, "zU" => 5.0, "zRH" => 1.5), #"tcld", "tmlt", "Sfmin" => 15, "bstb" => 8
    "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/balises/mask_balises_lautaret_bioclim/meteo/FORCING_1998080106_2023080106.nc", # change it
    "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
    "list_id" => [5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], #"all", # for s2m poste only
    "landcover" => Int32(1), # only for glacier simu (now only adapted in init_point)
    "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/gblanc/balises/output_1998-2023_S2M_balises_lautaret_bioclim.nc",
    "output_vars" => ["Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "SWE", "Sbsrf", "meltflux_out", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4"],
)

run_point_simulation(settings=settings)
```


In a terminal, launch the simulation:

```julia
include("script/run.jl")
```
