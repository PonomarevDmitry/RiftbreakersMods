require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'decompressor_liquid_menu' ( LuaEntityObject )

function decompressor_liquid_menu:__init()
    LuaEntityObject.__init(self, self)
end

function decompressor_liquid_menu:init()

    self.parentBuilding = EntityService:GetParent( self.entity )

    self:RegisterEventHandlers()

    self.showMenu = 0

    local playerId = PlayerService:GetPlayerForEntity( self.parentBuilding )

    if ( PlayerService:IsInFighterMode( playerId ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnLoad()

    self.parentBuilding = EntityService:GetParent( self.entity )

    self:RegisterEventHandlers()

    self.showMenu = self.showMenu or 0

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:RegisterEventHandlers()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        return
    end

    self:RegisterHandler( self.parentBuilding, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.parentBuilding, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.parentBuilding, "StartBuildingEvent",  "OnStartBuildingEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingBuildEndEvent", "OnBuildingBuildEndEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingModifiedEvent", "OnBuildingModifiedEvent" )
    
    self:RegisterHandler( self.parentBuilding, "BuildingSellEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingOverrideEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "ActivateBuildingEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "DeactivateBuildingEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "ActivateResourceBuildingEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "DeactivateResourceBuildingEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "BuildingPoweredEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingPowerOffEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingResourceGrantedEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "BuildingResourceMissingEvent", "OnBuildingModifiedEvent" )

    self:RegisterHandler( self.parentBuilding, "BuildingBuildEvent", "OnBuildingModifiedEvent" )
    self:RegisterHandler( self.parentBuilding, "DestroyRequest", "OnBuildingModifiedEvent" )

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function decompressor_liquid_menu:OnItemEquippedEvent( evt )

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnItemUnequippedEvent( evt )

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnStartBuildingEvent( evt )

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnBuildingBuildEndEvent( evt )

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnBuildingModifiedEvent( evt )

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:UpdateMenuIcons()
end

function decompressor_liquid_menu:UpdateMenuIcons()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        self.data:SetInt("liquid_visible", 0)
        return
    end

    if ( not self:IsCompressedResourceFilled() ) then

        self.data:SetString("liquid_icon", "gui/hud/resource_icons/compressed_resources_bigger")
        self.data:SetString("liquid_name", "gui/hud/messages/compressors_with_liquid_icon/select_compressed_resource")
    end

    self:SetMenuVisible()
end

function decompressor_liquid_menu:IsCompressedResourceFilled()

    local modItem = ItemService:GetEquippedItem( self.parentBuilding, "MOD_1" )

    if ( modItem == INVALID_ID or modItem == nil ) then

        --LogService:Log("modItem == INVALID_ID or modItem == nil ")
        return false
    end

    local blueprintName = EntityService:GetBlueprintName( modItem )
    blueprintName = blueprintName or ""

    --LogService:Log("blueprintName " .. tostring(blueprintName))

    if ( blueprintName == "" ) then

        --LogService:Log("blueprintName == nil ")
        return false
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then

        --LogService:Log("blueprint == nil ")
        return false
    end

    local inventoryComp = blueprint:GetComponent("InventoryItemComponent")
    if ( inventoryComp == nil ) then

        --LogService:Log("inventoryComp == nil ")
        return false
    end

    local inventoryCompRef = reflection_helper(inventoryComp)
    if ( inventoryCompRef == nil ) then
        return false
    end

    local itemBiggerIcon = inventoryCompRef.bigger_icon

    self.data:SetString("liquid_icon", itemBiggerIcon)
    self.data:SetString("liquid_name", "")

    return true
end

function decompressor_liquid_menu:SetMenuVisible()

    if ( self.parentBuilding == nil or self.parentBuilding == INVALID_ID or not EntityService:IsAlive( self.parentBuilding ) ) then
        self.data:SetInt("liquid_visible", 0)
        return
    end

    local visible = 0

    self.showMenu = self.showMenu or 0

    if ( BuildingService:IsBuildingFinished( self.parentBuilding ) ) then
        visible = self.showMenu
    end

    self.data:SetInt("liquid_visible", visible)
end

return decompressor_liquid_menu