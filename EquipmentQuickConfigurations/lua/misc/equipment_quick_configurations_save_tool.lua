local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

class 'equipment_quick_configurations_save_tool' ( tool )

function equipment_quick_configurations_save_tool:__init()
    tool.__init(self,self)
end

function equipment_quick_configurations_save_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function equipment_quick_configurations_save_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_equipment_quick_configurations_save_tool", self.entity)

    self.popupShown = false
    self.timeoutTime = nil

    self.clickCooldown = 0.75
end

function equipment_quick_configurations_save_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function equipment_quick_configurations_save_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function equipment_quick_configurations_save_tool:OnUpdate()
    
end

function equipment_quick_configurations_save_tool:AddedToSelection( entity )
end

function equipment_quick_configurations_save_tool:RemovedFromSelection( entity )
end

function equipment_quick_configurations_save_tool:OnRotate()
end

function equipment_quick_configurations_save_tool:OnActivateSelectorRequest()

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    self.popupShown = self.popupShown or false

    if( self.popupShown == true ) then
        return
    end

    self.popupShown = true

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    GuiService:OpenPopup(self.entity, "gui/popup/equipment_quick_configurations_popup_ingame_buttons", "gui/equipment_quick_configurations/select_configuration_to_save")
end

function equipment_quick_configurations_save_tool:OnGuiPopupResultEvent( evt)

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

  

    local saveResultEquipment, slotsHashToSave, configContent = EquipmentQuickConfigurationsUtils:GetSaveEquipmentInfo( self.playerId, self.slotNamePrefixArray, self.configName )

    local slotLocalizationNameFull = "${equipment_quick_configurations/slots/" .. self.slotLocalizationName .. '}'

    if ( #configContent == 0) then

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventNotification")

        local message = '<style="header_35">${voice_over/announcement/equipment_quick_configurations/load/empty} ' .. slotLocalizationNameFull .. '${voice_over/announcement/equipment_quick_configurations/load/empty_end}</style>'

        GuiService:OpenPopup(self.entity, "gui/popup/popup_template_1button", message)

        return
    end



    self.configContent = configContent

    local loadResultEquipment, slotsHashCurrent = EquipmentQuickConfigurationsUtils:ReadSavedEquipmentInfoAndEquipItems( self.playerId, self.slotNamePrefixArray, self.slotLocalizationName, self.configName, false )

    local configNameLocal = "${equipment_quick_configurations/configs/name/" .. self.configName .. '}'

    local playerSlotsArrayEquipment = EquipmentQuickConfigurationsUtils:GetPlayerSlotsEquipmentInfo(self.playerId)

    local confimMessage = '${voice_over/announcement/equipment_quick_configurations/confirming}\n<style="header_35">' .. slotLocalizationNameFull .. '</style>${voice_over/announcement/equipment_quick_configurations/confirming_to} <style="header_35">' .. configNameLocal .. '${voice_over/announcement/equipment_quick_configurations/confirming_end}</style>\n'

    for slotConfig in Iter( playerSlotsArrayEquipment ) do

        local slotConfigToSave = slotsHashToSave[slotConfig.Name]

        if ( slotConfigToSave ~= nil ) then

            for subSlotNumber=1,slotConfig.SubSlotsCount do

                local slotDesc = slotConfigToSave.SubSlots[subSlotNumber]

                if ( slotDesc ~= nil ) then

                    confimMessage = confimMessage .. "\n" .. " " .. slotConfig.Name

                    if ( slotConfig.SubSlotsCount > 1 ) then
                        confimMessage = confimMessage .. " "  .. tostring(subSlotNumber)
                    end

                    local rarityStyle = '<style="' .. EquipmentQuickConfigurationsUtils:GetRarityStyle( slotDesc.rarity ) .. '">'
                    local slotStr = '<img="' .. slotDesc.icon .. '"> ' .. rarityStyle .. '${' .. slotDesc.name .. '}' .. '</style>'

                    confimMessage = confimMessage .. ': ' .. slotStr

                    if ( slotsHashCurrent[slotConfig.Name] ~= nil and slotsHashCurrent[slotConfig.Name].SubSlots[subSlotNumber] ~= nil ) then

                        slotDesc = slotsHashCurrent[slotConfig.Name].SubSlots[subSlotNumber]

                        rarityStyle = '<style="' .. EquipmentQuickConfigurationsUtils:GetRarityStyle( slotDesc.rarity ) .. '">'
                        slotStr = '<img="' .. slotDesc.icon .. '"> ' .. rarityStyle .. '${' .. slotDesc.name .. '}' .. '</style>'

                        confimMessage = confimMessage .. ' ${equipment_quick_configurations/previous} ' .. slotStr
                    end
                end
            end
        end
    end

    --LogService:Log("confimMessage " .. confimMessage)

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventSaveResult")

    GuiService:OpenPopup(self.entity, "gui/popup/equipment_quick_configurations_popup_ingame_2buttons", confimMessage)
end

function equipment_quick_configurations_save_tool:OnGuiPopupResultEventSaveResult( evt)

    self.timeoutTime = GetLogicTime() + self.clickCooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventSaveResult")

    local eventResult = evt:GetResult()

    if ( eventResult == "button_yes" ) then

        EquipmentQuickConfigurationsUtils:SaveSettingKeyName( self.playerId, self.slotLocalizationName, self.configName, self.configContent )

        local configNameLocal = "${equipment_quick_configurations/configs/name/" .. self.configName .. '}'
        local slotLocalizationNameFull = "${equipment_quick_configurations/slots/" .. self.slotLocalizationName .. '}'

        local fullAnnouncement = '${voice_over/announcement/equipment_quick_configurations/saving} <style="header_24">' .. slotLocalizationNameFull .. '</style>${voice_over/announcement/equipment_quick_configurations/saving_to} <style="header_24">' .. configNameLocal .. '</style>${voice_over/announcement/equipment_quick_configurations/saving_end}'

        --LogService:Log("fullAnnouncement " .. fullAnnouncement)

        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end

    self.popupShown = false
end

function equipment_quick_configurations_save_tool:OnGuiPopupResultEventNotification( evt)

    self.timeoutTime = GetLogicTime() + self.clickCooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventNotification")

    self.popupShown = false
end

function equipment_quick_configurations_save_tool:OnActivateEntity( entity )
end

return equipment_quick_configurations_save_tool
