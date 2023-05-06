require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'wall_area_tool' ( LuaEntityObject )

function wall_area_tool:__init()
    LuaEntityObject.__init(self,self)
end

function wall_area_tool:init()
    
    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function wall_area_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest",     "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest",   "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector,  "RotateSelectorRequest",      "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "selector/hologram_blue" )
    EntityService:SetVisible( self.entity , false )

    self.nowBuildingLine = false
    self.gridEntities = {}
    self.oldBuildingsToSell = {}

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.wallBlueprintName = self:GetWallBlueprintName( selectorDB )

    self:SpawnWallTemplates( self.wallBlueprintName )

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)
end

function wall_area_tool:GetWallBlueprintName( selectorDB )

    local defaultWall = "buildings/defense/wall_small_straight_01"

    local blueprintName = selectorDB:GetStringOrDefault("$selected_wall_small_blueprint", defaultWall)

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return defaultWall
    end

    if ( not BuildingService:IsBuildingAvailable( blueprintName ) ) then
        return defaultWall
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return defaultWall
    end

    local buildingRef = reflection_helper( buildingDesc )
    if ( buildingRef == nil ) then
        return defaultWall
    end

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    if ( #list == 0 ) then
        return defaultWall
    end

    return blueprintName
end

function wall_area_tool:SpawnWallTemplates(wallBlueprintName)

    --local markerDB = EntityService:GetDatabase( self.markerEntity )
    --markerDB:SetString("message_text", "")
    --markerDB:SetInt("message_visible", 0)

    local buildingDesc = reflection_helper( BuildingService:GetBuildingDesc( wallBlueprintName ) )

    local transform = EntityService:GetWorldTransform( self.entity )

    local position = transform.position
    local orientation = transform.orientation

    local team = EntityService:GetTeam( self.entity )

    local buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.ghost_bp, self.selector )

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )
    EntityService:SetOrientation( buildingEntity, orientation )

    EntityService:ChangeMaterial( buildingEntity, "selector/hologram_blue" )

    self.ghostBlueprintName = buildingDesc.ghost_bp
    
    self.buildingDesc = buildingDesc
    self.ghostWall = buildingEntity
end

