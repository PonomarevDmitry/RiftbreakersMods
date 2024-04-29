local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'artificial_spawner_slots_replacer_all_map_tool' ( tool )

function artificial_spawner_slots_replacer_all_map_tool:__init()
    tool.__init(self,self)
end

function artificial_spawner_slots_replacer_all_map_tool:OnInit()
    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.scaleMap = {
        1,
    }

    local world_min = MissionService:GetWorldBoundsMin();
    local world_max = MissionService:GetWorldBoundsMax();

    world_min.y = -100.0
    world_max.y = 100.0

    self.allSpawners = FindService:FindEntitiesByBlueprintInBox("buildings/main/artificial_spawner", world_min, world_max )

    self.popupShown = false

    self.configName = self.data:GetString("config_name")
    self.configNameList = self.data:GetString("config_list_name")

    self.missing_localization = self.data:GetString("missing_localization")
    self.buildingLowUpgrade = self.data:GetStringOrDefault("buildingLowUpgrade", "") or ""

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.SelectedSlotsBlueprints = nil

    local currentValue = selectorDB:GetStringOrDefault( self.configName, "" ) or ""

    if ( currentValue ~= nil and currentValue ~= "" and currentValue ~= ",," ) then

        self.SelectedSlotsBlueprints = self:GetSlotsArrayFromString(currentValue)
    end

    self:UpdateMarker()
end

function artificial_spawner_slots_replacer_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function artificial_spawner_slots_replacer_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function artificial_spawner_slots_replacer_all_map_tool:GetSlotsArrayFromString(currentValue)

    local currentValueArray = Split( currentValue, "," )

    local result = {}

    for i=1,3 do
        result[i] = currentValueArray[i] or ""
    end

    return result
end

function artificial_spawner_slots_replacer_all_map_tool:UpdateMarker()

    local markerDB = EntityService:GetDatabase( self.childEntity )
    if ( markerDB == nil ) then
        return
    end

    markerDB:SetInt("slot_visible_1", 0)
    markerDB:SetInt("slot_visible_2", 0)
    markerDB:SetInt("slot_visible_3", 0)

    markerDB:SetString("slot_icon_1", "")
    markerDB:SetString("slot_icon_2", "")
    markerDB:SetString("slot_icon_3", "")

    markerDB:SetString("slot_name_1", "")
    markerDB:SetString("slot_name_2", "")
    markerDB:SetString("slot_name_3", "")

    markerDB:SetString("message_text", "")
    markerDB:SetInt("menu_visible", 1)

    if ( self.SelectedSlotsBlueprints ~= nil) then

        self:SetSlotsIcons(self.SelectedSlotsBlueprints, markerDB)

        markerDB:SetString("message_text", "")
    else
        markerDB:SetString("message_text", "${" .. self.missing_localization .. "}")

        markerDB:SetString("slot_icon_1", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetInt("slot_visible_1", 1)
    end
end

function artificial_spawner_slots_replacer_all_map_tool:SetSlotsIcons(slotsArray, markerDB)

    for i=1,3 do

        local blueprintName = slotsArray[i]

        if ( blueprintName ~= "" and blueprintName ~= nil ) then

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint ~= nil ) then

                local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
                if ( inventoryItemComponent ~= nil ) then

                    local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                    markerDB:SetInt("slot_visible_" .. tostring(i), 1)
                    markerDB:SetString("slot_icon_" .. tostring(i), inventoryItemComponentRef.icon)
                    markerDB:SetString("slot_name_" .. tostring(i), inventoryItemComponentRef.name)
                end
            end
        end
    end
end

function artificial_spawner_slots_replacer_all_map_tool:FindEntitiesToSelect( selectorComponent )

    local possibleSelectedEnts = self.allSpawners

    local distances = {}
    for entity in Iter( possibleSelectedEnts) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(possibleSelectedEnts, sorter)

    local selectedEntities = {}

    for entity in Iter( possibleSelectedEnts ) do

        local selectableComponent = EntityService:GetComponent( entity, "SelectableComponent")
        if ( selectableComponent == nil ) then goto continue end

        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )

        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode <= 2 ) then goto continue end 
        end

        Insert(selectedEntities, entity )
        ::continue::
    end

    if ( self.FilterSelectedEntities ) then
        selectedEntities = self:FilterSelectedEntities( selectedEntities )
    end

    return selectedEntities
