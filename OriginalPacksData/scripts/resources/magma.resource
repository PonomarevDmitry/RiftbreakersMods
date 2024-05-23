GameplayResourceDef
{
	id				"magma"
	localization_id "resource_name/magma"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/magma"
	bigger_icon		"gui/hud/resource_icons/magma_bigger"
	hud_visible 	"build_menu"
	order   		"24"
}

GameplayResourceDef
{
	id				"magma_vein"
	bp  			"resources/resource_magma"
	localization_id "resource_name/magma_pool"
	type 			"vein"
	specific_type	"local"
	ore				"magma"
	icon			"gui/hud/resource_icons/magma_pool"
	bigger_icon		"gui/hud/resource_icons/magma_pool_bigger"

	spawn_type		"liquid_volume"
	order   		"37"

	volume_unpack_blueprint "resources/volume_resource_magma"
	volume_repeat_effect	"effects/world/magma_resource_ambient"
	volume_ambient_effect  	"effects/world/magma_resource_ambient_sound"
	volume_splash_effect	"effects/magma_splash_small"	
	volume_minimap_color
	{
		r "1"
		g "0.5"
		b "0.0"
		a "0.2"
	}
}