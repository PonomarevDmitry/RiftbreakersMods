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
    self.delay = self.data:GetFloatOrDefault( "delay", 0.5 )
    if self.fsm == nil then
	    self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "bombardment", { from="*", enter="OnBombardmentEnter", exit="OnBombardmentExit"} )
	end
end

function orbital_bombardment:OnBombardmentEnter( state )
	local pos = PlayerService:GetWeaponLookPoint( self.owner )
	if self.crosshairBp ~= "" then
		self.crosshair = EntityService:SpawnEntity( self.crosshairBp, pos, EntityService:GetTeam( self.owner ) )
	end
	pos.y = 30
	self.bombardment = EntityService:SpawnEntity( self.bp, pos, EntityService:GetTeam( self.owner ) )
	state:SetDurationLimit( self.delay )
end

function orbital_bombardment:OnBombardmentExit()
	WeaponService:UpdateWeaponStatComponent( self.bombardment, self.bombardment )
	WeaponService:StartShoot( self.bombardment )
end

function orbital_bombardment:OnEquipped()

end

function orbital_bombardment:OnActivate()		
	self.fsm:ChangeState("bombardment")
end

function orbital_bombardment:OnDeactivate()
	return true
end

return orbital_bombardment
