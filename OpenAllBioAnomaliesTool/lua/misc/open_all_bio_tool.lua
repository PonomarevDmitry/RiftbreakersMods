local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'open_all_bio_tool' ( tool )

function open_all_bio_tool:__init()
    tool.__init(self,self)
end

function open_all_bio_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function open_all_bio_tool:OnInit()

    local markerName = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity( markerName, self.entity )

    self.scaleMap = {
        1,
    }
end

function open_all_bio_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function open_all_bio_tool:AddedToSelection( entity )
end

function open_all_bio_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function open_all_bio_tool:OnUpdate()
end

function open_all_bio_tool:OnActivateSelectorRequest()

    local activatedEntities = {}

    local entities = FindService:FindEntitiesByGroup( "loot_container" )

    for entity in Iter( entities ) do

        if ( IndexOf( activatedEntities, entity ) ~= nil ) then
            goto continue
        end

        QueueEvent( "HarvestStartEvent", entity )

        Insert( activatedEntities, ruinEntity )

        ::continue::
    end
end

function open_all_bio_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function open_all_bio_tool:OnRotateSelectorRequest(evt)
end

return open_all_bio_tool