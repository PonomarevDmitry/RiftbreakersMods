require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_small_floor_base_tool' ( LuaEntityObject )

function wall_small_floor_base_tool:__init()
    LuaEntityObject.__init(self,self)
end

function wall_small_floor_base_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    if ( self.OnPreInit ) then
        self:OnPreInit()
    end

    self:InitializeValues()

    if ( self.OnInit ) then
        self:OnInit()
    end
end

function wall_small_floor_base_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity , false )

    self:CreateInfoChild()

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    self.wallBlueprintName = self:GetWallBlueprintName()

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( self.wallBlueprintName ) )

    self.ghostBlueprintName = buildingDesc.ghost_bp
    self.buildingDesc = buildingDesc
end

function wall_small_floor_base_tool:CreateInfoChild()

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1)
    end
end

function wall_small_floor_base_tool:GetWallBlueprintName()

    local defaultBlueprintName = "buildings/defense/wall_small_floor_01"

    local result = self:GetMaxAvailableLevel( defaultBlueprintName )

    if ( result == nil or result == "" ) then

        return defaultBlueprintName
    end

    return result
end

function wall_small_floor_base_tool:GetMaxAvailableLevel( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return ""
    end

    if ( buildingDescRef.upgrade ~= nil and buildingDescRef.upgrade ~= "" ) then

        if ( self:IsBlueprintAvailable( buildingDescRef.upgrade ) ) then

            return self:GetMaxAvailableLevel( buildingDescRef.upgrade )
        end
    end

    return blueprintName
end

function wall_small_floor_base_tool:IsBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self:GetResearchForUpgrade( blueprintName ) or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function wall_small_floor_base_tool:GetResearchForUpgrade( blueprintName )

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function wall_small_floor_base_tool:SpawnGhostWallEntity()

    if ( self.ghostWall ~= nil) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )

    local orientation = transform.orientation

    local team = EntityService:GetTeam( self.entity )

    local buildingEntity = EntityService:SpawnAndAttachEntity( self.ghostBlueprintName, self.selector )

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )
    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    self:RemoveUselessComponents(buildingEntity)

    self.ghostWall = buildingEntity
end

function wall_small_floor_base_tool:RemoveUselessComponents(entity)

    if ( EntityService:HasComponent( entity, "DisplayRadiusComponent" ) ) then
        EntityService:RemoveComponent( entity, "DisplayRadiusComponent" )
    end

    if ( EntityService:HasComponent( entity, "GhostLineCreatorComponent" ) ) then
        EntityService:RemoveComponent( entity, "GhostLineCreatorComponent" )
    end
end

function wall_small_floor_base_tool:DestroyGhostWall()

    if ( self.ghostWall ~= nil) then
        EntityService:RemoveEntity(self.ghostWall)
        self.ghostWall = nil
    end
end

function wall_small_floor_base_tool:OnWorkExecute()

    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function wall_small_floor_base_tool:GetXZSigns(positionStart, positionEnd)

    local xSign = -1
    local zSign = -1

    if( positionEnd.x >= positionStart.x ) then
        xSign = 1
    end

    if( positionEnd.z >= positionStart.z ) then
        zSign = 1
    end

    return xSign, zSign
end

function wall_small_floor_base_tool:AddToEntitiesToSellList(testBuildable)

    if( testBuildable == nil or testBuildable.flag ~= CBF_OVERRIDES ) then

        return
    end

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        if ( entityToSell ~= nil and EntityService:IsAlive( entityToSell) ) then

            if ( IndexOf( self.oldBuildingsToSell, entityToSell ) == nil ) then

                local skinned = EntityService:IsSkinned(entityToSell)

                if ( skinned ) then
                    EntityService:SetMaterial( entityToSell, "selector/hologram_active_skinned", "selected")
                else
                    EntityService:SetMaterial( entityToSell, "selector/hologram_active", "selected")
                end

                Insert(self.oldBuildingsToSell, entityToSell)
            end
        end
    end
end

function wall_small_floor_base_tool:CheckEntityBuildable( entity, transform, id )

    id = id or 1
    local test = nil

    test = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, self.wallBlueprintName, id )

    if ( test == nil ) then
        return
    end

    local testBuildable = reflection_helper(test:ToTypeInstance(), test )

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

function wall_small_floor_base_tool:BuildEntity(entity, createCube, ignoreRandomRotation)

    createCube = createCube or false
    ignoreRandomRotation = ignoreRandomRotation or false

    local transform = EntityService:GetWorldTransform( entity )

    local testBuildable = self:CheckEntityBuildable( entity , transform )

    if ( testBuildable == nil ) then

        return
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

    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

    elseif( testBuildable.flag == CBF_OVERRIDES ) then

        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end

        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube )

    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function wall_small_floor_base_tool:OnActivateSelectorRequest()
end

function wall_small_floor_base_tool:OnDeactivateSelectorRequest()
end

function wall_small_floor_base_tool:OnRotateSelectorRequest(evt)
end

function wall_small_floor_base_tool:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
            local children = EntityService:GetChildren( entityToSell, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
    end
    self.oldBuildingsToSell = {}
end

function wall_small_floor_base_tool:OnRelease()

    self:RemoveMaterialFromOldBuildingsToSell()

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    self:DestroyGhostWall()
end

return wall_small_floor_base_tool 