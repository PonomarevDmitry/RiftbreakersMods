GameplayResourceDef
{
	id				"morphium"
	localization_id "resource_name/morphium"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/morphium_vein"
	bigger_icon		"gui/hud/resource_icons/morphium_vein_bigger"
	hud_visible 	"build_menu"
	order   		"21"
}

GameplayResourceDef
{
	id				"morphium_vein"
	bp  			"resources/resource_morphium"
	localization_id "resource_name/morphium_pool"
	type 			"vein"
	specific_type	"local"
	ore				"morphium"
	icon			"gui/hud/resource_icons/morphium_pool"
	bigger_icon		"gui/hud/resource_icons/morphium_pool_bigger"

	spawn_type		"liquid_volume"
	//terrain_material 			"resources/resource_morphium_vein"
	//terrain_overflow_material 	"resources/resource_morphium_vein_blend"

	order   		"35"
	
	volume_ambient_effect  	"effects/world/morphium_resource_ambient_sound"
	volume_repeat_effect	""
	volume_splash_effect	"effects/morphium_splash_small"

	volume_minimap_color
	{
		r "0.6"
		g "0.6"
		b "0.6"
		a "0.6"
	}
}