TimeOfDayPreset
{
	timeofday_sunrise
	{
		skybox_specular_intensity "0.300"
		time_of_day "2"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.250"
			x "1.000"
			y "0.753"
			w "20.000"
		}

		weather_effect
		light_size "0.050"
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
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/sudden_pressure_change"
		weather_wind "effects/wind/medium"
		weather_type "0"
	}

	timeofday_day
	{
		skybox_specular_intensity "0.588"
		time_of_day "0"
		skybox_diffuse_intensity "0.403"
		light_color
		{
			z "0.376"
			x "1.000"
			y "0.784"
			w "12.000"
		}

		weather_effect
		light_size "0.010"
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
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/sudden_pressure_change"
		weather_wind "effects/wind/medium"
		weather_type "0"
	}

	timeofday_night
	{
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

		weather_effect
		light_size "0.200"
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
		skybox_specular_intensity "0.300"
		time_of_day "1"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "20.000"
		}

		weather_effect
		light_size "0.050"
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

