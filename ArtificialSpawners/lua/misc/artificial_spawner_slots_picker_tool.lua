local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'artificial_spawner_slots_picker_tool' ( tool )

function artificial_spawner_slots_picker_tool:__init()
    tool.__init(self,self)
end

function artificial_spawner_slots_picker_tool:OnInit()
    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)
    self.popupShown = false

    self.configName = self.data:GetString("config_name")
    self.configNameList = self.data:GetString("config_list_name")
    self.configNameListLength = self.data:GetInt("config_list_length")

    self.scaleMap = {
        1,
    }

    self.buildingLowUpgrade = self.data:GetStringOrDefault("buildingLowUpgrade", "") or ""
    self.current_localization = self.data:GetString("current_localization")
    self.last_localization = self.data:GetString("last_localization")
    self.item_type = self.data:GetString("item_type")
    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

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

function artificial_spawner_slots_picker_tool:GetSlotsArrayFromString(currentValue)

    local currentValueArray = Split( currentValue, "," )

    local result = {}

    for i=1,3 do
        result[i] = currentValueArray[i] or ""
    end

    return result
end

function artificial_spawner_slots_picker_tool:UpdateMarker()

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

        local messageText = "${" .. self.current_localization .. "}"

        markerDB:SetString("message_text", messageText)
        markerDB:SetInt("menu_visible", 1)
    else
        markerDB:SetInt("menu_visible", 0)
    end
end

function artificial_spawner_slots_picker_tool:SetSlotsIcons(slotsArray, markerDB)

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

function artificial_spawner_slots_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function artificial_spawner_slots_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function artificial_spawner_slots_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function artificial_spawner_slots_picker_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function artificial_spawner_slots_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function artificial_spawner_slots_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( self.selectedMode ~= self.modeSelect ) then
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

function artificial_spawner_slots_picker_tool:GetSlotsValues(equipmentComponent, entity)

    local result = {}

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local slots = equipment.slots

    for i=1,3 do

        local slot = slots[i]

        local blueprintName = ""

        if ( slot ) then

            local modItem = ItemService:GetEquippedItem( entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local itemType = ItemService:GetItemType( modItem )

                if ( itemType == self.item_type ) then
                    blueprintName = EntityService:GetBlueprintName( modItem )
                end
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

function artificial_spawner_slots_picker_tool:GetDefaultBiomeBlueprint()

    local biomeName = MissionService:GetCurrentBiomeName()

    local result = "items/artificial_spawner_waves/" .. biomeName .. "_standard"

    return result
end

function artificial_spawner_slots_picker_tool:IsEqualSlots(slots1, slots2)

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

function artificial_spawner_slots_picker_tool:IsFullEqualSlots(slots1, slots2)

    for i=1,3 do

        local slot1 = slots1[i] or ""
        local slot2 = slots2[i] or ""

        if ( slot1 ~= slot2 ) then
            return false
        end
    end

    return true
end

function artificial_spawner_slots_picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeSelectLast ) then

        if ( self:ChangeSelector(self.lastSelectedSlots) ) then

            return
        end

        return
    end


    for entity in Iter( self.selectedEntities ) do

        local equipmentComponent = EntityService:GetComponent(entity, "EquipmentComponent")

        if ( equipmentComponent ~= nil ) then

            local slotsValues = self:GetSlotsValues(equipmentComponent, entity)

            if ( slotsValues ~= nil and self:ChangeSelector(slotsValues) ) then

                return
            end
        end
    end
end

function artificial_spawner_slots_picker_tool:ChangeSelector(slotsValues)

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

    if ( self.next_tool ~= "" ) then

        local nextToolBuildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( self.next_tool ) )

        QueueEvent( "ChangeSelectorRequest", self.selector, nextToolBuildingDescRef.bp, nextToolBuildingDescRef.ghost_bp )

        local nextToolBlueprintName = nextToolBuildingDescRef.bp

        local lowName = BuildingService:FindLowUpgrade( nextToolBlueprintName )

        if ( lowName == nextToolBlueprintName ) then
            lowName = nextToolBuildingDescRef.name
        end

        BuildingService:SetBuildingLastLevel( self.playerId, lowName, nextToolBuildingDescRef.name )

        QueueEvent( "ChangeBuildingRequest", self.selector, lowName )
    end

    return true
end

function artificial_spawner_slots_picker_tool:FillLastSlotssList(defaultModesArray, modeSelectLast, selector)

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

function artificial_spawner_slots_picker_tool:GetSlotsIndexOf( array, slots )

    for index, value in ipairs( array ) do

        if ( self:IsFullEqualSlots(value, slots) ) then
            return index
        end
    end

    return nil
end

function artificial_spawner_slots_picker_tool:GetCurrentList(parameterName, selectorDB)

    local currentListString = self:GetCurrentListString(parameterName, selectorDB)

    local currentListArray = Split( currentListString, "|" )

    local result = {}

    for slotsString in Iter( currentListArray ) do

        local slotsArray = self:GetSlotsArrayFromString(slotsString)

        Insert(result, slotsArray)
    end

    return result
end

function artificial_spawner_slots_picker_tool:GetCurrentListString(parameterName, selectorDB)

    local currentList = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        currentList = selectorDB:GetStringOrDefault( parameterName, "" ) or ""
    end

    return currentList
end

function artificial_spawner_slots_picker_tool:AddSlotsToLastList(slots, selectorDB)

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

function artificial_spawner_slots_picker_tool:OnRotateSelectorRequest(evt)

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

function artificial_spawner_slots_picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

return artificial_spawner_slots_picker_tool
