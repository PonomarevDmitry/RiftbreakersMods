local replace_lamp_base = require("lua/misc/replace_lamp_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_lamp_replacer_all_tool' ( replace_lamp_base )

function replace_lamp_replacer_all_tool:__init()
    replace_lamp_base.__init(self,self)
end

function replace_lamp_replacer_all_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function replace_lamp_replacer_all_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.missing_localization = self.data:GetStringOrDefault("missing_localization", "") or ""

    self.buildingDescHash = {}
    self.lampBluprintsArray = {}
    self.lampBluprintsResearch = {}
    self.cacheBuildCosts = {}
    
    self.template_name = self.data:GetStringOrDefault("template_name", "") or ""
    self.low_name = self.data:GetStringOrDefault("low_name", "") or ""

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

    self.selectedBlueprints = {}

    self.cacheBlueprintsLowNames = {}

    self:InitBlueprintList(self.selectedBuildingBlueprint, self.selectedBlueprints, self.cacheBlueprintsLowNames)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local blueprintName = self:GetFirstLevelBuilding(self.selectedBuildingBlueprint)

        self:FillAllBlueprints(blueprintName)
        self:FillResearches()
    end

    self:SetBuildingIcon()
end

function replace_lamp_replacer_all_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)

    if ( IndexOf( self.lampBluprintsArray, blueprintName ) == nil ) then
        Insert( self.lampBluprintsArray, blueprintName )

        self.buildingDescHash[buildingRef.bp] = buildingRef
    end

    if ( buildingRef.upgrade ~= "" and buildingRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingRef.upgrade )
    end
end

function replace_lamp_replacer_all_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.lampBluprintsArray do

        local blueprintName = self.lampBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.lampBluprintsResearch[blueprintName] = researchName
    end
end

function replace_lamp_replacer_all_tool:GetResearchForUpgrade( researchComponent, blueprintName )

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

function replace_lamp_replacer_all_tool:SetBuildingIcon()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    markerDB:SetInt("lamp_icon_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("lamp_name", "")

            markerDB:SetString("lamp_icon", menuIcon)
        else

            markerDB:SetString("lamp_name", self.missing_localization)

            markerDB:SetString("lamp_icon", "gui/menu/research/icons/missing_icon_big")
        end
    else
        markerDB:SetString("lamp_name", self.missing_localization)

        markerDB:SetString("lamp_icon", "gui/menu/research/icons/missing_icon_big")
    end
end

function replace_lamp_replacer_all_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
    end
end

function replace_lamp_replacer_all_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function replace_lamp_replacer_all_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( #self.lampBluprintsArray == 0 ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_lamp_replacer_all_tool:IsEntityApproved( entity )

    local blueprintName = EntityService:GetBlueprintName(entity)

    if ( self:IsBlueprintInList( self.selectedBlueprints, self.cacheBlueprintsLowNames, blueprintName) ) then
        return false
    end

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode >= BM_SELLING ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )
    if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
        return false
    end

    if ( self.low_name and self.low_name ~= "" ) then

        if ( self.low_name ~= lowName ) then

            return false
        end
    end

    local buildingRef = reflection_helper( buildingDesc )

    local level = buildingRef.level

    local lampBlueprintName = self:GetLampBlueprintName( level )

    if ( lampBlueprintName == "" ) then
        return false
    end

    return true
end

function replace_lamp_replacer_all_tool:OnUpdate()

    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingRef = reflection_helper(buildingDesc)

        local lampBlueprintName = self:GetLampBlueprintName( buildingRef.level )

        local list1 = self:GetBuildCosts( lampBlueprintName )
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

function replace_lamp_replacer_all_tool:OnActivateEntity( entity )

    if ( #self.lampBluprintsArray == 0 ) then
        return
    end

    if ( not self:IsEntityApproved(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingRef = reflection_helper(buildingDesc)

    local lampBlueprintName = self:GetLampBlueprintName( buildingRef.level )
    if ( lampBlueprintName == "" ) then
        return
    end




    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation


    local buildAfterSellScript = EntityService:SpawnEntity( "buildings/tools/replace_lamp_replacer_tool/script", position, team )

    local database = EntityService:GetOrCreateDatabase( buildAfterSellScript )

    database:SetInt( "target_entity", entity )
    database:SetInt( "player_id", self.playerId )
    database:SetString( "building_blueprintname", lampBlueprintName )



    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
end

function replace_lamp_replacer_all_tool:GetLampBlueprintName( level )

    local minNumber = math.min( level, #self.lampBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.lampBluprintsArray[i]

        if ( self:IsLampBlueprintAvailable( blueprintName ) ) then

            return blueprintName
        end
    end

    return ""
end

function replace_lamp_replacer_all_tool:IsLampBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self.lampBluprintsResearch[blueprintName] or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function replace_lamp_replacer_all_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_lamp_replacer_all_tool:CalculateBuildCosts( blueprintName )

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

return replace_lamp_replacer_all_tool