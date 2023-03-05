require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'buildings_saver_tool' ( LuaEntityObject )

function buildings_saver_tool:__init()
    LuaEntityObject.__init(self,self)
end

function buildings_saver_tool:init()
    
    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", {enter="OnWorkEnter", execute="OnWorkExecute", exit="OnWorkExit" } )
    self.stateMachine:ChangeState("working")

    self.massBuildLimitMachine = self:CreateStateMachine()
    self.massBuildLimitMachine:AddState( "working", { execute = "OnMassBuildLimitMachineWorking", interval = 0.05 } )
    self.massBuildLimitMachine:AddState( "idle", { interval = 10.0 } )
    self.massBuildLimitMachine:ChangeState("idle")

    self:InitializeValues()
end

function buildings_saver_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )
    
    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local buildingComponent = reflection_helper(EntityService:GetComponent( self.entity, "BuildingComponent") )
    self.blueprint = buildingComponent.bp 

    self.activated = false
    
    self.annoucements = { 
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",
        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",
        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium" 
    }

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue")

    EntityService:SetVisible( self.entity , false )

    self.template_name = self.data:GetString("template_name")

    self.templateEntities = {}

    self.limitedBuildingsQueue = {}

    self.oldBuildingsToSell = {}

    self.transformXX = 1
    self.transformXZ = 0

    self.transformZX = 0
    self.transformZZ = 1

    local team = EntityService:GetTeam( self.entity )
    local currentTransform = EntityService:GetWorldTransform( self.entity )

    self:SpawnBuildinsTemplates( team, currentTransform.position )

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    local marker = self.data:GetString("marker")

    local markerBlueprint = "misc/marker_selector_buildings_saver_tool_" .. marker
            
    self.markerEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
end

function buildings_saver_tool:SpawnBuildinsTemplates( team, currentPosition )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return
    end

    local templateString = campaignDatabase:GetStringOrDefault( self.template_name, "" )

    LogService:Log("SpawnBuildinsTemplates template_name " .. self.template_name .. " templateString " .. templateString )

    if ( templateString == nil or templateString == "" ) then
        return
    end

    local templatesArray = Split( templateString, "|" )

    for template in Iter( templatesArray ) do
        
        self:SpawnTemplate( template, currentPosition, team )
    end

    local firstBuildingTemplate = self.templateEntities[1]
    local firstEntity = firstBuildingTemplate.entity

    local gridSize = BuildingService:GetBuildingGridSize( firstEntity )

    EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z)
end

function buildings_saver_tool:SpawnTemplate( template, currentPosition, team )

    local valuesArray = Split( template, "," )

    local buildingTemplate = {}

    local blueprintName = valuesArray[1]

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    if ( blueprintBuildingDesc == nil ) then
        return
    end

    local buildingDesc = reflection_helper( blueprintBuildingDesc )

    buildingTemplate.blueprint = blueprintName

    buildingTemplate.positionX = tonumber( valuesArray[2] )
    buildingTemplate.positionZ = tonumber( valuesArray[3] )

    buildingTemplate.orientationX = tonumber( valuesArray[4] )
    buildingTemplate.orientationY = tonumber( valuesArray[5] )
    buildingTemplate.orientationZ = tonumber( valuesArray[6] )
    buildingTemplate.orientationW = tonumber( valuesArray[7] )

    buildingTemplate.buildingDesc = buildingDesc

    local newPosition = {}

    local deltaX, deltaZ = self:GetVectorDelta( buildingTemplate.positionX, buildingTemplate.positionZ )
                
    newPosition.x = currentPosition.x + deltaX
    newPosition.y = currentPosition.y
    newPosition.z = currentPosition.z + deltaZ

    local orientation = {}
                
    orientation.x = buildingTemplate.orientationX
    orientation.y = buildingTemplate.orientationY
    orientation.z = buildingTemplate.orientationZ
    orientation.w = buildingTemplate.orientationW

    buildingTemplate.orientation = orientation

    local buildingEntity = nil

    if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

        buildingEntity = EntityService:SpawnEntity( buildingDesc.ghost_bp, newPosition, team )
    else
        buildingEntity = EntityService:SpawnEntity( buildingDesc.bp, newPosition, team )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    buildingTemplate.entity = buildingEntity

    HideBuildingDisplayRadiusAround( buildingEntity, buildingDesc.ghost_bp )
    HideBuildingDisplayRadiusAround( buildingEntity, buildingDesc.bp )
    HideBuildingDisplayRadiusAround( buildingEntity, buildingEntity )
    
    Insert( self.templateEntities, buildingTemplate )
end

function buildings_saver_tool:GetVectorDelta( positionX, positionZ )
    
    local deltaX = self.transformXX * positionX + self.transformXZ * positionZ
    local deltaZ = self.transformZX * positionX + self.transformZZ * positionZ

    return deltaX, deltaZ
end

function buildings_saver_tool:GetBuildInfo( entity  )
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

function buildings_saver_tool:CheckEntityBuildable( entity, transform, blueprint, id )

    id = id or 1

    local checkStatus = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprint, id)

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

