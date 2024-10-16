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
    self.crosshairRadius = self.data:GetFloatOrDefault( "crosshair_radius", 10.0 )
    self.delay = self.data:GetFloatOrDefault( "delay", 0.5 )
    if self.fsm == nil then
	    self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "laser", { from="*", enter="OnBombardmentEnter", exit="OnBombardmentExit" } )
	end
end

function orbital_laser:OnBombardmentEnter( state )
	self.targetPos = PlayerService:GetWeaponLookPoint( self.owner )
	self.laserDir = PlayerService:GetAimDir( self.owner )
	if self.crosshairBp ~= "" then
		WeaponService:SpawnDangerMarker( self.crosshairBp, self.targetPos, self.crosshairRadius, self.delay )
	end

	state:SetDurationLimit( self.delay )
end

function orbital_laser:OnBombardmentExit()
	self.targetPos.y = 50
	self.laser = EntityService:SpawnEntity( self.bp, self.targetPos, EntityService:GetTeam( self.owner ) )
	EntityService:SetForward( self.laser, 0, -1, 0 )
	if self.laserDir ~= nil then
		MoveService:MoveInDirection( self.laser, 5, 5, 5, self.laserDir )
	end
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