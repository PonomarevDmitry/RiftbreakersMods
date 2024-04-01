local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local LightsUtils = require("lua/utils/lights_utils.lua")

class 'light_switcher_mech_tool' ( tool )

function light_switcher_mech_tool:__init()
    tool.__init(self,self)
end

function light_switcher_mech_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function light_switcher_mech_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self:UpdateMarker()
end

function light_switcher_mech_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function light_switcher_mech_tool:UpdateMarker()

    local markerBlueprint = self.data:GetString("marker")

    if ( self.childEntity == nil or EntityService:GetBlueprintName(self.childEntity) ~= markerBlueprint ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    end
end

function light_switcher_mech_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function light_switcher_mech_tool:AddedToSelection( entity )
end

function light_switcher_mech_tool:RemovedFromSelection( entity )
end

function light_switcher_mech_tool:OnUpdate()
end

function light_switcher_mech_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    return result
end

function light_switcher_mech_tool:OnActivateSelectorRequest()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    if ( player == nil or player == INVALID_ID ) then
        return
    end

    if ( EffectService:HasEffectByGroup(player, "sunset_night_sunrise") ) then

        EffectService:DestroyEffectsByGroup(player, "sunset_night_sunrise")
    else

        EffectService:AttachEffects(player, "sunset_night_sunrise")
    end
end

function light_switcher_mech_tool:OnRotateSelectorRequest(evt)
end

function light_switcher_mech_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return light_switcher_mech_tool