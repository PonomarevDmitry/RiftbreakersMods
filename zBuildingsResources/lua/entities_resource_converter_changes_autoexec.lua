require("lua/utils/reflection.lua")
-- test_log_blueprint player/player BlueprintComponent
-- test_log_blueprint player/player EquipmentComponent
-- test_log_blueprint player/player InventoryComponent
-- test_log_blueprint player/player ResourceStorageComponent

local InjectChangeBlueprintResourceConverterValues = function(blueprintName, direction, newResourceConverterValues)

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

    local inArray = resourceConverterDesc:GetField(direction):ToContainer()
    if ( inArray == nil ) then
        LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterDesc:GetField('" .. direction .. "'):ToContainer() NOT EXISTS.")
        return
    end
        
    for i=0,inArray:GetItemCount()-1 do

        local gameplayResourceObject = inArray:GetItem(i)
            
        if ( gameplayResourceObject == nil ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' gameplayResourceObject == nil")

            goto continue
        end

        local gameplayResourceObjectRef = reflection_helper(gameplayResourceObject)
        if ( gameplayResourceObjectRef.group ~= 12 ) then
            goto continue
        end

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
            --LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' newResourceConverterValues[resourceId] == nil " .. tostring(resourceId))

            goto continue
        end

        gameplayResourceObject:GetField("value"):SetValue(newResourceConverterValues[resourceId])

        ::continue::
    end
end

local InjectChangeListBlueprintResourceConverterValues = function(blueprintResourceConverterValues, direction)

    for _, configObject in ipairs(blueprintResourceConverterValues) do

        InjectChangeBlueprintResourceConverterValues(configObject.name, direction, configObject.resource_converter)
    end
end

local new_resource_converter_values = {
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant",
        ["resource_converter"] = {

            ["biomass_animal"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant_lvl_2",
        ["resource_converter"] = {

            ["biomass_animal"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant_lvl_3",
        ["resource_converter"] = {

            ["biomass_animal"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/energy/carbonium_powerplant",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_2",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_3",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/energy/nuclear_powerplant",
        ["resource_converter"] = {

            ["uranium"] = "0.4",
        },
    },
    
    {
        ["name"] = "buildings/energy/nuclear_powerplant_lvl_2",
        ["resource_converter"] = {

            ["uranium"] = "0.4",
        },
    },
    
    {
        ["name"] = "buildings/energy/nuclear_powerplant_lvl_3",
        ["resource_converter"] = {

            ["uranium"] = "0.4",
        },
    },


    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant_lvl_2",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant_lvl_3",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/resources/bio_composter",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_composter_lvl_2",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_composter_lvl_3",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/resources/carbonium_factory",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/carbonium_factory_lvl_2",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/carbonium_factory_lvl_3",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/resources/ionizer",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
            ["palladium"] = "0.2",
        },
    },
    
    {
        ["name"] = "buildings/resources/ionizer_lvl_2",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
            ["palladium"] = "0.2",
        },
    },
    
    {
        ["name"] = "buildings/resources/ionizer_lvl_3",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
            ["palladium"] = "0.2",
        },
    },


    
    {
        ["name"] = "buildings/resources/liquid_compressor",
        ["resource_converter"] = {

            ["energy"] = "50",
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_compressor_lvl_2",
        ["resource_converter"] = {

            ["energy"] = "75",
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_compressor_lvl_3",
        ["resource_converter"] = {

            ["energy"] = "100",
        },
    },


    
    {
        ["name"] = "buildings/resources/rare_element_mine",
        ["resource_converter"] = {
        
            ["uranium_ore_vein"] = "0.1",
            ["titanium_vein"] = "0.1",
            ["palladium_vein"] = "0.1",
            ["cobalt_vein"] = "0.1",
            ["voidinite_ore_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/rare_element_mine_lvl_2",
        ["resource_converter"] = {
        
            ["uranium_ore_vein"] = "0.1",
            ["titanium_vein"] = "0.1",
            ["palladium_vein"] = "0.1",
            ["cobalt_vein"] = "0.1",
            ["voidinite_ore_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/rare_element_mine_lvl_3",
        ["resource_converter"] = {
        
            ["uranium_ore_vein"] = "0.1",
            ["titanium_vein"] = "0.1",
            ["palladium_vein"] = "0.1",
            ["cobalt_vein"] = "0.1",
            ["voidinite_ore_vein"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/resources/steel_factory",
        ["resource_converter"] = {

            ["iron_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/steel_factory_lvl_2",
        ["resource_converter"] = {

            ["iron_vein"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/steel_factory_lvl_3",
        ["resource_converter"] = {

            ["iron_vein"] = "0.1",
        },
    },


    
    {
        ["name"] = "buildings/resources/supercoolant_refinery",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
        },
    },
    
    {
        ["name"] = "buildings/resources/supercoolant_refinery_lvl_2",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
        },
    },
    
    {
        ["name"] = "buildings/resources/supercoolant_refinery_lvl_3",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
        },
    },


    
    {
        ["name"] = "buildings/resources/uranium_centrifuge",
        ["resource_converter"] = {

            ["uranium_ore"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/uranium_centrifuge_lvl_2",
        ["resource_converter"] = {

            ["uranium_ore"] = "0.1",
        },
    },
    
    {
        ["name"] = "buildings/resources/uranium_centrifuge_lvl_3",
        ["resource_converter"] = {

            ["uranium_ore"] = "0.1",
        },
    },
}

InjectChangeListBlueprintResourceConverterValues(new_resource_converter_values, "in")

local new_resource_converter_values = {
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_3",
        ["resource_converter"] = {

            ["energy"] = "240",
        },
    },
}

InjectChangeListBlueprintResourceConverterValues(new_resource_converter_values, "out")