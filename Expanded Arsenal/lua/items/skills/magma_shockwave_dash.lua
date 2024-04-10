local item = require("lua/items/item.lua")

class 'magma_shockwave_dash' ( item )

function magma_shockwave_dash:__init()
	item.__init(self,self)
end

function magma_shockwave_dash:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end

function magma_shockwave_dash:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetString( "bp" )
	self.att = database:GetString( "att" )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 )
end

function magma_shockwave_dash:OnInit()
	self:FillInitialParams()
end

function magma_shockwave_dash:OnEquipped()
end

function magma_shockwave_dash:OnActivate()
	EntityService:Dash( self.owner, self.item);
	
	local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
	EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
	ItemService:SetItemCreator( spawned, self.bp)
	QueueEvent( "FadeEntityInRequest", spawned, 0.5 );
end

function magma_shockwave_dash:CanActivate()
	if ( self.checkEmptySpot == 0 ) then
		return true
	end

    local pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "")
    return pos.first
end

return magma_shockwave_dash
