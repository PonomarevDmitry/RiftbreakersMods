local pipe_base_tool = require("lua/buildings/resources/pipe_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'pipe_perimeter_tool' ( pipe_base_tool )

function pipe_perimeter_tool:__init()
    pipe_base_tool.__init(self,self)
end

function pipe_perimeter_tool:InitializeValues()

    pipe_base_tool.InitializeValues(self)

    self.childPos = {}

    self.selectedEntities = {}

    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local scale = self.initialScale
    EntityService:SetScale(self.entity, scale.x, scale.y, scale.z)

    local orientation = {x=0,y=0,z=0,w=1}
    EntityService:SetOrientation( self.entity, orientation )

    self:SpawnCornerBlueprint()

    self.currentScale = scale.x

    self.activated = false
    
    local children = EntityService:GetChildren( self.corners, true )
    for child in Iter(children ) do
        if ( EntityService:GetComponent(child, "GuiComponent") ~= nil ) then
            self.infoChild = child
        end
    end 

    self.scaleMap = {
        1,
        2,
        3,
        4,
        8,
        12,
        16,
        20,
        24,
        28,
        32,
    }
end

function pipe_perimeter_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function pipe_perimeter_tool:OnInit()

    EntityService:SetVisible( self.entity, true )

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_pipe_perimeter_tool", self.entity)

    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    -- Marker with number of pipe layers
    self.markerLinesConfig = 0
    self.currentMarkerLines = nil
    
    self.configNameScale = "$perimeter_pipe_scale"
    self.configNamePipesCount = "$perimeter_pipe_lines_count"

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    -- Pipe layers config
    self.pipeLinesCount = selectorDB:GetIntOrDefault(self.configNamePipesCount, 1)
    self.pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)


    self.currentScale = selectorDB:GetIntOrDefault(self.configNameScale, self.currentScale)

    EntityService:SetScale( self.entity, self.currentScale, 1.0, self.currentScale)

    self:UpdateMarker()
    
    self:SetChildrenPosition()
    self:RescaleChild()
end

function pipe_perimeter_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function pipe_perimeter_tool:UpdateMarker()

    -- Pipe layers config
    local pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)

    -- Correct Marker to show right number of pipe layers
    if ( self.markerLinesConfig ~= pipeLinesCount or self.currentMarkerLines == nil) then

        -- Destroy old marker
        if (self.currentMarkerLines ~= nil) then

            EntityService:RemoveEntity(self.currentMarkerLines)
            self.currentMarkerLines = nil
        end

        local markerBlueprint = "misc/marker_selector_diagonal_pipe_lines_" .. tostring( pipeLinesCount )

        -- Create new marker
        self.currentMarkerLines = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector )
        EntityService:SetPosition( self.currentMarkerLines, 0, 0, -2 )

        -- Save number of pipe layers
        self.markerLinesConfig = pipeLinesCount
    end
end

