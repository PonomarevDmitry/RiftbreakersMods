local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_raise_from_dead' ( base_skill )

function skill_raise_from_dead:__init()
	base_skill.__init(self, self)
end

function skill_raise_from_dead:OnInit()
	self.prepareBp			= self.data:GetString( "prepare_bp" )
	self.effectName			= self.data:GetString( "raise_effect_name" )
	self.cooldown			= self.data:GetFloat( "cooldown" )


	self.parent = EntityService:GetParent( self.entity )
	self.parentBp = EntityService:GetBlueprintName( self.parent )

	UnitService:SetStateMachineParam( self.parent, "force_leave_body", 1 )

    self.raise = self:CreateStateMachine()
    self.raise:AddState( "raise", { enter="OnEnterRaise", exit="OnExitRaise" } )
end


function skill_raise_from_dead:OnEnterRaise( state )
	state:SetDurationLimit( self.cooldown )
	EntityService:SpawnAndAttachEntity( self.prepareBp, self.parent, "att_death", "" )
end

function skill_raise_from_dead:OnExitRaise( state )
	local origin = EntityService:GetPosition( self.parent, "att_death" )

	local newUnit = EntityService:SpawnEntity( self.parentBp, origin.x, 0.0, origin.z, "wave_enemy" )
	UnitService:SetInitialState( newUnit, UNIT_AGGRESSIVE );

	QueueEvent( "SpawnEffectGroupRequest", newUnit, "resurrect", 0.0 );

    local children = EntityService:GetChildren( newUnit, true )
    for child in Iter( children ) do
        local bpName = EntityService:GetBlueprintName( child )

		if ( bpName == "units/skills/raise_from_dead" ) then
			UnitService:SetStateMachineParam( newUnit, "force_leave_body", 0 )
			EntityService:RemoveEntity( child )
			break
		end
    end

	EntityService:DissolveEntity( self.parent, 0.0 )

end

function skill_raise_from_dead:OnUnitDeadStateEvent( evt )
	self.raise:ChangeState( "raise" )
end

return skill_raise_from_dead