function buildings_saver_tool:OnUpdate()

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

    self.buildCost = {}

    local currentTransform = EntityService:GetWorldTransform( self.entity )
    local currentPosition = currentTransform.position

    self:CheckEntityBuildable( self.entity , currentTransform, self.blueprint )

    for i=1,#self.templateEntities do

        local buildingTemplate = self.templateEntities[i]

        local newPosition = {}

        local deltaX, deltaZ = self:GetVectorDelta( buildingTemplate.positionX, buildingTemplate.positionZ )

        newPosition.x = currentPosition.x + deltaX
        newPosition.y = currentPosition.y
        newPosition.z = currentPosition.z + deltaZ

        local transform = {}

        transform.scale = { x=1, y=1, z=1 }
        transform.orientation = buildingTemplate.orientation
        transform.position = newPosition
            
        local entity = buildingTemplate.entity

        local testBuildable = self:CheckEntityBuildable( entity, transform, buildingTemplate.blueprint, i )

        if ( testBuildable ~= nil) then    
            self:AddToEntitiesToSellList(testBuildable)
        end

        EntityService:SetPosition( entity, newPosition )
        EntityService:SetOrientation(entity, transform.orientation )
        BuildingService:CheckAndFixBuildingConnection(entity)

        HideBuildingDisplayRadiusAround( entity, buildingTemplate.buildingDesc.ghost_bp )
        HideBuildingDisplayRadiusAround( entity, buildingTemplate.buildingDesc.bp )
        HideBuildingDisplayRadiusAround( entity, entity )

        local list = BuildingService:GetBuildCosts( buildingTemplate.blueprint, self.playerId )

        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + resourceCost.second
        end
    end

    if ( self.infoChild == nil ) then
        self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end

    if ( self.activated  ) then

        self:FinishLineBuild( true )
    end
end

function buildings_saver_tool:AddToEntitiesToSellList(testBuildable)

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

