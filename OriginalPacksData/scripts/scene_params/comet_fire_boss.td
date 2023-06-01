TimeOfDayPreset
{
	weather_night
	{
		weather_sound
		weather_effect
		weather_wind "effects/wind/medium"
		weather_type "0"
		time_of_day "2"
	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.095"
				x "0.928"
				y "0.399"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.094"
				x "0.929"
				y "0.400"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}		
		skybox_specular_intensity "0.300"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.141"
				x "0.044"
				z "0.014"
			}

			start "52.000"
			end "68.000"
			density "0.298"
		}
		light_size "0.0001"
		light_color
		{
			w "20.000"
			y "0.361"
			x "0.982"
			z "0.102"
		}

		time_of_day "1"
		skybox_diffuse_intensity "0.180"
	}

	timeofday_day
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
		
		skybox_specular_intensity "1.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.913"
				x "0.068"
				z "0.144"
			}

			start "52.000"
			end "68.000"
			density "0.302"
		}
		light_size "0.0001"
		light_color
		{
			w "12.000"
			y "0.784"
			x "1.000"
			z "0.376"
		}

		time_of_day "0"
		skybox_diffuse_intensity "0.600"
	}

	weather_day
	{
		weather_sound
		weather_effect
		weather_wind "effects/wind/medium"
		weather_type "0"
		time_of_day "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.050"
			albedo
			{
				z "0.047"
				x "0.549"
				y "0.094"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "0.095"
				y "0.017"
				w "1.000"
			}

			fog_height "35.000"
			fade_in_distance "50.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}		
		skybox_specular_intensity "0.100"
		fog_params
		{
			color
			{
				w "1.000"
				y "0.000"
				x "0.000"
				z "0.000"
			}

			start "52.000"
			end "68.000"
			density "0.000"
		}
		light_size "0.0001"
		light_color
		{
			w "1.000"
			y "1.000"
			x "1.000"
			z "1.000"
		}

		time_of_day "3"
		skybox_diffuse_intensity "0.100"
	}

	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.004"
				x "0.714"
				y "0.192"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.003"
				x "0.715"
				y "0.194"
				w "1.000"
			}

			fog_height "35.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}		
		skybox_specular_intensity "0.300"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.855"
				x "0.509"
				z "0.168"
			}

			start "52.000"
			end "68.000"
			density "0.302"
		}
		light_size "0.0001"
		light_color
		{
			w "20.000"
			y "0.753"
			x "1.000"
			z "0.250"
		}

		time_of_day "2"
		skybox_diffuse_intensity "0.180"
	}

}

