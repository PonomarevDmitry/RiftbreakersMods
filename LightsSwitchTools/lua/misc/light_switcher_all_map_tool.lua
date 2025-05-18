local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local LightsUtils = require("lua/utils/lights_utils.lua")

class 'light_switcher_all_map_tool' ( tool )

function light_switcher_all_map_tool:__init()
    tool.__init(self,self)
end

function light_switcher_all_map_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function light_switcher_all_map_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.modeTurnOff = 0
    self.modeTurnOn = 1

    self.modeValuesArray = { self.modeTurnOff, self.modeTurnOn }

    self.selectedMode = self.modeTurnOff

    self:UpdateMarker()
end

function light_switcher_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function light_switcher_all_map_tool:UpdateMarker()

    local messageText = ""

    local markerBlueprint = self.data:GetString("marker_on")

    if ( self.selectedMode == self.modeTurnOn ) then

        markerBlueprint = self.data:GetString("marker_on")

        messageText = "${gui/hud/lights_switch_all_map/lights_on}"

    elseif ( self.selectedMode == self.modeTurnOff ) then

        markerBlueprint = self.data:GetString("marker_off")

        messageText = "${gui/hud/lights_switch_all_map/lights_off}"
    end

    if ( self.childEntity == nil or EntityService:GetBlueprintName(self.childEntity) ~= markerBlueprint ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    end

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("menu_visible", 1)
    markerDB:SetString("message_text", messageText)
end

function light_switcher_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function light_switcher_all_map_tool:AddedToSelection( entity )
end

function light_switcher_all_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function light_switcher_all_map_tool:OnUpdate()

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

function light_switcher_all_map_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    local setPower = ( self.selectedMode == self.modeTurnOn )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( self:IsEntityApproved(entity, "lamp") ) then

            Insert(result, entity)

        elseif ( lowName == "base_lamp" or lowName == "crystal_lamp" ) then

            if( setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "working") ) then

                    Insert(result, entity)
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "working") ) then

                    Insert(result, entity)
                end
            end
        end

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

function light_switcher_all_map_tool:IsEntityApproved( entity, effectGroupName )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( not LightsUtils:BlueprintHasEffectGroup( blueprintName, effectGroupName ) ) then

        return false
    end

    local setPower = ( self.selectedMode == self.modeTurnOn )

    if( setPower ) then

        if ( not EffectService:HasEffectByGroup(entity, effectGroupName) ) then

            return true
        end
    else

        if ( EffectService:HasEffectByGroup(entity, effectGroupName) ) then

            return true
        end
    end

    return false
end

function light_switcher_all_map_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    local setPower = ( self.selectedMode == self.modeTurnOn )

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName == "base_lamp" or lowName == "crystal_lamp" ) then

            if( setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "working") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:AttachEffects(entity, "working")
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "working") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:DestroyEffectsByGroup(entity, "working")
                end
            end

        else

            if( setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "lamp") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:AttachEffects(entity, "lamp")
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "lamp") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:DestroyEffectsByGroup(entity, "lamp")
                end
            end
        end
    end
end

function light_switcher_all_map_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local selectedMode = self:CheckModeValueExists(self.selectedMode)

    local index = IndexOf( self.modeValuesArray, selectedMode )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.modeValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.modeValuesArray[newIndex]

    self.selectedMode = newValue

    self:UpdateMarker()
end

function light_switcher_all_map_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function light_switcher_all_map_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return light_switcher_all_map_tool