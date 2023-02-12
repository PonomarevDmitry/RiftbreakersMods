local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'turn_on_ff_tool' ( tool )

function turn_on_ff_tool:__init()
    tool.__init(self,self)
end

function turn_on_ff_tool:OnInit()

    local setPower = ( self.data:GetIntOrDefault("set_power", 0) == 1 )

    self.setPower = setPower
    
    if ( setPower ) then 
        self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_turn_on", self.entity)
    else
        self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_turn_off", self.entity)
    end   
    
    self.popupShown = false
end

function turn_on_ff_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function turn_on_ff_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function turn_on_ff_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function turn_on_ff_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}
    
    for  ent in Iter(selectedEntities ) do
        if ( EntityService:GetComponent(ent, "ResourceConverterComponent") ~= nil ) then
            Insert(entities, ent)
        end
    end

    return entities
end

function turn_on_ff_tool:OnActivateEntity( entity )

    if( BuildingService:IsPlayerWorking( entity ) ~= self.setPower )  then
        QueueEvent("ChangeBuildingStatusRequest", entity, self.setPower )
    end
end

return turn_on_ff_tool
 