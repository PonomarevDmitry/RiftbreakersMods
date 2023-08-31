local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")

class 'buildings_upgrader_tool' ( buildings_tool_base )

function buildings_upgrader_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_upgrader_tool:OnInit()

    self.marker = self.data:GetString("marker")
    local markerBlueprint = "misc/marker_selector_buildings_upgrader_tool_" .. self.marker

    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.template_name = self.data:GetString("template_name")

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local templateString = campaignDatabase:GetStringOrDefault( self.template_name, "" ) or ""

    if ( templateString == "" ) then

        markerDB:SetString("message_text", "")
        markerDB:SetInt("message_visible", 0)
        return
    end

    local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

    if ( string.len(buildingsIcons) > 0 ) then

        local templateCaption = "gui/hud/building_templates/template_" .. self.marker

        local markerText = "${" .. templateCaption .. "}: " .. buildingsIcons

        markerDB:SetString("message_text", markerText)
    else

        markerDB:SetString("message_text", "gui/hud/messages/buildings_tool_base/template_already_created")
    end

    markerDB:SetInt("message_visible", 1)
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

    self:FillMarkerMessage()
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