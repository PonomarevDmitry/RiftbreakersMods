local building_base = require("lua/buildings/building_base.lua")

class 'wall_gate' ( building_base )

function wall_gate:__init()
	building_base.__init(self,self)
end

function wall_gate:OnInit()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent",  "OnLeftTriggerEvent" )
	self.down = false

	self:FindCollisionChild()
end

function wall_gate:FindCollisionChild( )
	local childreen = EntityService:GetChildren(self.entity, true)
	for ent in Iter(childreen ) do
		if (EntityService:GetComponent( ent, "PhysicsComponent") ~= nil ) then
			self.gateChild = ent
			break
		end
	end
end

function wall_gate:OnCubeFlyStart()
	self:MoveDown()
end

function wall_gate:OnBuildingStart()
end

function wall_gate:OnBuildingEnd()
	self:MoveUp()
end

function wall_gate:MoveDown()
	if ( self.down == false ) then
		AnimationService:StartAnim( self.entity, "move_down", false, 5 )
		EffectService:AttachEffects( self.entity, "down" )
		self.down = true
		EntityService:DisableCollisions(self.gateChild )
	end
end

function wall_gate:DestroyWrecks() 
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

function wall_gate:MoveUp()
	if ( self.down == true ) then		
		AnimationService:StartAnim( self.entity, "move_up",false, 5 )
		EffectService:AttachEffects( self.entity, "up" )
		self:DestroyWrecks();
		self.down = false
		EntityService:EnableCollisions(self.gateChild )

	end
end

function wall_gate:OnEnteredTriggerEvent(evt)
	self:MoveDown()
end

function wall_gate:OnLeftTriggerEvent(evt)
	self:MoveUp()
end

function wall_gate:OnLoad( )
	building_base.OnLoad( self )
	
	if ( self.gateChild == nil ) then
		self:FindCollisionChild()
	end
	-- body
end
return wall_gate
