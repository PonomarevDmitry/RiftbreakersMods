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
    EntityService:CreateBoundsComponent(target, { x=-0.1, y=-0.1, z=-0.1 }, { x=0.1, y=0.1, z=0.1 } )

    ItemService:SetItemReference( target, self.entity, EntityService:GetBlueprintName( self.entity ))
    EntityService:PropagateEntityOwner( target, self.entity )

    local lifetime = EntityService:GetLifeTime( target )
    if lifetime > 0 then
        BuildingService:AttachGuiTimerWithMaterial( target, lifetime, true, "gui/hud/bars/upgrade_timer" )
    end

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