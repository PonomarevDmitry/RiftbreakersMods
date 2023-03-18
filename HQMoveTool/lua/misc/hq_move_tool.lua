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

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity , false )
    
    self.markerEntity = EntityService:SpawnAndAttachEntity( "misc/marker_selector_hq_move_tool", self.selector )
    
    self.hq = nil
    
    self.annoucements = { 
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",
        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",
        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium" 
    }

    self:SpawnBuildinsTemplates()

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
end

function hq_move_tool:SpawnBuildinsTemplates()

    local markerDB = EntityService:GetDatabase( self.markerEntity )
    
    local findResult = FindService:FindEntityByName( "headquarters" )

    if ( findResult == nil or findResult == INVALID_ID ) then
        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_not_found")
        markerDB:SetInt("message_visible", 1)
        return
    end

    if ( not BuildingService:IsBuildingFinished( findResult ) ) then
        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_building_now")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local hqBlueprint = EntityService:GetBlueprintName( findResult )

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( hqBlueprint )
    local buildingDesc = reflection_helper( blueprintBuildingDesc )

    local nextUpgradeResearch = ""

    if ( buildingDesc.upgrade ~= "" and buildingDesc.upgrade ~= nil ) then

        local nextUpgrade = buildingDesc.upgrade

        nextUpgradeResearch = self:GetResearchForUpgrade( nextUpgrade )

        if ( self:CanUpgrade( findResult, buildingDesc, nextUpgradeResearch ) ) then
            markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_not_upgraded")
            markerDB:SetInt("message_visible", 1)
            return
        end
    end

    self.nextUpgradeResearch = nextUpgradeResearch

    local baseDesc = BuildingService:FindBaseBuilding( "buildings/main/headquarters" )
    if (baseDesc ~= nil ) then

        local baseDescRef = reflection_helper( baseDesc )

        self.base_min_radius_effect = baseDescRef.min_radius_effect
    end

    self.base_min_radius_effect = self.base_min_radius_effect or ""

    self.hq = findResult

    local skinned = EntityService:IsSkinned( self.hq )
    if ( skinned ) then
        EntityService:SetMaterial( self.hq, "selector/hologram_active_skinned", "selected")
    else
        EntityService:SetMaterial( self.hq, "selector/hologram_active", "selected")
    end

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

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )
    
    self.buildingDesc = buildingDesc
    self.ghostHQ = buildingEntity
    self.hqBlueprint = hqBlueprint


    local gridSize = BuildingService:GetBuildingGridSize( self.hq )

    EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z)

    markerDB:SetString("message_text", "")
    markerDB:SetInt("message_visible", 0)
end

function hq_move_tool:GetResearchForUpgrade( nextUpgrade )

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )
    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == nextUpgrade then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function hq_move_tool:OnWorkExecute()

    if ( self.hq ~= nil and self:CanUpgrade( self.hq, self.buildingDesc, self.nextUpgradeResearch ) ) then

        local markerDB = EntityService:GetDatabase( self.markerEntity )

        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_not_upgraded")
        markerDB:SetInt("message_visible", 1)

        EntityService:RemoveMaterial( self.hq, "selected" )
        self.hq = nil

        if ( self.ghostHQ ~= nil ) then
            EntityService:RemoveEntity(self.ghostHQ)
            self.ghostHQ = nil
        end
    end

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    self:CheckEntityBuildable( self.entity, currentTransform, self.blueprint )

    self.buildCost = {}

    if ( self.ghostHQ ~= nil ) then

        EntityService:SetPosition( self.ghostHQ, currentTransform.position )

        local currentTransform = EntityService:GetWorldTransform( self.ghostHQ )

        currentTransform.position = currentTransform.position

        local testBuildable = self:CheckEntityBuildable( self.ghostHQ, currentTransform, self.hqBlueprint )

        BuildingService:CheckAndFixBuildingConnection( self.ghostHQ )

        self:GetFullBuildCosts( self.buildCost )
    end

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
        EntityService:SetPosition( self.infoChild, -1, 0, 1)
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function hq_move_tool:GetFullBuildCosts( buildCost )

    local targetBlueprintName = self.buildingDesc.bp

    local baseDesc = BuildingService:FindBaseBuilding( "buildings/main/headquarters" )
    if (baseDesc ~= nil ) then

        local baseDescRef = reflection_helper( baseDesc )

        self:AddBuildCost( buildCost, baseDescRef, targetBlueprintName )
    end
end

