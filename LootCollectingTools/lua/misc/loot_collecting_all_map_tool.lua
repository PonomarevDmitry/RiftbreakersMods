local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'loot_collecting_all_map_tool' ( tool )

function loot_collecting_all_map_tool:__init()
    tool.__init(self,self)
end

function loot_collecting_all_map_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_loot_collecting_all_map_tool", self.entity)

    self.scaleMap = {
        1,
    }

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)
end

function loot_collecting_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function loot_collecting_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function loot_collecting_all_map_tool:OnUpdate()

    if ( self.activated ) then
        
        if ( is_server and is_client ) then

            self:CollectlAllLoot()

        else

            local mapperName = "LootCollectingToolsAllRequest|" .. tostring(self.playerId)

            QueueEvent("OperateActionMapperRequest", event_sink, mapperName, false )
        end
    end
end

function loot_collecting_all_map_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function loot_collecting_all_map_tool:ValidateTarget( entity, pawn )

    if ( not EntityService:IsAlive(entity) ) then
        return false
    end

    local test_entity = EntityService:GetParent( entity )
    if test_entity == INVALID_ID then
        test_entity = entity
    end

    if EntityService:GetComponent( test_entity, "PhysicsComponent") == nil then
        return false
    end

    return ItemService:CanFitResourceGiver( pawn, test_entity )
end

function loot_collecting_all_map_tool:AddedToSelection( entity )
end

function loot_collecting_all_map_tool:RemovedFromSelection( entity )
end

function loot_collecting_all_map_tool:OnRotate()
end

function loot_collecting_all_map_tool:OnActivateSelectorRequest()

    self.activated = true

    if ( is_server and is_client ) then

        self:CollectlAllLoot()

    else

        local mapperName = "LootCollectingToolsAllRequest|" .. tostring(self.playerId)

        QueueEvent("OperateActionMapperRequest", event_sink, mapperName, false )
    end
end

function loot_collecting_all_map_tool:CollectlAllLoot()

    local predicate = {

        signature = "BlueprintComponent,IdComponent,ParentComponent",

        filter = function(entity)

            local entity_name = EntityService:GetName(entity);
            if ( entity_name ~= "#loot#" ) then
                return false;
            end

            return self:ValidateTarget( entity, self.player )
        end
    };

    local world_min = MissionService:GetWorldBoundsMin();
    local world_max = MissionService:GetWorldBoundsMax();

    world_min.y = -100.0
    world_max.y = 100.0

    local tempCollection = FindService:FindEntitiesByPredicateInBox( world_min, world_max, predicate )

    local possibleSelectedEnts = {}

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
            goto continue
        end

        Insert( possibleSelectedEnts, entity )

        ::continue::
    end

    local distances = {}

    for entity in Iter( possibleSelectedEnts ) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(possibleSelectedEnts, sorter)

    for entity in Iter( possibleSelectedEnts ) do

        if ( self:ValidateTarget( entity, self.player ) ) then

            local test_entity = EntityService:GetParent( entity )
            if test_entity == INVALID_ID then
                test_entity = entity
            end
        
            EffectService:SpawnEffect(test_entity, "effects/loot_collecting_tool/select")

            EffectService:SpawnEffects(test_entity, "loot_collect")

            ItemService:FlyItemToInventory(self.player, test_entity)
        end
    end
end

return loot_collecting_all_map_tool
