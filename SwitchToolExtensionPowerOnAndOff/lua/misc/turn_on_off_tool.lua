local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

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

function turn_on_ff_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)

    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function turn_on_ff_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function turn_on_ff_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function turn_on_ff_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for ent in Iter( selectedEntities ) do

        if ( EntityService:GetComponent(ent, "ResourceConverterComponent") ~= nil ) then

            if (self:CanChangePower(ent)) then

                Insert(entities, ent)
            end
        end
    end

    return entities
end

function turn_on_ff_tool:CanChangePower( ent )

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

function turn_on_ff_tool:CalcCanChangePower( blueprintName )

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

function turn_on_ff_tool:OnActivateEntity( entity )

    if( BuildingService:IsPlayerWorking( entity ) ~= self.setPower ) then
        QueueEvent( "ChangeBuildingStatusRequest", entity, self.setPower )
    end
end

return turn_on_ff_tool