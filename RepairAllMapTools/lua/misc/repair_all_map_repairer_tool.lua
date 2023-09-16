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

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1 )
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

    self.repairCosts = {}

    local repairCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( repairCostsEntities[entity] ~= nil ) then
            goto continue
        end

        repairCostsEntities[entity] = true


        local isRuins = ( EntityService:GetGroup( entity ) == "##ruins##" )

        if ( not isRuins ) then

            if ( not BuildingService:IsBuildingFinished( entity ) ) then
                goto continue
            end
        end

        local blueprintName = self:GetBlueprintName( entity )
        if ( blueprintName == "" ) then
            goto continue
        end

        local skinned = EntityService:IsSkinned(entity)

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
        end

        local list = {}

        if ( isRuins ) then

            local database = EntityService:GetDatabase( entity )
            if ( database ) then

                local ruinsBlueprint = database:GetString("blueprint")

                list = BuildingService:GetBuildCosts( ruinsBlueprint, self.playerId )
            end
        else

            list = BuildingService:GetRepairCosts( entity )
        end

        for resourceCost in Iter(list) do

            if ( self.repairCosts[resourceCost.first] == nil ) then
                self.repairCosts[resourceCost.first] = 0
            end

            self.repairCosts[resourceCost.first] = self.repairCosts[resourceCost.first] + resourceCost.second
        end

        ::continue::
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateRepairCosts( self.infoChild, self.playerId, self.repairCosts )
        BuildingService:OperateRepairCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateRepairCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateRepairCosts( self.corners, self.playerId, self.repairCosts )
    end
end

function repair_all_map_repairer_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = self:FindRepairableBuildings()

    ConcatUnique( result, entitiesBuildings )

    local ruins = self:FindRuins()

    ConcatUnique( result, ruins )

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

function repair_all_map_repairer_tool:FindRepairableBuildings()

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

        local childRepair = EntityService:GetChildByName( entity, "##repair##" )

        if ( childRepair ~= INVALID_ID and EntityService:IsAlive(childRepair) ) then
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

    return result
end

function repair_all_map_repairer_tool:FindRuins()

    local result = {}

    local ruins = FindService:FindEntitiesByGroup( "##ruins##" )

    for entity in Iter( ruins ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetDatabase( entity )
        if ( not database ) then
            goto continue
        end
        
        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local blueprintName = database:GetString("blueprint")
        if ( blueprintName == "" ) then
            goto continue
        end

        if ( not self:IsBlueprintApproved(blueprintName) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function repair_all_map_repairer_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode ~= 2 ) then
        return false
    end

    if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
        return false
    end

    local blueprintName = self:GetBlueprintName(entity)
    if ( blueprintName == "" ) then
        return false
    end

    if ( self:IsBlueprintApproved( blueprintName ) ) then
        return true
    end

    return false
end

function repair_all_map_repairer_tool:IsBlueprintApproved( blueprintName )

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

    self:OnWorkExecute()
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
            local childRepair = EntityService:GetChildByName(entity, "##repair##")

            if ( BuildingService:CanAffordRepair( entity, self.playerId, -1 ) and not EntityService:IsAlive(childRepair) ) then

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

function repair_all_map_repairer_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( repair_all_map_base.OnRelease ) then
        repair_all_map_base.OnRelease(self)
    end
end

return repair_all_map_repairer_tool