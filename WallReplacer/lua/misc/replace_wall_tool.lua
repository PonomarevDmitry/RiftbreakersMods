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
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_upgrade", self.entity)
    self.popupShown = false

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.wallBluprintsArray = {}
    self.allWallBluprintsArray = {}

    local wallBlueprint = self.data:GetStringOrDefault("wallBlueprint", "")
    wallBlueprint = wallBlueprint or ""

    LogService:Log( "OnInit wallBlueprint " .. wallBlueprint )

    if ( wallBlueprint ~= "" ) then

        self:FillAllBlueprints( wallBlueprint )
    end

    self:SetMaxLevel()

    LogService:Log( "OnInit self.wallBlueprint " .. tostring(self.wallBlueprint) )

    for i=1,#self.wallBluprintsArray do
        LogService:Log( "OnInit wallBluprintsArray " .. tostring(i) .. " " .. self.wallBluprintsArray[i] )
    end

    for i=1,#self.allWallBluprintsArray do

        local blueprintName = self.allWallBluprintsArray[i]

        LogService:Log( "OnInit allWallBluprintsArray " .. tostring(i) .. " " .. blueprintName )

        --local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        --local buildingRef = reflection_helper(buildingDesc)
        --LogService:Log( "OnInit allWallBluprintsArray " .. tostring(i) .. " " .. blueprintName .. " " .. tostring(buildingRef) )
    end
end

function replace_wall_tool:SetMaxLevel()

    self.wallBlueprint = nil

    for i=#self.wallBluprintsArray,1,-1 do
        local blueprintName = self.wallBluprintsArray[i]

        if ( BuildingService:IsBuildingAvailable( blueprintName ) ) then
            self.wallBlueprint = blueprintName
            return
        end
    end
end

function replace_wall_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    if ( IndexOf( self.wallBluprintsArray, blueprintName ) == nil ) then
        Insert( self.wallBluprintsArray, blueprintName )
    end

    if ( IndexOf( self.allWallBluprintsArray, blueprintName ) == nil ) then
        Insert( self.allWallBluprintsArray, blueprintName )
    end

    local buildingRef = reflection_helper(buildingDesc)

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

function replace_wall_tool:AddedToSelection( entity )
end

function replace_wall_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function replace_wall_tool:OnUpdate()

    self.buildCost = {}

    for entity in Iter( self.selectedEntities ) do

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
        end

        local list = BuildingService:GetBuildCosts( self.wallBlueprint, self.playerId )
        for resourceCost in Iter(list) do
            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first ] = 0
            end

            self.buildCost[resourceCost.first ] = self.buildCost[resourceCost.first ] + resourceCost.second
        end

        local list = BuildingService:GetSellResourceAmount( entity )
        for resourceCost in Iter(list) do
            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first ] = 0 
            end

            self.buildCost[resourceCost.first ] = self.buildCost[resourceCost.first ] - resourceCost.second 
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

function replace_wall_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( self.wallBlueprint == nil ) then
        return entities
    end

    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( IndexOf( self.allWallBluprintsArray, blueprintName ) ~= nil ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingRef = reflection_helper(buildingDesc)

        if ( buildingRef.category ~= "defense" or buildingRef.type ~= "wall" ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_wall_tool:OnActivateEntity( entity )

    if ( self.wallBlueprint == nil ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( IndexOf( self.allWallBluprintsArray, blueprintName ) ~= nil ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)

    if ( buildingRef.category ~= "defense" or buildingRef.type ~= "wall" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( entity )

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.wallBlueprint, transform, true )
end

return replace_wall_tool
 