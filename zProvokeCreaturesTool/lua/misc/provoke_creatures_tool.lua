local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'provoke_creatures_tool' ( tool )

function provoke_creatures_tool:__init()
    tool.__init(self,self)
end

function provoke_creatures_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_provoke_creatures_tool", self.entity)

    self.scaleMap = {
        1,
    }

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)
end

function provoke_creatures_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function provoke_creatures_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function provoke_creatures_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function provoke_creatures_tool:AddedToSelection( entity )
end

function provoke_creatures_tool:RemovedFromSelection( entity )
end

function provoke_creatures_tool:OnRotate()
end

function provoke_creatures_tool:OnActivateSelectorRequest()

    EffectService:SpawnEffect( self.entity, "effects/enemies_generic/wave_start" )

    EntityService:ChangeAIGroupsToAggressive( self.entity, 100, false )
end

return provoke_creatures_tool
