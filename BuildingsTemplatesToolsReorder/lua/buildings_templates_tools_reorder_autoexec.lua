require("lua/utils/reflection.lua")

local InjectChangeBuildingsTemplatesToolsBuildingDescValues = function(blueprintName, order)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeBuildingsTemplatesToolsBuildingDescValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local buildingDesc = blueprint:GetComponent("BuildingDesc")
    if ( buildingDesc == nil ) then
        LogService:Log("InjectChangeBuildingsTemplatesToolsBuildingDescValues Blueprint '" .. blueprintName .. "' BuildingDesc NOT EXISTS.")
        return
    end

    local orderField = buildingDesc:GetField("order")
    if ( orderField == nil ) then
        LogService:Log("InjectChangeBuildingsTemplatesToolsBuildingDescValues Blueprint '" .. blueprintName .. "' buildingDesc:GetField('order') NOT EXISTS.")
        return
    end

    orderField:SetValue(order)
end

local InjectChangeListBuildingsTemplatesToolsBuildingDescValues = function(blueprintValues)

    for _, configObject in ipairs(blueprintValues) do

        local list = configObject.list
        local order = configObject.order

        for _, blueprintName in ipairs(list) do

            InjectChangeBuildingsTemplatesToolsBuildingDescValues(blueprintName, order)
        end
    end
end

local new_values = {

    {
        ["list"] = {
            "buildings/tools/buildings_picker_01",
            "buildings/tools/buildings_picker_02",
            "buildings/tools/buildings_picker_03",
            "buildings/tools/buildings_picker_04",
            "buildings/tools/buildings_picker_05",

            "buildings/tools/buildings_picker_06",
            "buildings/tools/buildings_picker_07",
            "buildings/tools/buildings_picker_08",
            "buildings/tools/buildings_picker_09",
            "buildings/tools/buildings_picker_10",
            
            "buildings/tools/buildings_picker_11",
            "buildings/tools/buildings_picker_12",
            "buildings/tools/buildings_picker_13",
            "buildings/tools/buildings_picker_14",
            "buildings/tools/buildings_picker_15",

            "buildings/tools/buildings_picker_16",
            "buildings/tools/buildings_picker_17",
            "buildings/tools/buildings_picker_18",
            "buildings/tools/buildings_picker_19",
            "buildings/tools/buildings_picker_20",
            
            "buildings/tools/buildings_picker_21",
            "buildings/tools/buildings_picker_22",
            "buildings/tools/buildings_picker_23",
            "buildings/tools/buildings_picker_24",
        },

        ["order"] = "4",
    },

    {
        ["list"] = {
            "buildings/tools/buildings_builder_01",
            "buildings/tools/buildings_builder_02",
            "buildings/tools/buildings_builder_03",
            "buildings/tools/buildings_builder_04",
            "buildings/tools/buildings_builder_05",

            "buildings/tools/buildings_builder_06",
            "buildings/tools/buildings_builder_07",
            "buildings/tools/buildings_builder_08",
            "buildings/tools/buildings_builder_09",
            "buildings/tools/buildings_builder_10",
            
            "buildings/tools/buildings_builder_11",
            "buildings/tools/buildings_builder_12",
            "buildings/tools/buildings_builder_13",
            "buildings/tools/buildings_builder_14",
            "buildings/tools/buildings_builder_15",

            "buildings/tools/buildings_builder_16",
            "buildings/tools/buildings_builder_17",
            "buildings/tools/buildings_builder_18",
            "buildings/tools/buildings_builder_19",
            "buildings/tools/buildings_builder_20",
            
            "buildings/tools/buildings_builder_21",
            "buildings/tools/buildings_builder_22",
            "buildings/tools/buildings_builder_23",
            "buildings/tools/buildings_builder_24",
        },

        ["order"] = "4.1",
    },

    {
        ["list"] = {
            "buildings/tools/buildings_builder_mass_01",
            "buildings/tools/buildings_builder_mass_02",
            "buildings/tools/buildings_builder_mass_03",
            "buildings/tools/buildings_builder_mass_04",
            "buildings/tools/buildings_builder_mass_05",

            "buildings/tools/buildings_builder_mass_06",
            "buildings/tools/buildings_builder_mass_07",
            "buildings/tools/buildings_builder_mass_08",
            "buildings/tools/buildings_builder_mass_09",
            "buildings/tools/buildings_builder_mass_10",
            
            "buildings/tools/buildings_builder_mass_11",
            "buildings/tools/buildings_builder_mass_12",
            "buildings/tools/buildings_builder_mass_13",
            "buildings/tools/buildings_builder_mass_14",
            "buildings/tools/buildings_builder_mass_15",

            "buildings/tools/buildings_builder_mass_16",
            "buildings/tools/buildings_builder_mass_17",
            "buildings/tools/buildings_builder_mass_18",
            "buildings/tools/buildings_builder_mass_19",
            "buildings/tools/buildings_builder_mass_20",
            
            "buildings/tools/buildings_builder_mass_21",
            "buildings/tools/buildings_builder_mass_22",
            "buildings/tools/buildings_builder_mass_23",
            "buildings/tools/buildings_builder_mass_24",
        },

        ["order"] = "4.2",
    },

    {
        ["list"] = {
            "buildings/tools/buildings_upgrader",
            "buildings/tools/buildings_swap_templates",
        },

        ["order"] = "4.3",
    },

    {
        ["list"] = {
            "buildings/tools/buildings_database_select",
            "buildings/tools/buildings_database_exporter",
            "buildings/tools/buildings_database_importer",
            "buildings/tools/buildings_database_eraser",
            "buildings/tools/buildings_database_swap_templates",
        },

        ["order"] = "4.4",
    },
}

-- #warning Commented Local InjectChangeListBuildingsTemplatesToolsBuildingDescValues(new_values)