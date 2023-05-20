local sell_by_type_base = require("lua/misc/sell_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_seller_tool' ( sell_by_type_base )

function sell_by_type_seller_tool:__init()
    sell_by_type_base.__init(self,self)
end

function sell_by_type_seller_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_by_type_seller_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self:InitLowUpgradeList()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("building_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetString("message_text", "")
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/sell_by_type/building_not_selected")
        end
    else

        markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("message_text", "gui/hud/sell_by_type/building_not_selected")
    end



    self.placeRuins = (self.data:GetIntOrDefault("place_ruins", 0) == 1)
    self.isGroup = (self.data:GetIntOrDefault("is_group", 0) == 1)

    self.previousMarkedBuildings = {}
    self.radiusShowBuildings = 100.0
end

function sell_by_type_seller_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_by_type_seller_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function sell_by_type_seller_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_by_type_seller_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_by_type_seller_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local buildingComponentRef = reflection_helper(buildingComponent)
    if ( buildingComponentRef.m_isSellable == false ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName(entity)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    if ( self.isGroup ) then

        if ( not self:IsBlueprintInLowNameList(blueprintName) ) then
            return false
        end
    else

        if ( not self:IsBlueprintInList(blueprintName) ) then
            return false
        end
    end

    return true
end

function sell_by_type_seller_tool:OnUpdate()

    local sellableBuildinsList = self:FindBuildingSellable()

    self.previousMarkedBuildings = self.previousMarkedBuildings or {}

    for entity in Iter( self.previousMarkedBuildings ) do

        if ( IndexOf( sellableBuildinsList, entity ) == nil and IndexOf( self.selectedEntities, entity ) == nil ) then
            self:RemovedFromSelection( entity )
        end
    end

    for entity in Iter( sellableBuildinsList ) do

        local skinned = EntityService:IsSkinned( entity )
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
        end
    end

    self.previousMarkedBuildings = sellableBuildinsList


    self.sellCosts = {}

    for entity in Iter( self.selectedEntities ) do

        local list = BuildingService:GetSellResourceAmount( entity )

        for resourceCost in Iter(list) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end

           self.sellCosts[resourceCost.first] = self.sellCosts[resourceCost.first] + resourceCost.second
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1)
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild , self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function sell_by_type_seller_tool:FindBuildingSellable()

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

function sell_by_type_seller_tool:OnRotate()
end

function sell_by_type_seller_tool:OnRelease()

    if ( self.previousMarkedBuildings ~= nil) then
        for ent in Iter( self.previousMarkedBuildings ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( sell_by_type_base.OnRelease ) then
        sell_by_type_base.OnRelease(self)
    end
end

function sell_by_type_seller_tool:OnActivateEntity( entity )

    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( self.placeRuins ) then

        local ruinsBlueprintName = blueprintName .. "_ruins"

        if ( ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprintName ) ) then

            local placeRuinScript = EntityService:SpawnEntity( "misc/place_ruin_after_sell/script", position, team )

            local database = EntityService:GetDatabase( placeRuinScript )

            database:SetInt( "target_entity", entity )
            database:SetString( "ruins_blueprint", ruinsBlueprintName )
        end
    end

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
end

return sell_by_type_seller_tool