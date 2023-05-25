local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'base_lamp_trail' ( item )

function base_lamp_trail:__init()
    item.__init(self,self)
end

function base_lamp_trail:OnInit()

    if ( item.OnInit ) then
        item.OnInit(self)
    end

    self:FillInitialParams()
end

function base_lamp_trail:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end

    self:FillInitialParams()
end

function base_lamp_trail:FillInitialParams()

    self.buildPosition = self.buildPosition or {}

    self.isWorking = self.isWorking or false

    if ( self.iconEntity ~= nil ) then
        EntityService:RemoveEntity(self.iconEntity)
    end
end

function base_lamp_trail:GetLampBlueprint()

    local defaultBlueprint = "buildings/decorations/base_lamp"

    local selector = PlayerService:GetPlayerSelector(self.playerId)
    if ( selector == nil ) then
        return defaultBlueprint
    end

    local selectorDB = EntityService:GetDatabase( selector )
    if ( selectorDB == nil ) then
        return defaultBlueprint
    end

    local blueprintName = selectorDB:GetStringOrDefault("$base_lamp_trail_blueprint", defaultBlueprint)

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultBlueprint
    end

    if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return defaultBlueprint
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultBlueprint
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return defaultBlueprint
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return defaultBlueprint
    end

    return blueprintName
end

function base_lamp_trail:FindMinDistance()

    --local lowName = BuildingService:FindLowUpgrade( blueprint )

    --LogService:Log("FindMinDistance " .. blueprint .. " " .. lowName )

    local blueprintName = self:GetLampBlueprint()

    self.radius = BuildingService:FindEnergyRadius( blueprintName )

    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max( bounds.x, bounds.z ) / 2.0
    end
end

function base_lamp_trail:FillPlayerId()

    self.playerId = 0

    if ( self.owner ~= nil and self.owner ~= INVALID_ID ) then

        local playerReferenceComponent = EntityService:GetComponent( self.owner, "PlayerReferenceComponent" )
        if ( playerReferenceComponent ) then

            local helper = reflection_helper(playerReferenceComponent)

            self.playerId = helper.player_id
        end
    end
end

function base_lamp_trail:OnActivate()

    if ( self.owner == nil or self.owner == INVALID_ID ) then

        return
    end

    self:FillPlayerId()

    self:FindMinDistance()

    self:InitStateMachine()

    self.isWorking = self.isWorking or false

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        if ( self.iconEntity ~= nil ) then
            EntityService:RemoveEntity(self.iconEntity)
        end

        self.iconEntity = EntityService:SpawnAndAttachEntity( "items/skills/base_lamp_trail/icon", self.owner )

        self:FillConnectorsList()

        if ( #self.buildPosition == 0 ) then

            local blueprintName = self:GetLampBlueprint()

            local transform = self:GetPlayerTransform()

            self:BuildOnSpot( blueprintName, transform )
        end

        self:OnWorkExecute()

        self.stateMachine:ChangeState("working")
    end
end

function base_lamp_trail:GetPlayerTransform()

    local transform = EntityService:GetWorldTransform( self.owner )
    transform.orientation = { x=0, y=1, z=0, w=0 }

    return transform
end

function base_lamp_trail:FillConnectorsList()

    self.buildPosition = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        local selectableComponent = EntityService:GetComponent( entity, "SelectableComponent")
        if ( selectableComponent == nil ) then
            goto continue
        end

        local resourceStorageComponent = EntityService:GetComponent( entity, "ResourceStorageComponent")
        if ( resourceStorageComponent == nil ) then
            goto continue
        end

        local resourceStorageRef = reflection_helper( resourceStorageComponent )
        if ( not self:HasDistributionRadius( resourceStorageRef ) ) then
            goto continue
        end

        --local blueprintName = EntityService:GetBlueprintName( entity )

        --LogService:Log("FillConnectorsList blueprintName " .. blueprintName .. " " .. tostring(resourceStorageRef) )

        local transform = EntityService:GetWorldTransform( entity )

        Insert( self.buildPosition, transform )

        ::continue::
    end

    --LogService:Log("FillConnectorsList #self.buildPosition " .. tostring(#self.buildPosition) )
end

function base_lamp_trail:HasDistributionRadius( resourceStorageRef )

    if ( resourceStorageRef ~= nil and resourceStorageRef.Storages ~= nil ) then

        local count = resourceStorageRef.Storages.count

        for i=1,count do

            local storage = resourceStorageRef.Storages[i]

            if ( tostring(storage.group) == "10" and storage.distribution_radius >= 1 ) then

                return true
            end
        end
    end

    return false
end

function base_lamp_trail:OnUnequipped()
    if ( self.isWorking ) then

        self:StopWorking()
    end
end

function base_lamp_trail:StopWorking()

    self.isWorking = false

    self.stateMachine:Deactivate()

    self.buildPosition = {}

    if ( self.iconEntity ~= nil ) then
        EntityService:RemoveEntity(self.iconEntity)
    end
end

function base_lamp_trail:OnRelease()

    if ( self.isWorking ) then
        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function base_lamp_trail:InitStateMachine()

    if ( self.stateMachine ~= nil ) then
        return
    end

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
end

function base_lamp_trail:OnWorkExecute()

    if ( #self.buildPosition == 0 ) then

        return
    end

    local transform = self:GetPlayerTransform()

    local nearestSpot = self:GetNearestSpot(transform.position)

    local blueprintName = self:GetLampBlueprint()

    local spots = BuildingService:FindSpotsByDistance( nearestSpot, transform, self.radius, blueprintName )

    for spot in Iter( spots ) do

        self:BuildOnSpot( blueprintName, spot )
    end
end

function base_lamp_trail:BuildOnSpot( blueprintName, spot )

    local antiQuickSandFloor = "buildings/decorations/floor_desert_1x1"

    if ( BuildingService:IsBuildingAvailable( self.playerId, antiQuickSandFloor ) and BuildingService:CanAffordBuilding( antiQuickSandFloor, self.playerId) ) then

        local terrainType = self:GetTerrainType( spot.position )

        if ( terrainType == "quicksand" ) then

            local transformFloor = {}
            transformFloor.position = spot.position
            transformFloor.orientation = { x=0, y=0, z=0, w=1}
            transformFloor.scale = { x=1, y=1, z=1}

            QueueEvent("BuildFloorRequest", INVALID_ID, self.playerId, antiQuickSandFloor, transformFloor )
        end
    end

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) and BuildingService:CanAffordBuilding( blueprintName, self.playerId) ) then

        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, spot, true )

        Insert( self.buildPosition, spot )
    end
end

function base_lamp_trail:GetTerrainType( position )

    local tempEntity = EntityService:SpawnEntity( position )
    local terrainType = EnvironmentService:GetTerrainTypeUnderEntity( tempEntity )
    EntityService:RemoveEntity(tempEntity)

    return terrainType
end

function base_lamp_trail:GetNearestSpot( playerPosition )

    local currentSpot = nil
    local currentDistance = nil

    for spot in Iter( self.buildPosition ) do

        local distance = Distance( playerPosition, spot.position )

        if currentSpot == nil or distance < currentDistance then

            currentSpot = spot;
            currentDistance = distance

            local lineDistance = self:GetDistance( playerPosition, spot.position )

            if ( lineDistance <= self.radius ) then

                return currentSpot
            end
        end
    end

    return currentSpot
end

function base_lamp_trail:GetDistance( playerPosition, position )

    local dx = math.abs(playerPosition.x - position.x)
    local dz = math.abs(playerPosition.z - position.z)

    return math.max(dx, dz)
end

return base_lamp_trail