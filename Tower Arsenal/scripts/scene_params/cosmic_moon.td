TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.856"
				x "0.055"
				y "0.262"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.479"
				x "0.029"
				y "0.073"
				w "1.000"
			}

			fog_height "15.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.100"
		clouds_opacity "0.220"
		bloom_params
		light_color
		{
			z "0.980"
			x "0.763"
			y "0.447"
			w "1.500"
		}

		weather_effect
		light_size "0.010"
		fog_params
		{
			end "68.000"
			color
			{
				z "1.000"
				x "0.000"
				y "0.584"
				w "0.039"
			}

			start "20.000"
			density "0.199"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/cosmic_moon"
		weather_wind "effects/wind/medium"
		weather_biome_mod
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.929"
				x "0.012"
				y "0.500"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.929"
				x "0.012"
				y "0.082"
				w "1.000"
			}

			fog_height "0.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}

		skybox_specular_intensity "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.100"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.980"
			x "0.763"
			y "0.447"
			w "1.500"
		}

		weather_effect
		light_size "0.010"
		fog_params
		{
			end "68.000"
			color
			{
				z "1.000"
				x "0.000"
				y "0.584"
				w "0.039"
			}

			start "20.000"
			density "0.199"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/cosmic_moon"
		weather_wind "effects/wind/medium"
		weather_biome_mod
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.978"
				x "0.431"
				y "0.963"
				w "12.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "1.000"
				x "0.491"
				y "0.611"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.100"
		time_of_day "3"
		skybox_diffuse_intensity "0.350"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.980"
			x "0.763"
			y "0.447"
			w "1.500"
		}

		weather_effect
		light_size "0.010"
		fog_params
		{
			end "60.000"
			color
			{
				z "0.000"
				x "0.521"
				y "0.000"
				w "1.000"
			}

			start "0.000"
			density "0.200"
		}

	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.000"
				x "0.769"
				y "0.016"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "0.769"
				y "0.016"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.100"
		time_of_day "3"
		skybox_diffuse_intensity "0.350"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.980"
			x "0.763"
			y "0.447"
			w "1.500"
		}

		weather_effect
		light_size "0.010"
		fog_params
		{
			end "60.000"
			color
			{
				z "0.000"
				x "0.521"
				y "0.000"
				w "1.000"
			}

			start "0.000"
			density "0.200"
		}

	}

}

