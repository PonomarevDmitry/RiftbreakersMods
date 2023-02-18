TimeOfDayPreset
{
	timeofday_sunrise
	{
		skybox_specular_intensity "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.250"
			x "1.000"
			y "0.753"
			w "2.036"
		}

		weather_effect
		light_size "0.075"
		fog_params
		{
			end "68.000"
			color
			{
				z "1.000"
				x "0.227"
				y "0.855"
				w "0.039"
			}

			start "20.000"
			density "1.000"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/ice_fog"
		weather_wind "effects/wind/none"
		weather_type "1"
	}

	timeofday_day
	{
		skybox_specular_intensity "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.595"
		light_color
		{
			z "0.376"
			x "1.000"
			y "0.784"
			w "1.964"
		}

		weather_effect
		light_size "0.070"
		fog_params
		{
			end "68.000"
			color
			{
				z "1.000"
				x "0.227"
				y "0.855"
				w "0.039"
			}

			start "20.000"
			density "1.000"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/ice_fog"
		weather_wind "effects/wind/none"
		weather_type "1"
	}

	timeofday_night
	{
		skybox_specular_intensity "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.096"
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
				z "1.000"
				x "0.227"
				y "0.855"
				w "0.039"
			}

			start "20.000"
			density "1.000"
		}

	}

	timeofday_sunset
	{
		skybox_specular_intensity "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.000"
			x "0.982"
			y "0.361"
			w "1.891"
		}

		weather_effect
		light_size "0.075"
		fog_params
		{
			end "68.000"
			color
			{
				z "1.000"
				x "0.227"
				y "0.855"
				w "0.039"
			}

			start "20.000"
			density "1.000"
		}

	}

}