function pipe_perimeter_tool:OnUpdate()

    self:RescaleChild()

    local selectorComponent = EntityService:GetComponent(self.selector, "BuildingSelectorComponent")

    local previousSelection = self.selectedEntities

    self.selectedEntities = self:FindEntitiesToSelect( reflection_helper(selectorComponent) )

    for ent in Iter( previousSelection ) do 
        if ( IndexOf( self.selectedEntities, ent ) == nil ) then
            self:RemovedFromSelection( ent )
        end
    end
    
    for ent in Iter( self.selectedEntities ) do 

        if ( IndexOf( previousSelection, ent ) == nil ) then

            self:AddedToSelection( ent )
        end
    end

    self:RemoveMaterialFromOldBuildingsToSell()

    self.buildCost = {}

    -- Pipe layers config
    local pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)

    local team = EntityService:GetTeam(self.entity)

    local currentTransform = EntityService:GetWorldTransform( self.entity )

    local newPositionsArray, hashPositions = self:FindPositionsToBuildLine( pipeLinesCount )

    local oldLinesEntities = self.linesEntities
    local oldLinesEntityInfo = self.linesEntityInfo
    local oldGridEntities = self.gridEntities

    local newLinesEntities = {}
    local newLinesEntityInfo = {}
    local newGridEntities = {}

    for i=1,#newPositionsArray do

        local newPosition = newPositionsArray[i]
        newPosition.y = currentTransform.position.y

        local lineEnt = self:GetEntityFromGrid( oldGridEntities, newPosition.x, newPosition.z )

        if ( lineEnt == nil ) then

            lineEnt = EntityService:SpawnEntity( self.ghostBlueprintName, newPosition, team )
            self:ChangeEntityMaterial( lineEnt, "hologram/blue" )
            EntityService:RemoveComponent(lineEnt, "LuaComponent")
            EntityService:RemoveComponent( lineEnt, "GhostLineCreatorComponent" )

            EntityService:SetOrientation(lineEnt, currentTransform.orientation )
            EntityService:SetPosition( lineEnt, newPosition)
        end

        Insert( newLinesEntities, lineEnt )
        self:InsertEntityToGrid( newGridEntities, lineEnt, newPosition.x, newPosition.z  )

        local entityInfo = {}

        entityInfo.position = newPosition
        entityInfo.entity = lineEnt

        Insert( newLinesEntityInfo, entityInfo )
    end

    for i=#oldLinesEntityInfo,1,-1 do

        local entityInfo = oldLinesEntityInfo[i]

        local lineEnt = entityInfo.entity

        local lineEntPosition = entityInfo.position

        if ( not self:HashContains( hashPositions, lineEntPosition.x, lineEntPosition.z ) ) then

            EntityService:RemoveEntity( lineEnt )
            oldLinesEntityInfo[i] = nil
        end
    end

    for i=1,#newLinesEntities do

        local lineEnt = newLinesEntities[i]

        local transform = EntityService:GetWorldTransform( lineEnt )

        local testBuildable = self:CheckEntityBuildable( lineEnt, transform, i )

        if ( testBuildable ~= nil) then
            self:AddToEntitiesToSellList(testBuildable)
        end

        BuildingService:CheckAndFixBuildingConnection( lineEnt )
    end

    self.linesEntities = newLinesEntities
    self.linesEntityInfo = newLinesEntityInfo
    self.gridEntities = newGridEntities


    if ( #newPositionsArray > 0 ) then

        local list = BuildingService:GetBuildCosts( self.pipeBlueprintName, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.buildCost[resourceCost.first] == nil ) then
                self.buildCost[resourceCost.first] = 0
            end

            self.buildCost[resourceCost.first] = self.buildCost[resourceCost.first] + ( resourceCost.second * #newPositionsArray )
        end
    end



    self:CreateInfoChild()

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )

    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
    else
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, {} )
    end

    if ( self.activated )  then
    
        for ent in Iter( self.selectedEntities ) do 
    
            if ( IndexOf( previousSelection, ent ) == nil ) then
    
                self:OnActivateEntity( ent )
            end
        end
    end
end

function pipe_perimeter_tool:FindEntitiesToSelect( selectorComponent )
    local position = selectorComponent.position 
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize, self.currentScale))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize, self.currentScale))
    local possibleSelectedEnts = FindService:FindGridOwnersByBox( min, max )

    local distances = {}
    for entity in Iter( possibleSelectedEnts) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity );    
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(possibleSelectedEnts, sorter)

    local selectedEntities = {}
    for entity in Iter(possibleSelectedEnts ) do
        local selectableComponent = EntityService:GetConstComponent( entity, "SelectableComponent")
        if ( selectableComponent == nil ) then goto continue end
    
        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        
        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode <= 2 ) then goto continue end 
        end
    
        Insert(selectedEntities, entity )
        ::continue::
    end
    
    if ( self.FilterSelectedEntities ) then
        selectedEntities = self:FilterSelectedEntities( selectedEntities )
    end
    
    return selectedEntities
end

function pipe_perimeter_tool:FilterSelectedEntities( selectedEntities ) 

    local result = {}

    for entity in Iter(selectedEntities ) do

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        if ( blueprintName == "buildings/resources/pipe_straight" or blueprintName == "buildings/resources/pipe_straight_windowless" or blueprintName == "buildings/resources/pipe_junction" ) then
            goto labelContinue
        end

        local baseDesc = BuildingService:FindBaseBuilding( blueprintName )
        if  (baseDesc ~= nil ) then

            local baseDescRef = reflection_helper(baseDesc)
            if ( baseDescRef.bp == "buildings/resources/pipe_straight" or baseDescRef.bp == "buildings/resources/pipe_straight_windowless" or baseDescRef.bp == "buildings/resources/pipe_junction" ) then
                goto labelContinue
            end
        end

        local pipeComponent = EntityService:GetComponent(entity, "PipeComponent")
        if ( pipeComponent ~= nil ) then

            Insert( result, entity )

            goto labelContinue
        end

        if ( self:IsBluepringHasAttachments( blueprintName ) ) then

            Insert( result, entity )

            goto labelContinue
        end

        ::labelContinue::
    end

    return result
