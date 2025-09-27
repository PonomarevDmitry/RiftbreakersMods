local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'spawner_activate_all_map_tool' ( tool )

function spawner_activate_all_map_tool:__init()
    tool.__init(self,self)
end

function spawner_activate_all_map_tool:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_spawner_activate_all_map_tool", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.scaleMap = {
        1,
    }

    self.allSpawners = {}
    
    local entities = FindService:FindEntitiesByGroup( "loot_container" )

    for entity in Iter( entities ) do

        if ( entity == nil or entity == INVALID_ID ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        if ( IndexOf( self.allSpawners, entity ) ~= nil ) then
            goto labelContinue
        end

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
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

        local databaseEntity = EntityService:GetOrCreateDatabase( entity )
        if ( databaseEntity ~= nil ) then
            
            if ( not databaseEntity:HasString("wave_logic_file") and not databaseEntity:HasString("boss_logic_file") ) then

                goto labelContinue
            end

            if ( databaseEntity:HasString("forced_group") ) then

                goto labelContinue
            end
        end

        Insert( self.allSpawners, entity )

        ::labelContinue::
    end

    self.popupShown = false
    self.timeoutTime = nil
end

function spawner_activate_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function spawner_activate_all_map_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function spawner_activate_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function spawner_activate_all_map_tool:FindEntitiesToSelect( selectorComponent )

    return self.allSpawners
end

function spawner_activate_all_map_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        self:AddedToSelection( entity )
    end
end

function spawner_activate_all_map_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function spawner_activate_all_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function spawner_activate_all_map_tool:OnRotate()
end

function spawner_activate_all_map_tool:OnActivateSelectorRequest()

    if ( #self.allSpawners == 0 ) then
        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/spawner_activate_tools/activate_all_spawners")

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end


function spawner_activate_all_map_tool:OnGuiPopupResultEvent( evt )

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        local mapperName = "ActivateBioAnomaliesToolsAllRequest|" .. tostring(self.playerId)

        QueueEvent("OperateActionMapperRequest", event_sink, mapperName, false )



        QueueEvent( "LeaveBuildModeRequest", self.selector, false )

        EntityService:RemoveEntity( self.entity )
    end

    self.popupShown = false
end

return spawner_activate_all_map_tool
