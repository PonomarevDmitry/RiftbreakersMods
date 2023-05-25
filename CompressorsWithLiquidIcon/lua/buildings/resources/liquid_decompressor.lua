require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local building = require("lua/buildings/building.lua")
class 'liquid_decompressor' ( building )

function liquid_decompressor:__init()
    building.__init(self,self)
end

function liquid_decompressor:OnInit()
    building.OnInit( self )

    self.item = INVALID_ID
    self.production = self.data:GetFloatOrDefault("production", 100 )
    self.consumption = self.data:GetFloatOrDefault("consumption", 1 )
    self.attachment = self.data:GetStringOrDefault("attachment", "att_out_1" )
    self.lastResource = ""

    local owner = self.data:GetIntOrDefault( "owner", 0)
    BuildingService:CheckAndAddAllCompressedresources( owner )
    BuildingService:ClearDecompressor(self.entity  )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self.postfix = self.data:GetStringOrDefault( "postfix", "_storage")
    EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )

    self.showLiquidIcon = 1
    self:registerBuildMenuTracker()
end

function liquid_decompressor:OnLoad()
    building.OnLoad(self)

    self:registerBuildMenuTracker()
end

function liquid_decompressor:UpdateWorkingStatus()
    if ( EntityService:IsAlive( self.item ) ) then
        BuildingService:EnableBuilding( self.entity )
    else
        BuildingService:DisableBuilding( self.entity )
    end

    self:PopulateSpecialActionInfo()
end

function liquid_decompressor:OnBuildingEnd()
    self:UpdateWorkingStatus()
    building.OnBuildingEnd(self)
end

function liquid_decompressor:CreateMenuEntity()

    self:registerBuildMenuTracker()

    if ( self.compressorLiquidMenu == nil ) then

        self.compressorLiquidMenu = EntityService:SpawnAndAttachEntity("misc/compressor_liquid_menu", self.entity)

        local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )

        if ( self.showLiquidIcon == nil ) then
            self.showLiquidIcon = 1
        end

        menuDB:SetInt("liquid_visible", self.showLiquidIcon)
    end
end

function liquid_decompressor:PopulateSpecialActionInfo()

    self:CreateMenuEntity()

    local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )

    if ( self:IsCompressedResourceFilled( menuDB ) ) then

        if ( self.compressorNonWorking ~= nil ) then
            EntityService:RemoveEntity(self.compressorNonWorking)
            self.compressorNonWorking = nil
        end
        return
    end

    self.data:SetString("action_icon", "gui/hud/resource_icons/compressed_resources_bigger" )

    menuDB:SetString("liquid_icon", "gui/hud/resource_icons/compressed_resources_bigger")
    menuDB:SetString("liquid_name", "gui/hud/messages/compressors_with_liquid_icon/select_compressed_resource")

    if ( self.compressorNonWorking == nil ) then
        self.compressorNonWorking = EntityService:SpawnAndAttachEntity("misc/compressor_minimap_icon_non_working_blue", self.entity)
    end
end

function liquid_decompressor:IsCompressedResourceFilled( menuDB )

    if ( self.item == INVALID_ID or self.item == nil ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( self.item )
    blueprintName = blueprintName or ""

    if ( blueprintName == "" ) then
        return false
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local inventoryComp = blueprint:GetComponent("InventoryItemComponent")
    if ( inventoryComp == nil ) then
        return false
    end

    local inventoryCompRef = reflection_helper(inventoryComp)
    if ( inventoryCompRef == nil ) then
        return false
    end

    local itemBiggerIcon = inventoryCompRef.bigger_icon
        
    self.data:SetString("action_icon", itemBiggerIcon )

    menuDB:SetString("liquid_icon", itemBiggerIcon)
    menuDB:SetString("liquid_name", "")

    return true
end

function liquid_decompressor:registerBuildMenuTracker()

    self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEventCompressorsShowHideIcon" )
end

function liquid_decompressor:OnLuaGlobalEventCompressorsShowHideIcon( evt )

    local eventName = evt:GetEvent()
    
    if eventName == "CompressorsHideLiquidIcon" then

        self.showLiquidIcon = 0

        if ( self.compressorLiquidMenu ~= nil ) then
            local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )
            menuDB:SetInt("liquid_visible", 0)
        end
    elseif eventName == "CompressorsShowLiquidIcon" then

        self.showLiquidIcon = 1

        if ( self.compressorLiquidMenu ~= nil ) then
            local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )
            menuDB:SetInt("liquid_visible", 1)
        end
    end
end

function liquid_decompressor:OnItemEquippedEvent( evt )

    self:registerBuildMenuTracker()

    self.item = evt:GetItem()    
    BuildingService:ReplaceProductionByCompressedItem( self.entity, self.item, self.lastResource, self.attachment, self.production, self.consumption )
    self:UpdateWorkingStatus()

    local info = EntityService:GetResourceAmount( self.item )
    self.lastResource = info.first
    self.resource = self.lastResource:gsub( "_compressed", "" )

    if (IsNullOrEmpty(self.resource)) then
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )
    else
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix, 1, "default" )
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel", 1, "fresnel" )
    end
end

function liquid_decompressor:OnRelease()

    if ( self.compressorLiquidMenu ~= nil and self.compressorLiquidMenu ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.compressorLiquidMenu )
    end

    if ( self.compressorNonWorking ~= nil and self.compressorNonWorking ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.compressorNonWorking )
    end

    if ( building.OnRelease ) then
        building.OnRelease( self )
    end
end

return liquid_decompressor