TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.008"
				x "0.169"
				y "0.420"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.008"
				x "0.169"
				y "0.420"
				w "1.000"
			}

			fog_height "15.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.200"
		physics_gravity_factor "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.180"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.162"
			x "0.791"
			y "0.776"
			w "20.000"
		}

		weather_effect
		light_size "0.050"
		fog_params
		{
			end "62.000"
			color
			{
				z "0.009"
				x "0.168"
				y "0.418"
				w "1.000"
			}

			start "45.000"
			density "0.602"
		}

	}

	weather_day
	{
		weather_sound "ambient/rain"
		weather_haptic "sound/samples/haptic/ambient_rain.wav"

		time_of_day "0"
		weather_effect "effects/weather/rain_toxic"
		weather_wind "effects/wind/tornado"
		weather_type "1"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.008"
				x "0.004"
				y "0.357"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.009"
				x "0.000"
				y "0.825"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}

		skybox_specular_intensity "1.000"
		physics_gravity_factor "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.500"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.171"
			x "0.708"
			y "0.708"
			w "12.000"
		}

		weather_effect
		light_size "0.000"
		fog_params
		{
			end "56.000"
			color
			{
				z "0.009"
				x "0.004"
				y "0.356"
				w "1.000"
			}

			start "43.000"
			density "0.799"
		}

	}

	weather_night
	{
		weather_sound "ambient/rain"
		weather_haptic "sound/samples/haptic/ambient_rain.wav"

		time_of_day "2"
		weather_effect "effects/weather/rain_toxic"
		weather_wind "effects/wind/tornado"
		weather_type "1"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.076"
				x "0.141"
				y "0.688"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "0.000"
				y "0.000"
				w "1.000"
			}

			fog_height "35.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.100"
		physics_gravity_factor "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.100"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.209"
			x "0.296"
			y "0.956"
			w "1.000"
		}

		weather_effect
		light_size "0.200"
		fog_params
		{
			end "48.000"
			color
			{
				z "0.002"
				x "0.004"
				y "0.012"
				w "1.000"
			}

			start "25.000"
			density "0.803"
		}

	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.030"
				x "0.057"
				y "0.285"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.059"
				x "0.432"
				y "0.536"
				w "1.000"
			}

			fog_height "15.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.200"
		physics_gravity_factor "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.180"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.445"
			w "20.000"
		}

		weather_effect
		light_size "0.050"
		fog_params
		{
			end "53.000"
			color
			{
				z "0.014"
				x "0.114"
				y "0.141"
				w "1.000"
			}

			start "42.000"
			density "0.748"
		}

	}

}

