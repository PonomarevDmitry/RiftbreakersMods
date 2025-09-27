local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'artificial_spawner_activate_all_map_tool' ( tool )

function artificial_spawner_activate_all_map_tool:__init()
    tool.__init(self,self)
end

function artificial_spawner_activate_all_map_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_artificial_spawner_activate_all_map_tool", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.scaleMap = {
        1,
    }

    local world_min = MissionService:GetWorldBoundsMin();
    local world_max = MissionService:GetWorldBoundsMax();

    world_min.y = -100.0
    world_max.y = 100.0

    self.allSpawners = FindService:FindEntitiesByBlueprintInBox("buildings/main/artificial_spawner", world_min, world_max )

    self.popupShown = false
    self.timeoutTime = nil
end

function artificial_spawner_activate_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function artificial_spawner_activate_all_map_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function artificial_spawner_activate_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function artificial_spawner_activate_all_map_tool:FindEntitiesToSelect( selectorComponent )

    return self.allSpawners
end

function artificial_spawner_activate_all_map_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        self:AddedToSelection( entity )
    end
end

function artificial_spawner_activate_all_map_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function artificial_spawner_activate_all_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function artificial_spawner_activate_all_map_tool:OnRotate()
end

function artificial_spawner_activate_all_map_tool:OnActivateSelectorRequest()

    if ( #self.allSpawners == 0 ) then
        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/artificial_spawner_slots_tools/activate_all_artificial_spawners")
        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end


function artificial_spawner_activate_all_map_tool:OnGuiPopupResultEvent( evt)

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        EffectService:SpawnEffect( self.player, "effects/enemies_generic/wave_start" )

        for entity in Iter( self.allSpawners ) do

            QueueEvent( "InteractWithEntityRequest", entity, self.player )
        end
    end

    self.popupShown = false
end

return artificial_spawner_activate_all_map_tool
