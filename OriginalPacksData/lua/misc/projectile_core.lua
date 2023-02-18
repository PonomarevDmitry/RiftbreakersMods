class 'projectile_core' ( LuaEntityObject )

function projectile_core:__init()
	LuaEntityObject.__init(self,self)
end

function projectile_core:init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "spiral", { from="*", enter="OnCoreEnter", execute="OnCoreExecute", exit="OnCoreExit" } )
	self.sm:ChangeState( "spiral" )
end

function projectile_core:OnCoreEnter( state )
	state:SetDurationLimit( 0.33 )
end

function projectile_core:OnCoreExecute( state )
	local currentProgress = ( 1.0 - state:GetDuration() / 0.33 )
	currentProgress = currentProgress * currentProgress
	local scale = EntityService:GetScale( self.entity )
	EntityService:SetScale( self.entity, scale.x, currentProgress, currentProgress )
end

function projectile_core:OnCoreExit( state )
	EntityService:RemoveEntity( self.entity )
end

return projectile_core
 