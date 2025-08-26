require("lua/units/units_utils.lua")

class 'skiller' ( LuaEntityObject )

function skiller:__init()
	LuaEntityObject.__init(self, self)
end

function skiller:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "check_skills", { enter="OnCheckSkills" } )
	self.fsm:ChangeState( "check_skills" )
end

function skiller:OnCheckSkills( state )
	if EntityService:HasComponent( self.entity, "SkillUnitComponent" ) then
		local children = EntityService:GetChildren( self.entity, false )
		EntityService:SetTeam( self.entity, "wave_enemy" )
		
		for child in Iter( children ) do
			EntityService:SetTeam( child, "wave_enemy" )
			QueueEvent( "UnitAggressiveStateEvent", child )
		end
	end
end

function skiller:OnDestroyRequest( evt )
	if EntityService:HasComponent( self.entity, "SkillUnitComponent" ) then
		local children = EntityService:GetChildren( self.entity, false )
		for child in Iter( children ) do			
			QueueEvent( "UnitDeadStateEvent", child )
		end
	end
end


return skiller
