local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")

class 'buildings_upgrader_all_tool' ( buildings_tool_base )

function buildings_upgrader_all_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_upgrader_all_tool:OnInit()

    local markerBlueprint = "misc/marker_selector_buildings_upgrader_tool"

    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.numberFrom = self.data:GetInt("number_from")
    self.numberTo = self.data:GetInt("number_to")
    self.templateFormat = self.data:GetString("template_format")

    self:FillMarkerMessage()
end

function buildings_upgrader_all_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local markerText = ""

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        LogService:Log("templateName " .. templateName)

        local templateString = campaignDatabase:GetStringOrDefault( templateName, "" ) or ""
        if ( templateString ~= nil and templateString ~= "" ) then

            if ( string.len(markerText) > 0 ) then

                markerText = markerText .. ", "
            end

            markerText = markerText .. tostring(number)
        end
    end

    LogService:Log("markerText " .. markerText)

    if ( string.len(markerText) > 0 ) then

        markerDB:SetString("message_text", markerText)
        markerDB:SetInt("message_visible", 1)
    end
end

function buildings_upgrader_all_tool:AddedToSelection( entity )
end

function buildings_upgrader_all_tool:RemovedFromSelection( entity )
end

function buildings_upgrader_all_tool:OnUpdate()
end

function buildings_upgrader_all_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_upgrader_all_tool:OnActivateSelectorRequest()

    self.activated = true

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        return
    end

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        self:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName)
    end

    self:FillMarkerMessage()
end

function buildings_upgrader_all_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_upgrader_all_tool