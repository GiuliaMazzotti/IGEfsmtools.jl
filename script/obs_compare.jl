# Helper functions for comparing FSM point simulations against observed snow depth.

using NaNStatistics
using CairoMakie
CairoMakie.activate!()

function load_mdw_data(filepath::String, layer::Int = 1)
    if !isfile(filepath)
        error("File not found: $filepath")
    end

    mdw = matread(filepath)

    time = datenum2datetime.(mdw["MDW"]["MDW_data"][layer]["dobj"]["time"])
    acro = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["acro"]
    x = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["x"]
    y = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["y"]
    z = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["z"]
    data = mdw["MDW"]["MDW_data"][layer]["dobj"]["data"][:, :, 1]
    sel_stats = mdw["MDW"]["MDW_settings"][layer]["stats"]
    nodata_value = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["nan_value"]

    attributes = Dict(
        "acro" => acro,
        "sel_stats" => sel_stats,
        "x" => x,
        "y" => y,
        "z" => z,
        "nodata_value" => nodata_value,
    )

    return (time = time, data = data, attributes = attributes)
end

function align_data(obs, sim)

    # match time
    times = sort(intersect(obs.time, sim.time))
    i_obs = indexin(times, vec(obs.time))
    i_sim = indexin(times, vec(sim.time))

    # match stations
    qc = vec(obs.attributes["sel_stats"])
    obs_acro = vec(obs.attributes["acro"])
    sim_acro = vec(sim.attributes["locations"]["acro"])

    obs_set = Set(obs_acro)
    sim_set = Set(sim_acro)
    acros = [a for a in qc if a in obs_set && a in sim_set]

    j_obs = indexin(acros, obs_acro)
    j_sim = indexin(acros, sim_acro)

    # align data
    obs_aligned = obs.data[i_obs, j_obs]
    sim_aligned = sim.data[j_sim, 1, i_sim]
    sim_aligned = permutedims(sim_aligned, [2 1])

    # handle missing data
    i_missing = obs_aligned .== obs.attributes["nodata_value"]
    obs_aligned[i_missing] .= NaN
    sim_aligned[i_missing] .= NaN

    altitudes = vec(obs.attributes["z"])[j_obs]

    return (times = times, obs_aligned = obs_aligned, sim_aligned = sim_aligned, altitudes = altitudes)

end

bias(sim, obs) = nanmean(sim .- obs)
rmse(sim, obs) = sqrt(nanmean((sim .- obs) .^ 2))
r2(sim, obs) = nancor(obs, sim)^2

function plot_band_time_series(obs, sim)

    times, obs_aligned, sim_aligned, altitudes = align_data(obs, sim)

    # altitude data
    altitude_bands = [(0, 3000), (0, 500), (500, 1000), (1000, 1500), (1500, 2000), (2000, 2500), (2500, 3000)]

    # plot data

    f = Figure(size = (1200, 2000))
    band_axes = Axis[]
    for (b, (lo, hi)) in enumerate(altitude_bands)
        mask = lo .<= altitudes .<= hi
        obs_band = obs_aligned[:, mask]
        sim_band = sim_aligned[:, mask]
        # obs is reported in cm, sim in m — convert obs to m for comparison
        obs_mean_b = vec(nanmean(obs_band; dims = 2)) / 100
        sim_mean_b = vec(nanmean(sim_band; dims = 2))

        ax = Axis(f[b, 1]; ylabel = "HS [m]", title = "$(lo)–$(hi) m (n=$(count(mask)))")
        lines!(ax, times, obs_mean_b; label = "obs", color = :black, linewidth = 2.5)
        lines!(ax, times, sim_mean_b; label = "sim", color = :red)
        axislegend(ax; position = :rt)
        push!(band_axes, ax)

        bias_val = bias(sim_mean_b, obs_mean_b)
        rmse_val = rmse(sim_mean_b, obs_mean_b)
        r2_val = r2(sim_mean_b, obs_mean_b)
        stat_text = "RMSE: $(round(rmse_val, digits = 3)) m\n" *
            "Bias: $(round(bias_val, digits = 3)) m\n" *
            "R²:   $(round(r2_val, digits = 3))"
        Label(f[b, 2], stat_text; halign = :left, justification = :left, tellwidth = false, tellheight = false)
    end

    colsize!(f.layout, 2, Fixed(160))

    linkxaxes!(band_axes...)
    for ax in band_axes[1:(end - 1)]
        hidexdecorations!(ax; ticks = false, grid = false)
    end
    band_axes[end].xlabel = "time"

    return f

end

"""
    subset_domain(dom_data, keep)

Return a deep copy of the station-domain dict restricted to the station indices in `keep`.
"""
function subset_domain(dom_data::Dict, keep)
    d = deepcopy(dom_data)
    nstat = length(vec(d["attributes"]["vector"]["acro"]))

    # top-level per-station landuse arrays: ["variable"]["data"] with first dim == nstat
    for (_, v) in d
        v isa Dict || continue
        haskey(v, "data") || continue
        arr = v["data"]
        arr isa AbstractArray || continue
        size(arr, 1) == nstat || continue
        v["data"] = ndims(arr) == 1 ? arr[keep] : arr[keep, :]
    end

    # per-station label arrays under attributes["locations"] / attributes["vector"]
    OSHDinternal.crop_fixture_attributes!(d["attributes"], keep, keep, nstat)

    return d
end