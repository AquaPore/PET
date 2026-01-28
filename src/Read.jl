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

	function READ_WEATHER(Path_Input)
		@assert isfile(Path_Input)

      Data₀  = CSV.read(Path_Input, DataFrame; header=true)

      Id₀     = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Id))
      Year₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
      Month₀  = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
      Day₀    = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
      Hour₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))
      Minute₀ = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Minute))

		Nmeteo = length(Year₀)

		DayHour = Dates.DateTime.(Year₀, Month₀, Day₀, Hour₀, Minute₀) #  <"standard"> "proleptic_gregorian" calendar

      RelativeHumidity₀ = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("Humidity[%]")))
      SolarRadiation₀   = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation[W/m²]")))
      Temp₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature[°C]")))
      TempSoil₀         = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SoilTemperature[°C]")))
      Wind₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("WindSpeed[m/s]")))
      Pet_Obs           = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("PotentialEvapotranspiration[mm]")))
		🎏_DataMissing      = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("FlagMissing")))

		ΔT = zeros(Float64, Nmeteo)
		# Computing ΔT of the time step
			for iT=1:Nmeteo
				if iT ≥ 2
					ΔT[iT] = Dates.value(DayHour[iT] - DayHour[iT-1]) / 1000
					if ΔT[iT] < 600 || ΔT[iT] > 600
						println("Dates issue=", iT, " = ",ΔT[iT])
					end
				end
			end # for iT=1:Nmeteo
			ΔT[1] = copy(ΔT[2])

		# Conversion
		for iT=1:Nmeteo
			# [%] ➡ [0-1]
				RelativeHumidity₀[iT] = RelativeHumidity₀[iT] / 100.0

			# Removing negative values
				Pet_Obs[iT] = max(Pet_Obs[iT], 0.0)

			# Convert [W m⁻² second⁻¹] ➡ [MJ m⁻² ΔT⁻¹]
				# SolarRadiation₀[iT] = SolarRadiation₀[iT] * ΔT[iT] * 1.0E-6
		end # for iT=1:Nmeteo

      meteo = METEO(Id=Id₀, RelativeHumidity=RelativeHumidity₀, SolarRadiation=SolarRadiation₀, Temp=Temp₀, TempSoil=TempSoil₀, Wind=Wind₀,    🎏_DataMissing=🎏_DataMissing)

		# Testing for missing data
		FieldName = propertynames(meteo)
		for iiFieldName ∈ FieldName
			Struct_Array = getfield(meteo, iiFieldName)

			for iT=1:Nmeteo
				if ismissing(Struct_Array[iT])
					@error "$(iiFieldName) cell is empty at Id= $iT"
				end
			end # for iT=1:Nmeteo
		end # for iiFieldName ∈ FieldName

	return DayHour, meteo, Nmeteo, Pet_Obs, ΔT
	end # function READ_WEATHER

end  # module: read
# ............................................................