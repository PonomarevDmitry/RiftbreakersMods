local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_aura_resistance' ( base_skill )

function skill_aura_resistance:__init()
	base_skill.__init(self, self)
end

function skill_aura_resistance:OnInit()

	local radius		= self.data:GetFloat( "radius" )
	self.resistance		= self.data:GetFloat( "resistance")

	self:SetupScale( radius )

    self.resistanceFSM = self:CreateStateMachine()
    self.resistanceFSM:AddState( "resistance", { execute="OnExecuteResistance" } )
	self.resistanceFSM:ChangeState( "resistance" )

	local parent = EntityService:GetParent( self.entity )
	EnvironmentService:SetWeaponAllResistances( parent, self.resistance, "aura_resistance" )
	self:SetResistanceMaterial( parent )
end

function skill_aura_resistance:OnExecuteResistance( state, dt )
	for i = 1, #self.inTrigger do  
		local entity = self.inTrigger[i]	
		if ( EnvironmentService:HasWeaponAllResistances( entity, "aura_resistance" ) == false ) then
			EnvironmentService:SetWeaponAllResistances( entity, self.resistance, "aura_resistance" )
			self:SetResistanceMaterial( entity )
		end
	end
end


function skill_aura_resistance:Clean( state )
	for i = 1, #self.inTrigger do  
		local entity = self.inTrigger[i]	
		EnvironmentService:RemoveWeaponAllResistances( entity, "aura_resistance" )
		self:RemoveResistanceMaterial( entity )
	end

	local parent = EntityService:GetParent( self.entity )
	if parent ~= INVALID_ID then
		self:RemoveResistanceMaterial( parent )
	end
end

function skill_aura_resistance:OnUnitDeadStateEvent( evt )
	self:Clean()

	EntityService:RemoveEntity( self.entity )
end

function skill_aura_resistance:OnEnteredTriggerEvent( evt, entity )
	if ( EnvironmentService:HasWeaponAllResistances( entity, "aura_resistance" ) == false ) then
		EnvironmentService:SetWeaponAllResistances( entity, self.resistance, "aura_resistance" )
		self:SetResistanceMaterial( entity )
	end
end

function skill_aura_resistance:OnLeftTriggerEvent( evt, entity )
	if ( EnvironmentService:HasWeaponAllResistances( entity, "aura_resistance" ) == true ) then
		EnvironmentService:RemoveWeaponAllResistances( entity, "aura_resistance" )
		self:RemoveResistanceMaterial( entity )
	end
end

function skill_aura_resistance:SetResistanceMaterial( entity )
	if ( EntityService:IsSkinned( entity ) ) then
		EntityService:SetMaterial( entity, "highlight/resistance_skinned", "aura_resistance" )
	else
		EntityService:SetMaterial( entity, "highlight/resistance", "aura_resistance" )
	end
end

function skill_aura_resistance:RemoveResistanceMaterial( entity )
	EntityService:RemoveMaterial( entity, "aura_resistance" )
end

return skill_aura_resistance