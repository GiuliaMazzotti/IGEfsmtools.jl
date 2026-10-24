# Helper functions for comparing FSM point simulations against observed snow depth.

using CSV
using DataFrames
using NaNStatistics
using Dates
using Statistics
using CairoMakie
CairoMakie.activate!()


# **************************************
# Load obs
function datenum2datetime(matlab_datenum)
    # MATLAB datenum for Unix epoch (Jan 1, 1970) is 719529
    unix_offset = 719529
    days_since_unix = matlab_datenum - unix_offset

    return DateTime(1970, 1, 1) + Millisecond(round(Int, days_since_unix * 86400000))
end

function datetime2datenum(dt::DateTime)
    # MATLAB datenum for Unix epoch (Jan 1, 1970) is 719529
    unix_offset = 719529
    days_since_unix = (dt - DateTime(1970, 1, 1)).value / 86400000  # milliseconds to days

    return unix_offset + days_since_unix
end

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

function load_csv_data(filepath::String)
    obs = CSV.read(filepath, DataFrame; header =[:id, :time, :HTN, :type_nivo], dateformat = "yyyy-mm-dd-HH-MM")
    return obs
end


# **************************************
# Load sims
function load_sim(path)
    NCDataset(path) do ds
        (
            time   = Vector{DateTime}(ds["time"][:]),
            data   = coalesce.(Array(ds["snowdepth"][:, :]), NaN32),  # plain Matrix{Float32}
            id     = Int.(ds["station"][:]),
            alt    = Float64.(ds["ZS"][:]),
            name   = String.(ds["name"][:]),
            massif = ds["massif"][:],
        )
    end
end

function load_sims(paths)
    sims = Pair{String, Any}[]
    for p in paths
        label, path = p isa Pair ? (String(first(p)), String(last(p))) :
                                   (splitext(basename(String(p)))[1], String(p))
        isfile(path) || error("File not found: $path")
        push!(sims, label => load_sim(path))
    end
    return sims
end

function load_sims_dir(dir; pattern = r"^sim_.*\.nc$")
    files = sort(filter(f -> occursin(pattern, f), readdir(dir)))
    load_sims([joinpath(dir, f) for f in files])
end


# **************************************
# Treats data
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

function max_hs(times, data)
    yr    = Dates.year.(times)
    years = unique(yr)
    maxs = fill(NaN, length(years), size(data, 2))
    rows = zeros(Int, length(years), size(data, 2))     # global row index of the max, 0 = no data
    for (iy, y) in enumerate(years)
        r = findall(==(y), yr)
        for j in axes(data, 2)
            col = @view data[r, j]
            valid = findall(!isnan, col)
            isempty(valid) && continue
            k = valid[argmax(col[valid])]
            maxs[iy, j] = col[k]
            rows[iy, j] = r[k]
        end
    end
    return maxs, rows, years
end

function align_data(obs, sim)

    if :attributes in fieldnames(typeof(obs))
        # match stations
        qc = vec(obs.attributes["sel_stats"])
        obs_id = vec(obs.attributes["acro"])
        sim_id = sim.id
        obs_set = Set(obs_id)
        sim_set = Set(sim_id)
        id = sort!([a for a in parse.(Int, qc) if a in parse.(Int, obs_set) && a in sim_set])
        i_obs = indexin(id, parse.(Int, obs_id))
        
        # match time
        times = sort(intersect(obs.time, collect(skipmissing(vec(sim.time)))))
        t_obs = indexin(times, vec(obs.time))

        # align obs
        obs_aligned = obs.data[t_obs, i_obs]

        # handle missing data
        i_missing = obs_aligned .== obs.attributes["nodata_value"]
        obs_aligned[i_missing] .= NaN
    else
        # match stations
        id = sort(intersect(obs.id, sim.id))
        i_dict = Dict(i => k for (k, i) in enumerate(id))

        # match time
        times = sort(intersect(obs.time, collect(skipmissing(vec(sim.time)))))
        t_obs = indexin(times, vec(obs.time))
        t_dict = Dict(t => k for (k, t) in enumerate(times))

        obs_sub = subset(obs,
           :id   => ByRow(in(id)),
           :time => ByRow(in(times)))

        # final rows 
        if isempty(obs_sub)
            error("No observations available")
        end

        # align obs
        obs_aligned = Matrix{Union{Missing, Float64}}(missing, length(times), length(id))
        for r in eachrow(obs_sub)
            obs_aligned[t_dict[r.time], i_dict[r.id]] = r.HTN
        end

        obs_aligned = coalesce.(obs_aligned, NaN)
    end

    i_sim = indexin(id, sim.id)
    found = .!isnothing.(i_sim)
    i_sim  = Int.(i_sim[found])       
    
    t_sim = indexin(times, vec(sim.time))
    sim_aligned = disallowmissing(sim.data[t_sim, i_sim])

    altitudes = vec(sim.alt)[i_sim]
    massifs = vec(sim.massif)[i_sim]

    return (times = times, obs_aligned = obs_aligned, sim_aligned = sim_aligned, altitudes = altitudes, massifs = massifs, ids = id)

