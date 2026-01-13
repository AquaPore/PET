# =============================================================
#		module: option
# =============================================================
module readtoml

	using Configurations, TOML

	@option mutable struct PATH
      Path_Input        :: String
      Path_Output       :: String
	end # struct DATA


	@option mutable struct OPTION
		path         :: PATH
	end

	function READTOML(PathToml)

		@assert isfile(PathToml)

	return Configurations.from_toml(OPTION, PathToml)
	end  # function: OPTION

end  # module: option
# ............................................................