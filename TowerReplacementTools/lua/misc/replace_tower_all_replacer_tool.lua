local replace_tower_base = require("lua/misc/replace_tower_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_tower_all_replacer_tool' ( replace_tower_base )

function replace_tower_all_replacer_tool:__init()
    replace_tower_base.__init(self,self)
end

function replace_tower_all_replacer_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function replace_tower_all_replacer_tool:OnInit()

    self.marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(self.marker_name, self.entity)

    self.popupShown = false

    self.missing_localization = self.data:GetStringOrDefault("missing_localization", "") or ""

    self.buildingDescHash = {}
    self.wallBluprintsArray = {}
    self.wallBluprintsResearch = {}
    self.cacheBuildCosts = {}

    self.template_name = self.data:GetStringOrDefault("template_name", "") or ""
    self.template_grid = self.data:GetStringOrDefault("template_grid", "") or ""

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""
    self.selectedBuildingGridSize = selectorDB:GetIntOrDefault(self.template_grid, 1) or 1

    self.selectedBlueprints = {}

    self.cacheBlueprintsLowNames = {}

    self:InitBlueprintList(self.selectedBuildingBlueprint, self.selectedBlueprints, self.cacheBlueprintsLowNames)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local blueprintName = self:GetFirstLevelBuilding(self.selectedBuildingBlueprint)

        self:FillAllBlueprints(blueprintName)
        self:FillResearches()
    end

    self:SetBuildingIcon()
end

function replace_tower_all_replacer_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)

    if ( IndexOf( self.wallBluprintsArray, blueprintName ) == nil ) then
        Insert( self.wallBluprintsArray, blueprintName )

        self.buildingDescHash[buildingRef.bp] = buildingRef
    end

    if ( buildingRef.upgrade ~= "" and buildingRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingRef.upgrade )
    end
end

function replace_tower_all_replacer_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.wallBluprintsArray do

        local blueprintName = self.wallBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.wallBluprintsResearch[blueprintName] = researchName
    end
end

function replace_tower_all_replacer_tool:GetResearchForUpgrade( researchComponent, blueprintName )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function replace_tower_all_replacer_tool:SetBuildingIcon()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("tower_icon_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("tower_name", buildingDescRef.localization_id)

            markerDB:SetString("tower_icon", menuIcon)
        else

            markerDB:SetString("tower_name", self.missing_localization)

            markerDB:SetString("tower_icon", "gui/menu/research/icons/missing_icon_big")
        end
    else
        markerDB:SetString("tower_name", self.missing_localization)

        markerDB:SetString("tower_icon", "gui/menu/research/icons/missing_icon_big")
    end
end

function replace_tower_all_replacer_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
    end
end

function replace_tower_all_replacer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function replace_tower_all_replacer_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( #self.wallBluprintsArray == 0 ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_tower_all_replacer_tool:IsEntityApproved( entity )

    local blueprintName = EntityService:GetBlueprintName(entity)

    if ( self:IsBlueprintInList( self.selectedBlueprints, self.cacheBlueprintsLowNames, blueprintName) ) then
        return false
    end

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local buildingRef = reflection_helper( buildingDesc )

    if ( buildingRef.type ~= "tower" ) then
        return false
    end

    local gridSize = BuildingService:GetBuildingGridSize(entity)
    if ( gridSize.x ~= self.selectedBuildingGridSize ) then
        return false
    end

    local level = buildingRef.level

    local wallBlueprint = self:GetWallBlueprintAndLevel( level )

    if ( wallBlueprint == "" ) then
        return false
    end

    return true
end

function replace_tower_all_replacer_tool:OnUpdate()

    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingRef = reflection_helper(buildingDesc)



        local list1 = self:GetBuildCosts( buildingRef.level )
        for resourceName, amount in pairs( list1 ) do

            if ( costValues[resourceName] == nil ) then

                Insert( costResourceList, resourceName )

                costValues[resourceName] = 0
            end

            costValues[resourceName] = costValues[resourceName] + amount
        end

        local list2 = BuildingService:GetSellResourceAmount( entity )
        for resourceCost in Iter(list2) do

            if ( costValues[resourceCost.first] == nil ) then

                Insert( costResourceList, resourceCost.first )

                costValues[resourceCost.first] = 0
            end

            costValues[resourceCost.first] = costValues[resourceCost.first] - resourceCost.second
        end

        ::continue::
    end


    self.buildCost = {}

    for resourceName in Iter(costResourceList) do

        local resourceValue = costValues[resourceName]

        if ( resourceValue ~= 0 ) then

            self.buildCost[resourceName] = resourceValue
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
        BuildingService:OperateBuildCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateBuildCosts( self.infoChild , self.playerId, {} )
        BuildingService:OperateBuildCosts( self.corners, self.playerId, self.buildCost )
    end
end

function replace_tower_all_replacer_tool:OnActivateEntity( entity )

    if ( #self.wallBluprintsArray == 0 ) then
        return
    end

    if ( not self:IsEntityApproved(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingRef = reflection_helper(buildingDesc)

    local wallBlueprint = self:GetWallBlueprintAndLevel( buildingRef.level )
    if ( wallBlueprint == "" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( entity )

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, wallBlueprint, transform, true )
end

function replace_tower_all_replacer_tool:GetWallBlueprintAndLevel( level )

    local minNumber = math.min( level, #self.wallBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.wallBluprintsArray[i]

        if ( self:IsWallBlueprintAvailable( blueprintName ) ) then

            return blueprintName
        end
    end

    return ""
end

function replace_tower_all_replacer_tool:IsWallBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( blueprintName ) ) then
        return true
    end

    local researchName = self.wallBluprintsResearch[blueprintName] or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function replace_tower_all_replacer_tool:GetBuildCosts( level )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[level] ~= nil ) then

        return self.cacheBuildCosts[level]
    end

    local result = self:CalculateBuildCosts( level )

    self.cacheBuildCosts[level] = result

    return result
end

function replace_tower_all_replacer_tool:CalculateBuildCosts( level )

    local blueprintName = self.wallBluprintsArray[level]

    local costValues = {}

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( costValues[resourceCost.first] == nil ) then
            costValues[resourceCost.first] = 0
        end

        costValues[resourceCost.first] = costValues[resourceCost.first] + resourceCost.second
    end

    return costValues
end

return replace_tower_all_replacer_tool