end

bias(sim, obs) = nanmean(sim .- obs)
rmse(sim, obs) = sqrt(nanmean((sim .- obs) .^ 2))
r2(sim, obs) = nancor(obs, sim)^2


# **************************************
# Plots and exported results
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

# max_pairs now also returns the years (needs the max_hs returning maxs, rows, years)
function max_pairs_date(al)
    obs_max, rows, years = max_hs(al.times, al.obs_aligned)
    obs_max = obs_max ./ 100                                   # cm -> m
    sim_max = fill(NaN, size(rows))
    for j in axes(rows, 2), iy in axes(rows, 1)
        rows[iy, j] > 0 && (sim_max[iy, j] = Float64(al.sim_aligned[rows[iy, j], j]))
    end
    return obs_max, sim_max, years
end

function max_pairs(al)
    obs_max, rows, years = max_hs(al.times, al.obs_aligned)
    obs_max = obs_max ./ 100                                   # cm -> m
    sim_max, _ = max_hs(al.times, al.sim_aligned)
    return obs_max, sim_max, years
end

# select(alt, ids) -> station mask   |   select(alt, ids, years) -> station mask or years×stations mask
function cell_mask(select, alt, ids, years)
    m = applicable(select, alt, ids, years) ? select(alt, ids, years) : select(alt, ids)
    m isa AbstractMatrix && return Matrix{Bool}(m)
    return repeat(reshape(Bool.(m), 1, :), length(years), 1)   # same stations for every year
end

# --- group builders ---
# periods = [(1994, 2003), (2004, 2013), ...] (inclusive, on the calendar year of the annual max)
year_groups(periods) = [("$(a)–$(b)", (alt, ids, yrs) -> (a .<= yrs .<= b) .& trues(1, length(ids)))
                        for (a, b) in periods]

# one group per year
each_year_groups(years) = [(string(y), (alt, ids, yrs) -> (yrs .== y) .& trues(1, length(ids)))
                           for y in years]

# combine a station group with a year group (intersection)
both(g1, g2) = ("$(g1[1]), $(g2[1])",
                (alt, ids, yrs) -> cell_mask(g1[2], alt, ids, yrs) .& cell_mask(g2[2], alt, ids, yrs))

# A group = (title, select) where select(altitudes, ids) returns a BitVector of stations
band_groups(bands) = [("$(lo)–$(hi) m", (alt, ids) -> lo .<= alt .< hi) for (lo, hi) in bands]

# massif_groups(massifs, names) =
#     [(name, (alt, ids) -> massifs .== m) for (m, name) in zip(massifs_list, names)]
    # names     : optional Dict massif number => display name
massif_groups(massif_of, massifs; names = Dict{Int,String}()) =
    [(get(names, m, "Massif $m"),
      (alt, ids) -> BitVector([isequal(get(massif_of, i, missing), m) for i in ids]))
     for m in massifs]

# names : Dict station id => name
station_groups(station_ids, names_of) =
    [("$(get(names_of, id, "?"))", (alt, ids) -> ids .== id) for id in station_ids]

# **************************************
# Plots time series of the sims per "groups" 
# Produces one plot with all the groups (different axes) each axes containing all sims
function plot_runs(obs, sims; groups, fsize = (2000, 2500))
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
                push!(stats, GridLayout(f[g, 2]; tellheight = false, valign = :top))
            end
            lines!(axes[g], al.times, sim_mean; label = label, color = color)

            sim_g[isnan.(obs_g)] .= NaN
            sim_mean = Float64.(vec(nanmean(sim_g; dims = 2)))
            stat_text = "$(label)\n" *
                "RMSE: $(round(rmse(sim_mean, obs_mean), digits = 3)) m, " *
                "Bias: $(round(bias(sim_mean, obs_mean), digits = 3)) m, " *
                "R²:   $(round(r2(sim_mean, obs_mean), digits = 3))"
            Label(stats[g][k, 1], stat_text; color = color, halign = :left,
                  justification = :left, tellwidth = false)
        end
    end

    finalize_band_figure!(f, (axes = axes, stats = stats))
    return f
