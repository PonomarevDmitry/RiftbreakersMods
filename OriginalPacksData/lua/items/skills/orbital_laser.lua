local item = require("lua/items/item.lua")

class 'orbital_laser' ( item )

function orbital_laser:__init()
	item.__init(self,self)
end

function orbital_laser:OnInit()
    self:Prepare()
end

function orbital_laser:OnLoad()
	item.OnLoad( self )
    self:Prepare()
end

function orbital_laser:Prepare()
    self.bp = self.data:GetString( "bp" )
    self.crosshairBp = self.data:GetStringOrDefault( "crosshair_bp", "" )
    self.delay = self.data:GetFloatOrDefault( "delay", 0.5 )
    if self.fsm == nil then
	    self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "laser", { from="*", enter="OnBombardmentEnter", exit="OnBombardmentExit"} )
	end
end

function orbital_laser:OnBombardmentEnter( state )
	local pos = PlayerService:GetWeaponLookPoint( self.owner )
	if self.crosshairBp ~= "" then
		self.crosshair = EntityService:SpawnEntity( self.crosshairBp, pos, EntityService:GetTeam( self.owner ) )
	end
	pos.y = 50
	self.laser = EntityService:SpawnEntity( self.bp, pos, EntityService:GetTeam( self.owner ) )
	EntityService:SetForward( self.laser, 0, -1, 0 )
	local dir = PlayerService:GetAimDir( self.owner )
	MoveService:MoveInDirection( self.laser, 5, 5, 5, dir )
	state:SetDurationLimit( self.delay )
end

function orbital_laser:OnBombardmentExit()
	WeaponService:UpdateWeaponStatComponent( self.laser, self.laser )
	WeaponService:StartShoot( self.laser )
end

function orbital_laser:OnEquipped()

end

function orbital_laser:OnActivate()		
	self.fsm:ChangeState("laser")
end

function orbital_laser:OnDeactivate()
	return true
end

return orbital_laser