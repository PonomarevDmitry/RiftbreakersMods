require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'stonkr' ( base_unit )

function stonkr:__init()
	base_unit.__init(self, self)
end

function stonkr:OnInit()
	self:RegisterHandler( self.entity, "PrepareSuecideEvent",  "OnPrepareSuecideEvent" )
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
end

function stonkr:OnPrepareSuecideEvent( evt )
	EntityService:RequestDestroyPattern( self.entity, "suicide" )
	--EffectService:AttachEffects( self.entity, "suicide_dmg" ) or SpawnEntity
end

	
return stonkr
