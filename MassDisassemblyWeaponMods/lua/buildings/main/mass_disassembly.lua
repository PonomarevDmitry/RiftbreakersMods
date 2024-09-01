local building = require("lua/buildings/building.lua")
require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")

class 'mass_disassembly' ( building )

function mass_disassembly:__init()
    building.__init(self,self)
end

function mass_disassembly:OnInit()

    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function mass_disassembly:OnInteractWithEntityRequest( event )

    self.popupShown = self.popupShown or false

    if ( self.popupShown ) then
        return
    end

    local player = event:GetOwner()

    local hashRarityBlueprint,hashInsertedMods,hasItems = self:GetModsToDisassebly()
    if ( hasItems == false ) then
        return
    end


    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local inventoryComponentRef = reflection_helper( inventoryComponent )

    while ( inventoryComponentRef.reference_entity ~= nil and inventoryComponentRef.reference_entity.id ~= INVALID_ID ) do

        inventoryComponent = EntityService:GetComponent(inventoryComponentRef.reference_entity.id, "InventoryComponent")

        if ( inventoryComponent == nil ) then
            inventoryComponentRef = nil
            break
        end

        inventoryComponentRef = reflection_helper( inventoryComponent )
    end

    if ( inventoryComponentRef == nil or inventoryComponentRef.inventory == nil or inventoryComponentRef.inventory.items == nil ) then
        return
    end



    local inventoryItems = inventoryComponentRef.inventory.items

    for itemNumber=1,inventoryItems.count do

        local itemEntity = inventoryItems[itemNumber]

        if ( itemEntity == nil or itemEntity.id == nil) then
            goto continue
        end

        if ( not EntityService:IsAlive( itemEntity.id )) then
            goto continue
        end

        local weaponModComponent = EntityService:GetComponent(itemEntity.id, "WeaponModComponent")
        if ( weaponModComponent == nil ) then
            goto continue
        end

        local weaponModComponentRef = reflection_helper( weaponModComponent )
        if ( weaponModComponentRef.mod_data == nil ) then
            goto continue
        end

        local rarity = weaponModComponentRef.mod_data.rarity

        if ( hashRarityBlueprint[rarity] == nil ) then
            goto continue
        end

        local hashByRarity = hashRarityBlueprint[rarity]

        local itemBlueprintName = EntityService:GetBlueprintName(itemEntity.id)

        local weaponModKey = self:GetWeaponModKey(itemBlueprintName, itemEntity.id)

        if ( hashByRarity[weaponModKey] == nil ) then
            goto continue
        end

        if ( IndexOf( hashByRarity[weaponModKey], itemEntity.id ) ~= nil ) then
            goto continue
        end

        Insert(hashByRarity[weaponModKey], itemEntity.id)

        ::continue::
    end

    local resourcesValues = {}

    for rarity, blueprintList in pairs( hashRarityBlueprint ) do

        for weaponModKey, itemList in pairs( blueprintList ) do

            if ( #itemList > 0 ) then

                local firstItemId = itemList[1]

                local itemBlueprintName = EntityService:GetBlueprintName(firstItemId)

                local blueprint = ResourceManager:GetBlueprint( itemBlueprintName )
                if ( blueprint ~= nil ) then

                    local costDesc = blueprint:GetComponent("CostDesc")
                    if ( costDesc ~= nil ) then

                        local costDescRef = reflection_helper(costDesc)
                        if ( costDescRef ~= nil and costDescRef.account ~= nil ) then

                            local account = costDescRef.account

                            if ( account.count > 0 ) then

                                for i = 1,account.count do

                                    local researchCost = account[i]

                                    if ( researchCost ~= nil and researchCost.resource ~= nil and researchCost.resource ~= "" and researchCost.count ~= nil and researchCost.count > 0 ) then

                                        local sum = (researchCost.count / 2) * #itemList

                                        resourcesValues[researchCost.resource] = ( resourcesValues[researchCost.resource] or 0 ) + sum
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    self.hashRarityBlueprint = hashRarityBlueprint
    self.resourcesValues = resourcesValues
    self.hashInsertedMods = hashInsertedMods

    local hasOverride, confimMessage = self:HasOverride(resourcesValues)

    if ( hasOverride ) then

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/mass_disassembly_popup_ingame_buttons", confimMessage)
    else

        self:DestroyAllWeaponMods()
    end
end

function mass_disassembly:OnGuiPopupResultEventResult( evt)

    self.popupShown = false

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

    local eventResult = evt:GetResult()

    if ( eventResult == "button_all" ) then

        self:DestroyAllWeaponMods()

    elseif ( eventResult == "button_before_storage_limit" ) then

        self:DestroyBeforeStorageLimit()

    elseif ( eventResult == "button_fill_storages" ) then

        self:DestroyFillStorageLimit()
    end
end

function mass_disassembly:DestroyAllWeaponMods()

    for rarity, blueprintList in pairs( self.hashRarityBlueprint ) do

        for weaponModKey, itemList in pairs( blueprintList ) do

            self:DestroyEntitiesList(itemList)
        end
    end

    for resource, addValue in pairs( self.resourcesValues ) do

        PlayerService:AddResourceAmount( resource, addValue )
    end

    EffectService:SpawnEffect(self.entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly:DestroyBeforeStorageLimit()

    local resourceCurrentValue = {}
    local resourceLimit = {}
    local resourceAddValues = {}
    
    for resourceName, _ in pairs( self.resourcesValues ) do

        resourceCurrentValue[resourceName] = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        resourceLimit[resourceName] = PlayerService:GetResourceLimit( resourceName )
        resourceAddValues[resourceName] = 0
    end
    
    local entitiesToDestroy = {}

    for rarity=0,3 do

        if ( self.hashRarityBlueprint[rarity] ) then

            local blueprintList = self.hashRarityBlueprint[rarity]

            for weaponModKey, itemList in pairs( blueprintList ) do

                if ( #itemList > 0 ) then

                    self:SortWeaponsMods(itemList)

                    local firstItemId = itemList[1]

                    local itemBlueprintName = EntityService:GetBlueprintName(firstItemId)

                    local blueprint = ResourceManager:GetBlueprint( itemBlueprintName )
                    if ( blueprint ~= nil ) then

                        local costDesc = blueprint:GetComponent("CostDesc")
                        if ( costDesc ~= nil ) then

                            local costDescRef = reflection_helper(costDesc)
                            if ( costDescRef ~= nil and costDescRef.account ~= nil ) then

                                local account = costDescRef.account

                                if ( account.count > 0 ) then

                                    local resourcesValuesForOne = {}

                                    for i = 1,account.count do

                                        local researchCost = account[i]

                                        if ( researchCost ~= nil and researchCost.resource ~= nil and researchCost.resource ~= "" and researchCost.count ~= nil and researchCost.count > 0 ) then

                                            local sum = researchCost.count / 2

                                            resourcesValuesForOne[researchCost.resource] = ( resourcesValuesForOne[researchCost.resource] or 0 ) + sum
                                        end
                                    end
                
                                    for i=1,#itemList do

                                        local newCurrent = {}
    
                                        for resourceName, _ in pairs( resourceLimit ) do

                                            newCurrent[resourceName] = (resourceCurrentValue[resourceName] or 0) + (resourcesValuesForOne[resourceName] or 0)
                                        end

                                        if ( self:IsAnyCurrentValueOverride(newCurrent, resourceLimit) ) then

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
                            end
                        end
                    end
                end
            end
        end
    end

    ::end_selecting_entities::

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    self:DestroyEntitiesList(entitiesToDestroy)

    for resource, addValue in pairs( resourceAddValues ) do

        PlayerService:AddResourceAmount( resource, addValue )
    end

    EffectService:SpawnEffect(self.entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly:DestroyFillStorageLimit()

    local resourceCurrentValue = {}
    local resourceLimit = {}
    local resourceAddValues = {}
    
    for resourceName, _ in pairs( self.resourcesValues ) do

        resourceCurrentValue[resourceName] = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        resourceLimit[resourceName] = PlayerService:GetResourceLimit( resourceName )
        resourceAddValues[resourceName] = 0
    end
    
    local entitiesToDestroy = {}

    for rarity=0,3 do

        if ( self.hashRarityBlueprint[rarity] ) then

            local blueprintList = self.hashRarityBlueprint[rarity]

            for weaponModKey, itemList in pairs( blueprintList ) do

                if ( #itemList > 0 ) then

                    self:SortWeaponsMods(itemList)

                    local firstItemId = itemList[1]

                    local itemBlueprintName = EntityService:GetBlueprintName(firstItemId)

                    local blueprint = ResourceManager:GetBlueprint( itemBlueprintName )
                    if ( blueprint ~= nil ) then

                        local costDesc = blueprint:GetComponent("CostDesc")
                        if ( costDesc ~= nil ) then

                            local costDescRef = reflection_helper(costDesc)
                            if ( costDescRef ~= nil and costDescRef.account ~= nil ) then

                                local account = costDescRef.account

                                if ( account.count > 0 ) then

                                    local resourcesValuesForOne = {}

                                    for i = 1,account.count do

                                        local researchCost = account[i]

                                        if ( researchCost ~= nil and researchCost.resource ~= nil and researchCost.resource ~= "" and researchCost.count ~= nil and researchCost.count > 0 ) then

                                            local sum = researchCost.count / 2

                                            resourcesValuesForOne[researchCost.resource] = ( resourcesValuesForOne[researchCost.resource] or 0 ) + sum
                                        end
                                    end
                
                                    for i=1,#itemList do

                                        if ( self:IsAllCurrentValueOverride(resourceCurrentValue, resourceLimit) ) then

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
                            end
                        end
                    end
                end
            end
        end
    end

    ::end_selecting_entities::

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    self:DestroyEntitiesList(entitiesToDestroy)

    for resource, addValue in pairs( resourceAddValues ) do

        PlayerService:AddResourceAmount( resource, addValue )
    end

    EffectService:SpawnEffect(self.entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly:DestroyEntitiesList(entitiesToDestroy)

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    for itemEntityId in Iter(entitiesToDestroy) do

        if ( self.hashInsertedMods[itemEntityId] ~= nil ) then

            local slotName = self.hashInsertedMods[itemEntityId]

            QueueEvent( "EquipmentChangeRequest", self.entity, slotName, 0, INVALID_ID )
        end

        EntityService:RemoveEntity( itemEntityId )
    end
end

function mass_disassembly:HasOverride(resourcesValues)

    local result = false

    local confimMessage = '<style="build_info_header_blue">${gui/menu/inventory/you_receive}</style>\n\n'

    local resourceArray = {}
    
    for resourceName, _ in pairs( resourcesValues ) do

        Insert(resourceArray, resourceName)
    end

    table.sort(resourceArray, function(a, b) return a:upper() < b:upper() end)
    
    for resourceName in Iter( resourceArray ) do

        local addValue = resourcesValues[resourceName]

        local currentValue = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        local limitValue = PlayerService:GetResourceLimit( resourceName )

        local addValueStyle = "resource_green"

        if ( currentValue + addValue > limitValue ) then
            confimMessage = confimMessage .. '<style="resource_red">${gui/menu/inventory/storage_limit_exceeded}</style>\n'
            result = true

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

function mass_disassembly:IsAnyCurrentValueOverride(resourceCurrentValue, resourceLimit)

    for resourceName, _ in pairs( resourceLimit ) do

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        if ( currentValue > limitValue ) then

            return true
        end
    end

    return false
end

function mass_disassembly:IsAllCurrentValueOverride(resourceCurrentValue, resourceLimit)

    for resourceName, _ in pairs( resourceLimit ) do

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        if ( currentValue < limitValue ) then

            return false
        end
    end

    return true
end

function mass_disassembly:SortWeaponsMods(itemList)

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

function mass_disassembly:GetModsToDisassebly()

    local hasItems = false
    local hashRarityBlueprint = {}
    local hashInsertedMods = {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local weaponModComponent = EntityService:GetComponent(modItem, "WeaponModComponent")
                if ( weaponModComponent ~= nil ) then

                    local weaponModComponentRef = reflection_helper( weaponModComponent )

                    local rarity = weaponModComponentRef.mod_data.rarity

                    hashRarityBlueprint[rarity] = hashRarityBlueprint[rarity] or {}

                    local hashByRarity = hashRarityBlueprint[rarity]



                    local itemBlueprintName = EntityService:GetBlueprintName(modItem)

                    local weaponModKey = self:GetWeaponModKey(itemBlueprintName, modItem)

                    hashByRarity[weaponModKey] = hashByRarity[weaponModKey] or {}




                    hasItems = true

                    Insert(hashByRarity[weaponModKey], modItem)

                    hashInsertedMods[modItem] = slot.name
                end
            end
        end
    end

    return hashRarityBlueprint, hashInsertedMods, hasItems
end

function mass_disassembly:GetWeaponModKey(blueprintName, entityId)

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

return mass_disassembly