local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_resources_tool' ( tool )

function eraser_resources_tool:__init()
    tool.__init(self,self)
end

function eraser_resources_tool:OnInit()
    self.baseSearch = false
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_resources_tool", self.entity)

    self.nowBuildingLine = false
    self.buildStartPosition = nil
    self.gridEntities = {}
    self.currentSize = 0
end

function eraser_resources_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_resources_tool:DisposeResources()

    for i=1,#self.selectedEntities do

        local entity = self.selectedEntities[i]

        QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
    end
end

function eraser_resources_tool:FindEntitiesToSelect( selectorComponent )

    local predicate = {

        signature="ResourceVolumeComponent"
    };

    local possibleSelectedEnts = {}

    for xIndex=1,#self.gridEntities do
        
        local gridEntitiesZ = self.gridEntities[xIndex]
        
        for zIndex=1,#gridEntitiesZ do
        
            local entity = gridEntitiesZ[zIndex]

            local position = EntityService:GetPosition( entity )

            local boundsSize = { x=1.0, y=1.0, z=1.0 }

            local min = VectorSub(position, VectorMulByNumber(boundsSize , self.currentScale))
            local max = VectorAdd(position, VectorMulByNumber(boundsSize , self.currentScale))
    
            local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

            for tempEntity in Iter( tempCollection ) do

                if ( tempEntity ~= nil and IndexOf( possibleSelectedEnts, tempEntity ) == nil ) then
                   Insert( possibleSelectedEnts, tempEntity )
                end
            end
        end
    end

    local selectorPosition = selectorComponent.position
    
    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2 
    end

    table.sort(possibleSelectedEnts, function(a,b) 
        return sorter(possibleSelectedEnts, a, b) 
    end)

    local selectedEntities = {}

    for entity in Iter( possibleSelectedEnts ) do

        local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
        if ( resourceVolumeComponent == nil ) then 
            goto continue
        end

        Insert(selectedEntities, entity )

        ::continue::
    end
    
    return selectedEntities
end

function eraser_resources_tool:AddedToSelection( entity )
end

function eraser_resources_tool:RemovedFromSelection( entity )
end

function eraser_resources_tool:OnUpdate()
    
    local currentScale = EntityService:GetScale(self.entity).x
    
    if ( self.currentSize ~= currentScale ) then
        
        self.currentSize = currentScale

        self:StopBuildingGhosts()
    end

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
                
                    local lineEnt = EntityService:SpawnEntity("buildings/tools/eraser_1x1_ghost", newPosition, team )
                    EntityService:RemoveComponent(lineEnt, "LuaComponent")
                    EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)
                    
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
                
                    local lineEnt = EntityService:SpawnEntity("buildings/tools/eraser_1x1_ghost", newPosition, team )
                    EntityService:RemoveComponent(lineEnt, "LuaComponent")
                    EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)
                    
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
                transform.scale = {x=1,y=1,z=1}
                transform.orientation = currentTransform.orientation
                transform.position = newPosition
                
                local lineEnt = gridEntitiesZ[zIndex];
                EntityService:SetPosition( lineEnt, newPosition)
                EntityService:SetScale( lineEnt, currentScale, 1.0, currentScale)
            end
        end
    end
end

function eraser_resources_tool:FindPositionsToBuildLine(buildStartPosition, buildEndPosition)

    local gridSize = BuildingService:GetBuildingGridSize(self.entity)
    
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

function eraser_resources_tool:GetXZSigns(positionStart, positionEnd)
                
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

function eraser_resources_tool:OnActivateSelectorRequest()

    if ( self.buildStartPosition == nil ) then

        self.nowBuildingLine = true;

        local transform = EntityService:GetWorldTransform( self.entity )
        self.buildStartPosition = transform
        EntityService:SetVisible( self.entity , false )

        self:OnUpdate()
    else
        self:DisposeResources()

        self:StopBuildingGhosts()
    end
end

function eraser_resources_tool:OnDeactivate()

    self:DisposeResources()

    self:StopBuildingGhosts()
end

function eraser_resources_tool:StopBuildingGhosts()

    self:ClearGridEntities()

    EntityService:SetVisible( self.entity , true )

    self.nowBuildingLine = false
    self.buildStartPosition = nil
end

function eraser_resources_tool:ClearGridEntities()

    if ( self.gridEntities ~= nil ) then
        for gridEntitiesZ in Iter(self.gridEntities) do
            for ghost in Iter(gridEntitiesZ) do
                EntityService:RemoveEntity(ghost)
            end
        end
    end
    
    self.gridEntities = {}
end

function eraser_resources_tool:OnRelease()

    self:ClearGridEntities()

    self.nowBuildingLine = false
    self.buildStartPosition = nil
    
    self.currentSize = 0

    tool.OnRelease(self)
end

function eraser_resources_tool:OnRotate()
end

return eraser_resources_tool
