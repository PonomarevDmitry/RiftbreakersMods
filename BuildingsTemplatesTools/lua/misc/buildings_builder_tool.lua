require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'buildings_builder_tool' ( LuaEntityObject )

function buildings_builder_tool:__init()
    LuaEntityObject.__init(self,self)
end

function buildings_builder_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { enter="OnWorkEnter", execute="OnWorkExecute", exit="OnWorkExit" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function buildings_builder_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    local marker = self.data:GetString("marker")
    self.template_name = self.data:GetString("template_name")

    self.templateEntities = {}
    self.oldBuildingsToSell = {}

    -- Identity matrix
    --   X Z
    -- X 1 0
    -- Z 0 1
    self.transformXX = 1
    self.transformXZ = 0

    self.transformZX = 0
    self.transformZZ = 1

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local buildingComponent = reflection_helper( EntityService:GetComponent( self.entity, "BuildingComponent" ) )
    self.blueprint = buildingComponent.bp

    self.activated = false

    self.annoucements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity, false )

    local markerBlueprint = "misc/marker_selector_buildings_builder_tool_" .. marker
    self.markerEntity = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )

    self:SpawnBuildinsTemplates()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
end

function buildings_builder_tool:SpawnBuildinsTemplates()

    self.buildCost = {}

    -- templateString format:
    -- blueprint1:ent1PosX,ent1PosZ,ent1OrientY,ent1OrientW;ent2PosX,ent2PosZ,ent2OrientY,ent2OrientW|blueprint2:ent3PosX,ent3PosZ,ent3OrientY,ent3OrientW;ent4PosX,ent4PosZ,ent4OrientY,ent4OrientW

    -- Delimiter between blueprints groups: "|"
    -- Delimiter between blueprint name and array of entities coordinates: ":"
    -- Delimiter between entities in array of entities coordinates: ";"
    -- Delimiter between coordinates for single entity: ","
    -- blueprint1, blueprint2 - blueprints names

    -- ent1PosX, ent2PosX, ent3PosX, ent4PosX - entities relative position.x
    -- ent1PosZ, ent2PosZ, ent3PosZ, ent4PosZ - entities relative position.z

    -- ent1OrientY, ent2OrientY, ent3OrientY, ent4OrientY - entities orientation.y
    -- ent1OrientW, ent2OrientW, ent3OrientW, ent4OrientW - entities orientation.w

    local markerDB = EntityService:GetDatabase( self.markerEntity )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local templateString = campaignDatabase:GetStringOrDefault( self.template_name, "" )
    templateString = templateString or ""

    --LogService:Log("SpawnBuildinsTemplates template_name " .. self.template_name .. " templateString " .. templateString )

    if ( templateString == "" ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/empty_template")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local team = EntityService:GetTeam( self.entity )
    local currentPosition = EntityService:GetWorldTransform( self.entity ).position

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    -- Split by "|" blueprints groups
    local blueprintsGroupsArray = Split( templateString, delimiterBlueprintsGroups )

    for template in Iter( blueprintsGroupsArray ) do

        -- Split by ":" blueprint template
        local blueprintValuesArray = Split( template, delimiterBlueprintName )

        -- Only 2 values in blueprintValuesArray
        if ( #blueprintValuesArray ~= 2 ) then
            goto continue
        end

        -- First blueprintName
        local blueprintName = blueprintValuesArray[1]
        -- Second array with entities coordinates
        local entitiesCoordinatesString = blueprintValuesArray[2]

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
            goto continue
        end

        if ( not BuildingService:IsBuildingAvailable( blueprintName ) ) then
            goto continue
        end

        local blueprintBuildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        if ( blueprintBuildingDesc == nil ) then
            goto continue
        end

        local buildingDesc = reflection_helper( blueprintBuildingDesc )

        if ( buildingDesc == nil ) then
            goto continue
        end

        local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )

        if ( #list == 0 ) then
            goto continue
        end

        --  Do not create cubes for building_mode "line"
        local createCube = not ( buildingDesc.building_mode == "line" )

        -- Split array of coordinates by ";"
        local entitiesCoordinatesArray = Split( entitiesCoordinatesString, delimiterEntitiesArray )

        for entityString in Iter( entitiesCoordinatesArray ) do

            self:CreateSingleBuildingTemplate( blueprintName, buildingDesc, createCube, entityString, list, delimiterBetweenCoordinates )
        end

        ::continue::
    end

    if ( #self.templateEntities > 0 ) then

        if ( #self.templateEntities > 1 ) then

            for i=2,#self.templateEntities do

                local buildingTemplate = self.templateEntities[i]

                EntityService:RemoveComponent( buildingTemplate.entity, "DisplayRadiusComponent" )
            end
        end

        local firstBuildingTemplate = self.templateEntities[1]
        local firstEntity = firstBuildingTemplate.entity

        local gridSize = BuildingService:GetBuildingGridSize( firstEntity )

        EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z )

        markerDB:SetString("message_text", "")
        markerDB:SetInt("message_visible", 0)
    else
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/building_impossible")
        markerDB:SetInt("message_visible", 1)
    end
end

function buildings_builder_tool:CreateSingleBuildingTemplate( blueprintName, buildingDesc, createCube, entityString, list, delimiterBetweenCoordinates )

    -- Split coordinates by ","
    local valuesArray = Split( entityString, delimiterBetweenCoordinates )

    -- Only 4 values in valuesArray
    if ( #valuesArray ~= 4 ) then
        return
    end

    local positionX = tonumber( valuesArray[1] )
    local positionZ = tonumber( valuesArray[2] )

    local orientationY = tonumber( valuesArray[3] )
    local orientationW = tonumber( valuesArray[4] )

    -- Parse to number successful
    if ( positionX == nil or positionZ == nil or orientationY == nil or orientationW == nil ) then
        return
    end

    local buildingTemplate = {}

    buildingTemplate.blueprint = blueprintName

    for resourceCost in Iter( list ) do

        if ( self.buildCost[resourceCost.first] == nil ) then
            self.buildCost[resourceCost.first] = 0
        end

        self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + resourceCost.second
    end

    buildingTemplate.buildingDesc = buildingDesc
    buildingTemplate.createCube = createCube

    buildingTemplate.positionX = positionX
    buildingTemplate.positionZ = positionZ

    local orientation = {}

    orientation.x = 0
    orientation.y = orientationY
    orientation.z = 0
    orientation.w = orientationW

    buildingTemplate.orientation = orientation

    local deltaX, deltaZ = self:GetVectorDelta( positionX, positionZ )

    local newPosition = {}

    newPosition.x = deltaX
    newPosition.y = 0
    newPosition.z = deltaZ

    local buildingEntity = nil

    if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

        buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.ghost_bp, self.selector )
    else
        buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.bp, self.selector )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )

    EntityService:SetPosition( buildingEntity, newPosition )
    EntityService:SetOrientation( buildingEntity, orientation )

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    buildingTemplate.entity = buildingEntity

    Insert( self.templateEntities, buildingTemplate )
end

function buildings_builder_tool:GetVectorDelta( positionX, positionZ )

    local deltaX = self.transformXX * positionX + self.transformXZ * positionZ
    local deltaZ = self.transformZX * positionX + self.transformZZ * positionZ

    return deltaX, deltaZ
end

function buildings_builder_tool:GetBuildInfo( entity  )
    local buildInfoComponent = EntityService:GetComponent( entity, "BuildInfoComponent")
    if ( not Assert( buildInfoComponent ~= nil ,"ERROR: missing build info component!") ) then
        return nil
    end
    if (buildInfoComponent == nil ) then
        return nil
    end
    local helper = reflection_helper(buildInfoComponent)
    return helper.build_info
end

function buildings_builder_tool:CheckEntityBuildable( entity, transform, blueprintName, id )

    id = id or 1

    local checkStatus = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprintName, id)

    if ( checkStatus == nil ) then
        return nil
    end

    local testBuildable = reflection_helper(checkStatus:ToTypeInstance(), checkStatus )


    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_OVERRIDES or testBuildable.flag == CBF_REPAIR)

    local skinned = EntityService:IsSkinned(entity)

    if ( testBuildable.flag == CBF_REPAIR  ) then

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
        elseif ( canBuild  ) then
            EntityService:ChangeMaterial( entity, "selector/hologram_blue")
        else
            EntityService:ChangeMaterial( entity, "selector/hologram_red")
        end
    end

    return testBuildable
