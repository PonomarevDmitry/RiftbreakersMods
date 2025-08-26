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
		light_size "0.06"
		weather_effect
		fog_params
		{
			end "50.000"
			color
			{
				z "0.546"
				x "1.000"
				y "0.855"
				w "1.000"
			}

			start "0.000"
			density "0.499"
		}

	}

	weather_day
	{
		weather_sound "ambient/wind_strong"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"
		time_of_day "0"
		weather_effect "effects/weather/dust_storm"
		weather_biome_mod "effects/biome_mod/dust_storm"
		weather_wind "effects/wind/strong"
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
		light_size "0.03"
		weather_effect
		fog_params
		{
			end "35.000"
			color
			{
				z "0.578"
				x "0.578"
				y "0.578"
				w "1.000"
			}

			start "0.000"
			density "0.502"
		}

	}

	weather_night
	{
		weather_sound "ambient/wind_strong"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"
		time_of_day "2"
		weather_effect "effects/weather/dust_storm"
		weather_biome_mod "effects/biome_mod/dust_storm"
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
		light_size "0.2"
		weather_effect
		fog_params
		{
			end "40.000"
			color
			{
				z "0.045"
				x "0.045"
				y "0.045"
				w "1.000"
			}

			start "0.000"
			density "0.499"
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
			w "0.000"
		}
		light_size "0.06"
		weather_effect
		fog_params
		{
			end "55.000"
			color
			{
				z "0.031"
				x "0.982"
				y "0.262"
				w "1.000"
			}

			start "0.000"
			density "0.495"
		}

	}

}

