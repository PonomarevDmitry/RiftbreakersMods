local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'loot_collecting_tool' ( tool )

function loot_collecting_tool:__init()
    tool.__init(self,self)
end

function loot_collecting_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_loot_collecting_tool", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)
end

function loot_collecting_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function loot_collecting_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function loot_collecting_tool:FindEntitiesToSelect( selectorComponent )

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

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(position, scaleVector)
    local maxVector = VectorAdd(position, scaleVector)

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

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

    return possibleSelectedEnts
end

function loot_collecting_tool:ValidateTarget( entity, pawn )

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

function loot_collecting_tool:AddedToSelection( entity )        

    local test_entity = EntityService:GetParent( entity )
    if test_entity == INVALID_ID then
        test_entity = entity
    end

    EffectService:SpawnEffect(test_entity, "effects/loot_collecting_tool/select")
end

function loot_collecting_tool:RemovedFromSelection( entity )
end

function loot_collecting_tool:OnRotate()
end

function loot_collecting_tool:OnActivateEntity( entity )

    if ( is_server and is_client ) then

        if ( self:ValidateTarget( entity, self.player ) ) then

            local test_entity = EntityService:GetParent( entity )
            if test_entity == INVALID_ID then
                test_entity = entity
            end
        
            EffectService:SpawnEffect(test_entity, "effects/loot_collecting_tool/select")

            EffectService:SpawnEffects(test_entity, "loot_collect")

            ItemService:FlyItemToInventory(self.player, test_entity)
        end
    else

        local mapperName = "LootCollectingToolsSingle_" .. tostring(self.playerId)

        QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
    end
end

return loot_collecting_tool
