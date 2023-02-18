GameplayResourceDef
{
	id					"cobalt_vein"
	localization_id 	"resource_name/cobalt_vein"
	bp  				"resources/resource_cobalt"
	type 				"vein"
	ore					"cobalt"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/cobalt"
	bigger_icon			"gui/hud/resource_icons/cobalt_bigger"

	terrain_material 	"ground/resources/cobalt"
	spawn_type			"deposit"
	order   			"30"

	volume_minimap_color
	{
		r "0"
		g "0"
		b "0.7"
		a "1"
	}
}

GameplayResourceDef
{
	id						"cobalt"
	localization_id 		"resource_name/cobalt"
	bp  					"items/loot/resources/shard_cobalt_item"
	type 					"global"
	icon					"gui/hud/resource_icons/cobalt"
	bigger_icon				"gui/hud/resource_icons/cobalt_bigger"
	hud_visible 			"build_menu"
	order   				"4"
	missing_effect 			"voice_over/announcement/cobalt_depleted"
	
	//missing_effect "voice_over/announcement/not_enough_cobalt"	
}
