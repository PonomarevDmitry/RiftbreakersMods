require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local mass_disassembly_utils = {}

mass_disassembly_utils.CostDescCache = {}

function mass_disassembly_utils:GetModsResources(hashRarityBlueprint)

    local resourcesValues = {}

    for rarity, blueprintList in pairs( hashRarityBlueprint ) do

        for weaponModKey, itemList in pairs( blueprintList ) do

            if ( #itemList == 0 ) then
                goto continue_weaponModKey
            end

            local firstItemId = itemList[1]

            local itemBlueprintName = EntityService:GetBlueprintName(firstItemId)

            local resourcesValuesForOne = mass_disassembly_utils:GetModCostDesc(itemBlueprintName)
            if ( resourcesValuesForOne ~= nil ) then

                for resourceName, sum in pairs( resourcesValuesForOne ) do

                    resourcesValues[resourceName] = ( resourcesValues[resourceName] or 0 ) + sum * #itemList
                end
            end

            ::continue_weaponModKey::
        end
    end

    return resourcesValues
end

function mass_disassembly_utils:GetModCostDesc(itemBlueprintName)

    if ( mass_disassembly_utils.CostDescCache[itemBlueprintName] ~= nil ) then

        return mass_disassembly_utils.CostDescCache[itemBlueprintName]
    end
    
    local result = mass_disassembly_utils:CalcModCostDesc(itemBlueprintName)

    mass_disassembly_utils.CostDescCache[itemBlueprintName] = result

    return result
end

function mass_disassembly_utils:CalcModCostDesc(itemBlueprintName)

    local blueprint = ResourceManager:GetBlueprint( itemBlueprintName )
    if ( blueprint == nil ) then
        return nil
    end

    local costDesc = blueprint:GetComponent("CostDesc")
    if ( costDesc == nil ) then
        return nil
    end

    local costDescRef = reflection_helper(costDesc)
    if ( costDescRef == nil or costDescRef.account == nil ) then
        return nil
    end

    local account = costDescRef.account
    if ( account.count == nil or account.count <= 0 ) then
        return nil
    end

    local resourcesValues = {}

    for i = 1,account.count do

        local researchCost = account[i]

        if ( researchCost ~= nil and researchCost.resource ~= nil and researchCost.resource ~= "" and researchCost.count ~= nil and researchCost.count > 0 ) then

            local sum = (researchCost.count / 2)

            resourcesValues[researchCost.resource] = ( resourcesValues[researchCost.resource] or 0 ) + sum
        end
    end

    return resourcesValues
end

function mass_disassembly_utils:DestroyAllWeaponMods(entity, hashRarityBlueprint, resourcesValues, hashInsertedMods)

    for rarity, blueprintList in pairs( hashRarityBlueprint ) do

        for weaponModKey, itemList in pairs( blueprintList ) do

            if ( #itemList > 0 ) then

                mass_disassembly_utils:DestroyEntitiesList(entity, itemList, hashInsertedMods)
            end
        end
    end

    for resource, addValue in pairs( resourcesValues ) do

        PlayerService:AddResourceAmount( resource, addValue )
    end

    EffectService:SpawnEffect(entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly_utils:DestroyBeforeStorageLimit(entity, hashRarityBlueprint, resourcesValues, hashInsertedMods)

    local resourceCurrentValue = {}
    local resourceLimit = {}
    local resourceAddValues = {}
    
    for resourceName, _ in pairs( resourcesValues ) do

        resourceCurrentValue[resourceName] = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        resourceLimit[resourceName] = PlayerService:GetResourceLimit( resourceName )
        resourceAddValues[resourceName] = 0
    end
    
    local entitiesToDestroy = {}

    for rarity=0,3 do

        if ( hashRarityBlueprint[rarity] == nil ) then
            goto continue_rarity
        end

        local blueprintList = hashRarityBlueprint[rarity]

        for weaponModKey, itemList in pairs( blueprintList ) do

            if ( #itemList == 0 ) then
                goto continue_weaponModKey
            end

            mass_disassembly_utils:SortWeaponsMods(itemList)

            local firstItemId = itemList[1]

            local itemBlueprintName = EntityService:GetBlueprintName(firstItemId)

            local resourcesValuesForOne = mass_disassembly_utils:GetModCostDesc(itemBlueprintName)
            if ( resourcesValuesForOne ~= nil ) then

                for i=1,#itemList do

                    local newCurrent = {}
    
                    for resourceName, _ in pairs( resourceLimit ) do

                        newCurrent[resourceName] = (resourceCurrentValue[resourceName] or 0) + (resourcesValuesForOne[resourceName] or 0)
                    end

                    if ( mass_disassembly_utils:IsAnyCurrentValueOverride(newCurrent, resourceLimit) ) then

                        goto end_selecting_entities
                    end

                    local itemId = itemList[i]

                    Insert(entitiesToDestroy, itemId)
    
                    for resourceName, _ in pairs( resourceLimit ) do

                        resourceCurrentValue[resourceName] = (newCurrent[resourceName] or 0)

                        resourceAddValues[resourceName] = (resourceAddValues[resourceName] or 0) + (resourcesValuesForOne[resourceName] or 0)
                    end
                end
            end

            ::continue_weaponModKey::
        end

        ::continue_rarity::
    end

    ::end_selecting_entities::

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    mass_disassembly_utils:DestroyEntitiesList(entity, entitiesToDestroy, hashInsertedMods)

    for resource, addValue in pairs( resourceAddValues ) do

        PlayerService:AddResourceAmount( resource, addValue )
    end

    EffectService:SpawnEffect(entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly_utils:DestroyFillStorageLimit(entity, hashRarityBlueprint, resourcesValues, hashInsertedMods)

    local resourceCurrentValue = {}
    local resourceLimit = {}
    local resourceAddValues = {}
    
    for resourceName, _ in pairs( resourcesValues ) do

        resourceCurrentValue[resourceName] = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        resourceLimit[resourceName] = PlayerService:GetResourceLimit( resourceName )
        resourceAddValues[resourceName] = 0
    end
    
    local entitiesToDestroy = {}

    for rarity=0,3 do

        if ( hashRarityBlueprint[rarity] == nil ) then
            goto continue_rarity
        end

        local blueprintList = hashRarityBlueprint[rarity]

        for weaponModKey, itemList in pairs( blueprintList ) do

            if ( #itemList == 0 ) then
                goto continue_weaponModKey
            end

            mass_disassembly_utils:SortWeaponsMods(itemList)

            local firstItemId = itemList[1]

            local itemBlueprintName = EntityService:GetBlueprintName(firstItemId)

            local resourcesValuesForOne = mass_disassembly_utils:GetModCostDesc(itemBlueprintName)
            if ( resourcesValuesForOne ~= nil ) then

                for i=1,#itemList do

                    if ( mass_disassembly_utils:IsAllCurrentValueOverride(resourceCurrentValue, resourceLimit) ) then

                        goto end_selecting_entities
                    end

                    local itemEntityId = itemList[i]

                    Insert(entitiesToDestroy, itemEntityId)
    
                    for resourceName, _ in pairs( resourceLimit ) do

                        resourceCurrentValue[resourceName] = (resourceCurrentValue[resourceName] or 0) + (resourcesValuesForOne[resourceName] or 0)

                        resourceAddValues[resourceName] = (resourceAddValues[resourceName] or 0) + (resourcesValuesForOne[resourceName] or 0)
                    end
                end
            end

            ::continue_weaponModKey::
        end

        ::continue_rarity::
    end

    ::end_selecting_entities::

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    mass_disassembly_utils:DestroyEntitiesList(entity, entitiesToDestroy, hashInsertedMods)

    for resource, addValue in pairs( resourceAddValues ) do

        PlayerService:AddResourceAmount( resource, addValue )
    end

    EffectService:SpawnEffect(entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly_utils:DestroyEntitiesList(entity, entitiesToDestroy, hashInsertedMods)

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    for itemEntityId in Iter(entitiesToDestroy) do

        if ( hashInsertedMods ~= nil and hashInsertedMods[itemEntityId] ~= nil ) then

            local slotName = hashInsertedMods[itemEntityId]

            QueueEvent( "EquipmentChangeRequest", entity, slotName, 0, INVALID_ID )
        end

        EntityService:RemoveEntity( itemEntityId )
    end
end

function mass_disassembly_utils:HasOverride(resourcesValues)

    local result = false

    local overrideResource = {}
    local resourceCurrentValue = {}
    local resourceLimit = {}
    
    for resourceName, addValue in pairs( resourcesValues ) do

        local currentValue = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        local limitValue = PlayerService:GetResourceLimit( resourceName )

        resourceCurrentValue[resourceName] = currentValue
        resourceLimit[resourceName] = limitValue

        if ( currentValue + addValue > limitValue ) then
            result = true

            overrideResource[resourceName] = true
        end
    end

    if ( result == false ) then

        return result, ""
    end

    local confimMessage = '<style="build_info_header_blue">${gui/menu/inventory/you_receive}</style>\n\n'

    local resourceArray = {}
    
    for resourceName, _ in pairs( resourcesValues ) do

        Insert(resourceArray, resourceName)
    end

    table.sort(resourceArray, function(a, b) return a:upper() < b:upper() end)
    
    for resourceName in Iter( resourceArray ) do

        local addValue = resourcesValues[resourceName]

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        local addValueStyle = "resource_green"

        if ( overrideResource[resourceName] == true ) then
            confimMessage = confimMessage .. '<style="resource_red">${gui/menu/inventory/storage_limit_exceeded}</style>\n'

            addValueStyle = "resource_red"
        end

        if ( ResourceManager:ResourceExists( "GameplayResourceDef", resourceName ) ) then

            local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resourceName)

            if ( resourceDef ~= nil ) then

                local resourceDefRef = reflection_helper( resourceDef )

                local resourceIcon = resourceDefRef.icon

                confimMessage = confimMessage .. '<img="' .. resourceIcon .. '">'

                confimMessage = confimMessage .. ' <style="inventory_description_yellow">${'.. resourceDefRef.localization_id .. '}</style>'

                confimMessage = confimMessage .. ' <style="resource_value">' .. tostring(currentValue) .. '</style> <style="resource_max">/ ' .. tostring(limitValue) .. '</style> <style="' .. addValueStyle .. '">+' .. tostring(addValue) .. '</style>'

                confimMessage = confimMessage .. '\n\n'
            end
        end
    end

    confimMessage = confimMessage .. '<style="build_info_header_blue">Disassemble Weapon Mods?</style>'

    return result, confimMessage
end

function mass_disassembly_utils:IsAnyCurrentValueOverride(resourceCurrentValue, resourceLimit)

    for resourceName, _ in pairs( resourceLimit ) do

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        if ( currentValue > limitValue ) then

            return true
        end
    end

    return false
end

function mass_disassembly_utils:IsAllCurrentValueOverride(resourceCurrentValue, resourceLimit)

    for resourceName, _ in pairs( resourceLimit ) do

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        if ( currentValue < limitValue ) then

            return false
        end
    end

    return true
end

function mass_disassembly_utils:SortWeaponsMods(itemList)

    local statValue = {}

    for itemEntityId in Iter(itemList) do

        local weaponModComponent = EntityService:GetComponent(itemEntityId, "WeaponModComponent")

        local weaponModComponentRef = reflection_helper( weaponModComponent )
        
        statValue[itemEntityId] = tonumber( weaponModComponentRef.mod_data.value )
    end

    local sorter = function( lh, rh )

        local lhStatValue = statValue[lh]
        local rhStatValue = statValue[rh]

        return lhStatValue < rhStatValue
    end

    table.sort(itemList, sorter)
end

function mass_disassembly_utils:GetAdditionalBlueprints(itemBlueprint)

    local result = {}

    if string.find(itemBlueprint, "advanced") then

        Insert( result, string.gsub( itemBlueprint, "advanced", "standard" ) )

    elseif string.find(itemBlueprint, "superior") then
    
        Insert( result, string.gsub( itemBlueprint, "superior", "standard" ) )
        Insert( result, string.gsub( itemBlueprint, "superior", "advanced" ) )

    elseif string.find(itemBlueprint, "extreme") then

        Insert( result, string.gsub( itemBlueprint, "extreme", "standard" ) )
        Insert( result, string.gsub( itemBlueprint, "extreme", "advanced" ) )
        Insert( result, string.gsub( itemBlueprint, "extreme", "superior" ) )
    end

    return result
end

function mass_disassembly_utils:GetWeaponModKey(blueprintName, entityId)

    if ( string.find(blueprintName, "items/loot/weapon_mods/mod_damage_over_time_") ~= nil

        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_standard_item") ~= nil
        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_advanced_item") ~= nil
        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_superior_item") ~= nil
        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_extreme_item") ~= nil
    ) then

        local weaponModComponent = EntityService:GetComponent(entityId, "WeaponModComponent")
        if ( weaponModComponent ~= nil ) then

            local weaponModComponentRef = reflection_helper( weaponModComponent )

            if ( weaponModComponentRef.mod_data and weaponModComponentRef.mod_data.damage_type ) then
        
                local keyResult = blueprintName .. "_" .. tostring(weaponModComponentRef.mod_data.damage_type)

                return keyResult
            end
        end
    end

    return blueprintName
end

return mass_disassembly_utils