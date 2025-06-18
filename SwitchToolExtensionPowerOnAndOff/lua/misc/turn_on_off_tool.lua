local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

local PowerUtils = require("lua/utils/power_utils.lua")

class 'turn_on_ff_tool' ( tool )

function turn_on_ff_tool:__init()
    tool.__init(self,self)
end

function turn_on_ff_tool:OnInit()

    self.setPower = ( self.data:GetIntOrDefault("set_power", 0) == 1 )

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity( marker_name, self.entity )

    self.popupShown = false
end

function turn_on_ff_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function turn_on_ff_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
        end

        ::continue::
    end
end

function turn_on_ff_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)

    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function turn_on_ff_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function turn_on_ff_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( EntityService:GetComponent(entity, "ResourceConverterComponent") ~= nil ) then

            if (PowerUtils:CanChangePower(entity)) then

                if( BuildingService:IsPlayerWorking( entity ) ~= self.setPower ) then
                    Insert(entities, entity)
                end
            end
        end
    end

    return entities
end

function turn_on_ff_tool:OnActivateEntity( entity )

    if( BuildingService:IsPlayerWorking( entity ) ~= self.setPower ) then
        QueueEvent( "ChangeBuildingStatusRequest", entity, self.setPower )
    end
end

return turn_on_ff_tool