function wall_area_tool:OnWorkExecute()

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

    self.buildCost = {}

    if ( self.nowBuildingLine and self.buildStartPosition ) then

        local positionY = self.buildStartPosition.position.y
    
        local team = EntityService:GetTeam(self.entity)
    
        local currentTransform = EntityService:GetWorldTransform( self.entity )
        
        local buildEndPosition = currentTransform.position
        
        local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition )
        
        if ( self.gridEntities == nil ) then
            self.gridEntities = {}
        end
        
        local positionX, positionZ

        if ( #self.gridEntities > #arrayX ) then
        
            for xIndex=#self.gridEntities,#arrayX + 1,-1 do
            
                local gridEntitiesZ = self.gridEntities[xIndex]
                
                for zIndex=1,#gridEntitiesZ do
                
                    EntityService:RemoveEntity(gridEntitiesZ[zIndex])
                    
                    gridEntitiesZ[zIndex] = nil
                end
                
                self.gridEntities[xIndex] = nil
            end
            
        elseif ( #self.gridEntities < #arrayX ) then
        
            for xIndex=#self.gridEntities + 1 ,#arrayX do
                
                positionX = arrayX[xIndex]
            
                local gridEntitiesZ = {}
                
                self.gridEntities[xIndex] = gridEntitiesZ
                
                for zIndex=1,#arrayZ do
                
                    positionZ = arrayZ[zIndex]
            
                    local newPosition = {}
                    
                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team)
                    
                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end
        
        for xIndex=1,#arrayX do
                
            positionX = arrayX[xIndex]
        
            local gridEntitiesZ = self.gridEntities[xIndex]
            
            if ( #gridEntitiesZ > #arrayZ ) then
            
                for zIndex=#gridEntitiesZ,#arrayZ + 1,-1 do 
                    EntityService:RemoveEntity(gridEntitiesZ[zIndex])
                    gridEntitiesZ[zIndex] = nil
                end
                
            elseif ( #gridEntitiesZ < #arrayZ ) then
            
                for zIndex=#gridEntitiesZ + 1 ,#arrayZ do
                
                    positionZ = arrayZ[zIndex]
            
                    local newPosition = {}
                    
                    newPosition.x = positionX
                    newPosition.y = positionY
                    newPosition.z = positionZ

                    local lineEnt = self:CreateNewEntity(newPosition, currentTransform.orientation, team)
                    
                    Insert(gridEntitiesZ, lineEnt)
                end
            end
        end
        
        for xIndex=1,#arrayX do
        
            positionX = arrayX[xIndex]
            
            local gridEntitiesZ = self.gridEntities[xIndex]
            
            for zIndex=1,#arrayZ do
                
                positionZ = arrayZ[zIndex]
        
                local newPosition = {}
                
                newPosition.x = positionX
                newPosition.y = positionY
                newPosition.z = positionZ
                
                local transform = {}
                transform.scale = currentTransform.scale
                transform.orientation = currentTransform.orientation
                transform.position = newPosition
                
                local lineEnt = gridEntitiesZ[zIndex];
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetOrientation( lineEnt, transform.orientation )
                
                local id = (xIndex -1 ) * #arrayX + zIndex
                
                local testBuildable = self:CheckEntityBuildable( lineEnt, transform, id )

                if ( testBuildable ~= nil) then    
                    self:AddToEntitiesToSellList(testBuildable)
                end
                
                BuildingService:CheckAndFixBuildingConnection(lineEnt)
            end
        end

        local list = BuildingService:GetBuildCosts( self.wallBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
               self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #arrayX * #arrayZ ) 
        end
    else

        local currentTransform = EntityService:GetWorldTransform( self.entity )
        local testBuildable = self:CheckEntityBuildable( self.ghostWall, currentTransform )
    
        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end
        
        --BuildingService:CheckAndFixBuildingConnection(self.ghostWall)
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

function wall_area_tool:CreateNewEntity(newPosition, orientation, team)

    local result = nil

    if ( self.ghostBlueprintName ~= "" and self.ghostBlueprintName ~= nil ) then

        result = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
    else
        result = EntityService:SpawnEntity( self.wallBlueprintName, newPosition, team )
    end

    EntityService:RemoveComponent( result, "LuaComponent" )
    EntityService:SetOrientation( result, orientation )

    EntityService:ChangeMaterial( result, "selector/hologram_blue" )

    return result
end

function wall_area_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

    local gridSize = BuildingService:GetBuildingGridSize(self.ghostWall)

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)
    
    local deltaX = gridSize.x * 2 * xSign
    local deltaZ = gridSize.z * 2 * zSign

    local smallDeltaX = (gridSize.x * xSign) / 2
    local smallDeltaZ = (gridSize.z * zSign) / 2

    local buildEndPositionX = buildEndPosition.x + smallDeltaX
    local buildEndPositionZ = buildEndPosition.z + smallDeltaZ
    
    local minX = math.min( buildStartPosition.x, buildEndPositionX )
    local maxX = math.max( buildStartPosition.x, buildEndPositionX )
    
    local minZ = math.min( buildStartPosition.z, buildEndPositionZ )
    local maxZ = math.max( buildStartPosition.z, buildEndPositionZ )
    
    local arrayX = {}
    
    local positionX = buildStartPosition.x
    
    while (minX <= positionX and positionX <= maxX) do
    
        Insert(arrayX, positionX)
        
        positionX = positionX + deltaX
    end
    
    local arrayZ = {}
    
    local positionZ = buildStartPosition.z

    while (minZ <= positionZ and positionZ <= maxZ) do
    
        Insert(arrayZ, positionZ)
        
        positionZ = positionZ + deltaZ
    end
    
    return arrayX, arrayZ
end

function wall_area_tool:GetXZSigns(positionStart, positionEnd)
                
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

function wall_area_tool:AddToEntitiesToSellList(testBuildable)

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

function wall_area_tool:CheckEntityBuildable( entity, transform, id )

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

function wall_area_tool:BuildEntity(entity, createCube)

    createCube = createCube or false

    local transform = EntityService:GetWorldTransform( entity )
       
    local testBuildable = self:CheckEntityBuildable( entity , transform )

    if ( testBuildable == nil ) then

        return
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

function wall_area_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then
    
        self.nowBuildingLine = true;
    
        local transform = EntityService:GetWorldTransform( self.ghostWall )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.ghostWall , false )
        
        self:OnWorkExecute()
    else
        self:FinishLineBuild() 
    end
end

function wall_area_tool:OnDeactivateSelectorRequest()
    self:FinishLineBuild()

    self:RemoveMaterialFromOldBuildingsToSell()
end

function wall_area_tool:OnRotateSelectorRequest(evt)

end

function wall_area_tool:FinishLineBuild()

    if ( self.nowBuildingLine == nil ) then
        self.nowBuildingLine = false
    end

    if ( self.nowBuildingLine ~= true ) then
    
        return
    end
    
    local allEntities = self:GetAllEntities()
    
    local count = #allEntities
    
    if ( count > 0 ) then

        local step = count

        if ( count > 5 )  then
            local additionalCubesCount = math.ceil( count / 5 ) 
            step = math.ceil( count / additionalCubesCount) 
        end

        for i=1,count do

            local createCube = (i == 1 or i == count or i % step == 0)
            
            local ghost = allEntities[i]
            
            self:BuildEntity(ghost, createCube)
            
            EntityService:RemoveEntity(ghost)
        end
    end

    EntityService:SetVisible( self.ghostWall , true )

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false;
end

function wall_area_tool:GetAllEntities()

    local result = {}

    for xIndex=1,#self.gridEntities do
        
        local gridEntitiesZ = self.gridEntities[xIndex]
        
        for zIndex=1,#gridEntitiesZ do
        
            local entity = gridEntitiesZ[zIndex]
            
            Insert(result, entity)
        end
    end
    
    return result
end

function wall_area_tool:RemoveMaterialFromOldBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial(entityToSell, "selected" )
        end
    end
end

function wall_area_tool:OnRelease()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghost in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghost)
            end
        end
    end
    
    self.gridEntities = {}
    self.nowBuildingLine = false
    self.buildStartPosition = nil

    self:RemoveMaterialFromOldBuildingsToSell()

    self.oldBuildingsToSell = {}

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
    end

    if ( self.ghostWall ~= nil) then
        EntityService:RemoveEntity(self.ghostWall)
        self.ghostWall = nil
    end
end

return wall_area_tool
 