GameplayResourceDef
{
	id					"geothermal_vent"
	localization_id 	"resource_name/geothermal_vent"
	bp  				"resources/resource_geothermal"
	type 				"vein"
	ore					"geothermal"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/geothermal"
	bigger_icon			"gui/hud/resource_icons/geothermal_bigger"

	spawn_type			"single"
}

GameplayResourceDef
{
	id				"geothermal"
	localization_id "resource_name/geothermal_vent"
	bp  			"items/loot/resources/shard_carbonium_item"
	
	icon			"gui/hud/resource_icons/geothermal"
	bigger_icon		"gui/hud/resource_icons/geothermal_bigger"
	hud_visible 	"build_menu"
}