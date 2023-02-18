TimeOfDayPreset
{
	timeofday_sunrise
	{
		skybox_specular_intensity "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.000"
		light_color
		{
			z "0.250"
			x "1.000"
			y "0.753"
			w "50.000"
		}

		weather_effect
		light_size "0.030"
		fog_params
		{
			end "56.000"
			color
			{
				z "0.076"
				x "0.332"
				y "0.235"
				w "1.000"
			}

			start "42.000"
			density "0.297"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_effect "effects/weather/solar_burn"
		weather_wind "effects/wind/none"
		weather_type "0"
	}

	timeofday_day
	{
		skybox_specular_intensity "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.000"
		light_color
		{
			z "0.223"
			x "0.888"
			y "0.644"
			w "50.000"
		}

		weather_effect
		light_size "0.000"
		fog_params
		{
			end "56.000"
			color
			{
				z "0.025"
				x "0.871"
				y "0.292"
				w "1.000"
			}

			start "42.000"
			density "0.381"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_effect "effects/weather/solar_burn"
		weather_wind "effects/wind/none"
		weather_type "0"
	}

	timeofday_night
	{
		skybox_specular_intensity "0.440"
		time_of_day "3"
		skybox_diffuse_intensity "0.201"
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
				w "1.000"
			}

			start "52.000"
			density "0.000"
		}

	}

	timeofday_sunset
	{
		skybox_specular_intensity "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.000"
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "50.000"
		}

		weather_effect
		light_size "0.030"
		fog_params
		{
			end "56.000"
			color
			{
				z "0.031"
				x "0.982"
				y "0.262"
				w "1.000"
			}

			start "42.000"
			density "0.298"
		}

	}

}

