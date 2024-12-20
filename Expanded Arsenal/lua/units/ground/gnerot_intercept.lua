require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'gnerot_intercept' ( alien_intercept )

function gnerot_intercept:__init()
	alien_intercept.__init(self, self)
end

function gnerot_intercept:OnInit()
	self:RegisterHandler( self.entity, "SleepEvent",  "OnSleepEvent" )
	self:RegisterHandler( self.entity, "IncreaseAllResistanceEvent",  "OnIncreaseAllResistanceEvent" )
	self:RegisterHandler( self.entity, "RemoveAllResistanceEvent",  "OnRemoveAllResistanceEvent" )

	self.uniformFSM = self:CreateStateMachine()
	self.uniformFSM:AddState( "uniform", { execute="OnUniformExecute"} )
	self.uniformFSM:ChangeState( "uniform" )

	self.resource = INVALID_ID;
	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.currentUniformValue = 1.0
	self.newUniformValue = 1.0
	self.uniformScaleValue = 0.4
	
	alien_intercept.OnInit(self)
end

function gnerot_intercept:OnUniformExecute( state, dt )
    
	local value = self.currentUniformValue
    value = value + ( ( self.newUniformValue - value ) * dt * self.uniformScaleValue )
	self.currentUniformValue = value
	
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", self.currentUniformValue )
end

function gnerot_intercept:OnSleepEvent( evt )
	--LogService:Log( "OnSleepEvent "  .. tostring( evt:GetEmissiveValue() ) ) 
	self.newUniformValue = evt:GetEmissiveValue()
end

function gnerot_intercept:OnIncreaseAllResistanceEvent( evt )

	EnvironmentService:SetWeaponAllResistances( self.entity, 0.1, "sleep" )
end

function gnerot_intercept:OnRemoveAllResistanceEvent( evt )
 
	EnvironmentService:RemoveWeaponAllResistances( self.entity, "sleep" )
end

function gnerot_intercept:OnDestroyRequest( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "charge" )
	EffectService:DestroyEffectsByBlueprint( self.entity, "effects/enemies_hammeroceros/angry" )
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")
end

function gnerot_intercept:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( markerName == "drill" ) then
		self.resource = UnitService:DrillResourceFromVein( "att_eat", self.entity, 4 )

		if ( self.resource ~= INVALID_ID ) then
			EntityService:RemoveComponent( self.resource, "PhysicsComponent" )
			EntityService:AttachEntity( self.resource, self.entity, "att_eat" )
		end	
	elseif ( markerName == "drill_end" ) then
		if ( self.resource ~= INVALID_ID ) then
			EntityService:DissolveEntity( self.resource, 1.5 )
			self.resource = INVALID_ID;
		end
	elseif ( markerName == "drop_resource" ) then
		if ( self.resource ~= INVALID_ID ) then
			EntityService:DetachEntity( self.resource )
			EntityService:ChangeToDynamic( self.resource, "default", "loot", 3, 400, 5.0, 0.5 )
			self.resource = INVALID_ID;
		end
	else
		return true
	end

	return false
end

return gnerot_intercept
