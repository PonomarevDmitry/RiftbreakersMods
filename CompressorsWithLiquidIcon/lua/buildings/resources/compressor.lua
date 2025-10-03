local building = require("lua/buildings/building.lua")
require("lua/utils/string_utils.lua")
class 'compressor' ( building )

function compressor:__init()
    building.__init(self,self)
end

function compressor:OnInit()
    self:RegisterHandler( self.entity, "BuildingModifiedEvent",  "OnBuildingModifiedEvent" )

    self.resource = ""
    self.postfix = self.data:GetStringOrDefault( "postfix", "_pipe")

    self:registerBuildMenuTracker()

    if ( is_server and is_client ) then
        self:CreateMenuEntity()
    end
end

function compressor:OnLoad()
    building.OnLoad(self)

    self:registerBuildMenuTracker()

    if ( is_server and is_client ) then
        self:CreateMenuEntity()
    end
end

function compressor:registerBuildMenuTracker()

    self:UnregisterHandlers( "LuaGlobalEvent" )

    self:UnregisterHandlers( "EnterBuildMenuEvent" )
    self:UnregisterHandlers( "EnterFighterModeEvent" )
end

function compressor:OnLuaGlobalEventCompressorsShowHideIcon()
    -- Legacy Empty function
end

function compressor:OnEnterBuildMenuEvent( evt )
    -- Legacy Empty function
end

function compressor:OnEnterFighterModeEvent( evt )
    -- Legacy Empty function
end

function compressor:CreateMenuEntity()

    local menuBlueprintName = "misc/compressor_liquid_menu"

    local menuEntity = nil

    local children = EntityService:GetChildren( self.entity, true )
    for child in Iter(children) do

        local blueprintName = EntityService:GetBlueprintName( child )
        if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

            menuEntity = child

            break
        end
    end

    if ( menuEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)
    end

    if ( menuEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and child ~= menuEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    if ( not EntityService:HasComponent( menuEntity, "LuaComponent" ) ) then

        QueueEvent( "RecreateComponentFromBlueprintRequest", menuEntity, "LuaComponent" )
    end

    --local sizeSelf = EntityService:GetBoundsSize( self.entity )
    --EntityService:SetPosition( menuEntity, 0, sizeSelf.y + 3, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("liquid_visible", 0)
    end

end

function compressor:OnBuildingEnd()
    self:FixMaterial()
end

function compressor:FixMaterial()

    local resourceConverterComponent = EntityService:GetComponent( self.entity, "ResourceConverterComponent" )
    if ( resourceConverterComponent == nil ) then
        self.resource = ""
    else
        self.resource = resourceConverterComponent:GetField("last_ore_produced"):GetValue()
    end

    self.resource = self.resource:gsub( "_compressed", "" )


    if (IsNullOrEmpty(self.resource)) then
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_empty_fresnel", 1, "default" )

        if ( self.compressorNonWorking == nil ) then
            self.compressorNonWorking = EntityService:SpawnAndAttachEntity("misc/compressor_minimap_icon_non_working_blue", self.entity)
        end
    else
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .. self.postfix, 1, "default" )
        EntityService:SetSubMeshMaterial( self.entity, "resources/resource_" .. self.resource .."_fresnel", 1, "fresnel" )

        if ( self.compressorNonWorking ~= nil ) then
            EntityService:RemoveEntity(self.compressorNonWorking)
            self.compressorNonWorking = nil
        end
    end
end

function compressor:CanEnableSpecialAction()
    return true
end

function compressor:OnBuildingModifiedEvent( evt )
    self:FixMaterial()
end

function compressor:OnRelease()

    if ( self.compressorNonWorking ~= nil and self.compressorNonWorking ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.compressorNonWorking )
    end

    if ( building.OnRelease ) then
        building.OnRelease( self )
    end
end

return compressor