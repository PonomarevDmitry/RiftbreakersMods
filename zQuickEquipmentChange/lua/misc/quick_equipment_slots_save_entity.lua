require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
local QuickEquipmentSlotsUtils = require("lua/utils/quick_equipment_slots_utils.lua")

local LOAD_RESULT_FAIL    = 1
local LOAD_RESULT_EMPTY   = 2
local LOAD_RESULT_INVALID = 3
local LOAD_RESULT_SUCCESS = 4

class 'quick_equipment_slots_save_entity' ( LuaEntityObject )

function quick_equipment_slots_save_entity:__init()
    LuaEntityObject.__init(self, self)
end

function quick_equipment_slots_save_entity:init()

    self.slotNamePrefixArray = self.data:GetString("slotNamePrefixArray")
    self.slotLocalizationName = self.data:GetString("slotLocalizationName")
    self.configName = self.data:GetString("configName")

    local configNameLocal = "quick_equipment_slots_change/configs/name/" .. self.configName
    local slotLocalizationNameFull = "quick_equipment_slots_change/slots/" .. self.slotLocalizationName

    local slotsHashToSave = {}
    local slotsHashCurrent = {}

    local hasConfig = false

    self.configBySlot = {}

    local slotNamesArray = Split( self.slotNamePrefixArray, "," )
    for slotsString in Iter( slotNamesArray ) do

        local saveResultEquipment, slotsHashEquipment, configContent = QuickEquipmentSlotsUtils:GetSaveEquipmentInfo( slotsString, self.configName )

        slotsHashToSave = QuickEquipmentSlotsUtils:CombineSlotsHashs( slotsHashToSave, slotsHashEquipment )

        if ( saveResultEquipment == LOAD_RESULT_SUCCESS ) then

            hasConfig = true
            self.configBySlot[slotsString] = configContent
        end

        slotsHashEquipment = QuickEquipmentSlotsUtils:GetLoadEquipmentInfo( slotsString, self.configName )
        slotsHashCurrent = QuickEquipmentSlotsUtils:CombineSlotsHashs( slotsHashCurrent, slotsHashEquipment )
    end

    if ( not hasConfig) then

        local message = '${voice_over/announcement/quick_equipment_slots_change/nothing_to_save}\r\n<style="header_35">${' .. slotLocalizationNameFull .. '}</style>${voice_over/announcement/quick_equipment_slots_change/nothing_to_save_to} <style="header_35">${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/nothing_to_save_end}</style>'

        GuiService:OpenPopup(INVALID_ID, "gui/popup/popup_template_1button", message)

        self:DestroySelf()
        return
    end

    local playerSlotsArrayEquipment = QuickEquipmentSlotsUtils:GetPlayerSlotsEquipmentInfo()

    local confimMessage = '${voice_over/announcement/quick_equipment_slots_change/confirming}\r\n<style="header_35">${' .. slotLocalizationNameFull .. '}</style>${voice_over/announcement/quick_equipment_slots_change/confirming_to} <style="header_35">${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/confirming_end}</style>'

    for slotConfig in Iter( playerSlotsArrayEquipment ) do

        local slotConfigToSave = slotsHashToSave[slotConfig.Name]

        if ( slotConfigToSave ~= nil ) then

            for subSlotNumber=1,slotConfig.SubSlotsCount do

                local slotDesc = slotConfigToSave.SubSlots[subSlotNumber]

                if ( slotDesc ~= nil ) then

                    confimMessage = confimMessage .. "\r\n" .. " " .. slotConfig.Name

                    if ( slotConfig.SubSlotsCount > 1 ) then
                        confimMessage = confimMessage .. " "  .. tostring(subSlotNumber)
                    end

                    local rarityStyle = '<style="' .. QuickEquipmentSlotsUtils:GetRarityStyle( slotDesc.rarity ) .. '">'
                    local slotStr = '<img="' .. slotDesc.icon .. '"> ' .. rarityStyle .. '${' .. slotDesc.name .. '}' .. '</style>'

                    confimMessage = confimMessage .. ': ' .. slotStr

                    if ( slotsHashCurrent[slotConfig.Name] ~= nil and slotsHashCurrent[slotConfig.Name].SubSlots[subSlotNumber] ~= nil ) then

                        slotDesc = slotsHashCurrent[slotConfig.Name].SubSlots[subSlotNumber]

                        rarityStyle = '<style="' .. QuickEquipmentSlotsUtils:GetRarityStyle( slotDesc.rarity ) .. '">'
                        slotStr = '<img="' .. slotDesc.icon .. '"> ' .. rarityStyle .. '${' .. slotDesc.name .. '}' .. '</style>'

                        confimMessage = confimMessage .. ' ${quick_equipment_slots_change/old} ' .. slotStr
                    end
                end
            end
        end
    end

    --LogService:Log("confimMessage " .. confimMessage)

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    GuiService:OpenPopup(self.entity, "gui/popup/quick_equipment_slots_popup_ingame_2buttons", confimMessage)
end

function quick_equipment_slots_save_entity:OnGuiPopupResultEvent( evt)

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        for slotsString,configContent in pairs(self.configBySlot) do 
            QuickEquipmentSlotsUtils:SaveSettingKeyName( slotsString, self.configName, configContent )
        end

        local configNameLocal = "quick_equipment_slots_change/configs/name/" .. self.configName
        local slotLocalizationNameFull = "quick_equipment_slots_change/slots/" .. self.slotLocalizationName

        local fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/saving} <style="header_24">${' .. slotLocalizationNameFull .. '}</style>${voice_over/announcement/quick_equipment_slots_change/saving_to} <style="header_24">${' .. configNameLocal .. '}</style>${voice_over/announcement/quick_equipment_slots_change/saving_end}'

        SoundService:PlayAnnouncement( fullAnnouncement, 0 )
    end

    self:DestroySelf()
end

function quick_equipment_slots_save_entity:OnLoad()
    self:DestroySelf()
end

function quick_equipment_slots_save_entity:DestroySelf()
    EntityService:RemoveEntity( self.entity )
end

return quick_equipment_slots_save_entity