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
			x "0.651"
			y "1.000"
			w "1.000"
		}

		weather_effect
		light_size "0.075"
		fog_params
		{
			end "68.000"
			color
			{
				z "0.000"
				x "0.500"
				y "1.000"
				w "0.500"
			}

			start "40.000"
			density "1.000"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/blooming_air"
		weather_wind "effects/wind/gentle"
		weather_type "1"
	}

	timeofday_day
	{
		skybox_specular_intensity "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.600"
		light_color
		{
			z "0.376"
			x "0.440"
			y "1.000"
			w "1.000"
		}

		weather_effect
		light_size "0.070"
		fog_params
		{
			end "68.000"
			color
			{
				z "0.000"
				x "0.500"
				y "1.000"
				w "0.500"
			}

			start "40.000"
			density "1.000"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/blooming_air"
		weather_wind "effects/wind/gentle"
		weather_type "1"
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
				x "0.500"
				y "1.000"
				w "0.500"
			}

			start "40.000"
			density "0.502"
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
			x "0.708"
			y "0.982"
			w "1.000"
		}

		weather_effect
		light_size "0.200"
		fog_params
		{
			end "68.000"
			color
			{
				z "0.000"
				x "0.500"
				y "1.000"
				w "0.500"
			}

			start "40.000"
			density "1.000"
		}

	}

}

