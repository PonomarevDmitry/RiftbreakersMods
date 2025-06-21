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

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function damage_buildings_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function damage_buildings_tool:OnRotate()
end

function damage_buildings_tool:OnActivateEntity( entity )

    local damageValue = HealthService:GetHealth( entity ) / 4

    QueueEvent( "DamageRequest", entity, damageValue, "physical", 1, 0 )


    local database = EntityService:GetOrCreateDatabase( entity )
    if ( database and database:HasInt("number_of_activations")) then

        local currentNumberOfActivations =  database:GetInt("number_of_activations")

        --local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )

        --local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")
        
        currentNumberOfActivations = math.ceil(currentNumberOfActivations / 4)

        database:SetInt("number_of_activations", math.max(1, currentNumberOfActivations))
    end
end

return damage_buildings_tool
