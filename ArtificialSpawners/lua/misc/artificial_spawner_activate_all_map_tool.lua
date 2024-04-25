local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'artificial_spawner_activate_all_map_tool' ( tool )

function artificial_spawner_activate_all_map_tool:__init()
    tool.__init(self,self)
end

function artificial_spawner_activate_all_map_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_artificial_spawner_activate_all_map_tool", self.entity)

    self.scaleMap = {
        1,
    }
end

function artificial_spawner_activate_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function artificial_spawner_activate_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function artificial_spawner_activate_all_map_tool:FindEntitiesToSelect( selectorComponent )

    local possibleSelectedEnts = {}

    return possibleSelectedEnts
end

function artificial_spawner_activate_all_map_tool:AddedToSelection( entity )
end

function artificial_spawner_activate_all_map_tool:RemovedFromSelection( entity )
end

function artificial_spawner_activate_all_map_tool:OnRotate()
end

function artificial_spawner_activate_all_map_tool:OnActivateSelectorRequest()


end

return artificial_spawner_activate_all_map_tool
