local item = require("lua/items/item.lua")

class 'teleport' ( item )

function teleport:__init()
	item.__init(self,self)
end

function teleport:OnInit()
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "marker", { from="*", execute= "OnMarkerExecute", exit="OnMarkerExit"} )
	self.marker = INVALID_ID
	self.foundPos = { false, {} }
	
	self.maxDistance = self.data:GetFloatOrDefault("distance", -1.0 )
	self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
	self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function teleport:OnTeleportAppearEnter()
	self.data:SetInt("leaving", 1)
end

function teleport:OnTeleportAppearExit()
	self.data:SetInt("leaving", 0)
end

function teleport:OnEquipped()
	self.machine:ChangeState("marker")
end

function teleport:OnActivate()
	if ( self.foundPos.first ) then
		PlayerService:TeleportPlayer( self.owner, self.foundPos.second , 0.2, 0.1, 0.2 )
	end
end

function teleport:OnMarkerExecute( state )
	local pos = PlayerService:GetWeaponLookPoint( self.owner )
	self.foundPos = PlayerService:FindPositionForTeleport( self.owner, pos, self.maxDistance )
	if ( self.foundPos.first == false and self.marker ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.marker )
		self.marker = INVALID_ID 
	elseif ( self.foundPos.first and ( self.marker == INVALID_ID or EntityService:IsAlive( self.marker ) == false ) ) then
		self.marker = EntityService:SpawnEntity("effects/mech/teleport_marker", self.foundPos.second, EntityService:GetTeam(INVALID_ID) )
	elseif ( self.foundPos.first and self.marker ~= INVALID_ID ) then
		EntityService:SetPosition( self.marker, self.foundPos.second )
		EntityService:CreateOrSetLifetime( self.marker, 2.0 / 33.0, "normal" )
		EntityService:SetVisible( self.marker, PlayerService:IsInFighterMode( self.owner ) )
	end
end

function teleport:OnMarkerExit()
	EntityService:RemoveEntity( self.marker )
	self.marker = INVALID_ID
end

function teleport:OnUnequipped()
	local state  = self.machine:GetState(self.machine:GetCurrentState())
	if( state ~= nil ) then
		state:Exit()
	end
end
return teleport
