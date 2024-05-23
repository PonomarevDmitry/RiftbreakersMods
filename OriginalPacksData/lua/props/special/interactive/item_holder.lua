

class 'item_holder' ( LuaEntityObject )
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/item_utils.lua")

function item_holder:__init()
	LuaEntityObject.__init(self,self)
end

function item_holder:init()
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )


    local entities = EntityService:GetChildren( self.entity, false )
    for entity in Iter(entities)  do
        EffectService:DestroyEffectsByGroup( entity, "laser_pointer")
    end
end

function item_holder:OnInteractWithEntityRequest( event )
    local player_id = PlayerService:GetPlayerForEntity( event:GetOwner()  )
    local entities = EntityService:GetChildren( self.entity, false )
    for entity in Iter(entities)  do
        QueueEvent( "FadeEntityOutRequest", entity, 1 )
    end
    EntityService:DissolveEntity( self.entity, 1 )

    local item = self.data:GetIntOrDefault("item", INVALID_ID)
    if ( item ~= INVALID_ID ) then
        QueueEvent( "InteractEntityRequest", item, player_id )
    end
end

return item_holder
