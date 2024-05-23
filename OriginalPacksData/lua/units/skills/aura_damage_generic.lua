local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_aura_damage_generic' ( base_skill )

function skill_aura_damage_generic:__init()
	base_skill.__init(self, self)
end

function skill_aura_damage_generic:OnInit()

	self.dmgEffect		    = self.data:GetString( "dmg_effect" )
	self.auraEffect			= self.data:GetString( "aura_effect" )
	self.dmgType			= self.data:GetString( "dmg_type" )
	self.dmgPerSec			= self.data:GetFloat( "dmg_per_sec" )
	local radius			= self.data:GetFloat( "radius" )

	self:SetupScale( radius )

	local displayRadiusComponent = reflection_helper( EntityService:GetComponent( self.entity, "DisplayRadiusComponent" ) )
	displayRadiusComponent.max_radius = radius
	displayRadiusComponent.min_radius = radius / 1.8 -- min_radius scale hack

    self.dmg = self:CreateStateMachine()
    self.dmg:AddState( "dmg", { execute="OnExecuteDmg" } )

	self.dmg:ChangeState( "dmg" )

	EnvironmentService:SetResistance( EntityService:GetParent( self.entity ), self.dmgType, 0.1, "aura_resistance_dmg" )
	EffectService:AttachEffects( EntityService:GetParent( self.entity ), self.auraEffect )
end

function skill_aura_damage_generic:RemoveEffect( entity )
	if ( EffectService:HasEffectByGroup( entity, self.dmgEffect ) == true ) then
		EffectService:DestroyEffectsByGroup( entity, self.dmgEffect )
	end	
end

function skill_aura_damage_generic:OnExecuteDmg( state, dt )
	for i = 1, #self.inTrigger do  
		local entity = self.inTrigger[i]

		QueueEvent( "DamageWithOwnerRequest", entity, self.dmgPerSec  * dt, self.dmgType, 1, 0, self.entity, self.entity )
		
		if ( EffectService:HasEffectByGroup( self.inTrigger[i], self.dmgEffect ) == false ) then
			EffectService:AttachEffects( self.inTrigger[i], self.dmgEffect )
		end	
	end
end

function skill_aura_damage_generic:Clean( state )
	for i = 1, #self.inTrigger do  		
		if ( EffectService:HasEffectByGroup( self.inTrigger[i], self.dmgEffect ) == true ) then
			EffectService:DestroyEffectsByGroup( self.inTrigger[i], self.dmgEffect )
		end	
	end

	EffectService:DestroyEffectsByGroup( EntityService:GetParent( self.entity ), self.auraEffect )
end

function skill_aura_damage_generic:OnUnitDeadStateEvent( evt )
	self:Clean()

	EntityService:RemoveEntity( self.entity )
end

function skill_aura_damage_generic:OnEnteredTriggerEvent( evt, entity )
	if ( EffectService:HasEffectByGroup( entity, self.dmgEffect ) == false ) then
		EffectService:AttachEffects( entity, self.dmgEffect )
	end	
end

function skill_aura_damage_generic:OnLeftTriggerEvent( evt, entity )
	if ( EffectService:HasEffectByGroup( entity, self.dmgEffect ) == true ) then
		EffectService:DestroyEffectsByGroup( entity, self.dmgEffect )
	end		
end

function skill_aura_damage_generic:OnLeftTriggerEvent( evt, entity )
	self:RemoveEffect( entity )
end

return skill_aura_damage_generic