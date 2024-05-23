GameplayResourceDef
{
	id				"sludge"
	localization_id "resource_name/sludge"
	bp  			""
	type 			"local"
	specific_type	"vein"
	icon			"gui/hud/resource_icons/sludge_vein"
	bigger_icon		"gui/hud/resource_icons/sludge_vein_bigger"
	hud_visible 	"build_menu"
	order   		"22"
}

GameplayResourceDef
{
	id					"sludge_vein"
	bp  				"resources/resource_sludge"
	localization_id 	"resource_name/sludge_pool"
	type 				"vein"
	specific_type		"local"
	ore					"sludge"
	icon				"gui/hud/resource_icons/sludge_pool"
	bigger_icon			"gui/hud/resource_icons/sludge_pool_bigger"

	spawn_type			"liquid_volume"
	order   			"36"
	
	volume_unpack_blueprint "resources/volume_resource_sludge"
	volume_ambient_effect  	"effects/world/sludge_resource_ambient_sound"
	volume_repeat_effect	"effects/world/resource_sludge"
	volume_splash_effect	"effects/sludge_splash_small"
	volume_minimap_color
	{
		r "0.1"
		g "1.0"
		b "0.1"
		a "0.2"
	}
}