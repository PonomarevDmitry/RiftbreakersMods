local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local debug_serialize_utils = require("lua/utils/debug_serialize_utils.lua")

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

        local skinned = EntityService:IsSkinned(entity)

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
        end
    end
end

function light_on_ff_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)

    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function light_on_ff_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function light_on_ff_tool:FilterSelectedEntities( selectedEntities )

    local result = {}

    for entity in Iter( selectedEntities ) do

        if ( self:IsEntityApproved(entity, "lamp") ) then

            Insert(result, entity)
        end

        ::continue::
    end

    return result
end

function light_on_ff_tool:IsEntityApproved( entity, effectGroupName )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( not self:BlueprintHasEffectGroup( blueprintName, effectGroupName ) ) then

        return false
    end
                
    if( self.setPower ) then

        if ( not EffectService:HasEffectByGroup(entity, effectGroupName) ) then

            return true
        end
    else
        
        if ( EffectService:HasEffectByGroup(entity, effectGroupName) ) then

            return true
        end
    end

    return false
end

function light_on_ff_tool:BlueprintHasEffectGroup( blueprintName, effectGroupName )

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return false
    end

    local effectDesc = blueprint:GetComponent("EffectDesc")
    if ( effectDesc == nil ) then
        return false
    end

    local effectDescRef = setmetatable( {}, TypeValueHelper.mt );
    rawset(effectDescRef, "__ptr", effectDesc);

    if ( effectDescRef.Effects ) then
    
        for i=1,effectDescRef.Effects.count do
    
            local effectInstance = effectDescRef.Effects[i]
    
            if ( effectInstance and effectInstance.group and effectInstance.group == effectGroupName ) then
    
                return true
            end
        end       
    end

    return false
end

function light_on_ff_tool:OnActivateEntity( entity )

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

return light_on_ff_tool