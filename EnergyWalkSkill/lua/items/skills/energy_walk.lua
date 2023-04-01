local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'energy_walk' ( item )

function energy_walk:__init()
    item.__init(self,self)
end

function energy_walk:OnInit()

    item.OnInit(self)

    self:FillInitialParams()
end

function energy_walk:OnLoad()

    item.OnLoad(self)

    self:FillInitialParams()
end

function energy_walk:FillInitialParams()
    
    self.blueprint = "buildings/energy/energy_connector"

    self.buildPosition = {}

    self.playerId = 0

    self:FindMinDistance()

    self.isWorking = self.isWorking or false
end

function energy_walk:OnEquipped()
    self:FindMinDistance()
end

function energy_walk:FindMinDistance()

    self.radius = BuildingService:FindEnergyRadius( self.blueprint )

    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max( bounds.x, bounds.z ) / 2.0
    end
end

function energy_walk:OnActivate()

    LogService:Log("OnActivate")

    self:InitStateMachine()

    self.playerId = 0

    self.isWorking = self.isWorking or false

    if ( self.isWorking ) then

        self.isWorking = false

        self.stateMachine:Deactivate()

        self.buildPosition = {}
    else

        self.isWorking = true

        self:FillConnectorsList()

        if ( #self.buildPosition == 0 ) then

            local transform = self:GetPlayerTransform()

            QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true )

            Insert( self.buildPosition, transform )
        end

        self:OnWorkExecute()

        self.stateMachine:ChangeState("working")
    end
end

function energy_walk:GetPlayerTransform()

    local player = PlayerService:GetPlayerControlledEnt( self.playerId )
    local transform = EntityService:GetWorldTransform( player )
    transform.orientation = { x=0, y=1, z=0, w=0 }

    return transform
end

function energy_walk:FillConnectorsList()

    self.buildPosition = {}

    local allEntities = FindService:FindEntitiesByName("energy_connector")

    LogService:Log("FillConnectorsList #allEntities " .. tostring(#allEntities) )

    for entity in Iter( allEntities ) do

        local spot = EntityService:GetWorldTransform( entity )

        Insert( self.buildPosition, spot )
    end
end

function energy_walk:OnUnequipped()
    if ( self.isWorking ) then

        self.isWorking = false

        self.stateMachine:Deactivate()

        self.buildPosition = {}
    end
end

function energy_walk:InitStateMachine()

    if ( self.stateMachine ~= nil ) then
        return
    end

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
end

function energy_walk:OnWorkExecute()

    if ( #self.buildPosition == 0 ) then

        return
    end

    local transform = self:GetPlayerTransform()

    local nearestSpot = self:GetNearestSpot(transform.position)

    local spots = BuildingService:FindSpotsByDistance( nearestSpot, transform, self.radius, self.blueprint )

    for spot in Iter( spots ) do
        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, spot, true )

        Insert( self.buildPosition, spot )
    end
end

function energy_walk:GetNearestSpot( playerPosition )

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

function energy_walk:GetDistance( playerPosition, position )

    local dx = math.abs(playerPosition.x - position.x)
    local dz = math.abs(playerPosition.z - position.z)

    return math.max(dx, dz)
end

return energy_walk