end

function pipe_perimeter_tool:GetEntityFromGrid( gridEntities, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        return nil
    end

    local arrayXPosition = gridEntities[newPositionX]

    if ( arrayXPosition[newPositionZ] == nil ) then

        return nil
    end

    return arrayXPosition[newPositionZ]
end

function pipe_perimeter_tool:InsertEntityToGrid( gridEntities, lineEnt, newPositionX, newPositionZ )

    if ( gridEntities[newPositionX] == nil) then

        gridEntities[newPositionX] = {}
    end

    local arrayXPosition = gridEntities[newPositionX]

    arrayXPosition[newPositionZ] = lineEnt
end

function pipe_perimeter_tool:HashContains( hashPositions, newPositionX, newPositionZ )

    if ( hashPositions[newPositionX] == nil) then

        return false
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] == nil ) then

        return false
    end

    return true
end

function pipe_perimeter_tool:FindPositionsToBuildLine( pipeLinesCount )

    local result = {}
    local hashPositions = {}

    for entity in Iter( self.selectedEntities ) do

        local gridCullerComponent = EntityService:GetComponent( entity, "GridCullerComponent" )
        if( gridCullerComponent == nil ) then
            goto labelContinue
        end

        local gridCullerComponentRef = reflection_helper(gridCullerComponent)

        local min, max = self:GetEntityMinMax(gridCullerComponentRef)

        if ( min == nil or max == nil ) then
            goto labelContinue
        end

        for i=1,pipeLinesCount do

            min.x = min.x - 2
            min.z = min.z - 2

            max.x = max.x + 2
            max.z = max.z + 2

            local entityPerimeterPositions = self:GetPerimeterPositions( min, max )

            for position in Iter( entityPerimeterPositions ) do

                if ( self:AddToHash(hashPositions, position.x, position.z ) ) then
                
                    Insert(result, position)
                end
            end
        end

        ::labelContinue::
    end

    return result, hashPositions
end

function pipe_perimeter_tool:GetPerimeterPositions( min, max )

    local result = {}

    local value = min.z

    while (value < max.z) do

        local newPosition = {}

        newPosition.x = max.x
        newPosition.z = value

        Insert(result, newPosition)

        value = value + 2
    end
    


    value = max.x

    while (value > min.x) do

        local newPosition = {}

        newPosition.x = value
        newPosition.z = max.z

        Insert(result, newPosition)

        value = value - 2
    end
    


    value = max.z

    while (value > min.z) do

        local newPosition = {}

        newPosition.x = min.x
        newPosition.z = value

        Insert(result, newPosition)

        value = value - 2
    end
    


    value = min.x

    while (value < max.x) do

        local newPosition = {}

        newPosition.x = value
        newPosition.z = min.z

        Insert(result, newPosition)

        value = value + 2
    end

    return result
end

function pipe_perimeter_tool:GetEntityMinMax(gridCullerComponentRef)

    local min = nil
    local max = nil

    local indexes = gridCullerComponentRef.terrain_cell_entities
    for i=indexes.count,1,-1 do

        local idx = indexes[i].id

        local pos = FindService:GetCellOrigin(idx)

        if ( min == nil ) then
            min = {}
            min.x = pos.x
            min.z = pos.z
        end

        if ( max == nil ) then
            max = {}
            max.x = pos.x
            max.z = pos.z
        end

        min.x = math.min(min.x, pos.x)
        min.z = math.min(min.z, pos.z)

        max.x = math.max(max.x, pos.x)
        max.z = math.max(max.z, pos.z)
    end

    return min, max
end

-- Check position has not already been added to hashPositions
function pipe_perimeter_tool:AddToHash(hashPositions, newPositionX, newPositionZ)

    if ( hashPositions[newPositionX] == nil) then

        hashPositions[newPositionX] = {}
    end

    local hashXPosition = hashPositions[newPositionX]

    if ( hashXPosition[newPositionZ] ~= nil ) then

        return false
    end

    hashXPosition[newPositionZ] = true

    return true
end

function pipe_perimeter_tool:IsBluepringHasAttachments( blueprintName )

    self.cacheBlueprints = self.cacheBlueprints or {}

    if ( self.cacheBlueprints[blueprintName] ~= nil ) then

        return self.cacheBlueprints[blueprintName]
    end

    local result = self:CalcIsBluepringHasAttachments( blueprintName )

    self.cacheBlueprints[blueprintName] = result

    return result
