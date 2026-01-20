# =============================================================
#		module: evapoFunc
# =============================================================
module evapoFunc

	# =============================================================
	#		module: aerodynamic
	# =============================================================
	module aerodynamic
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :Rₐ_INV
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		rₐ: [s m⁻¹] AERODYNAMIC RESISTANCE,

		INPUT
			Z_Wind:  [m] height of wind measurements,
			Z_Humidity: [m]:  height of humidity measurements,
			wIND: [m s⁻¹] wind speed at height Z_Wind,
			Hcrop: [m] height of the crop

		PROCESSES
			Z_ZERO_PLANE() [m]zero plane displacement height ,
			Z_ROUGHNESS_MOMENTUM() [m] roughness length governing momentum transfer [m],
			Z_ROUGHNESS_TRANSFER() [m] roughness length governing transfer of heat and vapour [m],

		# CONSTANT
			k [m] von Karman's constant, 0.41 [-],
		"""
		function Rₐ_INV_AERODYNAMIC_RESISTANCE(;Hcrop, Karmen, Wind, Z_Humidity, Z_Wind)
			#------------------------------
				function Z_ZERO_PLANE(Hcrop)
					Z_0 = (2.0 / 3.0) * Hcrop
				return Z_0
				end
			#------------------------------
			#------------------------------
				function Z_ROUGHNESS_MOMENTUM(Hcrop)
					Z_RoughnessMomentum = 0.123 * Hcrop
				return Z_RoughnessMomentum
				end  # function: Z_ROUGHNESS_MOMENTUM
			#------------------------------
			#------------------------------
				function Z_ROUGHNESS_TRANSFER(Z_RoughnessMomentum)
					Z_RoughnessTransfer = 0.1 * Z_RoughnessMomentum
					return Z_RoughnessTransfer
				end  # function: Z_ROUGHNESSMOMENTUM
			#------------------------------

			Z_0 = Z_ZERO_PLANE(Hcrop)
			Z_RoughnessMomentum = Z_ROUGHNESS_MOMENTUM(Hcrop)
			Z_RoughnessTransfer = Z_ROUGHNESS_TRANSFER(Z_RoughnessMomentum)

			if Z_Wind < Z_0
				error("Z_Wind = $Z_Wind ≥ Z_0 = $Z_0")
			end
			if Z_Humidity < Z_0
				error("Z_Humidity = $Z_Wind ≥ Z_0 = $Z_0")
			end

			Rₐ_Inv =  (Wind * Karmen^2 ) / log((Z_Wind - Z_0 ) / Z_RoughnessMomentum) * log((Z_Humidity - Z_0) / Z_RoughnessTransfer)

			return Rₐ_Inv
			end  # function: Rₐ_INV_AERODYNAMIC_RESISTANCE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :  Rₛ_SURFACE_RESISTANCE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Rₛ: [s m⁻¹] SURFACE RESISTANCE

		INPUT:
			* R_Stomatal: [s m⁻¹] bulk stomatal resistance of the well-illuminated leaf,
			* Hcrop: [m] height of the crop
		"""
			function Rₛ_SURFACE_RESISTANCE(;R_Stomatal, Hcrop)
				LAI = min(24.0 * Hcrop, 5.0)
				LAIactive = LAI * 0.5

				Rₛ = R_Stomatal / LAIactive
			return Rₛ
			end  # function: Rₛ_SURFACE_RESISTANCE
		# ------------------------------------------------------------------

	end  # module: aerodynamic
	# ............................................................

	# =============================================================
	#		module: psychometric
	# =============================================================
	module psychometric
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : ATMOSPHERIC_PRESSURE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function ATMOSPHERIC_PRESSURE(;Z_Altitude)
				P = 101.3 * ((293.0 - 0.0065 * Z_Altitude) / 293 ) ^ 5.26
			return P
			end  # function: ATMOSPHERIC_PRESSURE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : γ_PSYCHROMETRIC
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		γ PSYCHROMETRIC CONSTANT [kPa °C-1],
		The specific heat at constant pressure is the amount of energy required to increase the temperature of a unit mass of air by one degree at constant pressure.

		INPUT:
		P atmospheric pressure [kPa],

		CONSTANTS:
			* λ: [MJ kg-1] latent heat of vaporization, 2.45 ,
			* Cp: [MJ kg-1 °C-1] specific heat at constant pressure, 1.013 10-3 ,
			* ε: ratio molecular weight of water vapour/dry air = 0.622.
		"""
			function γ_PSYCHROMETRIC(;Cₚ, P, ϵ, λ)
				γ = (Cₚ * P) /  (ϵ * λ)
			return γ
			end  # function: ϵ
		# ------------------------------------------------------------------
	end  # module: psychometric
	# ............................................................


	# =============================================================
	#		module: humidity
	# =============================================================
	module humidity
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Eᴼ_SATURATED_VAPOUR_PRESSURE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Eᴼ(T) [kPa]: saturation vapour pressure at the air temperature
		"""
			function Eᴼ_SATURATION_VAPOUR_PRESSURE(;T)
				Eᴼ = 0.6108 * exp(17.27 * T / (T + 237.3))
			return Eᴼ
			end  # function: SATURATED_VAPOUR_PRESSURE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Eₐ [kPa] ACTUAL VAPOUR PRESSURE

		INPUT
		RelativeHumidity: [0-1  degree of saturation of the air (eₐ) to the saturation (eₛ =eₒ(T)) vapour pressure at the same temperature (T):
		"""
			function Ea_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)
				Eₐ = 	RelativeHumidity * Eₛ
				@assert RelativeHumidity ≤ 1.0
				@assert Eₛ ≥ Eₐ
			return Eₐ
			end  # function: Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Δ_SATURATION_VAPOUR_P_CURVE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			"""
			Δ: [kPa °C-1] SLOPE OF SATURATION VAPOUR PRESSURE CURVE AT AIR TEMPERATURE T ,
			slope of the relationship between saturation vapour pressure and temperature
			"""
			function Δ_SATURATION_VAPOUR_P_CURVE(;T)
				Δ = 4098.0 *0.6108 * exp(17.27 * T / (T + 237.3)) / (T + 237.3) ^ 2
			return Δ
			end  # function: Δ_SATURATION_VAPOUR_P_CURVE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Ea_2_Tdew
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		""" not used """
			function Eₐ_2_Tdew(;Eₐ)
				P₁ = (1.0 / 17.27) * log(Eₐ / 0.6108)
				Tdew = 237.3 * P₁ / (1.0 - P₁)
			return Tdew
			end  # function: Ea_2_Tdew
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			""" not used """
			function Eₐ_ACTUAL_VAPOUR_PRESSURE_Tdew(;Tdew)
				Eₐ = 0.6108 * exp((17.27 * Tdew)/(Tdew + 237.3))
			return Eₐ
			end  # function: Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ------------------------------------------------------------------
	end  # module: humidity
	# ............................................................


	# =============================================================
	#		module: radiation
	# =============================================================
	module radiation
		using Dates

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Extraterrestrial_radiation
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""Estimate daily extraterrestrial radiation (*Ra*, 'top of the atmosphere
		radiation').

		Based on equation 21 in Allen et al (1998). If monthly mean radiation is
		required make sure *sol_dec*. *sha* and *irl* have been calculated using
		the day of the year that corresponds to the middle of the month.

		**Note**: From Allen et al (1998): "For the winter months in latitudes
		greater than 55 degrees (N or S), the equations have limited validity.
		Reference should be made to the Smithsonian Tables to assess possible
		deviations."

		:param latitude: Latitude [radians]
		:param sol_dec: Solar declination [radians]. Can be calculated using
			``sol_dec()``.
		:param sha: Sunset hour angle [radians]. Can be calculated using
			``sunset_hour_angle()``.
		:param ird: Inverse relative distance earth-sun [dimensionless]. Can be
			calculated using ``inv_rel_dist_earth_sun()``.
		:return: Daily extraterrestrial radiation [MJ m-2 day-1]

		* Rₐ [MJ m-2 hour-1] EXTRATERRESTRIAL RADIATION IN THE HOUR (OR SHORTER) PERIOD ,

		INPUT
			* Gsc: [MJ m-2 min-1] solar constant = 0.0820 ,
			* Dₑₛ: [m] inverse relative distance Earth-Sun (Equation 23),
			* δ: solar declination [rad] (Equation 24),
			* ϕ: latitude [rad] (Equation 22),
			* ω1 [rad]: solar time angle at beginning of period [rad] (Equation 29),
			* ω2 [rad]: solar time angle at end of period  (Equation 30).
			* ΔT [hour] time step
			* Longitude_ᴼ : Longitude of the measured site [degress west of Greenwish]
			* longitude of the measurement site [degrees west of Greenwich]

			PROCESS
			ω [rad] solar time angle at midpoint of hourly or shorter period [rad]
			ωₛ [rad] sunset hour angle

		"""

		function  Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;Gsc, Longitude_ᴼ, Latitude_Minute, Date, ΔT=1.0, Latitude_ᴼ, Lz= 0.0)

         Latitude_Radian = (Latitude_ᴼ + Latitude_Minute / 60.0) * π/180
         DayOfYear       = Dates.dayofyear(Date)
         Hour            = Dates.hour(Date)

			δ_SOLAR_INCLINATION(DayOfYear) = 0.409 * sin(DayOfYear * 2.0 * π / 365.0 - 1.39)
			δ = δ_SOLAR_INCLINATION(DayOfYear)

			function ω_SOLAR_TIME_ANGLE_DAY(;Hour, DayOfYear, ΔT, δ)
            ωₛ  = acos(-tan(Latitude_Radian) * tan(δ))
			return ωₛ
			end #  ω_SOLAR_TIME_ANGLE

			function ω_SOLAR_TIME_ANGLE_HOUR(;Hour, DayOfYear, ΔT)
				# ωday_SOLAR_TIME_ANGLE(Latitude_Radian, δ) = acos(-tan(Latitude_Radian) * tan(δ))
            B  = 2 * π * (DayOfYear - 81) / 364
            Sc = 0.1645 * sin(2*B) - 0.1255 * cos(B) - 0.025 * sin(B)
            ω  = ((Hour + 0.06667 * (Lz - Longitude_ᴼ) * Sc ) - 12.0) * π / 12.0

				ω₁ = ω - π * ΔT / 24.0
				ω₂ = ω + π * ΔT / 24.0
			return ω₁, ω₂
			end #  ω_SOLAR_TIME_ANGLE

			ω₁, ω₂ = ω_SOLAR_TIME_ANGLE_HOUR(Hour, DayOfYear, ΔT)

			Dₑₛ_INVERSE_DISTANCE_SUN_EARTH(DayOfYear) = 1.0 + 0.033 * cos(DayOfYear * 2.0 * π / 365.0)
			Dₑₛ = Dₑₛ_INVERSE_DISTANCE_SUN_EARTH(DayOfYear)



			Rₐ = (12.0 * 60.0 / π) * Gsc * Dₑₛ * (ω₂ - ω₁) * sin(Latitude_Radian) * sin(δ) + cos(Latitude_Radian) * cos(δ) * (sin(ω₂)- sin(ω₁))
		return Rₐ
		end  # function: Extraterrestrial_radiation
	# ------------------------------------------------------------------

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rₙₗ_LONGWAVE RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Rₙₗ: [MJ m-2 day-1] NET OUTGOING LONGWAVE RADIATION.

		INPUT
			* σ: [MJ K-4 m-2 day-1] Stefan-Boltzmann constant [ 4.903 10-9 ];
			* T_max: [ᵒC] maximum  temperature during the 24-hour period,
			* T_min: [ᵒC] minimum temperature during the 24-hour period;
			* eₐ: [kPa] actual vapour pressure;
			* Rₛ: [MJ m-2 day-1] measured solar radiation;

		PROCESSES
			* Rₛₒ[MJ m-2 day-1]: clear-sky radiation.

		Rₛ/Rₛₒ relative shortwave radiation (limited to ≤ 1.0),
		"""
			function Rₙₗ_LONGWAVE_RADIATION(;σ, T_Min, T_Max, eₐ, Rₛ, T_Kelvin, Rₐ, Z_Altitude)

				function Rₛₒ_CLEAR_SKY_RADIATION(;Rₐ, Z_Altitude)
					Rₛₒ = (0.75 + 2.0E-5 * Z_Altitude) * Rₐ
				return Rₛₒ

				T₁ = (σ * ((T_Kelvin + T_Max)^4 + (T_Kelvin + T_Min)^4) / 2.0)

				# Correction for air humidity
					T₂ = (0.34 - (0.14 * √eₐ))

				# Correction for effect of cloundiness
					Rₛₒ = Rₛₒ_CLEAR_SKY_RADIATION(;Rₐ, Z_Altitude)
					T₃ = (1.35 * min(Rₛ / Rₛₒ, 1.0) - 0.35)

				Rₙₗ =  T₁ * T₂ * T₃
			return Rₙₗ
			end  # function: Rₙₗ_LONGWAVE RADIATION
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rₙ_NET_RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Rₙ [MJ m-2 day-1] NET RADIATION AT THE CROP SURFACE

		INPUT
			* Rₙₛ: [MJ m-2 day-1] Incoming net shortwave radiation,
		 	* Rₙₗ: [MJ m-2 day-1] Outgoing net longwave radiation.

		PARAMETER
			* α: [-] albedo or canopy reflection coefficient, which is 0.23 for the hypothetical grass reference crop

		PROCESSES
			* Rₙₛ: [MJ m-2 day-1] net shortwave radiation resulting from the balance between incoming and reflected solar radiation

		"""
			function Rₙ_NET_RADIATION(;Rₙₗ, α, Rₛ)

				function Rₙₛ_NET_SHORTWAVE_RADIATION(;α, Rₛ)
					Rₙₛ = (1.0 - α ) * Rₛ
				return Rₙₛ
				end  # function: Rₙₛ_NET_SHORTWAVE_RADIATION

		 		Rₙₛ = Rₙₛ_NET_SHORTWAVE_RADIATION(;α, Rₛ)

				Rₙ = Rₙₛ - Rₙₗ
			return Rₙ
			end  # function: Rₙ_NET_RADIATION
		# ------------------------------------------------------------------

	end  # module: radiation
	# ............................................................

end  # module: evapoFunc
# ............................................................

