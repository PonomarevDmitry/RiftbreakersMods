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

    if ( not EntityService:IsAlive( self.targetEntity ) ) then
        self:DestroySelf()
        return
    end

    local targetEntityBlueprintName = EntityService:GetBlueprintName(self.targetEntity)

    local buildingDesc = BuildingService:GetBuildingDesc( targetEntityBlueprintName )
    if ( buildingDesc == nil ) then
        self:DestroySelf()
        return
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        self:DestroySelf()
        return
    end

    self:RegisterHandler( self.targetEntity, "BuildingSellEndEvent", "OnBuildingSellEndEvent" )

    local database = EntityService:GetDatabase( self.targetEntity )
    if ( database == nil ) then
        return
    end

    local targetEntityLowNameKeyPrefix = BuildingService:FindLowUpgrade( targetEntityBlueprintName ) .. "_"

    self.databaseStringValues = {}
    self.databaseFloatValues = {}
    self.databaseIntValues = {}
    self.databaseVectorValues = {}

    local stringKeys = database:GetStringKeys()
    for key in Iter( stringKeys ) do

        local stringNumber = string.find( key, targetEntityLowNameKeyPrefix )
        if ( stringNumber == 1 ) then
            self.databaseStringValues[key] = database:GetString(key)
        end
    end

    local floatKeys = database:GetFloatKeys()
    for key in Iter( floatKeys ) do

        local stringNumber = string.find( key, targetEntityLowNameKeyPrefix )
        if ( stringNumber == 1 ) then
            self.databaseFloatValues[key] = database:GetFloat(key)
        end
    end

    local intKeys = database:GetIntKeys()
    for key in Iter( intKeys ) do

        local stringNumber = string.find( key, targetEntityLowNameKeyPrefix )
        if ( stringNumber == 1 ) then
            self.databaseIntValues[key] = database:GetInt(key)
        end
    end

    local keyVector = targetEntityLowNameKeyPrefix .. "center_point_vector"
    if ( database:HasVector(keyVector) ) then

        self.databaseVectorValues[keyVector] = database:GetVector(keyVector)
    end
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

    local database = EntityService:GetDatabase( newRuinsEntity )
    if ( database == nil ) then
        return
    end

    for key, value in pairs( self.databaseStringValues ) do
        database:SetString(key, value)
    end

    for key, value in pairs( self.databaseFloatValues ) do
        database:SetFloat(key, value)
    end

    for key, value in pairs( self.databaseIntValues ) do
        database:SetInt(key, value)
    end

    for key, value in pairs( self.databaseVectorValues ) do
        database:SetVector(key, value)
    end

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