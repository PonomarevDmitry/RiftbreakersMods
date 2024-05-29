require("lua/utils/numeric_utils.lua")

class 'player_modificator_source' ( LuaEntityObject )

function player_modificator_source:__init()
	LuaEntityObject.__init(self,self)
end

function player_modificator_source:init()
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
    self:RegisterHandler( self.entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" )
end

function player_modificator_source:AttachModificator( entity )
    local target = EntityService:SpawnAndAttachEntity( self.data:GetStringOrDefault("blueprint", "error"), entity )

    --local bounds_size = VectorDiv( EntityService:GetBoundsSize( entity ), EntityService:GetScale( entity ) )
    --EntityService:SetScale( target, bounds_size.x, bounds_size.y, bounds_size.z )
end

function player_modificator_source:OnInteractWithEntityRequest( evt )
    self:AttachModificator(evt:GetOwner())

    if self.data:GetIntOrDefault("remove_entity", 0) == 1 then
        EntityService:RemoveEntity(self.entity)
    end
end

function player_modificator_source:OnEnteredTriggerEvent(evt)
    self:AttachModificator(evt:GetOtherEntity())

    if self.data:GetIntOrDefault("remove_entity", 0) == 1 then
        EntityService:RemoveEntity(self.entity)
    end
end

return player_modificator_source