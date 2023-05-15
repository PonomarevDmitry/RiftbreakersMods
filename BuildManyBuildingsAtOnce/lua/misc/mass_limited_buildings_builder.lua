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

    self.annoucements = {
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
            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, tooCloseAnnoucement, entity, false )
        end

        return testBuildable.flag

    elseif( testBuildable.flag == CBF_LIMITS ) then

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", entity, false )

        return testBuildable.flag
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        if ( missingResources.count > 1 ) then

            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/not_enough_resources", entity, false )
        else

            local singleMissingResource = missingResources[1]

            if ( self.annoucements[singleMissingResource] ~= nil and self.annoucements[singleMissingResource] ~= "" ) then

                QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.annoucements[singleMissingResource], entity , false )
            end
        end

        return testBuildable.flag
    end

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, transform, true )

    elseif( testBuildable.flag == CBF_OVERRIDES ) then

        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, blueprintName, transform, true )

    elseif( testBuildable.flag == CBF_REPAIR ) then

        QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
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

    local skinned = EntityService:IsSkinned(entity)

    if ( testBuildable.flag == CBF_REPAIR ) then
        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 )) then
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_skinned_pass")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_pass")
            end
        else
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_skinned_deny")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_deny")
            end
        end
    else
        if ( canBuildOverride ) then
            if ( skinned ) then
                EntityService:ChangeMaterial( entity, "selector/hologram_active_skinned")
            else
                EntityService:ChangeMaterial( entity, "selector/hologram_active")
            end
        elseif ( canBuild ) then
            EntityService:ChangeMaterial( entity, "selector/hologram_blue")
        else
            EntityService:ChangeMaterial( entity, "selector/hologram_red")
        end
    end

    return testBuildable
end

function mass_limited_buildings_builder:GetTooCloseAnnoucement( blueprintName )

    self.cacheTooCloseAnnoucement = self.cacheTooCloseAnnoucement or {}

    if ( self.cacheTooCloseAnnoucement[blueprintName] ~= nil ) then

        return self.cacheTooCloseAnnoucement[blueprintName]
    end

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( blueprintName ) )

    local result = buildingDesc.min_radius_effect or ""

    self.cacheTooCloseAnnoucement[blueprintName] = result

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