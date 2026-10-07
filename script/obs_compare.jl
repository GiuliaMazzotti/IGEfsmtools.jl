# Helper functions for comparing FSM point simulations against observed snow depth.

using CSV
using DataFrames
using NaNStatistics
using Dates
using Statistics
using CairoMakie
CairoMakie.activate!()

# function load_mdw_data(filepath::String, layer::Int = 1)
#     if !isfile(filepath)
#         error("File not found: $filepath")
#     end

#     mdw = matread(filepath)

#     time = datenum2datetime.(mdw["MDW"]["MDW_data"][layer]["dobj"]["time"])
#     acro = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["acro"]
#     x = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["x"]
#     y = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["y"]
#     z = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["z"]
#     data = mdw["MDW"]["MDW_data"][layer]["dobj"]["data"][:, :, 1]
#     sel_stats = mdw["MDW"]["MDW_settings"][layer]["stats"]
#     nodata_value = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["nan_value"]

#     attributes = Dict(
#         "acro" => acro,
#         "sel_stats" => sel_stats,
#         "x" => x,
#         "y" => y,
#         "z" => z,
#         "nodata_value" => nodata_value,
#     )

#     return (time = time, data = data, attributes = attributes)
# end

function load_csv_data(filepath::String)
    obs = CSV.read(filepath, DataFrame; header =[:id, :time, :HTN, :type_nivo], dateformat = "yyyy-mm-dd-HH-MM")
    return obs
end

function daily_mean(sim)
    uniq_time = .!nonunique(DataFrame(t = sim.time)) 
    sim_time = sim.time[uniq_time]
    sim_data = sim.data[uniq_time, :]

    days = unique(Date.(sim_time))
    i_days = indexin(days, Date.(sim_time))

    daily_data = Matrix{Union{Missing, Float64}}(missing, length(i_days), length(sim_data[1,:])) 
    for d in eachindex(i_days)
        if d != length(i_days)
            daily_data[d, :] = mean(sim_data[i_days[d]:i_days[d+1]-1, :]; dims = 1)
        else
            daily_data[d, :] = mean(sim_data[i_days[d]:end, :]; dims = 1)
        end
    end

    sim_daily = merge(sim, (time = Union{Missing, DateTime}[DateTime(d) + Hour(6) for d in days], data = daily_data,))
    return sim_daily
end

function align_data(obs, sim)

    # match stations
    id = sort(intersect(obs.id, sim.id))
    i_sim = indexin(id, sim.id)
    i_dict = Dict(i => k for (k, i) in enumerate(id))

    # match time
    times = sort(intersect(obs.time, collect(skipmissing(vec(sim.time)))))
    t_sim = indexin(times, vec(sim.time))
    t_dict = Dict(t => k for (k, t) in enumerate(times))

    obs_sub = subset(obs,
           :id   => ByRow(in(id)),
           :time => ByRow(in(times)))

    # final rows 
    if isempty(obs_sub)
        error("No observations available")
    end

    # align data
    obs_aligned = Matrix{Union{Missing, Float64}}(missing, length(times), length(id))
    for r in eachrow(obs_sub)
        obs_aligned[t_dict[r.time], i_dict[r.id]] = r.HTN
    end

    obs_aligned = coalesce.(obs_aligned, NaN)
    sim_aligned = disallowmissing(sim.data[t_sim, i_sim])
    # sim_aligned = sim.data

    altitudes = vec(sim.alt)[i_sim]
    massifs = vec(sim.massif)[i_sim]

    return (times = times, obs_aligned = obs_aligned, sim_aligned = sim_aligned, altitudes = altitudes, massifs = massifs, ids = id)

end

bias(sim, obs) = nanmean(sim .- obs)
rmse(sim, obs) = sqrt(nanmean((sim .- obs) .^ 2))
r2(sim, obs) = nancor(obs, sim)^2

