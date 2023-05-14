local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")

class 'sell_place_ruin_tool' ( tool )

function sell_place_ruin_tool:__init()
    tool.__init(self,self)
end

function sell_place_ruin_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_place_ruin_tool", self.entity)
end

function sell_place_ruin_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_place_ruin_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_place_ruin_tool:AddedToSelection( entity )

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

function sell_place_ruin_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_place_ruin_tool:FilterSelectedEntities( selectedEntities )

    local result = {}

    for entity in Iter( selectedEntities ) do

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

function sell_place_ruin_tool:OnUpdate()

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
        BuildingService:OperateSellCosts( self.infoChild , self.playerId,{} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function sell_place_ruin_tool:OnRotate()
end

function sell_place_ruin_tool:OnActivateEntity( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    local ruinsBlueprint = blueprintName .. "_ruins"

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
        return
    end

    LogService:Log("ruinsBlueprint " .. ruinsBlueprint )

    LogService:Log("blueprintName " .. blueprintName .. " SelectableComponent " .. tostring(reflection_helper( EntityService:GetComponent( entity, "SelectableComponent") )) )

    LogService:Log("blueprintName " .. blueprintName .. " MeshComponent " .. tostring(reflection_helper( EntityService:GetComponent( entity, "MeshComponent") )) )


    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )

    local newRuinsEntity = EntityService:SpawnEntity( ruinsBlueprint, position, team )

    EntityService:SetOrientation( newRuinsEntity, orientation )
    EntityService:RemoveComponent( newRuinsEntity, "LuaComponent" )

    LogService:Log("ruinsBlueprint " .. ruinsBlueprint .. " SelectableComponent " .. tostring(reflection_helper( EntityService:GetComponent( newRuinsEntity, "SelectableComponent") )) )

    LogService:Log("ruinsBlueprint " .. ruinsBlueprint .. " MeshComponent " .. tostring(reflection_helper( EntityService:GetComponent( newRuinsEntity, "MeshComponent") )) )
end

return sell_place_ruin_tool