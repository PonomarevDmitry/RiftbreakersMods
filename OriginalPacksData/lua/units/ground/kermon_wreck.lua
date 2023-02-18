local wreck_ground_unit = require("lua/units/wreck_ground_unit.lua")

class 'kermon_wreck' ( wreck_ground_unit )

function kermon_wreck:__init()
	wreck_ground_unit.__init(self, self)
end

function kermon_wreck:initParams()
	--self.wreckLifetime = 600
    self.normalExplodeProbability = 2
	self.leaveBodyProbability = 10

	self.uniformFSM = self:CreateStateMachine()
	self.uniformFSM:AddState( "uniform", { execute="OnUniformExecute"} )
	self.uniformFSM:ChangeState( "uniform" )

	self.currentUniformValue = self.data:GetFloat( "current_uniform_value" )
	self.newUniformValue     = self.data:GetFloat( "new_uniform_value" )
	self.uniformScaleValue   = 8

	EntityService:RemoveMaterial( self.entity, "invisiblity" )
end



function kermon_wreck:OnUniformExecute( state, dt )

	--LogService:Log( "kermon_wreck 1 OnUniformExecute - self.currentUniformValue : "  .. tostring( self.currentUniformValue ) .. " self.newUniformValue : " .. tostring( self.newUniformValue ) ) 
    
	local value = self.currentUniformValue
    value = value + ( ( self.newUniformValue - value ) * dt * self.uniformScaleValue )
	self.currentUniformValue = value
	
	if ( self.currentUniformValue < 0.01 ) then
		self.currentUniformValue = 0.0
	end

	if ( self.currentUniformValue > 0.99 ) then
		self.currentUniformValue = 1.0
	end

	--LogService:Log( "kermon_wreck 2 OnUniformExecute - self.currentUniformValue : "  .. tostring( self.currentUniformValue ) .. " self.newUniformValue : " .. tostring( self.newUniformValue ) ) 
	
	EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", self.currentUniformValue )
end

return kermon_wreck