end

function artificial_spawner_slots_replacer_all_map_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( self.SelectedSlotsBlueprints == nil or self.SelectedSlotsBlueprints == "") then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= self.buildingLowUpgrade ) then
            goto continue
        end

        local equipmentComponent = EntityService:GetComponent(entity, "EquipmentComponent")
        if ( equipmentComponent == nil ) then
            goto continue
        end

        local slotsValues = self:GetSlotsValues(equipmentComponent, entity)
        if ( slotsValues == nil ) then
            goto continue
        end

        if ( self.SelectedSlotsBlueprints ~= nil) then
            if ( self:IsEqualSlots(self.SelectedSlotsBlueprints, slotsValues) ) then
                goto continue
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function artificial_spawner_slots_replacer_all_map_tool:GetSlotsValues(equipmentComponent, entity)

    local result = {}

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local slots = equipment.slots

    for i=1,3 do

        local slot = slots[i]

        local blueprintName = ""

        if ( slot ) then

            local modItem = ItemService:GetEquippedItem( entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                blueprintName = EntityService:GetBlueprintName( modItem )
            end
        end

        Insert(result, blueprintName)
    end

    if ( result[1] == "" and result[2] == "" and result[3] == "" ) then

        local defaultBiomeBlueprint = self:GetDefaultBiomeBlueprint()

        result[1] = defaultBiomeBlueprint
    end

    return result
end

function artificial_spawner_slots_replacer_all_map_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
        end
    end
end

function artificial_spawner_slots_replacer_all_map_tool:GetDefaultBiomeBlueprint()

    local biomeName = MissionService:GetCurrentBiomeName()

    local result = "items/artificial_spawner_waves/" .. biomeName .. "_standard"

    return result
end

function artificial_spawner_slots_replacer_all_map_tool:IsEqualSlots(slots1, slots2)

    for i=1,3 do

        local slot1 = slots1[i] or ""
        local slot2 = slots2[i] or ""

        if ( slot1 == "" or slot2 == "" ) then
            goto continue
        end

        if ( slot1 ~= slot2 ) then
            return false
        end

        ::continue::
    end

    return true
end

function artificial_spawner_slots_replacer_all_map_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function artificial_spawner_slots_replacer_all_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function artificial_spawner_slots_replacer_all_map_tool:OnRotate()
end

function artificial_spawner_slots_replacer_all_map_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    if ( self.SelectedSlotsBlueprints == nil) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/artificial_spawner_slots_tools/replace_all_artificial_spawners")
        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end


function artificial_spawner_slots_replacer_all_map_tool:OnGuiPopupResultEvent( evt)

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    self.popupShown = false

    if ( evt:GetResult() ~= "button_yes" ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        local equipmentComponent = EntityService:GetComponent(entity, "EquipmentComponent")
        if ( equipmentComponent == nil ) then
            goto continueEntity
        end

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local selectedModItemBlueprintName = self.SelectedSlotsBlueprints[i] or ""

            if ( selectedModItemBlueprintName == nil or selectedModItemBlueprintName == "" or not ResourceManager:ResourceExists( "EntityBlueprint", selectedModItemBlueprintName ) ) then
                goto continueSlot
            end

            local modItem = ItemService:GetEquippedItem( entity, slot.name )
            if ( modItem == nil or modItem == INVALID_ID ) then
                goto replaceItem
            end

            if ( EntityService:GetBlueprintName( modItem ) == selectedModItemBlueprintName ) then
                goto continueSlot
            end

            ::replaceItem::

            local item = ItemService:GetFirstItemForBlueprint( entity, selectedModItemBlueprintName )

            if ( item == INVALID_ID ) then
                item = ItemService:AddItemToInventory( entity, selectedModItemBlueprintName )
            end

            if ( item ~= INVALID_ID ) then
                ItemService:EquipItemInSlot( entity, item, slot.name )
            end

            ::continueSlot::
        end

        BuildingService:BlinkBuilding(entity)

        ::continueEntity::
    end
end

return artificial_spawner_slots_replacer_all_map_tool
