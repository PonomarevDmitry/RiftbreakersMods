TimeOfDayPreset
{
	weather_night
	{
		weather_sound "ambient/rain"
		weather_haptic "sound/samples/haptic/ambient_hail.wav"

		weather_effect "effects/weather/blue_hail"
		weather_wind "effects/wind/strong"
		weather_type "1"
		time_of_day "2"
	}

	timeofday_sunset
	{
		skybox_specular_intensity "1.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.855"
				x "0.227"
				z "1.000"
			}

			start "20.000"
			end "68.000"
			density "0.398"
		}
		light_size "0.075"
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
		skybox_specular_intensity "1.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.855"
				x "0.227"
				z "1.000"
			}

			start "20.000"
			end "68.000"
			density "0.398"
		}
		light_size "0.07"
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
		weather_sound  "ambient/rain"
		weather_haptic "sound/samples/haptic/ambient_hail.wav"

		weather_effect "effects/weather/blue_hail"
		weather_wind "effects/wind/strong"
		weather_type "1"
		time_of_day "0"
	}

	timeofday_night
	{
		skybox_specular_intensity "1.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.855"
				x "0.227"
				z "1.000"
			}

			start "20.000"
			end "68.000"
			density "0.398"
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
		skybox_specular_intensity "1.000"
		fog_params
		{
			color
			{
				w "0.039"
				y "0.855"
				x "0.227"
				z "1.000"
			}

			start "20.000"
			end "68.000"
			density "0.398"
		}
		light_size "0.075"
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

