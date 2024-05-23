
local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_drones' ( base_skill )

function skill_drones:__init()
	base_skill.__init(self, self)
end

function skill_drones:OnInit()
	self.canAttack = false
	self.isDead = false
end


function skill_drones:OnUnitAggressiveStateEvent( evt )
	 QueueEvent( "SwarmEnableSpawnRequest", self.entity )
	 QueueEvent( "SwarmChangeStateEvent", self.entity, 3 )

	 self.canAttack = true 
end

function skill_drones:OnUnitNotAggressiveStateEvent( evt )
	QueueEvent( "SwarmDisableSpawnRequest", self.entity )
	QueueEvent( "SwarmChangeStateEvent", self.entity, 0 )

	self.canAttack = false
end

function skill_drones:OnUnitDeadStateEvent( evt )
	self.canAttack = false
	self.isDead = true

	QueueEvent( "SwarmChangeStateEvent", self.entity, 4 )
	QueueEvent( "SwarmDisableSpawnRequest", self.entity )
end

function skill_drones:TargetHasChangedEvent( evt )
	if ( ( self.isDead == false ) and ( self.canAttack == true ) ) then
		if ( self.currentTarget ~= INVALID_ID ) then
			QueueEvent( "SwarmChangeStateEvent", self.entity, 3 )
		else
			QueueEvent( "SwarmChangeStateEvent", self.entity, 0 )
		end
	end
end

return skill_drones