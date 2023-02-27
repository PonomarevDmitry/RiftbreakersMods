local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'cultivator_sapling_replacer_tool' ( tool )

function cultivator_sapling_replacer_tool:__init()
    tool.__init(self,self)
end

function cultivator_sapling_replacer_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_cultivator_sapling_replacer_tool", self.entity)
    self.popupShown = false

    self.SelectedItemBlueprint = self:GetSaplingItem()
end

function cultivator_sapling_replacer_tool:GetSaplingItem()

    local DEFAULT_SAPLING_BLUEPRINT = "items/loot/saplings/biomas_sapling_item"

    local sapling_item = DEFAULT_SAPLING_BLUEPRINT

    local selectorDB = EntityService:GetDatabase( self.selector )

    if selectorDB:HasString("cultivator_sapling_picker_tool.selecteditem") then

        sapling_item = selectorDB:GetStringOrDefault( "cultivator_sapling_picker_tool.selecteditem", DEFAULT_SAPLING_BLUEPRINT )

        if not ResourceManager:ResourceExists( "EntityBlueprint", sapling_item ) then
            sapling_item = DEFAULT_SAPLING_BLUEPRINT
        end
    end

    if sapling_item == DEFAULT_SAPLING_BLUEPRINT then

        local biome_default_item = "items/loot/saplings/biomas_sapling_" .. MissionService:GetCurrentBiomeName() .. "_item"

        if ResourceManager:ResourceExists( "EntityBlueprint", biome_default_item ) then
            return biome_default_item
        end
    end

    return sapling_item
end

function cultivator_sapling_replacer_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function cultivator_sapling_replacer_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function cultivator_sapling_replacer_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function cultivator_sapling_replacer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function cultivator_sapling_replacer_tool:FilterSelectedEntities( selectedEntities ) 

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

function cultivator_sapling_replacer_tool:OnActivateEntity( entity )

    local item = ItemService:GetFirstItemForBlueprint( entity, self.SelectedItemBlueprint )

    if item == INVALID_ID then

        item = ItemService:AddItemToInventory( entity, self.SelectedItemBlueprint )
    end

    ItemService:EquipItemInSlot( entity, item, "MOD_1" )

    BuildingService:BlinkBuilding(entity)
end

return cultivator_sapling_replacer_tool
 