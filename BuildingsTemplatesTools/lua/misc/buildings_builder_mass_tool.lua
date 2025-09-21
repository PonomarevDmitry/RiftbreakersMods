require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
local TemplatesSerializeUtils = require("lua/misc/buildings_serialize_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_builder_mass_tool' ( LuaEntityObject )

function buildings_builder_mass_tool:__init()
    LuaEntityObject.__init(self,self)
end

function buildings_builder_mass_tool:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()
end

function buildings_builder_mass_tool:InitializeValues()

    self.selector = EntityService:GetParent( self.entity )

    self.marker = self.data:GetString("marker")
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
    self:RegisterHandler( self.selector, "RotateSelectorRequest",       "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent( self.selector, "PlayerReferenceComponent" ) )
    self.playerId = playerReferenceComponent.player_id

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    local buildingComponent = reflection_helper( EntityService:GetComponent( self.entity, "BuildingComponent" ) )
    self.blueprint = buildingComponent.bp

    self.activated = false

    self.announcements = {
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

    self:ChangeEntityMaterial( self.entity, "hologram/blue" )
    EntityService:SetVisible( self.entity, false )

    local markerBlueprint = "misc/marker_selector_buildings_builder_mass_tool"
    self.markerEntity = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )

    local number = tonumber(self.marker)
    local firstNumber = math.floor( number / 10 )
    local secondNumber = number % 10

    if ( firstNumber ~= 0 ) then
        markerBlueprint = "misc/marker_buildings_templates_numbers_" .. tostring(firstNumber) .. "x"
        self.firstNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)
    end

    markerBlueprint = "misc/marker_buildings_templates_numbers_x" .. tostring(secondNumber)
    self.secondNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1 )

    self.blockGridSize = {}
    self.blockGridSize.x = 0
    self.blockGridSize.z = 0

    self:SpawnBuildinsTemplates()

    self.nowBuildingLine = false
    self.gridEntities = {}

    self.configNameCellGaps = "$buildings_builder_mass_tool_cell_count_" .. self.marker

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.cellGapsCount = selectorDB:GetIntOrDefault(self.configNameCellGaps, 0)
    self.cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

    self.markerGapsConfig = -1
    self.currentMarkerGaps = nil
    self.currentMarkerGapsMinus = nil
end

