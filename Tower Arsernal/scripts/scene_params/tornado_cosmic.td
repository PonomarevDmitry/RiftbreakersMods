TimeOfDayPreset
{
	timeofday_sunrise
	{
		skybox_specular_intensity "0.300"
		time_of_day "2"
		skybox_diffuse_intensity "0.180"
		light_color
		{
			z "0.283"
			x "1.000"
			y "0.768"
			w "3.000"
		}

		weather_effect
		light_size "0.060"
		fog_params
		{
			end "54.000"
			color
			{
				z "0.012"
				x "0.462"
				y "0.133"
				w "1.000"
			}

			start "30.000"
			density "0.796"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/cosmicstorm"
		weather_wind "effects/wind/strong"
		weather_type "0"
	}

	timeofday_day
	{
		skybox_specular_intensity "0.314"
		time_of_day "0"
		skybox_diffuse_intensity "0.253"
		light_color
		{
			z "0.147"
			x "0.584"
			y "0.352"
			w "3.000"
		}

		weather_effect
		light_size "0.030"
		fog_params
		{
			end "54.000"
			color
			{
				z "0.000"
				x "0.768"
				y "0.122"
				w "1.000"
			}

			start "30.000"
			density "0.802"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/cosmicstorm"
		weather_wind "effects/wind/strong"
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
			end "60.000"
			color
			{
				z "0.003"
				x "0.381"
				y "0.089"
				w "1.000"
			}

			start "30.000"
			density "0.803"
		}

	}

	timeofday_sunset
	{
		skybox_specular_intensity "0.253"
		time_of_day "1"
		skybox_diffuse_intensity "0.213"
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "3.000"
		}

		weather_effect
		light_size "0.060"
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

			start "30.000"
			density "0.802"
		}

	}

}

