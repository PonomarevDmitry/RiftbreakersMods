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
		light_color
		{
			z "1.000"
			x "0.000"
			y "0.300"
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
		weather_effect "effects/weather/blue_moon"
		weather_wind "effects/wind/medium"
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
		light_color
		{
			z "1.000"
			x "0.000"
			y "0.300"
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
		weather_effect "effects/weather/blue_moon"
		weather_wind "effects/wind/medium"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.734"
				x "0.100"
				y "0.394"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.551"
				x "0.034"
				y "0.085"
				w "1.000"
			}

			fog_height "10.000"
			fade_in_distance "50.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}		
		skybox_specular_intensity "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.1"
		light_color
		{
			z "1.000"
			x "0.000"
			y "0.300"
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

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.525"
				x "0.223"
				y "0.274"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.791"
				x "0.015"
				y "0.146"
				w "1.000"
			}

			fog_height "10.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}		
		skybox_specular_intensity "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.100"
		light_color
		{
			z "1.000"
			x "0.000"
			y "0.300"
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

}

