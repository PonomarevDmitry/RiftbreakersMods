local weapon = require("lua/items/weapon.lua")

class 'grenade_weapon' ( weapon )

function grenade_weapon:__init()
	item.__init(self,self)
end

function grenade_weapon:OnInit()
    self.bp = self.data:GetString( "bp" )
    self.aimBp = self.data:GetString( "aim_bp" )
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "execute", { enter="OnEnter",execute="OnExecute", exit="OnExit" } )
	self.sm:AddState( "dummy", {} )
	self.aimEnt = nil
end

function grenade_weapon:OnEnter( state )

end

function grenade_weapon:OnExecute( state )
	if ( self.aimEnt == nil or EntityService:IsAlive( self.aimEnt ) == false ) then 
		self.aimEnt = EntityService:SpawnEntity( self.aimBp, 0, 0, 0, "" )
	end

	WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item )
	EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )
end

function grenade_weapon:OnExit( state )

end

function grenade_weapon:OnEquipped()
	weapon.OnEquipped( self )
	self.sm:ChangeState("execute")
end

function grenade_weapon:OnActivate()
	WeaponService:StartShoot( self.item );
end

function grenade_weapon:OnDeactivate()
	WeaponService:StopShoot( self.item );
	return true
end

function grenade_weapon:OnUnequipped()
	weapon.OnUnequipped( self )
	self.sm:ChangeState( "dummy" )
	if ( self.aimEnt ~= nil ) then 
		EntityService:RemoveEntity( self.aimEnt )
		self.aimEnt = nil
	end
end

function grenade_weapon:OnShootingStop()
	EffectService:AttachEffects( self.item, "shooting_end" ) 
end

return grenade_weapon