function hq_move_tool:AddBuildCost( buildCost, baseDescRef, targetBlueprintName )

    local list = BuildingService:GetBuildCosts( baseDescRef.bp, self.playerId )

    for resourceCost in Iter(list) do

        if ( buildCost[resourceCost.first] == nil ) then
            buildCost[resourceCost.first] = 0
        end

        buildCost[resourceCost.first] = buildCost[resourceCost.first] + resourceCost.second
    end

    if ( baseDescRef.bp == targetBlueprintName ) then
        return
    end

    if ( baseDescRef.upgrade ~= "" and baseDescRef.upgrade ~= nil ) then

        local nextUpgrade = baseDescRef.upgrade

        local nextUpgradeDesc = BuildingService:GetBuildingDesc( nextUpgrade )

        if ( nextUpgradeDesc ~= nil ) then
            local nextUpgradeRef = reflection_helper( nextUpgradeDesc )

            self:AddBuildCost( buildCost, nextUpgradeRef, targetBlueprintName )
        end
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
        EntityService:ChangeMaterial( entity, "selector/hologram_blue")
    else
        EntityService:ChangeMaterial( entity, "selector/hologram_red")
    end

    return testBuildable
end

function hq_move_tool:OnActivateSelectorRequest()

    if ( self.ghostHQ == nil or self.hq == nil ) then
        return
    end

    if ( self:CanUpgrade( self.hq, self.buildingDesc, self.nextUpgradeResearch ) ) then

        local markerDB = EntityService:GetDatabase( self.markerEntity )

        markerDB:SetString("message_text", "gui/hud/messages/hq_move_tool/hq_not_upgraded")
        markerDB:SetInt("message_visible", 1)

        EntityService:RemoveMaterial( self.hq, "selected" )
        self.hq = nil

        if ( self.ghostHQ ~= nil ) then
            EntityService:RemoveEntity(self.ghostHQ)
            self.ghostHQ = nil
        end

        return
    end

    local transformToNewHQ = EntityService:GetWorldTransform( self.ghostHQ )

    local testBuildable = self:CheckEntityBuildable( self.ghostHQ, transformToNewHQ, self.hqBlueprint )

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        if ( missingResources.count  > 1 ) then

            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/not_enough_resources", self.ghostHQ, false )

        elseif ( self.annoucements[missingResources[1]] ~= nil and self.annoucements[missingResources[1]] ~= "" ) then

            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, self.annoucements[missingResources[1]], self.ghostHQ, false )
        end

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

    local buildCost = {}
    
    -- Paying resources
    self:GetFullBuildCosts( buildCost )

    local paidResources = "";

    for resourceName,resourceValue in pairs(buildCost) do

        PlayerService:AddResourceAmount( resourceName, -resourceValue )

        if ( string.len(paidResources) > 0 ) then
            paidResources = paidResources .. "|"
        end

        paidResources = paidResources .. tostring(resourceName) .. ";" .. tostring(resourceValue)
    end

    local builder = EntityService:SpawnEntity( "buildings/tools/hq_move_tool/builder", transformToNewHQ.position, EntityService:GetTeam(self.entity) )

    EntityService:SetOrientation( builder, transformToNewHQ.orientation )
    
    local database = EntityService:GetDatabase( builder )
    
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
    
    EntityService:RemoveMaterial( self.hq, "selected" )
    self.hq = nil

    EntityService:RemoveEntity( self.entity )
end

function hq_move_tool:CanUpgrade( hqEntity, buildingDesc, nextUpgradeResearch )

    if ( hqEntity ~= nil ) then

        if ( BuildingService:CanUpgrade( hqEntity, self.playerId ) ) then
            return true
        end
    end

    if ( nextUpgradeResearch ~= "" and nextUpgradeResearch ~= nil ) then

        if ( PlayerService:IsResearchUnlocked( nextUpgradeResearch ) ) then
            return true
        end
    end

    return false
end

function hq_move_tool:OnDeactivateSelectorRequest()
end

function hq_move_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    -- Inverting rotation
    degree = -degree

    EntityService:Rotate( self.entity, 0.0, 1.0, 0.0, degree )

    if ( self.ghostHQ ~= nil ) then
        EntityService:Rotate( self.ghostHQ, 0.0, 1.0, 0.0, degree )
    end

    self:OnWorkExecute()
end

function hq_move_tool:OnRelease()

    if ( self.hq ~= nil ) then
        EntityService:RemoveMaterial( self.hq, "selected" )
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

    if ( self.markerEntity ~= nil) then
        EntityService:RemoveEntity(self.markerEntity)
    end
end

return hq_move_tool