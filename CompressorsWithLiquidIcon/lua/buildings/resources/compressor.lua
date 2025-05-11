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

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    if ( PlayerService:IsInFighterMode( owner ) ) then
        self.showLiquidIcon = 0
    else
        self.showLiquidIcon = 1
    end

    self:registerBuildMenuTracker()
end

function compressor:OnLoad()
    building.OnLoad(self)

    self.showLiquidIcon = self.showLiquidIcon or 0
    self:registerBuildMenuTracker()
end

function compressor:registerBuildMenuTracker()

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function compressor:OnLuaGlobalEventCompressorsShowHideIcon()
    -- Legacy Empty function
end

function compressor:OnEnterBuildMenuEvent( evt )

    self.showLiquidIcon = 1

    self:SetCompressorLiquidMenuVisible()
end

function compressor:OnEnterFighterModeEvent( evt )

    self.showLiquidIcon = 0

    self:SetCompressorLiquidMenuVisible()
end

function compressor:SetCompressorLiquidMenuVisible()

    self:CreateMenuEntity()

    local visible = 0

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    if ( BuildingService:IsBuildingFinished( self.entity ) and not PlayerService:IsInFighterMode( owner ) ) then
        visible = self.showLiquidIcon
    end

    local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )
    menuDB:SetInt("liquid_visible", visible)
end

function compressor:CreateMenuEntity()

    self:registerBuildMenuTracker()

    if ( self.compressorLiquidMenu == nil ) then

        self.compressorLiquidMenu = EntityService:SpawnAndAttachEntity("misc/compressor_liquid_menu", self.entity)

        local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )

        self.showLiquidIcon = self.showLiquidIcon or 1

        local visible = 0

        local owner = self.data:GetIntOrDefault( "owner", 0 )

        if ( BuildingService:IsBuildingFinished( self.entity ) and not PlayerService:IsInFighterMode( owner ) ) then
            visible = self.showLiquidIcon
        end

        menuDB:SetInt("liquid_visible", visible)
    end
end

function compressor:ChangeLiquidIcon()

    self:CreateMenuEntity()

    local menuDB = EntityService:GetDatabase( self.compressorLiquidMenu )

    if ( self:IsCompressedResourceFilled( menuDB ) ) then

        if ( self.compressorNonWorking ~= nil ) then
            EntityService:RemoveEntity(self.compressorNonWorking)
            self.compressorNonWorking = nil
        end
        return
    end

    menuDB:SetString("liquid_icon", "gui/hud/resource_icons/compressed_resources_bigger")
    menuDB:SetString("liquid_name", "gui/hud/messages/compressors_with_liquid_icon/connect_resource")

    if ( self.compressorNonWorking == nil ) then
        self.compressorNonWorking = EntityService:SpawnAndAttachEntity("misc/compressor_minimap_icon_non_working_blue", self.entity)
    end
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

    local itemBiggerIcon = inventoryCompRef.bigger_icon

    menuDB:SetString("liquid_icon", itemBiggerIcon)
    menuDB:SetString("liquid_name", "")

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
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )
    else
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix, 1, "default" )
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel", 1, "fresnel" )
    end
end

function compressor:CanEnableSpecialAction()
    return true
end

function compressor:OnBuildingModifiedEvent( evt )
    self:FixMaterial()
    self:ChangeLiquidIcon()
end

function compressor:OnRelease()

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

return compressor