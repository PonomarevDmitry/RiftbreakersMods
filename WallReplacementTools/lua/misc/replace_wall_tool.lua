local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'replace_wall_tool' ( tool )

function replace_wall_tool:__init()
    tool.__init(self,self)
end

function replace_wall_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function replace_wall_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_replace_wall_tool", self.entity)
    self.popupShown = false

    self.buildingDescHash = {}
    self.wallBluprintsArray = {}
    self.wallBluprintsResearch = {}
    self.allWallBluprintsArray = {}
    self.cacheBuildCosts = {}

    local wallBlueprint = self.data:GetStringOrDefault("wallBlueprint", "") or ""

    self.randomRotation = 0

    if ( wallBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", wallBlueprint ) ) then

        self:FillAllBlueprints( wallBlueprint )
        self:FillResearches()

        local database = EntityService:GetBlueprintDatabase( wallBlueprint )
        if ( database and database:HasInt("random_rotation") ) then

            self.randomRotation = database:GetIntOrDefault( "random_rotation", 0 )

            if ( self.randomRotation == 1 ) then

                local vector = { x=0, y=1, z=0 }

                self.randomOrientationArray = {
                    CreateQuaternion( vector, 0 ),
                    CreateQuaternion( vector, 90 ),
                    CreateQuaternion( vector, 180 ),
                    CreateQuaternion( vector, 270 )
                }
            end
        end
    end

    self:SetWallIcon()
end

function replace_wall_tool:FillAllBlueprints( blueprintName )

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

    if ( IndexOf( self.allWallBluprintsArray, blueprintName ) == nil ) then
        Insert( self.allWallBluprintsArray, blueprintName )
    end

    for i=1,buildingRef.connect.count do

        local connectRecord = buildingRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            if ( IndexOf( self.allWallBluprintsArray, connectBlueprintName ) == nil ) then
                Insert( self.allWallBluprintsArray, connectBlueprintName )
            end
        end
    end

    if ( buildingRef.upgrade ~= "" and buildingRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingRef.upgrade )
    end
end

function replace_wall_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.wallBluprintsArray do

        local blueprintName = self.wallBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.wallBluprintsResearch[blueprintName] = researchName
    end
end

function replace_wall_tool:GetResearchForUpgrade( researchComponent, blueprintName )

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

function replace_wall_tool:SetWallIcon()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    for i=#self.wallBluprintsArray,1,-1 do

        local blueprintName = self.wallBluprintsArray[i]

        if ( self:IsWallBlueprintAvailable( blueprintName ) ) then

            local buildingRef = self.buildingDescHash[blueprintName]

            markerDB:SetString("wall_name", buildingRef.localization_id)
            markerDB:SetString("wall_icon", buildingRef.menu_icon)
            markerDB:SetInt("wall_icon_visible", 1)

            return
        end
    end

    markerDB:SetString("wall_name", "gui/hud/messages/replace_wall_tool/walls_not_available")
    markerDB:SetString("wall_icon", "")
    markerDB:SetInt("wall_icon_visible", 0)
end

function replace_wall_tool:AddedToSelection( entity )
end

function replace_wall_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function replace_wall_tool:OnUpdate()

    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        if ( IndexOf( self.allWallBluprintsArray, blueprintName ) ~= nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName == "wall_small_floor" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingRef = reflection_helper(buildingDesc)
        if ( buildingRef.type ~= "wall" or buildingRef.category == "decorations" ) then
            goto continue
        end

        local connectType = self:GetConnectType( blueprintName, buildingRef )
        --if ( connectType == -1 ) then
        --    goto continue
        --end

        local level = BuildingService:GetBuildingLevel( entity )

        local wallBlueprintName, wallBlueprintLevel = self:GetWallBlueprintAndLevel( level, connectType )

        if ( wallBlueprintName == "" ) then
            goto continue
        end



        local list1 = self:GetBuildCosts( wallBlueprintName )
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

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
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

function replace_wall_tool:GetConnectType( blueprintName, buildingRef )

    for i=1,buildingRef.connect.count do

        local connectRecord = buildingRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            if ( connectBlueprintName == blueprintName ) then
                return connectRecord.key
            end
        end
    end

    return -1
end

function replace_wall_tool:GetWallBlueprintAndLevel( level, connectType )

    local minNumber = math.min( level, #self.wallBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.wallBluprintsArray[i]

        if ( self:IsWallBlueprintAvailable( blueprintName ) ) then

            local buildingRef = self.buildingDescHash[blueprintName]

            for i=1,buildingRef.connect.count do

                local connectRecord = buildingRef.connect[i]

                if ( connectRecord.key == connectType and connectRecord.value.count > 0 ) then

                    local connectBlueprintName = connectRecord.value[1]

                    return connectBlueprintName, buildingRef.level
                end
            end

            return blueprintName, buildingRef.level
        end
    end

    return "", 0
end

function replace_wall_tool:IsWallBlueprintAvailable( blueprintName )

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

function replace_wall_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_wall_tool:CalculateBuildCosts( blueprintName )

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

function replace_wall_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( #self.wallBluprintsArray == 0 ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then 
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        if ( IndexOf( self.allWallBluprintsArray, blueprintName ) ~= nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName == "wall_small_floor" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingRef = reflection_helper(buildingDesc)
        if ( buildingRef.type ~= "wall" or buildingRef.category == "decorations" ) then
            goto continue
        end

        --local connectType = self:GetConnectType( blueprintName, buildingRef )
        --if ( connectType == -1 ) then
        --    goto continue
        --end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_wall_tool:OnActivateEntity( entity )

    if ( #self.wallBluprintsArray == 0 ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( IndexOf( self.allWallBluprintsArray, blueprintName ) ~= nil ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )
    if ( lowName == "wall_small_floor" ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)
    if ( buildingRef.type ~= "wall" or buildingRef.category == "decorations"  ) then
        return
    end

    local connectType = self:GetConnectType( blueprintName, buildingRef )
    --if ( connectType == -1 ) then
    --    return
    --end

    local level = BuildingService:GetBuildingLevel( entity )

    local wallBlueprintName, wallBlueprintLevel = self:GetWallBlueprintAndLevel( level, connectType )
    if ( wallBlueprintName == "" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( entity )

    if ( self.randomRotation == 1 ) then
        transform.orientation = self.randomOrientationArray[RandInt(1,4)]
    end

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, wallBlueprintName, transform, true )
end

return replace_wall_tool
 