GameplayResourceDef
{
	id				"mud"
	localization_id "resource_name/mud"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/mud_vein"
	bigger_icon		"gui/hud/resource_icons/mud_vein_bigger"
	hud_visible 	"build_menu"
	order   		"21"
}

GameplayResourceDef
{
	id				"mud_vein"
	bp  			"resources/resource_mud"
	localization_id "resource_name/mud_pool"
	type 			"vein"
	specific_type	"local"
	ore				"mud"
	icon			"gui/hud/resource_icons/mud_pool"
	bigger_icon		"gui/hud/resource_icons/mud_pool_bigger"

	spawn_type		"liquid_volume"
	order   		"35"
	
	volume_unpack_blueprint "resources/volume_resource_mud"
	volume_ambient_effect  	"effects/world/mud_resource_ambient_sound"
	volume_repeat_effect	""
	volume_splash_effect	"effects/mud_splash_small"	
	
	volume_minimap_color
	{
		r "0.7"
		g "0.4"
		b "0.0"
		a "0.2"
	}
}