local replace_trap_base = require("lua/misc/replace_trap_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_trap_replacer_all_tool' ( replace_trap_base )

function replace_trap_replacer_all_tool:__init()
    replace_trap_base.__init(self,self)
end

function replace_trap_replacer_all_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function replace_trap_replacer_all_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.missing_localization = self.data:GetStringOrDefault("missing_localization", "") or ""

    self.buildingDescHash = {}
    self.trapBluprintsArray = {}
    self.trapBluprintsResearch = {}
    self.cacheBuildCosts = {}

    self.template_name = self.data:GetStringOrDefault("template_name", "") or ""

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

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

function replace_trap_replacer_all_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)

    if ( IndexOf( self.trapBluprintsArray, blueprintName ) == nil ) then
        Insert( self.trapBluprintsArray, blueprintName )

        self.buildingDescHash[buildingRef.bp] = buildingRef
    end

    if ( buildingRef.upgrade ~= "" and buildingRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingRef.upgrade )
    end
end

function replace_trap_replacer_all_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.trapBluprintsArray do

        local blueprintName = self.trapBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.trapBluprintsResearch[blueprintName] = researchName
    end
end

function replace_trap_replacer_all_tool:GetResearchForUpgrade( researchComponent, blueprintName )

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

function replace_trap_replacer_all_tool:SetBuildingIcon()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    markerDB:SetInt("trap_icon_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("trap_name", buildingDescRef.localization_id)

            markerDB:SetString("trap_icon", menuIcon)
        else

            markerDB:SetString("trap_name", self.missing_localization)

            markerDB:SetString("trap_icon", "gui/menu/research/icons/missing_icon_big")
        end
    else
        markerDB:SetString("trap_name", self.missing_localization)

        markerDB:SetString("trap_icon", "gui/menu/research/icons/missing_icon_big")
    end
end

function replace_trap_replacer_all_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/pass" )
end

function replace_trap_replacer_all_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function replace_trap_replacer_all_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( #self.trapBluprintsArray == 0 ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_trap_replacer_all_tool:IsEntityApproved( entity )

    local blueprintName = EntityService:GetBlueprintName(entity)

    if ( self:IsBlueprintInList( self.selectedBlueprints, self.cacheBlueprintsLowNames, blueprintName) ) then
        return false
    end

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode >= BM_SELLING ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local buildingRef = reflection_helper( buildingDesc )

    if ( buildingRef.type ~= "trap" ) then
        return false
    end

    local level = buildingRef.level

    local trapBlueprintName = self:GetTrapBlueprintName( level )

    if ( trapBlueprintName == "" ) then
        return false
    end

    return true
end

function replace_trap_replacer_all_tool:OnUpdate()

    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingRef = reflection_helper(buildingDesc)

        local trapBlueprintName = self:GetTrapBlueprintName( buildingRef.level )

        local list1 = self:GetBuildCosts( trapBlueprintName )
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

function replace_trap_replacer_all_tool:OnActivateEntity( entity )

    if ( #self.trapBluprintsArray == 0 ) then
        return
    end

    if ( not self:IsEntityApproved(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingRef = reflection_helper(buildingDesc)

    local trapBlueprintName = self:GetTrapBlueprintName( buildingRef.level )
    if ( trapBlueprintName == "" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( entity )

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, trapBlueprintName, transform, true, {} )
end

function replace_trap_replacer_all_tool:GetTrapBlueprintName( level )

    local minNumber = math.min( level, #self.trapBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.trapBluprintsArray[i]

        if ( self:IsTrapBlueprintAvailable( blueprintName ) ) then

            return blueprintName
        end
    end

    return ""
end

function replace_trap_replacer_all_tool:IsTrapBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self.trapBluprintsResearch[blueprintName] or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function replace_trap_replacer_all_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_trap_replacer_all_tool:CalculateBuildCosts( blueprintName )

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

return replace_trap_replacer_all_tool