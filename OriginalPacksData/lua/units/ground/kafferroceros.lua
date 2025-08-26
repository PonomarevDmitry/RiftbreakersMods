require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'kafferroceros' ( base_unit )

function kafferroceros:__init()
	base_unit.__init(self, self)
end

function kafferroceros:OnInit()
	self:RegisterHandler( self.entity, "ChargeAttackPrepareEvent",  "OnChargeAttackPrepareEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackStartEvent",  "OnChargeAttackStartEvent" )
	self:RegisterHandler( self.entity, "ChargeAttackEndEvent",  "OnChargeAttackEndEvent" )
	self:RegisterHandler( self.entity, "IrritatedStartEvent",  "OnIrritatedStartEvent" )
	self:RegisterHandler( self.entity, "IrritatedEndEvent",  "OnIrritatedEndEvent" )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4
	self.disallowDeathAnim = "death_3"
end

function kafferroceros:OnChargeAttackPrepareEvent( evt )	
	local entity = evt:GetEntity()
	EffectService:AttachEffects( entity, "charge_start" )
end

function kafferroceros:OnChargeAttackStartEvent( evt )
	local entity = evt:GetEntity()
	EffectService:AttachEffects( entity, "charge" )	
end

function kafferroceros:OnChargeAttackEndEvent( evt )
	local entity = evt:GetEntity()
	EffectService:DestroyEffectsByGroup( entity, "charge" )
end

function kafferroceros:OnIrritatedStartEvent( evt )
	local entity = evt:GetEntity()
	EffectService:AttachEffect( entity, "effects/enemies_hammeroceros/angry" )	
end

function kafferroceros:OnIrritatedEndEvent( evt )
	local entity = evt:GetEntity()
	EffectService:DestroyEffectsByBlueprint( entity, "effects/enemies_hammeroceros/angry" )
end

function kafferroceros:OnDestroyRequest( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "charge" )
	EffectService:DestroyEffectsByBlueprint( self.entity, "effects/enemies_hammeroceros/angry" )
end

return kafferroceros
