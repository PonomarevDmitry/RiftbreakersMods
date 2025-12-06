local building = require("lua/buildings/building.lua")

require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'mass_disassembly_base' ( building )

function mass_disassembly_base:__init()
    building.__init(self,self)
end

function mass_disassembly_base:OnInit()

    if ( building.OnInit ) then
        building.OnInit(self)
    end

    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    local playerId = PlayerService:GetPlayerForEntity( self.entity )

    if ( PlayerService:IsInFighterMode( playerId ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self:PopulateSpecialActionInfo()
end

function mass_disassembly_base:OnLoad()

    if ( building.OnLoad ) then
        building.OnLoad(self)
    end

    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    self.showMenu = self.showMenu or 0

    self:PopulateSpecialActionInfo()
end

function mass_disassembly_base:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "UnequipedItemEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "UnequipItemRequest", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.entity, "TimerElapsedEvent", "OnTimerElapsedEvent")

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function mass_disassembly_base:OnBuildingStart()

    if ( building.OnBuildingStart ) then
        building.OnBuildingStart(self)
    end

    self:PopulateSpecialActionInfo()
end

function mass_disassembly_base:OnBuildingEnd()

    if ( building.OnBuildingEnd ) then
        building.OnBuildingEnd(self)
    end

    self:PopulateSpecialActionInfo()
end

function mass_disassembly_base:OnInteractWithEntityRequest( event )
end

function mass_disassembly_base:OnItemEquippedEvent( evt )

    self:PopulateSpecialActionInfo()
end

function mass_disassembly_base:OnItemUnequippedEvent( evt )

    self:PopulateSpecialActionInfo()

    EntityService:CreateComponent( self.entity, "TimerComponent")

    QueueEvent( "SetTimerRequest", self.entity, "RefreshIcons", 3 )
end

function mass_disassembly_base:OnTimerElapsedEvent( evt )

    self:PopulateSpecialActionInfo()
end

function mass_disassembly_base:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:SetMenuVisible(self.menuEntity)
end

function mass_disassembly_base:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:SetMenuVisible(self.menuEntity)
end

function mass_disassembly_base:SetMenuVisible(menuEntity)

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    local visible = 0

    self.showMenu = self.showMenu or 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showMenu
    end

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", visible)
    end
end

function mass_disassembly_base:CreateMenuEntity()

    local menuBlueprintName = "misc/mass_disassembly_slots_menu"

    if ( self.menuEntity ~= nil and not EntityService:IsAlive(self.menuEntity) ) then
        self.menuEntity = nil
    end

    if ( self.menuEntity ~= nil ) then

        local menuParent = EntityService:GetParent( self.menuEntity )

        if ( menuParent == nil or menuParent == INVALID_ID or menuParent ~= self.entity ) then
            self.menuEntity = nil
        end
    end

    if ( self.menuEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.menuEntity = child

                break
            end
        end
    end

    if ( self.menuEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        self.menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)
    end

    if ( self.menuEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and child ~= self.menuEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    if ( self.menuEntity == nil or self.menuEntity == INVALID_ID or not EntityService:IsAlive( self.menuEntity ) ) then
        self.menuEntity = nil
        return
    end

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( self.menuEntity, 0, sizeSelf.y, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( self.menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

function mass_disassembly_base:PopulateSpecialActionInfo()
end

function mass_disassembly_base:GetWeaponModKey(blueprintName, entityId)

    if ( string.find(blueprintName, "items/loot/weapon_mods/mod_damage_over_time_") ~= nil

        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_standard_item") ~= nil
        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_advanced_item") ~= nil
        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_superior_item") ~= nil
        or string.find(blueprintName, "items/loot/weapon_mods/mod_damage_extreme_item") ~= nil
    ) then

        local weaponModComponent = EntityService:GetComponent(entityId, "WeaponModComponent")
        if ( weaponModComponent ~= nil ) then

            local weaponModComponentRef = reflection_helper( weaponModComponent )

            if ( weaponModComponentRef.mod_data and weaponModComponentRef.mod_data.damage_type ) then
        
                local keyResult = blueprintName .. "_" .. tostring(weaponModComponentRef.mod_data.damage_type)

                return keyResult
            end
        end
    end

    return blueprintName
end

return mass_disassembly_base