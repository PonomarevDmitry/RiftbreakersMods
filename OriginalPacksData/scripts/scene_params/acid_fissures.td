TimeOfDayPreset
{
	weather_night
	{
		weather_sound "ambient/rain"
		weather_effect "effects/weather/rain_toxic"
		weather_wind "effects/wind/rain"
		weather_type "1"
		time_of_day "2"
	}

	timeofday_sunset
	{
		skybox_specular_intensity "0.300"
		fog_params
		{
			color
			{
				w "0.500"
				y "1.000"
				x "0.500"
				z "0.000"
			}

			start "48.000"
			end "68.000"
			density "0.100"
		}
		light_size "0.05"
		light_color
		{
			w "1.000"
			y "0.361"
			x "0.982"
			z "0.102"
		}

		time_of_day "1"
		skybox_diffuse_intensity "0.180"
	}

	timeofday_day
	{
		skybox_specular_intensity "1.000"
		fog_params
		{
			color
			{
				w "0.500"
				y "1.000"
				x "0.500"
				z "0.000"
			}

			start "48.000"
			end "68.000"
			density "0.200"
		}
		light_size "0.0001"
		light_color
		{
			w "1.000"
			y "0.784"
			x "1.000"
			z "0.376"
		}

		time_of_day "0"
		skybox_diffuse_intensity "0.600"
	}

	weather_day
	{
		weather_sound "ambient/rain"
		weather_effect "effects/weather/rain_toxic"
		weather_wind "effects/wind/rain"
		weather_type "1"
		time_of_day "0"
	}

	timeofday_night
	{
		skybox_specular_intensity "0.100"
		fog_params
		{
			color
			{
				w "0.500"
				y "1.000"
				x "0.500"
				z "0.000"
			}

			start "48.000"
			end "68.000"
			density "0.054"
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
		skybox_diffuse_intensity "0.100"
	}

	timeofday_sunrise
	{
		skybox_specular_intensity "0.300"
		fog_params
		{
			color
			{
				w "0.500"
				y "1.000"
				x "0.500"
				z "0.000"
			}

			start "48.000"
			end "68.000"
			density "0.100"
		}
		light_size "0.05"
		light_color
		{
			w "1.000"
			y "0.753"
			x "1.000"
			z "0.250"
		}

		time_of_day "2"
		skybox_diffuse_intensity "0.180"
	}

}

