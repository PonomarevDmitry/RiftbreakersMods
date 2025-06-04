local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'heal_neutral_tool' ( tool )

function heal_neutral_tool:__init()
    tool.__init(self,self)
end

function heal_neutral_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_heal_neutral_tool", self.entity)
    
    self.heal_effect = self.data:GetStringOrDefault("heal_effect", "")

    if ( self.heal_effect and self.heal_effect ~= "" ) then

        self.heal_effectArray = Split(self.heal_effect, ",")
    end

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)
end

function heal_neutral_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function heal_neutral_tool:FindEntitiesToSelect( selectorComponent )

    local selectorPosition = selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(selectorPosition, scaleVector)
    local maxVector = VectorAdd(selectorPosition, scaleVector)

    local predicate = {

        signature = "HealthComponent",

        filter = function(entity)

            if ( not EntityService:IsAlive(entity) ) then
                return false
            end

            if ( not HealthService:IsAlive(entity) ) then
                return false
            end

            local health = HealthService:GetHealthInPercentage( entity )

            if ( health >= 1.0 ) then
                return false
            end

            if ( EntityService:HasComponent( entity, "BuildingComponent" ) or EntityService:HasComponent( entity, "MechComponent" ) ) then
            
                return false
            end

            local isUnitEntity = EntityService:HasComponent( entity, "AIUnitComponent" )
                or EntityService:HasComponent( entity, "NeutralUnitComponent" )
                or EntityService:HasComponent( entity, "WaveUnitComponent" )
                or EntityService:HasComponent( entity, "AggressiveStateComponent" )
                or EntityService:HasComponent( entity, "NotAggressiveStateComponent" )
                ;

            local isEnemy = EntityService:IsInTeamRelation(self.player, entity, "hostility")

            if ( isUnitEntity ) then

                if ( isEnemy ) then

                    return false
                else
                
                    return true
                end
            end

            if ( EntityService:HasComponent( entity, "VegetationComponent" ) ) then
            
                if ( isEnemy ) then

                    return true
                else
                
                    return false
                end
            end

            return false
        end
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

    local result = {}

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2
    end

    table.sort(result, function(a,b)
        return sorter(result, a, b)
    end)

    return result
end

function heal_neutral_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function heal_neutral_tool:RemovedFromSelection( entity )

    EntityService:RemoveMaterial( entity, "selected" )
end

function heal_neutral_tool:OnRotate()
end

function heal_neutral_tool:OnActivateEntity( entity )

    HealthService:SetHealth( entity, HealthService:GetMaxHealth( entity) )

    if ( self.heal_effectArray and #self.heal_effectArray > 0 ) then

        for effectName in Iter(self.heal_effectArray) do

            EffectService:SpawnEffect( entity, effectName )
        end
    end
end

return heal_neutral_tool
