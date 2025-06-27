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
			w "1.000"
		}
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

			start "48.000"
			density "0.502"
		}

	}

	weather_day
	{
		weather_sound "ambient/rain"
		weather_haptic "sound/samples/haptic/ambient_rain.wav"

		time_of_day "0"
		weather_effect "effects/weather/rain_toxic"
		weather_biome_mod "effects/biome_mod/rain_toxic"
		weather_wind "effects/wind/rain"
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
			x "1.000"
			y "0.784"
			w "1.000"
		}
		light_size "0.07"
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

			start "48.000"
			density "0.497"
		}

	}

	weather_night
	{
		weather_sound "ambient/rain"
		weather_haptic "sound/samples/haptic/ambient_rain.wav"

		time_of_day "2"
		weather_effect "effects/weather/rain_toxic"
		weather_biome_mod "effects/biome_mod/rain_toxic"
		weather_wind "effects/wind/rain"
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
		light_size "0.2"
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

			start "48.000"
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
			x "0.982"
			y "0.361"
			w "1.000"
		}
		light_size "0.2"
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

			start "48.000"
			density "0.502"
		}

	}

}

