local replace_tower_base = require("lua/misc/replace_tower_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_tower_replacer_from_to_tool' ( replace_tower_base )

function replace_tower_replacer_from_to_tool:__init()
    replace_tower_base.__init(self,self)
end

function replace_tower_replacer_from_to_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.missing_localization_from = self.data:GetStringOrDefault("missing_localization_from", "") or ""
    self.missing_localization_to = self.data:GetStringOrDefault("missing_localization_to", "") or ""

    self.template_name_from = self.data:GetStringOrDefault("template_name_from", "") or ""
    self.template_grid_from = self.data:GetStringOrDefault("template_grid_from", "") or ""

    self.template_name_to = self.data:GetStringOrDefault("template_name_to", "") or ""
    self.template_grid_to = self.data:GetStringOrDefault("template_grid_to", "") or ""

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.fromBlueprintName = selectorDB:GetStringOrDefault( self.template_name_from, "" ) or ""
    self.fromBlueprintGridSize = selectorDB:GetIntOrDefault( self.template_grid_from, 1 ) or 1

    self.toBlueprintName = selectorDB:GetStringOrDefault( self.template_name_to, "" ) or ""
    self.toBlueprintGridSize = selectorDB:GetIntOrDefault( self.template_grid_to, 1 ) or 1

    self.fromBlueprintsList = {}
    self.fromCacheBlueprintsLowNames = {}

    self:InitBlueprintList(self.fromBlueprintName, self.fromBlueprintsList, self.fromCacheBlueprintsLowNames)

    self.toBlueprintsList = {}
    self.toCacheBlueprintsLowNames = {}

    self:InitBlueprintList(self.toBlueprintName, self.toBlueprintsList, self.toCacheBlueprintsLowNames)

    self.buildingDescHash = {}
    self.towerBluprintsArray = {}
    self.towerBluprintsResearch = {}
    self.cacheBuildCosts = {}

    if ( self.toBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.toBlueprintName ) ) then

        local blueprintName = self:GetFirstLevelBuilding(self.toBlueprintName)

        self:FillAllBlueprints(blueprintName)
        self:FillResearches()
    end

    self:SetBuildingIcon()

    self.previousMarkedBuildings = {}
    self.radiusShowBuildings = 100.0
end

function replace_tower_replacer_from_to_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)

    if ( IndexOf( self.towerBluprintsArray, blueprintName ) == nil ) then
        Insert( self.towerBluprintsArray, blueprintName )

        self.buildingDescHash[buildingRef.bp] = buildingRef
    end

    if ( buildingRef.upgrade ~= "" and buildingRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingRef.upgrade )
    end
end

function replace_tower_replacer_from_to_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.towerBluprintsArray do

        local blueprintName = self.towerBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.towerBluprintsResearch[blueprintName] = researchName
    end
end

function replace_tower_replacer_from_to_tool:GetResearchForUpgrade( researchComponent, blueprintName )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

