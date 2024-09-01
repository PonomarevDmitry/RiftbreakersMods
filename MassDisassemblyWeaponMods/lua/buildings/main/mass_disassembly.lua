local building = require("lua/buildings/building.lua")
require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local mass_disassembly_utils = require("lua/utils/mass_disassembly_utils.lua")

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

        local weaponModKey = mass_disassembly_utils:GetWeaponModKey(itemBlueprintName, itemEntity.id)

        if ( hashByRarity[weaponModKey] == nil ) then
            goto continue
        end

        if ( IndexOf( hashByRarity[weaponModKey], itemEntity.id ) ~= nil ) then
            goto continue
        end

        Insert(hashByRarity[weaponModKey], itemEntity.id)

        ::continue::
    end

    local resourcesValues = mass_disassembly_utils:GetModsResources(hashRarityBlueprint)

    self.hashRarityBlueprint = hashRarityBlueprint
    self.resourcesValues = resourcesValues
    self.hashInsertedMods = hashInsertedMods

    local hasOverride, confimMessage = mass_disassembly_utils:HasOverride(resourcesValues)

    if ( hasOverride ) then

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/mass_disassembly_popup_ingame_buttons", confimMessage)
    else

        mass_disassembly_utils:DestroyAllWeaponMods(self.entity, self.hashRarityBlueprint, self.resourcesValues, self.hashInsertedMods)
    end
end

function mass_disassembly:OnGuiPopupResultEventResult( evt)

    self.popupShown = false

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventResult")

    local eventResult = evt:GetResult()

    if ( eventResult == "button_all" ) then

        mass_disassembly_utils:DestroyAllWeaponMods(self.entity, self.hashRarityBlueprint, self.resourcesValues, self.hashInsertedMods)

    elseif ( eventResult == "button_before_storage_limit" ) then

        mass_disassembly_utils:DestroyBeforeStorageLimit(self.entity, self.hashRarityBlueprint, self.resourcesValues, self.hashInsertedMods)

    elseif ( eventResult == "button_fill_storages" ) then

        mass_disassembly_utils:DestroyFillStorageLimit(self.entity, self.hashRarityBlueprint, self.resourcesValues, self.hashInsertedMods)
    end
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

                    local weaponModKey = mass_disassembly_utils:GetWeaponModKey(itemBlueprintName, modItem)

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

return mass_disassembly