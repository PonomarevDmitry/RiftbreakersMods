local supported_item_blueprints = {

     "buildings/megastructures/gravitational_hyper_lens_lvl_2",
     "buildings/megastructures/gravitational_hyper_lens_lvl_3",
     "buildings/megastructures/gravitational_hyper_lens_lvl_4",
     "buildings/megastructures/gravitational_hyper_lens_lvl_5",

     "buildings/megastructures/hydroponic_lab_lvl_2",
     "buildings/megastructures/hydroponic_lab_lvl_3",
     "buildings/megastructures/hydroponic_lab_lvl_4",
     "buildings/megastructures/hydroponic_lab_lvl_5",

     "buildings/megastructures/nanobot_center_lvl_2",
     "buildings/megastructures/nanobot_center_lvl_3",
     "buildings/megastructures/nanobot_center_lvl_4",
     "buildings/megastructures/nanobot_center_lvl_5",

     "buildings/megastructures/quantum_cortex_laboratory_lvl_2",
     "buildings/megastructures/quantum_cortex_laboratory_lvl_3",
     "buildings/megastructures/quantum_cortex_laboratory_lvl_4",
     "buildings/megastructures/quantum_cortex_laboratory_lvl_5",
}

for _,blueprint_name in ipairs(supported_item_blueprints) do

    local blueprint = ResourceManager:GetBlueprint( blueprint_name )

    local building_component = blueprint:GetComponent("BuildingDesc")

    if ( building_component ~= nil ) then

        local name = building_component:GetField("name"):GetValue()

        local newMenuIcon = "gui/hud/building_icons/" .. tostring(name)

        building_component:GetField("menu_icon"):SetValue(newMenuIcon)
    end
end



--local supported_item_blueprints = {
--}
--
--for _,blueprint_name in ipairs(supported_item_blueprints) do
--
--    local blueprint = ResourceManager:GetBlueprint( blueprint_name )
--
--    local building_component = blueprint:GetComponent("BuildingDesc")
--
--    if ( building_component ~= nil ) then
--    
--        building_component:GetField("limit"):SetValue("100")
--    end
--end