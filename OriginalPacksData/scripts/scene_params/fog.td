TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.045"
			albedo
			{
				z "0.395"
				x "0.726"
				y "0.621"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.460"
				x "0.166"
				y "0.443"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "40.000"
			fog_density "0.025"
			fade_in_falloff "2.000"
		}

		skybox_specular_intensity "0.300"
		physics_gravity_factor "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.180"
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
		light_size "0.075"
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
			density "1.000"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/fog"
		weather_wind "effects/wind/weak"
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.045"
			albedo
			{
				z "1.000"
				x "0.420"
				y "0.855"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "1.000"
				x "0.420"
				y "0.855"
				w "1.000"
			}

			fog_height "40.000"
			fade_in_distance "40.000"
			fog_density "0.025"
			fade_in_falloff "2.000"
		}

		skybox_specular_intensity "0.588"
		physics_gravity_factor "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.403"
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
		light_size "0.070"
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
			density "1.000"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/fog"
		weather_wind "effects/wind/weak"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.045"
			albedo
			{
				z "1.000"
				x "1.000"
				y "1.000"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.350"
			emissive
			{
				z "0.048"
				x "0.048"
				y "0.048"
				w "1.000"
			}

			fog_height "40.000"
			fade_in_distance "50.000"
			fog_density "0.025"
			fade_in_falloff "2.000"
		}

		skybox_specular_intensity "0.100"
		physics_gravity_factor "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.100"
		clouds_opacity "0.000"
		bloom_params
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
			end "40.000"
			color
			{
				z "0.045"
				x "0.045"
				y "0.045"
				w "1.000"
			}

			start "0.000"
			density "1.000"
		}

	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.045"
			albedo
			{
				z "0.115"
				x "0.909"
				y "0.489"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "1.000"
				y "0.182"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "40.000"
			fog_density "0.025"
			fade_in_falloff "2.000"
		}

		skybox_specular_intensity "0.300"
		physics_gravity_factor "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.180"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "0.000"
		}

		weather_effect
		light_size "0.075"
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
			density "1.000"
		}

	}

}

