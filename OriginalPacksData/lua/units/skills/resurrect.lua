
local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_resurrect' ( base_skill )

function skill_resurrect:__init()
	base_skill.__init(self, self)
end

function skill_resurrect:OnInit()

    self.auraEffect	= self.data:GetString( "aura_effect" )

   	self:RegisterHandler( self.entity, "ResurrectReadyEvent",  "OnResurrectReadyEvent" )
    self:RegisterHandler( self.entity, "SummonReadyEvent",  "OnSummonReadyEvent" )

    self.targetCorpsesExist = false
    self.targetSummonExist = false
	self.isResurrecting = false
    self.isSummoning = false

    self.think = self:CreateStateMachine()
    self.think:AddState( "think", { enter = "OnEnterThink", execute="OnExecuteThink" } )

    self.resurrect = self:CreateStateMachine()
    self.resurrect:AddState( "resurrect_prepare", { enter="OnEnterResurrectPrepare" } )
    self.resurrect:AddState( "resurrect_finish", { enter="OnEnterResurrectFinish",exit="OnExitResurrectFinish" } )

    self.summon = self:CreateStateMachine()
    self.summon:AddState( "summon_prepare", { enter="OnEnterSummonPrepare" } )
    self.summon:AddState( "summon_finish", { enter="OnEnterSummonFinish",exit="OnExitSummonFinish" } )

    EffectService:AttachEffects( EntityService:GetParent( self.entity ), self.auraEffect )
end

function skill_resurrect:OnResurrectReadyEvent( evt )
    QueueEvent( "ResurrectEvent", self.entity )
    self.resurrect:ChangeState( "resurrect_finish" )
end

function skill_resurrect:OnExecuteThink( state, dt )
    if ( self.isSummoning == false ) then
    	local canResurrect = UnitService:GetStateMachineParamInt( self.entity, "can_resurrect" )
	    if ( ( canResurrect == 1 ) and  ( self.targetCorpsesExist == true ) and ( self.isResurrecting == false ) ) then
		    self.isResurrecting = true
            self.resurrect:ChangeState( "resurrect_prepare" )
	    end
    end

    if ( self.isResurrecting == false ) then
	    local canSummon = UnitService:GetStateMachineParamInt( self.entity, "can_summon" )
	    if ( ( canSummon == 1 ) and  ( self.targetSummonExist == true ) and ( self.isSummoning == false ) ) then
		    self.isSummoning = true
            self.summon:ChangeState( "summon_prepare" )
	    end
    end
end

function skill_resurrect:OnEnterThink( state )
    self.isResurrecting = false
    self.isSummoning = false
end

function skill_resurrect:OnEnterResurrectPrepare( state )
    QueueEvent( "PrepareResurrectEvent", self.entity, "corpses" )
end

function skill_resurrect:OnEnterResurrectFinish( state )
    state:SetDurationLimit( 1 )
end

function skill_resurrect:OnExitResurrectFinish( state )
    QueueEvent( "FinishResurrectEvent", self.entity )
    self.isResurrecting = false
end

function skill_resurrect:OnSummonReadyEvent( evt )
    QueueEvent( "SummonEvent", self.entity )
    self.summon:ChangeState( "summon_finish" )
end

function skill_resurrect:OnEnterSummonPrepare( state )
    QueueEvent( "PrepareSummonEvent", self.entity, "move" )
end

function skill_resurrect:OnEnterSummonFinish( state )
    state:SetDurationLimit( 1 )
end

function skill_resurrect:OnExitSummonFinish( state )
    QueueEvent( "FinishSummonEvent", self.entity )
    self.isSummoning = false
end


function skill_resurrect:OnUnitAggressiveStateEvent( evt )
	self.think:ChangeState( "think" )
end


function skill_resurrect:OnUnitNotAggressiveStateEvent( evt )
	local state  = self.think:GetState( self.think:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end

function skill_resurrect:OnUnitDeadStateEvent( evt )
    EffectService:DestroyEffectsByGroup( EntityService:GetParent( self.entity ), self.auraEffect )
	EntityService:RemoveEntity( self.entity )
end

function skill_resurrect:TargetHasChangedEvent( evt )

    local tag = evt:GetTag()
    local target = evt:GetTarget()
    if ( tag == "corpses" ) then
        if ( target == INVALID_ID ) then
            self.targetCorpsesExist = false
        else
            self.targetCorpsesExist = true
        end
    end

    if ( self.currentTarget == INVALID_ID ) then
        self.targetSummonExist = false
    else
        self.targetSummonExist = true
    end
end

return skill_resurrect