function finalize_band_figure!(f, state)
    foreach(ax -> axislegend(ax; position = :rt), state.axes)
    colsize!(f.layout, 2, Fixed(180))
    linkxaxes!(state.axes...)
    foreach(ax -> hidexdecorations!(ax; ticks = false, grid = false), state.axes[1:end-1])
    state.axes[end].xlabel = "time"
    return f
end

function station_metrics(obs, sim, config, run_id; min_days = 30, tol = 0.0)
    _, obs_aligned, sim_aligned, altitudes, massifs, ids = align_data(obs, daily_mean(sim))

    rows = map(eachindex(ids)) do j
        o = obs_aligned[:, j] ./ 100            # cm -> m
        s = Float64.(sim_aligned[:, j])

        # keep days with both values valid, dropping days where both are snow-free
        keep = [!isnan(o[i]) && !isnan(s[i]) && !(o[i] <= tol && s[i] <= tol)
                for i in eachindex(o)]
        o, s = o[keep], s[keep]

        n = length(o)
        ok = n >= min_days
        (config = config, run_id = string(run_id), id = ids[j], altitude = altitudes[j], massif = massifs[j],
         band_lo = 500 * floor(Int, altitudes[j] / 500),
         n_days = n,
         rmse = ok ? rmse(s, o) : NaN,
         bias = ok ? bias(s, o) : NaN,
         r2   = ok ? r2(s, o)   : NaN)
    end
    return DataFrame(rows)
end

# A group = (title, select) where select(altitudes, ids) returns a BitVector of stations
band_groups(bands) = [("$(lo)–$(hi) m", (alt, ids) -> lo .<= alt .< hi) for (lo, hi) in bands]

station_groups(station_ids, names) =
    [("$(names[id]) (id=$id)", (alt, ids) -> ids .== id) for id in station_ids]

station_names(sim) = Dict(zip(sort(sim.id), sim.name))   # names come sorted by ID

function plot_runs(obs, sims; groups, fsize = (1200, 2000))
    # keep only the groups that select at least one station
    al = align_data(obs, daily_mean(last(first(sims))))
    groups = filter(g -> any(g[2](al.altitudes, al.ids)), groups)
    isempty(groups) && error("No station matches the requested groups")

    f = Figure(size = fsize)
    axes, stats = Axis[], GridLayout[]

    for (k, (label, sim)) in enumerate(sims)
        al = align_data(obs, daily_mean(sim))
        color = Makie.wong_colors()[mod1(k, 7)]

        for (g, (title, select)) in enumerate(groups)
            mask = select(al.altitudes, al.ids)
            obs_g = al.obs_aligned[:, mask]
            sim_g = al.sim_aligned[:, mask]
            # sim_g[isnan.(obs_g)] .= NaN                   # compare only where obs exist

            obs_mean = vec(nanmean(obs_g; dims = 2)) ./ 100
            sim_mean = Float64.(vec(nanmean(sim_g; dims = 2)))

            if k == 1
                n = count(mask)
                ax = Axis(f[g, 1]; ylabel = "HS [m]", title = n > 1 ? "$title (n=$n)" : title)
                lines!(ax, al.times, obs_mean; label = "obs", color = :black, linewidth = 2.5)
                push!(axes, ax)
                push!(stats, GridLayout(f[g, 2]))
            end
            lines!(axes[g], al.times, sim_mean; label = label, color = color)

            sim_g[isnan.(obs_g)] .= NaN
            stat_text = "$(label)\n" *
                "RMSE: $(round(rmse(sim_mean, obs_mean), digits = 3)) m\n" *
                "Bias: $(round(bias(sim_mean, obs_mean), digits = 3)) m\n" *
                "R²:   $(round(r2(sim_mean, obs_mean), digits = 3))"
            Label(stats[g][k, 1], stat_text; color = color, halign = :left,
                  justification = :left, tellwidth = false)
        end
    end

    finalize_band_figure!(f, (axes = axes, stats = stats))
    return f
end

