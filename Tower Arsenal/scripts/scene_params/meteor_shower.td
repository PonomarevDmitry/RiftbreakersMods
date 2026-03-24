TimeOfDayPreset
{
	weather_night
	{
		weather_sound
		weather_effect "effects/weather/meteor_shower"
		weather_wind "effects/wind/medium"
		weather_type "1"
		time_of_day "2"
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
		skybox_specular_intensity "0.00"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.761"
				x "0.270"
				z "1.000"
			}

			start "48.000"
			end "68.000"
			density "0.100"
		}
		light_size "0.05"
		light_color
		{
			w "1.891"
			y "0.361"
			x "0.982"
			z "0.000"
		}

		time_of_day "1"
		skybox_diffuse_intensity "0.180"
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
		skybox_specular_intensity "0.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.823"
				x "0.328"
				z "1.000"
			}

			start "48.000"
			end "68.000"
			density "0.200"
		}
		light_size "0.010"
		light_color
		{
			w "1.964"
			y "0.784"
			x "1.000"
			z "0.376"
		}

		time_of_day "0"
		skybox_diffuse_intensity "0.595"
	}

	weather_day
	{
		weather_sound
		weather_effect "effects/weather/meteor_shower"
		weather_wind "effects/wind/medium"
		weather_type "1"
		time_of_day "0"
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
		skybox_specular_intensity "0.000"
		fog_params
		{
			color
			{
				w "0.000"
				y "0.807"
				x "0.305"
				z "1.000"
			}

			start "48.000"
			end "68.000"
			density "0.027"
		}
		light_size "0.2"
		light_color
		{
			w "0.000"
			y "0.000"
			x "0.000"
			z "0.000"
		}

		time_of_day "3"
		skybox_diffuse_intensity "0.096"
	}

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
		skybox_specular_intensity "0.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.863"
				x "0.423"
				z "0.947"
			}

			start "48.000"
			end "68.000"
			density "0.100"
		}
		light_size "0.05"
		light_color
		{
			w "2.036"
			y "0.753"
			x "1.000"
			z "0.250"
		}

		time_of_day "2"
		skybox_diffuse_intensity "0.180"
	}

}

