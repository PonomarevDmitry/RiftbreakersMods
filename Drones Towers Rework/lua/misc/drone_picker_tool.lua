local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/building_utils.lua")

class 'drone_picker_tool' ( tool )

function drone_picker_tool:__init()
    tool.__init(self,self)
end

function drone_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_drone_picker_tool", self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.pickedBuildings = {}
end

function drone_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function drone_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function drone_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function drone_picker_tool:AddedToSelection( entity )
end

function drone_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function drone_picker_tool:OnUpdate()

    for entity in Iter( self.pickedBuildings ) do

        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
        end
    end

    for entity in Iter( self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)

        local isInList = ( IndexOf( self.pickedBuildings, entity ) ~= nil )

        if ( isInList ) then

            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_deny", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_deny", "selected")
            end
        else
            -- Mark candidate to add to template
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
            end
        end
    end
end

function drone_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= "tower_drone_attack" and lowName ~= "tower_mine_layer" ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function drone_picker_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities > 0 ) then

        for entity in Iter( self.selectedEntities ) do

            self:OnActivateEntity( entity )
        end

        return
    end

    if ( #self.pickedBuildings == 0 ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )

    local params = {
        point_x = transform.position.x,
        point_z = transform.position.z
    }

    for entity in Iter( self.pickedBuildings ) do

        QueueEvent( "LuaGlobalEvent", entity, "DronePointChangeEvent", params )
    end
end

function drone_picker_tool:OnActivateEntity( entity )

    if ( IndexOf( self.pickedBuildings, entity ) == nil ) then

        Insert( self.pickedBuildings, entity )

    else

        Remove( self.pickedBuildings, entity )
    end

    local min, max = GetBuildingDisplayRadius(entity)
    local display_effect_blueprint = nil

    if max ~= nil then
        local database = EntityService:GetBlueprintDatabase( self.entity );
        display_effect_blueprint = database:GetStringOrDefault( "display_radius_blueprint", "effects/decals/range_circle" )
    end

    if ( #self.pickedBuildings > 0 ) then

        ShowBuildingDisplayRadiusAround( self.entity, "buildings/defense/tower_mine_layer" )

        if max ~= nil then
            local displayRadiusComponent = EntityService:GetComponent(self.childEntity,"DisplayRadiusComponent")

            if ( displayRadiusComponent == nil ) then

                displayRadiusComponent = EntityService:CreateComponent(self.childEntity,"DisplayRadiusComponent")

                local displayRadiusComponentRef = reflection_helper( displayRadiusComponent )
                displayRadiusComponentRef.min_radius = min
                displayRadiusComponentRef.max_radius = max
                displayRadiusComponentRef.max_radius_blueprint = display_effect_blueprint
            end
        end
    else
        HideBuildingDisplayRadiusAround( self.entity, "buildings/defense/tower_mine_layer" )

        EntityService:RemoveComponent( self.childEntity, "DisplayRadiusComponent" )
    end
end

function drone_picker_tool:OnRotateSelectorRequest(evt)
end

function drone_picker_tool:ClearPickedBuildings()

    if ( self.pickedBuildings ~= nil) then
        for entity in Iter( self.pickedBuildings ) do
            self:RemovedFromSelection( entity )

            HideBuildingDisplayRadiusAround( self.entity, entity )
        end
    end
    self.pickedBuildings = {}
end

function drone_picker_tool:OnRelease()

    self:ClearPickedBuildings()

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return drone_picker_tool