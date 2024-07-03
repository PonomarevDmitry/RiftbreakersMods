require("lua/utils/reflection.lua")
-- test_log_blueprint player/player BlueprintComponent
-- test_log_blueprint player/player EquipmentComponent
-- test_log_blueprint player/player InventoryComponent
-- test_log_blueprint player/player ResourceStorageComponent

local InjectChangeBlueprintResourceConverterValues = function(blueprintName, newResourceConverterValues)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    local resourceConverterDesc = blueprint:GetComponent("ResourceConverterDesc")
    if ( resourceConverterDesc == nil ) then
        LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterDesc NOT EXISTS.")
        return
    end

    local inArray = resourceConverterDesc:GetField("in"):ToContainer()
    if ( inArray == nil ) then
        LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterDesc:GetField('in'):ToContainer() NOT EXISTS.")
        return
    end
        
    for i=0,inArray:GetItemCount()-1 do

        local gameplayResourceObject = inArray:GetItem(i)
            
        if ( gameplayResourceObject == nil ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' gameplayResourceObject == nil")

            goto continue
        end

        local gameplayResourceObjectRef = reflection_helper(gameplayResourceObject)

        if ( gameplayResourceObjectRef.resource == nil ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint 'player/player' gameplayResourceObjectRef.resource == nil")

            goto continue
        end

        if ( gameplayResourceObjectRef.resource.resource == nil ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint 'player/player' gameplayResourceObjectRef.resource.resource == nil")

            goto continue
        end

        local resourceId = gameplayResourceObjectRef.resource.resource.id

        if ( resourceId == nil or resourceId == "" ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceId == nil or resourceId == ''")

            goto continue
        end

        if ( newResourceConverterValues[resourceId] == nil ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' newResourceConverterValues[resourceId] == nil")

            goto continue
        end

        gameplayResourceObject:GetField("value"):SetValue(newResourceConverterValues[resourceId])

        ::continue::
    end
end

local InjectChangeListBlueprintResourceConverterValues = function(blueprintResourceConverterValues)

    for blueprintName, newResourceConverterValues in pairs(blueprintResourceConverterValues) do

        InjectChangeBlueprintResourceConverterValues(blueprintName, newResourceConverterValues)
    end
end

local new_resource_converter_values = {

    ["buildings/energy/animal_biomass_powerplant"] = {

        ["biomass_animal"] = "0.1",
    },

    ["buildings/energy/animal_biomass_powerplant_lvl_2"] = {

        ["biomass_animal"] = "0.1",
    },

    ["buildings/energy/animal_biomass_powerplant_lvl_3"] = {

        ["biomass_animal"] = "0.1",
    },



    ["buildings/energy/carbonium_powerplant"] = {

        ["carbon_vein"] = "0.1",
    },

    ["buildings/energy/carbonium_powerplant_lvl_2"] = {

        ["carbon_vein"] = "0.1",
    },

    ["buildings/energy/carbonium_powerplant_lvl_3"] = {

        ["carbon_vein"] = "0.1",
    },



    ["buildings/energy/nuclear_powerplant"] = {

        ["uranium"] = "0.4",
    },

    ["buildings/energy/nuclear_powerplant_lvl_2"] = {

        ["uranium"] = "0.4",
    },

    ["buildings/energy/nuclear_powerplant_lvl_3"] = {

        ["uranium"] = "0.4",
    },



    ["buildings/energy/plant_biomass_powerplant"] = {

        ["biomass_plant"] = "0.1",
    },

    ["buildings/energy/plant_biomass_powerplant_lvl_2"] = {

        ["biomass_plant"] = "0.1",
    },

    ["buildings/energy/plant_biomass_powerplant_lvl_3"] = {

        ["biomass_plant"] = "0.1",
    },



    ["buildings/resources/bio_composter"] = {

        ["biomass_plant"] = "0.1",
    },

    ["buildings/resources/bio_composter_lvl_2"] = {

        ["biomass_plant"] = "0.1",
    },

    ["buildings/resources/bio_composter_lvl_3"] = {

        ["biomass_plant"] = "0.1",
    },



    ["buildings/resources/carbonium_factory"] = {

        ["carbon_vein"] = "0.1",
    },

    ["buildings/resources/carbonium_factory_lvl_2"] = {

        ["carbon_vein"] = "0.1",
    },

    ["buildings/resources/carbonium_factory_lvl_3"] = {

        ["carbon_vein"] = "0.1",
    },



    ["buildings/resources/ionizer"] = {

        ["titanium"] = "0.2",
        ["palladium"] = "0.2",
    },

    ["buildings/resources/ionizer_lvl_2"] = {

        ["titanium"] = "0.2",
        ["palladium"] = "0.2",
    },

    ["buildings/resources/ionizer_lvl_3"] = {

        ["titanium"] = "0.2",
        ["palladium"] = "0.2",
    },



    ["buildings/resources/liquid_compressor"] = {

        ["energy"] = "50",
    },

    ["buildings/resources/liquid_compressor_lvl_2"] = {

        ["energy"] = "75",
    },

    ["buildings/resources/liquid_compressor_lvl_3"] = {

        ["energy"] = "100",
    },



    ["buildings/resources/liquid_compressor"] = {

        ["energy"] = "50",
    },

    ["buildings/resources/liquid_compressor_lvl_2"] = {

        ["energy"] = "75",
    },

    ["buildings/resources/liquid_compressor_lvl_3"] = {

        ["energy"] = "100",
    },



    ["buildings/resources/rare_element_mine"] = {
        
        ["uranium_ore_vein"] = "0.1",
        ["titanium_vein"] = "0.1",
        ["palladium_vein"] = "0.1",
        ["cobalt_vein"] = "0.1",
        ["voidinite_ore_vein"] = "0.1",
    },

    ["buildings/resources/rare_element_mine_lvl_2"] = {
        
        ["uranium_ore_vein"] = "0.1",
        ["titanium_vein"] = "0.1",
        ["palladium_vein"] = "0.1",
        ["cobalt_vein"] = "0.1",
        ["voidinite_ore_vein"] = "0.1",
    },

    ["buildings/resources/rare_element_mine_lvl_3"] = {
        
        ["uranium_ore_vein"] = "0.1",
        ["titanium_vein"] = "0.1",
        ["palladium_vein"] = "0.1",
        ["cobalt_vein"] = "0.1",
        ["voidinite_ore_vein"] = "0.1",
    },



    ["buildings/resources/steel_factory"] = {

        ["iron_vein"] = "0.1",
    },

    ["buildings/resources/steel_factory_lvl_2"] = {

        ["iron_vein"] = "0.1",
    },

    ["buildings/resources/steel_factory_lvl_3"] = {

        ["iron_vein"] = "0.1",
    },



    ["buildings/resources/supercoolant_refinery"] = {

        ["titanium"] = "0.2",
    },

    ["buildings/resources/supercoolant_refinery_lvl_2"] = {

        ["titanium"] = "0.2",
    },

    ["buildings/resources/supercoolant_refinery_lvl_3"] = {

        ["titanium"] = "0.2",
    },



    ["buildings/resources/uranium_centrifuge"] = {

        ["uranium_ore"] = "0.1",
    },

    ["buildings/resources/uranium_centrifuge_lvl_2"] = {

        ["uranium_ore"] = "0.1",
    },

    ["buildings/resources/uranium_centrifuge_lvl_3"] = {

        ["uranium_ore"] = "0.1",
    },
}

InjectChangeListBlueprintResourceConverterValues(new_resource_converter_values)