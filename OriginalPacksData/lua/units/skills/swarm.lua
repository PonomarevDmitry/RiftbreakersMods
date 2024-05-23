local swarm = require("lua/units/ground/canceroth.lua")
class 'skill_swarm' ( swarm )

function skill_swarm:__init()
	swarm.__init(self, self)
end

function skill_swarm:__OnInit()
	self:RegisterHandler( self.entity, "UnitDeadStateEvent",  "OnUnitDeadStateEvent" )
	self:RegisterHandler( self.entity, "UnitAggressiveStateEvent",  "OnUnitAggressiveStateEvent" )
	self:RegisterHandler( self.entity, "UnitNotAggressiveStateEvent",  "OnUnitNotAggressiveStateEvent" )

end

function skill_swarm:__OnDestroyRequest()
	EntityService:RemoveEntity( self.entity )
end

function skill_swarm:SetChildSpeed()
	self.childSpeed = UnitService:GetMaxSpeed( EntityService:GetParent( self.entity ) )
	self.childSpeed = self.childSpeed + ( self.childSpeed * 1.2 )
end

function skill_swarm:OnUnitAggressiveStateEvent( evt )
	self:SetChildSpeed()
end

function skill_swarm:OnUnitNotAggressiveStateEvent( evt )
	self:SetChildSpeed()
end

function skill_swarm:_CreateChild( entity )
	local keepHighNavigationComponent = reflection_helper( EntityService:GetComponent( entity, "KeepHighNavigationComponent" ) )
	keepHighNavigationComponent.interpolation_speed = keepHighNavigationComponent.interpolation_speed * self.childSpeed / 5
end

function skill_swarm:OnUnitDeadStateEvent( evt )
	QueueEvent( "DestroyRequest",self.entity, "default", 100 )	
end

return skill_swarm