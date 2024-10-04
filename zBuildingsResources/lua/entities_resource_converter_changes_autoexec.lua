require("lua/utils/reflection.lua")
-- test_log_blueprint player/player BlueprintComponent
-- test_log_blueprint player/player EquipmentComponent
-- test_log_blueprint player/player InventoryComponent
-- test_log_blueprint player/player ResourceStorageComponent

local InjectChangeBlueprintResourceConverterValues = function(blueprintName, direction, newResourceConverterValues, newResourceConverterComponentValues)

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' NOT EXISTS.")
        return
    end

    if ( newResourceConverterValues ~= nil ) then

        local resourceConverterDesc = blueprint:GetComponent("ResourceConverterDesc")
        if ( resourceConverterDesc == nil ) then
            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterDesc NOT EXISTS.")
        
        else
            local inArray = resourceConverterDesc:GetField(direction):ToContainer()
            if ( inArray == nil ) then
                LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterDesc:GetField('" .. direction .. "'):ToContainer() NOT EXISTS.")

            else

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
        end
    end



    if ( newResourceConverterComponentValues ~= nil ) then

        local convertedHash = {}

        for key, value in pairs(newResourceConverterComponentValues) do

            local keyHash = CalcHash(key)

            convertedHash[keyHash] = value

            --LogService:Log("InjectChangeBlueprintResourceConverterValues convertedHash Blueprint '" .. blueprintName .. "' key " .. key .. "  keyHash " .. keyHash .. " value = " .. tostring(value))
        end

        local resourceConverterComponent = blueprint:GetComponent("ResourceConverterComponent")
        if ( resourceConverterComponent == nil ) then

            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterComponent NOT EXISTS.")
        else

            local resourcesArray = resourceConverterComponent:GetField("resources"):ToContainer()
            if ( resourcesArray == nil ) then

                LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' resourceConverterComponent:GetField('resources'):ToContainer() NOT EXISTS.")
            else

                for i=0,resourcesArray:GetItemCount()-1 do

                    local flatMap_GameplayResourceTypeResourceBasket = resourcesArray:GetItem(i)

                    local flatMap_GameplayResourceTypeResourceBasketContainer = flatMap_GameplayResourceTypeResourceBasket:ToContainer()
            
                    for j=0,flatMap_GameplayResourceTypeResourceBasketContainer:GetItemCount()-1 do

                        local pair_GameplayResourceType_ResourceBasket = flatMap_GameplayResourceTypeResourceBasketContainer:GetItem(j)

                        if ( pair_GameplayResourceType_ResourceBasket ~= nil ) then

                            local pair_GameplayResourceType_ResourceBasketValue = pair_GameplayResourceType_ResourceBasket:GetField("value")

                            if ( pair_GameplayResourceType_ResourceBasketValue ~= nil ) then

                                local resourceArray = pair_GameplayResourceType_ResourceBasketValue:GetField("resource"):ToContainer()

                                if ( resourceArray == nil ) then

                                    LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' pair_GameplayResourceType_ResourceBasketValue:GetField('resources'):ToContainer() NOT EXISTS.")
                                else

                                    for k=0,resourceArray:GetItemCount()-1 do
                                        
                                        local keyValueObject = resourceArray:GetItem(k)

                                        local keyValueObjectRef = reflection_helper(keyValueObject)

                                        if ( keyValueObjectRef.key ~= nil and keyValueObjectRef.key.hash ~= nil and convertedHash[keyValueObjectRef.key.hash] ~= nil ) then

                                            keyValueObjectRef.value.value = convertedHash[keyValueObjectRef.key.hash]
                                        end
                                    end
                                end
                            else
                                LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' pair_GameplayResourceType_ResourceBasketValue NOT EXISTS.")
                            end
                        else
                            LogService:Log("InjectChangeBlueprintResourceConverterValues Blueprint '" .. blueprintName .. "' pair_GameplayResourceType_ResourceBasket NOT EXISTS.")
                        end
                    end
                end
            end
        end
    end
end

local InjectChangeListBlueprintResourceConverterValues = function(blueprintResourceConverterValues, direction)

    for _, configObject in ipairs(blueprintResourceConverterValues) do

        InjectChangeBlueprintResourceConverterValues(configObject.name, direction, configObject.resource_converter, configObject.resource_converter_comp)
    end
end

