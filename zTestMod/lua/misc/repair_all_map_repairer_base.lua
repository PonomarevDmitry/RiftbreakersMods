require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

class 'repair_all_map_repairer_base' ( LuaEntityObject )

function repair_all_map_repairer_base:__init()
    LuaEntityObject.__init(self,self)
end

function repair_all_map_repairer_base:init()

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute", interval=0.25 } )
    self.stateMachine:ChangeState("working")

    self:InitializeValues()

    if ( self.OnInit ) then
        self:OnInit()
    end

    self:OnWorkExecute()
end

function repair_all_map_repairer_base:InitializeValues()

    self.previousSelected = {}
    self.selectedEntities = {}

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest", "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest", "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.action = self.data:GetStringOrDefault( "action", "")

    local scale = { x=1, y=1, z=1 }
    EntityService:SetScale(self.entity, scale.x, scale.y, scale.z)

    local orientation = { x=0, y=0, z=0, w=1 }
    EntityService:SetOrientation( self.entity, orientation )

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )

    self:SpawnCornerBlueprint()
end

function repair_all_map_repairer_base:OnWorkExecute()

    local selectorComponent = EntityService:GetComponent(self.selector, "BuildingSelectorComponent")

    local previousSelection = self.selectedEntities

    self.selectedEntities =  self:FindEntitiesToSelect( reflection_helper(selectorComponent) )

    if ( self.RemovedFromSelection) then
        for ent in Iter( previousSelection ) do 
            if ( IndexOf( self.selectedEntities, ent ) == nil ) then
                self:RemovedFromSelection( ent )
            end
        end
    end



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

            local database = EntityService:GetOrCreateDatabase( entity )
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

function repair_all_map_repairer_base:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function repair_all_map_repairer_base:FindEntitiesToSelect( selectorComponent )

    local result = {}

    return result
end

function repair_all_map_repairer_base:InitLowUpgradeList()

    self.template_name = self.data:GetString("template_name")

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

    self.selectedBlueprints = {}

    self.selectedLowUpgrade = {}

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local blueprintName = self:GetFirstLevelBuilding(self.selectedBuildingBlueprint)

        self:FillSelectedBlueprintsList(self.selectedBlueprints, self.selectedBuildingBlueprint)

        self:FillLowUpgradeList(self.selectedLowUpgrade, self.selectedBuildingBlueprint)

        self:FillCache()
    end
end

