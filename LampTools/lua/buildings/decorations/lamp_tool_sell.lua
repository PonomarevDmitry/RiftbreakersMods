local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")

class 'lamp_tool_sell' ( tool )

function lamp_tool_sell:__init()
    tool.__init(self,self)
end

function lamp_tool_sell:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.placeRuins = (self.data:GetIntOrDefault("place_ruins", 0) == 1)

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function lamp_tool_sell:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function lamp_tool_sell:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function lamp_tool_sell:AddedToSelection( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent")
    if ( buildingComponent == nil ) then
        return
    end

    local buildingComponentHelper = reflection_helper(buildingComponent)

    local isSkinned = EntityService:IsSkinned( entity )

    if ( buildingComponentHelper.m_isSellable == true ) then

        if ( isSkinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
        end
    else

        if ( isSkinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_red_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_red", "selected" )
        end
    end
end

function lamp_tool_sell:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local ruins = {}

    if ( self.placeRuins == false ) then

        local findedRuins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

        for ruinEntity in Iter( findedRuins ) do

            if ( IndexOf( ruins, ruinEntity ) ~= nil ) then
                goto continue
            end

            local database = EntityService:GetDatabase( ruinEntity )
            if ( database == nil ) then
                goto continue
            end

            if ( not database:HasString("blueprint") ) then
                goto continue
            end

            local ruinsBlueprint = database:GetString("blueprint")
            if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
                goto continue
            end

            local lowName = BuildingService:FindLowUpgrade( ruinsBlueprint )
            if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
                goto continue
            end

            Insert( ruins, ruinEntity )

            ::continue::
        end

        for entity in Iter( ruins ) do

            if ( IndexOf( self.selectedEntities, entity ) == nil ) then

                if ( EntityService:IsSkinned(entity ) ) then
                    EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
                else
                    EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
                end

                if ( self.activated ) then
                    self:OnActivateEntity( entity )
                end
            end
        end

        ConcatUnique( selectedItems, ruins )
    end

    for entity in Iter( self.selectedEntities ) do
        if ( IndexOf( ruins, entity ) == nil and IndexOf( selectedItems, entity ) == nil ) then
            EntityService:RemoveMaterial( entity, "selected" )
        end
    end

    return selectedItems
end

function lamp_tool_sell:FilterSelectedEntities( selectedEntities ) 

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function lamp_tool_sell:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function lamp_tool_sell:OnUpdate()

    self:HighlightRuins()


    self.sellCosts = {}

    for entity in Iter( self.selectedEntities ) do

        local list = BuildingService:GetSellResourceAmount( entity )

        for resourceCost in Iter( list ) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
               self.sellCosts[resourceCost.first] = 0
            end

            self.sellCosts[resourceCost.first] = self.sellCosts[resourceCost.first] + resourceCost.second
        end
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild , self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function lamp_tool_sell:OnRotate()

end

function lamp_tool_sell:OnActivateEntity( entity )
    if ( EntityService:GetGroup( entity ) == "##ruins##" ) then
        EntityService:SetGroup( entity, "" )
        BuildingService:BlinkBuilding(entity)
        QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
    else

        if ( self.placeRuins ) then

            local blueprintName = EntityService:GetBlueprintName( entity )

            local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
            if ( buildingDesc ~= nil ) then

                local buildingDescRef = reflection_helper( buildingDesc )
                if ( buildingDescRef ~= nil and buildingDescRef.build_cost ~= nil and buildingDescRef.build_cost.resource ~= nil and buildingDescRef.build_cost.resource.count ~= nil and buildingDescRef.build_cost.resource.count > 0 ) then

                    local ruinsBlueprintName = blueprintName .. "_ruins"

                    if ( ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprintName ) ) then

                        local team = EntityService:GetTeam( entity )

                        local transform = EntityService:GetWorldTransform( entity )

                        local position = transform.position
                        local orientation = transform.orientation


                        local placeRuinScript = EntityService:SpawnEntity( "misc/place_ruin_after_sell/script", position, team )

                        local database = EntityService:GetDatabase( placeRuinScript )

                        database:SetInt( "player_id", self.playerId )
                        database:SetInt( "target_entity", entity )
                        database:SetString( "ruins_blueprint", ruinsBlueprintName )
                    end
                end
            end
        end

        QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
    end
end

function lamp_tool_sell:HighlightRuins()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    -- Remove highlighting from previous ruins
    for ruinEntity in Iter( self.previousMarkedRuins ) do

        -- If the ruin is not included in the new list
        if ( IndexOf( ruinsList, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        EntityService:RemoveMaterial( ruinEntity, "selected" )

        ::continue::
    end

    for ruinEntity in Iter( ruinsList ) do

        local skinned = EntityService:IsSkinned( ruinEntity )
        if ( skinned ) then
            EntityService:SetMaterial( ruinEntity, "selector/hologram_grey_skinned", "selected")
        else
            EntityService:SetMaterial( ruinEntity, "selector/hologram_grey", "selected")
        end
    end

    self.previousMarkedRuins = ruinsList
end

function lamp_tool_sell:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local ruinsList = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for ruinEntity in Iter( ruinsList ) do

        if ( IndexOf( result, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetDatabase( ruinEntity )
        if ( database == nil ) then
            goto continue
        end

        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local ruinsBlueprint = database:GetString("blueprint")
        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( ruinsBlueprint )
        if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
            goto continue
        end

        Insert( result, ruinEntity )

        ::continue::
    end

    return result
end

function lamp_tool_sell:OnRelease()

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do
            EntityService:RemoveMaterial( ruinEntity, "selected" )
        end
    end
    self.previousMarkedRuins = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return lamp_tool_sell