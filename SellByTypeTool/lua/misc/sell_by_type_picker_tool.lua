
local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'sell_by_type_picker_tool' ( tool )

function sell_by_type_picker_tool:__init()
    tool.__init(self,self)
end

function sell_by_type_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_by_type_picker_tool", self.entity)
    self.popupShown = false
    
    self.scaleMap = {
        1,
    }

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.SelectedBuildingBlueprint = selectorDB:GetStringOrDefault( "sell_by_type_picker_tool.selectedbuilding", "" ) or ""

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.SelectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedBuildingBlueprint ) ) then

        self.SelectedLowUpgrade = BuildingService:FindLowUpgrade( self.SelectedBuildingBlueprint )

        LogService:Log("self.SelectedBuildingBlueprint " .. self.SelectedBuildingBlueprint .. " self.SelectedLowUpgrade " .. self.SelectedLowUpgrade)

        local menuIcon = self:GetMenuIcon( self.SelectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetInt("building_visible", 1)
        else

            markerDB:SetInt("building_visible", 0)
        end
    else
        self.SelectedBuildingBlueprint = ""
        self.SelectedLowUpgrade = ""
        markerDB:SetInt("building_visible", 0)
    end
end

function sell_by_type_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_by_type_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_by_type_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_by_type_picker_tool:GetMenuIcon( blueprintName )

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( blueprintBuildingDesc == nil ) then
        return ""
    end

    local buildingDesc = reflection_helper( blueprintBuildingDesc )
    if ( buildingDesc == nil ) then
        return ""
    end

    local menuIcon = buildingDesc.menu_icon or ""

    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    for i=1,buildingDesc.connect.count do

        local connectRecord = buildingDesc.connect[i]

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

function sell_by_type_picker_tool:GetBuildingMenuIcon( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( blueprintBuildingDesc == nil ) then
        return ""
    end

    local buildingDesc = reflection_helper( blueprintBuildingDesc )
    if ( buildingDesc == nil ) then
        return ""
    end

    local menuIcon = buildingDesc.menu_icon or ""

    return menuIcon
end

function sell_by_type_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function sell_by_type_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_by_type_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for  entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingComponentHelper = reflection_helper(buildingComponent)
        if ( buildingComponentHelper.m_isSellable == false ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( self.SelectedLowUpgrade == lowName ) then
            goto continue
        end


        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function sell_by_type_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local selectorDB = EntityService:GetDatabase( self.selector )

        selectorDB:SetString( "sell_by_type_picker_tool.selectedbuilding", blueprintName or "" )



        local sellerToolBlueprintDesc = reflection_helper( BuildingService:GetBuildingDesc( "buildings/tools/sell_by_type_seller" ) )

        QueueEvent( "ChangeSelectorRequest", self.selector, sellerToolBlueprintDesc.bp, sellerToolBlueprintDesc.ghost_bp )

        local sellerToolBlueprintName = sellerToolBlueprintDesc.bp

        local lowName = BuildingService:FindLowUpgrade( sellerToolBlueprintName )
                
        if ( lowName == sellerToolBlueprintName ) then
            lowName = sellerToolBlueprintDesc.name
        end

        BuildingService:SetBuildingLastLevel( lowName, sellerToolBlueprintDesc.name )

        QueueEvent( "ChangeBuildingRequest", self.selector, lowName )

        return
    end
end


return sell_by_type_picker_tool
 