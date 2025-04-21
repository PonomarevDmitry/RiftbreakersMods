local mass_disassembly_base = require("lua/buildings/main/mass_disassembly_base.lua")
require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local mass_disassembly_utils = require("lua/utils/mass_disassembly_utils.lua")

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

    local hashRarityBlueprint,hasItems = self:GetModsToDisassebly()
    if ( hasItems == false ) then
        return
    end
    

    local player = event:GetOwner()

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

        local weaponModKey = mass_disassembly_utils:GetWeaponModKey(itemBlueprintName, itemEntity.id)

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

    local resourcesValues = mass_disassembly_utils:GetModsResources(hashRarityBlueprint)

    self.hashRarityBlueprint = hashRarityBlueprint
    self.resourcesValues = resourcesValues

    local hasOverride, confimMessage = mass_disassembly_utils:HasOverride(resourcesValues)

    if ( hasOverride ) then

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/mass_disassembly_popup_ingame_buttons", confimMessage)
    else

        mass_disassembly_utils:DestroyAllWeaponMods(self.entity, self.hashRarityBlueprint, self.resourcesValues, nil)
    end
end

function mass_disassembly_by_rarity:OnGuiPopupResultEventResult( evt)

    self.popupShown = false

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

    local eventResult = evt:GetResult()

    if ( eventResult == "button_all" ) then

        mass_disassembly_utils:DestroyAllWeaponMods(self.entity, self.hashRarityBlueprint, self.resourcesValues, nil)

    elseif ( eventResult == "button_not_waste" ) then

        mass_disassembly_utils:DestroyBeforeStorageLimit(self.entity, self.hashRarityBlueprint, self.resourcesValues, nil)

    elseif ( eventResult == "button_fill_storages" ) then

        mass_disassembly_utils:DestroyFillStorageLimit(self.entity, self.hashRarityBlueprint, self.resourcesValues, nil)
    end
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

    menuDB:SetInt("slot_time_visible_1", 0)
    menuDB:SetInt("slot_time_visible_2", 0)
    menuDB:SetInt("slot_time_visible_3", 0)

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