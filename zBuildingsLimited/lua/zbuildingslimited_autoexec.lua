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