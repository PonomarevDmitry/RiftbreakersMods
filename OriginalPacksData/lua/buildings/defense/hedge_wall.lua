local building_base = require("lua/buildings/building_base.lua")

class 'hedge_wall' ( building_base )

function hedge_wall:__init()
	building_base.__init(self,self)
end

function hedge_wall:OnInit()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent",  "OnLeftTriggerEvent" )
	self.down = false

end

function hedge_wall:OnCubeFlyStart()
    self.position = EntityService:GetPosition( self.entity )
end

function hedge_wall:OnBuildingStart()
end

function hedge_wall:OnBuildingEnd()
end

function hedge_wall:MoveDown()
	if ( self.down == false ) then
        AnimationService:StopAnim( self.entity, "move_up")
		AnimationService:StartAnim( self.entity, "move_down", false, 5 )
		EffectService:AttachEffects( self.entity, "down" )
		self.down = true
		EntityService:DisableCollisions(self.entity )

		EntityService:CreateComponent( self.entity, "PhysicsClientDisableCollisionComponent")
	end
end

function hedge_wall:DestroyWrecks() 
	-- second physics object is the moving part of the gate 
	local gateAabb = EntityService:GetPhysicsWorldAabb( self.entity, 1 );
	gateAabb.max.y = gateAabb.max.y + 4.0; 
	local wrecks = FindService:FindEntitiesByTeamInBox(  "wreck", gateAabb )
			
	for i = 1, #wrecks do		
		if ( EntityService:HasComponent( wrecks[i], "PhysicsComponent" ) ) then
			EntityService:RemoveComponent( wrecks[i], "PhysicsComponent" );
			local dissolveTime = RandFloat( 1.0, 2.0 )
			EntityService:DissolveEntity( wrecks[i], dissolveTime );
			-- EntityService:RequestDestroyPattern( wrecks[i], "" );
		end
	end		
end

function hedge_wall:MoveUp()
	if ( self.down == true ) then		
        AnimationService:StopAnim( self.entity, "move_down")
        AnimationService:StartAnim( self.entity, "move_up",false, 5 )
		EffectService:AttachEffects( self.entity, "up" )
		self:DestroyWrecks();
		self.down = false
		EntityService:EnableCollisions(self.entity )

		EntityService:RemoveComponent( self.entity, "PhysicsClientDisableCollisionComponent")

	end
end

function hedge_wall:OnEnteredTriggerEvent(evt)
	self:MoveDown()
end

function hedge_wall:OnLeftTriggerEvent(evt)
	self:MoveUp()
end

function hedge_wall:OnLoad( )
	building_base.OnLoad( self )
end
return hedge_wall
