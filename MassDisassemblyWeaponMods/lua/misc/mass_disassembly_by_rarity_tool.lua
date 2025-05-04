local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'mass_disassembly_by_rarity_tool' ( tool )

function mass_disassembly_by_rarity_tool:__init()
    tool.__init(self,self)
end

function mass_disassembly_by_rarity_tool:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_mass_disassembly_by_rarity_tool", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.scaleMap = {
        1,
    }

    self.data:SetInt("slot_visible_1", 0)
    self.data:SetInt("slot_visible_2", 0)
    self.data:SetInt("slot_visible_3", 0)

    self.data:SetInt("slot_time_visible_1", 0)
    self.data:SetInt("slot_time_visible_2", 0)
    self.data:SetInt("slot_time_visible_3", 0)

    self.data:SetInt("slot_rarity_1", 0)
    self.data:SetInt("slot_rarity_2", 0)
    self.data:SetInt("slot_rarity_3", 0)

    self.data:SetString("slot_icon_1", "")
    self.data:SetString("slot_icon_2", "")
    self.data:SetString("slot_icon_3", "")

    self.data:SetString("slot_name_1", "")
    self.data:SetString("slot_name_2", "")
    self.data:SetString("slot_name_3", "")

    self.data:SetInt("menu_visible", 0)
end

function mass_disassembly_by_rarity_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function mass_disassembly_by_rarity_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function mass_disassembly_by_rarity_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function mass_disassembly_by_rarity_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function mass_disassembly_by_rarity_tool:OnUpdate()
end

function mass_disassembly_by_rarity_tool:AddedToSelection( entity )
end

function mass_disassembly_by_rarity_tool:RemovedFromSelection( entity )
end

function mass_disassembly_by_rarity_tool:OnRotate()
end

function mass_disassembly_by_rarity_tool:OnActivateSelectorRequest()

















end

function mass_disassembly_by_rarity_tool:OnGuiPopupResultEvent( evt )











end

return mass_disassembly_by_rarity_tool
