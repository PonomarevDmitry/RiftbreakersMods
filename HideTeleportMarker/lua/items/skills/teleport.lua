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

	self.version = 1
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

	if ( self.marker ~= nil and self.marker ~= INVALID_ID and ItemService:IsItemReference( self.marker, self.entity ) ) then
		EntityService:RemoveEntity( self.marker )
	end
	self.marker = INVALID_ID
end

function teleport:OnMarkerExit()
	if ( self.marker ~= nil and self.marker ~= INVALID_ID and ItemService:IsItemReference( self.marker, self.entity ) ) then
		EntityService:RemoveEntity( self.marker )
	end
	self.marker = INVALID_ID
end

function teleport:OnUnequipped()
	local state  = self.machine:GetState(self.machine:GetCurrentState())
	if( state ~= nil ) then
		state:Exit()
	end
end

function teleport:OnLoad()
	item.OnLoad(self)
	self.version = self.version or 0
	if ( self.version < 1 and self.marker ~= INVALID_ID ) then
		if ( EntityService:GetBlueprintName( self.marker ) ~= "effects/mech/teleport_marker" ) then
			self.marker = INVALID_ID
		end
	end

	if ( not self:ValidateEntityReference( self.marker ) ) then
		self.marker = INVALID_ID
	end
end

return teleport
