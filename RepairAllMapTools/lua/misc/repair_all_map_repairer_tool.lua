local repair_all_map_base = require("lua/misc/repair_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'repair_all_map_repairer_tool' ( repair_all_map_base )

function repair_all_map_repairer_tool:__init()
    repair_all_map_base.__init(self,self)
end

function repair_all_map_repairer_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_repairer_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self.isGroup = false
    self.currentChildIsGroup = nil

    self:UpdateMarker()
end

function repair_all_map_repairer_tool:UpdateMarker()

    local messageText = ""
    local groupString = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.isGroup ) then
        messageText = "gui/hud/repair_all_map/building_group"
        groupString = "_by_group"

        markerBlueprint = self.data:GetString("marker_group")
    end

    if ( self.childEntity == nil or self.currentChildIsGroup ~= self.isGroup ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        
        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        self.currentChildIsGroup = self.isGroup
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
            markerDB:SetString("message_text", "gui/hud/repair_all_map/building_not_selected")
        end
    else

        markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("message_text", "gui/hud/repair_all_map/building_not_selected")
    end
end

function repair_all_map_repairer_tool:SetTypeSetting()

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

function repair_all_map_repairer_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_repairer_tool:AddedToSelection( entity )
end

function repair_all_map_repairer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function repair_all_map_repairer_tool:OnUpdate()

    self.upgradeCosts = {}

    local upgradeCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] ~= nil ) then
            goto continue
        end

        upgradeCostsEntities[entity] = true

        local skinned = EntityService:IsSkinned(entity)



        local blueprintName = self:GetBlueprintName( entity )
        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
        end

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto continue
        end

        local list = BuildingService:GetUpgradeCosts( entity, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.upgradeCosts[resourceCost.first] == nil ) then
                self.upgradeCosts[resourceCost.first] = 0
            end

            self.upgradeCosts[resourceCost.first] = self.upgradeCosts[resourceCost.first] + resourceCost.second
        end

        ::continue::
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, self.upgradeCosts )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, self.upgradeCosts )
    end
end

function repair_all_map_repairer_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local healthComponent = EntityService:GetComponent(entity, "HealthComponent")
        if ( healthComponent == nil ) then
            goto continue
        end

        local healthComponentRef = reflection_helper(healthComponent)

        if ( healthComponentRef.health < healthComponentRef.max_health ) then
            Insert( result, entity )
            goto continue
        end

        local database = EntityService:GetDatabase( entity )
        if ( database and database:HasInt("number_of_activations")) then

            local currentNumberOfActivations =  database:GetInt("number_of_activations")

            local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )
            local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")

            if ( maxNumberOfActivations > currentNumberOfActivations ) then
                Insert( result, entity )
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

function repair_all_map_repairer_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
        return false
    end

    local blueprintName = self:GetBlueprintName(entity)
    if ( blueprintName == "" ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
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

function repair_all_map_repairer_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentGroupValue = self:CheckGroupValueExists(self.isGroup)

    local groupValuesArray = self:GetGroupValuesArray()

    local index = IndexOf( groupValuesArray, currentGroupValue )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #groupValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = groupValuesArray[newIndex]

    self.isGroup = newValue

    self:UpdateMarker()
end

function repair_all_map_repairer_tool:CheckGroupValueExists( groupValue )

    local groupValuesArray = self:GetGroupValuesArray()

    groupValue = groupValue or groupValuesArray[1]

    local index = IndexOf(groupValuesArray, groupValue )

    if ( index == nil ) then

        return groupValuesArray[1]
    end

    return groupValue
end

function repair_all_map_repairer_tool:GetGroupValuesArray()

    if ( self.groupValuesArray == nil ) then

        self.groupValuesArray = { false, true }
    end

    return self.groupValuesArray
end

function repair_all_map_repairer_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        if ( EntityService:GetGroup( entity ) == "##ruins##" ) then

            local database = EntityService:GetDatabase( entity )
            if ( database ) then

                local ruinsBlueprint = database:GetString("blueprint")

                local transform = EntityService:GetWorldTransform( entity )

                QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, ruinsBlueprint, transform, true )
            end
        else
            local child = EntityService:GetChildByName(entity, "##repair##")

            if ( BuildingService:CanAffordRepair( entity, self.playerId, -1 ) and not EntityService:IsAlive(child) ) then

                local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
                if ( buildingComponent ~= nil ) then

                    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
                    if ( mode ~= 2 ) then
                        return
                    end
                end

                QueueEvent( "ScheduleRepairBuildingRequest", entity, self.playerId )

                local database = EntityService:GetDatabase( entity )
                if ( database and database:HasInt("number_of_activations")) then

                    local currentNumberOfActivations =  database:GetInt("number_of_activations")

                    local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )
                    local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")

                    if ( maxNumberOfActivations > currentNumberOfActivations ) then
                        database:SetInt("number_of_activations", maxNumberOfActivations)
                    end
                end
            end
        end
    end
end

return repair_all_map_repairer_tool