require("lua/utils/numeric_utils.lua")

local item = require("lua/items/item.lua")
class 'player_modificator_item' ( item )

function player_modificator_item:__init()
	item.__init(self,self)
end

function player_modificator_item:OnInit()
    self.modificator = INVALID_ID
end

function player_modificator_item:AttachModificator( entity )
    local target = EntityService:SpawnAndAttachEntity( self.data:GetStringOrDefault("blueprint", "error"), entity )

    --local bounds_size = VectorDiv( EntityService:GetBoundsSize( entity ), EntityService:GetScale( entity ) )
    --EntityService:SetScale( target, bounds_size.x, bounds_size.y, bounds_size.z )

    ItemService:SetItemReference( target, self.entity, EntityService:GetBlueprintName( self.entity ))
    EntityService:PropagateEntityOwner( target, self.entity )

    return target
end

function player_modificator_item:OnActivate()
    if self.modificator ~= INVALID_ID then
        EntityService:RemoveEntity( self.modificator )
    end

    self.modificator = self:AttachModificator(self.owner)
end

function player_modificator_item:OnUnequipped()
    if not ItemService:IsItemReference( self.modificator, self.entity ) then
        return
    end

    EntityService:RemoveEntity( self.modificator )
    self.modificator = INVALID_ID
end

return player_modificator_item