GameplayResourceDef
{
	id					"carbon_vein"
	localization_id 	"resource_name/carbon_vein"
	bp  				"resources/resource_carbon"
	type 				"vein"
	ore					"carbonium"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/carbon_vein"
	bigger_icon			"gui/hud/resource_icons/carbon_vein_bigger"
	order   			"2"
	missing_effect 		"voice_over/announcement/carbonium_depleted"
	hud_visible 		"build_menu"

	terrain_material	"ground/resources/carbonium"
	spawn_type			"deposit"
	order   			"28"

	volume_minimap_color
	{
		r "0"
		g "0.6"
		b "2"
		a "1"
	}
}

GameplayResourceDef
{
	id				"carbonium"
	localization_id "resource_name/carbonium"
	bp  			"items/loot/resources/shard_carbonium_item"
	type 			"global"
	icon			"gui/hud/resource_icons/carbonium"
	bigger_icon		"gui/hud/resource_icons/carbonium_bigger"
	order   		"2"
	hud_visible 	"always"
}