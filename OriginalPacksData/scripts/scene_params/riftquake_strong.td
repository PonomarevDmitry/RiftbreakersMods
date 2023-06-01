TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.395"
				x "0.726"
				y "0.621"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.460"
				x "0.166"
				y "0.443"
				w "1.000"
			}

			fog_height "25.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}		
		skybox_specular_intensity "0.300"
		time_of_day "2"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.250"
			x "1.000"
			y "0.753"
			w "0.500"
		}
		light_size "0.05"
		fog_params
		{
			end "62.000"
			color
			{
				z "0.546"
				x "1.000"
				y "0.855"
				w "1.000"
			}

			start "47.000"
			density "0.202"
		}

	}

	weather_day
	{
		weather_sound "ambient/earthquake"
		time_of_day "0"
		weather_effect "effects/weather/rift_weather_strong"
		weather_wind "effects/wind/tornado_clean"
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "1.000"
				x "0.420"
				y "0.855"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "1.000"
				x "0.420"
				y "0.855"
				w "1.000"
			}

			fog_height "0.000"
			fade_in_distance "60.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}		
		skybox_specular_intensity "0.588"
		time_of_day "0"
		skybox_diffuse_intensity "0.403"
		light_color
		{
			z "0.376"
			x "1.000"
			y "0.784"
			w "0.500"
		}
		light_size "0.0001"
		fog_params
		{
			end "58.000"
			color
			{
				z "1.000"
				x "0.418"
				y "0.855"
				w "1.000"
			}

			start "46.000"
			density "0.300"
		}

	}

	weather_night
	{
		weather_sound "ambient/earthquake"
		time_of_day "2"
		weather_effect "effects/weather/rift_weather_strong"
		weather_wind "effects/wind/tornado_clean"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "1.000"
				x "1.000"
				y "1.000"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "0.000"
				y "0.000"
				w "1.000"
			}

			fog_height "0.000"
			fade_in_distance "50.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}		
		skybox_specular_intensity "0.100"
		time_of_day "3"
		skybox_diffuse_intensity "0.100"
		light_color
		{
			z "0.000"
			x "0.000"
			y "0.000"
			w "0.000"
		}
		light_size "0.2"
		fog_params
		{
			end "68.000"
			color
			{
				z "0.000"
				x "0.000"
				y "0.000"
				w "0.000"
			}

			start "52.000"
			density "0.000"
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
				x "0.980"
				y "0.263"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "1.000"
				y "0.244"
				w "1.000"
			}

			fog_height "0.100"
			fade_in_distance "60.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}		
		skybox_specular_intensity "0.300"
		time_of_day "1"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "0.500"
		}
		light_size "0.05"
		fog_params
		{
			end "61.000"
			color
			{
				z "0.031"
				x "0.982"
				y "0.262"
				w "1.000"
			}

			start "50.000"
			density "0.198"
		}
	}
}