end

function pipe_perimeter_tool:CalcIsBluepringHasAttachments( blueprintName )

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local resourceStorageComponent = blueprint:GetComponent( "ResourceStorageComponent")
    if ( resourceStorageComponent ~= nil ) then

        local resourceStorageRef = reflection_helper( resourceStorageComponent )

        if ( self:IsResourceStorageComponentHasAttachments( resourceStorageRef ) ) then

            return true
        end
    end

    local resourceConverterDesc = blueprint:GetComponent("ResourceConverterDesc")
    if ( resourceConverterDesc ~= nil ) then

        local resourceConverterRef = reflection_helper(resourceConverterDesc)
        if ( resourceConverterRef ~= nil ) then

            if ( self:IsResourceConverterDescHasAttachments( resourceConverterRef ) ) then

                return true
            end
        end
    end

    return false
end

function pipe_perimeter_tool:IsResourceStorageComponentHasAttachments( resourceStorageRef )

    if ( resourceStorageRef.Storages == nil or resourceStorageRef.Storages.count <= 0 ) then

        return false
    end

    local count = resourceStorageRef.Storages.count

    for i=1,count do

        local storage = resourceStorageRef.Storages[i]

        if ( storage.attachment == nil or storage.attachment.count <= 0 ) then

            goto labelContinue
        end

        for attachmentIndex = 1,storage.attachment.count do
                                
            local attachmentName = storage.attachment[attachmentIndex]
                                    
            if ( attachmentName ~= nil and attachmentName ~= "" ) then

                return true
            end
        end

        ::labelContinue::
    end

    return false
end

function pipe_perimeter_tool:IsResourceConverterDescHasAttachments( resourceConverterRef )

    local inValue = resourceConverterRef["in"]
    if ( inValue ~= nil and inValue.count > 0 ) then
                    
        if ( self:IsConverterArray( inValue ) ) then

            return true
        end
    end

    local outValue = resourceConverterRef["out"]
    if ( outValue ~= nil and outValue.count > 0 ) then
                    
        if ( self:IsConverterArray( outValue ) ) then

            return true
        end
    end

    return false
end

function pipe_perimeter_tool:IsConverterArray( converterArray )

    for index = 1,converterArray.count do
                
        local gameResource = converterArray[index]

        if ( gameResource == nil or gameResource.value == nil or gameResource.value <= 0 ) then

            goto labelContinue
        end

        if ( gameResource.attachment == nil or gameResource.attachment.count == 0 ) then

            goto labelContinue
        end

        for attachmentIndex = 1,gameResource.attachment.count do
                                
            local attachmentName = gameResource.attachment[attachmentIndex]
                                    
            if ( attachmentName ~= nil and attachmentName ~= "" ) then

                return true
            end
        end

        ::labelContinue::
    end

    return false
end

function pipe_perimeter_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/current" )
end

function pipe_perimeter_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function pipe_perimeter_tool:CheckConfigExists( pipeLinesCount )

    pipeLinesCount = pipeLinesCount or 1

    local scalePipeLines = self:GetPipeConfigArray()

    local index = IndexOf( scalePipeLines, pipeLinesCount )

    if ( index == nil ) then

        return scalePipeLines[1]
    end

    return pipeLinesCount
end

function pipe_perimeter_tool:GetPipeConfigArray()

    if ( self.scalePipeLines == nil ) then

        self.scalePipeLines = {
            1,
            2,
            3,
            --4,
            --5,
            --6,
        }
    end

    return self.scalePipeLines
end

