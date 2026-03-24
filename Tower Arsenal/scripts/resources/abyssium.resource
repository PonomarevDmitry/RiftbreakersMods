GameplayResourceDef
{
	id				"abyssium"
	localization_id "resource_name/abyssium"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/abyssium_vein"
	bigger_icon		"gui/hud/resource_icons/abyssium_vein_bigger"
	hud_visible 	"build_menu"
	order   		"21"
}

GameplayResourceDef
{
	id				"abyssium_vein"
	bp  			"resources/resource_abyssium"
	localization_id "resource_name/abyssium_pool"
	type 			"vein"
	specific_type	"local"
	ore				"abyssium"
	icon			"gui/hud/resource_icons/abyssium_pool"
	bigger_icon		"gui/hud/resource_icons/abyssium_pool_bigger"

	spawn_type		"liquid_volume"
	order   		"35"

	volume_unpack_blueprint "resources/volume_resource_abyssium"
	volume_repeat_effect	""
	volume_ambient_effect  	"effects/world/morphium_resource_ambient_sound"
	volume_splash_effect	"effects/the_abyss_splash_small"	

	volume_minimap_color
	{
		r "0.4"
		g "0.0"
		b "0.7"
		a "1.0"
	}
}