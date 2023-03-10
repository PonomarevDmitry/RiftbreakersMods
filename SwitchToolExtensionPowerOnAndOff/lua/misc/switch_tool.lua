
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

    for ent in Iter(selectedEntities ) do

        if ( EntityService:GetComponent(ent, "ResourceConverterComponent") ~= nil ) then

            if (self:CanChangePower(ent)) then

                Insert(entities, ent)
            end
        end
    end

    return entities
end

function switch_tool:CanChangePower( ent )

    local blueprintName = EntityService:GetBlueprintName( ent )

    if ( blueprintName == nil or blueprintName == "" ) then
        return false
    end

    if ( switch_turn_on_off_toolCache == nil ) then
        switch_turn_on_off_toolCache = {}
    end

    if ( switch_turn_on_off_toolCache[blueprintName] == nil ) then
        switch_turn_on_off_toolCache[blueprintName] = self:CalcCanChangePower( blueprintName )
    end

    return switch_turn_on_off_toolCache[blueprintName]
end

function switch_tool:CalcCanChangePower( blueprintName )

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local resourceConverterDesc = blueprint:GetComponent("ResourceConverterDesc")
    if ( resourceConverterDesc == nil ) then
        return false
    end

    local resourceConverterRef = reflection_helper(resourceConverterDesc)
    if ( resourceConverterRef == nil or resourceConverterRef["in"] == nil ) then
        return false
    end

    local inValue = resourceConverterRef["in"]
    if ( inValue.count == 0 ) then
        return false
    end

    for i = 1,inValue.count do

        local resource = inValue[i]

        if ( resource ~= nil and resource.value ~= nil and resource.value > 0 ) then
            return true
        end
    end

    return false
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
 