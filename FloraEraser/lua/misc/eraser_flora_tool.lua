local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_flora_tool' ( tool )

function eraser_flora_tool:__init()
    tool.__init(self,self)
end

function eraser_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_flora_tool", self.entity)

    self.poogretPlantSmall = CalcHash("props/special/interactive/poogret_plant_small_01")
    self.poogretPlantMedium = CalcHash("props/special/interactive/poogret_plant_medium_01")
    self.poogretPlantBig = CalcHash("props/special/interactive/poogret_plant_big_01")
end

function eraser_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_flora_tool:FindEntitiesToSelect( selectorComponent )

    local selectorPosition = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(selectorPosition, scaleVector)
    local maxVector = VectorAdd(selectorPosition, scaleVector)

    local predicate = {

        signature="TypeComponent",

        filter = function(entity)

            if ( not EntityService:CompareType( entity, "flora" ) ) then
                return false
            end

            local blueprintName = EntityService:GetBlueprintName(entity)
            if ( string.find(blueprintName, "props/special/interactive/poogret_plant" ) ~= nil ) then
                return false
            end

            return true
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

        if ( not EntityService:CompareType( entity, "flora" ) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)
        if ( string.find(blueprintName, "props/special/interactive/poogret_plant" ) ~= nil ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end


    predicate = {
        signature = "VegetationLifecycleEnablerComponent"
    }

    tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue2
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue2
        end

        local blueprintName = EntityService:GetBlueprintName(entity)
        if ( string.find(blueprintName, "props/special/interactive/poogret_plant" ) ~= nil ) then
            goto continue2
        end

        local enablerComponent = EntityService:GetComponent( entity, "VegetationLifecycleEnablerComponent")
        if ( enablerComponent == nil ) then
            goto continue2
        end

        local enablerComponentRef = reflection_helper(enablerComponent)
        if ( enablerComponentRef.chain_destination and (enablerComponentRef.chain_destination.hash == self.poogretPlantSmall or enablerComponentRef.chain_destination.hash == self.poogretPlantMedium or enablerComponentRef.chain_destination.hash == self.poogretPlantBig)) then
            goto continue2
        end

        Insert( result, entity )

        ::continue2::
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

function eraser_flora_tool:AddedToSelection( entity )
end

function eraser_flora_tool:RemovedFromSelection( entity )
end

function eraser_flora_tool:OnRotate()
end

function eraser_flora_tool:OnActivateEntity( entity )

    EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

    EntityService:RequestDestroyPattern( entity, "default" )

    QueueEvent( "DissolveEntityRequest", entity, 2.0, 0 )
end

return eraser_flora_tool
