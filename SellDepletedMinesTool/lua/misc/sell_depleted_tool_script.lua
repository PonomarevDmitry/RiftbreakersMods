require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'sell_depleted_tool_script' ( LuaEntityObject )

function sell_depleted_tool_script:__init()
    LuaEntityObject.__init(self, self)
end

function sell_depleted_tool_script:init()

    self.playerId = self.data:GetInt("player_id")

    self.targetEntity = self.data:GetInt("target_entity")

    self.buildingCount = self.data:GetInt("building_count")

    self.newBuildingBlueprintName = self.data:GetString("building_blueprintname")

    self.team = EntityService:GetTeam( self.targetEntity )

    self.transform = EntityService:GetWorldTransform( self.targetEntity )

    self.position = self.transform.position
    self.orientation = self.transform.orientation

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function sell_depleted_tool_script:OnLoad()

    if ( self.targetEntity == nil ) then
        self:DestroySelf()
        return
    end

    if ( self.targetEntity == INVALID_ID ) then
        self:DestroySelf()
        return
    end

    if ( not EntityService:IsAlive( self.targetEntity) ) then
        self:DestroySelf()
        return
    end

    if ( self.newBuildingBlueprintName == "" or self.newBuildingBlueprintName == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.newBuildingBlueprintName ) ) then
        self:DestroySelf()
        return
    end

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function sell_depleted_tool_script:OnBuildingSellEndEvent()

    if ( self.newBuildingBlueprintName == "" or self.newBuildingBlueprintName == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.newBuildingBlueprintName ) ) then
        self:DestroySelf()
        return
    end

    local deltas = { -1, 1 }

    for deltaX in Iter( deltas ) do
        for deltaZ in Iter( deltas ) do

            local newTransform = {}

            newTransform.scale = newTransform.scale
            newTransform.orientation = newTransform.orientation

            newTransform.position = {}
            newTransform.position.y = self.transform.position.y
            newTransform.position.x = self.transform.position.x + deltaX * 2
            newTransform.position.z = self.transform.position.z + deltaZ * 2

            QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.newBuildingBlueprintName, newTransform, false )
        end
    end

    self:DestroySelf()
end

function sell_depleted_tool_script:DestroySelf()
    self.targetEntity = nil
    EntityService:RemoveEntity( self.entity )
end

return sell_depleted_tool_script