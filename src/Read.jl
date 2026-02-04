# =============================================================
#		module: read
# =============================================================
module read
	using Dates, CSV, Tables, DataFrames

	Base.@kwdef mutable struct METEO
		# Id
      Id               :: Union{Missing,Vector}
		# Humidity [0-1]
      RelativeHumidity :: Union{Missing,Vector}
		# Solar radiation mean [ W/M⁻²]
      SolarRadiation   :: Union{Missing,Vector}
		# Maximum temperature [⁰C]
      Temp             :: Union{Missing,Vector}
		# Minimum temperature [⁰C]
      TempSoil         :: Union{Missing,Vector}
		# Velocity of wind speed [M S⁻¹]
      Wind             :: Union{Missing,Vector}
		# Data which are missing and which were artficially filled
      🎏_DataMissing   :: Union{Missing,Vector}
	end
"""
Read weather data from .csv

"""
	function READ_WEATHER(; date, path, flag)

		# Reading data from CSV
			Path_Input = joinpath(pwd(), path.Path_Input)
			@assert isfile(Path_Input)
			Data₀  = CSV.read(Path_Input, DataFrame; header=true)

			Id₀     = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Id))
			Year₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
			Month₀  = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
			Day₀    = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
			Hour₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))
			Minute₀ = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Minute))

			Nmeteo₀ = length(Year₀)

			DayHour = Dates.DateTime.(Year₀, Month₀, Day₀, Hour₀, Minute₀) #  <"standard"> "proleptic_gregorian" calendar

			RelativeHumidity₀ = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("Humidity[%]")))
			SolarRadiation₀   = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation[W/m²]")))
			Temp₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature[°C]")))
			TempSoil₀         = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SoilTemperature[°C]")))
			Wind₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("WindSpeed[m/s]")))

			if flag.🎏_PetObs
				Pet_Obs           = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("PotentialEvapotranspiration[mm]")))
			else
				Pet_Obs = zeros(Nmeteo₀)
			end
			🎏_DataMissing      = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("FlagMissing")))

		# Determening period of interest
			DateTrue = fill(false, Nmeteo₀)
			convert(Vector{Bool},DateTrue)
			for iD=1:Nmeteo₀
				if date.Id_Start ≤ iD ≤ date.Id_End
					DateTrue[iD] = true
				else
					DateTrue[iD] = false
				end
			end

		# Time step
			ΔT = zeros(Float64, Nmeteo₀)
			# Computing ΔT of the time step
				for iT=date.Id_Start:date.Id_End
					if iT ≥ 2
						ΔT[iT] = Dates.value(DayHour[iT] - DayHour[iT-1]) / 1000
						if ΔT[iT] < 600 || ΔT[iT] > 600
							println("Dates issue=", iT, " = ",ΔT[iT])
						end
					end
				end # for iT=1:Nmeteo
				ΔT[1] = copy(ΔT[2])

		# Conversion
			for iT=date.Id_Start:date.Id_End
				# [%] ➡ [0-1]
					RelativeHumidity₀[iT] = RelativeHumidity₀[iT] / 100.0

				# Removing negative values
					Pet_Obs[iT] = max(Pet_Obs[iT], 0.0)
			end # for iT=1:Nmeteo

      meteo = METEO(Id=Id₀[DateTrue], RelativeHumidity=RelativeHumidity₀[DateTrue], SolarRadiation=SolarRadiation₀[DateTrue], Temp=Temp₀[DateTrue], TempSoil=TempSoil₀[DateTrue], Wind=Wind₀[DateTrue], 🎏_DataMissing=🎏_DataMissing[DateTrue])

		# The new number of data
			Nmeteo = date.Id_End - date.Id_Start + 1

		# Testing if missing data
			FieldName = propertynames(meteo)
			for iiFieldName ∈ FieldName
				Struct_Array = getfield(meteo, iiFieldName)

				for iT=1:Nmeteo
					if ismissing(Struct_Array[iT])
						@error "$(iiFieldName) cell is empty at Id= $(Id₀[iT])"
					end
				end # for iT=1:Nmeteo
			end # for iiFieldName ∈ FieldName

	return DayHour[DateTrue], meteo, Nmeteo, Pet_Obs[DateTrue], ΔT[DateTrue]
	end # function READ_WEATHER

end  # module: read
# ............................................................