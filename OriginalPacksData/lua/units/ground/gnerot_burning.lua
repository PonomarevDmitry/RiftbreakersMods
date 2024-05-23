require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'gnerot_burning' ( base_unit )

function gnerot_burning:__init()
	base_unit.__init(self, self)
end

function gnerot_burning:OnInit()
	self:RegisterHandler( self.entity, "SleepEvent",  "OnSleepEvent" )
	self:RegisterHandler( self.entity, "IncreaseAllResistanceEvent",  "OnIncreaseAllResistanceEvent" )
	self:RegisterHandler( self.entity, "RemoveAllResistanceEvent",  "OnRemoveAllResistanceEvent" )

	self.uniformFSM = self:CreateStateMachine()
	self.uniformFSM:AddState( "uniform", { execute="OnUniformExecute"} )
	self.uniformFSM:ChangeState( "uniform" )

	self.resource = INVALID_ID;
	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
	
	self.currentUniformValue = 1.0
	self.newUniformValue = 1.0
	self.uniformScaleValue = 0.4
end

function gnerot_burning:OnUniformExecute( state, dt )

	--LogService:Log( "1 OnUniformExecute - self.currentUniformValue : "  .. tostring( self.currentUniformValue ) .. " self.newUniformValue : " .. tostring( self.newUniformValue ) ) 
    
	local value = self.currentUniformValue
    value = value + ( ( self.newUniformValue - value ) * dt * self.uniformScaleValue )
	self.currentUniformValue = value
	
	--LogService:Log( "2 OnUniformExecute - self.currentUniformValue : "  .. tostring( self.currentUniformValue ) .. " self.newUniformValue : " .. tostring( self.newUniformValue ) ) 
	
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", self.currentUniformValue )
end

function gnerot_burning:OnSleepEvent( evt )
	--LogService:Log( "OnSleepEvent "  .. tostring( evt:GetEmissiveValue() ) ) 
	self.newUniformValue = evt:GetEmissiveValue()
end

function gnerot_burning:OnIncreaseAllResistanceEvent( evt )
	--LogService:Log( "gnerot_burning:OnIncreaseAllResistanceEvent" ) 
	EnvironmentService:SetWeaponAllResistances( self.entity, 0.1, "sleep" )
end

function gnerot_burning:OnRemoveAllResistanceEvent( evt )
	--LogService:Log( "gnerot_burning:OnRemoveAllResistanceEvent" ) 
	EnvironmentService:RemoveWeaponAllResistances( self.entity, "sleep" )
end

function gnerot_burning:OnDestroyRequest( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "charge" )
	EffectService:DestroyEffectsByBlueprint( self.entity, "effects/enemies_hammeroceros/angry" )
end

function gnerot_burning:OnAnimationMarkerReached( evt )
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

return gnerot_burning
