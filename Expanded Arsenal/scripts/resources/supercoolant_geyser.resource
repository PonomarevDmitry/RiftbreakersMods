GameplayResourceDef
{
	id					"supercoolant_vent"
	localization_id 	"resource_name/supercoolant_vent"
	bp  				"resources/resource_supercoolant_geyser"
	type 				"vein"
	ore					"supercoolant_geyser"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/supercoolant_geyser"
	bigger_icon			"gui/hud/resource_icons/supercoolant_geyser_bigger"

	spawn_type			"single"
}

GameplayResourceDef
{
	id				"supercoolant_geyser"
	localization_id "resource_name/supercoolant_geyser"
	bp  			"items/loot/resources/shard_carbonium_item"
	
	icon			"gui/hud/resource_icons/supercoolant_geyser"
	bigger_icon		"gui/hud/resource_icons/supercoolant_geyser_bigger"
	hud_visible 	"build_menu"
}