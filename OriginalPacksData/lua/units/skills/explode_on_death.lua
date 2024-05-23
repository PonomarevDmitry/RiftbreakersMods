local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_explode_on_death' ( base_skill )

function skill_explode_on_death:__init()
	base_skill.__init(self, self)
end

function skill_explode_on_death:OnInit()
	self.prepareBp			= self.data:GetString( "prepare_bp" )
	self.explodeBp			= self.data:GetString( "explode_bp" )
	self.cooldown			= self.data:GetFloat( "cooldown" )

	self.parent = EntityService:GetParent( self.entity )

	UnitService:SetStateMachineParam( self.parent, "force_leave_body", 1 )

    self.explode = self:CreateStateMachine()
    self.explode:AddState( "explode", { enter="OnEnterExplode", exit="OnExitExplode" } )
end


function skill_explode_on_death:OnEnterExplode( state )
	state:SetDurationLimit( self.cooldown )
	EntityService:SpawnAndAttachEntity( self.prepareBp, self.parent, "att_death", "" )
end

function skill_explode_on_death:OnExitExplode( state )
	local origin = EntityService:GetPosition( self.parent, "att_death" )
	EntityService:SpawnEntity( self.explodeBp, origin.x, 0.0, origin.z, "" )
	EntityService:RequestDestroyPattern( self.parent, "wreck" )
end

function skill_explode_on_death:OnUnitDeadStateEvent( evt )
	self.explode:ChangeState( "explode" )
end

return skill_explode_on_death