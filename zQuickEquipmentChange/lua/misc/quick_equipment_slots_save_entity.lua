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

    self.slotNamePrefix = self.data:GetString("slotNamePrefix")
    self.configName = self.data:GetString("configName")
    self.announcement = self.data:GetString("announcement")
    self.confirm = self.data:GetString("confirm")

    self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", self.confirm)
end

function quick_equipment_slots_save_entity:OnGuiPopupResultEvent( evt)

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        local slotNamesArray = Split( self.slotNamePrefix, "," )

        for slotsString in Iter( slotNamesArray ) do

            QuickEquipmentSlotsUtils:SaveEquipment( slotsString, self.configName )
        end

        SoundService:PlayAnnouncement( self.announcement, 0 )
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