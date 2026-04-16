local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'floor_under_buildings_tool' ( tool )

function floor_under_buildings_tool:__init()
    tool.__init(self,self)
end

function floor_under_buildings_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.announcements = {
        ["ai"] = "voice_over/announcement/not_enough_ai_cores",

        ["carbonium"] = "voice_over/announcement/not_enough_carbonium",
        ["steel"] = "voice_over/announcement/not_enough_steel",

        ["cobalt"] = "voice_over/announcement/not_enough_cobalt",
        ["palladium"] = "voice_over/announcement/not_enough_palladium",
        ["titanium"] = "voice_over/announcement/not_enough_titanium",
        ["uranium"] = "voice_over/announcement/not_enough_uranium"
    }

    self.floorBlueprintName = self.data:GetString("blueprintName")
end

function floor_under_buildings_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function floor_under_buildings_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function floor_under_buildings_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function floor_under_buildings_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function floor_under_buildings_tool:OnRotate()
end

function floor_under_buildings_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local blueprintName = self.floorBlueprintName

    local gridSize = BuildingService:GetBuildingGridSize(entity)

    local currentTransform = EntityService:GetWorldTransform( entity )

    local transform = {}
    transform.position = currentTransform.position
    transform.orientation = { x=0, y=0, z=0, w=1}
    transform.scale = { x = gridSize.x, y = 1, z = gridSize.z}

    QueueEvent( "BuildFloorRequest", self.entity, self.playerId, blueprintName, transform )
end

return floor_under_buildings_tool
