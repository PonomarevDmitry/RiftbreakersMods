
local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'cultivator_sapling_picker_tool' ( tool )

function cultivator_sapling_picker_tool:__init()
    tool.__init(self,self)
end

function cultivator_sapling_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_cultivator_sapling_picker", self.entity)
    self.popupShown = false
    
    self.scaleMap = {
        1,
    }
end

function cultivator_sapling_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function cultivator_sapling_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function cultivator_sapling_picker_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function cultivator_sapling_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function cultivator_sapling_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function cultivator_sapling_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for  ent in Iter(selectedEntities ) do

        local blueprint = EntityService:GetBlueprintName(ent)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprint )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprint )

        if ( lowName ~= "flora_cultivator" ) then
            goto continue
        end

        Insert(entities, ent)

        ::continue::
    end

    return entities
end

function cultivator_sapling_picker_tool:OnActivateSelectorRequest()

    for entity in Iter( self.selectedEntities ) do

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil ) then

            local blueprint = EntityService:GetBlueprintName(modItem)

            local selectorDB = EntityService:GetDatabase( self.selector )

            selectorDB:SetString( "cultivator_sapling_picker_tool.selecteditem", blueprint or "" )

            QueueEvent( "ChangeSelectorRequest", self.selector, "buildings/tools/cultivator_sapling_saver", "buildings/tools/cultivator_sapling_saver_ghost" )

            QueueEvent( "ChangeBuildingRequest", self.selector, "buildings/tools/cultivator_sapling_saver" )

            return
        end
    end
end


return cultivator_sapling_picker_tool
 