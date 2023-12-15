local upgrade_all_map_base = require("lua/misc/upgrade_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/upgrade_all_map_tools_last_selected_blueprints_utils.lua")

class 'upgrade_all_map_picker_tool' ( upgrade_all_map_base )

function upgrade_all_map_picker_tool:__init()
    upgrade_all_map_base.__init(self,self)
end

function upgrade_all_map_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function upgrade_all_map_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function upgrade_all_map_picker_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    self.modeBuilding = 0
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:SetBuildingIcon()

    -- List of buildings highlighted for upgrade
    self.previousMarkedBuildings = {}
    -- Radius from player to highlight buildings for upgrade
    self.radiusShowBuildingsToUpgrade = 100.0

    self.currentTick = 0
    self.tickMod = 5
end

function upgrade_all_map_picker_tool:SetBuildingIcon()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local indexBuilding = self.selectedMode - self.modeBuildingLastSelected

        local buildingNumber = #self.lastSelectedBuildingsArray - indexBuilding

        local buildingBlueprint = self.lastSelectedBuildingsArray[buildingNumber]

        self.lastSelectedBuilding = buildingBlueprint

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/upgrade_all_map/last_building}: " .. tostring(indexBuilding + 1) .. ": ${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/upgrade_all_map/current_building} ${" .. buildingDescRef.localization_id .. "}"
        end
    end

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("building_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)
    markerDB:SetString("message_text", messageText)
end

function upgrade_all_map_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function upgrade_all_map_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function upgrade_all_map_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function upgrade_all_map_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( self.selectedMode ~= self.modeBuilding ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( self:IsBlueprintInList(blueprintName) ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        if ( buildingDescRef.limit_name == "hq" ) then
            goto continue
        end

        if ( not self:IsUpgradable(buildingDescRef) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function upgrade_all_map_picker_tool:OnUpdate()

    self:HighlightBuildingsToUpgrade()
end

function upgrade_all_map_picker_tool:IsUpgradable(buildingDescRef)

    if ( buildingDescRef.level > 1 ) then
        return true
    end

    if ( buildingDescRef.upgrade ~= nil and buildingDescRef.upgrade ~= "" ) then
        return true
    end

    return false
end

function upgrade_all_map_picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        if ( self:ChangeSelector(self.lastSelectedBuilding) ) then

            return
        end
        
        return
    end

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

        if ( self:ChangeSelector(blueprintName) ) then

            return
        end

        ::continue::
    end
end

function upgrade_all_map_picker_tool:ChangeSelector(blueprintName)

    if ( blueprintName == "" or blueprintName == nil ) then
        return false
    end

    local selectorDB = EntityService:GetDatabase( self.selector )

    selectorDB:SetString( self.template_name, blueprintName )

    self.selectedBuildingBlueprint = blueprintName

    self:InitLowUpgradeList()

    self:AddBlueprintToLastList(blueprintName, self.selector)

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:SetBuildingIcon()

    if ( self.next_tool ~= "" ) then

        local nextToolBuildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( self.next_tool ) )

        QueueEvent( "ChangeSelectorRequest", self.selector, nextToolBuildingDescRef.bp, nextToolBuildingDescRef.ghost_bp )

        local nextToolBlueprintName = nextToolBuildingDescRef.bp

        local lowName = BuildingService:FindLowUpgrade( nextToolBlueprintName )

        if ( lowName == nextToolBlueprintName ) then
            lowName = nextToolBuildingDescRef.name
        end

        BuildingService:SetBuildingLastLevel( lowName, nextToolBuildingDescRef.name )

        QueueEvent( "ChangeBuildingRequest", self.selector, lowName )
    end

    return true
end

function upgrade_all_map_picker_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

    local campaignDatabase = CampaignService:GetCampaignData()
    local selectorDB = EntityService:GetDatabase( selector )

    self.lastSelectedBuildingsArray = LastSelectedBlueprintsListUtils:GetCurrentList(self.list_name, selectorDB, campaignDatabase)

    if ( self.selectedBuildingBlueprint ~= "" and self.selectedBuildingBlueprint ~= nil and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(self.lastSelectedBuildingsArray, self.selectedBuildingBlueprint)
    end

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedBuildingsArray-1 do

        Insert(modeValuesArray, (modeBuildingLastSelected + index))
    end

    return modeValuesArray
end

function upgrade_all_map_picker_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function upgrade_all_map_picker_tool:OnRotateSelectorRequest(evt)

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

    self:SetBuildingIcon()
end

function upgrade_all_map_picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function upgrade_all_map_picker_tool:HighlightBuildingsToUpgrade()
    
    local performFind = (self.currentTick % self.tickMod) == 0

    if ( performFind ) then

        self.currentTick = 0
    end

    self.currentTick = self.currentTick + 1

    if ( not performFind ) then

        return
    end

    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = self:FindUpgradableBuildings()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    -- Remove highlighting from previous buildings
    for entity in Iter( self.previousMarkedBuildings ) do

        -- If the building is not included in the new list
        if ( IndexOf( buildings, entity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        self:RemovedFromSelection( entity )

        ::continue::
    end

    for entity in Iter( buildings ) do

        -- Highlight building if it can be upgraded
        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
        end
    end

    self.previousMarkedBuildings = buildings
end

function upgrade_all_map_picker_tool:FindUpgradableBuildings()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    -- Buildings within a radius radiusShowBuildingsToUpgrade from player to highlight
    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildingsToUpgrade )

    local result = {}

    for entity in Iter( buildings ) do

        -- Skip buildins from result
        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        -- Skip buildins from self.selectedEntities
        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        -- Highlight building if it can be upgraded
        if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function upgrade_all_map_picker_tool:OnRelease()

    -- Remove highlighting from buildings
    if ( self.previousMarkedBuildings ~= nil ) then
        for ent in Iter( self.previousMarkedBuildings ) do

            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( upgrade_all_map_base.OnRelease ) then
        upgrade_all_map_base.OnRelease(self)
    end
end

return upgrade_all_map_picker_tool
 