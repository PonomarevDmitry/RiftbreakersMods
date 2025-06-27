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
	else
		ItemService:ResetCooldown( self.entity, 0.0 )
	end
end

function teleport:OnMarkerExecute( state )
	local pos = PlayerService:GetWeaponLookPoint( self.owner )
	self.foundPos = PlayerService:FindPositionForTeleport( self.owner, pos, self.maxDistance )
	if ( self.foundPos.first == false and self.marker ~= INVALID_ID ) then
		if ( ItemService:IsItemReference( self.marker, self.entity ) ) then
			EntityService:RemoveEntity( self.marker )
		end
		self.marker = INVALID_ID 
	elseif ( self.foundPos.first and ( self.marker == INVALID_ID or EntityService:IsAlive( self.marker ) == false ) ) then
		self.marker = EntityService:SpawnEntity("effects/mech/teleport_marker", self.foundPos.second, EntityService:GetTeam(INVALID_ID) )
		ItemService:SetItemReference( self.marker, self.entity, EntityService:GetBlueprintName( self.entity ) )
	elseif ( self.foundPos.first and self.marker ~= INVALID_ID ) then
		EntityService:SetPosition( self.marker, self.foundPos.second )
		EntityService:CreateOrSetLifetime( self.marker, 2.0 / 33.0, "normal" )
		EntityService:SetVisible( self.marker, PlayerService:IsInFighterMode( self.owner ) )
	end
end

function teleport:OnMarkerExit()
	if ( ItemService:IsItemReference( self.marker, self.entity ) ) then
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
		if ( EntityService:GetBlueprintName( self.marker ) ~= "effects/mech/teleport_marker") then
			self.marker = INVALID_ID
		end
	end

	if ( not self:ValidateEntityReference( self.marker ) ) then
		self.marker = INVALID_ID
	end
end

return teleport
