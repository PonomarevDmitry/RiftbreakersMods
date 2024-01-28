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

    self.resourceName = "carbon_vein"

    self.configName = "$store_resources_tool_config." .. self.resourceName

    local selectorDB = EntityService:GetDatabase( self.selector )
    if ( selectorDB ) then
        self.currentValue = selectorDB:GetIntOrDefault(self.configName, self.currentValue)
    end

    self:UpdateMarker()
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

function store_resources_tool:UpdateMarker()

    local markerDB = self.data

    markerDB:SetString("message_text", tostring(self.currentValue))
    markerDB:SetInt("message_visible", 1)
end

function store_resources_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function store_resources_tool:AddedToSelection( entity )
end

function store_resources_tool:RemovedFromSelection( entity )
end

function store_resources_tool:OnActivateSelectorRequest()

    if ( self.currentValue <= 0 ) then
        return
    end

    local treasureSpotFind = FindService:FindEmptySpotInRadius( self.entity, 1.0, "", "" ).second

    local newEnt = ResourceService:FindEmptySpace(0, 0)
    EntityService:SetPosition(newEnt, treasureSpotFind.x, treasureSpotFind.y, treasureSpotFind.z)

    ResourceService:SpawnResources( newEnt, "resources/volume_template_resource", self.resourceName, self.currentValue, self.currentValue )

    EntityService:RemoveEntity(newEnt)
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

    self:UpdateMarker()
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
