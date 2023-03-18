GameplayResourceDef
{
	id				"voidinite_ore_vein"
	localization_id "resource_name/voidinite_vein"
	bp  			"resources/resource_voidinite_ore"
	type 			"vein"
	ore				"voidinite_ore"
	random_rotation "1"
	icon			"gui/hud/resource_icons/voidinite_vein"
	bigger_icon		"gui/hud/resource_icons/voidinite_vein_bigger"

	terrain_material	"ground/resources/voidinite"
	spawn_type 		"deposit"
	order   		"35"
	
	volume_minimap_color
	{
		r "1.5"
		g "0"
		b "7"
		a "1"
	}
}

GameplayResourceDef
{
	id				"voidinite_ore"
	localization_id "resource_name/voidinite_ore"
	bp  			"items/loot/resources/shard_voidinite_ore_item"
	type 			"global"	
	icon			"gui/hud/resource_icons/voidinite_ore"
	bigger_icon		"gui/hud/resource_icons/voidinite_ore_bigger"
	hud_visible 	"build_menu"
	order   		"36"
}