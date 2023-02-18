class 'projectile_spiral' ( LuaEntityObject )

function projectile_spiral:__init()
	LuaEntityObject.__init(self,self)
end

function projectile_spiral:init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "spiral", { from="*", enter="OnSpiralEnter", execute="OnSpiralExecute", exit="OnSpiralExit" } )
	self.sm:ChangeState( "spiral" )
end

function projectile_spiral:OnSpiralEnter( state )
	state:SetDurationLimit( 0.5 )

end

function projectile_spiral:OnSpiralExecute( state )
	local currentProgress = ( 1.0 - state:GetDuration() / 0.5 )
	currentProgress = currentProgress * currentProgress
	EntityService:Rotate( self.entity, 1, 0, 0, 3000 / 30 )
	EntityService:SetScale( self.entity, 1.0 , currentProgress, currentProgress )
end

function projectile_spiral:OnSpiralExit( state )
	EntityService:RemoveEntity( self.entity )
end

return projectile_spiral
 