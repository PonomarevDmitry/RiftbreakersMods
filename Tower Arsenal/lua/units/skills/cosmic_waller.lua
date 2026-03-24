local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_waller' ( base_skill )

function skill_waller:__init()
	base_skill.__init(self, self)
end

function skill_waller:OnInit()
	self.wallerBp			= self.data:GetString( "waller_blueprint" )

    self.spawner = self:CreateStateMachine()
    self.spawner:AddState( "spawn", { execute="OnExecuteSpawn", interval=0.1 } )

end

function skill_waller:OnExecuteSpawn( state, dt )
	if ( ( FindService:FindEntityByBlueprint( self.wallerBp ) == INVALID_ID ) and ( self.currentTarget ~= INVALID_ID ) and ( EntityService:IsAlive( self.currentTarget ) == true ) ) then
		local targetOrigin = EntityService:GetPosition( self.currentTarget )
		local myOrigin = EntityService:GetPosition( self.entity )

		local entity = EntityService:SpawnEntity( self.wallerBp, targetOrigin.x, targetOrigin.y, targetOrigin.z, "" )

		local forward = Normalize( VectorSub( myOrigin, targetOrigin ) )
		local right= EntityService:GetRightVector( VectorSub( targetOrigin, myOrigin ) )
		local db = EntityService:GetDatabase( entity )

		db:SetVector( "forward", forward )
		db:SetVector( "right", right )
	end
end

function skill_waller:OnUnitAggressiveStateEvent( evt )
	self.spawner:ChangeState( "spawn" )
end

function skill_waller:OnUnitNotAggressiveStateEvent( evt )
	local state  = self.spawner:GetState( self.spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end

function skill_waller:OnUnitDeadStateEvent( evt )
	EntityService:RemoveEntity( self.entity )
end

return skill_waller