local supported_item_blueprints = {
     "buildings/defense/portal",
}

for _,blueprint_name in ipairs(supported_item_blueprints) do

    local blueprint = ResourceManager:GetBlueprint( blueprint_name )

    local building_component = blueprint:GetComponent("BuildingDesc")

    if building_component ~= nil then

        building_component:GetField("building_functionality"):SetValue("10")
    end
end