local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'unit_type_add_invisible_tool' ( tool )

function unit_type_add_invisible_tool:__init()
    tool.__init(self,self)
end

function unit_type_add_invisible_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_unit_type_changer_tool", self.entity)
end

function unit_type_add_invisible_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function unit_type_add_invisible_tool:FindEntitiesToSelect( selectorComponent )

    local selectorPosition = selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(selectorPosition, scaleVector)
    local maxVector = VectorAdd(selectorPosition, scaleVector)

    self.predicateType = self.predicateType or {

        signature = "TypeComponent",

        filter = function(entity)

            local blueprintName = EntityService:GetBlueprintName(entity)

            if ( EntityService:CompareType( entity, "player" ) ) then
                return false
            end

            if ( EntityService:CompareType( entity, "quelver" ) ) then
                return false
            end

            if ( EntityService:CompareType( entity, "invisible" ) ) then
                return false
            end

            if ( EntityService:CompareType( entity, "ground_unit" ) ) then
                return true
            end

            if ( EntityService:CompareType( entity, "ground_unit_big" ) ) then
                return true
            end

            if ( EntityService:CompareType( entity, "ground_unit_medium" ) ) then
                return true
            end

            if ( EntityService:CompareType( entity, "ground_unit_small" ) ) then
                return true
            end

            return false
        end
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, self.predicateType )

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

function unit_type_add_invisible_tool:AddedToSelection( entity )

    if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
        QueueEvent( "SelectEntityRequest", entity )
    end
end

function unit_type_add_invisible_tool:RemovedFromSelection( entity )

    if ( EntityService:HasComponent( entity, "SelectableComponent" ) ) then
        QueueEvent( "DeselectEntityRequest", entity )
    end
end

function unit_type_add_invisible_tool:OnRotate()
end

function unit_type_add_invisible_tool:OnActivateEntity( entity )

    local currentType = EntityService:GetType(entity) or ""

    if ( string.len(currentType) > 0 ) then

        currentType = currentType .. "|"
    end

    currentType = currentType .. "invisible"

    EntityService:ChangeType( entity, currentType )
end

return unit_type_add_invisible_tool
