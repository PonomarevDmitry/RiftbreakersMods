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

    QueueEvent("OperateActionMapperRequest", self.hq, "HQMoveToolEnableSellOption", false )

    QueueEvent( "SellBuildingRequest", self.hq, self.playerId, false )
end

function hq_move_tool_builder:OnBuildingSellEndEvent()

    if ( self.paidResources ~= "" ) then

        local leadingPlayer = PlayerService:GetLeadingPlayer()

        local paidResourcesArray = Split( self.paidResources, "|" )

        for template in Iter( paidResourcesArray ) do

            if ( template ~= "") then

                local resourceArray = Split( template, ";" )
                if ( #resourceArray == 2 ) then

                    local resourceName = resourceArray[1]
                    local resourceValue = tonumber( resourceArray[2] )

                    if ( resourceName ~= "" and resourceValue ~= nil ) then
                        PlayerService:AddResourceAmount( leadingPlayer, resourceName, resourceValue, false )
                    end
                end
            end
        end
    end

    EntityService:RemoveEntity( self.ghostHQ )
    self.ghostHQ = nil

    QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, self.blueprint, self.transform, true, {} )

    EntityService:RemoveEntity( self.entity )
end

function hq_move_tool_builder:OnRelease()

    if ( self.ghostHQ ~= nil ) then

        EntityService:RemoveEntity( self.ghostHQ )
    end
end

return hq_move_tool_builder
 