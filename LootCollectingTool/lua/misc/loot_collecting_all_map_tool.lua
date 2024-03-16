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

    self.currentTick = 0
    self.tickMod = 10
end

function loot_collecting_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function loot_collecting_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function loot_collecting_all_map_tool:FindEntitiesToSelect( selectorComponent )

    local performFind = (self.currentTick % self.tickMod) == 0

    if ( performFind ) then

        self.currentTick = 0
    end

    self.currentTick = self.currentTick + 1

    if ( not performFind ) then

        return self.selectedEntities
    end

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

    local selectorPosition = selectorComponent.position

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2
    end

    table.sort(possibleSelectedEnts, function(a,b)
        return sorter(possibleSelectedEnts, a, b)
    end)

    return possibleSelectedEnts
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

    for entity in Iter( self.selectedEntities ) do

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
