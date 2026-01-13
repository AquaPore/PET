module pet
	import Dates, CSV, Tables

	include("Read.jl")
	include("Write.jl")
	include("ReadToml.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function RUN_PET()
			Path_Toml₀ =  raw"DATA\PARAMETER\PetOption.toml"
			Path_Toml = joinpath(pwd(), Path_Toml₀)

			option = readtoml.READTOML(Path_Toml)

			Path_Input = joinpath(pwd(), option.path.Path_Input)
			DateTime, meteo, Nmeteo = read.READ_WEATHER(Path_Input)


			Path_Output = joinpath(pwd(), option.path.Path_Output)
			write.TABLE_PET(meteo, Nmeteo, Path_Output)

			# @show meteo
		end  # function: PET
	# ------------------------------------------------------------------

end

