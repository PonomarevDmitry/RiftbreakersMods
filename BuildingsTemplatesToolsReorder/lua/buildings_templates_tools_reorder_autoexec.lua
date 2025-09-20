------ #warning Commented Local ------
do return end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local InjectChangeBuildingsTemplatesToolsBuildingDescValues = function(blueprintName, order)

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        LogService:Log("InjectChangeBuildingsTemplatesToolsBuildingDescValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

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
            "buildings/tools/buildings_picker_25",

            "buildings/tools/buildings_picker_26",
            "buildings/tools/buildings_picker_27",
            "buildings/tools/buildings_picker_28",
            "buildings/tools/buildings_picker_29",
            "buildings/tools/buildings_picker_30",
            
            "buildings/tools/buildings_picker_31",
            "buildings/tools/buildings_picker_32",
            "buildings/tools/buildings_picker_33",
            "buildings/tools/buildings_picker_34",
            "buildings/tools/buildings_picker_35",

            "buildings/tools/buildings_picker_36",
            "buildings/tools/buildings_picker_37",
            "buildings/tools/buildings_picker_38",
            "buildings/tools/buildings_picker_39",
            "buildings/tools/buildings_picker_40",
            
            "buildings/tools/buildings_picker_41",
            "buildings/tools/buildings_picker_42",
            "buildings/tools/buildings_picker_43",
            "buildings/tools/buildings_picker_44",
            "buildings/tools/buildings_picker_45",

            "buildings/tools/buildings_picker_46",
            "buildings/tools/buildings_picker_47",
            "buildings/tools/buildings_picker_48",
            "buildings/tools/buildings_picker_49",
            "buildings/tools/buildings_picker_50",
            
            "buildings/tools/buildings_picker_51",
            "buildings/tools/buildings_picker_52",
            "buildings/tools/buildings_picker_53",
            "buildings/tools/buildings_picker_54",
            "buildings/tools/buildings_picker_55",

            "buildings/tools/buildings_picker_56",
            "buildings/tools/buildings_picker_57",
            "buildings/tools/buildings_picker_58",
            "buildings/tools/buildings_picker_59",
            "buildings/tools/buildings_picker_60",
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
            "buildings/tools/buildings_builder_25",

            "buildings/tools/buildings_builder_26",
            "buildings/tools/buildings_builder_27",
            "buildings/tools/buildings_builder_28",
            "buildings/tools/buildings_builder_29",
            "buildings/tools/buildings_builder_30",

            "buildings/tools/buildings_builder_31",
            "buildings/tools/buildings_builder_32",
            "buildings/tools/buildings_builder_33",
            "buildings/tools/buildings_builder_34",
            "buildings/tools/buildings_builder_35",

            "buildings/tools/buildings_builder_36",
            "buildings/tools/buildings_builder_37",
            "buildings/tools/buildings_builder_38",
            "buildings/tools/buildings_builder_39",
            "buildings/tools/buildings_builder_40",

            "buildings/tools/buildings_builder_41",
            "buildings/tools/buildings_builder_42",
            "buildings/tools/buildings_builder_43",
            "buildings/tools/buildings_builder_44",
            "buildings/tools/buildings_builder_45",

            "buildings/tools/buildings_builder_46",
            "buildings/tools/buildings_builder_47",
            "buildings/tools/buildings_builder_48",
            "buildings/tools/buildings_builder_49",
            "buildings/tools/buildings_builder_50",

            "buildings/tools/buildings_builder_51",
            "buildings/tools/buildings_builder_52",
            "buildings/tools/buildings_builder_53",
            "buildings/tools/buildings_builder_54",
            "buildings/tools/buildings_builder_55",

            "buildings/tools/buildings_builder_56",
            "buildings/tools/buildings_builder_57",
            "buildings/tools/buildings_builder_58",
            "buildings/tools/buildings_builder_59",
            "buildings/tools/buildings_builder_60",
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
            "buildings/tools/buildings_builder_mass_25",

            "buildings/tools/buildings_builder_mass_26",
            "buildings/tools/buildings_builder_mass_27",
            "buildings/tools/buildings_builder_mass_28",
            "buildings/tools/buildings_builder_mass_29",
            "buildings/tools/buildings_builder_mass_30",

            "buildings/tools/buildings_builder_mass_31",
            "buildings/tools/buildings_builder_mass_32",
            "buildings/tools/buildings_builder_mass_33",
            "buildings/tools/buildings_builder_mass_34",
            "buildings/tools/buildings_builder_mass_35",

            "buildings/tools/buildings_builder_mass_36",
            "buildings/tools/buildings_builder_mass_37",
            "buildings/tools/buildings_builder_mass_38",
            "buildings/tools/buildings_builder_mass_39",
            "buildings/tools/buildings_builder_mass_40",

            "buildings/tools/buildings_builder_mass_41",
            "buildings/tools/buildings_builder_mass_42",
            "buildings/tools/buildings_builder_mass_43",
            "buildings/tools/buildings_builder_mass_44",
            "buildings/tools/buildings_builder_mass_45",

            "buildings/tools/buildings_builder_mass_46",
            "buildings/tools/buildings_builder_mass_47",
            "buildings/tools/buildings_builder_mass_48",
            "buildings/tools/buildings_builder_mass_49",
            "buildings/tools/buildings_builder_mass_50",

            "buildings/tools/buildings_builder_mass_51",
            "buildings/tools/buildings_builder_mass_52",
            "buildings/tools/buildings_builder_mass_53",
            "buildings/tools/buildings_builder_mass_54",
            "buildings/tools/buildings_builder_mass_55",

            "buildings/tools/buildings_builder_mass_56",
            "buildings/tools/buildings_builder_mass_57",
            "buildings/tools/buildings_builder_mass_58",
            "buildings/tools/buildings_builder_mass_59",
            "buildings/tools/buildings_builder_mass_60",
        },

        ["order"] = "4.2",
    },

    {
        ["list"] = {
            "buildings/tools/buildings_upgrader",
            "buildings/tools/buildings_eraser",
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

InjectChangeListBuildingsTemplatesToolsBuildingDescValues(new_values)