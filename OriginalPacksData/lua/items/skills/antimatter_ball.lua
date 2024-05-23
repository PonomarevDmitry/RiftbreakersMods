local item = require("lua/items/item.lua")

class 'antimatter_ball' ( item )

function antimatter_ball:__init()
	item.__init(self,self)
end

function antimatter_ball:OnInit()
    self:Prepare()
end

function antimatter_ball:OnLoad()
	item.OnLoad( self )
    self:Prepare()
end

function antimatter_ball:Prepare()
    self.bp = self.data:GetString( "bp" )
    self.att = self.data:GetString( "att" )
    self.initialSpeed = self.data:GetFloat( "initial_speed" )
    self.maxSpeed = self.data:GetFloat( "max_speed" )
    self.acceleration = self.data:GetFloat( "acceleration" )
end

function antimatter_ball:OnEquipped()

end

function antimatter_ball:OnActivate()
    local pos = EntityService:GetPosition( self.owner, self.att )
	local dir = PlayerService:GetAimDir( self.owner )
	self.ball = EntityService:SpawnEntity( self.bp, pos, EntityService:GetTeam( self.owner ) )
	EntityService:PropagateEntityOwner( self.ball, self.entity )
	EntityService:SetForward( self.ball, dir.x, dir.y, dir.z )
	MoveService:MoveInDirection( self.ball, self.initialSpeed, self.maxSpeed, self.acceleration, dir )
	WeaponService:UpdateWeaponStatComponent( self.ball, self.ball )
	WeaponService:StartShoot( self.ball )
end

function antimatter_ball:OnDeactivate()
	return true
end

return antimatter_ball