end

function buildings_builder_tool:OnUpdate()

    local buildingsToSell = {}

    for i=1,#self.templateEntities do

        local buildingTemplate = self.templateEntities[i]

        local entity = buildingTemplate.entity

        local transform = EntityService:GetWorldTransform( entity )

        local testBuildable = self:CheckEntityBuildable( entity, transform, buildingTemplate.blueprint, i )

        if ( testBuildable ~= nil ) then
            self:AddToEntitiesToSellList( testBuildable, buildingsToSell )
        end
    end

    for entity in Iter( self.oldBuildingsToSell ) do

        if ( IndexOf( buildingsToSell, entity ) == nil ) then
            EntityService:RemoveMaterial(entity, "selected" )
        end
    end

    for entity in Iter( buildingsToSell ) do

        local skinned = EntityService:IsSkinned(entity)

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
        end
    end

    self.oldBuildingsToSell = buildingsToSell



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

    if ( self.activated  ) then

        self:FinishLineBuild()
    end
end

function buildings_builder_tool:AddToEntitiesToSellList(testBuildable, buildingsToSell)

    if( testBuildable == nil or testBuildable.flag ~= CBF_OVERRIDES ) then

        return
    end

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        if ( entityToSell ~= nil and EntityService:IsAlive( entityToSell) ) then

            if ( IndexOf( buildingsToSell, entityToSell ) == nil ) then

                Insert( buildingsToSell, entityToSell )
            end
        end
    end
