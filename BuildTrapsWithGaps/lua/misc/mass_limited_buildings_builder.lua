require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'mass_limited_buildings_builder' ( LuaEntityObject )

function mass_limited_buildings_builder:__init()
    LuaEntityObject.__init(self, self)
end

function mass_limited_buildings_builder:init()

    self.playerId = self.data:GetInt("playerId")

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    self.limitedBuildingsQueue = {}

    local delimiterEntities = "|"

    local entitiesListString = self.data:GetString("entities_list")

    local entitiesListArray = Split( entitiesListString, delimiterEntities )

    for entityString in Iter( entitiesListArray ) do

        local entityId = tonumber(entityString)

        if ( entityId ~= nil ) then

            Insert( self.limitedBuildingsQueue, entityId )
        end
    end

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute = "onWorking", interval = 0.05 } )

    self.stateMachine:ChangeState("working")
end

function mass_limited_buildings_builder:onWorking( state )

    if ( #self.limitedBuildingsQueue == 0 ) then

        EntityService:RemoveEntity( self.entity )
        return
    end

    local ghost = self.limitedBuildingsQueue[1]
    Remove( self.limitedBuildingsQueue, ghost )

    local testBuildableFlag = self:BuildEntity(ghost)
    EntityService:RemoveEntity(ghost)

    if( testBuildableFlag == CBF_LIMITS ) then

        if ( #self.limitedBuildingsQueue > 0 ) then

            for index=1,#self.limitedBuildingsQueue do

                local entity = self.limitedBuildingsQueue[index]
                EntityService:RemoveEntity(entity)
            end

            self.limitedBuildingsQueue = {}
        end
    end
end

function mass_limited_buildings_builder:BuildEntity(entity)

    local transform = EntityService:GetWorldTransform( entity )

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    local blueprintName = buildingComponent.bp

    local testBuildable = self:CheckEntityBuildable( entity , transform, blueprintName )

    if ( testBuildable == nil ) then

        return
    end

    if ( testBuildable.flag == CBF_TO_CLOSE ) then

        local tooCloseAnnoucement = self:GetTooCloseAnnoucement( blueprintName )

        if ( tooCloseAnnoucement ~= "" ) then
            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, tooCloseAnnoucement, self.playerEntity, false )
        end

        return testBuildable.flag

    elseif( testBuildable.flag == CBF_LIMITS ) then

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", self.playerEntity, false )

        return testBuildable.flag
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        local soundAnnouncement = "voice_over/announcement/not_enough_resources"

        if ( missingResources.count  == 1 ) then

            local singleMissingResource = missingResources[1]

            if ( self.announcements and self.announcements[singleMissingResource] ~= nil and self.announcements[singleMissingResource] ~= "" ) then

                soundAnnouncement = self.announcements[singleMissingResource]
            end
        end

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, soundAnnouncement, self.playerEntity, false )

        return testBuildable.flag
    end

    --  Do not create cubes for building_mode "line"
    local createCube = self:GetCreateCube( blueprintName )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, transform, createCube, {} )

    elseif( testBuildable.flag == CBF_OVERRIDES ) then

        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, transform, createCube, {} )

    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function mass_limited_buildings_builder:CheckEntityBuildable( entity, transform, blueprintName, id )

    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprintName, id )

    if ( test == nil ) then
        return
    end

    local testBuildable = reflection_helper( test:ToTypeInstance(), test )

    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

    local materialToSet = "hologram/blue"

    if ( testBuildable.flag == CBF_REPAIR ) then
        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 )) then

            materialToSet = "hologram/pass"

            else

            materialToSet = "hologram/deny"
        end
    else
        if ( canBuildOverride ) then

            materialToSet = "hologram/active"

        elseif ( canBuild ) then
            
            materialToSet = "hologram/blue"

        else

            materialToSet = "hologram/red"
        end
    end

    self:ChangeEntityMaterial( entity, materialToSet )

    return testBuildable
end

function mass_limited_buildings_builder:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function mass_limited_buildings_builder:GetTooCloseAnnoucement( blueprintName )

    self.cacheTooCloseAnnoucement = self.cacheTooCloseAnnoucement or {}

    if ( self.cacheTooCloseAnnoucement[blueprintName] ~= nil ) then

        return self.cacheTooCloseAnnoucement[blueprintName]
    end

    local buildingDesc = self:GetBuildingDesc( blueprintName )

    local result = buildingDesc.min_radius_effect or ""

    self.cacheTooCloseAnnoucement[blueprintName] = result

    return result
end

function mass_limited_buildings_builder:GetCreateCube( blueprintName )

    self.cacheGetCreateCube = self.cacheGetCreateCube or {}

    if ( self.cacheGetCreateCube[blueprintName] ~= nil ) then

        return self.cacheGetCreateCube[blueprintName]
    end

    local buildingDesc = self:GetBuildingDesc( blueprintName )

    local buildingMode = buildingDesc.building_mode or ""

    --  Do not create cubes for building_mode "line"
    local result = not ( buildingMode == "line" )

    self.cacheGetCreateCube[blueprintName] = result

    return result
end

function mass_limited_buildings_builder:GetBuildingDesc( blueprintName )

    self.cacheBuildingDesc = self.cacheBuildingDesc or {}

    if ( self.cacheBuildingDesc[blueprintName] ~= nil ) then

        return self.cacheBuildingDesc[blueprintName]
    end

    local result = reflection_helper( BuildingService:GetBuildingDesc( blueprintName ) )

    self.cacheBuildingDesc[blueprintName] = result

    return result
end

function mass_limited_buildings_builder:OnRelease()

    if ( self.limitedBuildingsQueue ~= nil) then
        for ghost in Iter(self.limitedBuildingsQueue) do
            EntityService:RemoveEntity(ghost)
        end
    end
end

return mass_limited_buildings_builder