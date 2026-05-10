local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'compressors_resources_replacer_all_tool' ( tool )

function compressors_resources_replacer_all_tool:__init()
    tool.__init(self,self)
end

function compressors_resources_replacer_all_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function compressors_resources_replacer_all_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function compressors_resources_replacer_all_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_compressors_resources_replacer_all_tool", self.entity)
    self.popupShown = false
    self.timeoutTime = nil

    self.configName = "compressors_resources_picker_tool.selecteditem"
    self.configNameList = "compressors_resources_picker_tool.last_selected_resources"

    self.SelectedItemBlueprint = self:GetResourceItem()

    self.modeSelect = 0
    self.modeSelectLast = 100

    self.defaultModesArray = { self.modeSelect }

    self.modeValuesArray = self:FillLastResourcesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()
end

function compressors_resources_replacer_all_tool:UpdateMarker()

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

        local messageText = "${" .. resourceName .. "}"

        markerDB:SetString("compressors_resources_icon", resourceIcon)
        markerDB:SetString("compressors_resources_name", messageText)
        markerDB:SetInt("menu_visible", 1)
    else
        markerDB:SetString("compressors_resources_icon", "")
        markerDB:SetString("compressors_resources_name", "")
        markerDB:SetInt("menu_visible", 0)
    end
end

function compressors_resources_replacer_all_tool:GetResourceItem()

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    if ( selectorDB and selectorDB:HasString(self.configName) ) then

        local resource_item = selectorDB:GetStringOrDefault( self.configName, "" )

        if ( resource_item ~= nil and resource_item ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", resource_item ) ) then
            return resource_item
        end
    end

    return ""
end

function compressors_resources_replacer_all_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function compressors_resources_replacer_all_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function compressors_resources_replacer_all_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function compressors_resources_replacer_all_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    if ( self.selectedMode ~= self.modeSelect ) then
        return result
    end

    local hashResult = {}

    local entitiesBuildings = {}

    ConcatUnique( entitiesBuildings, FindService:FindEntitiesByBlueprint( "buildings/resources/liquid_decompressor" ) )
    ConcatUnique( entitiesBuildings, FindService:FindEntitiesByBlueprint( "buildings/resources/liquid_decompressor_lvl_2" ) )
    ConcatUnique( entitiesBuildings, FindService:FindEntitiesByBlueprint( "buildings/resources/liquid_decompressor_lvl_3" ) )

    for entity in Iter( entitiesBuildings ) do

        if ( not EntityService:IsAlive(entity) ) then
            goto labelContinue
        end

        if ( hashResult[entity] == true ) then
            goto labelContinue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto labelContinue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto labelContinue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName ~= "liquid_decompressor" ) then
            goto labelContinue
        end

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil and modItem ~= INVALID_ID ) then

            local modItemBlueprint = EntityService:GetBlueprintName(modItem)

            if ( modItemBlueprint == self.SelectedItemBlueprint ) then

                goto labelContinue
            end
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function compressors_resources_replacer_all_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeSelectLast ) then

        if ( self:ChangeSelector(self.lastSelectedResource) ) then

            return
        end

        return
    end

    if ( #self.selectedEntities == 0 ) then
        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/compressors_resources_tools/replace_all_decompressors")
        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end

function compressors_resources_replacer_all_tool:OnGuiPopupResultEvent( evt)

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        for entity in Iter( self.selectedEntities ) do

            if ( EntityService:IsAlive( entity ) ) then

                if ( is_server and is_client ) then

                    local item = ItemService:GetFirstItemForBlueprint( entity, self.SelectedItemBlueprint )

                    if item == INVALID_ID then

                        item = ItemService:AddItemToInventory( entity, self.SelectedItemBlueprint )
                    end

                    ItemService:EquipItemInSlot( entity, item, "MOD_1" )

                else

                    local mapperName = "CultivatorResourceToolsReplaceRequest|" .. self.SelectedItemBlueprint

                    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
                end

                BuildingService:BlinkBuilding(entity)
            end
        end
    end

    self.popupShown = false
end

function compressors_resources_replacer_all_tool:ChangeSelector(modItemBlueprintName)

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

    self.SelectedItemBlueprint = modItemBlueprintName

    self.modeValuesArray = self:FillLastResourcesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()

    return true
end

function compressors_resources_replacer_all_tool:FillLastResourcesList(defaultModesArray, modeSelectLast, selector)

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

function compressors_resources_replacer_all_tool:GetCurrentList(parameterName, selectorDB)

    local currentListString = self:GetCurrentListString(parameterName, selectorDB)

    local currentListArray = Split( currentListString, "|" )

    return currentListArray
end

function compressors_resources_replacer_all_tool:GetCurrentListString(parameterName, selectorDB)

    local currentList = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        currentList = selectorDB:GetStringOrDefault( parameterName, "" ) or ""
    end

    return currentList
end

function compressors_resources_replacer_all_tool:AddResourceToLastList(selectedBlueprintName, selectorDB)

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

function compressors_resources_replacer_all_tool:OnRotateSelectorRequest(evt)

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

function compressors_resources_replacer_all_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

return compressors_resources_replacer_all_tool
 