function buildings_saver_tool:FinishLineBuild( onlyUnlimited )
    
    local count = #self.templateEntities
    
    if ( count == 0 ) then
        return
    end

    local limitedBuildingsQueuesByName, unlimitedBuildings = self:FilterLimitedAndUnimited( onlyUnlimited )

    if ( #limitedBuildingsQueuesByName > 0 ) then

        if ( self.limitedBuildingsQueue == nil ) then
            self.limitedBuildingsQueue = {}
        end

        for i=1,#limitedBuildingsQueuesByName do

            Insert( self.limitedBuildingsQueue, limitedBuildingsQueuesByName[i] ) 
        end

        self.massBuildLimitMachine:ChangeState("working")
    end

    if ( #unlimitedBuildings > 0 ) then

        for i=1,#unlimitedBuildings do

            local buildingTemplate = unlimitedBuildings[i]
            
            self:BuildEntity(buildingTemplate)
        end
    end
end

function buildings_saver_tool:FilterLimitedAndUnimited( onlyUnlimited )
    
    local limitedBuildingsQueuesByName = {}
    local limitedBuildingsHash = {}

    local unlimitedBuildings = {}

    local count = #self.templateEntities

    local team = EntityService:GetTeam( self.entity )

    for i=1,count do

        local buildingTemplate = self.templateEntities[i]

        local entity = buildingTemplate.entity

        local transform = EntityService:GetWorldTransform( entity )

        local testBuildable = self:CheckEntityBuildable( entity, transform, buildingTemplate.blueprint )

        local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES)

        if ( canBuild ) then

            local buildingDesc = buildingTemplate.buildingDesc

            if ( buildingDesc ~= nil and ( (buildingDesc.limit ~= nil and buildingDesc.limit > 0) or (buildingDesc.map_limit ~= nil and buildingDesc.map_limit > 0) ) ) then

                if ( not onlyUnlimited ) then

                    local blueprintLowName = BuildingService:FindLowUpgrade( buildingTemplate.blueprint )

                    if ( limitedBuildingsHash[blueprintLowName] == nil ) then

                        local newQueue = {}

                        Insert( limitedBuildingsQueuesByName, newQueue )

                        limitedBuildingsHash[blueprintLowName] = newQueue
                    end

                    local lowNameQueue = limitedBuildingsHash[blueprintLowName]

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

                    local doubleBuildingTemplate = {}

                    doubleBuildingTemplate.entity = doubleEntity
                    doubleBuildingTemplate.buildingDesc = buildingTemplate.buildingDesc
                    doubleBuildingTemplate.blueprint = buildingTemplate.blueprint

                    Insert( lowNameQueue, doubleBuildingTemplate )

                end
            else
                Insert( unlimitedBuildings, buildingTemplate )
            end

        end
    end

    return limitedBuildingsQueuesByName, unlimitedBuildings
end

function buildings_saver_tool:BuildEntity(buildingTemplate)

    local entity = buildingTemplate.entity

    local buildingDesc = buildingTemplate.buildingDesc

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
        if ( missingResources.count  > 1 ) then
            QueueEvent("PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/not_enough_resources", entity, false )
        elseif ( self.annoucements[missingResources[1]] ~= nil and self.annoucements[missingResources[1]] ~= "" ) then
            QueueEvent("PlayTimeoutSoundRequest",INVALID_ID, 5.0, self.annoucements[missingResources[1]],entity , false )
        end
        
        return testBuildable.flag
    end
        
    local buildingComponent = reflection_helper( EntityService:GetComponent( entity, "BuildingComponent" ) )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then
        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true )
    elseif( testBuildable.flag == CBF_OVERRIDES ) then
        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent("SellBuildingRequest", entityToSell, self.playerId, false )
        end
        QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, true )
    elseif( testBuildable.flag == CBF_REPAIR  ) then
        QueueEvent("ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId)
    end

    return testBuildable.flag
end

function buildings_saver_tool:OnWorkEnter()
end

function buildings_saver_tool:OnWorkExit()
end

function buildings_saver_tool:OnWorkExecute()
    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function buildings_saver_tool:OnActivateSelectorRequest()
    self.activated = true
    if ( self.OnActivate ) then
        self:OnActivate()
    end
end

function buildings_saver_tool:OnDeactivateSelectorRequest()
    self.activated = false
    if ( self.OnDeactivate ) then
        self:OnDeactivate()
    end
end

function buildings_saver_tool:OnActivate()

    self:FinishLineBuild( false )    
end

function buildings_saver_tool:OnDeactivate()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function buildings_saver_tool:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
        end
    end
end

function buildings_saver_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    for buildingTemplate in Iter(self.templateEntities) do
    
        EntityService:Rotate( buildingTemplate.entity, 0.0, 1.0, 0.0, -degree )

        local transform = EntityService:GetWorldTransform( buildingTemplate.entity )

        buildingTemplate.orientation = transform.orientation
    end

    local coefAA = 1 
    local coefAB = 0
    local coefBA = 0
    local coefBB = 1

    if ( degree > 0 ) then

        -- clockwise
        coefAA = 0 
        coefAB = -1
        coefBA = 1
        coefBB = 0
    else

        -- counter-clockwise

        coefAA = 0 
        coefAB = 1
        coefBA = -1
        coefBB = 0
    end

    local newtransformXX, newtransformXZ, newtransformZX, newtransformZZ = self:TrasformMatrix( coefAA, coefAB, coefBA, coefBB )

    self.transformXX = newtransformXX
    self.transformXZ = newtransformXZ
    self.transformZX = newtransformZX
    self.transformZZ = newtransformZZ

    self:OnUpdate()
end

function buildings_saver_tool:TrasformMatrix( coefAA, coefAB, coefBA, coefBB)

    local newtransformXX = self.transformXX * coefAA + self.transformXZ * coefBA
    local newtransformXZ = self.transformXX * coefAB + self.transformXZ * coefBB
    local newtransformZX = self.transformZX * coefAA + self.transformZZ * coefBA
    local newtransformZZ = self.transformZX * coefAB + self.transformZZ * coefBB

    return newtransformXX, newtransformXZ, newtransformZX, newtransformZZ
end

function buildings_saver_tool:OnRelease()

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

    if ( self.limitedBuildingsQueue ~= nil) then
        for arrayBuildings in Iter(self.limitedBuildingsQueue) do
            for ghostBuildingTemplate in Iter(arrayBuildings) do
                EntityService:RemoveEntity(ghostBuildingTemplate.entity)
                ghostBuildingTemplate.entity = nil
            end
        end
    end

    self.limitedBuildingsQueue = {}

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}
end

function buildings_saver_tool:OnMassBuildLimitMachineWorking( state )

    if ( self.limitedBuildingsQueue == nil ) then
        self.limitedBuildingsQueue = {}
    end

    if ( #self.limitedBuildingsQueue == 0 ) then
        self.massBuildLimitMachine:ChangeState("idle")
        return
    end

    local buildinsTemplatesArray = self.limitedBuildingsQueue[1]

    if ( #buildinsTemplatesArray == 0) then

        Remove( self.limitedBuildingsQueue, buildinsTemplatesArray )
        return
    end

    local ghostBuildingTemplate = buildinsTemplatesArray[1]
    Remove( buildinsTemplatesArray, ghostBuildingTemplate )

    local testBuildableFlag = self:BuildEntity(ghostBuildingTemplate)
    EntityService:RemoveEntity(ghostBuildingTemplate.entity)

    if ( #buildinsTemplatesArray == 0) then

        Remove( self.limitedBuildingsQueue, buildinsTemplatesArray )
        return
    end

    if( testBuildableFlag == CBF_LIMITS ) then

        if ( #buildinsTemplatesArray > 0 ) then

            for index=1,#buildinsTemplatesArray do
                local ghostBuildingTemplate = buildinsTemplatesArray[index]
                EntityService:RemoveEntity(ghostBuildingTemplate.entity)
            end

            Remove( self.limitedBuildingsQueue, buildinsTemplatesArray )
        end
    end
end

return buildings_saver_tool