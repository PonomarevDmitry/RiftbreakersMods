require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'hq_move_tool' ( LuaEntityObject )

function hq_move_tool:__init()
    LuaEntityObject.__init(self,self)
end

function hq_move_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function hq_move_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local buildingComponent = reflection_helper( EntityService:GetComponent( self.entity, "BuildingComponent") )
    self.blueprint = buildingComponent.bp

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )
    EntityService:SetVisible( self.entity , false )

    self.markerEntity = EntityService:SpawnAndAttachEntity( "misc/marker_selector_hq_move_tool", self.selector )

    self.hq = nil
    self.ghostHQ = nil
    self.buildCost = {}

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    local currentScale = EntityService:GetScale(self.entity).x

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -currentScale, 0, currentScale)
    
    ShowBuildingDisplayRadiusAround( self.entity, "buildings/defense/portal" )
    ShowBuildingDisplayRadiusAround( self.entity, "buildings/defense/portal_ghost" )

    self:SpawnBuildinsTemplates()
end

function hq_move_tool:SpawnBuildinsTemplates()

    local markerDB = EntityService:GetOrCreateDatabase( self.markerEntity )

    local findResult = FindService:FindEntityByName( "headquarters" )

    if ( findResult == nil or findResult == INVALID_ID ) then
        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_not_found")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local hqBlueprint = EntityService:GetBlueprintName( findResult )

    local lowName = BuildingService:FindLowUpgrade( hqBlueprint )

    if ( lowName ~= "headquarters" ) then
        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_not_found")
        markerDB:SetInt("message_visible", 1)
        return
    end

    if ( not BuildingService:IsBuildingFinished( findResult ) ) then
        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_building_now")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( hqBlueprint )
    local buildingDesc = reflection_helper( blueprintBuildingDesc )


    local baseDesc = BuildingService:GetBuildingDesc( "buildings/main/headquarters" )
    if (baseDesc ~= nil ) then

        local baseDescRef = reflection_helper( baseDesc )

        self.base_min_radius_effect = baseDescRef.min_radius_effect
    end

    self.base_min_radius_effect = self.base_min_radius_effect or ""

    self.hq = findResult

    self:SetEntitySelectedMaterial( self.hq, "hologram/active" )

    local transform = EntityService:GetWorldTransform( self.hq )

    local position = transform.position
    local orientation = transform.orientation

    local team = EntityService:GetTeam( self.entity )

    local newPosition = EntityService:GetWorldTransform( self.entity ).position

    local buildingEntity = nil

    if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

        buildingEntity = EntityService:SpawnEntity( buildingDesc.ghost_bp, newPosition, team )
    else
        buildingEntity = EntityService:SpawnEntity( buildingDesc.bp, newPosition, team )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    self:ChangeEntityMaterial( buildingEntity, "hologram/blue" )

    self.buildingDesc = buildingDesc
    self.ghostHQ = buildingEntity
    self.hqBlueprint = hqBlueprint

    self.buildCost = self:GetFullBuildCosts( self.buildingDesc.bp )

    local gridSize = BuildingService:GetBuildingGridSize( self.ghostHQ )

    EntityService:SetPosition( self.infoChild, -gridSize.x, 0, gridSize.z)

    EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z)

    markerDB:SetString("message_text", "")
    markerDB:SetInt("message_visible", 0)
end

function hq_move_tool:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function hq_move_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function hq_move_tool:RemoveEntitySelectedMaterial( entity )

    EntityService:RemoveMaterial( entity, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function hq_move_tool:GetFullBuildCosts( targetBlueprintName )

    local buildCost = {}

    local list = BuildingService:GetBuildCosts( targetBlueprintName, self.playerId )

    for resourceCost in Iter(list) do

        if ( buildCost[resourceCost.first] == nil ) then
            buildCost[resourceCost.first] = 0
        end

        buildCost[resourceCost.first] = buildCost[resourceCost.first] + resourceCost.second
    end

    return buildCost
end

function hq_move_tool:OnWorkExecute()

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    self:CheckEntityBuildable( self.entity, currentTransform, self.blueprint )

    if ( self.ghostHQ ~= nil ) then

        EntityService:SetPosition( self.ghostHQ, currentTransform.position )

        local currentTransform = EntityService:GetWorldTransform( self.ghostHQ )

        currentTransform.position = currentTransform.position

        local testBuildable = self:CheckEntityBuildable( self.ghostHQ, currentTransform, self.hqBlueprint )

        BuildingService:CheckAndFixBuildingConnection( self.ghostHQ )
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function hq_move_tool:CheckEntityBuildable( entity, transform, blueprint, id )

    id = id or 1

    local checkStatus = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprint, id)

    if ( checkStatus == nil ) then
        return nil
    end

    local testBuildable = reflection_helper(checkStatus:ToTypeInstance(), checkStatus )

    if ( testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_LIMITS  ) then
        self:ChangeEntityMaterial( entity, "hologram/blue")
    else
        self:ChangeEntityMaterial( entity, "hologram/red")
    end

    return testBuildable
