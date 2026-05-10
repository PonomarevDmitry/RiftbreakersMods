local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'compressors_resources_replacer_tool' ( tool )

function compressors_resources_replacer_tool:__init()
    tool.__init(self,self)
end

function compressors_resources_replacer_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function compressors_resources_replacer_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_compressors_resources_replacer_tool", self.entity)
    self.popupShown = false

    self.SelectedItemBlueprint = self:GetResourceItem()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    LogService:Log("self.SelectedItemBlueprint " .. tostring(self.SelectedItemBlueprint))

    if ( self.SelectedItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.SelectedItemBlueprint ) ) then

        local blueprint = ResourceManager:GetBlueprint( self.SelectedItemBlueprint )

        local component = blueprint:GetComponent("InventoryItemComponent")

        local componentRef = reflection_helper(component)

        local resourceIcon = componentRef.bigger_icon
        local resourceName = componentRef.name

        markerDB:SetString("compressors_resources_icon", resourceIcon)
        markerDB:SetString("compressors_resources_name", resourceName)
        markerDB:SetInt("menu_visible", 1)
    else

        markerDB:SetString("compressors_resources_icon", "")
        markerDB:SetString("compressors_resources_name", "")
        markerDB:SetInt("menu_visible", 0)
    end
end

function compressors_resources_replacer_tool:GetResourceItem()

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    if ( selectorDB and selectorDB:HasString("compressors_resources_picker_tool.selecteditem") ) then

        local resource_item = selectorDB:GetStringOrDefault( "compressors_resources_picker_tool.selecteditem", "" )

        if ( resource_item ~= nil and resource_item ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", resource_item ) ) then
            return resource_item
        end
    end

    return ""
end

function compressors_resources_replacer_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function compressors_resources_replacer_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function compressors_resources_replacer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function compressors_resources_replacer_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName ~= "liquid_decompressor" ) then
            goto continue
        end

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil and modItem ~= INVALID_ID ) then

            local modItemBlueprint = EntityService:GetBlueprintName(modItem)

            if ( modItemBlueprint == self.SelectedItemBlueprint ) then

                goto continue
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function compressors_resources_replacer_tool:OnActivateEntity( entity )

    if ( is_server and is_client ) then

        LogService:Log("OnActivateEntity entity " .. tostring(entity))

        local modItem = ItemService:GetEquippedItem( entity, "MOD_1" )

        if ( modItem ~= nil and modItem ~= INVALID_ID ) then

            LogService:Log("OnActivateEntity RemoveEntity modItem " .. tostring(modItem))

            EntityService:RemoveEntity( modItem )

            QueueEvent( "EquipmentChangeRequest", entity, "MOD_1", 0, INVALID_ID )
        end

        local item = INVALID_ID

        local children = EntityService:GetChildren( entity, true )

        for child in Iter(children) do

            local blueprintName = EntityService:GetBlueprintName( child )

            if ( blueprintName == self.SelectedItemBlueprint and EntityService:GetParent( child ) == entity ) then

                item = child

                break
            end
        end

        if ( item == INVALID_ID ) then

            item = EntityService:SpawnAndAttachEntity(self.SelectedItemBlueprint, entity )

            ItemService:SetInvisible(item, false)

            LogService:Log("OnActivateEntity EntityService:SpawnAndAttachEntity item " .. tostring(item))
        end

        if ( item ~= nil and item ~= INVALID_ID ) then

            LogService:Log("OnActivateEntity EquipItemInSlot item " .. tostring(item))

            ItemService:EquipItemInSlot( entity, item, "MOD_1" )
        end

    else

        local mapperName = "CultivatorResourceToolsReplaceRequest|" .. self.SelectedItemBlueprint

        QueueEvent( "OperateActionMapperRequest", entity, mapperName, false )
    end

    BuildingService:BlinkBuilding(entity)
end

return compressors_resources_replacer_tool
 