require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'build_after_sell_script' ( LuaEntityObject )

function build_after_sell_script:__init()
    LuaEntityObject.__init(self, self)
end

function build_after_sell_script:init()

    self.playerId = self.data:GetInt("player_id")

    self.targetEntity = self.data:GetInt("target_entity")

    self.newBuildingBlueprintName = self.data:GetString("building_blueprintname")

    self.team = EntityService:GetTeam( self.targetEntity )

    self.transform = EntityService:GetWorldTransform( self.targetEntity )

    self.position = self.transform.position
    self.orientation = self.transform.orientation

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function build_after_sell_script:OnBuildingSellEndEvent()

    if ( self.newBuildingBlueprintName == "" or self.newBuildingBlueprintName == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.newBuildingBlueprintName ) ) then
        self:DestroySelf()
        return
    end

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, self.newBuildingBlueprintName, self.transform, true, {} )

    self:DestroySelf()
end

function build_after_sell_script:OnLoad()

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

function build_after_sell_script:DestroySelf()
    self.targetEntity = nil
    EntityService:RemoveEntity( self.entity )
end

return build_after_sell_script