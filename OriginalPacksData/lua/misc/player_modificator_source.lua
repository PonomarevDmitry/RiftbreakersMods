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
    EntityService:CreateBoundsComponent(target, { x=-0.1, y=-0.1, z=-0.1 }, { x=0.1, y=0.1, z=0.1 } )

    local lifetime = EntityService:GetLifeTime( target )
    if lifetime > 0 then
        BuildingService:AttachGuiTimerWithMaterial( target, lifetime, true, "gui/hud/bars/upgrade_timer" )
    end
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