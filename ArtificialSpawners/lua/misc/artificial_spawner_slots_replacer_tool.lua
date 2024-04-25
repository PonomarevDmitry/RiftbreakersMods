local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'artificial_spawner_slots_replacer_tool' ( tool )

function artificial_spawner_slots_replacer_tool:__init()
    tool.__init(self,self)
end

function artificial_spawner_slots_replacer_tool:OnInit()
    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)
    self.popupShown = false

    self.configName = self.data:GetString("config_name")
    self.configNameList = self.data:GetString("config_list_name")

    self.missing_localization = self.data:GetString("missing_localization")
    self.buildingLowUpgrade = self.data:GetStringOrDefault("buildingLowUpgrade", "") or ""

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.SelectedSlotsBlueprints = nil

    local currentValue = selectorDB:GetStringOrDefault( self.configName, "" ) or ""

    if ( currentValue ~= nil and currentValue ~= "" and currentValue ~= ",," ) then

        self.SelectedSlotsBlueprints = self:GetSlotsArrayFromString(currentValue)
    end

    self:UpdateMarker()
end

function artificial_spawner_slots_replacer_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function artificial_spawner_slots_replacer_tool:GetSlotsArrayFromString(currentValue)

    local currentValueArray = Split( currentValue, "," )

    local result = {}

    for i=1,3 do
        result[i] = currentValueArray[i] or ""
    end

    return result
end

function artificial_spawner_slots_replacer_tool:UpdateMarker()

    local markerDB = EntityService:GetDatabase( self.childEntity )
    if ( markerDB == nil ) then
        return
    end

    markerDB:SetInt("slot_visible_1", 0)
    markerDB:SetInt("slot_visible_2", 0)
    markerDB:SetInt("slot_visible_3", 0)

    markerDB:SetString("slot_icon_1", "")
    markerDB:SetString("slot_icon_2", "")
    markerDB:SetString("slot_icon_3", "")

    markerDB:SetString("slot_name_1", "")
    markerDB:SetString("slot_name_2", "")
    markerDB:SetString("slot_name_3", "")

    markerDB:SetString("message_text", "")
    markerDB:SetInt("menu_visible", 1)

    if ( self.SelectedSlotsBlueprints ~= nil) then

        self:SetSlotsIcons(self.SelectedSlotsBlueprints, markerDB)

        markerDB:SetString("message_text", "")
    else
        markerDB:SetString("message_text", "${" .. self.missing_localization .. "}")

        markerDB:SetString("slot_icon_1", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetInt("slot_visible_1", 1)
    end
end

function artificial_spawner_slots_replacer_tool:SetSlotsIcons(slotsArray, markerDB)

    for i=1,3 do

        local blueprintName = slotsArray[i]

        if ( blueprintName ~= "" and blueprintName ~= nil ) then

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint ~= nil ) then

                local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
                if ( inventoryItemComponent ~= nil ) then

                    local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                    markerDB:SetInt("slot_visible_" .. tostring(i), 1)
                    markerDB:SetString("slot_icon_" .. tostring(i), inventoryItemComponentRef.icon)
                    markerDB:SetString("slot_name_" .. tostring(i), inventoryItemComponentRef.name)
                end
            end
        end
    end
end

function artificial_spawner_slots_replacer_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function artificial_spawner_slots_replacer_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
    end
end

function artificial_spawner_slots_replacer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function artificial_spawner_slots_replacer_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= self.buildingLowUpgrade ) then
            goto continue
        end

        local equipmentComponent = EntityService:GetComponent(entity, "EquipmentComponent")
        if ( equipmentComponent == nil ) then
            goto continue
        end

        local slotsValues = self:GetSlotsValues(equipmentComponent, entity)
        if ( slotsValues == nil ) then
            goto continue
        end

        if ( self.SelectedSlotsBlueprints ~= nil) then
            if ( self:IsEqualSlots(self.SelectedSlotsBlueprints, slotsValues) ) then
                goto continue
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function artificial_spawner_slots_replacer_tool:GetSlotsValues(equipmentComponent, entity)

    local result = {}

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local slots = equipment.slots

    for i=1,3 do

        local slot = slots[i]

        if ( slot ) then

            local modItem = ItemService:GetEquippedItem( entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local blueprintName = EntityService:GetBlueprintName( modItem )

                Insert(result, blueprintName)
            end
        end
    end

    if ( result[1] == "" and result[2] == "" and result[3] == "" ) then
        return nil
    end

    return result
end

function artificial_spawner_slots_replacer_tool:IsEqualSlots(slots1, slots2)

    for i=1,3 do

        local slot1 = slots1[i] or ""
        local slot2 = slots2[i] or ""

        if ( slot1 == "" or slot2 == "" ) then
            goto continue
        end

        if ( slot1 ~= slot2 ) then
            return false
        end

        ::continue::
    end

    return true
end

function artificial_spawner_slots_replacer_tool:OnActivateEntity( entity )

    if ( self.SelectedSlotsBlueprints == nil) then
        return
    end

    local equipmentComponent = EntityService:GetComponent(entity, "EquipmentComponent")
    if ( equipmentComponent == nil ) then
        return
    end

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local blueprintName = ""

    local slots = equipment.slots
    for i=1,slots.count do

        local slot = slots[i]

        local modItemBlueprintName = self.SelectedSlotsBlueprints[i] or ""

        if ( modItemBlueprintName == nil or modItemBlueprintName == "" or not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then
            goto continue
        end

        local modItem = ItemService:GetEquippedItem( entity, slot.name )
        if ( modItem == nil or modItem == INVALID_ID ) then
            goto replaceItem
        end

        blueprintName = EntityService:GetBlueprintName( modItem )
        if ( blueprintName == modItemBlueprintName ) then
            goto continue
        end

        ::replaceItem::

        local item = ItemService:GetFirstItemForBlueprint( entity, modItemBlueprintName )

        if ( item == INVALID_ID ) then
            item = ItemService:AddItemToInventory( entity, modItemBlueprintName )
        end

        if ( item ~= INVALID_ID ) then
            ItemService:EquipItemInSlot( entity, item, slot.name )
        end

        ::continue::
    end

    BuildingService:BlinkBuilding(entity)
end

return artificial_spawner_slots_replacer_tool
