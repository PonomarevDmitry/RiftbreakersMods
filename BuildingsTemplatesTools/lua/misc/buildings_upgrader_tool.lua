local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")

class 'buildings_upgrader_tool' ( buildings_tool_base )

function buildings_upgrader_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_upgrader_tool:OnInit()

    local marker = self.data:GetString("marker")
    local markerBlueprint = "misc/marker_selector_buildings_upgrader_tool_" .. marker

    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.template_name = self.data:GetString("template_name")

    self:FillMarkerMessageWithBuildingsIcons(self.template_name)
end

function buildings_upgrader_tool:AddedToSelection( entity )
end

function buildings_upgrader_tool:RemovedFromSelection( entity )
end

function buildings_upgrader_tool:OnUpdate()
end

function buildings_upgrader_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_upgrader_tool:OnActivateSelectorRequest()

    self.activated = true

    self:UpgradeBlueprintsInTemplateAndSaveToDatabase(self.template_name)

    self:FillMarkerMessageWithBuildingsIcons(self.template_name)
end

function buildings_upgrader_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_upgrader_tool