end

function hq_move_tool:OnActivateSelectorRequest()

    if ( self.ghostHQ == nil or self.hq == nil ) then
        return
    end


    local transformToNewHQ = EntityService:GetWorldTransform( self.ghostHQ )

    local testBuildable = self:CheckEntityBuildable( self.ghostHQ, transformToNewHQ, self.hqBlueprint )

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        local soundAnnouncement = "voice_over/announcement/not_enough_resources"

        if ( missingResources.count == 1 ) then

            local singleMissingResource = missingResources[1]

            if ( self.announcements and self.announcements[singleMissingResource] ~= nil and self.announcements[singleMissingResource] ~= "" ) then

                soundAnnouncement = self.announcements[singleMissingResource]
            end
        end

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, soundAnnouncement, self.ghostHQ, false )

        return
    end

    if ( testBuildable.flag == CBF_TO_CLOSE ) then

        if ( self.buildingDesc.min_radius_effect ~= "" ) then
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.buildingDesc.min_radius_effect, self.ghostHQ, false)
        elseif( self.base_min_radius_effect ~= "" ) then
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.base_min_radius_effect, self.ghostHQ, false)
        end

        return
    end

    if ( testBuildable.free_grids.count  ~= 56 ) then
        return
    end

    -- Paying resources

    local paidResources = "";

    local leadingPlayer = PlayerService:GetLeadingPlayer()

    for resourceName,resourceValue in pairs(self.buildCost) do

        PlayerService:AddResourceAmount( leadingPlayer, resourceName, -resourceValue )

        if ( string.len(paidResources) > 0 ) then
            paidResources = paidResources .. "|"
        end

        paidResources = paidResources .. tostring(resourceName) .. ";" .. tostring(resourceValue)
    end

    local builder = EntityService:SpawnEntity( "buildings/main/hq_move_tool/builder", transformToNewHQ.position, EntityService:GetTeam(self.entity) )

    EntityService:SetOrientation( builder, transformToNewHQ.orientation )

    local database = EntityService:GetOrCreateDatabase( builder )

    database:SetInt("playerId", self.playerId )

    database:SetInt("hq", self.hq )
    database:SetInt("ghostHQ", self.ghostHQ )

    database:SetString("paidResources", paidResources )
    database:SetString("hq_blueprint", self.buildingDesc.bp )

    database:SetFloat("position.x", transformToNewHQ.position.x )
    database:SetFloat("position.y", transformToNewHQ.position.y )
    database:SetFloat("position.z", transformToNewHQ.position.z )

    database:SetFloat("orientation.x", transformToNewHQ.orientation.x )
    database:SetFloat("orientation.y", transformToNewHQ.orientation.y )
    database:SetFloat("orientation.z", transformToNewHQ.orientation.z )
    database:SetFloat("orientation.w", transformToNewHQ.orientation.w )

    self.ghostHQ = nil
    self.buildCost = {}

    self:RemoveEntitySelectedMaterial( self.hq )

    QueueEvent("OperateActionMapperRequest", self.hq, "HQMoveToolEnableSellOption", false )

    BuildingService:EnableSellOption( self.hq )

    self.hq = nil

    --local SM_SELECT  = 2
    --QueueEvent( "ChangeSelectorModeRequest", self.selector, SM_SELECT )

    QueueEvent( "LeaveBuildModeRequest", self.selector, false )

    EntityService:RemoveEntity( self.entity )
end

function hq_move_tool:OnDeactivateSelectorRequest()
end

function hq_move_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end


    EntityService:Rotate( self.entity, 0.0, 1.0, 0.0, degree )

    if ( self.ghostHQ ~= nil ) then
        EntityService:Rotate( self.ghostHQ, 0.0, 1.0, 0.0, degree )

        local gridSize = BuildingService:GetBuildingGridSize( self.ghostHQ )

        EntityService:SetPosition( self.infoChild, -gridSize.x, 0, gridSize.z)
    end

    self:OnWorkExecute()
end

function hq_move_tool:OnRelease()
    
    HideBuildingDisplayRadiusAround( self.entity, "buildings/defense/portal" )
    HideBuildingDisplayRadiusAround( self.entity, "buildings/defense/portal_ghost" )

    if ( self.hq ~= nil ) then

        self:RemoveEntitySelectedMaterial( self.hq )

        self.hq = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( self.ghostHQ ~= nil ) then
        EntityService:RemoveEntity(self.ghostHQ)
        self.ghostHQ = nil
    end
    self.buildCost = {}

    if ( self.markerEntity ~= nil) then
        EntityService:RemoveEntity(self.markerEntity)
    end
end

return hq_move_tool