GameplayResourceDef
{
	id				"supercoolant"
	localization_id "resource_name/supercoolant"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/super_coolant"
	bigger_icon		"gui/hud/resource_icons/super_coolant_bigger"
	hud_visible 	"build_menu"
	order   		"25"
}

GameplayResourceDef
{
	id				"supercoolant_vein"
	localization_id "resource_name/supercoolant_pool"
	bp  			"resources/resource_supercoolant"
	type 			"vein"
	specific_type	"local"
	ore				"supercoolant"
	icon			"gui/hud/resource_icons/super_coolant_pool"
	bigger_icon		"gui/hud/resource_icons/super_coolant_pool_bigger"

	spawn_type 		"liquid_volume"
	order   		"34"
	
	volume_ambient_effect  	"effects/world/morphium_resource_ambient_sound"
	volume_repeat_effect	""
	volume_splash_effect	"effects/morphium_splash_small"
	volume_minimap_color
	{
		r "0.3"
		g "0.3"
		b "0.7"
		a "0.2"
	}
}