local new_resource_converter_values = {
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant",
        ["resource_converter"] = {

            ["biomass_animal"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_animal"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant_lvl_2",
        ["resource_converter"] = {

            ["biomass_animal"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_animal"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/energy/animal_biomass_powerplant_lvl_3",
        ["resource_converter"] = {

            ["biomass_animal"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_animal"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/energy/carbonium_powerplant",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["carbon_vein"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_2",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["carbon_vein"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/energy/carbonium_powerplant_lvl_3",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["carbon_vein"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/energy/nuclear_powerplant",
        ["resource_converter"] = {

            ["uranium"] = "0.4",
        },

        ["resource_converter_comp"] = {

            ["uranium"] = 400000,
        },
    },
    
    {
        ["name"] = "buildings/energy/nuclear_powerplant_lvl_2",
        ["resource_converter"] = {

            ["uranium"] = "0.4",
        },

        ["resource_converter_comp"] = {

            ["uranium"] = 400000,
        },
    },
    
    {
        ["name"] = "buildings/energy/nuclear_powerplant_lvl_3",
        ["resource_converter"] = {

            ["uranium"] = "0.4",
        },

        ["resource_converter_comp"] = {

            ["uranium"] = 400000,
        },
    },


    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_plant"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant_lvl_2",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_plant"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/energy/plant_biomass_powerplant_lvl_3",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_plant"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/resources/bio_composter",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_plant"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_composter_lvl_2",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_plant"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/bio_composter_lvl_3",
        ["resource_converter"] = {

            ["biomass_plant"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["biomass_plant"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/resources/carbonium_factory",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["carbon_vein"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/carbonium_factory_lvl_2",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["carbon_vein"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/carbonium_factory_lvl_3",
        ["resource_converter"] = {

            ["carbon_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["carbon_vein"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/resources/ionizer",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
            ["palladium"] = "0.2",
        },

        ["resource_converter_comp"] = {

            ["titanium"] = 200000,
            ["palladium"] = 200000,
        },
    },
    
    {
        ["name"] = "buildings/resources/ionizer_lvl_2",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
            ["palladium"] = "0.2",
        },

        ["resource_converter_comp"] = {

            ["titanium"] = 200000,
            ["palladium"] = 200000,
        },
    },
    
    {
        ["name"] = "buildings/resources/ionizer_lvl_3",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
            ["palladium"] = "0.2",
        },

        ["resource_converter_comp"] = {

            ["titanium"] = 200000,
            ["palladium"] = 200000,
        },
    },


    
    {
        ["name"] = "buildings/resources/liquid_compressor",
        ["resource_converter"] = {

            ["energy"] = "50",
        },

        ["resource_converter_comp"] = {

            ["energy"] = 50000000,
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_compressor_lvl_2",
        ["resource_converter"] = {

            ["energy"] = "75",
        },

        ["resource_converter_comp"] = {

            ["energy"] = 75000000,
        },
    },
    
    {
        ["name"] = "buildings/resources/liquid_compressor_lvl_3",
        ["resource_converter"] = {

            ["energy"] = "100",
        },

        ["resource_converter_comp"] = {

            ["energy"] = 100000000,
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
            ["cosmonite_ore_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["uranium_ore_vein"] = 100000,
            ["titanium_vein"] = 100000,
            ["palladium_vein"] = 100000,
            ["cobalt_vein"] = 100000,
            ["voidinite_ore_vein"] = 100000,
            ["cosmonite_ore_vein"] = 100000,
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
            ["cosmonite_ore_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["uranium_ore_vein"] = 100000,
            ["titanium_vein"] = 100000,
            ["palladium_vein"] = 100000,
            ["cobalt_vein"] = 100000,
            ["voidinite_ore_vein"] = 100000,
            ["cosmonite_ore_vein"] = 100000,
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
            ["cosmonite_ore_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["uranium_ore_vein"] = 100000,
            ["titanium_vein"] = 100000,
            ["palladium_vein"] = 100000,
            ["cobalt_vein"] = 100000,
            ["voidinite_ore_vein"] = 100000,
            ["cosmonite_ore_vein"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/resources/steel_factory",
        ["resource_converter"] = {

            ["iron_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["iron_vein"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/steel_factory_lvl_2",
        ["resource_converter"] = {

            ["iron_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["iron_vein"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/steel_factory_lvl_3",
        ["resource_converter"] = {

            ["iron_vein"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["iron_vein"] = 100000,
        },
    },


    
    {
        ["name"] = "buildings/resources/supercoolant_refinery",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
        },

        ["resource_converter_comp"] = {

            ["titanium"] = 200000,
        },
    },
    
    {
        ["name"] = "buildings/resources/supercoolant_refinery_lvl_2",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
        },

        ["resource_converter_comp"] = {

            ["titanium"] = 200000,
        },
    },
    
    {
        ["name"] = "buildings/resources/supercoolant_refinery_lvl_3",
        ["resource_converter"] = {

            ["titanium"] = "0.2",
        },

        ["resource_converter_comp"] = {

            ["titanium"] = 200000,
        },
    },


    
    {
        ["name"] = "buildings/resources/uranium_centrifuge",
        ["resource_converter"] = {

            ["uranium_ore"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["uranium_ore"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/uranium_centrifuge_lvl_2",
        ["resource_converter"] = {

            ["uranium_ore"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["uranium_ore"] = 100000,
        },
    },
    
    {
        ["name"] = "buildings/resources/uranium_centrifuge_lvl_3",
        ["resource_converter"] = {

            ["uranium_ore"] = "0.1",
        },

        ["resource_converter_comp"] = {

            ["uranium_ore"] = 100000,
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

        ["resource_converter_comp"] = {

            ["energy"] = 240000000,
        },
    },
}

InjectChangeListBlueprintResourceConverterValues(new_resource_converter_values, "out")