function repair_all_map_repairer_base:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function repair_all_map_repairer_base:GetFirstLevelBuilding(blueprintName)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then

        return blueprintName
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef.level == 1 ) then

        return buildingDescRef.bp
    end

    blueprintName = buildingDescRef.bp

    local suffix = "_lvl_" .. tostring(buildingDescRef.level)

    if ( blueprintName:sub(-#suffix) == suffix ) then

        local result = blueprintName:sub(1,-#suffix-1)

        if ( ResourceManager:ResourceExists( "EntityBlueprint", result )  ) then

            local buildingDesc = BuildingService:GetBuildingDesc( result )
            if ( buildingDesc ~= nil ) then

                return result
            end
        end
    end

    return blueprintName
end

function repair_all_map_repairer_base:FillCache()

    self.cacheBlueprintsLowNames = {}

    self.cacheBlueprints = {}

    for blueprintName in Iter( self.selectedBlueprints ) do

        self.cacheBlueprints[blueprintName] = true
    end
end

function repair_all_map_repairer_base:FillLowUpgradeList( list, blueprintName, seenBlueprintList )

    seenBlueprintList = seenBlueprintList or {}

    if ( seenBlueprintList[blueprintName] == true ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc ~= nil ) then

        local buildingDescRef = reflection_helper( buildingDesc )

        self:AddToLowUpgradeList( list, buildingDescRef )

        seenBlueprintList[blueprintName] = true

        if ( buildingDescRef.upgrade ~= "" and buildingDescRef.upgrade ~= nil ) then

            self:FillLowUpgradeList( list, buildingDescRef.upgrade, seenBlueprintList )
        end

        local buildingDescRef = reflection_helper( buildingDesc )

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                self:FillLowUpgradeList( list, connectBlueprintName, seenBlueprintList )
            end
        end
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if (baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper(baseBuildingDesc)

        if ( baseBuildingDescRef.bp ~= blueprintName ) then

            self:FillLowUpgradeList( list, baseBuildingDescRef.bp, seenBlueprintList )
        end
    end
end

function repair_all_map_repairer_base:AddToLowUpgradeList( list, buildingDescRef )

    local lowName = BuildingService:FindLowUpgrade( buildingDescRef.bp )

    if ( IndexOf( list, lowName ) == nil ) then
        Insert( list, lowName )
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            lowName = BuildingService:FindLowUpgrade( connectBlueprintName )

            if ( IndexOf( list, lowName ) == nil ) then
                Insert( list, lowName )
            end
        end
    end
end

function repair_all_map_repairer_base:FillSelectedBlueprintsList( list, blueprintName, seenBlueprintList )

    seenBlueprintList = seenBlueprintList or {}

    if ( seenBlueprintList[blueprintName] == true ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc ~= nil ) then

        local buildingDescRef = reflection_helper( buildingDesc )

        self:AddToSelectedBlueprintsList( list, buildingDescRef )

        seenBlueprintList[blueprintName] = true

        if ( buildingDescRef.upgrade ~= "" and buildingDescRef.upgrade ~= nil ) then

            self:FillSelectedBlueprintsList( list, buildingDescRef.upgrade, seenBlueprintList )
        end

        local buildingDescRef = reflection_helper( buildingDesc )

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                self:FillSelectedBlueprintsList( list, connectBlueprintName, seenBlueprintList )
            end
        end
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if (baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper(baseBuildingDesc)

        if ( baseBuildingDescRef.bp ~= blueprintName ) then

            self:FillSelectedBlueprintsList( list, baseBuildingDescRef.bp, seenBlueprintList )
        end
    end
end

function repair_all_map_repairer_base:AddToSelectedBlueprintsList( list, buildingDescRef )

    if ( IndexOf( list, buildingDescRef.bp ) == nil ) then

        Insert( list, buildingDescRef.bp )
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            if ( IndexOf( list, connectBlueprintName ) == nil ) then
                Insert( list, connectBlueprintName )
            end
        end
    end
end

function repair_all_map_repairer_base:IsBlueprintInList( blueprintName )

    if ( #self.selectedBlueprints == 0 ) then
        return false
    end

    if ( self.cacheBlueprints[blueprintName] ~= nil ) then

        return self.cacheBlueprints[blueprintName]
    end

    local result = self:CalcIsBlueprintInList( blueprintName )

    self.cacheBlueprints[blueprintName] = result

    return result
end

function repair_all_map_repairer_base:CalcIsBlueprintInList( blueprintName )

    if ( #self.selectedBlueprints == 0 ) then
        return false
    end

    if ( IndexOf( self.selectedBlueprints, blueprintName ) ~= nil ) then
        return true
    end

    local firstLevelBlueprintName = self:GetFirstLevelBuilding(blueprintName)

    local list = {}

    self:FillSelectedBlueprintsList(list, firstLevelBlueprintName)

    for itemBlueprintName in Iter( list ) do

        if ( IndexOf( self.selectedBlueprints, itemBlueprintName ) ~= nil ) then
            return true
        end
    end

    return false
end

function repair_all_map_repairer_base:IsBlueprintInLowNameList( blueprintName )

    if ( #self.selectedLowUpgrade == 0 ) then
        return false
    end

    if ( self.cacheBlueprintsLowNames[blueprintName] ~= nil ) then

        return self.cacheBlueprintsLowNames[blueprintName]
    end

    local result = self:CalcIsBlueprintInLowNameList( blueprintName )

    self.cacheBlueprintsLowNames[blueprintName] = result

    return result
end

function repair_all_map_repairer_base:CalcIsBlueprintInLowNameList( blueprintName )

    if ( #self.selectedLowUpgrade == 0 ) then
        return false
    end

    local firstLevelBlueprintName = self:GetFirstLevelBuilding(blueprintName)

    local list = {}

    self:FillLowUpgradeList(list, firstLevelBlueprintName)

    for lowName in Iter( list ) do

        if ( IndexOf( self.selectedLowUpgrade, lowName ) ~= nil ) then
            return true
        end
    end

    return false
end

function repair_all_map_repairer_base:GetMenuIcon( blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = buildingDescRef.menu_icon or ""
    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            local connectMenuIcon = self:GetBuildingMenuIcon( connectBlueprintName )

            if ( connectMenuIcon ~= "" ) then

                return connectMenuIcon
            end
        end
    end

    return ""
end

function repair_all_map_repairer_base:GetBuildingMenuIcon( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = buildingDescRef.menu_icon or ""
    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end

    return ""
end

function repair_all_map_repairer_base:GetBlueprintName( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetOrCreateDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            blueprintName = database:GetString("blueprint")
        end
    end

    blueprintName = blueprintName or ""

    return blueprintName
end

function repair_all_map_repairer_base:OnRelease()

    if ( self.RemovedFromSelection ) then
        for ent in Iter(self.selectedEntities ) do
            self:RemovedFromSelection( ent )
        end
    end

    if ( self.corners ~= nil) then
        EntityService:RemoveEntity(self.corners)
        self.corners = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end
end

return repair_all_map_repairer_base
