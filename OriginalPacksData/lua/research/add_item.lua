class 'add_item' ( LuaGraphNode )

function add_item:__init()
    LuaGraphNode.__init(self,self)
end

function add_item:init()
	self.item = self.data:GetString("blueprint" )
	self.slot = self.data:GetStringOrDefault( "slot", "" )
end

function add_item:IsReadyForResearch()
	return true
end

function add_item:CheckPlayer( player )
    local key = "player_aquired_" .. player
    local aquired = 0
    if ( self.data:HasInt(key)) then
         aquired = self.data:GetIntOrDefault(key, 0 )
    else
        if ( PlayerService:HasSimilarEquipped( player,self.item )) then
            aquired = 1
        end
    end
    return aquired == 1
end

function add_item:AddItemToPlayer( player )
    local itemEnt = PlayerService:AddItemToInventory( player, self.item )
    PlayerService:EquipItemInSlot( player, itemEnt, self.slot )
    self.data:SetInt("player_aquired_" .. player, 1 )
end

function add_item:OnResearchAcquired( )
    local players = PlayerService:GetPlayersFromTeam( self.team_id )
    for player in Iter(players ) do
        if ( self:CheckPlayer( player ) == false ) then
            self:AddItemToPlayer( player )
        end 
    end

	self:RegisterHandler( event_sink, "PlayerInitializedEvent",  "OnPlayerInitializedEvent" )
end

function add_item:Activated()
	if ( self.data:GetIntOrDefault("is_acquired", 0 ) == 1 ) then
		self:OnResearchAcquired( )
	end
end

function add_item:OnPlayerInitializedEvent( evt)
    local player = evt:GetPlayerId()
    if ( self:CheckPlayer( player ) == true ) then
        return
    end
    self:AddItemToPlayer( player )
end

return add_item