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

	local worldEffectComponent =EntityService:CreateComponent( self.entity, "WorldEffectComponent" )
    local worldEffectComponentHelper = reflection_helper( worldEffectComponent )
	worldEffectComponentHelper.type = WORLD_EFFECT_TYPE_LOCAL
	worldEffectComponentHelper.size = WORLD_EFFECT_SIZE_RADIUS;
	worldEffectComponentHelper.damage_per_sec = self.dmgPerSec
	worldEffectComponentHelper.damage_type = self.dmgType
	worldEffectComponentHelper.radius = radius
	worldEffectComponentHelper.dmg_effect = self.dmgEffect
	worldEffectComponentHelper.damage_tag = "dmg_aura_boss"
	worldEffectComponentHelper.max_health_percentage_damage_threshold = 30
	worldEffectComponentHelper.damage_threshold_entity_type_mask = EntityService:BuildType( "energy_connector" )

	EnvironmentService:SetResistance( EntityService:GetParent( self.entity ), self.dmgType, 0.1, "aura_resistance_dmg" )
	EffectService:AttachEffects( EntityService:GetParent( self.entity ), self.auraEffect )
end

function skill_aura_damage_generic:OnUnitDeadStateEvent( evt )
	EffectService:DestroyEffectsByGroup( EntityService:GetParent( self.entity ), self.auraEffect )
	EntityService:RemoveEntity( self.entity )
end


return skill_aura_damage_generic