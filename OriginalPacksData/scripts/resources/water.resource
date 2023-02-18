GameplayResourceDef
{
	id				"water"
	localization_id "resource_name/water"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/water_vein"
	bigger_icon		"gui/hud/resource_icons/water_vein_bigger"
	hud_visible 	"build_menu"
	order   		"20"
}

GameplayResourceDef
{
	id				"water_vein"
	localization_id "resource_name/water_pool"
	bp  			"resources/resource_water"
	type 			"vein"
	specific_type	"local"
	ore				"water"
	icon			"gui/hud/resource_icons/water_pool"
	bigger_icon		"gui/hud/resource_icons/water_pool_bigger"

	spawn_type 		"liquid_volume"
	order   		"34"
	
	volume_ambient_effect  	"effects/world/water_resource_ambient_sound"
	volume_repeat_effect	""
	volume_splash_effect	"effects/water_splash_small"
	volume_minimap_color
	{
		r "0.3"
		g "0.3"
		b "0.7"
		a "0.2"
	}
}