GameplayResourceDef
{
	id				"titanium_vein"
	localization_id "resource_name/titanium_vein"
	bp  			"resources/resource_titanium"
	type 			"vein"
	ore				"titanium"
	random_rotation "1"
	icon			"gui/hud/resource_icons/titanium_vein"
	bigger_icon		"gui/hud/resource_icons/titanium_vein_bigger"

	terrain_material	"ground/resources/titanium"
	spawn_type 		"deposit"
	order   		"33"
	volume_minimap_color
	{
		r "0.7"
		g "0"
		b "2"
		a "1"
	}
}

GameplayResourceDef
{
	id				"titanium"
	localization_id "resource_name/titanium"
	bp  			"items/loot/resources/shard_titanium_item"
	type 			"global"
	icon			"gui/hud/resource_icons/titanium"
	bigger_icon		"gui/hud/resource_icons/titanium_bigger"
	missing_effect	"voice_over/announcement/titanium_depleted"
	hud_visible 	"build_menu"
	order   		"8"	
}