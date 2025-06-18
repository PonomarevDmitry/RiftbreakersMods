local replace_wall_gate_base = require("lua/misc/replace_wall_gate_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_wall_gate_replacer_all_tool' ( replace_wall_gate_base )

function replace_wall_gate_replacer_all_tool:__init()
    replace_wall_gate_base.__init(self,self)
end

function replace_wall_gate_replacer_all_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.missing_localization = self.data:GetString("missing_localization")

    self.template_name = self.data:GetString("template_name")

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.toBlueprintName = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

    self.toBlueprintsList = {}
    self.toCacheBlueprintsLowNames = {}

    self:InitBlueprintList(self.toBlueprintName, self.toBlueprintsList, self.toCacheBlueprintsLowNames)

    self.buildingDescHash = {}
    self.wallBluprintsArray = {}
    self.wallBluprintsResearch = {}
    self.cacheBuildCosts = {}

    if ( self.toBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.toBlueprintName ) ) then

        local blueprintName = self:GetFirstLevelBuilding(self.toBlueprintName)

        self:FillAllBlueprints(blueprintName)
        self:FillResearches()
    end

    self:SetBuildingIcon()
end

function replace_wall_gate_replacer_all_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper(buildingDesc)

    if ( IndexOf( self.wallBluprintsArray, blueprintName ) == nil ) then
        Insert( self.wallBluprintsArray, blueprintName )

        self.buildingDescHash[buildingDescRef.bp] = buildingDescRef
    end

    if ( buildingDescRef.upgrade ~= "" and buildingDescRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingDescRef.upgrade )
    end
end

function replace_wall_gate_replacer_all_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.wallBluprintsArray do

        local blueprintName = self.wallBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.wallBluprintsResearch[blueprintName] = researchName
    end
end

function replace_wall_gate_replacer_all_tool:GetResearchForUpgrade( researchComponent, blueprintName )

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

function replace_wall_gate_replacer_all_tool:SetBuildingIcon()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    markerDB:SetInt("wall_gate_icon_visible", 1)

    if ( self.toBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.toBlueprintName ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.toBlueprintName )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("wall_gate_name", buildingDescRef.localization_id)

            markerDB:SetString("wall_gate_icon", menuIcon)
        else

            markerDB:SetString("wall_gate_name", self.missing_localization)

            markerDB:SetString("wall_gate_icon", "gui/menu/research/icons/missing_icon_big")
        end
    else
        markerDB:SetString("wall_gate_name", self.missing_localization)

        markerDB:SetString("wall_gate_icon", "gui/menu/research/icons/missing_icon_big")
    end
end

function replace_wall_gate_replacer_all_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
    end
end

function replace_wall_gate_replacer_all_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function replace_wall_gate_replacer_all_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

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

function replace_wall_gate_replacer_all_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode >= BM_SELLING ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName(entity)

    if ( self:IsBlueprintInList( self.toBlueprintsList, self.toCacheBlueprintsLowNames, blueprintName) ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local buildingDescRef = reflection_helper( buildingDesc )

    if ( buildingDescRef.type ~= "gate" or buildingDescRef.category == "decorations" ) then
        return false
    end

    local level = buildingDescRef.level

    local gateBlueprintName = self:GetWallGateBlueprint( level )
    if ( gateBlueprintName == "" ) then
        return false
    end

    return true
end

function replace_wall_gate_replacer_all_tool:OnUpdate()

    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper(buildingDesc)

        local gateBlueprintName = self:GetWallGateBlueprint( buildingDescRef.level )



        local list1 = self:GetBuildCosts( gateBlueprintName )
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

function replace_wall_gate_replacer_all_tool:OnRotate()
end

function replace_wall_gate_replacer_all_tool:OnActivateEntity( entity )

    if ( #self.wallBluprintsArray == 0 ) then
        return
    end

    if ( not self:IsEntityApproved(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingDescRef = reflection_helper(buildingDesc)

    local gateBlueprintName = self:GetWallGateBlueprint( buildingDescRef.level )
    if ( gateBlueprintName == "" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( entity )

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, gateBlueprintName, transform, true )
end

function replace_wall_gate_replacer_all_tool:GetWallGateBlueprint( level )

    local minNumber = math.min( level, #self.wallBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.wallBluprintsArray[i]

        if ( self:IsWallBlueprintAvailable( blueprintName ) ) then

            return blueprintName
        end
    end

    return ""
end

function replace_wall_gate_replacer_all_tool:IsWallBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
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

function replace_wall_gate_replacer_all_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_wall_gate_replacer_all_tool:CalculateBuildCosts( blueprintName )

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

return replace_wall_gate_replacer_all_tool