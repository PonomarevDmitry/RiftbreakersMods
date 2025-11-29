local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_aura_heal' ( base_skill )

function skill_aura_heal:__init()
	base_skill.__init(self, self)
end

function skill_aura_heal:OnInit()

	self.healingEffect		= self.data:GetString( "healing_effect" )
	self.auraEffect			= self.data:GetString( "aura_effect" )
	self.healingRay			= self.data:GetString( "healing_ray" )
	self.minHeal			= self.data:GetFloat( "min_heal" )
	self.maxHeal			= self.data:GetFloat( "max_heal" )
	self.entityHpMax		= self.data:GetFloat( "entity_hp_max" )
	local radius			= self.data:GetFloatOrDefault( "radius", 5 )

	self:SetupScale( radius )

    self.heal = self:CreateStateMachine()
    self.heal:AddState( "heal", { execute="OnExecuteHeal" } )

	self.heal:ChangeState( "heal" )

	self.parentEntity = EntityService:GetParent( self.entity )

	table.insert( self.inTrigger, self.parentEntity )

	EffectService:AttachEffects( self.parentEntity, self.auraEffect )
end

function skill_aura_heal:RemoveEffect( entity )
	if ( EffectService:HasEffectByGroup( entity, self.healingEffect ) == true ) then
		EffectService:DestroyEffectsByGroup( entity, self.healingEffect )
	end	
end

function skill_aura_heal:OnExecuteHeal( state, dt )
	
	local parentOrigin = EntityService:GetPosition( self.parentEntity ) 

	for i = 1, #self.inTrigger do  
		local entity = self.inTrigger[i]
		
		local health = HealthService:GetHealth( entity );
		local maxHealth = HealthService:GetMaxHealth( entity );	

		if ( HealthService:IsAlive( entity ) ) then
			if ( health < maxHealth ) then
				
				local healAmount = maxHealth * self.maxHeal / self.entityHpMax
				
				--LogService:Log( "before clamp : " .. tostring( healAmount ) .. " max health : " .. tostring( maxHealth ) )

				healAmount = Clamp( healAmount, self.minHeal, self.maxHeal )

				--LogService:Log( "after clamp : " .. tostring( healAmount ) .. " max health : " .. tostring( maxHealth ) )

				health = health + healAmount  * dt
				HealthService:SetHealth( entity, math.min( health, maxHealth ) );

				if ( EffectService:HasEffectByGroup( entity, self.healingEffect ) == false ) then
					EffectService:AttachEffects( entity, self.healingEffect )
				end
				
				if ( entity ~= self.parentEntity ) then
					local entityOrigin = EntityService:GetPosition( entity )
					self:CreateHealingRay( parentOrigin, entityOrigin )
				end
			else
				self:RemoveEffect( entity )
			end
		end
		
	end
end

function skill_aura_heal:CreateHealingRay( fromOrigin, toOrigin )
	local distance = Distance( fromOrigin, toOrigin )


    local lightning = EntityService:SpawnEntity( self.healingRay, self.entity, "" )
    local component = reflection_helper( EntityService:GetComponent( lightning, "LightningDataComponent" ) )

    local container = rawget( component.lighning_vec, "__ptr" );
    local instance = nil
    if ( container:GetItemCount() == 0 ) then
        instance = reflection_helper(container:CreateItem())
    else 
        instance = reflection_helper(container:GetItem(0))
    end

    instance.start_point.x = fromOrigin.x
    instance.start_point.y = fromOrigin.y + 2.0
    instance.start_point.z = fromOrigin.z

    instance.end_point.x = toOrigin.x
    instance.end_point.y = toOrigin.y + 2.0
    instance.end_point.z = toOrigin.z

	EntityService:CreateLifeTime( lightning, RandFloat( 0.02, 0.08 ), "" )
end

function skill_aura_heal:Clean( state )
	for i = 1, #self.inTrigger do  		
		self:RemoveEffect( self.inTrigger[i] )
	end

	EffectService:DestroyEffectsByGroup( self.parentEntity, self.auraEffect )
end

function skill_aura_heal:OnUnitDeadStateEvent( evt )
	self:Clean()

	EntityService:RemoveEntity( self.entity )
end

function skill_aura_heal:OnLeftTriggerEvent( evt, entity )
	self:RemoveEffect( entity )
end

return skill_aura_heal
