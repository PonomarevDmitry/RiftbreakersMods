require("lua/utils/table_utils.lua")
require("lua/utils/building_utils.lua")
local building = require("lua/buildings/building.lua");

class 'quantum_gate_stabilizer' ( building )

function quantum_gate_stabilizer:__init()
	building.__init(self)
end

function quantum_gate_stabilizer:OnInit()

	self:RegisterHandler( event_sink , "PortalOpeningFinishedEvent", "OnPortalOpeningFinishedEvent" )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "idle",		{ execute="OnIdle" } )

	self.chargingSpeed = self.data:GetFloatOrDefault("charging_work_speed",  1.0)
	self.chargingEndSpeed = self.data:GetFloatOrDefault("charging_end_speed", 0.5)
	--BuildingService:DisableBuilding( self.entity )
	self.data:SetInt("is_working", 0 )
	self.glowFactor = 0.0
	self.portalActivated = false
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.0 );
	self.data:SetFloat("charging_speed", 0 )

	self.workingEffect = false
	self.portalEffect = false
end

function quantum_gate_stabilizer:OnBuildingStart()
	local portal = FindService:FindEntityByName("_rift_station_")
	EntityService:AttachEntity( self.entity, portal, "quantum_gate_stabilizer" )
	EntityService:SetPosition(self.entity, 0,0,0)
	EntityService:SetName( self.entity, "quantum_gate_stabilizer")
end

function quantum_gate_stabilizer:OnBuildingEnd()
	--BuildingService:DisableBuilding( self.entity )
	self.riftPortal = EntityService:GetParent( self.entity)
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.0 );
	self.fsm:ChangeState( "idle" )
end

function quantum_gate_stabilizer:OnIdle( state, dt )
	local portalPowered = BuildingService:IsBuildingPowered( self.riftPortal )
	local isWorking = BuildingService:IsWorking( self.riftPortal )
	local working 		= 0
	if ( portalPowered == true ) then
		working = 1
		self.glowFactor = self.glowFactor + dt
	else
		working = 0
		EffectService:DestroyEffectsByGroup(self.entity, "idle")
		EffectService:DestroyEffectsByGroup(self.entity, "portal_active")
		self.workingEffect = false
		self.portalEffect = false
		self.glowFactor = self.glowFactor - dt
	end
	self.glowFactor = math.min( 1.0, self.glowFactor )
	self.glowFactor = math.max( 0.0, self.glowFactor )

	self.data:SetInt("is_working", working )
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", self.glowFactor );

	if ( working > 0 ) then
		if ( isWorking ) then
			if ( self.portalEffect == false )  then
				EffectService:DestroyEffectsByGroup(self.entity, "idle")
				EffectService:AttachEffects( self.entity, "portal_active" )
				self.portalEffect = true
				self.workingEffect = false
			end
			if ( self.portalActivated == false ) then
				self.data:SetFloat("charging_speed",self.chargingSpeed )
			else
				self.data:SetFloat("charging_speed", self.chargingEndSpeed )
	
			end
		else
			if ( self.workingEffect == false ) then
				EffectService:AttachEffects( self.entity, "idle" )
				self.workingEffect = true
			end
			self.data:SetFloat("charging_speed", 0 )
		end
	else
		self.data:SetFloat("charging_speed", 0 )
	end

end

function quantum_gate_stabilizer:OnPortalOpeningFinishedEvent( event )
		self.portalActivated = true
end

return quantum_gate_stabilizer
