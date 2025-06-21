local replace_lamp_base = require("lua/misc/replace_lamp_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'replace_lamp_tool' ( replace_lamp_base )

function replace_lamp_tool:__init()
    replace_lamp_base.__init(self,self)
end

function replace_lamp_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.icon_from = self.data:GetStringOrDefault("icon_from", "") or ""
    self.icon_to = self.data:GetStringOrDefault("icon_to", "") or ""

    self.replace_from = self.data:GetStringOrDefault("replace_from", "") or ""
    self.replace_to = self.data:GetStringOrDefault("replace_to", "") or ""

    self.low_name = self.data:GetStringOrDefault("low_name", "") or ""

    self.cacheBuildCosts = {}

    self:SetBuildingIcon()

    self.previousMarkedBuildings = {}
    self.radiusShowBuildings = 100.0
end

function replace_lamp_tool:SetBuildingIcon()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    if ( self.icon_from ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.icon_from ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.icon_from )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("lamp_1_icon", menuIcon)
            markerDB:SetString("lamp_1_name", "")
        else

            markerDB:SetString("lamp_1_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("lamp_1_name", "")
        end
    else

        markerDB:SetString("lamp_1_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("lamp_1_name", "")
    end



    if ( self.icon_to ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.icon_to ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.icon_to )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("lamp_2_icon", menuIcon)
            markerDB:SetString("lamp_2_name", "")
        else

            markerDB:SetString("lamp_2_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("lamp_2_name", "")
        end
    else

        markerDB:SetString("lamp_2_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("lamp_2_name", "")
    end
end

function replace_lamp_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/pass" )
end

function replace_lamp_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function replace_lamp_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

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

function replace_lamp_tool:IsEntityApproved( entity )

    local blueprintName = EntityService:GetBlueprintName(entity)

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

    local lampBlueprintName = self:GetLampBlueprintName( blueprintName )

    if ( lampBlueprintName == "" ) then
        return false
    end

    return true
end

function replace_lamp_tool:OnUpdate()

    local buildinsList = self:FindBuildingFrom()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    for entity in Iter( self.previousMarkedBuildings ) do

        if ( IndexOf( buildinsList, entity ) == nil and IndexOf( self.selectedEntities, entity ) == nil ) then
            self:RemovedFromSelection( entity )
        end
    end

    for entity in Iter( buildinsList ) do

        self:SetEntitySelectedMaterial( entity, "hologram/active" )
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

        local lampBlueprintName = self:GetLampBlueprintName( blueprintName )

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

function replace_lamp_tool:FindBuildingFrom()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local buildings = FindService:FindEntitiesByTypeInRadius( player, "building", self.radiusShowBuildings )

    local result = {}

    for entity in Iter( buildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

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

function replace_lamp_tool:OnRotate()
end

function replace_lamp_tool:OnRelease()

    if ( self.previousMarkedBuildings ~= nil) then
        for ent in Iter( self.previousMarkedBuildings ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( replace_lamp_base.OnRelease ) then
        replace_lamp_base.OnRelease(self)
    end
end

function replace_lamp_tool:OnActivateEntity( entity )

    if ( not self:IsEntityApproved(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingRef = reflection_helper(buildingDesc)

    local lampBlueprintName = self:GetLampBlueprintName( blueprintName )
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

function replace_lamp_tool:GetLampBlueprintName( blueprintName )

    local result = string.gsub( blueprintName, self.replace_from, self.replace_to )

    if ( ResourceManager:ResourceExists( "EntityBlueprint", result ) and self:IsLampBlueprintAvailable( result ) ) then

        return result
    end

    return ""
end

function replace_lamp_tool:IsLampBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    return false
end

function replace_lamp_tool:GetBuildCosts( blueprintName )

    self.cacheBuildCosts = self.cacheBuildCosts or {}

    if ( self.cacheBuildCosts[blueprintName] ~= nil ) then

        return self.cacheBuildCosts[blueprintName]
    end

    local result = self:CalculateBuildCosts( blueprintName )

    self.cacheBuildCosts[blueprintName] = result

    return result
end

function replace_lamp_tool:CalculateBuildCosts( blueprintName )

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

return replace_lamp_tool