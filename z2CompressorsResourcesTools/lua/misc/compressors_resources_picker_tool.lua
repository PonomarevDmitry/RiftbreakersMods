local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'compressors_resources_picker_tool' ( tool )

function compressors_resources_picker_tool:__init()
    tool.__init(self,self)
end

function compressors_resources_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function compressors_resources_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function compressors_resources_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_compressors_resources_picker_tool", self.entity)
    self.popupShown = false

    self.configName = "compressors_resources_picker_tool.selecteditem"
    self.configNameList = "compressors_resources_picker_tool.last_selected_resources"

    self.scaleMap = {
        1,
    }

    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.SelectedItemBlueprint = selectorDB:GetStringOrDefault( self.configName, "" ) or ""

    if ( self.SelectedItemBlueprint == nil or self.SelectedItemBlueprint == "" or not ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedItemBlueprint ) ) then

        self.SelectedItemBlueprint = ""
    end

    self.modeSelect = 0
    self.modeSelectLast = 100

    self.defaultModesArray = { self.modeSelect }

    self.modeValuesArray = self:FillLastResourcesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()
end

function compressors_resources_picker_tool:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    if ( self.selectedMode >= self.modeSelectLast ) then

        local indexResource = self.selectedMode - self.modeSelectLast

        local resourceNumber = #self.lastSelectedResourcesArray - indexResource

        local resourceBlueprintName = self.lastSelectedResourcesArray[resourceNumber]

        self.lastSelectedResource = resourceBlueprintName




        local blueprint = ResourceManager:GetBlueprint( resourceBlueprintName )

        local component = blueprint:GetComponent("InventoryItemComponent")

        local componentRef = reflection_helper(component)

        local resourceIcon = componentRef.bigger_icon
        local resourceName = componentRef.name

        local messageText = "${gui/hud/compressors_resources_tools/last_resource} " .. tostring(indexResource + 1) .. ": ${" .. resourceName .. "}"

        markerDB:SetString("compressors_resources_icon", resourceIcon)
        markerDB:SetString("compressors_resources_name", messageText)
        markerDB:SetInt("menu_visible", 1)

    elseif ( self.SelectedItemBlueprint ~= nil and self.SelectedItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedItemBlueprint ) ) then

        local blueprint = ResourceManager:GetBlueprint( self.SelectedItemBlueprint )

        local component = blueprint:GetComponent("InventoryItemComponent")

        local componentRef = reflection_helper(component)

        local resourceIcon = componentRef.bigger_icon
        local resourceName = componentRef.name

        local messageText = "${gui/hud/compressors_resources_tools/current_resource} ${" .. resourceName .. "}"

        markerDB:SetString("compressors_resources_icon", resourceIcon)
        markerDB:SetString("compressors_resources_name", messageText)
        markerDB:SetInt("menu_visible", 1)
    else
        markerDB:SetString("compressors_resources_icon", "")
        markerDB:SetString("compressors_resources_name", "")
        markerDB:SetInt("menu_visible", 0)
    end
end

function compressors_resources_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function compressors_resources_picker_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function compressors_resources_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function compressors_resources_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( self.selectedMode ~= self.modeSelect ) then
        return entities
    end

    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName ~= "liquid_compressor" and lowName ~= "liquid_decompressor" ) then
            goto continue
        end

        if ( lowName == "liquid_decompressor" ) then

            local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

            if ( modItem == nil or modItem == INVALID_ID ) then

                goto continue
            end

            if ( self.SelectedItemBlueprint ~= nil and self.SelectedItemBlueprint ~= "" ) then

                local modItemBlueprintName = EntityService:GetBlueprintName(modItem)

                if ( modItemBlueprintName == self.SelectedItemBlueprint ) then

                    goto continue
                end
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function compressors_resources_picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeSelectLast ) then

        if ( self:ChangeSelector(self.lastSelectedResource) ) then

            return
        end

        return
    end



    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName == "liquid_decompressor" ) then

            local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

            LogService:Log("modItem " .. tostring(modItem))

            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local modItemBlueprintName = EntityService:GetBlueprintName(modItem) or ""

                LogService:Log("modItemBlueprintName " .. tostring(modItemBlueprintName))

                if ( self:ChangeSelector(modItemBlueprintName) ) then

                    return
                end
            end

        elseif ( lowName == "liquid_compressor" ) then

        end
    end
end

function compressors_resources_picker_tool:ChangeSelector(modItemBlueprintName)

    if ( modItemBlueprintName == "" or modItemBlueprintName == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.configName, modItemBlueprintName )

    if ( self.SelectedItemBlueprint ~= nil and self.SelectedItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedItemBlueprint ) ) then

        self:AddResourceToLastList(self.SelectedItemBlueprint, selectorDB)
    end

    if ( modItemBlueprintName ~= nil and modItemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then

        self:AddResourceToLastList(modItemBlueprintName, selectorDB)
    end

    self.modeValuesArray = self:FillLastResourcesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

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

function compressors_resources_picker_tool:FillLastResourcesList(defaultModesArray, modeSelectLast, selector)

    local selectorDB = EntityService:GetOrCreateDatabase( selector )

    self.lastSelectedResourcesArray = self:GetCurrentList(self.configNameList, selectorDB)

    if ( self.SelectedItemBlueprint ~= nil and self.SelectedItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedItemBlueprint ) ) then

        if ( IndexOf( self.lastSelectedResourcesArray, self.SelectedItemBlueprint ) ~= nil ) then
            Remove( self.lastSelectedResourcesArray, self.SelectedItemBlueprint )
        end
    end

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedResourcesArray-1 do

        Insert(modeValuesArray, (modeSelectLast + index))
    end

    return modeValuesArray
end

function compressors_resources_picker_tool:GetCurrentList(parameterName, selectorDB)

    local currentListString = self:GetCurrentListString(parameterName, selectorDB)

    local currentListArray = Split( currentListString, "|" )

    return currentListArray
end

function compressors_resources_picker_tool:GetCurrentListString(parameterName, selectorDB)

    local currentList = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        currentList = selectorDB:GetStringOrDefault( parameterName, "" ) or ""
    end

    return currentList
end

function compressors_resources_picker_tool:AddResourceToLastList(selectedBlueprintName, selectorDB)

    if ( selectedBlueprintName == "" or selectedBlueprintName == nil ) then
        return
    end

    local currentListArray = self:GetCurrentList(self.configNameList, selectorDB)

    if ( IndexOf( currentListArray, selectedBlueprintName ) ~= nil ) then
        Remove( currentListArray, selectedBlueprintName )
    end

    Insert( currentListArray, selectedBlueprintName )






    while ( #currentListArray > 20 ) do

        table.remove( currentListArray, 1 )
    end

    local currentListString = table.concat( currentListArray, "|" )

    if ( selectorDB ) then
        selectorDB:SetString(self.configNameList, currentListString)
    end
end

function compressors_resources_picker_tool:OnRotateSelectorRequest(evt)

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

function compressors_resources_picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

return compressors_resources_picker_tool
 