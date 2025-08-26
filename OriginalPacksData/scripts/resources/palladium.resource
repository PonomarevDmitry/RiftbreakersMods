GameplayResourceDef
{
	id						"palladium_vein"
	localization_id 		"resource_name/palladium_vein"
	bp  					"resources/resource_palladium"
	type 					"vein"
	ore						"palladium"
	random_rotation 		"1"
	icon					"gui/hud/resource_icons/palladium"
	bigger_icon				"gui/hud/resource_icons/palladium_bigger"

	terrain_material		"ground/resources/palladium"
	spawn_type				"deposit"
	order   				"31"

	volume_unpack_blueprint "resources/volume_resource_palladium"
}

GameplayResourceDef
{
	id				"palladium"
	localization_id "resource_name/palladium"
	bp  			"items/loot/resources/shard_palladium_item"
	type 			"global"
	icon			"gui/hud/resource_icons/palladium"
	bigger_icon		"gui/hud/resource_icons/palladium_bigger"
	missing_effect	"voice_over/announcement/palladium_depleted"
	hud_visible 	"build_menu"
	order   		"5"	
}