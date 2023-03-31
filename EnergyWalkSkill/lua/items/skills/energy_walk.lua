local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

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

    self.buildPosition = nil

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

        self.stateMachine:Deactivate()

        self.buildPosition = nil

        self.isWorking = false
    else

        local player = PlayerService:GetPlayerControlledEnt( self.playerId )

        local transform = EntityService:GetWorldTransform( player )
        transform.orientation = { x=0, y=0, z=0, w=1 }

        self.buildPosition = transform

        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true )

        self.isWorking = true

        self.stateMachine:ChangeState("working")
    end
end

function energy_walk:OnUnequipped()
    if ( self.isWorking ) then

        self.stateMachine:Deactivate()

        self.buildPosition = nil

        self.isWorking = false
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

    LogService:Log("OnWorkExecute")

    if ( self.buildPosition == nil ) then

        LogService:Log("OnWorkExecute self.buildPosition == nil")

        return
    end

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local transform = EntityService:GetWorldTransform( player )
    transform.orientation = { x=0, y=0, z=0, w=1 }

    local spots = BuildingService:FindSpotsByDistance( self.buildPosition, transform, self.radius, self.blueprint )

    for spot in Iter( spots ) do
        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, spot, true )
        self.buildPosition = spot
    end
end

return energy_walk
