GameplayResourceDef
{
	id				"cosmoganic_gas"
	localization_id "resource_name/cosmoganic_gas"
	bp  			""
	type 			"local"
	icon			"gui/hud/resource_icons/cosmoganic_gas"
	bigger_icon		"gui/hud/resource_icons/cosmoganic_gas_bigger"
	hud_visible 	"build_menu"
	order   		"23"
}

GameplayResourceDef
{
	id					"cosmic_vent"
	localization_id 	"resource_name/cosmic_vent"
	bp  				"resources/resource_cosmoganic_gas"
	type 				"vein"
	ore					"cosmoganic_gas"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/cosmoganic_gas"
	bigger_icon			"gui/hud/resource_icons/cosmoganic_gas_bigger"

	spawn_type			"single"
}

