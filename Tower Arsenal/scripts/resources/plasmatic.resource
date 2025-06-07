GameplayResourceDef
{
	id				"plasmatic"
	localization_id "resource_name/plasmatic"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/plasmatic"
	bigger_icon		"gui/hud/resource_icons/plasmatic_bigger"
	hud_visible 	"build_menu"
	order   		"24"
}

GameplayResourceDef
{
	id				"plasmatic_vein"
	bp  			"resources/resource_plasmatic"
	localization_id "resource_name/plasmatic_pool"
	type 			"vein"
	specific_type	"local"
	ore				"plasmatic"
	icon			"gui/hud/resource_icons/plasmatic_pool"
	bigger_icon		"gui/hud/resource_icons/plasmatic_pool_bigger"

	spawn_type		"liquid_volume"
	order   		"37"

	volume_unpack_blueprint "resources/volume_resource_plasmatic"
	volume_repeat_effect	"effects/world/magma_resource_ambient"
	volume_ambient_effect  	"effects/world/magma_resource_ambient_sound"
	volume_splash_effect	"effects/magma_splash_small"	
	volume_minimap_color
	{
		r "0.5"
		g "0.0"
		b "0.5"
		a "0.2"
	}
}

