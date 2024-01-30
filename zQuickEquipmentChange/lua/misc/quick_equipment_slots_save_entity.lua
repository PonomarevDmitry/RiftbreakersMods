require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
local QuickEquipmentSlotsUtils = require("lua/utils/quick_equipment_slots_utils.lua")

class 'quick_equipment_slots_save_entity' ( LuaEntityObject )

function quick_equipment_slots_save_entity:__init()
    LuaEntityObject.__init(self, self)
end

function quick_equipment_slots_save_entity:init()

    self.slotNamePrefixArray = self.data:GetString("slotNamePrefixArray")
    self.slotLocalizationName = self.data:GetString("slotLocalizationName")
    self.configName = self.data:GetString("configName")

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    local configNameLocal = "quick_equipment_slots_change/configs/name/" .. self.configName
    local slotLocalizationNameFull = "quick_equipment_slots_change/slots/" .. self.slotLocalizationName

    local loadResult = LOAD_RESULT_EMPTY
    local slotsHashToSave = {}

    self.configBySlot = {}

    local playerSlotsArray = {}

    local slotNamesArray = Split( self.slotNamePrefixArray, "," )
    for slotsString in Iter( slotNamesArray ) do

        local loadResultEquipment, slotsHashEquipment, configContent = QuickEquipmentSlotsUtils:GetSaveEquipmentInfo( slotsString, self.configName )

        loadResult = QuickEquipmentSlotsUtils:CombineResults(loadResult, loadResultEquipment)
        slotsHashToSave = QuickEquipmentSlotsUtils:CombineSlotsHashs( slotsHashToSave, slotsHashEquipment )

        local playerSlotsArrayEquipment = QuickEquipmentSlotsUtils:GetPlayerSlotsEquipment( slotsString )

        playerSlotsArray = QuickEquipmentSlotsUtils:CombineSlotsNamesArrays( playerSlotsArray, playerSlotsArrayEquipment )

        if ( loadResultEquipment == LOAD_RESULT_SUCCESS ) then

            self.configBySlot[slotsString] = configContent
        end
    end

    local confimMessage = '${voice_over/announcement/quick_equipment_slots_change/confirming}\r\n<style="header_35">${' .. slotLocalizationNameFull .. '}</style>${voice_over/announcement/quick_equipment_slots_change/confirming_to} <style="header_35">${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/confirming_end}</style>'

    for slotConfig in Iter( playerSlotsArray ) do

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
                end
            end
        end
    end

    LogService:Log("confimMessage " .. confimMessage)

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