local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local mass_disassembly_utils = require("lua/utils/mass_disassembly_utils.lua")

class 'mass_disassembly_by_rarity_tool' ( tool )

function mass_disassembly_by_rarity_tool:__init()
    tool.__init(self,self)
end

function mass_disassembly_by_rarity_tool:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_mass_disassembly_by_rarity_tool", self.entity)

    self.menuEntity = EntityService:SpawnAndAttachEntity("misc/mass_disassembly_slots_menu", self.entity)
    EntityService:SetPosition( self.menuEntity, 0, 4, 0 )

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.scaleMap = {
        1,
    }

    self.popupShown = false

    self.defaultRarityArray = {
        "standard",
        "advanced",
        "superior",
        "extreme",
    }

    self.selectedRarity = "standard"

    self:UpdateMarker()
end

function mass_disassembly_by_rarity_tool:UpdateMarker()

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

    menuDB:SetInt("slot_rarity_1", 0)
    menuDB:SetInt("slot_rarity_2", 0)
    menuDB:SetInt("slot_rarity_3", 0)

    menuDB:SetString("slot_icon_1", "")
    menuDB:SetString("slot_icon_2", "")
    menuDB:SetString("slot_icon_3", "")

    menuDB:SetString("slot_name_1", "")
    menuDB:SetString("slot_name_2", "")
    menuDB:SetString("slot_name_3", "")

    menuDB:SetInt("menu_visible", 0)

    self.selectedRarity = self:CheckRarityValueExists(self.selectedRarity)

    local blueprintName = "items/mass_disassembly_rarity/" .. self.selectedRarity

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint ~= nil ) then

        local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
        if ( inventoryItemComponent ~= nil ) then

            local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

            menuDB:SetInt("slot_visible_1", 1)
            menuDB:SetString("slot_icon_1", inventoryItemComponentRef.icon)
            menuDB:SetString("slot_name_1", inventoryItemComponentRef.name)
            menuDB:SetInt("slot_rarity_1", inventoryItemComponentRef.rarity)

            menuDB:SetInt("menu_visible", 1)
        end
    end
end

function mass_disassembly_by_rarity_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function mass_disassembly_by_rarity_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function mass_disassembly_by_rarity_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function mass_disassembly_by_rarity_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function mass_disassembly_by_rarity_tool:OnUpdate()
end

function mass_disassembly_by_rarity_tool:AddedToSelection( entity )
end

function mass_disassembly_by_rarity_tool:RemovedFromSelection( entity )
end

function mass_disassembly_by_rarity_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local selectedRarity = self:CheckRarityValueExists(self.selectedRarity)

    local index = IndexOf( self.defaultRarityArray, selectedRarity )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.defaultRarityArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.defaultRarityArray[newIndex]

    self.selectedRarity = newValue

    self:UpdateMarker()
end

function mass_disassembly_by_rarity_tool:CheckRarityValueExists( selectedRarity )

    selectedRarity = selectedRarity or self.defaultRarityArray[1]

    local index = IndexOf(self.defaultRarityArray, selectedRarity )

    if ( index == nil ) then

        return self.defaultRarityArray[1]
    end

    return selectedRarity
end

function mass_disassembly_by_rarity_tool:GetModsToDisassebly()

    local hasItems = false
    local hashRarityBlueprint = {}

    self.selectedRarity = self:CheckRarityValueExists(self.selectedRarity)

    local blueprintName = "items/mass_disassembly_rarity/" .. self.selectedRarity

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint ~= nil ) then

        local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")

        if ( inventoryItemComponent ~= nil ) then

            local inventoryItemComponentRef = reflection_helper( inventoryItemComponent )

            local rarity = inventoryItemComponentRef.rarity

            hashRarityBlueprint[rarity] = {}

            hasItems = true
        end
    end

    return hashRarityBlueprint, hasItems
end

function mass_disassembly_by_rarity_tool:OnActivateSelectorRequest()

    self.popupShown = self.popupShown or false

    if ( self.popupShown ) then
        return
    end

    local hashRarityBlueprint,hasItems = self:GetModsToDisassebly()
    if ( hasItems == false ) then
        return
    end
    


    local inventoryComponent = EntityService:GetComponent(self.player, "InventoryComponent")
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
            goto labelContinue
        end

        if ( not EntityService:IsAlive( itemEntity.id )) then
            goto labelContinue
        end

        local weaponModComponent = EntityService:GetComponent(itemEntity.id, "WeaponModComponent")
        if ( weaponModComponent == nil ) then
            goto labelContinue
        end

        local weaponModComponentRef = reflection_helper( weaponModComponent )
        if ( weaponModComponentRef.mod_data == nil ) then
            goto labelContinue
        end

        local rarity = weaponModComponentRef.mod_data.rarity

        if ( hashRarityBlueprint[rarity] == nil ) then
            goto labelContinue
        end

        local hashByRarity = hashRarityBlueprint[rarity]

        local itemBlueprintName = EntityService:GetBlueprintName(itemEntity.id)

        local weaponModKey = mass_disassembly_utils:GetWeaponModKey(itemBlueprintName, itemEntity.id)

        hashByRarity[weaponModKey] = hashByRarity[weaponModKey] or {}

        if ( IndexOf( hashByRarity[weaponModKey], itemEntity.id ) ~= nil ) then
            goto labelContinue
        end

        Insert(hashByRarity[weaponModKey], itemEntity.id)

        hasItems = true

        ::labelContinue::
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

function mass_disassembly_by_rarity_tool:OnGuiPopupResultEventResult( evt )

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

function mass_disassembly_by_rarity_tool:OnRelease()

    if ( self.menuEntity ~= nil ) then
        EntityService:RemoveEntity( self.menuEntity )
        self.menuEntity = nil
    end
end

return mass_disassembly_by_rarity_tool
