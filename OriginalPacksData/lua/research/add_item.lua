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
    local aquired = self.data:GetIntOrDefault("player_aquired_" .. player, 0 )
    return aquired == 1
end

function add_item:AddItemToPlayer( player )
    local itemEnt = PlayerService:AddItemToInventory( player, self.item )
    PlayerService:EquipItemInSlot( player, itemEnt, self.slot )
    self.data:SetInt("player_aquired_" .. player, 1 )
end

function add_item:OnResearchAcquired( teamId )
    local players = PlayerService:GetPlayersFromTeam( teamId )
    for player in Iter(players ) do
        if ( self:CheckPlayer( player ) == false ) then
            self:AddItemToPlayer( player )
        end 
    end

	self:RegisterHandler( event_sink, "PlayerCreatedEvent",  "OnPlayerCreatedEvent" )
end

function add_item:OnPlayerCreatedEvent( evt)
    local player = evt:GetPlayerId()
    if ( self:CheckPlayer( player ) == true ) then
        return
    end
    self:AddItemToPlayer( player )
end

return add_item