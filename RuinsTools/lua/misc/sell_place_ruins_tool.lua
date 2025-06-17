local tool_highlight_ruins = require("lua/misc/tool_highlight_ruins.lua")
require("lua/utils/reflection.lua")

class 'sell_place_ruins_tool' ( tool_highlight_ruins )

function sell_place_ruins_tool:__init()
    tool_highlight_ruins.__init(self,self)
end

function sell_place_ruins_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_place_ruins_tool", self.entity)
end

function sell_place_ruins_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_place_ruins_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_place_ruins_tool:AddedToSelection( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
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

function sell_place_ruins_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function sell_place_ruins_tool:FilterSelectedEntities( selectedEntities )

    local result = {}

    for entity in Iter( selectedEntities ) do

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local ruinsBlueprint = blueprintName .. "_ruins"

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function sell_place_ruins_tool:OnUpdate()

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

function sell_place_ruins_tool:OnRotate()
end

function sell_place_ruins_tool:OnActivateEntity( entity )

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

                local database = EntityService:GetOrCreateDatabase( placeRuinScript )

                database:SetInt( "player_id", self.playerId )
                database:SetInt( "target_entity", entity )
                database:SetString( "ruins_blueprint", ruinsBlueprintName )
            end
        end
    end

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
end

return sell_place_ruins_tool