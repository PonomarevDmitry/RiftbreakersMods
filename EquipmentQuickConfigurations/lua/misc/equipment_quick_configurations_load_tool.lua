local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

class 'equipment_quick_configurations_load_tool' ( tool )

function equipment_quick_configurations_load_tool:__init()
    tool.__init(self,self)
end

function equipment_quick_configurations_load_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function equipment_quick_configurations_load_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_equipment_quick_configurations_load_tool", self.entity)

    self.popupShown = false
    self.timeoutTime = nil

    self.clickCooldown = 0.75
end

function equipment_quick_configurations_load_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function equipment_quick_configurations_load_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function equipment_quick_configurations_load_tool:OnUpdate()
    
end

function equipment_quick_configurations_load_tool:AddedToSelection( entity )
end

function equipment_quick_configurations_load_tool:RemovedFromSelection( entity )
end

function equipment_quick_configurations_load_tool:OnRotate()
end

function equipment_quick_configurations_load_tool:OnActivateSelectorRequest()

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    self.popupShown = self.popupShown or false

    if( self.popupShown == true ) then
        return
    end

    self.popupShown = true

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    GuiService:OpenPopup(self.entity, "gui/popup/equipment_quick_configurations_popup_ingame_buttons", "gui/equipment_quick_configurations/select_configuration_to_load")
end

function equipment_quick_configurations_load_tool:OnGuiPopupResultEvent( evt)

    self.timeoutTime = GetLogicTime() + self.clickCooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")



    local buttonResult = evt:GetResult()

    if ( buttonResult == "button_cancel" ) then

        self.popupShown = false
        return
    end



    local split = Split( buttonResult, "_" )
    
    self.slotNamePrefixArray = split[2]
    self.slotLocalizationName = split[2]
    self.configName = "QuickConfig0" .. split[3]

    if ( self.slotLocalizationName == "weapon" ) then

        self.slotNamePrefixArray = "left_hand,right_hand"
    end


  
    local loadResult, slotsHash = EquipmentQuickConfigurationsUtils:ReadSavedEquipmentInfoAndEquipItems( self.playerId, self.slotNamePrefixArray, self.slotLocalizationName, self.configName, true )

    EquipmentQuickConfigurationsUtils:PlayLoadAnnouncementAndSound(self.playerId, loadResult, self.slotLocalizationName, self.configName, slotsHash)

    self.popupShown = false
end

function equipment_quick_configurations_load_tool:OnActivateEntity( entity )
end

return equipment_quick_configurations_load_tool
