GameplayResourceDef
{
	id					"acid_vent"
	localization_id 	"resource_name/acid_vent"
	bp  				"resources/resource_acid_rift"
	type 				"vein"
	ore					"acid_rift"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/acid_rift"
	bigger_icon			"gui/hud/resource_icons/acid_rift_bigger"

	spawn_type			"single"
}

GameplayResourceDef
{
	id				"acid_rift"
	localization_id "resource_name/acid_rift"
	bp  			"items/loot/resources/shard_carbonium_item"
	
	icon			"gui/hud/resource_icons/acid_rift"
	bigger_icon		"gui/hud/resource_icons/acid_rift_bigger"
	hud_visible 	"build_menu"
}