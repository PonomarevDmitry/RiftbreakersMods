local weapon = require("lua/items/weapon.lua")

class 'grenade_weapon' ( weapon )

local CURRENT_VERSION = 1

function grenade_weapon:__init()
	item.__init(self,self)
end

function grenade_weapon:OnInit()
	self:Init()

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "execute", { enter="OnEnter",execute="OnExecute", exit="OnExit" } )
	self.sm:AddState( "dummy", {} )

	self.aimEnt = nil
end

function grenade_weapon:OnLoad()
	self.version = self.version or 0
    weapon.OnLoad(self)

	if ( self.aimEnt ~= nil and self.version < 1 ) then
		if ( EntityService:GetBlueprintName(self.aimEnt) ~= self.aimBp) then
    	       self.aimEnt = nil
		else
			table.insert( self.references, self.aimEnt )
			ItemService:SetItemReference( self.aimEnt, self.entity, self.entity_blueprint )
		end
	end

	self.version = CURRENT_VERSION
    self:Init()

	if ( not self:ValidateEntityReference( self.aimEnt ) ) then
		self.aimEnt = nil
	end
end

function grenade_weapon:Init()
    self.bp = self.data:GetString( "bp" )
    self.aimBp = self.data:GetString( "aim_bp" )
    self.maxDistance = self.data:GetFloatOrDefault( "max_distance", 0.0 )
	self.version = CURRENT_VERSION
end

function grenade_weapon:OnEnter( state )

end

function grenade_weapon:OnExecute( state )
	if ( self.aimEnt == nil or EntityService:IsAlive( self.aimEnt ) == false ) then 
		self.aimEnt = self:SpawnReferenceEntity( self.aimBp, { x=0, y=0, z=0 })
		EntityService:CreateComponent(self.aimEnt, "NetReplicationDisabledComponent")
	end

	WeaponService:UpdateGrenadeAiming( self.aimEnt, self.owner, self.item, self.maxDistance )
	EntityService:SetVisible( self.aimEnt, PlayerService:IsInFighterMode( self.owner ) )
end

function grenade_weapon:OnExit( state )

end

function grenade_weapon:OnEquipped()
	weapon.OnEquipped( self )

	if self.sm ~= nil then
		self.sm:ChangeState("execute")
	end
end

function grenade_weapon:OnActivate( activation_id )
	WeaponService:StartShoot( self.item, activation_id );
end

function grenade_weapon:OnDeactivate()
	WeaponService:StopShoot( self.item );
	return true
end

function grenade_weapon:OnUnequipped()
	weapon.OnUnequipped( self )

	if self.sm ~= nil then
		self.sm:ChangeState( "dummy" )
	end
end

function grenade_weapon:OnShootingStop()
	if is_server then
		EffectService:AttachEffects( self.item, "shooting_end" ) -- TODO Prediction?
	end
end

return grenade_weapon
