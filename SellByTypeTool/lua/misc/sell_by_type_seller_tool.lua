local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_seller_tool' ( tool )

function sell_by_type_seller_tool:__init()
    tool.__init(self,self)
end

function sell_by_type_seller_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_by_type_seller_tool", self.entity)

    local selectorDB = EntityService:GetDatabase( self.selector )

    local selectedBuildingBlueprint = selectorDB:GetStringOrDefault( "sell_by_type_picker_tool.selectedbuilding", "" ) or ""

    local markerDB = EntityService:GetDatabase( self.childEntity )

    self.SelectedLowUpgrade = {}

    if ( selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", selectedBuildingBlueprint ) ) then

        self:FillLowUpgradeList(self.SelectedLowUpgrade, selectedBuildingBlueprint)

        local menuIcon = self:GetMenuIcon( selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetInt("building_visible", 1)
        else

            markerDB:SetInt("building_visible", 0)
        end
    else
        markerDB:SetInt("building_visible", 0)
    end
end

function sell_by_type_seller_tool:FillLowUpgradeList( list, blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc ~= nil ) then
        local buildingDescRef = reflection_helper( buildingDesc )

        self:AddToLowUpgradeList( list, buildingDescRef )
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if (baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper(baseBuildingDesc)

        if ( baseBuildingDescRef.bp ~= blueprintName ) then

            self:AddToLowUpgradeList( list, baseBuildingDescRef )
        end
    end
end

function sell_by_type_seller_tool:AddToLowUpgradeList( list, buildingDescRef )

    local lowName = BuildingService:FindLowUpgrade( buildingDescRef.bp )

    if ( IndexOf( list, lowName ) == nil ) then
        Insert( list, lowName )
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            lowName = BuildingService:FindLowUpgrade( connectBlueprintName )

            if ( IndexOf( list, lowName ) == nil ) then
                Insert( list, lowName )
            end
        end
    end    
end

function sell_by_type_seller_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_by_type_seller_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_by_type_seller_tool:GetMenuIcon( blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = buildingDescRef.menu_icon or ""
    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            local connectMenuIcon = self:GetBuildingMenuIcon( connectBlueprintName )

            if ( connectMenuIcon ~= "" ) then

                return connectMenuIcon
            end
        end
    end

    return ""
end

function sell_by_type_seller_tool:GetBuildingMenuIcon( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = buildingDescRef.menu_icon or ""
    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end

    return ""
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

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingComponentRef = reflection_helper(buildingComponent)
        if ( buildingComponentRef.m_isSellable == false ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if (baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescRef = reflection_helper(buildingDesc)

        local blueprintNameBP = buildingDescRef.bp

        local lowName = BuildingService:FindLowUpgrade( blueprintNameBP )

        if ( IndexOf( self.SelectedLowUpgrade, lowName ) == nil ) then
            goto continue
        end


        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_by_type_seller_tool:OnUpdate()

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

function sell_by_type_seller_tool:OnRotate()

end

function sell_by_type_seller_tool:OnActivateEntity( entity )

    QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
end

return sell_by_type_seller_tool