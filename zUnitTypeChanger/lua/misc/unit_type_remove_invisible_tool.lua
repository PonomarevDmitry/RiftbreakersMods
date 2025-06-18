local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'unit_type_remove_invisible_tool' ( tool )

function unit_type_remove_invisible_tool:__init()
    tool.__init(self,self)
end

function unit_type_remove_invisible_tool:OnInit()
    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)
end

function unit_type_remove_invisible_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function unit_type_remove_invisible_tool:OnUpdate()

    if ( self.activated )  then

        for entity in Iter( self.selectedEntities ) do

            self:OnActivateEntity( entity )
        end
    end
end

function unit_type_remove_invisible_tool:FindEntitiesToSelect( selectorComponent )

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

            if ( not EntityService:CompareType( entity, "ground_unit" )
                and not EntityService:CompareType( entity, "ground_unit_big" )
                and not EntityService:CompareType( entity, "ground_unit_medium" )
                and not EntityService:CompareType( entity, "ground_unit_small" )
            ) then
                return false
            end

            if ( EntityService:CompareType( entity, "invisible" ) ) then
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

function unit_type_remove_invisible_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function unit_type_remove_invisible_tool:RemovedFromSelection( entity )

    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function unit_type_remove_invisible_tool:OnRotate()
end

function unit_type_remove_invisible_tool:OnActivateEntity( entity )

    local currentType = EntityService:GetType(entity) or ""

    currentType = string.gsub( currentType, "|invisible", "" )

    currentType = string.gsub( currentType, "invisible|", "" )

    currentType = string.gsub( currentType, "invisible", "" )

    currentType = string.gsub( currentType, "||", "|" )

    currentType = string.gsub( currentType, "^[|]*(.-)[|]*$", "%1" )

    EntityService:ChangeType( entity, currentType )





    local markerBlueprintName = "effects/unit_type_changer_tool/unit_type_changer_ignore"

    local childreen = EntityService:GetChildren(entity, true)

    for childEntity in Iter( childreen ) do

        local blueprintName = EntityService:GetBlueprintName(childEntity)

        if ( blueprintName == markerBlueprintName ) then

            EntityService:RemoveEntity( childEntity )
        end
    end
end

return unit_type_remove_invisible_tool
