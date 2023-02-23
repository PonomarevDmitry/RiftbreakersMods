GameplayResourceDef
{
	id				"rhodonite"
	localization_id "resource_name/rhodonite"
	bp  			"items/loot/resources/shard_rhodonite_item"
	type 			"loot"
	icon			"gui/hud/resource_icons/rhodonite"
	bigger_icon		"gui/hud/resource_icons/rhodonite_bigger"
	hud_visible 	"build_menu"
	order			"39"
	allow_overflow 	"1"
	specific_type	"rare"				 
	
	//missing_effect "voice_over/announcement/not_enough_rhodonite"	
}

GameplayResourceDef
{
	id				"rhodonite_crystal"
	localization_id "resource_name/rhodonite_crystal"
	bp  			""
	type 			"vein"
	icon			"gui/hud/resource_icons/rhodonite"
	bigger_icon		"gui/hud/resource_icons/rhodonite_bigger"
	ore				"rhodonite"
	
	//missing_effect "voice_over/announcement/not_enough_rhodonite"		
}