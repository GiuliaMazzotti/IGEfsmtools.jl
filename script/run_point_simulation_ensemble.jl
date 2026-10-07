## Function section
# include("../src/IGEfsmtools.jl")
using IGEfsmtools
using FlexibleSnowModelOSHD
using Infiltrator
using NCDatasets
using ProgressMeter
using ArchGDAL
using DataFrames


"""
    preload_forcing(times, run_id, settings_domain, settings_common,
                    prec_multi, dt, met_host, keep, Tf, verbose = true)

Run the operational meteo reader (`read_input!`) once over all time steps and snapshot the
fully-processed forcing for the selected stations `keep`.
"""
function get_station_name(list_id, shapefile_path)
    station_shapefile = ArchGDAL.read(shapefile_path)
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame 
    shp = shapefile[in.(shapefile.ID, Ref(list_id)),:]
    sort!(shp, [:ID])
    return vec(shp.Name)
end

function get_station_massif(list_id, shapefile_path)
    station_shapefile = ArchGDAL.read(shapefile_path)
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame 
    shp = shapefile[in.(shapefile.ID, Ref(list_id)),:]
    sort!(shp, [:ID])
    return vec(shp.massif_num)
end

function preload_forcing(settings, Tf)

    meteo_file = Dataset(settings["file_path"]) 
    time = meteo_file["time"][:]
    stations = meteo_file["station"][:]

    ntimes = length(time)
    if  ! (settings["list_id"] == "all") 
        nstations = length(settings["list_id"])
        mask = indexin(sort(settings["list_id"]), meteo_file["station"][:])
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
        Alt       = meteo_file["ZS"][mask]

    else 
        settings["list_id"] = stations
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
        Alt       = meteo_file["ZS"]
    end

    settings["alt"] = vec(Alt)
    settings["name"] = get_station_name(settings["list_id"], settings["shapefile"])
    settings["massif"] = get_station_massif(settings["list_id"], settings["shapefile"])

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
    build_physics!(grid, settings, landuse)
    physics = get(settings, "physics", Dict())
    schemes = (; (Symbol(k) => v for (k, v) in physics)...)
    fsm = FSM(grid, landuse; schemes...)
    apply_params!(fsm, settings["params"])
    met = MET{Tf}(Nx = nstat)

    # Pre-allocate results
    snowdepth = zeros(length(times), size(fsm.state.Ds, 2))

    progress_bar = verbose ? Progress(length(times), desc = "Running snow model...") : nothing

    for (i, t) in enumerate(times)

        # Inject pre-processed operational forcing
        met.Sdir[:, :] .= forcing.Sdir[:, i]
        met.Sdif[:, :] .= forcing.Sdif[:, i]
        met.Sdird[:, :] .= forcing.Sdird[:, i]
        met.LW[:, :] .= forcing.LW[:, i]
        met.Rf[:, :] .= forcing.Rf[:, i]
        met.Sf[:, :] .= forcing.Sf[:, i] .*landuse["prec_multi"]["data"]
        met.Ta[:, :] .= forcing.Ta[:, i]
        met.RH[:, :] .= forcing.RH[:, i]
        met.Ua[:, :] .= forcing.Ua[:, i]
        met.Ps[:, :] .= forcing.Ps[:, i]
        met.Sf24h[:, :] .= forcing.Sf24h[:, i]

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

