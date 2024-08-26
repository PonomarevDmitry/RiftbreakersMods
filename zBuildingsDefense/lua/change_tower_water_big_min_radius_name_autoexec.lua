local supported_item_blueprints = {

     "buildings/defense/tower_water_big",
     "buildings/defense/tower_water_big_lvl_2",
     "buildings/defense/tower_water_big_lvl_3",
}

for _,blueprint_name in ipairs(supported_item_blueprints) do

    local blueprint = ResourceManager:GetBlueprint( blueprint_name )

    local building_component = blueprint:GetComponent("BuildingDesc")

    if building_component ~= nil then

        building_component:GetField("radius_name"):SetValue("water_tower_big")
    end
end