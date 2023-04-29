local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'energy_connector_trail' ( item )

function energy_connector_trail:__init()
    item.__init(self,self)
end

function energy_connector_trail:OnInit()

    item.OnInit(self)

    self:FillInitialParams()
end

function energy_connector_trail:OnLoad()

    item.OnLoad(self)

    self:FillInitialParams()
end

function energy_connector_trail:FillInitialParams()
    
    self.blueprint = "buildings/energy/energy_connector"

    self.buildPosition = {}

    self.playerId = 0

    self:FindMinDistance()

    self.isWorking = self.isWorking or false

    if ( self.iconEntity ~= nil ) then
        EntityService:RemoveEntity(self.iconEntity)
    end
end

function energy_connector_trail:OnEquipped()
    self:FindMinDistance()
end

function energy_connector_trail:FindMinDistance()

    self.radius = BuildingService:FindEnergyRadius( self.blueprint )

    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max( bounds.x, bounds.z ) / 2.0
    end
end

function energy_connector_trail:OnActivate()

    self:InitStateMachine()

    self.playerId = 0

    self.isWorking = self.isWorking or false

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        if ( self.iconEntity ~= nil ) then
            EntityService:RemoveEntity(self.iconEntity)
        end

        self.iconEntity = EntityService:SpawnAndAttachEntity("items/skills/energy_connector_trail/icon", self.owner )

        self:FillConnectorsList()

        if ( #self.buildPosition == 0 ) then

            local transform = self:GetPlayerTransform()

            self:BuildOnSpot( transform )
        end

        self:OnWorkExecute()

        self.stateMachine:ChangeState("working")
    end
end

function energy_connector_trail:GetPlayerTransform()

    local player = PlayerService:GetPlayerControlledEnt( self.playerId )
    local transform = EntityService:GetWorldTransform( player )
    transform.orientation = { x=0, y=1, z=0, w=0 }

    return transform
end

function energy_connector_trail:FillConnectorsList()

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

function energy_connector_trail:HasDistributionRadius( resourceStorageRef )

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

function energy_connector_trail:OnUnequipped()
    if ( self.isWorking ) then

        self:StopWorking()
    end
end

function energy_connector_trail:StopWorking()

    self.isWorking = false

    self.stateMachine:Deactivate()

    self.buildPosition = {}

    if ( self.iconEntity ~= nil ) then
        EntityService:RemoveEntity(self.iconEntity)
    end
end

function energy_connector_trail:OnRelease()
    if ( self.isWorking ) then

        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function energy_connector_trail:InitStateMachine()

    if ( self.stateMachine ~= nil ) then
        return
    end

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
end

function energy_connector_trail:OnWorkExecute()

    if ( #self.buildPosition == 0 ) then

        return
    end

    local transform = self:GetPlayerTransform()

    local nearestSpot = self:GetNearestSpot(transform.position)

    local spots = BuildingService:FindSpotsByDistance( nearestSpot, transform, self.radius, self.blueprint )

    for spot in Iter( spots ) do

        self:BuildOnSpot( spot )
    end
end

function energy_connector_trail:BuildOnSpot( spot )

    local antiQuickSandFloor = "buildings/decorations/floor_desert_1x1"

    if ( BuildingService:IsBuildingAvailable( antiQuickSandFloor ) and BuildingService:CanAffordBuilding( antiQuickSandFloor, self.playerId) ) then 

        local terrainType = self:GetTerrainType( spot.position )

        if ( terrainType == "quicksand" ) then

            local transformFloor = {}
            transformFloor.position = spot.position
            transformFloor.orientation = { x=0, y=0, z=0, w=1}
            transformFloor.scale = { x=1, y=1, z=1}

            QueueEvent("BuildFloorRequest", INVALID_ID, self.playerId, antiQuickSandFloor, transformFloor )
        end
    end

    if ( BuildingService:IsBuildingAvailable( self.blueprint ) and BuildingService:CanAffordBuilding( self.blueprint, self.playerId) ) then

        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, spot, true )

        Insert( self.buildPosition, spot )
    end
end

function energy_connector_trail:GetTerrainType( position )

    local tempEntity = EntityService:SpawnEntity( position )
    local terrainType = EnvironmentService:GetTerrainTypeUnderEntity( tempEntity )
    EntityService:RemoveEntity(tempEntity)

    return terrainType
end

function energy_connector_trail:GetNearestSpot( playerPosition )

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

function energy_connector_trail:GetDistance( playerPosition, position )

    local dx = math.abs(playerPosition.x - position.x)
    local dz = math.abs(playerPosition.z - position.z)

    return math.max(dx, dz)
end

return energy_connector_trail
