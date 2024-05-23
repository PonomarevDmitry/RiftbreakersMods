local item = require("lua/items/item.lua")

class 'orbital_bombardment' ( item )

function orbital_bombardment:__init()
	item.__init(self,self)
end

function orbital_bombardment:OnInit()
    self:Prepare()
end

function orbital_bombardment:OnLoad()
	item.OnLoad( self )
    self:Prepare()
end

function orbital_bombardment:Prepare()
    self.bp = self.data:GetString( "bp" )
    self.crosshairBp = self.data:GetStringOrDefault( "crosshair_bp", "" )
    self.crosshairRadius = self.data:GetFloatOrDefault( "crosshair_radius", 10.0 )
    self.delay = self.data:GetFloatOrDefault( "delay", 0.5 )
	self.version = 1
    if self.fsm == nil then
	    self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "bombardment", { from="*", enter="OnBombardmentEnter", exit="OnBombardmentExit" } )
		self.fsm:AddState( "shoot", { from="*", enter="OnShootEnter", exit="OnShootExit"  } )
	end
end

function orbital_bombardment:OnBombardmentEnter( state )
	self.targetPos = PlayerService:GetWeaponLookPoint( self.owner )
	if self.crosshairBp ~= "" then
		WeaponService:SpawnDangerMarker( self.crosshairBp, self.targetPos, self.crosshairRadius, self.delay )
	end

	state:SetDurationLimit( self.delay )
end

function orbital_bombardment:OnBombardmentExit( state )
	self.targetPos.y = 30
	self.bombardment = EntityService:SpawnEntity( self.bp, self.targetPos, EntityService:GetTeam( self.owner ) )
	WeaponService:UpdateWeaponStatComponent( self.bombardment, self.bombardment )
	self.fsm:ChangeState( "shoot" )
end

function orbital_bombardment:OnShootEnter( state )
	state:SetDurationLimit( 1.0 / 30.0 )
end

function orbital_bombardment:OnShootExit( state )
	WeaponService:StartShoot( self.bombardment )
end

function orbital_bombardment:OnEquipped()

end

function orbital_bombardment:OnActivate()		
	self.fsm:ChangeState( "bombardment" )
end

function orbital_bombardment:OnDeactivate()
	return true
end

return orbital_bombardment
