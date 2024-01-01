local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/building_utils.lua")

class 'tower_mine_drone_point_picker_tool' ( tool )

function tower_mine_drone_point_picker_tool:__init()
    tool.__init(self,self)
end

function tower_mine_drone_point_picker_tool:OnInit()
    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.buildingBlueprint = self.data:GetStringOrDefault("buildingBlueprint", "") or ""
    self.buildingLowUpgrade = self.data:GetStringOrDefault("buildingLowUpgrade", "") or ""

    self.pickedBuildings = {}
end

function tower_mine_drone_point_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function tower_mine_drone_point_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function tower_mine_drone_point_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function tower_mine_drone_point_picker_tool:AddedToSelection( entity )
end

function tower_mine_drone_point_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function tower_mine_drone_point_picker_tool:OnUpdate()

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

function tower_mine_drone_point_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter(selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= self.buildingLowUpgrade ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function tower_mine_drone_point_picker_tool:OnActivateSelectorRequest()

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

function tower_mine_drone_point_picker_tool:OnActivateEntity( entity )

    local min, max = GetBuildingDisplayRadius(entity)
    local display_effect_blueprint = ""
    local display_radius_group = ""

    if max ~= nil then
        local database = EntityService:GetBlueprintDatabase( self.entity );
        display_effect_blueprint = database:GetStringOrDefault( "display_radius_blueprint", "effects/decals/range_circle" )
        display_radius_group = database:GetStringOrDefault("display_radius_group", "") or ""
    end

    if ( IndexOf( self.pickedBuildings, entity ) == nil ) then

        Insert( self.pickedBuildings, entity )

        if ( display_radius_group == "" ) then
            ShowBuildingDisplayRadiusAround( self.entity, entity )
        end
    else

        Remove( self.pickedBuildings, entity )

        if ( display_radius_group == "" ) then
            HideBuildingDisplayRadiusAround( self.entity, entity )
        end
    end

    if ( #self.pickedBuildings > 0 ) then

        if ( display_radius_group ~= "" ) then
            ShowBuildingDisplayRadiusAround( self.entity, self.buildingBlueprint )
        end

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
        if ( display_radius_group ~= "" ) then
            HideBuildingDisplayRadiusAround( self.entity, self.buildingBlueprint )
        end

        EntityService:RemoveComponent( self.childEntity, "DisplayRadiusComponent" )
    end
end

function tower_mine_drone_point_picker_tool:OnRotateSelectorRequest(evt)
end

function tower_mine_drone_point_picker_tool:ClearPickedBuildings()

    if ( self.pickedBuildings ~= nil) then
        for entity in Iter( self.pickedBuildings ) do
            self:RemovedFromSelection( entity )

            HideBuildingDisplayRadiusAround( self.entity, entity )
        end
    end
    self.pickedBuildings = {}
end

function tower_mine_drone_point_picker_tool:OnRelease()

    self:ClearPickedBuildings()

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return tower_mine_drone_point_picker_tool