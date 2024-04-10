local item = require("lua/items/item.lua")

class 'teleport_shockwave' ( item )

function teleport_shockwave:__init()
	item.__init(self,self)
end

function teleport_shockwave:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetStringOrDefault( "bp", "items/skills/teleport_shockwave" )
	self.att = database:GetStringOrDefault( "att", "items/skills/teleport_shockwave" )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 )
end

function teleport_shockwave:OnInit()
	
	self:FillInitialParams()
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "marker", { from="*", execute= "OnMarkerExecute", exit="OnMarkerExit"} )
	self.marker = INVALID_ID
	self.foundPos = { false, {} }
	
	self.maxDistance = self.data:GetFloatOrDefault("distance", -1.0 )
	self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
	self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )
end

function teleport_shockwave:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end

function teleport_shockwave:OnTeleportAppearEnter()
	self.data:SetInt("leaving", 1)
end

function teleport_shockwave:OnTeleportAppearExit()
	self.data:SetInt("leaving", 0)
end

function teleport_shockwave:OnEquipped()
	self.machine:ChangeState("marker")
end

function teleport_shockwave:OnActivate()
	if ( self.foundPos.first ) then
		PlayerService:TeleportPlayer( self.owner, self.foundPos.second , 0.2, 0.1, 0.2 )
	end
	
	local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
	EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
	ItemService:SetItemCreator( spawned, self.bp)
	QueueEvent( "FadeEntityInRequest", spawned, 0.5 );
end

function teleport_shockwave:OnMarkerExecute( state )
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

function teleport_shockwave:OnMarkerExit( state )
	EntityService:RemoveEntity( self.marker )
	self.marker = INVALID_ID
end

function teleport_shockwave:CanActivate()
	if ( self.checkEmptySpot == 0 ) then
		return true
	end

    local pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "")
    return pos.first
end

function teleport_shockwave:OnUnequipped()
	local state  = self.machine:GetState(self.machine:GetCurrentState())
	if( state ~= nil ) then
		state:Exit()
	end
end

return teleport_shockwave
