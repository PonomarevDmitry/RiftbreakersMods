TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{			
			fog_height_falloff "0.000"
			fog_height "0.000"
			fog_density "0.076"
			albedo
			{
				z "0.302"
				x "0.506"
				y "0.395"
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

			fade_in_distance "60.000"
			fade_in_falloff "4"
		}		
		skybox_specular_intensity "0.000"
		physics_gravity_factor "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.000"
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
		light_size "0.030"
		fog_params
		{
			end "55.000"
			color
			{
				z "0.006"
				x "0.049"
				y "0.021"
				w "1.000"
			}

			start "30.000"
			density "0.750"
		}

	}

	weather_day
	{
		weather_sound "ambient/wind_medium"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"		
		time_of_day "0"
		weather_effect "effects/weather/wind_strong"
		weather_wind "effects/wind/wind_spot"
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{			
			fog_height_falloff "0.000"
			fog_height "0.000"
			fog_density "0.076"
			albedo
			{
				z "0.224"
				x "0.361"
				y "0.321"
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

			fade_in_distance "60.000"
			fade_in_falloff "4"
		}		
		skybox_specular_intensity "0.100"
		physics_gravity_factor "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.000"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.376"
			x "1.000"
			y "0.784"
			w "30.000"
		}

		weather_effect
		light_size "0.188"
		fog_params
		{
			end "55.000"
			color
			{
				z "0.006"
				x "0.049"
				y "0.021"
				w "1.000"
			}

			start "30.000"
			density "0.750"
		}

	}

	weather_night
	{
		weather_sound "ambient/wind_medium"
		weather_haptic "sound/samples/haptic/ambient_strong_wind.wav"		
		time_of_day "2"
		weather_effect "effects/weather/wind_strong"
		weather_wind "effects/wind/wind_spot"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.000"
			fog_height "0.000"
			fog_density "0.076"
			albedo
			{
				z "0.302"
				x "0.506"
				y "0.455"
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

			fade_in_distance "60.000"
			fade_in_falloff "4"
		}		
		skybox_specular_intensity "0.000"
		physics_gravity_factor "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.000"
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
			end "55.000"
			color
			{
				z "0.006"
				x "0.049"
				y "0.021"
				w "1.000"
			}

			start "30.000"
			density "0.750"
		}

	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height "0.000"
			fog_height_falloff "0.000"
			fog_density "0.076"
			albedo
			{
				z "0.302"
				x "0.506"
				y "0.502"
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

			fade_in_distance "60.000"
			fade_in_falloff "4"
		}		
		skybox_specular_intensity "0.000"
		physics_gravity_factor "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.000"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "3.000"
		}

		weather_effect
		light_size "0.050"
		fog_params
		{
			end "55.000"
			color
			{
				z "0.006"
				x "0.049"
				y "0.021"
				w "1.000"
			}

			start "30.000"
			density "0.750"
		}

	}

}

