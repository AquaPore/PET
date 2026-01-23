# =============================================================
#		module: read
# =============================================================
module read

	using Dates, CSV, Tables, DataFrames

	Base.@kwdef mutable struct METEO
		# Humidity [0-1]
      	RelativeHumidity            :: Union{Missing,Vector}
		# Solar radiation mean [ W/M⁻²]
      	SolarRadiation  :: Union{Missing,Vector}
		# Maximum temperature [⁰C]
      	Temp            :: Union{Missing,Vector}
		# Minimum temperature [⁰C]
      	TempSoil         :: Union{Missing,Vector}
		# Velocity of wind speed [M S⁻¹]
      	Wind              :: Union{Missing,Vector}
	end

	function READ_WEATHER(Path_Input)

		@assert isfile(Path_Input)

		Data₀ = CSV.read(Path_Input, DataFrame; header=true)

      Year                = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
      Month               = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
      Day                 = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
      Hour                = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

		DayHour = Dates.DateTime.(Year, Month, Day, Hour) #  <"standard"> "proleptic_gregorian" calendar

      RelativeHumidity = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("Humidity[%]"))) ./ 100.0
      SolarRadiation   = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation_Mean[W/M2]")))
      Temp             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature_Mean[⁰C]")))
      TempSoil         = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SoilTemperature[⁰C]")))
      Wind             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("WindSpeed_Mean[M/S]")))
      Pet_obs          = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("PET_Obs[MM]")))

		Nmeteo = length(Year)

		meteo = METEO(RelativeHumidity, SolarRadiation, Temp, TempSoil, Wind)

		# Testing for missing data
		FieldName = propertynames(meteo)
		for iiFieldName ∈ FieldName
			Struct_Array = getfield(meteo, iiFieldName)

			for i=1:Nmeteo
				if ismissing(Struct_Array[i])
					@error "$(iiFieldName) cell is empty at Id= $i"
				end
			end
		end

		#	PRODCESSING
			# Convert [%] ➡ [0-1]
				meteo.RelativeHumidity = meteo.RelativeHumidity ./ 100.0

			# Convert [W m⁻² hour⁻¹] ➡ [MJ m⁻² hour⁻¹]
				meteo.SolarRadiation = meteo.SolarRadiation * 60.0 * 60.0 * 1.0E-6

			# Removing negative values
				Pet_obs = max.(Pet_obs, 0.0)

	return DayHour, meteo, Nmeteo, Pet_obs
	end

end  # module: read
# ............................................................