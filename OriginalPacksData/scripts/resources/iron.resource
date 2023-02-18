GameplayResourceDef
{
	id				"iron_vein"
	localization_id "resource_name/iron_vein"
	bp  			"resources/resource_iron"
	type 			"vein"
	ore				"steel"
	random_rotation "1"
	icon			"gui/hud/resource_icons/iron_vein"
	bigger_icon		"gui/hud/resource_icons/iron_vein_bigger"
	order   		"3"
	
	missing_effect 	"voice_over/announcement/steel_depleted"
	hud_visible 	"build_menu"

	terrain_material	"ground/resources/ironium"
	spawn_type			"deposit"
	order   		"29"

	volume_minimap_color
	{
		r "2"
		g "0.5"
		b "0"
		a "1"
	}
}

GameplayResourceDef
{
	id				"steel"
	localization_id "resource_name/steel"
	bp  			"items/loot/resources/shard_steel_item"
	type 			"global"
	icon			"gui/hud/resource_icons/ironium"
	bigger_icon		"gui/hud/resource_icons/ironium_bigger"
	order   		"3"
}