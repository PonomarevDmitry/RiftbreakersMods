local supported_item_blueprints = {
     "buildings/defense/trap_acid",
     "buildings/defense/trap_area",
     "buildings/defense/trap_cryo",
     "buildings/defense/trap_energy",
     "buildings/defense/trap_fire",
     "buildings/defense/trap_physical",
}

for _,blueprint_name in ipairs(supported_item_blueprints) do

    local blueprint = ResourceManager:GetBlueprint( blueprint_name )

    local building_component = blueprint:GetComponent("BuildingDesc")

    if building_component ~= nil then

        building_component:GetField("limit"):SetValue("1425")
    end
end



local supported_item_blueprints = {
     "buildings/main/armory",
     "buildings/main/armory_lvl_2",
     "buildings/main/armory_lvl_3",
     "buildings/main/armory_lvl_4",
     "buildings/main/armory_lvl_5",

     "buildings/main/communications_hub",
     "buildings/main/communications_hub_lvl_2",
     "buildings/main/communications_hub_lvl_3",
     "buildings/main/communications_hub_lvl_4",
     "buildings/main/communications_hub_lvl_5",

     "buildings/main/laboratory",
     "buildings/main/laboratory_lvl_2",
     "buildings/main/laboratory_lvl_3",
     "buildings/main/laboratory_lvl_4",
     "buildings/main/laboratory_lvl_5",

     "buildings/main/outpost",

     "buildings/resources/ammunition_storage",
     "buildings/resources/ammunition_storage_lvl_2",
     "buildings/resources/ammunition_storage_lvl_3",
}

for _,blueprint_name in ipairs(supported_item_blueprints) do

    local blueprint = ResourceManager:GetBlueprint( blueprint_name )

    local building_component = blueprint:GetComponent("BuildingDesc")

    if building_component ~= nil then
    
        building_component:GetField("map_limit"):SetValue("0")
        building_component:GetField("limit"):SetValue("0")
        building_component:GetField("limit_name"):SetValue("")
    end
end