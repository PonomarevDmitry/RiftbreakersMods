require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
local EquipmentQuickConfigurationsUtils = require("lua/utils/equipment_quick_configurations_utils.lua")

local LOAD_RESULT_FAIL    = 1
local LOAD_RESULT_EMPTY   = 2
local LOAD_RESULT_INVALID = 3
local LOAD_RESULT_SUCCESS = 4

class 'equipment_quick_configurations_save_entity' ( LuaEntityObject )

function equipment_quick_configurations_save_entity:__init()
    LuaEntityObject.__init(self, self)
end

function equipment_quick_configurations_save_entity:init()

    self.slotNamePrefixArray = self.data:GetString("slotNamePrefixArray")
    self.slotLocalizationName = self.data:GetString("slotLocalizationName")
    self.configName = self.data:GetString("configName")

    local saveResultEquipment, slotsHashToSave, configContent = EquipmentQuickConfigurationsUtils:GetSaveEquipmentInfo( self.slotNamePrefixArray, self.configName )

    self.configContent = configContent

    local loadResultEquipment, slotsHashCurrent = EquipmentQuickConfigurationsUtils:ReadSavedEquipmentInfoAndQuipItems( self.slotNamePrefixArray, self.slotLocalizationName, self.configName, false )

    local slotLocalizationNameFull = "${equipment_quick_configurations/slots/" .. self.slotLocalizationName .. '}'

    if ( #self.configContent == 0) then

        local message = '<style="header_35">${voice_over/announcement/equipment_quick_configurations/load/empty} ' .. slotLocalizationNameFull .. '${voice_over/announcement/equipment_quick_configurations/load/empty_end}</style>'

        GuiService:OpenPopup(INVALID_ID, "gui/popup/popup_template_1button", message)

        self:DestroySelf()

        return
    end

    local configNameLocal = "${equipment_quick_configurations/configs/name/" .. self.configName .. '}'

    local playerSlotsArrayEquipment = EquipmentQuickConfigurationsUtils:GetPlayerSlotsEquipmentInfo()

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

function equipment_quick_configurations_save_entity:OnGuiPopupResultEventSaveResult( evt)

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventSaveResult")

    local eventResult = evt:GetResult()

    if ( eventResult == "button_yes" ) then

        EquipmentQuickConfigurationsUtils:SaveSettingKeyName( self.slotLocalizationName, self.configName, self.configContent )

        local configNameLocal = "${equipment_quick_configurations/configs/name/" .. self.configName .. '}'
        local slotLocalizationNameFull = "${equipment_quick_configurations/slots/" .. self.slotLocalizationName .. '}'

        local fullAnnouncement = '${voice_over/announcement/equipment_quick_configurations/saving} <style="header_24">' .. slotLocalizationNameFull .. '</style>${voice_over/announcement/equipment_quick_configurations/saving_to} <style="header_24">' .. configNameLocal .. '</style>${voice_over/announcement/equipment_quick_configurations/saving_end}'

        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end

    self:DestroySelf()
end

function equipment_quick_configurations_save_entity:OnLoad()
    self:DestroySelf()
end

function equipment_quick_configurations_save_entity:DestroySelf()
    EntityService:RemoveEntity( self.entity )
    globalEquipmentQuickConfigurationsUtilsPopupEntity = nil
end

return equipment_quick_configurations_save_entity