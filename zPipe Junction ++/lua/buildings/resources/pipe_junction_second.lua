class 'pipe_junction_second'( LuaEntityObject )
require( "lua/utils/string_utils.lua" )

function pipe_junction_second:__init()
    LuaEntityObject.__init( self, self )
end

function pipe_junction_second:init()
    local parent = EntityService:GetParent( self.entity )
    self:RegisterHandler( parent, "BuildingModifiedEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( parent, "RecreateComponentFromBlueprintRequest", "OnRecreateComponentFromBlueprintRequest" )

    self:RegisterHandler( self.entity, "BuildingModifiedEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.entity, "RecreateComponentFromBlueprintRequest", "OnRecreateComponentFromBlueprintRequest" )

    self.resource = ""
    self.postfix = self.data:GetStringOrDefault( "postfix", "_pipe" )

    local function SellPipesInsideJunction()
        local predicate = {
            -- type = "building"
            signature = "PipeComponent",
            filter = function( entity )
                local component = EntityService:GetComponent( entity, "BuildingComponent" )
                if not component or component:GetField( "type" ):GetValue() ~= "pipe" then
                    return false
                end

                local name = EntityService:GetBlueprintName( entity )
                if not name:find( "buildings/resources/pipe" ) or name:find( "pipe_junction" ) then
                    return false
                end

                return true
            end
        }

        local entities = FindService:FindEntitiesByPredicateInRadius( parent, 2, predicate )
        local player = PlayerService:GetPlayerForEntity( parent ) -- self.entity cause crash
        for i = 1, #entities do
            local entity = entities[i]
            -- copy from repair tool
            if EntityService:GetGroup( entity ) == "##ruins##" then
                EntityService:SetGroup( entity, "" )
                BuildingService:BlinkBuilding( entity )
                QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
            else
                QueueEvent( "SellBuildingRequest", entity, player, false )
            end
        end
    end

    SellPipesInsideJunction()
end

function pipe_junction_second:OnBuildingEnd()
    self:FixMaterial()
end

function pipe_junction_second:FixMaterial()
    local pipeComponent = EntityService:GetComponent( self.entity, "PipeComponent" )
    if (pipeComponent == nil) then
        self.resource = ""
    else
        self.resource = pipeComponent:GetField( "resource_name" ):GetValue()
    end

    if (IsNullOrEmpty( self.resource )) then
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )
    else
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix, 1, "default" )
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. "_fresnel", 1, "fresnel" )
    end
end

function pipe_junction_second:OnBuildingModifiedEvent( evt )
    self:FixMaterial()
end

function pipe_junction_second:OnRecreateComponentFromBlueprintRequest( evt )
    self:FixMaterial()
end

return pipe_junction_second
