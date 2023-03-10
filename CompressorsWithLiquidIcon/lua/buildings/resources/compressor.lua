local building = require("lua/buildings/building.lua")
require("lua/utils/string_utils.lua")
class 'compressor' ( building )

function compressor:__init()
    building.__init(self,self)
end

function compressor:OnInit()
    self:RegisterHandler( self.entity, "BuildingModifiedEvent",  "OnBuildingModifiedEvent" )
    
    self.resource = ""
    self.postfix = self.data:GetStringOrDefault( "postfix", "_pipe")

    self.showLiquidIcon = 1
    self:registerBuildMenuTracker()
end

function compressor:OnLoad()
    building.OnLoad(self)

    self:registerBuildMenuTracker()
end

function compressor:registerBuildMenuTracker()

    self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEventCompressorsShowHideIcon" )
end

function compressor:OnLuaGlobalEventCompressorsShowHideIcon( evt )

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

function compressor:CreateMenuEntity()

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

function compressor:ChangeLiquidIcon()

    self:CreateMenuEntity()

    local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )

    if ( self:IsCompressedResourceFilled( menuDB ) ) then
        return
    end

    menuDB:SetString("liquid_icon", "gui/hud/resource_icons/compressed_resources_bigger")
    menuDB:SetString("liquid_name", "")
end

function compressor:IsCompressedResourceFilled( menuDB )

    local resource = ""

    local resourceConverterComponent = EntityService:GetComponent( self.entity, "ResourceConverterComponent" )
    if ( resourceConverterComponent == nil ) then
        resource = ""
    else
        resource = resourceConverterComponent:GetField("last_ore_produced"):GetValue()
    end
    resource = resource or ""

    if ( resource == "" ) then
        return false
    end



    local blueprintName = ItemService:GetResourceBlueprint( resource )
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

    local itemIcon = inventoryCompRef.icon
    local itemBiggerIcon = inventoryCompRef.bigger_icon
    local itemName = inventoryCompRef.name
        
    menuDB:SetString("liquid_icon", itemBiggerIcon)
    menuDB:SetString("liquid_name", itemName)

    return true
end

function compressor:OnBuildingEnd()
    self:FixMaterial()
    self:ChangeLiquidIcon()
end

function compressor:FixMaterial() 
    local resourceConverterComponent = EntityService:GetComponent( self.entity, "ResourceConverterComponent" )
    if ( resourceConverterComponent == nil ) then
        self.resource = ""
    else
        self.resource = resourceConverterComponent:GetField("last_ore_produced"):GetValue()
    end

    self.resource = self.resource:gsub( "_compressed", "" )

    if (IsNullOrEmpty(self.resource)) then
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel" , 1, "default" )
    else
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix , 1, "default" )
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel" , 1, "fresnel" )
    end
end

function compressor:CanEnableSpecialAction()
    return true
end

function compressor:OnBuildingModifiedEvent( evt )
    self:FixMaterial()
    self:ChangeLiquidIcon()
end

return compressor