local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'replace_carbonium_tool' ( tool )

function replace_carbonium_tool:__init()
    tool.__init(self,self)
end

function replace_carbonium_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function replace_carbonium_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function replace_carbonium_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_replace_carbonium_tool", self.entity)
    self.popupShown = false

    self.buildingDescHash = {}
    self.carboniumBluprintsArray = {}
    self.carboniumBluprintsResearch = {}
    self.cacheBuildCosts = {}

    self.fromLowName = self.data:GetStringOrDefault("fromLowName", "") or ""

    local carboniumBlueprint = self.data:GetStringOrDefault("toBlueprint", "") or ""

    if ( carboniumBlueprint ~= "" ) then

        self:FillAllBlueprints( carboniumBlueprint )
        self:FillResearches()
    end

    self:SetBuildingIcon()
end

function replace_carbonium_tool:FillAllBlueprints( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingRef = reflection_helper(buildingDesc)

    if ( IndexOf( self.carboniumBluprintsArray, blueprintName ) == nil ) then
        Insert( self.carboniumBluprintsArray, blueprintName )

        self.buildingDescHash[buildingRef.bp] = buildingRef
    end

    if ( buildingRef.upgrade ~= "" and buildingRef.upgrade ~= nil ) then

        self:FillAllBlueprints( buildingRef.upgrade )
    end
end

function replace_carbonium_tool:FillResearches()

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    for i=1,#self.carboniumBluprintsArray do

        local blueprintName = self.carboniumBluprintsArray[i]

        local researchName = self:GetResearchForUpgrade( researchComponent, blueprintName )

        self.carboniumBluprintsResearch[blueprintName] = researchName
    end
end

function replace_carbonium_tool:GetResearchForUpgrade( researchComponent, blueprintName )

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

function replace_carbonium_tool:SetBuildingIcon()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    for i=#self.carboniumBluprintsArray,1,-1 do

        local blueprintName = self.carboniumBluprintsArray[i]

        if ( self:IsCarboniumBlueprintAvailable( blueprintName ) ) then

            local buildingRef = self.buildingDescHash[blueprintName]

            markerDB:SetString("carbonium_name", buildingRef.localization_id)
            markerDB:SetString("carbonium_icon", buildingRef.menu_icon)
            markerDB:SetInt("carbonium_icon_visible", 1)

            return
        end
    end

    markerDB:SetString("carbonium_name", "gui/hud/messages/replace_carbonium_tool/carboniums_not_available")
    markerDB:SetString("carbonium_icon", "")
    markerDB:SetInt("carbonium_icon_visible", 0)
end

function replace_carbonium_tool:AddedToSelection( entity )
end

function replace_carbonium_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function replace_carbonium_tool:OnUpdate()

    local costResourceList = {}
    local costValues = {}

    for entity in Iter( self.selectedEntities ) do

        if ( not self:IsEntityApproved( entity ) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingRef = reflection_helper(buildingDesc)

        local level = buildingRef.level

        local carboniumBlueprint = self:GetCarboniumBlueprintNameByLevel( level )

        if ( carboniumBlueprint == "" ) then
            goto continue
        end



        local list1 = self:GetBuildCosts( carboniumBlueprint )
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

        self:SetEntitySelectedMaterial( entity, "hologram/pass" )

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

function replace_carbonium_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function replace_carbonium_tool:GetCarboniumBlueprintNameByLevel( level )

    local minNumber = math.min( level, #self.carboniumBluprintsArray )

    for i=minNumber,1,-1 do

        local blueprintName = self.carboniumBluprintsArray[i]

        if ( self:IsCarboniumBlueprintAvailable( blueprintName ) ) then

            return blueprintName
        end
    end

    return ""
end

function replace_carbonium_tool:IsCarboniumBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self.carboniumBluprintsResearch[blueprintName] or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function replace_carbonium_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_carbonium_tool:CalculateBuildCosts( blueprintName )

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

function replace_carbonium_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( #self.carboniumBluprintsArray == 0 ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved( entity ) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function replace_carbonium_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode >= BM_SELLING ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local lowName = BuildingService:FindLowUpgrade( blueprintName )
    if ( lowName ~= self.fromLowName ) then
        return false
    end

    if ( IndexOf( self.carboniumBluprintsArray, blueprintName ) ~= nil ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local buildingRef = reflection_helper(buildingDesc)

    local level = buildingRef.level

    local carboniumBlueprint = self:GetCarboniumBlueprintNameByLevel( level )

    if ( carboniumBlueprint == "" ) then
        return false
    end

    return true
end

function replace_carbonium_tool:OnActivateEntity( entity )

    if ( #self.carboniumBluprintsArray == 0 ) then
        return
    end

    if ( not self:IsEntityApproved( entity ) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingRef = reflection_helper(buildingDesc)

    local level = buildingRef.level

    local carboniumBlueprint = self:GetCarboniumBlueprintNameByLevel( level )



    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation


    local buildAfterSellScript = EntityService:SpawnEntity( "misc/build_after_sell/script", position, team )

    local database = EntityService:GetOrCreateDatabase( buildAfterSellScript )

    database:SetInt( "target_entity", entity )
    database:SetInt( "player_id", self.playerId )
    database:SetString( "building_blueprintname", carboniumBlueprint )



    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
end

return replace_carbonium_tool