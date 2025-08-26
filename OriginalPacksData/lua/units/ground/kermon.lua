require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'kermon' ( base_unit )

function kermon:__init()
	base_unit.__init(self, self)
end

function kermon:OnInit()
	self:RegisterHandler( self.entity, "EnterInvisiblityEvent",  "OnEnterInvisiblityEvent" )
	self:RegisterHandler( self.entity, "ExitInvisiblityEvent",  "OnExitInvisiblityEvent" )
	
	self.uniformFSM = self:CreateStateMachine()
	self.uniformFSM:AddState( "uniform", { execute="OnUniformExecute"} )
	self.uniformFSM:ChangeState( "uniform" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 8
	self.disallowDeathAnim = "death_running_3"

    self.damageInvisibilityCooldownFSM = self:CreateStateMachine()
    self.damageInvisibilityCooldownFSM:AddState( "cooldown", { from="*", enter="OnEnterCooldown", exit= "OnExitCooldown" } )

	self.damageInvisibilityCooldown = 1.0

	self.currentUniformValue = 0.0
	self.newUniformValue = 0.0
	self.uniformScaleValue = 3

	self.shouldBeInvisible = true
	self.isInDamageInvisibilityCooldown = false
end

function kermon:OnEnterCooldown( state )

	--LogService:Log( "kermon:OnEnterCooldown" )	

    state:SetDurationLimit( self.damageInvisibilityCooldown )

    if ( self.shouldBeInvisible == true ) then
		self:InvisibilityOff()
	end

	self.isInDamageInvisibilityCooldown = true
end

function kermon:OnExitCooldown( state )

	--LogService:Log( "kermon:OnExitCooldown" )	

    if ( self.shouldBeInvisible == true ) then
		self:InvisibilityOn()
	end

	self.isInDamageInvisibilityCooldown = false
end

function kermon:InvisibilityOn()
	
	--LogService:Log( "kermon:InvisibilityOn" )	
	self.uniformScaleValue = 2
	self.newUniformValue = 1.0

	EntityService:SetMaterial( self.entity, "units/invisibility", "invisiblity" )
	EffectService:AttachEffects( self.entity, "invisibility" )
end

function kermon:InvisibilityOff()

	--LogService:Log( "kermon:InvisibilityOff" )	
	self.uniformScaleValue = 6
    self.newUniformValue = 0.0

	EntityService:RemoveMaterial( self.entity, "invisiblity" )
	EffectService:DestroyEffectsByGroup( self.entity, "invisibility" )
end

function kermon:OnEnterInvisiblityEvent( evt )

	--LogService:Log( "kermon:OnEnterInvisiblityEvent" )

	if ( self.isInDamageInvisibilityCooldown == false ) then
		self:InvisibilityOn()
	end

	self.shouldBeInvisible = true
end

function kermon:OnUniformExecute( state, dt )

	--LogService:Log( "kermon 1 OnUniformExecute - self.currentUniformValue : "  .. tostring( self.currentUniformValue ) .. " self.newUniformValue : " .. tostring( self.newUniformValue ) ) 
    
	local value = self.currentUniformValue
    value = value + ( ( self.newUniformValue - value ) * dt * self.uniformScaleValue )
	self.currentUniformValue = value
	
	if ( self.currentUniformValue < 0.01 ) then
		self.currentUniformValue = 0.0
	end

	if ( self.currentUniformValue > 0.99 ) then
		self.currentUniformValue = 1.0
	end
	--LogService:Log( "kermon 2 OnUniformExecute - self.currentUniformValue : "  .. tostring( self.currentUniformValue ) .. " self.newUniformValue : " .. tostring( self.newUniformValue ) ) 
	
	EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", self.currentUniformValue )
	EntityService:SetGraphicsUniform( self.entity, "cDistortionFactor", self.currentUniformValue )

end

function kermon:OnExitInvisiblityEvent( evt )

	--LogService:Log( "kermon:OnExitInvisiblityEvent" )
	
	self:InvisibilityOff()
	self.shouldBeInvisible = false
end

function kermon:OnDamageEvent( evt )
	self.damageInvisibilityCooldownFSM:ChangeState( "cooldown" )
end

function kermon:OnDestroyRequest( evt )
	self.data:SetFloat( "current_uniform_value", self.currentUniformValue )
	self.data:SetFloat( "new_uniform_value", 0.0 )

	self:InvisibilityOff()
end

return kermon
