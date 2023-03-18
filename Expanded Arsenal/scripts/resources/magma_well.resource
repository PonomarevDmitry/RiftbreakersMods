GameplayResourceDef
{
	id					"magma_vent"
	localization_id 	"resource_name/magma_vent"
	bp  				"resources/resource_magma_well"
	type 				"vein"
	ore					"magma_well"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/magma_well"
	bigger_icon			"gui/hud/resource_icons/magma_well_bigger"

	spawn_type			"single"
}

GameplayResourceDef
{
	id				"magma_well"
	localization_id "resource_name/magma_well"
	bp  			"items/loot/resources/shard_carbonium_item"
	
	icon			"gui/hud/resource_icons/magma_well"
	bigger_icon		"gui/hud/resource_icons/magma_well_bigger"
	hud_visible 	"build_menu"
}