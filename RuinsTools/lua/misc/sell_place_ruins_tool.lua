local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")

class 'sell_place_ruins_tool' ( tool )

function sell_place_ruins_tool:__init()
    tool.__init(self,self)
end

function sell_place_ruins_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_place_ruins_tool", self.entity)

    self.previousMarkedRuins = {}
    self.radiusShowRuins = 100.0
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
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_place_ruins_tool:FilterSelectedEntities( selectedEntities )

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

function sell_place_ruins_tool:OnUpdate()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    for ruinEntity in Iter( self.previousMarkedRuins ) do

        if ( IndexOf( ruinsList, ruinEntity ) == nil and IndexOf( self.selectedEntities, ruinEntity ) == nil ) then
            self:RemovedFromSelection( ruinEntity )
        end
    end

    for ruinEntity in Iter( ruinsList ) do

        local skinned = EntityService:IsSkinned( ruinEntity )
        if ( skinned ) then
            EntityService:SetMaterial( ruinEntity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( ruinEntity, "selector/hologram_current", "selected")
        end
    end

    self.previousMarkedRuins = ruinsList



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

function sell_place_ruins_tool:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local buildings = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for entity in Iter( buildings ) do

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function sell_place_ruins_tool:OnRotate()
end

function sell_place_ruins_tool:OnActivateEntity( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    local ruinsBlueprint = blueprintName .. "_ruins"

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
        return
    end

    local team = EntityService:GetTeam( entity )

    local transform = EntityService:GetWorldTransform( entity )

    local position = transform.position
    local orientation = transform.orientation

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )

    local newRuinsEntity = EntityService:SpawnEntity( ruinsBlueprint, position, team )

    EntityService:SetOrientation( newRuinsEntity, orientation )
    EntityService:RemoveComponent( newRuinsEntity, "LuaComponent" )
end

function sell_place_ruins_tool:OnRelease()

    if ( self.previousMarkedRuins ~= nil) then
        for ent in Iter( self.previousMarkedRuins ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedRuins = {}

    if ( tool.OnRelease ) then

        tool.OnRelease(self)
    end
end

return sell_place_ruins_tool