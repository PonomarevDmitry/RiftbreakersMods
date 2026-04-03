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

    local transform = EntityService:GetWorldTransform( self.entity )
    
    self:CheckEntityBuildable( self.entity, transform )

    self.ghostBlueprint = self.data:GetStringOrDefault("building_blueprint", "")

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    self:SpawnMarker()
end

function power_wells_respawn_tool:SpawnMarker()

    local markerBlueprintName = "misc/power_well_tool_icon_menu"

    local team = EntityService:GetTeam( self.entity )

    self.markerEntity = EntityService:SpawnAndAttachEntity( markerBlueprintName, self.entity, team )

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( self.markerEntity, 0, sizeSelf.y, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( self.markerEntity )
    if ( menuDB == nil ) then
        return
    end

    --menuDB:SetString("power_well_icon", skillLinkUnitComponentRef.icon)
    --menuDB:SetString("power_well_name", skillLinkUnitComponentRef.name)

    menuDB:SetInt("power_well_icon_visible", 1)
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

    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )
end

function power_wells_respawn_tool:OnActivate()

    local transform = EntityService:GetWorldTransform( self.entity )
    local testBuildable = self:CheckEntityBuildable( self.entity , transform, false )

    if ( testBuildable.flag == CBF_CAN_BUILD ) then

        self:SetLastBuildSpot()
    end
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
    if ( degree > 0 ) then
        change = -1
    end

    local playerPosition = EntityService:GetPosition(self.playerEntity)
    
    local entityPosition = EntityService:GetPosition(self.entity)

    local isChangeList = ( entityPosition.x >= playerPosition.x )

    if ( isChangeList ) then

    else
    
        self:RotateBuilding( degree )
    end
end

function power_wells_respawn_tool:RotateBuilding( degree )

    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end

    EntityService:Rotate(self.entity, 0.0, 1.0, 0.0, degree )
end

return power_wells_respawn_tool
 
