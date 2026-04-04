local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'power_wells_respawn_tool' ( ghost )

local PowerWellsToolsUtils = require("lua/utils/power_wells_tools_utils.lua")

function power_wells_respawn_tool:__init()
    ghost.__init(self,self)
end

function power_wells_respawn_tool:OnInit()

    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local boundsSize = EntityService:GetBoundsSize( self.selector)
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "hologram/blue")
    for child in Iter( self:GetChildren() ) do
        EntityService:ChangeMaterial( child, "hologram/blue")
    end

    self.parameterNameStoreBlueprints = "$PowerWellStore"
    self.parameterNameSelectedBlueprint = "$power_wells_respawn_tool_selected_blueprint"

    local transform = EntityService:GetWorldTransform( self.entity )
    
    self:CheckEntityBuildable( self.entity, transform )

    self.ghostBlueprint = self.data:GetStringOrDefault("building_blueprint", "")

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )
    self.globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    local globalPlayerEntityDB = nil
    if ( self.globalPlayerEntity and self.globalPlayerEntity ~= INVALID_ID ) then
    
        globalPlayerEntityDB = EntityService:GetDatabase( self.globalPlayerEntity )
    end
    
    self.storeBlueprints = PowerWellsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, self.parameterNameStoreBlueprints)

    self:FillStoredPowerWells()

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedBlueprint = selectorDB:GetStringOrDefault( self.parameterNameSelectedBlueprint, "" ) or ""

    self.selectedBlueprint = self:CheckSelectedBlueprintExist(self.selectedBlueprint)

    if ( #self.storeBlueprintsArray == 0 ) then

        self.selectedBlueprint = nil

        EntityService:SetVisible( self.entity, false )
    end

    self:SpawnMarker()

    self:UpdateMarker()
end

function power_wells_respawn_tool:FillStoredPowerWells()

    self.storeBlueprintsArray = {}

    if ( self.storeBlueprints == nil ) then
        return
    end

    for blueprintName, count in pairs( self.storeBlueprints ) do

        if ( count > 0 ) then
        
            Insert(self.storeBlueprintsArray, blueprintName)
        end
    end

    table.sort(self.storeBlueprintsArray)
end

function power_wells_respawn_tool:CheckSelectedBlueprintExist( selectedBlueprint )

    local index = IndexOf(self.storeBlueprintsArray, selectedBlueprint )

    if ( index ~= nil ) then

        return selectedBlueprint
    end

    if ( #self.storeBlueprintsArray > 0 ) then

        return self.storeBlueprintsArray[1]
    end

    return nil
end

function power_wells_respawn_tool:SpawnMarker()

    local markerBlueprintName = "misc/power_well_tool_icon_menu"

    local team = EntityService:GetTeam( self.entity )

    self.markerEntity = EntityService:SpawnAndAttachEntity( markerBlueprintName, self.entity, team )

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( self.markerEntity, 0, sizeSelf.y, 0 )
end

function power_wells_respawn_tool:UpdateMarker()

    self.selectedBlueprint = self:CheckSelectedBlueprintExist(self.selectedBlueprint)

    local powerWellIcon = ""
    local powerWellName = ""
    local powerWellIconVisible = 0

    powerWellIcon, powerWellName, powerWellIconVisible = self:GetPowerWellIconNameVisible()

    local menuDB = EntityService:GetOrCreateDatabase( self.markerEntity )
    if ( menuDB == nil ) then
        return
    end

    menuDB:SetString("power_well_icon", powerWellIcon)
    menuDB:SetString("power_well_name", powerWellName)

    menuDB:SetInt("power_well_icon_visible", powerWellIconVisible)
end

function power_wells_respawn_tool:GetPowerWellIconNameVisible()

    self.selectedBlueprint = self:CheckSelectedBlueprintExist(self.selectedBlueprint)

    local powerWellIcon = ""
    local powerWellName = "${gui/hud/power_wells_tools/no_stored_power_wells}"
    local powerWellIconVisible = 0

    if ( self.selectedBlueprint == nil ) then

        return powerWellIcon, powerWellName, powerWellIconVisible
    end

    local blueprintDatabase = EntityService:GetBlueprintDatabase( self.selectedBlueprint )
    if ( blueprintDatabase == nil ) then
        return powerWellIcon, powerWellName, powerWellIconVisible
    end

    if ( not blueprintDatabase:HasString("blueprint") ) then
        return powerWellIcon, powerWellName, powerWellIconVisible
    end

    local bonusBlueprintName = blueprintDatabase:GetString("blueprint")

    local bonusBlueprint = ResourceManager:GetBlueprint( bonusBlueprintName )
    if ( bonusBlueprint == nil ) then
        return powerWellIcon, powerWellName, powerWellIconVisible
    end

    local skillLinkUnitComponent = bonusBlueprint:GetComponent("SkillLinkUnitComponent")
    if ( skillLinkUnitComponent == nil ) then
        return powerWellIcon, powerWellName, powerWellIconVisible
    end

    local skillLinkUnitComponentRef = reflection_helper( skillLinkUnitComponent )

    local count = self.storeBlueprints[self.selectedBlueprint]

    powerWellIcon = skillLinkUnitComponentRef.icon
    powerWellName =  "${" ..skillLinkUnitComponentRef.name .. "}" .. "\n" .. tostring(count)
    powerWellIconVisible = 1

    if ( mod_power_wells_respawn_tool_unlimited ~= nil and mod_power_wells_respawn_tool_unlimited == 1 ) then

        powerWellName = powerWellName .. " - ${gui/hud/power_wells_tools/unlimited}"
    end

    return powerWellIcon, powerWellName, powerWellIconVisible
end

function power_wells_respawn_tool:SetLastBuildSpot()

    local transform = EntityService:GetWorldTransform( self.entity )

    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item == nil ) then item = container:CreateItem() end

    local itemHelper = reflection_helper(item)
    itemHelper.x = transform.position.x
    itemHelper.y = transform.position.y
    itemHelper.z = transform.position.z
end

function power_wells_respawn_tool:OnUpdate()

    if ( self.selectedBlueprint == nil ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )
end

function power_wells_respawn_tool:OnActivate()

    if ( self.selectedBlueprint == nil ) then
        return
    end

    if ( self.globalPlayerEntity == nil or self.globalPlayerEntity == INVALID_ID ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )

    if ( testBuildable.flag ~= CBF_CAN_BUILD ) then

        return
    end

    self:SetLastBuildSpot()

    local delimiter = "|";
    local formatFloat = "%g"

    local position = transform.position
    local orientation = transform.orientation

    local mapperNameArray = {}

    Insert( mapperNameArray, "PowerWellRespawnRequest" )
    Insert( mapperNameArray, delimiter )

    Insert( mapperNameArray, self.selectedBlueprint )
    Insert( mapperNameArray, delimiter )

    Insert( mapperNameArray, string.format(formatFloat, position.x) )
    Insert( mapperNameArray, delimiter )

    Insert( mapperNameArray, string.format(formatFloat, position.y) )
    Insert( mapperNameArray, delimiter )

    Insert( mapperNameArray, string.format(formatFloat, position.z) )
    Insert( mapperNameArray, delimiter )

    Insert( mapperNameArray, string.format(formatFloat, orientation.y) )
    Insert( mapperNameArray, delimiter )

    Insert( mapperNameArray, string.format(formatFloat, orientation.w) )

    local mapperName = table.concat( mapperNameArray )

    if not ( mod_power_wells_respawn_tool_unlimited ~= nil and mod_power_wells_respawn_tool_unlimited == 1 ) then

        self.storeBlueprints[self.selectedBlueprint] = self.storeBlueprints[self.selectedBlueprint] - 1
    end

    if ( self.storeBlueprints[self.selectedBlueprint] <= 0 ) then
        self.storeBlueprints[self.selectedBlueprint] = nil
    end


    

    QueueEvent("OperateActionMapperRequest", self.globalPlayerEntity, mapperName, false )

    self:FillStoredPowerWells()

    self.selectedBlueprint = self:CheckSelectedBlueprintExist(self.selectedBlueprint)

    if ( #self.storeBlueprintsArray == 0 ) then

        self.selectedBlueprint = nil

        EntityService:SetVisible( self.entity, false )
    end

    self:UpdateMarker()
end

function power_wells_respawn_tool:ClearLastBuildPos()

    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item ~= nil ) then
         container:EraseItem(0)
    end
end

function power_wells_respawn_tool:OnDeactivate()
    self:ClearLastBuildPos()
end

function power_wells_respawn_tool:OnRelease()
    self:ClearLastBuildPos()

    if ( self.markerEntity ~= nil ) then
        
        EntityService:RemoveEntity(self.markerEntity)
        self.markerEntity = nil
    end
end

function power_wells_respawn_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree < 0 ) then
        change = -1
    end

    self:ChangeSelectedBlueprint( change )
end

function power_wells_respawn_tool:ChangeSelectedBlueprint( change )

    if ( #self.storeBlueprintsArray > 0 ) then

        local selectedBlueprint = self:CheckSelectedBlueprintExist(self.selectedBlueprint)

        local index = IndexOf( self.storeBlueprintsArray, selectedBlueprint )
        if ( index == nil ) then
            index = 1
        end

        local maxIndex = #self.storeBlueprintsArray

        local newIndex = index + change
        if ( newIndex > maxIndex ) then
            newIndex = maxIndex
        elseif( newIndex <= 0 ) then
            newIndex = 1
        end

        local newValue = self.storeBlueprintsArray[newIndex]

        self.selectedBlueprint = newValue
    end

    self:UpdateMarker()
end

return power_wells_respawn_tool
 
