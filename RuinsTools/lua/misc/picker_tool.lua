local tool_highlight_ruins = require("lua/misc/tool_highlight_ruins.lua")
require("lua/utils/table_utils.lua")

class 'picker_tool' ( tool_highlight_ruins )

function picker_tool:__init()
    tool_highlight_ruins.__init(self,self)
end

function picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_picker", self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }
end

function picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function picker_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function picker_tool:OnUpdate()

    self:HighlightRuins()
end

function picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins )

    return selectedItems
end

function picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for ent in Iter(selectedEntities ) do

        local blueprint = EntityService:GetBlueprintName(ent)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprint )

        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescHelper = reflection_helper(buildingDesc)

        if ( BuildingService:IsBuildingAvailable(self.playerId , blueprint ) == false ) then
            goto continue
        end

        local list = BuildingService:GetBuildCosts( blueprint, self.playerId )

        if ( #list == 0 ) then
            goto continue
        end

        Insert(entities, ent)

        ::continue::
    end

    return entities
end

function picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local blueprint = ""

        if( EntityService:GetGroup( entity ) == "##ruins##" ) then
            local database = EntityService:GetDatabase( entity )
            if ( database ) then
                blueprint = database:GetString("blueprint")
            else
                goto continue
            end
        else
            blueprint = EntityService:GetBlueprintName(entity)
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprint )
        if ( buildingDesc == nil ) then goto continue end

        local baseDesc= BuildingService:FindBaseBuilding(blueprint )
        if  (baseDesc ~= nil ) then
            buildingDesc = baseDesc
        end

        local list = BuildingService:GetBuildCosts( blueprint, self.playerId )

        if ( #list == 0 ) then
            goto continue
        end

        local buildingDescHelper = reflection_helper(buildingDesc)

        local transform = EntityService:GetWorldTransform( entity )
        EntityService:SetEntityWorldTransform( entity, transform)

        blueprint = buildingDescHelper.bp

        QueueEvent("ChangeSelectorRequest", self.selector, buildingDescHelper.bp ,buildingDescHelper.ghost_bp)

        local lowName = BuildingService:FindLowUpgrade( blueprint )

        if ( lowName == blueprint ) then
            lowName = buildingDescHelper.name
        end

        BuildingService:SetBuildingLastLevel( lowName, buildingDescHelper.name)

        QueueEvent("ChangeBuildingRequest", self.selector, lowName )

        ::continue::
    end
end

return picker_tool