end

# **************************************
# Plots scatter between obs and sim per sim categorized by "groups" selection
# Produces one plot per sim
function plot_scatter_run(obs, label, sim; groups, fsize = (1100, 600), csv = nothing)
    al = align_data(obs, daily_mean(sim))
    obs_max, sim_max, years = max_pairs(al)          # years × stations

    masks  = [cell_mask(sel, al.altitudes, al.ids, years) for (_, sel) in groups]
    keep   = findall(M -> any(M .& .!isnan.(obs_max) .& .!isnan.(sim_max)), masks)
    isempty(keep) && error("No data matches the requested groups")
    groups, masks = groups[keep], masks[keep]

    f = Figure(size = fsize)
    ax = Axis(f[1, 1]; xlabel = "Obs annual max HS [m]",
              ylabel = "Sim HS at obs max date [m]", title = label, aspect = 1)
    stats = GridLayout(f[1, 2]; tellheight = false, valign = :top)

    rows = NamedTuple[]   
    lim = 0.0
    for (g, ((title, _), M)) in enumerate(zip(groups, masks))
        color = Makie.wong_colors()[mod1(g, 7)]
        ok = M .& .!isnan.(obs_max) .& .!isnan.(sim_max)
        x, y = obs_max[ok], sim_max[ok]

        nst  = count(vec(any(ok; dims = 1)))          # stations with at least one point
        name = "$title (n=$(length(x)), $nst st.)"
        scatter!(ax, x, y; color = color, markersize = 8, label = name)
        r_rmse, r_bias, r_r2 = rmse(y, x), bias(y, x), r2(y, x)
        r_factor = r_bias / mean(x)
        push!(rows, (config = label, group = title, n_points = length(x), n_stations = nst, rmse = r_rmse, bias = r_bias, r2 = r_r2, factor = r_factor))

        lim = max(lim, maximum(x), maximum(y))
        stat_text = "$name\n" *
            "RMSE: $(round(rmse(y, x), digits = 3)) m, " *
            "Bias: $(round(bias(y, x), digits = 3)) m, " *
            "R²: $(round(r2(y, x), digits = 3))"
        Label(stats[g, 1], stat_text; color = color, halign = :left,
              justification = :left, tellwidth = false)
    end

    lines!(ax, [0, lim], [0, lim]; color = :black, linestyle = :dash)   # 1:1
    limits!(ax, 0, lim * 1.05, 0, lim * 1.05)
    axislegend(ax; position = :rb)
    colsize!(f.layout, 2, Relative(0.4))

    if !isnothing(csv)
        mkpath(dirname(csv))
        CSV.write(csv, DataFrame(rows); append = isfile(csv))   # header only on first write
    end
    return f
end

plot_scatter_runs(obs, sims; groups, kwargs...) =
    [label => plot_scatter_run(obs, label, sim; groups = groups, kwargs...)
     for (label, sim) in sims]