end

function buildings_builder_tool:FinishLineBuild()

    local count = #self.templateEntities

    if ( count == 0 ) then
        return
    end

    local limitedBuildingsQueuesByName, unlimitedBuildings = self:FilterLimitedAndUnimited()

    if ( #limitedBuildingsQueuesByName > 0 ) then

        for allEntities in Iter( limitedBuildingsQueuesByName ) do

            local delimiterEntities = "|"

            local entitiesListArray = {}

            for entityId in Iter( allEntities ) do

                if ( #entitiesListArray > 0 ) then

                    Insert( entitiesListArray, delimiterEntities )
                end

                local entityString = tostring(entityId)

                Insert( entitiesListArray, entityString )
            end

            local entitiesListString = table.concat( entitiesListArray )

            local builder = EntityService:SpawnEntity( "misc/mass_limited_buildings_builder", self.entity, "" )

            local database = EntityService:GetDatabase( builder )

            database:SetInt( "playerId", self.playerId )

            database:SetString( "entities_list", entitiesListString )
        end
    end

    if ( #unlimitedBuildings > 0 ) then

        for i=1,#unlimitedBuildings do

            local buildingTemplate = unlimitedBuildings[i]

            self:BuildEntity(buildingTemplate)
        end
    end
end

function buildings_builder_tool:FilterLimitedAndUnimited()

    local limitedBuildingsQueuesByName = {}
    local limitedBuildingsHash = {}

    local unlimitedBuildings = {}

    local team = EntityService:GetTeam( self.entity )

    for buildingTemplate in Iter( self.templateEntities ) do

        local entity = buildingTemplate.entity

        local transform = EntityService:GetWorldTransform( entity )

        local testBuildable = self:CheckEntityBuildable( entity, transform, buildingTemplate.blueprint )

        local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

        if ( canBuild ) then

            local buildingDesc = buildingTemplate.buildingDesc

            if ( buildingDesc ~= nil and ( (buildingDesc.limit ~= nil and buildingDesc.limit > 0) or (buildingDesc.map_limit ~= nil and buildingDesc.map_limit > 0) ) ) then

                local entityTransform = EntityService:GetWorldTransform( buildingTemplate.entity )

                local newPosition = entityTransform.position
                local newOrientation = entityTransform.orientation

                local doubleEntity = nil

                if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

                    doubleEntity = EntityService:SpawnEntity( buildingDesc.ghost_bp, newPosition, team )
                else
                    doubleEntity = EntityService:SpawnEntity( buildingDesc.bp, newPosition, team )
                end

                EntityService:RemoveComponent( doubleEntity, "LuaComponent" )
                EntityService:SetPosition( doubleEntity, newPosition )
                EntityService:SetOrientation( doubleEntity, newOrientation )
                EntityService:ChangeMaterial( doubleEntity, "selector/hologram_blue" )



                local limitName = buildingDesc.limit_name or ""

                if ( limitName == "" ) then

                    limitName = BuildingService:FindLowUpgrade( buildingTemplate.blueprint )
                end

                if ( limitedBuildingsHash[limitName] == nil ) then

                    local newQueue = {}

                    Insert( limitedBuildingsQueuesByName, newQueue )

                    limitedBuildingsHash[limitName] = newQueue
                end

                local limitNameQueue = limitedBuildingsHash[limitName]

                Insert( limitNameQueue, doubleEntity )
            else
                Insert( unlimitedBuildings, buildingTemplate )
            end
        end
    end

    return limitedBuildingsQueuesByName, unlimitedBuildings
end

function buildings_builder_tool:BuildEntity(buildingTemplate)

    local entity = buildingTemplate.entity

    local buildingDesc = buildingTemplate.buildingDesc

    local createCube = false

    if ( buildingTemplate.createCube ~= nil ) then
        createCube = buildingTemplate.createCube
    end

    local transform = EntityService:GetWorldTransform( entity )

    local testBuildable = self:CheckEntityBuildable( entity , transform, buildingTemplate.blueprint )

    if ( testBuildable == nil ) then
        return
    end

    if ( testBuildable.flag == CBF_TO_CLOSE ) then

        if ( buildingDesc.min_radius_effect ~= "" ) then
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, buildingDesc.min_radius_effect, entity, false)
        end

        return testBuildable.flag

    elseif( testBuildable.flag == CBF_LIMITS ) then

        QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", entity, false )

        return testBuildable.flag
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count  > 0 ) then

        local soundAnnouncement = "voice_over/announcement/not_enough_resources"

        if ( missingResources.count  == 1 ) then

            local singleMissingResource = missingResources[1]

            if ( self.annoucements[singleMissingResource] ~= nil and self.annoucements[singleMissingResource] ~= "" ) then

                soundAnnouncement = self.annoucements[singleMissingResource]
            end
        end

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, soundAnnouncement, entity, false )

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
    elseif( testBuildable.flag == CBF_REPAIR  ) then
        QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
    end

    return testBuildable.flag
