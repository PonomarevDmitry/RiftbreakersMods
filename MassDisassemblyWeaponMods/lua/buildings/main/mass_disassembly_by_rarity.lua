local mass_disassembly_base = require("lua/buildings/main/mass_disassembly_base.lua")
require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'mass_disassembly_by_rarity' ( mass_disassembly_base )

function mass_disassembly_by_rarity:__init()
    mass_disassembly_base.__init(self,self)
end

function mass_disassembly_by_rarity:OnInit()

    if ( mass_disassembly_base.OnInit ) then
        mass_disassembly_base.OnInit(self)
    end

    self.data:SetString("action_icon", "gui/menu/inventory/stat_icons/quality_icon" )
end

function mass_disassembly_by_rarity:OnLoad()

    if ( mass_disassembly_base.OnLoad ) then
        mass_disassembly_base.OnLoad(self)
    end

    self.data:SetString("action_icon", "gui/menu/inventory/stat_icons/quality_icon" )
end

function mass_disassembly_by_rarity:OnInteractWithEntityRequest( event )

    self.popupShown = self.popupShown or false

    if ( self.popupShown ) then
        return
    end

    local player = event:GetOwner()

    local hashRarityBlueprint,hasItems = self:GetModsToDisassebly()
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



    local hasItems = false

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

        hashByRarity[weaponModKey] = hashByRarity[weaponModKey] or {}

        if ( IndexOf( hashByRarity[weaponModKey], itemEntity.id ) ~= nil ) then
            goto continue
        end

        Insert(hashByRarity[weaponModKey], itemEntity.id)

        hasItems = true

        ::continue::
    end

    if ( hasItems == false ) then
        return
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

    local hasOverride, confimMessage = self:HasOverride(resourcesValues)

    if ( hasOverride ) then

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/mass_disassembly_popup_ingame_buttons", confimMessage)
    else

        self:DestroyAllWeaponMods()
    end
end

function mass_disassembly_by_rarity:OnGuiPopupResultEventResult( evt)

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

function mass_disassembly_by_rarity:DestroyAllWeaponMods()

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

function mass_disassembly_by_rarity:DestroyBeforeStorageLimit()

    local resourceCurrentValue = {}
    local resourceLimit = {}
    local resourceAddValues = {}
    
    for resourceName, _ in pairs( self.resourcesValues ) do

        resourceCurrentValue[resourceName] = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        resourceLimit[resourceName] = PlayerService:GetResourceLimit( resourceName )
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

function mass_disassembly_by_rarity:DestroyFillStorageLimit()

    local resourceCurrentValue = {}
    local resourceLimit = {}
    local resourceAddValues = {}
    
    for resourceName, _ in pairs( self.resourcesValues ) do

        resourceCurrentValue[resourceName] = math.floor(PlayerService:GetResourceAmount( resourceName ) + 0.5)
        resourceLimit[resourceName] = PlayerService:GetResourceLimit( resourceName )
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

function mass_disassembly_by_rarity:DestroyEntitiesList(entitiesToDestroy)

    if ( #entitiesToDestroy == 0 ) then
        return
    end

    for itemEntityId in Iter(entitiesToDestroy) do

        EntityService:RemoveEntity( itemEntityId )
    end
end

function mass_disassembly_by_rarity:HasOverride(resourcesValues)

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

function mass_disassembly_by_rarity:IsAnyCurrentValueOverride(resourceCurrentValue, resourceLimit)

    for resourceName, _ in pairs( resourceLimit ) do

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        if ( currentValue > limitValue ) then

            return true
        end
    end

    return false
end

function mass_disassembly_by_rarity:IsAllCurrentValueOverride(resourceCurrentValue, resourceLimit)

    for resourceName, _ in pairs( resourceLimit ) do

        local currentValue = resourceCurrentValue[resourceName] or 0
        local limitValue = resourceLimit[resourceName] or 0

        if ( currentValue < limitValue ) then

            return false
        end
    end

    return true
end

function mass_disassembly_by_rarity:SortWeaponsMods(itemList)

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

function mass_disassembly_by_rarity:GetModsToDisassebly()

    local hasItems = false
    local hashRarityBlueprint = {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local inventoryItemComponent = EntityService:GetConstComponent( modItem, "InventoryItemComponent" )

                if ( inventoryItemComponent ~= nil ) then

                    local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )

                    local rarity = inventoryItemComponentRef.rarity

                    hashRarityBlueprint[rarity] = hashRarityBlueprint[rarity] or {}

                    local hashByRarity = hashRarityBlueprint[rarity]

                    hasItems = true
                end
            end
        end
    end

    return hashRarityBlueprint, hasItems
end

function mass_disassembly_by_rarity:PopulateSpecialActionInfo()

    local menuEntity = self.menuEntity
    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    local menuDB = EntityService:GetDatabase( menuEntity )
    if ( menuDB == nil ) then
        return
    end

    menuDB:SetInt("slot_visible_1", 0)
    menuDB:SetInt("slot_visible_2", 0)
    menuDB:SetInt("slot_visible_3", 0)

    menuDB:SetString("slot_icon_1", "")
    menuDB:SetString("slot_icon_2", "")
    menuDB:SetString("slot_icon_3", "")

    menuDB:SetString("slot_name_1", "")
    menuDB:SetString("slot_name_2", "")
    menuDB:SetString("slot_name_3", "")

    menuDB:SetInt("slot_rarity_1", 0)
    menuDB:SetInt("slot_rarity_2", 0)
    menuDB:SetInt("slot_rarity_3", 0)

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent == nil ) then
        menuDB:SetInt("menu_visible", 0)
        return
    end

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local slotsCount = 1

    local slots = equipment.slots
    for i=1,slots.count do

        local slot = slots[i]

        local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
        if ( modItem ~= nil and modItem ~= INVALID_ID ) then

            local blueprintName = EntityService:GetBlueprintName( modItem )

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint ~= nil ) then

                local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
                if ( inventoryItemComponent ~= nil ) then

                    local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                    menuDB:SetInt("slot_visible_" .. tostring(slotsCount), 1)
                    menuDB:SetString("slot_icon_" .. tostring(slotsCount), inventoryItemComponentRef.icon)
                    menuDB:SetString("slot_name_" .. tostring(slotsCount), inventoryItemComponentRef.name)
                    menuDB:SetInt("slot_rarity_" .. tostring(slotsCount), inventoryItemComponentRef.rarity)

                    slotsCount = slotsCount + 1
                end
            end
        end
    end

    self:SetMenuVisible(menuEntity)
end

return mass_disassembly_by_rarity