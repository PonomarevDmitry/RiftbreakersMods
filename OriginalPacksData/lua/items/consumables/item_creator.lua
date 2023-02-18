local item = require("lua/items/item.lua")

class 'item_creator' ( item )

function item_creator:__init()
	item.__init(self,self)
end

function item_creator:OnInit()
	self:FillInitialParams()
end

function item_creator:OnEquipped()
end

function item_creator:OnActivate()
	local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
	EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
	ItemService:SetItemCreator( spawned, self.bp)
	QueueEvent( "FadeEntityInRequest", spawned, 0.5 );
end


function item_creator:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetString( "bp" )
	self.att = database:GetString( "att" )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 )
end

function  item_creator:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end


function item_creator:CanActivate()
	if ( self.checkEmptySpot == 0 ) then
		return true
	end

    local pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "")
    return pos.first
end

return item_creator