end

function buildings_builder_tool:OnWorkEnter()
end

function buildings_builder_tool:OnWorkExit()
end

function buildings_builder_tool:OnWorkExecute()
    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function buildings_builder_tool:OnActivateSelectorRequest()
    self.activated = true
    if ( self.OnActivate ) then
        self:OnActivate()
    end
end

function buildings_builder_tool:OnDeactivateSelectorRequest()
    self.activated = false
    if ( self.OnDeactivate ) then
        self:OnDeactivate()
    end
end

function buildings_builder_tool:OnActivate()

    self:FinishLineBuild()
end

function buildings_builder_tool:OnDeactivate()

    self:RemoveMaterialFromBuildingsToSell()
end

function buildings_builder_tool:RemoveMaterialFromBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
        end
    end
end

function buildings_builder_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    -- Inverting rotation
    degree = -degree

    EntityService:Rotate( self.entity, 0.0, 1.0, 0.0, degree )

    -- Identity matrix
    --   A B
    -- A 1 0
    -- B 0 1
    local coefAA = 1
    local coefAB = 0
    local coefBA = 0
    local coefBB = 1

    if ( degree > 0 ) then

        -- counter-clockwise matrix
        --    A B
        -- A  0 1
        -- B -1 0

        coefAA = 0
        coefAB = 1
        coefBA = -1
        coefBB = 0
    else

        -- clockwise matrix
        --   A  B
        -- A 0 -1
        -- B 1  0

        coefAA = 0
        coefAB = -1
        coefBA = 1
        coefBB = 0
    end

    local newtransformXX = self.transformXX * coefAA + self.transformXZ * coefBA
    local newtransformXZ = self.transformXX * coefAB + self.transformXZ * coefBB
    local newtransformZX = self.transformZX * coefAA + self.transformZZ * coefBA
    local newtransformZZ = self.transformZX * coefAB + self.transformZZ * coefBB

    self.transformXX = newtransformXX
    self.transformXZ = newtransformXZ
    self.transformZX = newtransformZX
    self.transformZZ = newtransformZZ

    for buildingTemplate in Iter(self.templateEntities) do

        EntityService:Rotate( buildingTemplate.entity, 0.0, 1.0, 0.0, degree )

        local deltaX, deltaZ = self:GetVectorDelta( buildingTemplate.positionX, buildingTemplate.positionZ )

        local newPosition = {}
        newPosition.x = deltaX
        newPosition.y = 0
        newPosition.z = deltaZ

        local entity = buildingTemplate.entity

        EntityService:SetPosition( buildingTemplate.entity, newPosition )

        local transform = EntityService:GetWorldTransform( buildingTemplate.entity )

        buildingTemplate.orientation = transform.orientation
    end
end

function buildings_builder_tool:OnRelease()

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
    end

    if ( self.markerEntity ~= nil) then
        EntityService:RemoveEntity(self.markerEntity)
    end

    for buildingTemplate in Iter(self.templateEntities) do

        EntityService:RemoveEntity(buildingTemplate.entity)
        buildingTemplate.entity = nil
    end

    self.templateEntities = {}

    self:RemoveMaterialFromBuildingsToSell()

    self.oldBuildingsToSell = {}
end

return buildings_builder_tool