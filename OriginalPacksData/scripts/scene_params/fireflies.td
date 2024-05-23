TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.980"
				x "0.984"
				y "0.718"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.298"
				x "0.300"
				y "0.123"
				w "1.000"
			}

			fog_height "0.000"
			fade_in_distance "58.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.020"
		physics_gravity_factor "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.020"
		clouds_opacity "0.000"
		bloom_params
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
		weather_effect "effects/weather/fireflies"
		weather_wind "effects/wind/weak"
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.980"
				x "0.985"
				y "0.719"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.461"
				x "0.468"
				y "0.137"
				w "1.000"
			}

			fog_height "0.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}

		skybox_specular_intensity "0.400"
		physics_gravity_factor "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.070"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.376"
			x "1.000"
			y "0.784"
			w "12.000"
		}

		weather_effect
		light_size "0.000"
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
		weather_effect "effects/weather/fireflies"
		weather_wind "effects/wind/weak"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.980"
				x "0.984"
				y "0.718"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.207"
				x "0.209"
				y "0.036"
				w "1.000"
			}

			fog_height "0.100"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}

		skybox_specular_intensity "0.040"
		physics_gravity_factor "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.030"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.000"
			x "0.000"
			y "0.000"
			w "20.000"
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
		volumetric_fog_params
		{
			fog_height_falloff "0.085"
			albedo
			{
				z "0.000"
				x "1.000"
				y "0.243"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.463"
				x "0.467"
				y "0.137"
				w "1.000"
			}

			fog_height "0.100"
			fade_in_distance "58.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.100"
		physics_gravity_factor "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.050"
		clouds_opacity "0.000"
		bloom_params
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