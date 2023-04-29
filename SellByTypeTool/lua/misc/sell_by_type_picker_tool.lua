local sell_by_type_base = require("lua/misc/sell_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_picker_tool' ( sell_by_type_base )

function sell_by_type_picker_tool:__init()
    sell_by_type_base.__init(self,self)
end

function sell_by_type_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_by_type_picker_tool", self.entity)
    self.popupShown = false
    
    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()
end

function sell_by_type_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_by_type_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_by_type_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function sell_by_type_picker_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function sell_by_type_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function sell_by_type_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for  entity in Iter( selectedEntities ) do

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

        blueprintName = buildingDescRef.bp

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( IndexOf( self.SelectedLowUpgrade, lowName ) ~= nil ) then
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

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end
        
        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if (baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescHelper = reflection_helper(buildingDesc)

        blueprintName = buildingDescHelper.bp

        local selectorDB = EntityService:GetDatabase( self.selector )

        selectorDB:SetString( self.template_name, blueprintName or "" )



        local sellerToolBlueprintDesc = reflection_helper( BuildingService:GetBuildingDesc( "buildings/tools/sell_by_type_seller" ) )

        QueueEvent( "ChangeSelectorRequest", self.selector, sellerToolBlueprintDesc.bp, sellerToolBlueprintDesc.ghost_bp )

        local sellerToolBlueprintName = sellerToolBlueprintDesc.bp

        local lowName = BuildingService:FindLowUpgrade( sellerToolBlueprintName )
                
        if ( lowName == sellerToolBlueprintName ) then
            lowName = sellerToolBlueprintDesc.name
        end

        BuildingService:SetBuildingLastLevel( lowName, sellerToolBlueprintDesc.name )

        QueueEvent( "ChangeBuildingRequest", self.selector, lowName )

        do
            return
        end

        ::continue::
    end
end

return sell_by_type_picker_tool
 