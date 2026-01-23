"""
include(raw"src\\PET.jl")
"""

module pet
	import Dates, CSV, Tables

	include("Read.jl")
	include("Write.jl")
	include("ReadToml.jl")
	include("EvapoFunc.jl")
	include("Plot.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function RUN_PET()
			printstyled(" ==== Running PET ======= \n", color=:blue)

			# Read TOML input file
				Path_Toml₀ =  raw"DATA\PARAMETER\PetOption.toml"
				Path_Toml = joinpath(pwd(), Path_Toml₀)
				option = readtoml.READTOML(Path_Toml)

				Path_Input = joinpath(pwd(), option.path.Path_Input)
				DayHour, meteo, Nmeteo, Pet_Obs = read.READ_WEATHER(Path_Input)

				Pet = zeros(Float64, Nmeteo)

				Latitude, Longitude = evapoFunc.utils.LATITUDE_DEGREE_HOUR_2_DEGREE(;option.param.Latitude_Minute, option.param.Latitude_ᴼ, option.param.Longitude_Minute, option.param.Longitude_ᴼ)

				for  (iT, iiDateTime) in enumerate(DayHour)
					Pet[iT] = pet.PENMAN_MONTEITH_HOURLY(;DayHour, cst=option.cst, iT, Latitude, Longitude, meteo, param=option.param )
				end

				# Writting csv
				Path_Output = joinpath(pwd(), option.path.Path_Output)
				write.TABLE_PET(;DayHour, meteo, Nmeteo, Path_Output, Pet, Pet_Obs)

				# Plotting
					plot.PLOT_PET(;DayHour, Pet, Pet_Obs)

				# @show meteo
		end  # function: PET
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	function PENMAN_MONTEITH_HOURLY(;cst, DayHour, iT, Latitude, Longitude, meteo, param )

      RelativeHumidity = meteo.RelativeHumidity[iT]
      Radₛ             = meteo.SolarRadiation[iT]
      Temp             = meteo.Temp[iT]
      TempSoil         = meteo.TempSoil[iT]
      Wind             = meteo.Wind[iT]
      DateTime         = DayHour[iT]

		Rₐ_Inv = evapoFunc.aerodynamic.Rₐ_INV_AERODYNAMIC_RESISTANCE(;param.Hcrop, cst.Karmen, Wind, param.Z_Humidity, param.Z_Wind)
			# println("Rₐ_INV =",  1/ Rₐ_Inv)

		Rₛ = evapoFunc.aerodynamic.Rₛ_SURFACE_RESISTANCE(;param.R_Stomatal, param.Hcrop)
			# 	@show Rₛ

		Pressure = evapoFunc.physics.ATMOSPHERIC_PRESSURE(;param.Z_Altitude)
			# 	println("Pressure=", Pressure )

		γ = evapoFunc.physics.γ_PSYCHROMETRIC(;cst.Cₚ, Pressure, cst.ϵ, cst.λ)
			# 	@show γ

		ρₐᵢᵣ = evapoFunc.physics.ρₐᵢᵣ_AIR_DENSITY(;Pressure, Temp, cst.T_Kelvin, cst.ℜ)
			# 	@show ρₐᵢᵣ

		Δ = evapoFunc.humidity.Δ_SATURATION_VAPOUR_P_CURVE(;Temp)
		# 	@show Δ

		Eₛ = evapoFunc.humidity.Eᴼ_SATURATION_VAPOUR_PRESSURE(;Temp)
		# 	@show Eₛ

		Eₐ = evapoFunc.humidity.Eₐ_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)
		# @show Eₐ
		# @show Eₛ - Eₐ

		Radₐ = evapoFunc.radiation.Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;DateTime, cst.Gsc, Latitude, Longitude, param.Z_Altitude)
		# 	@show Radₐ

		Radₙₗ = evapoFunc.radiation.Radₙₗ_LONGWAVE_RADIATION(;cst.σₕₒᵤᵣ, Temp, Eₐ, Radₛ, cst.T_Kelvin, Radₐ, param.Z_Altitude)
		# @show Radₙₗ

		ΔRadₙ = evapoFunc.radiation.ΔRadₙ_NET_RADIATION(;Radₙₗ, param.α, Radₛ)
		# @show ΔRadₙ

		G = evapoFunc.ground.G_SOIL_HEAT_FLUX_HOURLY(;DateTime, Latitude, Longitude, ΔRadₙ, param.Z_Altitude)
		# 	@show G

		Pet = evapoFunc.penmanmonteith.PET_PENMAN_MONTEITH_HOURLY(;cst.Cₚ, Eₐ, Eₛ, G, Rₐ_Inv, ΔRadₙ, Rₛ, γ, Δ, cst.λ, ρₐᵢᵣ)

		# @show ETₒ


	return Pet
	end  # function: PENMAN_MONTEITH
	#------------------------------------------------------------------

end

pet.RUN_PET()