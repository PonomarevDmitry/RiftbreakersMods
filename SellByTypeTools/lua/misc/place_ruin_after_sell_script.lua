require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'place_ruin_after_sell_script' ( LuaEntityObject )

function place_ruin_after_sell_script:__init()
    LuaEntityObject.__init(self, self)
end

function place_ruin_after_sell_script:init()

    self.playerId = self.data:GetInt("player_id")
    self.targetEntity = self.data:GetInt("target_entity")

    self.ruinsBlueprint = self.data:GetString("ruins_blueprint")

    self.team = EntityService:GetTeam( self.targetEntity )

    self.transform = EntityService:GetWorldTransform( self.targetEntity )

    self.position = self.transform.position
    self.orientation = self.transform.orientation

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function place_ruin_after_sell_script:OnBuildingSellEndEvent()

    if ( self.ruinsBlueprint == "" or self.ruinsBlueprint == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.ruinsBlueprint ) ) then
        self:DestroySelf()
        return
    end

    local newRuinsEntity = EntityService:SpawnEntity( self.ruinsBlueprint, self.position, self.team )

    local playerReferenceRef = reflection_helper( EntityService:CreateComponent( newRuinsEntity, "PlayerReferenceComponent" ) )

    -- const PlayerReferenceType PlayerReferenceType::RT_BUILDING = PlayerReferenceType{ 4 };
    playerReferenceRef.player_id = self.playerId
    playerReferenceRef.reference_type.internal_enum = 4

    EntityService:SetOrientation( newRuinsEntity, self.orientation )
    EntityService:RemoveComponent( newRuinsEntity, "LuaComponent" )

    self:DestroySelf()
end

function place_ruin_after_sell_script:OnLoad()

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

    if ( self.ruinsBlueprint == "" or self.ruinsBlueprint == nil ) then
        self:DestroySelf()
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.ruinsBlueprint ) ) then
        self:DestroySelf()
        return
    end

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )
end

function place_ruin_after_sell_script:DestroySelf()
    self.targetEntity = nil
    EntityService:RemoveEntity( self.entity )
end

return place_ruin_after_sell_script