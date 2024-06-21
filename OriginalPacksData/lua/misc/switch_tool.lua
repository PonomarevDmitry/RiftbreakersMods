
local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'switch_tool' ( tool )

function switch_tool:__init()
    tool.__init(self,self)
end

function switch_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_switch", self.entity)
    self.popupShown = false
end

function switch_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function switch_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function switch_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end


function switch_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}
    for  ent in Iter(selectedEntities ) do
        local component = EntityService:GetComponent(ent, "ResourceConverterComponent")
        if ( component ~= nil ) then
            local blueprintName = EntityService:GetBlueprintName(ent)
            local buildingComponent = EntityService:GetBlueprintComponent(blueprintName, "BuildingDesc")
            if ( buildingComponent ~= nil and buildingComponent:GetField( "disableable" ):GetValue() == "1" ) then
                --LogService:Log( blueprintName .. " " .. buildingComponent:GetField( "disableable" ):GetValue())
                Insert(entities, ent)
            end
        end
    end

    return entities
end

function switch_tool:OnActivateSelectorRequest()

    local haveOff = false
    local haveOn = false
    for entity in Iter( self.selectedEntities ) do
        if( BuildingService:IsPlayerWorking( entity )) then
            haveOn = true
        else
            haveOff = true
        end
    end

    if ( haveOn ~= haveOff ) then
        for entity in Iter( self.selectedEntities ) do
            QueueEvent("ChangeBuildingStatusRequest", entity, haveOff )
        end
    else
        for entity in Iter( self.selectedEntities ) do
            if( not BuildingService:IsPlayerWorking( entity )) then
                QueueEvent("ChangeBuildingStatusRequest", entity, true )
            end
        end
    end


end


return switch_tool
 