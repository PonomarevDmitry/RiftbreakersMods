require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'flurian_boss_intercept' ( alien_intercept )

function flurian_boss_intercept:__init()
	alien_intercept.__init(self, self)
end

function flurian_boss_intercept:OnInit()
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )
	self:RegisterHandler( self.entity, "PrepareArtilleryEvent",  "OnPrepareArtilleryEvent" )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.projectileBp = ""

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
	
	alien_intercept.OnInit(self)
end

function flurian_boss_intercept:_OnDestroyRequest( evt )

	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end


function flurian_boss_intercept:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )
	WeaponService:UpdateGrenadeAiming( self.entity,targetOrigin.x, targetOrigin.y + 1.0, targetOrigin.z )
	WeaponService:ShootOnce( self.entity )

end

function flurian_boss_intercept:OnPrepareArtilleryEvent( evt )
	self.projectileBp = evt:GetPrepareBlueprint()
end

return flurian_boss_intercept
