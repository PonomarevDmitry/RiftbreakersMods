local weapon = require("lua/items/weapon.lua")

class 'charge_weapon' ( weapon )

function charge_weapon:__init()
	weapon.__init(self,self)
end

function charge_weapon:OnInit()
end

function charge_weapon:OnEquipped()
	weapon.OnEquipped( self )

    self:RegisterEventsListeners( true )
end

function charge_weapon:RegisterEventsListeners(register)
    self.event_registered = register

    if register then
        self:RegisterHandler( self.item, "ShootingWeaponChargeAcquiredEvent", "_ShootingChargeLevelAcquired" )
        self:RegisterHandler( self.item, "ShootingWeaponChargeReleasedEvent", "_ShootingChargeReleased" )
    else
        self:UnregisterHandler( self.item, "ShootingWeaponChargeAcquiredEvent", "_ShootingChargeLevelAcquired" )
        self:UnregisterHandler( self.item, "ShootingWeaponChargeReleasedEvent", "_ShootingChargeReleased" )
    end
end

function charge_weapon:OnUnequipped()
	weapon.OnUnequipped( self )

    self:RegisterEventsListeners( false )
end

function charge_weapon:_ShootingChargeLevelAcquired(evt)
	self:SetPadTriggerParams("charge_acquired", 0.2)
end

function charge_weapon:_ShootingChargeReleased(evt)
	self:SetPadTriggerParams("charge_released", 0.2)
end

function charge_weapon:OnLoad()
    weapon.OnLoad(self)

    if ( not self.event_registered and self.data:GetInt( "equipped" ) == 1 ) then
        self:RegisterEventsListeners( true )
    end
end

function charge_weapon:OnActivate()
    WeaponService:StartCharge( self.item );
end

function charge_weapon:OnDeactivate()
    WeaponService:StopCharge( self.item );
	return true
end

function charge_weapon:OnShootingStart()
    weapon.OnShootingStart( self )
end

function charge_weapon:OnShootingStop()
    weapon.OnShootingStop( self )

    EffectService:AttachEffects( self.item, "shooting_end" ) 
end

return charge_weapon
