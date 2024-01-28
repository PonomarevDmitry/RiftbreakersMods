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
    self.slotName = self.data:GetString("slotName")
    self.configName = self.data:GetString("configName")

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    local configNameLocal = "quick_equipment_slots_change/configs/name/" .. self.configName
    local slotNameLocal = "quick_equipment_slots_change/slots/" .. self.slotName

    local confimMessage = '${voice_over/announcement/quick_equipment_slots_change/confirming} <style="header_35">${' .. slotNameLocal .. '}</style>${voice_over/announcement/quick_equipment_slots_change/confirming_to} <style="header_35">${' .. configNameLocal .. '}${voice_over/announcement/quick_equipment_slots_change/confirming_end}</style>'

    GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", confimMessage)
end

function quick_equipment_slots_save_entity:OnGuiPopupResultEvent( evt)

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        local slotNamesArray = Split( self.slotNamePrefixArray, "," )

        for slotsString in Iter( slotNamesArray ) do

            QuickEquipmentSlotsUtils:SaveEquipment( slotsString, self.configName )
        end

        local configNameLocal = "quick_equipment_slots_change/configs/name/" .. self.configName
        local slotNameLocal = "quick_equipment_slots_change/slots/" .. self.slotName

        local fullAnnouncement = '${voice_over/announcement/quick_equipment_slots_change/saving} <style="header_35">${' .. slotNameLocal .. '}</style>${voice_over/announcement/quick_equipment_slots_change/saving_to} <style="header_35">${' .. configNameLocal .. '}</style>${voice_over/announcement/quick_equipment_slots_change/saving_end}'

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