function pipe_perimeter_tool:OnRotateSelectorRequest( evt )

    self.activated = self.activated or false

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local playerPosition = EntityService:GetPosition(self.playerEntity)
    
    local entityPosition = EntityService:GetPosition(self.entity)

    local isPipeCount = ( entityPosition.x < playerPosition.x )

    if ( isPipeCount and not self.activated ) then

        local currentLinesConfig = self:CheckConfigExists(self.pipeLinesCount)

        local scalePipeLines = self:GetPipeConfigArray()

        local index = IndexOf( scalePipeLines, currentLinesConfig )
        if ( index == nil ) then
            index = 1
        end

        local maxIndex = #scalePipeLines

        local newIndex = index + change
        if ( newIndex > maxIndex ) then
            newIndex = maxIndex
        elseif( newIndex < 1 ) then
            newIndex = 1
        end

        local newValue = scalePipeLines[newIndex]

        self.pipeLinesCount = newValue

        -- Pipe layers config
        local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
        selectorDB:SetInt(self.configNamePipesCount, newValue)

        self:UpdateMarker()
    else

        local currentScale = self.currentScale

        local maxIndex = #self.scaleMap

        local index = IndexOf( self.scaleMap, currentScale )
        if ( index == nil ) then 
            index = 1
        end

        local newValue = index + change
        if ( newValue > maxIndex ) then
            newValue = 1
        elseif( newValue == 0 ) then
            newValue = maxIndex
        end

        self.currentScale = self.scaleMap[newValue]

        EntityService:SetScale( self.entity, self.currentScale, 1.0, self.currentScale)

        local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
        selectorDB:SetInt(self.configNameScale, self.currentScale)

        self:SetChildrenPosition()
        self:RescaleChild()
    end

    self:OnUpdate()
end

function pipe_perimeter_tool:OnActivateSelectorRequest()

    self.activated = true

    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function pipe_perimeter_tool:OnActivateEntity( entity )

    local gridCullerComponent = EntityService:GetComponent( entity, "GridCullerComponent" )
    if( gridCullerComponent == nil ) then
        return
    end

    local gridCullerComponentRef = reflection_helper(gridCullerComponent)

    local min, max = self:GetEntityMinMax(gridCullerComponentRef)

    if ( min == nil or max == nil ) then
        return
    end

    local newPositionsArray = {}
    local hashPositions = {}

    local pipeLinesCount = self:CheckConfigExists(self.pipeLinesCount)

    for i=1,pipeLinesCount do

        min.x = min.x - 2
        min.z = min.z - 2

        max.x = max.x + 2
        max.z = max.z + 2

        local entityPerimeterPositions = self:GetPerimeterPositions( min, max )

        for position in Iter( entityPerimeterPositions ) do

            if ( self:AddToHash(hashPositions, position.x, position.z ) ) then
                
                Insert(newPositionsArray, position)
            end
        end
    end


    local currentTransform = EntityService:GetWorldTransform( self.entity )

    for i=1,#newPositionsArray do

        local newPosition = newPositionsArray[i]
        newPosition.y = currentTransform.position.y

        local ghostEntity = self:GetEntityFromGrid( self.gridEntities, newPosition.x, newPosition.z )

        if ( ghostEntity ~= nil ) then

            self:BuildEntity(ghostEntity, false)
        end
    end
end

function pipe_perimeter_tool:OnDeactivateSelectorRequest()

    self.activated = false
end

function pipe_perimeter_tool:RescaleChild()
    local scale = EntityService:GetScale( self.entity )
    scale.x = 1.0 / scale.x
    scale.z  = 1.0 / scale.z
    if ( self.childEntity ~= nil and self.childEntity ~= INVALID_ID ) then
        EntityService:SetScale( self.childEntity, scale.x, scale.y, scale.z )
    end
    if ( self.corners ~= nil ) then
        EntityService:SetScale( self.corners, scale.x, scale.y, scale.z )
    end
end

function pipe_perimeter_tool:SetChildrenPosition()
    local diagonal = VectorMulByNumber(self.boundsSize , self.currentScale)
    diagonal.y = 1
    local children = EntityService:GetChildren( self.corners, true )
    for child in Iter(children ) do
        local childPos = EntityService:GetLocalPosition(child)
        if ( self.childPos[child] == nil ) then
            self.childPos[child] = childPos
        else
            childPos = self.childPos[child]
        end
        childPos = VectorMul(childPos, diagonal)
        EntityService:SetPosition(child,childPos)
    end
end

function pipe_perimeter_tool:OnRelease()

    for ent in Iter(self.selectedEntities ) do
        self:RemovedFromSelection( ent )
    end
    EntityService:RemoveEntity(self.corners)

    for ghost in Iter(self.linesEntities) do
        EntityService:RemoveEntity(ghost)
    end
    self.linesEntities = {}
    self.linesEntityInfo = {}
    self.gridEntities = {}

    -- Destroy Marker with layers count
    if (self.currentMarkerLines ~= nil) then

        EntityService:RemoveEntity(self.currentMarkerLines)
        self.currentMarkerLines = nil
    end

    if ( pipe_base_tool.OnRelease ) then
        pipe_base_tool.OnRelease(self)
    end
end

return pipe_perimeter_tool
