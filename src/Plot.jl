# =============================================================
#		module: plot
# =============================================================
module plot
	using CairoMakie

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PLOT_PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PLOT_PET(;DayHour, Pet, Pet_Obs)

			Line = range(0.0, stop=maximum(Pet_Obs), length=100)

			# Activating the figure
				CairoMakie.activate!(type="svg", pt_per_unit=1)
				Fig = Figure(font="Sans", titlesize=20,  xlabelsize=20, ylabelsize=20, labelsize=30, fontsize=20)

			Axis_1 =  Axis(Fig[1, 1], yticklabelcolor=:black, yaxisposition=:left, rightspinecolor=:black, ytickcolor=:black, xlabel= L"$PET_{Sim}$ ", ylabel= L"$PET_{Obs}$ $[mm]$", xgridvisible=false, ygridvisible=false, width=800, height=400)

				scatter!(Axis_1, Pet, Pet_Obs)

				lines!(Axis_1, Line, Line, color=:grey, linestyle=:dash, linewidth=5)

			# Axis_2 = Axis(Fig[1,2])

				colgap!(Fig.layout, 15)
				rowgap!(Fig.layout, 15)
				resize_to_layout!(Fig)
				trim!(Fig.layout)
				display(Fig)

		return nothing
		end  # function: PLOT_PET
	# ------------------------------------------------------------------

end  # module: plot
# ............................................................