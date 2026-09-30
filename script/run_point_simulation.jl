## Function section
# include("../src/IGEfsmtools.jl")
using IGEfsmtools
using FlexibleSnowModelOSHD
using Infiltrator
using NCDatasets

"""
    preload_forcing(times, run_id, settings_domain, settings_common,
                    prec_multi, dt, met_host, keep, Tf, verbose = true)

Run the operational meteo reader (`read_input!`) once over all time steps and snapshot the
fully-processed forcing for the selected stations `keep`.
"""
function preload_forcing(settings, Tf)

    meteo_file = Dataset(settings["file_path"]) 
    time = meteo_file["time"][:]
    stations = meteo_file["station"][:]

    ntimes = length(time)
    if  ! (settings["list_id"] == "all") 
        nstations = length(settings["list_id"])
        mask = indexin(settings["list_id"], meteo_file["station"][:])
        mask = Int64.(filter(!isnothing, mask))

        DIR_SW    = meteo_file["DIR_SWdown"][mask,:]           
        SCA_SW    = meteo_file["SCA_SWdown"][mask,:]
        LWdown    = meteo_file["LWdown"][mask,:]
        Snowf     = meteo_file["Snowf"][mask,:]
        Rainf     = meteo_file["Rainf"][mask,:]
        Tair      = meteo_file["Tair"][mask,:]
        Qair      = meteo_file["Qair"][mask,:]
        Wind      = meteo_file["Wind"][mask,:]
        PSurf     = meteo_file["PSurf"][mask,:]

    else 
        nstations = length(stations)

        DIR_SW    = meteo_file["DIR_SWdown"]           
        SCA_SW    = meteo_file["SCA_SWdown"]
        LWdown    = meteo_file["LWdown"]
        Snowf     = meteo_file["Snowf"]
        Rainf     = meteo_file["Rainf"]
        Tair      = meteo_file["Tair"]
        Qair      = meteo_file["Qair"]
        Wind      = meteo_file["Wind"]
        PSurf     = meteo_file["PSurf"]
    end
    
    alloc() = zeros(Tf, nstations, ntimes)
    forcing = (
        Sdir = alloc(), Sdif = alloc(), Sdird = alloc(), LW = alloc(),
        Rf = alloc(), Sf = alloc(), Ta = alloc(), RH = alloc(),
        Ua = alloc(), Ps = alloc(), Sf24h = alloc(),
    )

    forcing.Sdir[:, :] = DIR_SW
    forcing.Sdif[:, :] = SCA_SW
    forcing.Sdird[:, :] = DIR_SW
    forcing.LW[:, :] = LWdown
    forcing.Rf[:, :] = Rainf 
    forcing.Sf[:, :] = Snowf
    forcing.Ta[:, :] = Tair
    forcing.RH[:, :] = Qair
    forcing.Ua[:, :] = Wind
    forcing.Ps[:, :] = PSurf
    forcing.Sf24h[:, :] = (c = cumsum(Snowf .* 3600, dims=2); c .- [zeros(size(c,1), 24) c[:, 1:end-24]]) 

    return forcing, time
end

"""
    run_simulation(forcing, landuse, times, settings, Tf, verbose = true)

Run simulation using cached operational forcing.
"""
function run_simulation(forcing, landuse, times, settings, Tf, verbose = true)

    # Setup model on the selected stations
    nstat = size(landuse["elevation"]["data"], 1)
    grid = Grid(Tf; Nx = nstat, Ny = 1)
    # build_physics!(grid, settings, landuse)
    fsm = setup(grid, landuse, settings)
    met = MET{Tf}(Nx = nstat)

    # Pre-allocate results
    snowdepth = zeros(length(times), size(fsm.state.Ds, 2))

    progress_bar = verbose ? Progress(length(times), desc = "Running snow model...") : nothing

    for (i, t) in enumerate(times)

        # Inject pre-processed operational forcing
        met.Sdir[:, :] .= forcing.Sdir[i, :]
        met.Sdif[:, :] .= forcing.Sdif[i, :]
        met.Sdird[:, :] .= forcing.Sdird[i, :]
        met.LW[:, :] .= forcing.LW[i, :]
        met.Rf[:, :] .= forcing.Rf[i, :]
        met.Sf[:, :] .= forcing.Sf[i, :]
        met.Ta[:, :] .= forcing.Ta[i, :]
        met.RH[:, :] .= forcing.RH[i, :]
        met.Ua[:, :] .= forcing.Ua[i, :]
        met.Ps[:, :] .= forcing.Ps[i, :]
        met.Sf24h[:, :] .= forcing.Sf24h[i, :]

        # Run model step
        step!(fsm, met, t)

        # Store results
        snowdepth[i, :] = dropdims(sum(fsm.state.Ds, dims = 1), dims = 3)

        if verbose
            next!(progress_bar)
        end
    end

    return snowdepth
end

## Setup section

Tf = Float32
verbose = true

settings_init = settings["INIT"]
settings_tuning = settings["TUNING"]

landuse, Nx, Ny = prepare_landuse(settings_init)

met = MET{Tf}(Nx = Nx, Ny = Ny)
prec_multi = landuse["prec_multi"]["data"]
dt = FlexibleSnowModelOSHD.Parameters{Tf}().dt

forcing, time = preload_forcing(settings_init, Tf)


## Tuning section

# for adn = 1 2 3
settings_simu = deepcopy(settings_tuning)
settings_simu["physics"]["snow_albedo"] = scheme(PrognosticAlbedo; ALRADT= false, adm = 130, adc = ElevationTuned((1500, 2300), (3000, 6000)))
settings_simu["params"] = Dict("z0_snow" => ElevationTuned((1500, 2300), (0.2, 0.01)))

@infiltrate

snowdepth = run_simulation(forcing, landuse, time, settings_simu, Tf, verbose)


