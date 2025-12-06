require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'artificial_spawner_slots_menu' ( LuaEntityObject )

function artificial_spawner_slots_menu:__init()
    LuaEntityObject.__init(self, self)
end

function artificial_spawner_slots_menu:init()

    self.parentBuilding = EntityService:GetParent( self.entity )

    self:RegisterEventHandlers()

    self.showMenu = 0

    local playerId = PlayerService:GetPlayerForEntity( self.parentBuilding )

    if ( PlayerService:IsInFighterMode( playerId ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnLoad()

    self.parentBuilding = EntityService:GetParent( self.entity )

    self:RegisterEventHandlers()

    self.showMenu = self.showMenu or 0

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:RegisterEventHandlers()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        return
    end

    self:RegisterHandler( self.parentBuilding, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.parentBuilding, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.parentBuilding, "UnequipedItemEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.parentBuilding, "UnequipItemRequest", "OnItemUnequippedEvent" )

	self:RegisterHandler( self.parentBuilding, "StartBuildingEvent",  "OnStartBuildingEvent" )
	self:RegisterHandler( self.parentBuilding, "BuildingBuildEndEvent", "OnBuildingBuildEndEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingModifiedEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function artificial_spawner_slots_menu:OnItemEquippedEvent( evt )

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnItemUnequippedEvent( evt )

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnStartBuildingEvent( evt )

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnBuildingBuildEndEvent( evt )

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnBuildingModifiedEvent( evt )

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:UpdateMenuIcons()
end

function artificial_spawner_slots_menu:UpdateMenuIcons()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        self.data:SetInt("menu_visible", 0)
        return
    end

    self.data:SetInt("slot_visible_1", 0)
    self.data:SetInt("slot_visible_2", 0)
    self.data:SetInt("slot_visible_3", 0)

    self.data:SetString("slot_icon_1", "")
    self.data:SetString("slot_icon_2", "")
    self.data:SetString("slot_icon_3", "")

    self.data:SetString("slot_name_1", "")
    self.data:SetString("slot_name_2", "")
    self.data:SetString("slot_name_3", "")

    self.data:SetInt("slot_rarity_1", 0)
    self.data:SetInt("slot_rarity_2", 0)
    self.data:SetInt("slot_rarity_3", 0)

    local equipmentComponent = EntityService:GetComponent(self.parentBuilding, "EquipmentComponent")
    if ( equipmentComponent == nil ) then
        self.data:SetInt("menu_visible", 0)
        return
    end

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local slotsCount = 1

    local slots = equipment.slots
    for i=1,slots.count do

        local slot = slots[i]

        local modItem = ItemService:GetEquippedItem( self.parentBuilding, slot.name )
        if ( modItem ~= nil and modItem ~= INVALID_ID ) then

            local blueprintName = EntityService:GetBlueprintName( modItem )

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint ~= nil ) then

                local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
                if ( inventoryItemComponent ~= nil ) then

                    local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                    self.data:SetInt("slot_visible_" .. tostring(slotsCount), 1)
                    self.data:SetString("slot_icon_" .. tostring(slotsCount), inventoryItemComponentRef.icon)
                    self.data:SetString("slot_name_" .. tostring(slotsCount), inventoryItemComponentRef.name)
                    self.data:SetInt("slot_rarity_" .. tostring(slotsCount), inventoryItemComponentRef.rarity)

                    slotsCount = slotsCount + 1
                end
            end
        end
    end

    if ( slotsCount == 1 ) then

        local defaultBiomeBlueprint = self:GetDefaultBiomeBlueprint();

        local blueprint = ResourceManager:GetBlueprint( defaultBiomeBlueprint )
        if ( blueprint ~= nil ) then

            local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
            if ( inventoryItemComponent ~= nil ) then

                local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                self.data:SetInt("slot_visible_" .. tostring(slotsCount), 1)
                self.data:SetString("slot_icon_" .. tostring(slotsCount), inventoryItemComponentRef.icon)
                self.data:SetString("slot_name_" .. tostring(slotsCount), inventoryItemComponentRef.name)
                self.data:SetInt("slot_rarity_" .. tostring(slotsCount), inventoryItemComponentRef.rarity)

                slotsCount = slotsCount + 1
            end
        end
    end

    self:SetMenuVisible()
end

function artificial_spawner_slots_menu:SetMenuVisible()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        self.data:SetInt("menu_visible", 0)
        return
    end

    local visible = 0

    self.showMenu = self.showMenu or 0

    if ( BuildingService:IsBuildingFinished( self.parentBuilding ) ) then
        visible = self.showMenu
    end

    self.data:SetInt("menu_visible", visible)
end

function artificial_spawner_slots_menu:GetDefaultBiomeBlueprint()

    local biomeName = MissionService:GetCurrentBiomeName()

    local result = "items/artificial_spawner_waves/" .. biomeName .. "_standard"

    return result
end

return artificial_spawner_slots_menu