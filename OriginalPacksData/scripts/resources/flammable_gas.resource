GameplayResourceDef
{
	id				"flammable_gas"
	localization_id "resource_name/flammable_gas"
	bp  			""
	type 			"local"
	icon			"gui/hud/resource_icons/flammable_gas"
	bigger_icon		"gui/hud/resource_icons/flammable_gas_bigger"
	hud_visible 	"build_menu"
	order   		"23"
}

GameplayResourceDef
{
	id					"flammable_gas_vent"
	localization_id 	"resource_name/flammable_gas_vent"
	bp  				"resources/resource_flammable_gas"
	type 				"vein"
	ore					"flammable_gas"
	random_rotation 	"1"
	icon				"gui/hud/resource_icons/flammable_gas"
	bigger_icon			"gui/hud/resource_icons/flammable_gas_bigger"

	spawn_type			"single"
}