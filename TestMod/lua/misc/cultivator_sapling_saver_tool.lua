local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'cultivator_sapling_saver_tool' ( tool )

function cultivator_sapling_saver_tool:__init()
    tool.__init(self,self)
end

function cultivator_sapling_saver_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_cultivator_sapling_saver_tool", self.entity)
    self.popupShown = false

    local DEFAULT_SAPLING_BLUEPRINT = "items/loot/saplings/biomas_sapling_item"

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.SelectedItemBlueprint = selectorDB:GetStringOrDefault( "cultivator_sapling_picker_tool.selecteditem", DEFAULT_SAPLING_BLUEPRINT )
end

function cultivator_sapling_saver_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function cultivator_sapling_saver_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function cultivator_sapling_saver_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function cultivator_sapling_saver_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function cultivator_sapling_saver_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}
    
    for ent in Iter(selectedEntities ) do

        local blueprint = EntityService:GetBlueprintName(ent)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprint )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprint )

        if ( lowName ~= "flora_cultivator" ) then
            goto continue
        end

        local modItem = ItemService:GetEquippedItem( ent, "MOD_1" )

        if ( modItem ~= nil ) then

            local blueprintMod = EntityService:GetBlueprintName(modItem)

            if ( blueprintMod == self.SelectedItemBlueprint ) then

                goto continue
            end
        end

        Insert(entities, ent)

        ::continue::
    end

    return entities
end

function cultivator_sapling_saver_tool:OnActivateEntity( entity )

    local item = ItemService:GetFirstItemForBlueprint( entity, self.SelectedItemBlueprint )

    if item == INVALID_ID then

        item = ItemService:AddItemToInventory( entity, self.SelectedItemBlueprint )
    end

    ItemService:EquipItemInSlot( entity, item, "MOD_1" )

    BuildingService:BlinkBuilding(entity)
end

return cultivator_sapling_saver_tool
 