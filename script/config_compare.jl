using CSV, DataFrames, CairoMakie

function boxplot_metric(metrics_path, col::Symbol; by_band = false, verbose=true)
    metrics = CSV.read(metrics_path, DataFrame)

    df = filter(r -> !isnan(r[col]), metrics)
    configs = unique(df.config)                       # keeps the run order
    x = Int.(indexin(df.config, configs))

    f = Figure(size = (1000, 500))
    ax = Axis(f[1, 1]; xticks = (1:length(configs), configs), ylabel = string(col),
              xticklabelrotation = π / 6)

    if by_band
        bands = sort(unique(df.band_lo))
        d = Int.(indexin(df.band_lo, bands))
        cols = cgrad(:viridis, length(bands); categorical = true)
        boxplot!(ax, x, df[!, col]; dodge = d, color = cols[d])
        Legend(f[1, 2], [PolyElement(color = cols[i]) for i in eachindex(bands)],
               ["$(b)–$(b + 500) m" for b in bands], "Altitude")
    else
        boxplot!(ax, x, df[!, col])
    end

    col == :bias && hlines!(ax, 0; color = :black, linestyle = :dash)
    return f
end

function heatmap_metrics(metrics_path, col::Symbol; groups = nothing, ncols = 3,
                         panel = (480, 420))
    metrics = CSV.read(metrics_path, DataFrame)
    df = filter(r -> !ismissing(r[col]) && !isnan(r[col]), metrics)

    parts = split.(df.config, "|")
    df.p1 = strip.(first.(parts))
    df.p2 = strip.(last.(parts))

    xs = sort(unique(df.p2))
    ys = sort(unique(df.p1))

    # one subset per group, using the same select(alt, ids) as in plot_runs
    subsets = isnothing(groups) ? [("", df)] :
        [(title, df[collect(Bool, select(df.altitude, df.id)), :]) for (title, select) in groups]
    subsets = filter(s -> !isempty(s[2]), subsets)      # drop groups with no station
    isempty(subsets) && error("No station matches the requested groups")

    function matrix(sub)
        agg = combine(groupby(sub, [:p1, :p2]), col => mean => :val)
        Z = fill(NaN, length(xs), length(ys))
        for r in eachrow(agg)
            Z[findfirst(==(r.p2), xs), findfirst(==(r.p1), ys)] = r.val
        end
        return Z
    end
    Zs = [matrix(sub) for (_, sub) in subsets]

    label  = uppercase(String(col))
    signed = col == :bias
    allv   = filter(!isnan, vcat(vec.(Zs)...))
    crange = signed ? (let m = maximum(abs, allv); (-m, m) end) : extrema(allv)
    cmap   = signed ? :RdBu : :viridis

    n  = length(subsets)
    nc = min(ncols, n)
    nr = cld(n, nc)
    fig = Figure(size = (nc * panel[1] + 120, nr * panel[2]))

    local hm
    for (k, ((gtitle, sub), Z)) in enumerate(zip(subsets, Zs))
        nst = length(unique(sub.id))
        ax = Axis(fig[cld(k, nc), mod1(k, nc)];
                  title = isnothing(groups) ? label : "$label, $gtitle (n=$nst)",
                  xticks = (1:length(xs), xs), yticks = (1:length(ys), string.(ys)),
                  xticklabelrotation = π/4, ylabel = "precip")
        hm = heatmap!(ax, 1:length(xs), 1:length(ys), Z;
                      colormap = cmap, colorrange = crange, nan_color = :lightgray)
        for i in eachindex(xs), j in eachindex(ys)
            isnan(Z[i, j]) && continue
            text!(ax, i, j; text = string(round(Z[i, j]; digits = 2)), fontsize = 11,
                  align = (:center, :center), color = signed ? :black : :white)
        end
    end
    Colorbar(fig[:, nc + 1], hm; label = label)
    return fig
end

save(settings_path["boxplot"],      boxplot_metric(settings_path["metrics"], :rmse))
save(settings_path["boxplot_band"], boxplot_metric(settings_path["metrics"], :rmse; by_band = true))
save(settings_path["heatmap"],      heatmap_metrics(settings_path["metrics"], :rmse))

