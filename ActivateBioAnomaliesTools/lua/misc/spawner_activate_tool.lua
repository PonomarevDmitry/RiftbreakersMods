local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'spawner_activate_tool' ( tool )

function spawner_activate_tool:__init()
    tool.__init(self,self)
end

function spawner_activate_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_spawner_activate_tool", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)
end

function spawner_activate_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function spawner_activate_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function spawner_activate_tool:FindEntitiesToSelect( selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)



    local result = {}

    local searchEntities = FindService:FindEntitiesByGroupInBox( "loot_container", min, max )

    for entity in Iter( searchEntities ) do

        if ( entity == nil or entity == INVALID_ID ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" ) then
            goto labelContinue
        end

        local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
        if ( interactiveComponent == nil ) then
            goto labelContinue
        end

        local interactiveComponentRef = reflection_helper( interactiveComponent )
        if ( interactiveComponentRef.slot ~= "HARVESTER" ) then
            goto labelContinue
        end

        local databaseEntity = EntityService:GetDatabase( entity )
        if ( databaseEntity ~= nil ) then
            
            if ( not databaseEntity:HasString("wave_logic_file") and not databaseEntity:HasString("boss_logic_file") ) then

                goto labelContinue
            end

            if ( databaseEntity:HasString("forced_group") ) then

                goto labelContinue
            end
        end


        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function spawner_activate_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function spawner_activate_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function spawner_activate_tool:OnRotate()
end

function spawner_activate_tool:OnActivateSelectorRequest()

    self.activated = true
    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function spawner_activate_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local minimapItemComponent = EntityService:GetComponent( entity, "MinimapItemComponent" )
    if ( minimapItemComponent ~= nil ) then
        local minimapItemComponentRef = reflection_helper( minimapItemComponent )
        minimapItemComponentRef.unknown_until_visible = false
    end

    local databaseEntity = EntityService:GetDatabase( entity )
    if ( databaseEntity ~= nil ) then
        databaseEntity:SetFloat( "harvest_duration", 2.5 )
    end

    QueueEvent( "HarvestStartEvent", entity )

    EntityService:SpawnEntity( "items/consumables/radar_pulse", entity, "" )
end

return spawner_activate_tool
