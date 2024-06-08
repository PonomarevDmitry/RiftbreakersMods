local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'sell_depleted' ( tool )

function sell_depleted:__init()
    tool.__init(self,self)
end

function sell_depleted:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_depleted:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell", self.entity)

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )

    self.scaleMap = {
        1,
    }

    self.replaceWithConnectorsValuesArray = { false, true }

    self.configName = "$sell_depleted_config"

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.replaceWithConnectors = (selectorDB:GetIntOrDefault(self.configName, 0) == 1)

    self:UpdateMarker()
end

function sell_depleted:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_depleted:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_depleted:AddedToSelection( entity )
end

function sell_depleted:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function sell_depleted:OnUpdate()

    self.sellCosts = {}

    local countEnergyConnectors = 0

    for entity in Iter( self.selectedEntities ) do

        if ( EntityService:IsSkinned( entity ) ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
        end

        local list = BuildingService:GetSellResourceAmount( entity )

        for resourceCost in Iter(list) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end

            self.sellCosts[resourceCost.first ] = self.sellCosts[resourceCost.first] + resourceCost.second
        end

        local gridSize = BuildingService:GetBuildingGridSize(entity)

        local count = 1

        if (gridSize.x > 1) then
            count = count * 2
        end
        if (gridSize.z > 1) then
            count = count * 2
        end

        countEnergyConnectors = countEnergyConnectors + count
    end

    if ( self.replaceWithConnectors and countEnergyConnectors > 0 ) then

        local list = BuildingService:GetBuildCosts( "buildings/energy/energy_connector", self.playerId )

        for resourceCost in Iter(list) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end

            self.sellCosts[resourceCost.first ] = self.sellCosts[resourceCost.first] - resourceCost.second * countEnergyConnectors
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function sell_depleted:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then 
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "ResourceConverterComponent" ) ) then
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

        local resourceRequirement = buildingDescRef.resource_requirement
        if ( resourceRequirement == nil or resourceRequirement.count <= 0 ) then
            goto continue
        end

        local isOnResource = self:CheckEntityOnResource( entity, resourceRequirement, blueprintName )
        if ( isOnResource ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function sell_depleted:CheckEntityOnResource( entity, resourceRequirement, blueprintName )

    for i = 1,resourceRequirement.count do

        local resource = resourceRequirement[i] or ""

        if ( resource ~= "" ) then

            if ( BuildingService:IsOnResource( entity, resource ) ) then
                return true
            end

            local veins = BuildingService:GetResourceVeins( entity, resource )

            if ( #veins > 0) then
                return true
            end
        end
    end

    return false
end

function sell_depleted:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    local team = EntityService:GetTeam( self.entity )

    for entity in Iter( self.selectedEntities ) do

        if ( self.replaceWithConnectors ) then

            local transform = EntityService:GetWorldTransform( entity )

            local position = transform.position
            local orientation = transform.orientation

            local buildAfterSellScript = EntityService:SpawnEntity( "buildings/tools/sell_depleted/script", position, team )

            local database = EntityService:GetDatabase( buildAfterSellScript )

            database:SetInt( "target_entity", entity )
            database:SetInt( "player_id", self.playerId )
            database:SetInt( "building_count", 4 )

            database:SetString( "building_blueprintname", "buildings/energy/energy_connector" )
        end


        QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
    end

    QueueEvent( "LeaveBuildModeRequest", self.selector, false )

    EntityService:RemoveEntity( self.entity )
end

function sell_depleted:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentReplaceWithConnectors = self:CheckReplaceWithConnectorsValueExists(self.replaceWithConnectors)

    local replaceWithConnectorsValuesArray = self.replaceWithConnectorsValuesArray

    local index = IndexOf( replaceWithConnectorsValuesArray, currentReplaceWithConnectors )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #replaceWithConnectorsValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = replaceWithConnectorsValuesArray[newIndex]

    self.replaceWithConnectors = newValue

    local savedValue = 0;
    if ( newValue ) then
        savedValue = 1;
    end
    local selectorDB = EntityService:GetDatabase( self.selector )
    selectorDB:SetInt(self.configName, savedValue)

    self:UpdateMarker()

    self:OnUpdate()
end

function sell_depleted:CheckReplaceWithConnectorsValueExists( replaceWithConnectors )

    local replaceWithConnectorsValuesArray = self.replaceWithConnectorsValuesArray

    replaceWithConnectors = replaceWithConnectors or replaceWithConnectorsValuesArray[1]

    local index = IndexOf(replaceWithConnectorsValuesArray, replaceWithConnectors )

    if ( index == nil ) then

        return replaceWithConnectorsValuesArray[1]
    end

    return replaceWithConnectors
end

function sell_depleted:UpdateMarker()

    local markerDB = self.data

    if ( self.replaceWithConnectors ) then

        markerDB:SetString("message_text", "gui/hud/sell_depleted/replace_with_connectors")
        markerDB:SetInt("message_visible", 1)
    else
        markerDB:SetString("message_text", "")
        markerDB:SetInt("message_visible", 0)
    end
end

function sell_depleted:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return sell_depleted