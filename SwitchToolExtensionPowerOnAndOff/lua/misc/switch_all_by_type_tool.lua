local turn_on_off_by_type_base = require("lua/misc/turn_on_off_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local PowerUtils = require("lua/utils/power_utils.lua")

class 'switch_all_by_type_tool' ( turn_on_off_by_type_base )

function switch_all_by_type_tool:__init()
    turn_on_off_by_type_base.__init(self,self)
end

function switch_all_by_type_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function switch_all_by_type_tool:OnInit()

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self.scaleMap = {
        1,
    }

    self.powerValuesArray = { false, true }

    self.configName = "$switch_all_by_type_tool_config"

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.setPower = (selectorDB:GetIntOrDefault(self.configName, 0) == 1)
    self.currentChildSetPower = nil

    self.isGroup = (self.data:GetIntOrDefault("is_group", 0) == 1)

    self:UpdateMarker()
end

function switch_all_by_type_tool:UpdateMarker()

    local setPowerString = ""

    if ( self.setPower ) then
        setPowerString = "on"
    else
        setPowerString = "off"
    end

    local messageText = "gui/hud/building_name/turn_" .. setPowerString .. "_tool"

    if ( self.childEntity == nil or self.currentChildSetPower ~= self.setPower ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        local markerTemplate = self.data:GetString("marker_template")
        local markerBlueprint = markerTemplate .. "_" .. setPowerString

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        -- Save number of wall layers
        self.currentChildSetPower = self.setPower
    end

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("building_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetString("message_text", messageText)
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/turn_on_off_tools/building_not_selected")
        end
    else

        markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("message_text", "gui/hud/turn_on_off_tools/building_not_selected")
    end
end

function switch_all_by_type_tool:SetTypeSetting()

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

function switch_all_by_type_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function switch_all_by_type_tool:AddedToSelection( entity )
end

function switch_all_by_type_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function switch_all_by_type_tool:OnUpdate()

    self.upgradeCosts = {}

    for entity in Iter( self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
        end

        ::continue::
    end
end

function switch_all_by_type_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
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

        Insert( result, entity )

        ::continue::
    end

    local distances = {}

    for entity in Iter( result ) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(result, sorter)

    return result
end

function switch_all_by_type_tool:IsEntityApproved( entity )

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

function switch_all_by_type_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentPowerValue = self:CheckPowerValueExists(self.setPower)

    local index = IndexOf( self.powerValuesArray, currentPowerValue )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.powerValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.powerValuesArray[newIndex]

    self.setPower = newValue

    local savedValue = 0;
    if ( newValue ) then
        savedValue = 1;
    end
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configName, savedValue)

    self:UpdateMarker()
end

function switch_all_by_type_tool:CheckPowerValueExists( powerValue )

    powerValue = powerValue or self.powerValuesArray[1]

    local index = IndexOf(self.powerValuesArray, powerValue )

    if ( index == nil ) then

        return powerValuesArray[1]
    end

    return powerValue
end

function switch_all_by_type_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        if( BuildingService:IsPlayerWorking( entity ) ~= self.setPower ) then
            QueueEvent( "ChangeBuildingStatusRequest", entity, self.setPower )
        end

        ::continue::
    end
end

return switch_all_by_type_tool