if Base.identify_package("GLMakie") === nothing
    error(
        "The script compare_simulations.jl requires GLMakie in the default environment." *
            "Add it to your default (global) environment with: " *
            "`import Pkg; Pkg.activate(); Pkg.add(\"GLMakie\")` and re-run this script."
    )
end

using MAT
using Dates
using GLMakie
using OSHDinternal
using ProgressMeter
using NaNStatistics

run_dir(h) = "LATEST_$(lpad(h, 2, '0'))h_RUN"

const MODEL_SPECS = Dict(
    "FSM_HS" => (
        mat_dir = (tile, run_id) -> "K:/MODEL_DATA_FSM/FSM_HS/$(run_dir(run_id))/OUTPUT_OSHD_0250/RESULTS_24h_$(tile)",
        mat_filename = (tstart_str, tend_str) -> "MODELDATA_$(tstart_str)-$(tend_str)_FSM22.mat",
        mat_time_re = r"-(\d{12})_FSM22\.mat$",
        mat_time_to_tend = identity,
        jul_dir = (tile, run_id) -> "R:/MODEL_DATA_FSM/FSM_HS/$(run_dir(run_id))/OUTPUT_OSHD_0250/RESULTS_24h_$(tile)",
        jul_filename = (tstart_str, tend_str) -> "MODELDATA_$(tstart_str)-$(tend_str)_FSM.mat",
        var_pairs = [("hsne", "hsne"), ("swee", "swee"), ("scfe", "scfe"), ("rotc", "rotc")],
    ),
    "FSM_HN" => (
        mat_dir = (tile, run_id) -> "U:/MODEL_DATA_FSM/FSM_HN/$(run_dir(run_id))/OUTPUT_OSHD_0250/RESULTS_24h_hn",
        mat_filename = (tstart_str, tend_str) -> "MODELDATA_$(tstart_str)_FSM22.mat",
        mat_time_re = r"_(\d{12})_FSM22\.mat$",
        mat_time_to_tend = t -> t + Day(1),
        jul_dir = (tile, run_id) -> "R:/MODEL_DATA_FSM/FSM_HN/$(run_dir(run_id))/OUTPUT_OSHD_0250/RESULTS_24h_$(tile)",
        jul_filename = (tstart_str, tend_str) -> "MODELDATA_$(tstart_str)-$(tend_str)_FSM.mat",
        var_pairs = [("hs24", "hs24"), ("sn24", "sn24"), ("sf24", "sf24")],
    ),
)

function load_data(time, sim_type, run_id, tile, jul_var, mat_var)
    spec = MODEL_SPECS[sim_type]
    tstart_str = Dates.format(time - Day(1), "yyyymmddHHMM")
    tend_str = Dates.format(time, "yyyymmddHHMM")

    jul_file = joinpath(spec.jul_dir(tile, run_id), spec.jul_filename(tstart_str, tend_str))
    jul_data = matopen(f -> read(f, jul_var)["data"], jul_file)::Matrix{Float64}

    mat_file = joinpath(spec.mat_dir(tile, run_id), spec.mat_filename(tstart_str, tend_str))
    mat_data = matopen(f -> read(f, mat_var)["data"], mat_file)::Matrix{Float64}

    i_nan = mat_data .< 0
    jul_data[i_nan] .= NaN
    mat_data[i_nan] .= NaN

    return jul_data, mat_data
end

function find_period(sim_type, run_id, tile)
    spec = MODEL_SPECS[sim_type]

    jul_files = searchdir(spec.jul_dir(tile, run_id), ".mat")
    mat_files = searchdir(spec.mat_dir(tile, run_id), ".mat")

    jul_times = [DateTime(match(r"_(\d{12})_FSM\.mat$", f)[1], dateformat"yyyymmddHHMM") for f in jul_files]
    mat_times = [spec.mat_time_to_tend(DateTime(match(spec.mat_time_re, f)[1], dateformat"yyyymmddHHMM")) for f in mat_files]

    return sort(collect(intersect(Set(jul_times), Set(mat_times))))
end

