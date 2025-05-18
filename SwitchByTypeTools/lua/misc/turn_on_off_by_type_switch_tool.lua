local turn_on_off_by_type_base = require("lua/misc/turn_on_off_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local PowerUtils = require("lua/utils/power_utils.lua")

class 'turn_on_off_by_type_switch_tool' ( turn_on_off_by_type_base )

function turn_on_off_by_type_switch_tool:__init()
    turn_on_off_by_type_base.__init(self,self)
end

function turn_on_off_by_type_switch_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self:InitLowUpgradeList()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("menu_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetString("message_text", "")
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/turn_by_type_tools/building_not_selected")
        end
    else

        markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("message_text", "gui/hud/turn_by_type_tools/building_not_selected")
    end




    self.setPower = ( self.data:GetIntOrDefault("set_power", 0) == 1 )
    self.isGroup = (self.data:GetIntOrDefault("is_group", 0) == 1)

    self:SetTypeSetting()

    self.previousMarkedBuildings = {}
    self.radiusShowBuildings = 100.0
end

function turn_on_off_by_type_switch_tool:SetTypeSetting()

    self.selectedType = ""

    if ( self.selectedBuildingBlueprint == "" ) then
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( self.selectedBuildingBlueprint )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper( buildingDesc )

    if ( buildingDescRef.type == nil or buildingDescRef.type == "" ) then
        return
    end

    self.selectedType = buildingDescRef.type
end

function turn_on_off_by_type_switch_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function turn_on_off_by_type_switch_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function turn_on_off_by_type_switch_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        if ( EntityService:GetComponent(entity, "ResourceConverterComponent") == nil ) then
            goto continue
        end

        if ( not PowerUtils:CanChangePower(entity)) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        if( BuildingService:IsPlayerWorking( entity ) == self.setPower ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function turn_on_off_by_type_switch_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName(entity)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    if ( EntityService:GetComponent(entity, "ResourceConverterComponent") == nil ) then
        return false
    end

    if ( not PowerUtils:CanChangePower(entity) ) then
        return false
    end

    if ( self.isGroup ) then

        if ( self:IsBlueprintInLowNameList(blueprintName) ) then
            return true
        end

        if ( self.selectedType == "tower" or self.selectedType == "trap" or self.selectedType == "gate" ) then

            local buildingDescRef = reflection_helper( buildingDesc )

            if ( buildingDescRef.type == self.selectedType ) then
                return true
            end
        end
    else

        if ( self:IsBlueprintInList(blueprintName) ) then
            return true
        end
    end

    return false
end

function turn_on_off_by_type_switch_tool:OnUpdate()

    local availableBuildinsList = self:FindBuildingAvailable()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    for entity in Iter( self.previousMarkedBuildings ) do

        if ( IndexOf( availableBuildinsList, entity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        self:RemovedFromSelection( entity )

        ::continue::
    end

    for entity in Iter( availableBuildinsList ) do

        local skinned = EntityService:IsSkinned( entity )
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
        end
    end

    self.previousMarkedBuildings = availableBuildinsList

    for entity in Iter( self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
        end
    end
end

function turn_on_off_by_type_switch_tool:FindBuildingAvailable()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildings )

    local result = {}

    for entity in Iter( buildings ) do

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function turn_on_off_by_type_switch_tool:OnRotate()
end

function turn_on_off_by_type_switch_tool:OnRelease()

    if ( self.previousMarkedBuildings ~= nil) then
        for ent in Iter( self.previousMarkedBuildings ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( turn_on_off_by_type_base.OnRelease ) then
        turn_on_off_by_type_base.OnRelease(self)
    end
end

function turn_on_off_by_type_switch_tool:OnActivateEntity( entity )

    if( BuildingService:IsPlayerWorking( entity ) ~= self.setPower ) then
        QueueEvent( "ChangeBuildingStatusRequest", entity, self.setPower )
    end
end

return turn_on_off_by_type_switch_tool