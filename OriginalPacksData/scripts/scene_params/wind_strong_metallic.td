TimeOfDayPreset
{
	timeofday_sunrise
	{
		skybox_specular_intensity "0.210"
		physics_gravity_factor "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.115"
		light_color
		{
			z "1.000"
			x "0.723"
			y "0.776"
			w "19.818"
		}

		weather_effect
		light_size "0.030"
		fog_params
		{
			end "55.000"
			color
			{
				z "0.283"
				x "0.002"
				y "0.033"
				w "1.000"
			}

			start "37.000"
			density "0.709"
		}

	}

	weather_day
	{
		weather_sound "ambient/wind_strong"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"	
		time_of_day "0"
		weather_effect "effects/weather/wind_strong"
		weather_wind "effects/wind/strong"
		weather_type "0"
	}

	timeofday_day
	{
		skybox_specular_intensity "0.497"
		physics_gravity_factor "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.000"
		light_color
		{
			z "1.000"
			x "0.947"
			y "0.965"
			w "10.364"
		}

		weather_effect
		light_size "0.000"
		fog_params
		{
			end "58.000"
			color
			{
				z "0.930"
				x "0.010"
				y "0.084"
				w "1.000"
			}

			start "46.000"
			density "0.403"
		}

	}

	weather_night
	{
		weather_sound "ambient/wind_strong"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"	
		time_of_day "2"
		weather_effect "effects/weather/wind_strong"
		weather_wind "effects/wind/strong"
		weather_type "0"
	}

	timeofday_night
	{
		skybox_specular_intensity "0.103"
		physics_gravity_factor "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.000"
		light_color
		{
			z "0.000"
			x "0.000"
			y "0.000"
			w "0.000"
		}

		weather_effect
		light_size "0.200"
		fog_params
		{
			end "48.000"
			color
			{
				z "0.074"
				x "0.002"
				y "0.004"
				w "1.000"
			}

			start "38.000"
			density "0.902"
		}

	}

	timeofday_sunset
	{
		skybox_specular_intensity "0.300"
		physics_gravity_factor "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "1.000"
			x "0.776"
			y "0.947"
			w "20.000"
		}

		weather_effect
		light_size "0.050"
		fog_params
		{
			end "56.000"
			color
			{
				z "0.982"
				x "0.031"
				y "0.191"
				w "1.000"
			}

			start "42.000"
			density "0.410"
		}

	}

}