function compare_simulations_interactive(sim_type = "FSM_HS", run_id = 0, tile = "opn")

    spec = MODEL_SPECS[sim_type]

    dates = find_period(sim_type, run_id, tile)

    jul0, mat0 = load_data(dates[1], sim_type, run_id, tile, spec.var_pairs[1]...)
    mat_obs = Observable(mat0')
    jul_obs = Observable(jul0')

    fig = Figure(size = (1700, 550))
    title_label = Label(fig[0, 1:4], "Date: $(dates[1]) | $(sim_type) | $(tile)", fontsize = 16, tellwidth = false)

    scatter_points = lift(mat_obs, jul_obs) do m, j
        Point2f.(vec(m), vec(j))
    end

    ax3 = Axis(
        fig[1, 1],
        title = "Matlab/Fortran vs Julia",
        xlabel = "matlab/fortran",
        ylabel = "julia",
        aspect = AxisAspect(1)
    )
    scatter!(ax3, scatter_points, markersize = 3)
    ablines!(ax3, [0], [1], color = :red, linestyle = :dash)

    ax1 = Axis(fig[1, 2], title = "Matlab/Fortran", aspect = DataAspect())
    hm1 = heatmap!(ax1, mat_obs)

    ax2 = Axis(fig[1, 3], title = "Julia", aspect = DataAspect())
    hm2 = heatmap!(ax2, jul_obs)
    Colorbar(fig[1, 4], hm2)

    linkaxes!(ax1, ax2)

    jul_vars = first.(spec.var_pairs)

    sl = Makie.Slider(fig[2, 1:2], range = 1:length(dates), startvalue = 1, update_while_dragging = false)
    menu = Menu(fig[2, 3], options = jul_vars, default = jul_vars[1])

    function update_plot(date_idx, var_idx)
        jul_var, mat_var = spec.var_pairs[var_idx]
        j, m = load_data(dates[date_idx], sim_type, run_id, tile, jul_var, mat_var)
        mat_obs[] = m'
        jul_obs[] = j'
        title_label.text = "Date: $(dates[date_idx]) | $(sim_type) | $(tile)"
        mx = max(maximum(filter(isfinite, m)), maximum(filter(isfinite, j)), 0.001)
        limits!(ax3, 0, mx, 0, mx)
        return nothing
    end

    on(sl.value) do i
        var_idx = findfirst(==(menu.selection[]), jul_vars)
        update_plot(i, var_idx)
    end

    on(menu.selection) do s
        var_idx = findfirst(==(s), jul_vars)
        update_plot(sl.value[], var_idx)
    end

    on(events(fig).keyboardbutton) do event
        event.action in (Keyboard.press, Keyboard.repeat) || return nothing
        if event.key == Keyboard.right
            set_close_to!(sl, min(sl.value[] + 1, length(dates)))
        elseif event.key == Keyboard.left
            set_close_to!(sl, max(sl.value[] - 1, 1))
        end
    end

    display(fig)
    return nothing

end

function compare_simulations_summary(sim_type = "FSM_HS", run_id = 0, tile = "opn")

    spec = MODEL_SPECS[sim_type]

    dates = find_period(sim_type, run_id, tile)

    for (jul_var, mat_var) in spec.var_pairs

        err_mean = Float64[]
        err_maximum = Float64[]

        @showprogress dt = 1 desc = "Running for $(jul_var)..." for date in dates

            jul, mat = load_data(date, sim_type, run_id, tile, jul_var, mat_var)

            err = mat .- jul

            push!(err_mean, nanmean(abs.(err)))
            push!(err_maximum, nanmaximum(abs.(err)))

        end

        fig = Figure(size = (1200, 600))

        ax_top = Axis(fig[1, 1], ylabel = "Mean absolute error", title = "$(sim_type) | $(tile) | $(mat_var)")
        lines!(ax_top, dates, err_mean)
        hidexdecorations!(ax_top, grid = false)

        ax_bottom = Axis(fig[2, 1], ylabel = "Maximum absolute error")
        lines!(ax_bottom, dates, err_maximum)

        linkxaxes!(ax_top, ax_bottom)
        display(GLMakie.Screen(), fig)

    end

    return nothing
end

# compare_simulations_summary("FSM_HS", 0)

# compare_simulations_interactive("FSM_HS", 0)