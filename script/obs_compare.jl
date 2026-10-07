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

# function plot_band_time_series(obs, sim)

#     times, obs_aligned, sim_aligned, altitudes, _ = align_data(obs, daily_mean(sim))

#     # altitude data
#     altitude_bands = [(0, 3000), (0, 500), (500, 1000), (1000, 1500), (1500, 2000), (2000, 2500), (2500, 3000)]

#     # plot data

#     f = Figure(size = (1200, 2000))
#     band_axes = Axis[]
#     for (b, (lo, hi)) in enumerate(altitude_bands)
#         mask = lo .<= altitudes .<= hi
#         obs_band = obs_aligned[:, mask]
#         sim_band = sim_aligned[:, mask]
#         # obs is reported in cm, sim in m — convert obs to m for comparison
#         obs_mean_b = vec(nanmean(obs_band; dims = 2)) / 100
#         sim_mean_b = Float64.(vec(nanmean(sim_band; dims = 2)))

#         ax = Axis(f[b, 1]; ylabel = "HS [m]", title = "$(lo)–$(hi) m (n=$(count(mask)))")
#         lines!(ax, times, obs_mean_b; label = "obs", color = :black, linewidth = 2.5)
#         lines!(ax, times, sim_mean_b; label = "sim", color = :red)
#         axislegend(ax; position = :rt)
#         push!(band_axes, ax)

#         bias_val = bias(sim_mean_b, obs_mean_b)
#         rmse_val = rmse(sim_mean_b, obs_mean_b)
#         r2_val = r2(sim_mean_b, obs_mean_b)
#         stat_text = "RMSE: $(round(rmse_val, digits = 3)) m\n" *
#             "Bias: $(round(bias_val, digits = 3)) m\n" *
#             "R²:   $(round(r2_val, digits = 3))"
#         Label(f[b, 2], stat_text; halign = :left, justification = :left, tellwidth = false, tellheight = false)
#     end

#     colsize!(f.layout, 2, Fixed(160))

#     linkxaxes!(band_axes...)
#     for ax in band_axes[1:(end - 1)]
#         hidexdecorations!(ax; ticks = false, grid = false)
#     end
#     band_axes[end].xlabel = "time"

#     return f

# end


# function plot_band_loop_time_series!(f, state, obs, sim, label, k, verbose=true)
#     times, obs_aligned, sim_aligned, altitudes, _ = align_data(obs, daily_mean(sim))
#     color = Makie.wong_colors()[k]
#     first_call = isempty(state.axes)

#     # altitude data
#     altitude_bands = [(0, 3000), (0, 500), (500, 1000), (1000, 1500), (1500, 2000), (2000, 2500), (2500, 3000)]

#     progress_bar = verbose ? Progress(length(times), desc = "Running plot elevation band...") : nothing

#     for (b, (lo, hi)) in enumerate(altitude_bands)
#         mask = lo .<= altitudes .< hi
#         obs_band = obs_aligned[:, mask]
#         sim_band = sim_aligned[:, mask]
#         sim_band[isnan.(obs_band)] .= NaN          # compare only where obs exist (see 3.)

#         obs_mean = vec(nanmean(obs_band; dims = 2)) ./ 100
#         sim_mean = Float64.(vec(nanmean(sim_band; dims = 2)))

#         if first_call
#             ax = Axis(f[b, 1]; ylabel = "HS [m]", title = "$(lo)–$(hi) m (n=$(count(mask)))")
#             lines!(ax, times, obs_mean; label = "obs", color = :black, linewidth = 2.5)
#             push!(state.axes, ax)
#             push!(state.stats, GridLayout(f[b, 2]))
#         end

#         lines!(state.axes[b], times, sim_mean; label = label, color = color)

#         stat_text = "$(label)\n" *
#             "RMSE: $(round(rmse(sim_mean, obs_mean), digits = 3)) m\n" *
#             "Bias: $(round(bias(sim_mean, obs_mean), digits = 3)) m\n" *
#             "R²:   $(round(r2(sim_mean, obs_mean), digits = 3))"
#         Label(state.stats[b][k, 1], stat_text; color = color, halign = :left,
#               justification = :left, tellwidth = false)

#         if verbose
#             next!(progress_bar)
#         end
#     end
#     return f
# end

# function plot_band_massif_time_series(obs, sim)

#     times, obs_aligned, sim_aligned, altitudes, massifs, _ = align_data(obs, daily_mean(sim))

#     # altitude data
#     massif_bands = collect(0:23)

#     # plot data

#     f = Figure(size = (1200, 5000))
#     band_axes = Axis[]
#     for (b, m) in enumerate(massif_bands)
#         if m==0
#             mask = trues(length(massifs))
#             m = "all"
#         else 
#             mask = massifs.==m
#         end
 
#         obs_band = obs_aligned[:, mask]
#         sim_band = sim_aligned[:, mask]
#         # obs is reported in cm, sim in m — convert obs to m for comparison
#         obs_mean_b = vec(nanmean(obs_band; dims = 2)) / 100
#         sim_mean_b = Float64.(vec(nanmean(sim_band; dims = 2)))

#         ax = Axis(f[b, 1]; ylabel = "HS [m]", title = "massif : $(m) (n=$(count(mask)))")
#         lines!(ax, times, obs_mean_b; label = "obs", color = :black, linewidth = 2.5)
#         lines!(ax, times, sim_mean_b; label = "sim", color = :red)
#         axislegend(ax; position = :rt)
#         push!(band_axes, ax)

#         bias_val = bias(sim_mean_b, obs_mean_b)
#         rmse_val = rmse(sim_mean_b, obs_mean_b)
#         r2_val = r2(sim_mean_b, obs_mean_b)
#         stat_text = "RMSE: $(round(rmse_val, digits = 3)) m\n" *
#             "Bias: $(round(bias_val, digits = 3)) m\n" *
#             "R²:   $(round(r2_val, digits = 3))"
#         Label(f[b, 2], stat_text; halign = :left, justification = :left, tellwidth = false, tellheight = false)
#     end

#     colsize!(f.layout, 2, Fixed(160))

#     linkxaxes!(band_axes...)
#     for ax in band_axes[1:(end - 1)]
#         hidexdecorations!(ax; ticks = false, grid = false)
#     end
#     band_axes[end].xlabel = "time"

#     return f

# end

# ## Other functions to plot (1 station, ...)
# function plot_single_time_series(obs, sim)

#     times, obs_aligned, sim_aligned, altitudes, _ = align_data(obs, daily_mean(sim))

#     # name data
#     name = sim.name

#     # plot data

#     f  = Figure(size = (1200, 600))

#     ax = Axis(f[1, 1]; xlabel = "time", ylabel = "HS [m]", title = "$(name[1]) (id=$(sim.id[1]), $(altitudes[1]) m)")

#     sim_vec = vec(sim_aligned)
#     obs_vec = vec(obs_aligned) /100

#     lines!(ax, times, obs_vec; label = "obs", color = :black, linewidth = 2.5)
#     lines!(ax, times, sim_vec; label = "sim", color = :red)
#     axislegend(ax; position = :rt)

#     stat_text = """
#     RMSE: $(round(rmse(sim_vec, obs_vec), digits = 3)) m
#     Bias: $(round(bias(sim_vec, obs_vec), digits = 3)) m
#     R²:   $(round(r2(sim_vec, obs_vec), digits = 3))"""

#     Label(f[1, 2], stat_text; halign = :left, justification = :left, tellwidth = false, tellheight = false)

#     colsize!(f.layout, 2, Fixed(160))

#     return f

# end