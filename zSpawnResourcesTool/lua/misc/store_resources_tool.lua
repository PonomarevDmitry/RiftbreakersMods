local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'store_resources_tool' ( tool )

function store_resources_tool:__init()
    tool.__init(self,self)
end

function store_resources_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_store_resources_tool", self.entity)

    self.currentValue = 500
    self.stepValue = 100

    self.veinName = self.data:GetString("vein")
    self.resourceName = self.data:GetString("resource")

    --self.configName = "$store_resources_tool_config." .. self.veinName
    self.configName = "$store_resources_tool_config"

    local selectorDB = EntityService:GetDatabase( self.selector )
    if ( selectorDB ) then
        self.currentValue = selectorDB:GetIntOrDefault(self.configName, self.currentValue)
    end

    self.infoChild = EntityService:SpawnAndAttachEntity("misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1)

    self:OnUpdate()
end

function store_resources_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function store_resources_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function store_resources_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function store_resources_tool:OnUpdate()

    self.buildCost = {}

    self.buildCost[self.resourceName] = self.currentValue

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

function store_resources_tool:FindEntitiesToSelect( selectorComponent )

    return {}

    --local selectorPosition = selectorComponent.position
    --
    --local boundsSize = { x=1.0, y=100.0, z=1.0 }
    --
    --local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)
    --
    --local min = VectorSub(selectorPosition, scaleVector)
    --local max = VectorAdd(selectorPosition, scaleVector)
    --
    --local predicate = {
    --
    --    signature="ResourceVolumeComponent"
    --}
    --
    --local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )
    --
    --local resourceVolumeEntities = {}
    --
    --for entity in Iter( tempCollection ) do
    --
    --    if ( entity == nil ) then
    --        goto continue
    --    end
    --
    --    if ( IndexOf( resourceVolumeEntities, entity ) ~= nil ) then
    --        goto continue
    --    end
    --
    --    local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
    --    if ( resourceVolumeComponent == nil ) then
    --        goto continue
    --    end
    --
    --    local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )
    --    if ( resourceVolumeComponentRef.type == nil or resourceVolumeComponentRef.type.resource == nil or resourceVolumeComponentRef.type.resource.id == nil ) then
    --        goto continue
    --    end
    --
    --    local resourceId = resourceVolumeComponentRef.type.resource.id or ""
    --    if ( resourceId ~= self.veinName ) then
    --        goto continue
    --    end
    --
    --    Insert( resourceVolumeEntities, entity )
    --
    --    ::continue::
    --end
    --
    --local sorter = function( lhs, rhs )
    --    local position1 = EntityService:GetPosition( lhs )
    --    local position2 = EntityService:GetPosition( rhs )
    --    local distance1 = Distance( selectorPosition, position1 )
    --    local distance2 = Distance( selectorPosition, position2 )
    --    return distance1 < distance2
    --end
    --
    --table.sort(resourceVolumeEntities, sorter)
    --
    --return resourceVolumeEntities
end

function store_resources_tool:AddedToSelection( entity )

    --local childrenList = EntityService:GetChildren( entity, false )
    --
    --for childResource in Iter( childrenList ) do
    --
    --    if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
    --        goto continue
    --    end
    --
    --    if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
    --        goto continue
    --    end
    --
    --    QueueEvent( "SelectEntityRequest", childResource )
    --
    --    ::continue::
    --end
end

function store_resources_tool:RemovedFromSelection( entity )

    --local childrenList = EntityService:GetChildren( entity, false )
    --for childResource in Iter( childrenList ) do
    --
    --    if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
    --        goto continue
    --    end
    --
    --    if ( not EntityService:HasComponent( childResource, "SelectableComponent" ) ) then
    --        goto continue
    --    end
    --
    --    QueueEvent( "DeselectEntityRequest", childResource )
    --
    --    ::continue::
    --end
end

function store_resources_tool:OnActivateSelectorRequest()

    if ( self.currentValue <= 0 ) then
        return
    end

    local treasureSpotFind = FindService:FindEmptySpotInRadius( self.entity, 1.0, "", "" )

    if ( treasureSpotFind.first == false ) then
        return
    end

    local newEnt = ResourceService:FindEmptySpace(0, 0)
    EntityService:SetPosition(newEnt, treasureSpotFind.second.x, treasureSpotFind.second.y, treasureSpotFind.second.z)

    ResourceService:SpawnResources( newEnt, "resources/volume_template_resource", self.veinName, self.currentValue - self.stepValue, self.currentValue )

    EntityService:RemoveEntity(newEnt)

    PlayerService:AddResourceAmount( self.resourceName, -self.currentValue )
end

function store_resources_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = self.stepValue
    if ( degree > 0 ) then
        change = -change
    end

    local newValue = self.currentValue + change

    if( newValue <= 0 ) then
        newValue = 0
    end

    self.currentValue = newValue

    local selectorDB = EntityService:GetDatabase( self.selector )
    if ( selectorDB ) then
        selectorDB:SetInt(self.configName, newValue)
    end

    self:OnUpdate()
end

function store_resources_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return store_resources_tool
