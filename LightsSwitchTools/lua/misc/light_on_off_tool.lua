local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LightsUtils = require("lua/utils/lights_utils.lua")

class 'light_on_ff_tool' ( tool )

function light_on_ff_tool:__init()
    tool.__init(self,self)
end

function light_on_ff_tool:OnInit()

    self.setPower = ( self.data:GetIntOrDefault("set_power", 0) == 1 )

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity( marker_name, self.entity )
end

function light_on_ff_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function light_on_ff_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        self:AddedToSelection( entity )
    end
end

function light_on_ff_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function light_on_ff_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function light_on_ff_tool:FilterSelectedEntities( selectedEntities )

    local result = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( self:IsEntityApproved(entity, "lamp") ) then

            Insert(result, entity)

        elseif ( lowName == "base_lamp" or lowName == "crystal_lamp" ) then

            Insert(result, entity)
        end

        ::continue::
    end

    return result
end

function light_on_ff_tool:IsEntityApproved( entity, effectGroupName )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( not LightsUtils:BlueprintHasEffectGroup( blueprintName, effectGroupName ) ) then

        return false
    end

    return true
end

function light_on_ff_tool:OnActivateEntity( entity )

    if ( is_server and is_client ) then

        local blueprintName = EntityService:GetBlueprintName( entity )

        local lowName = BuildingService:FindLowUpgrade( blueprintName )

        if ( lowName == "base_lamp" or lowName == "crystal_lamp" ) then

            if( self.setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "working") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:AttachEffects(entity, "working")
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "working") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:DestroyEffectsByGroup(entity, "working")
                end
            end

        else

            if( self.setPower ) then

                if ( not EffectService:HasEffectByGroup(entity, "lamp") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:AttachEffects(entity, "lamp")
                end
            else

                if ( EffectService:HasEffectByGroup(entity, "lamp") ) then

                    BuildingService:BlinkBuilding(entity)

                    EffectService:DestroyEffectsByGroup(entity, "lamp")
                end
            end
        end

    else

        local mapperName = ""

        if( self.setPower ) then

            mapperName = "LightsSwitchToolsEntityTurnOn"

        else

            mapperName = "LightsSwitchToolsEntityTurnOff"
        end

        QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
    end
end

return light_on_ff_tool