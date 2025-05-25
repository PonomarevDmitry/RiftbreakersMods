local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'fertilizer_flora_tool' ( tool )

function fertilizer_flora_tool:__init()
    tool.__init(self,self)
end

function fertilizer_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_fertilizer_flora_tool", self.entity)

    self.effect_blueprint = self.data:GetStringOrDefault("fertilize_effect", "")
end

function fertilizer_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function fertilizer_flora_tool:FindEntitiesToSelect( selectorComponent )

    local selectorPosition = selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(selectorPosition, scaleVector)
    local maxVector = VectorAdd(selectorPosition, scaleVector)

    local predicate = {
        signature = "VegetationLifecycleEnablerComponent,VegetationLifecycleComponent"
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

function fertilizer_flora_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
    end
end

function fertilizer_flora_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function fertilizer_flora_tool:OnRotate()
end

function fertilizer_flora_tool:OnActivateEntity( entity )

    EntityService:RemoveComponent(entity, "VegetationLifecycleComponent")

    EntityService:CreateComponent(entity, "VegetationLifecycleComponent") -- create new component that will trigger re-growth on next update

    if self.effect_blueprint ~= "" then
        EffectService:SpawnEffect( entity, self.effect_blueprint )
    end
end

return fertilizer_flora_tool