# **************************************
# Plots time series of the mean values of the different stations grouped by "groups" selection (alt, massif, station, year...)
# Produces one plot per group with all sims on it
# Allows to choose the period that is plotted 
function plot_year_runs(obs, sims; groups, period = (nothing, nothing), fsize = (1400, 600))
    t0, t1 = period     # e.g. (Date(2010, 8, 1), Date(2011, 7, 31)); `nothing` = no bound

    # align each sim once
    als = [label => align_data(obs, daily_mean(sim)) for (label, sim) in sims]

    # keep only the groups that select at least one station
    al1 = last(first(als))
    groups = filter(g -> any(g[2](al1.altitudes, al1.ids)), groups)
    isempty(groups) && error("No station matches the requested groups")

    in_period(t) = (isnothing(t0) || t >= DateTime(t0)) && (isnothing(t1) || t <= DateTime(t1))

    figs = Pair{String, Figure}[]
    for (title, select) in groups
        n = count(select(al1.altitudes, al1.ids))

        f = Figure(size = fsize)
        ax = Axis(f[1, 1]; ylabel = "HS [m]", title = n > 1 ? "$title (n=$n)" : title)
        stats = GridLayout(f[1, 2]; tellheight = false, valign = :top)

        for (k, (label, al)) in enumerate(als)
            color = Makie.wong_colors()[mod1(k, 7)]
            mask = select(al.altitudes, al.ids)
            tm = in_period.(al.times)
            any(tm) || error("No data in the requested period for $label")

            times = al.times[tm]
            obs_g = al.obs_aligned[tm, mask]
            sim_g = al.sim_aligned[tm, mask]

            obs_mean = vec(nanmean(obs_g; dims = 2)) ./ 100
            sim_mean = Float64.(vec(nanmean(sim_g; dims = 2)))

            k == 1 && lines!(ax, times, obs_mean; label = "obs", color = :black, linewidth = 2.5)
            lines!(ax, times, sim_mean; label = label, color = color)

            # stats: compare only where obs exist
            sim_g[isnan.(obs_g)] .= NaN
            sim_mean = Float64.(vec(nanmean(sim_g; dims = 2)))
            stat_text = "$(label)\n" *
                "RMSE: $(round(rmse(sim_mean, obs_mean), digits = 3)) m, " *
                "Bias: $(round(bias(sim_mean, obs_mean), digits = 3)) m, " *
                "R²:   $(round(r2(sim_mean, obs_mean), digits = 3))"
            Label(stats[k, 1], stat_text; color = color, halign = :left,
                  justification = :left, tellwidth = false)
        end

        finalize_band_figure!(f, (axes = [ax], stats = [stats]))
        push!(figs, title => f)
    end
    return figs
end

# **************************************
# Plots mean over the hole period of the different stations grouped by "groups" selection (alt, massif, station, year...)
# Produces one plot per group with one year mean time series
# function plot_period_runs(obs, sims; groups, fsize = (1400, 600))
#     # align each sim once
#     als = [label => align_data(obs, daily_mean(sim)) for (label, sim) in sims]

#     # keep only the groups that select at least one station
#     al1 = last(first(als))
#     groups = filter(g -> any(g[2](al1.altitudes, al1.ids)), groups)
#     isempty(groups) && error("No station matches the requested groups")

#     yr = unique(Dates.monthday.(sims[1].second.time))[1:end-1]

#     figs = Pair{String, Figure}[]
#     for (title, select) in groups
#         n = count(select(al1.altitudes, al1.ids))

#         f = Figure(size = fsize)
#         ax = Axis(f[1, 1]; ylabel = "HS [m]", title = n > 1 ? "$title (n=$n)" : title)
#         stats = GridLayout(f[1, 2]; tellheight = false, valign = :top)

#         for (k, (label, al)) in enumerate(als)
#             color = Makie.wong_colors()[mod1(k, 7)]
#             mask = select(al.altitudes, al.ids)
#             tm = [findall(in([d]), Dates.monthday.(al.times)) for (i, d) in enumerate(yr)]
#             # any(tm) || error("No data in the requested period for $label")

#             times = 1:length(yr)
#             obs_g = al.obs_aligned[:, mask]
#             sim_g = al.sim_aligned[:, mask]

#             obs_m = vec(nanmean(obs_g; dims = 2)) ./ 100
#             sim_m = Float64.(vec(nanmean(sim_g; dims = 2)))

#             obs_mean = [nanmean(obs_m[tm[d]]) for d in eachindex(tm)]
#             sim_mean = [nanmean(sim_m[tm[d]]) for d in eachindex(tm)]

#             k == 1 && lines!(ax, times, obs_mean; label = "obs", color = :black, linewidth = 2.5)
#             lines!(ax, times, sim_mean; label = label, color = color)

#             month_names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
#             first_of_month = findall(t -> t[2] == 1, yr)          # indices des 1er du mois
#             ax.xticks = (first_of_month, [month_names[yr[i][1]] for i in first_of_month])

#             # stats: compare only where obs exist
#             sim_g[isnan.(obs_g)] .= NaN
#             sim_m = Float64.(vec(nanmean(sim_g; dims = 2)))
#             stat_text = "$(label)\n" *
#                 "RMSE: $(round(rmse(sim_m, obs_m), digits = 3)) m, " *
#                 "Bias: $(round(bias(sim_m, obs_m), digits = 3)) m, " *
#                 "R²:   $(round(r2(sim_m, obs_m), digits = 3))"
#             Label(stats[k, 1], stat_text; color = color, halign = :left,
#                   justification = :left, tellwidth = false)
#         end

#         finalize_band_figure!(f, (axes = [ax], stats = [stats]))
#         push!(figs, title => f)
#     end
#     return figs
# end