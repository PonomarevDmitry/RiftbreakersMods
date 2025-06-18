local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_energy_tool' ( tool )

function sell_energy_tool:__init()
    tool.__init(self,self)
end

function sell_energy_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_energy_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.minModificator = 0.05

    self.previousMarkedBuildings = {}
    self.radiusShowBuildings = 100.0
end

function sell_energy_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_energy_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function sell_energy_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function sell_energy_tool:FilterSelectedEntities( selectedEntities )

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

function sell_energy_tool:IsEntityApproved( entity )

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

    local lowName = BuildingService:FindLowUpgrade( blueprintName )

    if ( lowName == "solar_panels" ) then

        local solarModificator = BuildingService:GetSolarPowerModificator( entity )

        if ( solarModificator < self.minModificator ) then

            return true
        end
    end

    if ( lowName == "wind_turbine" ) then

        local windModificator = BuildingService:GetWindPowerModificator( entity )

        if ( windModificator < self.minModificator ) then

            return true
        end
    end

    return false
end

function sell_energy_tool:OnUpdate()

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

function sell_energy_tool:FindBuildingSellable()

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

function sell_energy_tool:OnRotate()
end

function sell_energy_tool:OnRelease()

    if ( self.previousMarkedBuildings ~= nil) then
        for ent in Iter( self.previousMarkedBuildings ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedBuildings = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function sell_energy_tool:OnActivateEntity( entity )

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
end

return sell_energy_tool