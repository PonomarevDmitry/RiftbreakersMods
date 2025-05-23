local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/building_utils.lua")

class 'ghost_building_portal_construction' ( ghost )

function ghost_building_portal_construction:__init()
    ghost.__init(self,self)
end

function ghost_building_portal_construction:FindMinDistance()
    self.radius = BuildingService:FindEnergyRadius( self.blueprint )
    if ( self.radius == nil ) then
        local bounds = EntityService:GetBoundsSize( self.entity )
        self.radius = math.max(bounds.x, bounds.z ) / 2.0
    end
end

function ghost_building_portal_construction:OnInit()
    -- action line
    self.data:SetString("action", "portal_construction")

    LogService:Log("ghost_building_portal_construction:OnInit ")

    self:FindMinDistance()
    
    self:RegisterHandler( INVALID_ID, "StartBuildingEvent", "OnBuildingStartEvent" )
    ShowBuildingDisplayRadiusAround( self.entity, self.blueprint )
end

function ghost_building_portal_construction:OnBuildingStartEvent( evt)
    local playerReferenceComponent = EntityService:GetComponent( evt:GetEntity(), "PlayerReferenceComponent")
    local owner = -1
    if (playerReferenceComponent) then
        local helper = reflection_helper(playerReferenceComponent)
        owner = helper.player_id
    end
    if ( owner ~= self.playerId or not self.activated) then
        return
    end

    ShowBuildingDisplayRadiusAround( self.entity, self.ghostBlueprint )
end


function ghost_building_portal_construction:OnUpdate()
    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform )

    if ( self.activated and self.buildPosition ~= nil ) then
        local currentPosition = EntityService:GetWorldTransform( self.entity )
        local spots = BuildingService:FindSpotsByDistance( self.buildPosition, currentPosition, self.radius, self.blueprint)
        for spot in Iter( spots ) do
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, spot, true )
            self.buildPosition = spot
        end
    end
end

function ghost_building_portal_construction:OnActivate()
    
    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable =  self:GetBuildInfo(self.entity )

    self.buildPosition = transform

    if ( self.activated  ) then
        if ( testBuildable.flag == CBF_CAN_BUILD ) then
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true )
        elseif( testBuildable.flag == CBF_OVERRIDES ) then
            for entityToSell in Iter(testBuildable.entities_to_sell) do
                QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
            end
            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, transform, true )

        elseif( testBuildable.flag == CBF_REPAIR ) then
            QueueEvent("RepairBuildingByPlayerRequest", testBuildable.entity_to_repair, self.playerId, -1 )
        end
    end
    
end

function ghost_building_portal_construction:OnDeactivate()
    self.buildPosition = nil
end

function ghost_building_portal_construction:OnRelease()
    HideBuildingDisplayRadiusAround( self.entity, self.blueprint )
end

return ghost_building_portal_construction
