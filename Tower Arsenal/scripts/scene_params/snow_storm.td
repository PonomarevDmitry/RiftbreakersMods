TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.7260001"
				x "0.39500004"
				y "0.72380614"
				w "1"
			}

			max_distance "100"
			scattering_distribution "0"
			extinction_scale "0.75"
			emissive
			{
				z "0.46"
				x "0.166"
				y "0.443"
				w "1"
			}

			fog_height "25"
			fade_in_distance "55"
			fog_density "0.025"
			fade_in_falloff "10"
		}

		skybox_specular_intensity "0.125"
		time_of_day "2"
		skybox_diffuse_intensity "0.18"
		clouds_opacity "0"
		bloom_params
		light_color
		{
			z "0.99715227"
			x "0.32130405"
			y "0.9575843"
			w "20.000015"
		}

		weather_effect
		light_size "0.05"
		fog_params
		{
			end "62"
			color
			{
				z "0.546"
				x "1"
				y "0.855"
				w "1"
			}

			start "47"
			density "0.202"
		}

	}

	weather_day
	{
		weather_sound "ambient/wind_strong"
		time_of_day "0"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"
		weather_effect "effects/weather/snow_storm"
		weather_wind "effects/wind/strong"
		weather_biome_mod "effects/biome_mod/snow_burn"
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "1"
				x "0.42"
				y "0.855"
				w "1"
			}

			max_distance "100"
			scattering_distribution "0"
			extinction_scale "0.75"
			emissive
			{
				z "1"
				x "0.42"
				y "0.855"
				w "1"
			}

			fog_height "0"
			fade_in_distance "60"
			fog_density "0.025"
			fade_in_falloff "20"
		}

		skybox_specular_intensity "0.85"
		time_of_day "0"
		skybox_diffuse_intensity "0.5"
		clouds_opacity "0"
		bloom_params
		light_color
		{
			z "1"
			x "0.37600008"
			y "0.99545383"
			w "12.000002"
		}

		weather_effect
		light_size "0.01"
		fog_params
		{
			end "58"
			color
			{
				z "1"
				x "0.418"
				y "0.855"
				w "1"
			}

			start "46"
			density "0.3"
		}

	}

	weather_night
	{
		weather_sound "ambient/wind_strong"
		time_of_day "2"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"
		weather_effect "effects/weather/snow_storm"
		weather_wind "effects/wind/strong"
		weather_biome_mod "effects/biome_mod/snow_burn"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "1"
				x "1"
				y "1"
				w "1"
			}

			max_distance "100"
			scattering_distribution "0"
			extinction_scale "0.75"
			emissive
			{
				z "0"
				x "0"
				y "0"
				w "1"
			}

			fog_height "0"
			fade_in_distance "50"
			fog_density "0.025"
			fade_in_falloff "10"
		}

		skybox_specular_intensity "0.05"
		time_of_day "3"
		skybox_diffuse_intensity "0.1"
		clouds_opacity "0"
		bloom_params
		light_color
		{
			z "0"
			x "0"
			y "0"
			w "0"
		}

		weather_effect
		light_size "0.2"
		fog_params
		{
			end "68"
			color
			{
				z "0"
				x "0"
				y "0"
				w "0"
			}

			start "52"
			density "0"
		}

	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.031"
				x "0.98"
				y "0.263"
				w "1"
			}

			max_distance "100"
			scattering_distribution "0"
			extinction_scale "0.75"
			emissive
			{
				z "0"
				x "1"
				y "0.244"
				w "1"
			}

			fog_height "0.1"
			fade_in_distance "60"
			fog_density "0.025"
			fade_in_falloff "20"
		}

		skybox_specular_intensity "0.1"
		time_of_day "1"
		skybox_diffuse_intensity "0.18"
		clouds_opacity "0"
		bloom_params
		light_color
		{
			z "0.9820002"
			x "0.1020001"
			y "0.94551617"
			w "20.000006"
		}

		weather_effect
		light_size "0.05"
		fog_params
		{
			end "61"
			color
			{
				z "0.031"
				x "0.982"
				y "0.262"
				w "1"
			}

			start "50"
			density "0.198"
		}

	}

}