function replace_tower_replacer_from_to_tool:SetBuildingIcon()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.fromBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.fromBlueprintName ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.fromBlueprintName )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("tower_1_icon", menuIcon)
            markerDB:SetString("tower_1_name", buildingDescRef.localization_id)
        else

            markerDB:SetString("tower_1_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("tower_1_name", self.missing_localization_from)
        end
    else

        markerDB:SetString("tower_1_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("tower_1_name", self.missing_localization_from)
    end



    if ( self.toBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.toBlueprintName ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.toBlueprintName )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("tower_2_icon", menuIcon)
            markerDB:SetString("tower_2_name", buildingDescRef.localization_id)
        else

            markerDB:SetString("tower_2_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("tower_2_name", self.missing_localization_to)
        end
    else

        markerDB:SetString("tower_2_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("tower_2_name", self.missing_localization_to)
    end
end

function replace_tower_replacer_from_to_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
    end
end

function replace_tower_replacer_from_to_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function replace_tower_replacer_from_to_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( #self.towerBluprintsArray == 0 ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_tower_replacer_from_to_tool:IsEntityApproved( entity )

    local blueprintName = EntityService:GetBlueprintName(entity)

    if ( not self:IsBlueprintInList( self.fromBlueprintsList, self.fromCacheBlueprintsLowNames, blueprintName) ) then
        return false
    end

    if ( self:IsBlueprintInList( self.toBlueprintsList, self.toCacheBlueprintsLowNames, blueprintName) ) then
        return false
    end

    if ( not EntityService:CompareType( entity, "tower" ) ) then
        return false
    end

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local buildingRef = reflection_helper( buildingDesc )

    if ( buildingRef.type ~= "tower" ) then
        return false
    end

    local gridSize = BuildingService:GetBuildingGridSize(entity)
    if ( gridSize.x ~= self.toBlueprintGridSize ) then
        return false
    end

    local level = buildingRef.level

    local towerBlueprintName = self:GetTowerBlueprintByLevel( level )

    if ( towerBlueprintName == "" ) then
        return false
    end

    return true
end

function replace_tower_replacer_from_to_tool:OnUpdate()

    local buildinsList = self:FindBuildingFrom()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    for entity in Iter( self.previousMarkedBuildings ) do

        if ( IndexOf( buildinsList, entity ) == nil and IndexOf( self.selectedEntities, entity ) == nil ) then
            self:RemovedFromSelection( entity )
        end
    end

    for entity in Iter( buildinsList ) do

        local skinned = EntityService:IsSkinned( entity )
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
        end
    end

    self.previousMarkedBuildings = buildinsList



    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingRef = reflection_helper(buildingDesc)

        local towerBlueprintName = self:GetTowerBlueprintByLevel( buildingRef.level )

        local list1 = self:GetBuildCosts( towerBlueprintName )
        for resourceName, amount in pairs( list1 ) do

            if ( costValues[resourceName] == nil ) then

                Insert( costResourceList, resourceName )

                costValues[resourceName] = 0
            end

            costValues[resourceName] = costValues[resourceName] + amount
        end

        local list2 = BuildingService:GetSellResourceAmount( entity )
        for resourceCost in Iter(list2) do

            if ( costValues[resourceCost.first] == nil ) then

                Insert( costResourceList, resourceCost.first )

                costValues[resourceCost.first] = 0
            end

            costValues[resourceCost.first] = costValues[resourceCost.first] - resourceCost.second
        end

        ::continue::
    end


    self.buildCost = {}

    for resourceName in Iter(costResourceList) do

        local resourceValue = costValues[resourceName]

        if ( resourceValue ~= 0 ) then

            self.buildCost[resourceName] = resourceValue
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateBuildCosts( self.infoChild, self.playerId, self.buildCost )
        BuildingService:OperateBuildCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateBuildCosts( self.infoChild , self.playerId, {} )
        BuildingService:OperateBuildCosts( self.corners, self.playerId, self.buildCost )
    end
end

function replace_tower_replacer_from_to_tool:FindBuildingFrom()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildings )

    local result = {}

    for entity in Iter( buildings ) do

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
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

function replace_tower_replacer_from_to_tool:OnRotate()
end

function replace_tower_replacer_from_to_tool:OnRelease()

    if ( self.previousMarkedBuildings ~= nil) then
        for ent in Iter( self.previousMarkedBuildings ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( replace_tower_base.OnRelease ) then
        replace_tower_base.OnRelease(self)
    end
end

function replace_tower_replacer_from_to_tool:OnActivateEntity( entity )

    if ( #self.towerBluprintsArray == 0 ) then
        return
    end

    if ( not self:IsEntityApproved(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingRef = reflection_helper(buildingDesc)

    local towerBlueprintName = self:GetTowerBlueprintByLevel( buildingRef.level )
    if ( towerBlueprintName == "" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( entity )

    QueueEvent("BuildBuildingRequest", INVALID_ID, self.playerId, towerBlueprintName, transform, true )
end

function replace_tower_replacer_from_to_tool:GetTowerBlueprintByLevel( level )

    local minNumber = math.min( level, #self.towerBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.towerBluprintsArray[i]

        if ( self:IstowerBlueprintAvailable( blueprintName ) ) then

            return blueprintName
        end
    end

    return ""
end

function replace_tower_replacer_from_to_tool:IstowerBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( blueprintName ) ) then
        return true
    end

    local researchName = self.towerBluprintsResearch[blueprintName] or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function replace_tower_replacer_from_to_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_tower_replacer_from_to_tool:CalculateBuildCosts( blueprintName )

    local costValues = {}

    local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )
    for resourceCost in Iter(list) do

        if ( costValues[resourceCost.first] == nil ) then
            costValues[resourceCost.first] = 0
        end

        costValues[resourceCost.first] = costValues[resourceCost.first] + resourceCost.second
    end

    return costValues
end

return replace_tower_replacer_from_to_tool