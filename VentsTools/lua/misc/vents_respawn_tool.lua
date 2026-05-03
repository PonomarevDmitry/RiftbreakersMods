local ghost = require("lua/misc/ghost.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'vents_respawn_tool' ( ghost )

local VentsToolsUtils = require("lua/utils/vents_tools_utils.lua")

function vents_respawn_tool:__init()
    ghost.__init(self,self)
end

function vents_respawn_tool:OnInit()

    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local boundsSize = EntityService:GetBoundsSize( self.selector)
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    EntityService:ChangeMaterial( self.entity, "hologram/blue")
    for child in Iter( self:GetChildren() ) do
        EntityService:ChangeMaterial( child, "hologram/blue")
    end

    self.parameterNamestoreResourceVents = "$VentStore"
    self.parameterNameSelectedBlueprint = "$vents_respawn_tool_selected_blueprint"

    local transform = EntityService:GetWorldTransform( self.entity )
    
    self:CheckEntityBuildable( self.entity, transform )

    self.ghostBlueprint = self.data:GetStringOrDefault("building_blueprint", "")

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )
    self.globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( self.playerId )

    local globalPlayerEntityDB = nil
    if ( self.globalPlayerEntity and self.globalPlayerEntity ~= INVALID_ID ) then
    
        globalPlayerEntityDB = EntityService:GetDatabase( self.globalPlayerEntity )
    end
    
    self.storeResourceVents = VentsToolsUtils:GetStoredBlueprints(globalPlayerEntityDB, self.parameterNamestoreResourceVents)

    self:FillStoredVents()

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedResourceVent = selectorDB:GetStringOrDefault( self.parameterNameSelectedBlueprint, "" ) or ""

    self.selectedResourceVent = self:CheckSelectedBlueprintExist(self.selectedResourceVent)

    if ( #self.storeResourceVentsArray == 0 ) then

        self.selectedResourceVent = nil

        EntityService:SetVisible( self.entity, false )
    end

    self:SpawnMarker()

    self:UpdateMarker()
end

function vents_respawn_tool:FillStoredVents()

    self.storeResourceVentsArray = {}

    if ( self.storeResourceVents == nil ) then
        self.storeResourceVents = {}
    end

    for resourceName, count in pairs( self.storeResourceVents ) do

        if ( count > 0 ) then
        
            Insert(self.storeResourceVentsArray, resourceName)
        end
    end

    if ( mod_vents_respawn_tool_without_preserve ~= nil and mod_vents_respawn_tool_without_preserve == 1 and mod_vents_respawn_tool_without_preserve_list ~= nil ) then

        for resourceName in Iter( mod_vents_respawn_tool_without_preserve_list ) do

            if ( ResourceManager:ResourceExists( "GameplayResourceDef", resourceName ) ) then
            
                if ( self.storeResourceVents[resourceName] == nil or tonumber(self.storeResourceVents[resourceName]) <= 0 ) then

                    self.storeResourceVents[resourceName] = 1

                    if ( IndexOf( self.storeResourceVentsArray, resourceName ) == nil ) then

                        Insert(self.storeResourceVentsArray, resourceName)
                    end
                end
            end
        end
    end

    LogService:Log("storeResourceVentsArray " .. table.concat( self.storeResourceVentsArray, ", " ))

    table.sort(self.storeResourceVentsArray)
end

function vents_respawn_tool:CheckSelectedBlueprintExist( selectedResourceVent )

    local index = IndexOf( self.storeResourceVentsArray, selectedResourceVent )

    if ( index ~= nil ) then

        return selectedResourceVent
    end

    if ( #self.storeResourceVentsArray > 0 ) then

        return self.storeResourceVentsArray[1]
    end

    return nil
end

function vents_respawn_tool:SpawnMarker()

    local markerresourceName = "misc/vent_tool_icon_menu"

    local team = EntityService:GetTeam( self.entity )

    self.markerEntity = EntityService:SpawnAndAttachEntity( markerresourceName, self.entity, team )

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( self.markerEntity, 0, sizeSelf.y, 0 )
end

function vents_respawn_tool:UpdateMarker()

    self.selectedResourceVent = self:CheckSelectedBlueprintExist(self.selectedResourceVent)

    LogService:Log("self.selectedResourceVent " .. tostring(self.selectedResourceVent))

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    if ( self.selectedResourceVent and selectorDB ) then
        selectorDB:SetString( self.parameterNameSelectedBlueprint, self.selectedResourceVent )
    end

    local ventIcon = ""
    local ventName = ""
    local ventIconVisible = 0

    ventIcon, ventName, ventIconVisible = self:GetVentIconNameVisible()

    local menuDB = EntityService:GetOrCreateDatabase( self.markerEntity )
    if ( menuDB == nil ) then
        return
    end

    menuDB:SetString("vent_icon", ventIcon)
    menuDB:SetString("vent_name", ventName)

    menuDB:SetInt("vent_icon_visible", ventIconVisible)
end

function vents_respawn_tool:GetVentIconNameVisible()

    self.selectedResourceVent = self:CheckSelectedBlueprintExist(self.selectedResourceVent)

    local ventIcon = ""
    local ventName = "${gui/hud/vents_tools/no_stored_vents}"
    local ventIconVisible = 0

    if ( self.selectedResourceVent == nil ) then

        return ventIcon, ventName, ventIconVisible
    end

    if ( not ResourceManager:ResourceExists( "GameplayResourceDef", self.selectedResourceVent ) ) then
        return ventIcon, ventName, ventIconVisible
    end

    local resourceDef = ResourceManager:GetResource("GameplayResourceDef", self.selectedResourceVent)
    if ( resourceDef == nil ) then
        return ventIcon, ventName, ventIconVisible
    end

    local resourceDefRef = reflection_helper(resourceDef)



    local count = self.storeResourceVents[self.selectedResourceVent] or 0

    ventIcon = resourceDefRef.bigger_icon
    ventName =  "${" ..resourceDefRef.localization_id .. "}" .. "\n" .. tostring(count)
    ventIconVisible = 1

    local isUnlimited = ( mod_vents_respawn_tool_unlimited ~= nil and mod_vents_respawn_tool_unlimited == 1 ) or ( mod_vents_respawn_tool_without_preserve ~= nil and mod_vents_respawn_tool_without_preserve == 1 );

    if ( isUnlimited ) then

        ventName = ventName .. " - ${gui/hud/vents_tools/unlimited}"
    end

    return ventIcon, ventName, ventIconVisible
end

function vents_respawn_tool:SetLastBuildSpot()

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

function vents_respawn_tool:OnUpdate()

    if ( self.selectedResourceVent == nil ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )
end

function vents_respawn_tool:OnActivate()

    if ( self.selectedResourceVent == nil ) then
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

    Insert( mapperNameArray, "VentRespawnRequest" )

    Insert( mapperNameArray, delimiter )
    Insert( mapperNameArray, self.selectedResourceVent )

    Insert( mapperNameArray, delimiter )
    Insert( mapperNameArray, string.format(formatFloat, position.x) )

    Insert( mapperNameArray, delimiter )
    Insert( mapperNameArray, string.format(formatFloat, position.y) )

    Insert( mapperNameArray, delimiter )
    Insert( mapperNameArray, string.format(formatFloat, position.z) )



    local mapperName = table.concat( mapperNameArray )

    if not ( mod_vents_respawn_tool_unlimited ~= nil and mod_vents_respawn_tool_unlimited == 1 ) then

        self.storeResourceVents[self.selectedResourceVent] = self.storeResourceVents[self.selectedResourceVent] - 1
    end

    if ( self.storeResourceVents[self.selectedResourceVent] <= 0 ) then
        self.storeResourceVents[self.selectedResourceVent] = nil
    end


    

    QueueEvent("OperateActionMapperRequest", self.globalPlayerEntity, mapperName, false )

    self:FillStoredVents()

    self.selectedResourceVent = self:CheckSelectedBlueprintExist(self.selectedResourceVent)

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    if ( self.selectedResourceVent and selectorDB ) then
        selectorDB:SetString( self.parameterNameSelectedBlueprint, self.selectedResourceVent )
    end

    if ( #self.storeResourceVentsArray == 0 ) then

        self.selectedResourceVent = nil

        EntityService:SetVisible( self.entity, false )
    end

    self:UpdateMarker()
end

function vents_respawn_tool:ClearLastBuildPos()

    local selectorComponent = EntityService:GetComponent( self.selector, "BuildingSelectorComponent")
    local container = selectorComponent:GetField("last_build_pos"):ToContainer()
    local item = container:GetItem(0)
    if ( item ~= nil ) then
         container:EraseItem(0)
    end
end

function vents_respawn_tool:OnDeactivate()
    self:ClearLastBuildPos()
end

function vents_respawn_tool:OnRelease()

    self:ClearLastBuildPos()

    if ( self.markerEntity ~= nil ) then
        
        EntityService:RemoveEntity(self.markerEntity)
        self.markerEntity = nil
    end
end

function vents_respawn_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree < 0 ) then
        change = -1
    end

    self:ChangeSelectedBlueprint( change )
end

function vents_respawn_tool:ChangeSelectedBlueprint( change )

    if ( #self.storeResourceVentsArray > 0 ) then

        local selectedResourceVent = self:CheckSelectedBlueprintExist(self.selectedResourceVent)

        local index = IndexOf( self.storeResourceVentsArray, selectedResourceVent )
        if ( index == nil ) then
            index = 1
        end

        local maxIndex = #self.storeResourceVentsArray

        local newIndex = index + change
        if ( newIndex > maxIndex ) then
            newIndex = maxIndex
        elseif( newIndex <= 0 ) then
            newIndex = 1
        end

        local newValue = self.storeResourceVentsArray[newIndex]

        self.selectedResourceVent = newValue

        local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
        if ( self.selectedResourceVent and selectorDB ) then
            selectorDB:SetString( self.parameterNameSelectedBlueprint, self.selectedResourceVent )
        end
    end

    self:UpdateMarker()
end

return vents_respawn_tool
 
