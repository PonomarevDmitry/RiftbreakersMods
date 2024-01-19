local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'damage_buildings_tool' ( tool )

function damage_buildings_tool:__init()
    tool.__init(self,self)
end

function damage_buildings_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_damage_buildings_tool", self.entity)
end

function damage_buildings_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function damage_buildings_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function damage_buildings_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function damage_buildings_tool:OnRotate()
end

function damage_buildings_tool:OnActivateEntity( entity )

    local damageValue = HealthService:GetHealth( entity ) / 4

    QueueEvent( "DamageRequest", entity, damageValue, "physical", 1, 0 )
end

return damage_buildings_tool
