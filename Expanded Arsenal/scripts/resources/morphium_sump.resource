GameplayResourceDef
{
	id					"morphium_vent"
	localization_id 	"resource_name/morphium_vent"
	bp  				"resources/resource_morphium_sump"
	type 				"vein"
	ore					"morphium_sump"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/morphium_sump"
	bigger_icon			"gui/hud/resource_icons/morphium_sump_bigger"

	spawn_type			"single"
}

GameplayResourceDef
{
	id				"morphium_sump"
	localization_id "resource_name/morphium_sump"
	bp  			"items/loot/resources/shard_carbonium_item"
	
	icon			"gui/hud/resource_icons/morphium_sump"
	bigger_icon		"gui/hud/resource_icons/morphium_sump_bigger"
	hud_visible 	"build_menu"
}