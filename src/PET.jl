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

				DayHour, meteo, Nmeteo, Pet_Obs, ΔT = read.READ_WEATHER(Path_Input)

				Pet = zeros(Float64, Nmeteo)

				Latitude, Longitude = pet.PENMAN_MONTEITH_CONSTANT(; option.param.Latitude_Minute, option.param.Latitude_ᴼ, option.param.Longitude_Minute, option.param.Longitude_ᴼ)

				for  (iT, iiDateTime) in enumerate(DayHour)
					Pet[iT] = pet.PENMAN_MONTEITH(;DayHour, cst=option.cst, iT, Latitude, Longitude, meteo, param=option.param,  ΔT₁=ΔT[iT])
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
	#		FUNCTION : PENMAN_MONTEITH_CONSTANT
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PENMAN_MONTEITH_CONSTANT(;Latitude_Minute, Latitude_ᴼ, Longitude_Minute, Longitude_ᴼ)

			Latitude, Longitude = evapoFunc.utils.LATITUDE_DEGREE_HOUR_2_DEGREE(;Latitude_Minute, Latitude_ᴼ,Longitude_Minute, Longitude_ᴼ)
				println("Latitude= ", Latitude )
				println("Longitude= ", Longitude )

		return Latitude, Longitude
		end  # function: PENMAN_MONTEITH_CONSTANT
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PENMAN_MONTEITH(;cst, DayHour, iT, Latitude, Longitude, meteo, param, ΔT₁)
			RelativeHumidity = meteo.RelativeHumidity[iT]
			Radₛ             = meteo.SolarRadiation[iT]
			Temp             = meteo.Temp[iT]
			TempSoil         = meteo.TempSoil[iT]
			Wind             = meteo.Wind[iT]
			DateTime         = DayHour[iT]

			λᵥ = evapoFunc.physics.λ_LATENT_HEAT_VAPORIZATION(;Temp)

			Pressure = evapoFunc.physics.ATMOSPHERIC_PRESSURE(;cst.T_Kelvin, Temp, param.Z_Altitude)

			Rₐ_Inv = evapoFunc.aerodynamic.Rₐ_INV_AERODYNAMIC_RESISTANCE(;param.Hcrop, cst.Karmen, Wind, param.Z_Humidity, param.Z_Wind)

			Rₛ = evapoFunc.aerodynamic.Rₛ_SURFACE_RESISTANCE(;param.R_Stomatal, param.Hcrop)

			γ = evapoFunc.physics.γ_PSYCHROMETRIC(;cst.Cₚ, Pressure, cst.ϵ, λᵥ)

			Δ = evapoFunc.humidity.Δ_SATURATION_VAPOUR_P_CURVE(;Temp)

			Eₛ = evapoFunc.humidity.Eᴼ_SATURATION_VAPOUR_PRESSURE(;Temp)

			Eₐ = evapoFunc.humidity.Eₐ_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)

			ρₐᵢᵣ = evapoFunc.physics.ρₐᵢᵣ_AIR_DENSITY(;Pressure, Temp, cst.T_Kelvin, cst.ℜ, Eₐ)

			Radₐ, 🎏_Daylight = evapoFunc.radiation.Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;DateTime, cst.Gsc, Latitude, Longitude, param.Z_Altitude, ΔT₁)

			Radₛₒ = evapoFunc.radiation.Radₛₒ_CLEAR_SKY_RADIATION(;Radₐ, param.Z_Altitude)

			Radₙₗ = evapoFunc.radiation.Radₙₗ_LONGWAVE_RADIATION(;cst.σ, Temp, Eₐ, Radₛ, cst.T_Kelvin,  Radₛₒ)

			Radₙₛ = evapoFunc.radiation.Radₙₛ_NET_SHORTWAVE_RADIATION_REFLECTED(;param.α, Radₛ)

			ΔRadₙ = evapoFunc.radiation.ΔRadₙ_NET_RADIATION(;Radₙₗ, Radₙₛ)

			G = evapoFunc.ground.G_SOIL_HEAT_FLUX_HOURLY(;DateTime, Latitude, Longitude, ΔRadₙ, param.Z_Altitude, 🎏_Daylight)

			Pet = evapoFunc.penmanmonteith.PET_PENMAN_MONTEITH_HOURLY(;cst.Cₚ, param.Kc, Eₐ, Eₛ, G, Rₐ_Inv, ΔRadₙ, Rₛ, γ, Δ, λᵥ, ρₐᵢᵣ, ΔT₁)
		return Pet
		end  # function: PENMAN_MONTEITH
	#------------------------------------------------------------------
end

pet.RUN_PET()