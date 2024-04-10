local item = require("lua/items/item.lua")

class 'item_creator_potion' ( item )

function item_creator_potion:__init()
	item.__init(self,self)
end

function item_creator_potion:OnInit()
	self:FillInitialParams()
end

function item_creator_potion:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetString( "bp" )
	self.att = database:GetString( "att" )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 )
	self.amount = database:GetFloatOrDefault( "amount",25 )
end

function item_creator_potion:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end

function item_creator_potion:OnEquipped()
end

function item_creator_potion:OnActivate()
	local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
	HealthService:AddHealthInPercentage( self.owner, self.amount );
	EffectService:SpawnEffect(self.entity, "effects/items/potion");
	EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
	ItemService:SetItemCreator( spawned, self.bp)
	QueueEvent( "FadeEntityInRequest", spawned, 0.5 );
end

function item_creator_potion:CanActivate()
	if ( self.checkEmptySpot == 0 ) then
		return true
	end

    local pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "")
    return pos.first
end

return item_creator_potion