function run_comparison(settings, obs, runs, Tf; verbose = true)
    all_metrics = DataFrame[]
    sims = Pair{String, Any}[]

    forcing, times = preload_forcing(settings["INIT"], Tf)

    for (name, overrides) in runs
        s = apply_overrides(settings, overrides)
        settings_init, settings_tuning = s["INIT"], s["TUNING"]

        landuse, Nx, Ny = prepare_landuse(settings_init)
        snowdepth = run_simulation(forcing, landuse, times, settings_tuning, Tf, verbose)

        run_id, _ = set_run_id(s)
        log_run("C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/runs_tuning.md", run_id, s)

        sim = (
            time = collect(times), 
            data = snowdepth, 
            id = sort(settings_init["list_id"]),
            alt = settings_init["alt"], 
            name = settings_init["name"],
            massif = settings_init["massif"]
            )

        push!(all_metrics, station_metrics(obs, sim, name, run_id))
        push!(sims, name => sim)
    end

    metrics = reduce(vcat, all_metrics)
    # CSV.write("C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/precip/metrics_precip.csv", metrics; header = ["config", "run_id", "id", "altitude", "massif", "band_lo", "n_days", "rmse", "bias", "r2"])
    CSV.write(settings_path["metrics"], metrics; header = ["config", "run_id", "id", "altitude", "massif", "band_lo", "n_days", "rmse", "bias", "r2"], append=true)
    return sims, metrics
end


## Setup section

Tf = Float32
verbose = true
include("obs_compare.jl")
include("tuning_track.jl")

## Settings of tuning

runs = [
    # # precipitation settings
    # "raw"    => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0, cst = 1)],
    # "linear" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = -0.000215, cst = 1.52)],
    # "log"    => [("INIT", "prec_multi") => scheme(LogbisPrecip; mult1 = -0.0156, mult2 = 0.42, cst = 50)],
    # "tanh"   => [("INIT", "prec_multi") => scheme(TanhPrecip;)],

    # z0 settings
    "raw" => [],
    "z0.001" => [("TUNING", "params", "z0_snow") => 0.001],
    "z0.005" => [("TUNING", "params", "z0_snow") => 0.005],

    # # other settings, alone or combined
    # "tanh + albedo" => [
    #     ("INIT", "prec_multi") => scheme(TanhPrecip;),
    #     ("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, adm = 130,
    #                                                      adc = ElevationTuned((1500, 2300), (3000, 6000))),
    # ],
    # "tanh + z0" => [
    #     ("INIT", "prec_multi") => scheme(TanhPrecip;),
    #     ("TUNING", "params", "z0_snow") => ElevationTuned((1500, 2300), (0.2, 0.01)),
    # ],
]

## Combinations of tuning
# product_runs(groups...) = vec([
#     join(first.(c), " | ") => reduce(vcat, last.(c))
#     for c in Iterators.product(groups...)
# ])

# precips = [
#     "linear" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0, cst = 1)],
#     "tanh"   => [("INIT", "prec_multi") => scheme(TanhPrecip;)],
# ]
# albedos = [
#     "alb default" => Pair{Tuple,Any}[],        # no override = keep the base setting
#     "alb elev"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, adm = 130,
#                                                                       adc = ElevationTuned((1500, 2300), (3000, 6000)))],
# ]

# runs = product_runs(precips, albedos)   # 4 runs, named "linear | alb default", ...

## Run simulations
obs = load_csv_data("C:/Users/navarrel/Documents/Workspace/Data/obs/nivo/OBS_1980_2025.csv")

sims, metrics = run_comparison(settings, obs, runs, Float32)

# altitude bands, as before
ALT_BANDS = [(0, 3000), (0, 500), (500, 1000), (1000, 1500), (1500, 2000), (2000, 2500), (2500, 3000)]
save(settings_path["alt_band"], plot_runs(obs, sims; groups = band_groups(ALT_BANDS)))

# a few single stations in one figure
names = station_names(last(first(sims)))
ids = sort(settings["INIT"]["list_id"])                              # your station ids
save(settings_path["multi_station"],
     plot_runs(obs, sims; groups = station_groups(ids, names), fsize = (1200, 300 * length(ids))))

# one figure per station, without rerunning the model
for id in ids
    f = plot_runs(obs, sims; groups = station_groups([id], names), fsize = (1200, 500))
    save(settings_path["single_station"]*"$(id).png", f)
end

include("config_compare.jl")
