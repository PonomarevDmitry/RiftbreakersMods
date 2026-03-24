GameplayResourceDef
{
	id					"cosmonite_ore_vein"
	localization_id 	"resource_name/cosmonite_vein"
	bp  				"resources/resource_cosmonite_ore"
	type 				"vein"
	ore					"cosmonite_ore"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/cosmonite_vein"
	bigger_icon			"gui/hud/resource_icons/cosmonite_vein_bigger"

	terrain_material	"ground/resources/cosmonite"
	spawn_type 			"deposit"
	order   			"35"

	volume_unpack_blueprint "resources/volume_resource_cosmonite_ore"
}

GameplayResourceDef
{
	id					"cosmonite_ore"
	localization_id 	"resource_name/cosmonite"
	bp  				"items/loot/resources/shard_cosmonite_ore_item"
	type 				"global"
	icon				"gui/hud/resource_icons/cosmonite_ore"
	bigger_icon			"gui/hud/resource_icons/cosmonite_ore_bigger"
	hud_visible 		"build_menu"
	order   			"7"
}

GameplayResourceDef
{
	id					"cosmonite"
	localization_id 	"resource_name/cosmonite_ore"
	bp  				"items/loot/resources/shard_cosmonite_item"
	type 				"loot"
	icon				"gui/hud/resource_icons/cosmonite_vein"
	bigger_icon			"gui/hud/resource_icons/cosmonite_vein_bigger"
	missing_effect		"voice_over/announcement/Cosmonite_depleted"
	hud_visible 		"build_menu"
	order   			"6"
}
