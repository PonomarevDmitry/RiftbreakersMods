require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'hq_move_tool_builder' ( LuaEntityObject )

function hq_move_tool_builder:__init()
    LuaEntityObject.__init(self, self)
end

function hq_move_tool_builder:init()

    self.playerId = self.data:GetInt("playerId")

    self.hq = self.data:GetInt("hq")
    self.ghostHQ = self.data:GetInt("ghostHQ")

    self.paidResources = self.data:GetStringOrDefault("paidResources", "")
    self.blueprint = self.data:GetString("hq_blueprint")

    local position = {}

    position.x = self.data:GetFloat("position.x")
    position.y = self.data:GetFloat("position.y")
    position.z = self.data:GetFloat("position.z")

    local orientation = {}
    
    orientation.x = self.data:GetFloat("orientation.x")
    orientation.y = self.data:GetFloat("orientation.y")
    orientation.z = self.data:GetFloat("orientation.z")
    orientation.w = self.data:GetFloat("orientation.w")

    local transform = {}
    transform.position = position
    transform.orientation = orientation

    self.transform = transform

    self:RegisterHandler( self.hq, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )

    local component = EntityService:GetComponent( self.hq, "BuildingComponent" )
    if ( component ~= nil ) then

        component:GetField("m_isSellable"):SetValue("1")

        local componentRef = reflection_helper( component )
    
        if ( componentRef.build_costs ~= nil and componentRef.build_costs.resource ~= nil ) then
    
            local container = rawget( componentRef.build_costs.resource, "__ptr" );
    
            if ( container ~= nil ) then

                local itemsCount = container:GetItemCount()

                for i=itemsCount,1,-1 do
                    container:EraseItem(i-1)
                end
            end
        end
    end

    QueueEvent( "SellBuildingRequest", self.hq, self.playerId, false )
end

function hq_move_tool_builder:OnBuildingSellEndEvent()

    if ( self.paidResources ~= "" ) then

        local paidResourcesArray = Split( self.paidResources, "|" )

        for template in Iter( paidResourcesArray ) do

            if ( template ~= "") then

                local resourceArray = Split( template, ";" )
                if ( #resourceArray == 2 ) then

                    local resourceName = resourceArray[1]
                    local resourceValue = tonumber( resourceArray[2] )

                    if ( resourceName ~= "" and resourceValue ~= nil ) then
                        PlayerService:AddResourceAmount( resourceName, resourceValue )
                    end
                end
            end
        end
    end

    EntityService:RemoveEntity( self.ghostHQ )
    self.ghostHQ = nil

    QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, self.transform, true )

    EntityService:RemoveEntity( self.entity )
end

function hq_move_tool_builder:OnRelease()

    if ( self.ghostHQ ~= nil ) then

        EntityService:RemoveEntity( self.ghostHQ )
    end
end

return hq_move_tool_builder
 