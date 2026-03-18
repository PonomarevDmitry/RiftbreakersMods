require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'sell_depleted_tool_script' ( LuaEntityObject )

function sell_depleted_tool_script:__init()
    LuaEntityObject.__init(self, self)
end

function sell_depleted_tool_script:init()

    self.playerId = self.data:GetInt("player_id")

    self.targetEntity = self.data:GetInt("target_entity")

    self.buildingCount = self.data:GetInt("building_count")

    self.newBuildingBlueprintName = self.data:GetString("building_blueprintname")

    self.team = EntityService:GetTeam( self.targetEntity )

    self.transform = EntityService:GetWorldTransform( self.targetEntity )

    self.targetGridSize = BuildingService:GetBuildingGridSize(self.targetEntity)

    self.position = self.transform.position
    self.orientation = self.transform.orientation

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function sell_depleted_tool_script:OnLoad()

    if ( self.targetEntity == nil ) then
        self:DestroySelf()
        return
    end

    if ( self.targetEntity == INVALID_ID ) then
        self:DestroySelf()
        return
    end

    if ( not EntityService:IsAlive( self.targetEntity) ) then
        self:DestroySelf()
        return
    end

    if ( self.newBuildingBlueprintName == "" or self.newBuildingBlueprintName == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.newBuildingBlueprintName ) ) then
        self:DestroySelf()
        return
    end

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function sell_depleted_tool_script:OnBuildingSellEndEvent()

    if ( self.newBuildingBlueprintName == "" or self.newBuildingBlueprintName == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.newBuildingBlueprintName ) ) then
        self:DestroySelf()
        return
    end

    local sizeX = (self.targetGridSize.x - 1) / 2
    local sizeZ = (self.targetGridSize.z - 1) / 2

    local deltas = { -1, 1 }

    local hashPositions = {}

    for deltaX in Iter( deltas ) do
        for deltaZ in Iter( deltas ) do

            local newTransform = {}

            newTransform.scale = newTransform.scale
            newTransform.orientation = newTransform.orientation

            newTransform.position = {}
            newTransform.position.y = self.transform.position.y
            newTransform.position.x = self.transform.position.x + deltaX * 2 * sizeX
            newTransform.position.z = self.transform.position.z + deltaZ * 2 * sizeZ

            if ( self:AddToHash(hashPositions, newTransform.position.x, newTransform.position.z) ) then

                self:BuildDesertFloor(newTransform.position)

                QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.newBuildingBlueprintName, newTransform, false, {} )
            end
        end
    end

    self:DestroySelf()
end

function sell_depleted_tool_script:BuildDesertFloor(position)

    local antiQuickSandFloor = "buildings/decorations/floor_desert_1x1"

    if ( BuildingService:IsBuildingAvailable( self.playerId, antiQuickSandFloor ) and BuildingService:CanAffordBuilding( antiQuickSandFloor, self.playerId) ) then

        local buildDesertFloor = self:ShouldBuildDesertFloor( position )

        if ( buildDesertFloor ) then

            local transformFloor = {}
            transformFloor.position = position
            transformFloor.orientation = { x=0, y=0, z=0, w=1}
            transformFloor.scale = { x=1, y=1, z=1}

            QueueEvent("BuildFloorRequest", INVALID_ID, self.playerId, antiQuickSandFloor, transformFloor )
        end
    end
end

function sell_depleted_tool_script:ShouldBuildDesertFloor( position )

    local terrainType = ""

    local overrideTerrains = {}

    local terrainCellEntityId = EnvironmentService:GetTerrainCell(position)

    if ( terrainCellEntityId ~= nil and terrainCellEntityId ~= INVALID_ID ) then

        local terrainTypeLayerComponent = EntityService:GetComponent( terrainCellEntityId, "TerrainTypeLayerComponent" )

        if ( terrainTypeLayerComponent ~= nil ) then

            local terrainTypeLayerComponentRef = reflection_helper(terrainTypeLayerComponent)

            if ( terrainTypeLayerComponentRef.terrain_type and terrainTypeLayerComponentRef.terrain_type.resource and terrainTypeLayerComponentRef.terrain_type.resource.name ) then

                terrainType = terrainTypeLayerComponentRef.terrain_type.resource.name
            end
        end

        local overrideTerrainComponent = EntityService:GetComponent( terrainCellEntityId, "OverrideTerrainComponent" )

        if ( overrideTerrainComponent ~= nil ) then

            local overrideTerrainComponentRef = reflection_helper(overrideTerrainComponent)

            if ( overrideTerrainComponentRef.terrain_overrides ) then

                for i=1,overrideTerrainComponentRef.terrain_overrides.count do

                    local terrainTypeHolder = overrideTerrainComponentRef.terrain_overrides[i]

                    if ( terrainTypeHolder and terrainTypeHolder.resource and terrainTypeHolder.resource.name ) then

                        if ( IndexOf( overrideTerrains, terrainTypeHolder.resource.name ) == nil ) then
                            Insert( overrideTerrains, terrainTypeHolder.resource.name )
                        end
                    end
                end
            end
        end
    end

    local isQuickSand = (terrainType == "quicksand")
    local hasDesertFloor = (IndexOf( overrideTerrains, "desert_floor" ) ~= nil)

    if ( isQuickSand and not hasDesertFloor ) then

        return true
    end

    return false
end

function sell_depleted_tool_script:AddToHash(hashPositions, newPositionX, newPositionZ)

    hashPositions[newPositionX] = hashPositions[newPositionX] or {}

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] ~= nil ) then

        return false
    end

    hashXPosition[newPositionZ] = true

    return true
end

function sell_depleted_tool_script:DestroySelf()
    self.targetEntity = nil
    EntityService:RemoveEntity( self.entity )
end

return sell_depleted_tool_script