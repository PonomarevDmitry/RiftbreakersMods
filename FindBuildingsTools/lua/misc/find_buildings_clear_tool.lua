local find_buildings_base = require("lua/misc/find_buildings_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'find_buildings_clear_tool' ( find_buildings_base )

function find_buildings_clear_tool:__init()
    find_buildings_base.__init(self,self)
end

function find_buildings_clear_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function find_buildings_clear_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function find_buildings_clear_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.modeAll = 0
    self.modeBuilding = 1
    self.modeBuildingGroup = 2
    self.modeBuildingCategory = 3
    self.modeBuildingLastSelected = 4

    self.modeValuesArray = { self.modeAll, self.modeBuilding, self.modeBuildingGroup, self.modeBuildingCategory }

    self:FillLastBuildingsList(self.modeValuesArray,self.modeBuildingLastSelected)

    self.selectedMode = 0

    self:UpdateMarker()
end

function find_buildings_clear_tool:UpdateMarker()

    local messageText = ""
    local markerBlueprint = ""

    local buildingIconVisible = 0
    local buildingIcon = ""

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local indexBuilding = self.selectedMode - self.modeBuildingLastSelected

        local buildingNumber = #self.lastSelectedBuildingsArray - indexBuilding

        local buildingBlueprint = self.lastSelectedBuildingsArray[buildingNumber]

        self.lastSelectedBuilding = buildingBlueprint

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        messageText = buildingDescRef.localization_id

        buildingIconVisible = 1
        buildingIcon = menuIcon

        markerBlueprint = "misc/marker_selector_find_buildings_clear_tool"

    elseif ( self.selectedMode == self.modeBuilding ) then

        messageText = "gui/hud/find_buildings/building"
        markerBlueprint = "misc/marker_selector_find_buildings_clear_tool"

    elseif ( self.selectedMode == self.modeBuildingGroup ) then

        messageText = "gui/hud/find_buildings/building_group"
        markerBlueprint = "misc/marker_selector_find_buildings_clear_tool"

    elseif ( self.selectedMode == self.modeBuildingCategory ) then

        messageText = "gui/hud/find_buildings/building_category"
        markerBlueprint = "misc/marker_selector_find_buildings_clear_category_tool"

    else

        messageText = "gui/hud/find_buildings/all"
        markerBlueprint = "misc/marker_selector_find_buildings_clear_tool"
    end

    if ( self.childEntity == nil or EntityService:GetBlueprintName(self.childEntity) ~= markerBlueprint ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    end

    local markerDB = EntityService:GetDatabase( self.childEntity )
    
    markerDB:SetInt("building_icon_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)

    markerDB:SetInt("menu_visible", 1)
    markerDB:SetString("message_text", messageText)
end

function find_buildings_clear_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function find_buildings_clear_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
    end
end

function find_buildings_clear_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function find_buildings_clear_tool:FilterSelectedEntities( selectedEntities )

    local result = {}

    if ( self.selectedMode ~= self.modeBuilding and self.selectedMode ~= self.modeBuildingGroup and self.selectedMode ~= self.modeBuildingCategory ) then
        return result
    end

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
        if ( #list == 0 ) then
            goto continue
        end

        Insert(result, entity)

        ::continue::
    end

    return result
end

function find_buildings_clear_tool:OnUpdate()

end

function find_buildings_clear_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local buildingsList = self:FindEntitiesToMark(self.lastSelectedBuilding, false)

        for building in Iter( buildingsList ) do

            self:RemoveMarkEntity(building)
        end

        return
    end

    if ( self.selectedMode == self.modeAll ) then

        local entities = FindService:FindEntitiesByBlueprint( "misc/building_marked_minimap_icon" )

        for entity in Iter( entities ) do

            EntityService:RemoveEntity( entity )
        end

        return
    end

    local isGroup = (self.selectedMode == self.modeBuildingGroup)

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if ( baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescRef = reflection_helper(buildingDesc)

        blueprintName = buildingDescRef.bp or ""

        if ( self.selectedMode == self.modeBuilding or self.selectedMode == self.modeBuildingGroup ) then

            if ( blueprintName ~= "" ) then

                local buildingsList = self:FindEntitiesToMark(blueprintName, isGroup)

                for building in Iter( buildingsList ) do

                    self:RemoveMarkEntity(building)
                end
            end
        end

        if ( self.selectedMode == self.modeBuildingCategory ) then

            if ( buildingDescRef.category ~= "" ) then

                local buildingsList = self:FindEntitiesByCategoryToMark(buildingDescRef.category)

                for building in Iter( buildingsList ) do

                    self:RemoveMarkEntity(building)
                end
            end
        end

        ::continue::
    end
end

function find_buildings_clear_tool:OnRotateSelectorRequest(evt)

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

function find_buildings_clear_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function find_buildings_clear_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( find_buildings_base.OnRelease ) then
        find_buildings_base.OnRelease(self)
    end
end

return find_buildings_clear_tool