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
    self.timeoutTime = nil

    self.configName = self.data:GetString("config_name")
    self.configNameList = self.data:GetString("config_list_name")
    self.configNameListLength = self.data:GetInt("config_list_length")

    self.missing_localization = self.data:GetString("missing_localization")
    self.buildingLowUpgrade = self.data:GetStringOrDefault("buildingLowUpgrade", "") or ""
    self.current_localization = self.data:GetString("current_localization")
    self.last_localization = self.data:GetString("last_localization")

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.SelectedSlotsBlueprints = nil

    local currentValue = selectorDB:GetStringOrDefault( self.configName, "" ) or ""

    if ( currentValue ~= nil and currentValue ~= "" and currentValue ~= ",," ) then

        self.SelectedSlotsBlueprints = self:GetSlotsArrayFromString(currentValue)
    end

    self.modeSelect = 0
    self.modeSelectLast = 100

    self.defaultModesArray = { self.modeSelect }

    self.modeValuesArray = self:FillLastSlotssList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()
end

function artificial_spawner_slots_replacer_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function artificial_spawner_slots_replacer_all_map_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
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

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )
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

    if ( self.selectedMode >= self.modeSelectLast ) then

        local indexSlots = self.selectedMode - self.modeSelectLast

        local slotsNumber = #self.lastSelectedSlotssArray - indexSlots

        self.lastSelectedSlots = self.lastSelectedSlotssArray[slotsNumber]

        self:SetSlotsIcons(self.lastSelectedSlots, markerDB)

        local messageText = "${" .. self.last_localization .. "}: " .. tostring(indexSlots + 1)

        markerDB:SetString("message_text", messageText)
        markerDB:SetInt("menu_visible", 1)

    elseif ( self.SelectedSlotsBlueprints ~= nil) then

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

        local selectableComponent = EntityService:GetConstComponent( entity, "SelectableComponent")
        if ( selectableComponent == nil ) then goto continue end

        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )

        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode <= BM_COMPLETED ) then goto continue end
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

    if ( self.selectedMode ~= self.modeSelect ) then
        return entities
    end

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

        self:AddedToSelection( entity )
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

function artificial_spawner_slots_replacer_all_map_tool:IsFullEqualSlots(slots1, slots2)

    for i=1,3 do

        local slot1 = slots1[i] or ""
        local slot2 = slots2[i] or ""

        if ( slot1 ~= slot2 ) then
            return false
        end
    end

    return true
end

function artificial_spawner_slots_replacer_all_map_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function artificial_spawner_slots_replacer_all_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function artificial_spawner_slots_replacer_all_map_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeSelectLast ) then

        if ( self:ChangeSelector(self.lastSelectedSlots) ) then

            return
        end

        return
    end



    if ( #self.selectedEntities == 0 ) then
        return
    end

    if ( self.SelectedSlotsBlueprints == nil) then
        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/artificial_spawner_slots_tools/replace_all_artificial_spawners")
        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end

function artificial_spawner_slots_replacer_all_map_tool:OnGuiPopupResultEvent( evt )

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

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

    self.popupShown = false
end

function artificial_spawner_slots_replacer_all_map_tool:ChangeSelector(slotsValues)

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    local value = table.concat(slotsValues, ",")

    selectorDB:SetString( self.configName, value )

    if ( self.SelectedSlotsBlueprints ~= nil ) then

        self:AddSlotsToLastList(self.SelectedSlotsBlueprints, selectorDB)
    end

    if ( slotsValues ~= nil ) then

        self:AddSlotsToLastList(slotsValues, selectorDB)
    end

    self.SelectedSlotsBlueprints = slotsValues

    self.modeValuesArray = self:FillLastSlotssList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()

    return true
end

function artificial_spawner_slots_replacer_all_map_tool:FillLastSlotssList(defaultModesArray, modeSelectLast, selector)

    local selectorDB = EntityService:GetOrCreateDatabase( selector )

    self.lastSelectedSlotssArray = self:GetCurrentList(self.configNameList, selectorDB)

    if ( self.SelectedSlotsBlueprints ~= nil ) then

        local index = self:GetSlotsIndexOf( self.lastSelectedSlotssArray, self.SelectedSlotsBlueprints )
        if ( index ~= nil ) then

            table.remove( self.lastSelectedSlotssArray, index )
        end
    end

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedSlotssArray-1 do

        Insert(modeValuesArray, (modeSelectLast + index))
    end

    return modeValuesArray
end

function artificial_spawner_slots_replacer_all_map_tool:GetSlotsIndexOf( array, slots )

    for index, value in ipairs( array ) do

        if ( self:IsFullEqualSlots(value, slots) ) then
            return index
        end
    end

    return nil
end

function artificial_spawner_slots_replacer_all_map_tool:GetCurrentList(parameterName, selectorDB)

    local currentListString = self:GetCurrentListString(parameterName, selectorDB)

    local currentListArray = Split( currentListString, "|" )

    local result = {}

    for slotsString in Iter( currentListArray ) do

        local slotsArray = self:GetSlotsArrayFromString(slotsString)

        Insert(result, slotsArray)
    end

    return result
end

function artificial_spawner_slots_replacer_all_map_tool:GetCurrentListString(parameterName, selectorDB)

    local currentList = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        currentList = selectorDB:GetStringOrDefault( parameterName, "" ) or ""
    end

    return currentList
end

function artificial_spawner_slots_replacer_all_map_tool:AddSlotsToLastList(slots, selectorDB)

    if ( slots == nil ) then
        return
    end

    local currentListArray = self:GetCurrentList(self.configNameList, selectorDB)

    if ( slots ~= nil ) then

        local index = self:GetSlotsIndexOf( currentListArray, slots )
        if ( index ~= nil ) then

            table.remove( currentListArray, index )
        end
    end

    Insert( currentListArray, slots )

    while ( #currentListArray > self.configNameListLength ) do

        table.remove( currentListArray, 1 )
    end



    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ",";

    local templateStringArray = {}

    for slotsArray in Iter( currentListArray ) do

        if ( #templateStringArray > 0 ) then
            Insert( templateStringArray, delimiterBlueprintsGroups )
        end

        Insert( templateStringArray, slotsArray[1] or "" )
        Insert( templateStringArray, delimiterBlueprintName )

        Insert( templateStringArray, slotsArray[2] or "" )
        Insert( templateStringArray, delimiterBlueprintName )

        Insert( templateStringArray, slotsArray[3] or "" )
    end

    local currentListString = table.concat( templateStringArray )

    if ( selectorDB ) then
        selectorDB:SetString(self.configNameList, currentListString)
    end
end

function artificial_spawner_slots_replacer_all_map_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local selectedMode = self:CheckModeValueExists(self.selectedMode)

    local index = IndexOf( self.modeValuesArray, selectedMode )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.modeValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.modeValuesArray[newIndex]

    self.selectedMode = newValue

    self:UpdateMarker()
end

function artificial_spawner_slots_replacer_all_map_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

return artificial_spawner_slots_replacer_all_map_tool
