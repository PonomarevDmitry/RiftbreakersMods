

class 'item_holder' ( LuaEntityObject )

require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/item_utils.lua")

function item_holder:__init()
	LuaEntityObject.__init(self,self)
end

function item_holder:init()
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )

    local entities = EntityService:GetChildren( self.entity, false )
    for entity in Iter(entities)  do
        EffectService:DestroyEffectsByGroup( entity, "laser_pointer")
        EffectService:AttachEffects( entity, "loot")
    end

    local item = self.data:GetIntOrDefault("item", INVALID_ID)
    if EntityService:HasComponent( item, "PlayerReferenceComponent") then
        EntityService:DisableComponent( self.entity, "InteractiveComponent")
        EntityService:CreateComponent( self.entity, "NetReplicateToOwnerComponent")
    else
        EntityService:DisableComponent( self.entity, "TriggerComponent")
    end
end

function item_holder:GiveItemToPlayer( player_id )
    local entities = EntityService:GetChildren( self.entity, false )
    for entity in Iter(entities)  do
        QueueEvent( "FadeEntityOutRequest", entity, 1 , true)

        EffectService:SpawnEffects( entity, "loot_collect")
        EffectService:DestroyEffectsByGroup( entity, "loot")
    end

    EntityService:DissolveEntity( self.entity, 1 )

    local item = self.data:GetIntOrDefault("item", INVALID_ID)
    if ( item ~= INVALID_ID ) then
        QueueEvent( "InteractEntityRequest", item, player_id )
    end
end

function item_holder:OnEnteredTriggerEvent( evt )
    local item = self.data:GetIntOrDefault("item", INVALID_ID)
    
    local item_owner = PlayerService:GetPlayerForEntity( item )
    if item_owner == INVALID_ID then
        return
    end

    local player_id = PlayerService:GetPlayerForEntity( evt:GetOtherEntity() )
    if item_owner == player_id and HealthService:IsAlive( evt:GetOtherEntity() ) then 
        self:GiveItemToPlayer( player_id )
    end
end

function item_holder:OnInteractWithEntityRequest( event )
    local player_id = PlayerService:GetPlayerForEntity( event:GetOwner()  )
    self:GiveItemToPlayer( player_id )
end

return item_holder