function buildings_builder_mass_tool:SpawnBuildinsTemplates()

    self.buildCostOriginal = {}

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

    local markerDB = EntityService:GetOrCreateDatabase( self.markerEntity )

    local globalPlayerEntityDB, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntityDB == nil and selectorDB == nil and campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

    local templateString = BuildingsTemplatesUtils:GetTemplateString(self.template_name, campaignDatabase, selectorDB)

    if ( templateString == "" ) then

        local templateCaption = "gui/hud/building_templates/template_" .. self.marker

        local markerText = "${" .. templateCaption .. "}: ${gui/hud/messages/building_templates/empty_template}"

        markerDB:SetString("message_text", markerText)
        markerDB:SetInt("menu_visible", 1)
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

        --if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        --    goto continue
        --end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
            goto continue
        end

        local buildCosts = BuildingService:GetBuildCosts( blueprintName, self.playerId )
        --if ( #buildCosts == 0 ) then
        --    goto continue
        --end

        -- Do not create cubes for building_mode "line"
        local createCube = not ( buildingDescRef.building_mode == "line" )

        -- Split array of coordinates by ";"
        local entitiesCoordinatesArray = Split( entitiesCoordinatesString, delimiterEntitiesArray )

        for entityString in Iter( entitiesCoordinatesArray ) do

            self:CreateSingleBuildingTemplate( blueprintName, buildingDescRef, createCube, entityString, buildCosts, delimiterBetweenCoordinates )
        end

        ::continue::
    end

    if ( #self.templateEntities > 0 ) then

        if ( #self.templateEntities > 1 ) then

            for i=2,#self.templateEntities do

                local buildingTemplate = self.templateEntities[i]

                if ( EntityService:HasComponent( buildingTemplate.entity, "DisplayRadiusComponent" ) ) then

                    EntityService:RemoveComponent( buildingTemplate.entity, "DisplayRadiusComponent" )
                end

                if ( EntityService:HasComponent( buildingTemplate.entity, "GhostLineCreatorComponent" ) ) then

                    EntityService:RemoveComponent( buildingTemplate.entity, "GhostLineCreatorComponent" )
                end
            end
        end

        local firstBuildingTemplate = self.templateEntities[1]
        local firstEntity = firstBuildingTemplate.entity

        local gridSize = BuildingService:GetBuildingGridSize( firstEntity )

        EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z )

        EntityService:SetPosition( self.infoChild, -gridSize.x, 0, gridSize.z )

        markerDB:SetString("message_text", "")
        markerDB:SetInt("menu_visible", 0)

        local minX = 0
        local maxX = 0

        local minZ = 0
        local maxZ = 0

        for i=1,#self.templateEntities do

            local buildingTemplate = self.templateEntities[i]

            local positionX, positionZ = self:GetVectorDelta( buildingTemplate.positionX, buildingTemplate.positionZ )

            local gridSize = BuildingService:GetBuildingGridSize( buildingTemplate.entity )

            minX = math.min( minX , positionX - gridSize.x )
            maxX = math.max( maxX , positionX + gridSize.x )

            minZ = math.min( minZ , positionZ - gridSize.z )
            maxZ = math.max( maxZ , positionZ + gridSize.z )
        end

        self.blockGridSize.x = maxX - minX
        self.blockGridSize.z = maxZ - minZ
    else
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/building_impossible")
        markerDB:SetInt("menu_visible", 1)
    end
end

function buildings_builder_mass_tool:CreateSingleBuildingTemplate( blueprintName, buildingDesc, createCube, entityString, buildCosts, delimiterBetweenCoordinates )

    -- Split coordinates by ","
    local valuesArray = Split( entityString, delimiterBetweenCoordinates )

    -- Only 4 values in valuesArray
    if ( #valuesArray < 4 ) then
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

    local databaseInfo = valuesArray[5]

    local buildingTemplate = {}

    buildingTemplate.blueprint = blueprintName
    buildingTemplate.databaseInfo = databaseInfo

    for resourceCost in Iter( buildCosts ) do

        if ( self.buildCostOriginal[resourceCost.first] == nil ) then
            self.buildCostOriginal[resourceCost.first] = 0
        end

        self.buildCostOriginal[resourceCost.first] = self.buildCostOriginal[resourceCost.first] + resourceCost.second
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

    self:ChangeEntityMaterial( buildingEntity, "hologram/blue" )

    buildingTemplate.entity = buildingEntity

    Insert( self.templateEntities, buildingTemplate )
end

function buildings_builder_mass_tool:GetVectorDelta( positionX, positionZ )

    local deltaX = self.transformXX * positionX + self.transformXZ * positionZ
    local deltaZ = self.transformZX * positionX + self.transformZZ * positionZ

    return deltaX, deltaZ
end

function buildings_builder_mass_tool:CheckEntityBuildable( entity, transform, blueprintName, id )

    id = id or 1

    local checkStatus = BuildingService:CheckGhostBuildingStatus( self.playerId, entity, transform, blueprintName, id )

    if ( checkStatus == nil ) then
        return nil
    end

    local testBuildable = reflection_helper( checkStatus:ToTypeInstance(), checkStatus )


    local canBuildOverride = (testBuildable.flag == CBF_OVERRIDES)
    local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_OVERRIDES or testBuildable.flag == CBF_REPAIR)

    local materialToSet = "hologram/blue"

    if ( testBuildable.flag == CBF_REPAIR  ) then

        if ( BuildingService:CanAffordRepair( testBuildable.entity_to_repair, self.playerId, -1 ) ) then

            materialToSet = "hologram/pass"

        else

            materialToSet = "hologram/deny"
        end
    else

        if ( canBuildOverride ) then

            materialToSet = "hologram/active"

        elseif ( canBuild  ) then

            materialToSet = "hologram/blue"

        else

            materialToSet = "hologram/red"
        end

        self:ChangeEntityMaterial( entity, materialToSet )
    end

    return testBuildable
end

function buildings_builder_mass_tool:OnUpdate()

    local cellGapsCount = self:CheckConfigExists(self.cellGapsCount)

    if ( self.markerGapsConfig ~= cellGapsCount or self.currentMarkerGaps == nil) then

        if (self.currentMarkerGaps ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerGaps)
            self.currentMarkerGaps = nil
        end

        local markerBlueprint = "misc/marker_selector_gaps_count_" .. tostring( math.abs( cellGapsCount ) )

        self.currentMarkerGaps = EntityService:SpawnAndAttachEntity( markerBlueprint, self.selector )
        EntityService:SetPosition( self.currentMarkerGaps, 0, 0, -2 )


        if ( cellGapsCount < 0 ) then

            if (self.currentMarkerGapsMinus == nil) then

                self.currentMarkerGapsMinus = EntityService:SpawnAndAttachEntity( "misc/marker_selector_gaps_minus", self.selector )
                EntityService:SetPosition( self.currentMarkerGapsMinus, 0, 0, -2 )
            end

        else

            if (self.currentMarkerGapsMinus ~= nil) then

                EntityService:RemoveEntity(self.currentMarkerGapsMinus)
                self.currentMarkerGapsMinus = nil
            end
        end

        self.markerGapsConfig = cellGapsCount
    end

    self.buildCost = {}

    local buildingsToSell = {}


    if ( #self.templateEntities > 0 ) then

        if ( self.nowBuildingLine and self.buildStartPosition ) then

            local positionY = self.buildStartPosition.position.y

            local team = EntityService:GetTeam(self.entity)

            local currentTransform = EntityService:GetWorldTransform( self.entity )

            local buildEndPosition = currentTransform.position

            local arrayX, arrayZ = self:FindPositionsToBuildLine( self.buildStartPosition.position, buildEndPosition, cellGapsCount )

            self.gridEntities = self.gridEntities or {}

            local positionX, positionZ

            if ( #self.gridEntities > #arrayX ) then

                for xNumber=#self.gridEntities,#arrayX + 1,-1 do

                    local gridEntitiesZ = self.gridEntities[xNumber]

                    for zNumber=1,#gridEntitiesZ do

                        local buildingTemplateBlock = gridEntitiesZ[zNumber]
                        for buildingTemplate in Iter( buildingTemplateBlock.templatesArray ) do

                            EntityService:RemoveEntity(buildingTemplate.entity)
                        end

                        gridEntitiesZ[zNumber] = nil
                    end

                    self.gridEntities[xNumber] = nil
                end

            elseif ( #self.gridEntities < #arrayX ) then

                for xNumber=#self.gridEntities + 1 ,#arrayX do

                    positionX = arrayX[xNumber]

                    local gridEntitiesZ = {}

                    self.gridEntities[xNumber] = gridEntitiesZ

                    for zNumber=1,#arrayZ do

                        positionZ = arrayZ[zNumber]

                        local newPosition = {}

                        newPosition.x = positionX
                        newPosition.y = positionY
                        newPosition.z = positionZ

                        local lineEnt = self:CreateNewTemplateBlock(newPosition, team)

                        Insert(gridEntitiesZ, lineEnt)
                    end
                end
            end

            for xNumber=1,#arrayX do

                positionX = arrayX[xNumber]

                local gridEntitiesZ = self.gridEntities[xNumber]

                if ( #gridEntitiesZ > #arrayZ ) then

                    for zNumber=#gridEntitiesZ,#arrayZ + 1,-1 do

                        local buildingTemplateBlock = gridEntitiesZ[zNumber]
                        for buildingTemplate in Iter( buildingTemplateBlock.templatesArray ) do

                            EntityService:RemoveEntity(buildingTemplate.entity)
                        end

                        gridEntitiesZ[zNumber] = nil
                    end

                elseif ( #gridEntitiesZ < #arrayZ ) then

                    for zNumber=#gridEntitiesZ + 1 ,#arrayZ do

                        positionZ = arrayZ[zNumber]

                        local newPosition = {}

                        newPosition.x = positionX
                        newPosition.y = positionY
                        newPosition.z = positionZ

                        local lineEnt = self:CreateNewTemplateBlock(newPosition, team)

                        Insert(gridEntitiesZ, lineEnt)
                    end
                end
            end

            local idCheckBuildable = 1

            for xNumber=1,#arrayX do

                positionX = arrayX[xNumber]

                local gridEntitiesZ = self.gridEntities[xNumber]

                for zNumber=1,#arrayZ do

                    positionZ = arrayZ[zNumber]

                    local buildingTemplateBlock = gridEntitiesZ[zNumber]

                    for buildingTemplate in Iter( buildingTemplateBlock.templatesArray ) do

                        local lineEnt = buildingTemplate.entity

                        local deltaX, deltaZ = self:GetVectorDelta( buildingTemplate.positionX, buildingTemplate.positionZ )

                        local newPosition = {}

                        newPosition.x = positionX + deltaX
                        newPosition.y = positionY
                        newPosition.z = positionZ + deltaZ

                        local currentTransform = EntityService:GetWorldTransform( buildingTemplate.parentTemplate.entity )

                        local transform = {}
                        transform.scale = currentTransform.scale
                        transform.orientation = currentTransform.orientation
                        transform.position = newPosition

                        EntityService:SetPosition( lineEnt, newPosition)
                        EntityService:SetOrientation( lineEnt, currentTransform.orientation )

                        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, buildingTemplate.blueprint, idCheckBuildable )

                        if ( testBuildable ~= nil ) then
                            self:AddToEntitiesToSellList( testBuildable, buildingsToSell )
                        end

                        BuildingService:CheckAndFixBuildingConnection(lineEnt)

                        idCheckBuildable = idCheckBuildable + 1
                    end
                end
            end

            for resourceName, amount in pairs( self.buildCostOriginal ) do

                self.buildCost[resourceName] = amount * #arrayX * #arrayZ
            end

        else

            for i=1,#self.templateEntities do

                local buildingTemplate = self.templateEntities[i]

                local entity = buildingTemplate.entity

                local transform = EntityService:GetWorldTransform( entity )

                local testBuildable = self:CheckEntityBuildable( entity, transform, buildingTemplate.blueprint, i )

                if ( testBuildable ~= nil ) then
                    self:AddToEntitiesToSellList( testBuildable, buildingsToSell )
                end
            end

            self.buildCost = self.buildCostOriginal
        end

    end







    for entity in Iter( self.oldBuildingsToSell ) do

        if ( IndexOf( buildingsToSell, entity ) == nil ) then
            EntityService:RemoveMaterial( entity, "selected" )
            local children = EntityService:GetChildren( entity, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
    end

    for entity in Iter( buildingsToSell ) do

        self:SetEntitySelectedMaterial( entity, "hologram/active" )
    end

    self.oldBuildingsToSell = buildingsToSell



    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end
end

function buildings_builder_mass_tool:ChangeEntityMaterial( entity, material )

    EntityService:ChangeMaterial( entity, material )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:ChangeMaterial( child, material )
        end
    end
end

function buildings_builder_mass_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function buildings_builder_mass_tool:CreateNewTemplateBlock(newPosition, team)

    local result = {}

    result.position = newPosition
    result.templatesArray = {}

    for buildingTemplate in Iter( self.templateEntities ) do

        local newBuildingTemplate = {}

        newBuildingTemplate.parentTemplate = buildingTemplate

        newBuildingTemplate.blueprint = buildingTemplate.blueprint
        newBuildingTemplate.databaseInfo = buildingTemplate.databaseInfo

        newBuildingTemplate.buildingDesc = buildingTemplate.buildingDesc
        newBuildingTemplate.createCube = buildingTemplate.createCube

        newBuildingTemplate.positionX = buildingTemplate.positionX
        newBuildingTemplate.positionZ = buildingTemplate.positionZ

        newBuildingTemplate.orientation = buildingTemplate.orientation

        local currentTransform = EntityService:GetWorldTransform( buildingTemplate.entity )

        local orientation = currentTransform.orientation

        local deltaX, deltaZ = self:GetVectorDelta( newBuildingTemplate.positionX, newBuildingTemplate.positionZ )

        local newBuildingTemplatePosition = {}

        newBuildingTemplatePosition.x = newPosition.x + deltaX
        newBuildingTemplatePosition.y = newPosition.y
        newBuildingTemplatePosition.z = newPosition.z + deltaZ

        local buildingEntity = nil

        if ( newBuildingTemplate.buildingDesc.ghost_bp ~= "" and newBuildingTemplate.buildingDesc.ghost_bp ~= nil ) then

            buildingEntity = EntityService:SpawnEntity( newBuildingTemplate.buildingDesc.ghost_bp, newBuildingTemplatePosition, team )
        else
            buildingEntity = EntityService:SpawnEntity( newBuildingTemplate.buildingDesc.bp, newBuildingTemplatePosition, team )
        end

        EntityService:RemoveComponent( buildingEntity, "LuaComponent" )

        EntityService:SetPosition( buildingEntity, newBuildingTemplatePosition )
        EntityService:SetOrientation( buildingEntity, orientation )

        self:ChangeEntityMaterial( buildingEntity, "hologram/blue" )

        newBuildingTemplate.entity = buildingEntity

        if ( EntityService:HasComponent( newBuildingTemplate.entity, "DisplayRadiusComponent" ) ) then

            EntityService:RemoveComponent( newBuildingTemplate.entity, "DisplayRadiusComponent" )
        end

        if ( EntityService:HasComponent( newBuildingTemplate.entity, "GhostLineCreatorComponent" ) ) then

            EntityService:RemoveComponent( newBuildingTemplate.entity, "GhostLineCreatorComponent" )
        end

        Insert(result.templatesArray, newBuildingTemplate)
    end

    return result
end

function buildings_builder_mass_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition, cellGapsCount)

    local gridSize = self.blockGridSize

    local xSign, zSign = self:GetXZSigns(buildStartPosition, buildEndPosition)

    local deltaX = gridSize.x + cellGapsCount * 2
    local deltaZ = gridSize.z + cellGapsCount * 2

    if ( deltaX <= 0 ) then
        deltaX = 2
    end

    if ( deltaZ <= 0 ) then
        deltaZ = 2
    end

    deltaX = deltaX * xSign
    deltaZ = deltaZ * zSign

    local smallDeltaX = (gridSize.x * xSign) / 4
    local smallDeltaZ = (gridSize.z * zSign) / 4

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

function buildings_builder_mass_tool:GetXZSigns(positionStart, positionEnd)

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

function buildings_builder_mass_tool:AddToEntitiesToSellList(testBuildable, buildingsToSell)

    if( testBuildable == nil or testBuildable.flag ~= CBF_OVERRIDES ) then

        return
    end

    local buildingToSellCount = testBuildable.entities_to_sell.count

    for i = 1,buildingToSellCount do

        local entityToSell = testBuildable.entities_to_sell[i]

        if ( entityToSell ~= nil and EntityService:IsAlive( entityToSell ) ) then

            if ( IndexOf( buildingsToSell, entityToSell ) == nil ) then

                Insert( buildingsToSell, entityToSell )
            end
        end
    end
end

function buildings_builder_mass_tool:FinishLineBuild()

    if ( #self.templateEntities > 0 ) then

        local allTemplates = self:GetAllTemplates()

        local limitedBuildingsQueuesByName, unlimitedBuildings, unBuildable = self:FilterLimitedAndUnimited(allTemplates)

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

                local builder = EntityService:SpawnEntity( "misc/templates_mass_limited_buildings_builder", self.entity, "" )

                local database = EntityService:GetOrCreateDatabase( builder )

                database:SetInt( "playerId", self.playerId )

                database:SetString( "entities_list", entitiesListString )
            end
        end

        if ( #unlimitedBuildings > 0 ) then

            for buildingTemplate in Iter( unlimitedBuildings ) do

                self:BuildEntity(buildingTemplate)

                EntityService:RemoveEntity(buildingTemplate.entity)
            end
        end

        if ( #unBuildable > 0 ) then

            for entity in Iter( unBuildable ) do

                EntityService:RemoveEntity(entity)
            end
        end
    end

    for buildingTemplate in Iter(self.templateEntities) do

        EntityService:SetVisible( buildingTemplate.entity , true )
    end

    self.gridEntities = {}
    self.buildStartPosition = nil
    self.nowBuildingLine = false
end

function buildings_builder_mass_tool:GetAllTemplates()

    local result = {}

    for xNumber=1,#self.gridEntities do

        local gridEntitiesZ = self.gridEntities[xNumber]

        for zNumber=1,#gridEntitiesZ do

            local buildingTemplateBlock = gridEntitiesZ[zNumber]

            for buildingTemplate in Iter( buildingTemplateBlock.templatesArray ) do

                Insert(result, buildingTemplate)
            end
        end
    end

    return result
end

function buildings_builder_mass_tool:FilterLimitedAndUnimited(allTemplates)

    local limitedBuildingsQueuesByName = {}
    local limitedBuildingsHash = {}

    local unlimitedBuildings = {}

    local unBuildable = {}

    local team = EntityService:GetTeam( self.entity )

    for buildingTemplate in Iter( allTemplates ) do

        local entity = buildingTemplate.entity

        local transform = EntityService:GetWorldTransform( entity )

        local testBuildable = self:CheckEntityBuildable( entity, transform, buildingTemplate.blueprint )

        local canBuild = (testBuildable.flag == CBF_CAN_BUILD or testBuildable.flag == CBF_ONE_GRID_FLOOR or testBuildable.flag == CBF_OVERRIDES or testBuildable.flag == CBF_REPAIR)

        if ( canBuild ) then

            local buildingDesc = buildingTemplate.buildingDesc

            if ( buildingDesc ~= nil and buildingDesc.limit ~= nil and buildingDesc.limit > 0 ) then

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

                Insert( limitNameQueue, entity )

                if ( buildingTemplate.databaseInfo ~= nil and buildingTemplate.databaseInfo ~= "" ) then

                    self:TransferDatabaseInfoFromTemplateToEntity(buildingTemplate.databaseInfo, entity)
                end
            else
                Insert( unlimitedBuildings, buildingTemplate )
            end
        else
            Insert( unBuildable, entity )
        end
    end

    return limitedBuildingsQueuesByName, unlimitedBuildings, unBuildable
end

function buildings_builder_mass_tool:BuildEntity(buildingTemplate)

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
            QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, buildingDesc.min_radius_effect, self.playerEntity, false )
        end

        return testBuildable.flag

    elseif( testBuildable.flag == CBF_LIMITS ) then

        QueueEvent( "PlayTimeoutSoundRequest", INVALID_ID, 5.0, "voice_over/announcement/building_limit", self.playerEntity, false )

        return testBuildable.flag
    end

    local missingResources = testBuildable.missing_resources
    if ( missingResources.count > 0 ) then

        local soundAnnouncement = "voice_over/announcement/not_enough_resources"

        if ( missingResources.count == 1 ) then

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

        self:CreateRuinsBeforeBuilding(buildingTemplate.databaseInfo, buildingComponent.bp, transform)

        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )
    elseif( testBuildable.flag == CBF_OVERRIDES ) then
        for entityToSell in Iter(testBuildable.entities_to_sell) do
            QueueEvent( "SellBuildingRequest", entityToSell, self.playerId, false )
        end

        self:CreateRuinsBeforeBuilding(buildingTemplate.databaseInfo, buildingComponent.bp, transform)

        QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, buildingComponent.bp, transform, createCube, {} )
    elseif( testBuildable.flag == CBF_REPAIR and testBuildable.entity_to_repair ~= nil and testBuildable.entity_to_repair ~= INVALID_ID ) then

        QueueEvent( "ScheduleRepairBuildingRequest", testBuildable.entity_to_repair, self.playerId )
    end

    return testBuildable.flag
end

function buildings_builder_mass_tool:CreateRuinsBeforeBuilding(databaseInfoString, blueprintName, transform)

    if ( databaseInfoString == nil or databaseInfoString == "" ) then
        return
    end

    local ruinsBlueprint = blueprintName .. "_ruins"

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
        return
    end

    local team = EntityService:GetTeam( self.entity )

    local newRuinsEntity = EntityService:SpawnEntity( ruinsBlueprint, transform.position, team )

    local playerReferenceRef = reflection_helper( EntityService:CreateComponent( newRuinsEntity, "PlayerReferenceComponent" ) )

    playerReferenceRef.player_id = self.playerId
    playerReferenceRef.reference_type.internal_enum = 4

    EntityService:SetOrientation( newRuinsEntity, transform.orientation )
    EntityService:RemoveComponent( newRuinsEntity, "LuaComponent" )

    self:TransferDatabaseInfoFromTemplateToEntity(databaseInfoString, newRuinsEntity)
end

function buildings_builder_mass_tool:TransferDatabaseInfoFromTemplateToEntity(databaseInfoString, entity)

    if ( databaseInfoString == nil or databaseInfoString == "" ) then
        return
    end

    local databaseInfo = TemplatesSerializeUtils:DeserializeObject( databaseInfoString )
    if ( databaseInfo == nil ) then
        return
    end

    local database = EntityService:GetOrCreateDatabase( entity )
    if ( database == nil ) then
        return
    end

    database:SetInt("$building_has_databaseInfo", 1)

    if ( databaseInfo.databaseStringValues ) then
        for key, value in pairs( databaseInfo.databaseStringValues ) do
            database:SetString(key, value)
        end
    end

    if ( databaseInfo.databaseFloatValues ) then
        for key, value in pairs( databaseInfo.databaseFloatValues ) do
            database:SetFloat(key, value)
        end
    end

    if ( databaseInfo.databaseIntValues ) then
        for key, value in pairs( databaseInfo.databaseIntValues ) do
            database:SetInt(key, value)
        end
    end

    if ( databaseInfo.databaseVectorValues ) then
        for key, vector in pairs( databaseInfo.databaseVectorValues ) do

            local newVectorX, newVectorZ = self:GetVectorDelta( vector.x, vector.z )

            local newVector = {
                y = vector.y,
                x = newVectorX,
                z = newVectorZ
            }

            database:SetVector(key, newVector)
        end
    end
end

function buildings_builder_mass_tool:OnWorkExecute()
    if ( self.OnUpdate ) then
        self:OnUpdate()
    end
end

function buildings_builder_mass_tool:OnActivateSelectorRequest()
    self.activated = true
    if ( self.OnActivate ) then
        self:OnActivate()
    end
end

function buildings_builder_mass_tool:OnDeactivateSelectorRequest()
    self.activated = false
    if ( self.OnDeactivate ) then
        self:OnDeactivate()
    end
end

function buildings_builder_mass_tool:OnActivate()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform

        for buildingTemplate in Iter(self.templateEntities) do

            EntityService:SetVisible( buildingTemplate.entity , false )
        end

        self:OnUpdate()
    else
        self:FinishLineBuild()
    end
end

function buildings_builder_mass_tool:OnDeactivate()

    self:FinishLineBuild()

    self:RemoveMaterialFromBuildingsToSell()
end

function buildings_builder_mass_tool:RemoveMaterialFromBuildingsToSell()

    if ( self.oldBuildingsToSell ~= nil ) then
        for entityToSell in Iter( self.oldBuildingsToSell ) do
            EntityService:RemoveMaterial( entityToSell, "selected" )
            local children = EntityService:GetChildren( entityToSell, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
        self.oldBuildingsToSell = {}
    end
end

function buildings_builder_mass_tool:OnRotateSelectorRequest(evt)

    self.nowBuildingLine = self.nowBuildingLine or false

    if ( self.nowBuildingLine ) then
        self:ChangeCellsGapsCount(evt)
    else
        self:RotateEntityTemplates(evt)
    end
end

function buildings_builder_mass_tool:RotateEntityTemplates(evt)

    local degree = evt:GetDegree()

    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end


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

    if ( self.blockGridSize ~= nil ) then

        local sizeX = self.blockGridSize.x
        local sizeZ = self.blockGridSize.z

        self.blockGridSize.x = sizeZ
        self.blockGridSize.z = sizeX
    end

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

    if ( #self.templateEntities > 0 ) then

        local firstBuildingTemplate = self.templateEntities[1]
        local firstEntity = firstBuildingTemplate.entity

        local gridSize = BuildingService:GetBuildingGridSize( firstEntity )

        EntityService:SetPosition( self.infoChild, -gridSize.x, 0, gridSize.z )
    end
end

function buildings_builder_mass_tool:ChangeCellsGapsCount(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentGapsConfig = self:CheckConfigExists(self.cellGapsCount)

    local scaleWallGaps = self:GetGapsConfigArray()

    local index = IndexOf( scaleWallGaps, currentGapsConfig )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #scaleWallGaps

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex < 1 ) then
        newIndex = 1
    end

    local newValue = scaleWallGaps[newIndex]

    self.cellGapsCount = newValue

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    selectorDB:SetInt(self.configNameCellGaps, newValue)

    self:OnUpdate()
end

function buildings_builder_mass_tool:CheckConfigExists( cellGapsCount )

    local scaleWallGaps = self:GetGapsConfigArray()

    cellGapsCount = cellGapsCount or scaleWallGaps[1]

    local index = IndexOf(scaleWallGaps, cellGapsCount )

    if ( index == nil ) then

        return scaleWallGaps[1]
    end

    return cellGapsCount
end

function buildings_builder_mass_tool:GetGapsConfigArray()

    if ( self.scaleWallGaps == nil ) then

        self.scaleWallGaps = {
            -6,
            -5,
            -4,
            -3,
            -2,
            -1,
            0,
            1,
            2,
            3,
            4,
            5,
            6,
        }
    end

    return self.scaleWallGaps
end

function buildings_builder_mass_tool:OnRelease()

    if ( self.infoChild ~= nil ) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( self.markerEntity ~= nil ) then
        EntityService:RemoveEntity(self.markerEntity)
        self.markerEntity = nil
    end

    if ( self.firstNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.firstNumberEntity)
        self.firstNumberEntity = nil
    end

    if ( self.secondNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.secondNumberEntity)
        self.secondNumberEntity = nil
    end

    for buildingTemplate in Iter(self.templateEntities) do

        EntityService:RemoveEntity(buildingTemplate.entity)
        buildingTemplate.entity = nil
    end
    self.templateEntities = {}

    self:RemoveMaterialFromBuildingsToSell()

    if ( self.gridEntities ~= nil) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for buildingTemplateBlock in Iter(gridEntitiesZ) do
                for buildingTemplate in Iter( buildingTemplateBlock.templatesArray ) do

                    EntityService:RemoveEntity(buildingTemplate.entity)
                end
            end
        end
    end
    self.gridEntities = {}

    self.nowBuildingLine = false
    self.buildStartPosition = nil

    if (self.currentMarkerGaps ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerGaps)
        self.currentMarkerGaps = nil
    end

    if (self.currentMarkerGapsMinus ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerGapsMinus)
        self.currentMarkerGapsMinus = nil
    end
end

return buildings_builder_mass_tool