local tool = require("lua/misc/tool.lua")

class 'tool_highlight_ruins' ( tool )

function tool_highlight_ruins:__init()
    tool.__init(self,self)

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function tool_highlight_ruins:HighlightRuins()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    -- Remove highlighting from previous ruins
    for ruinEntity in Iter( self.previousMarkedRuins ) do

        -- If the ruin is not included in the new list
        if ( IndexOf( ruinsList, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        EntityService:RemoveMaterial( ruinEntity, "selected" )
        local children = EntityService:GetChildren( ruinEntity, true )
        for child in Iter( children ) do
            EntityService:RemoveMaterial( child, "selected" )
        end

        ::continue::
    end

    for ruinEntity in Iter( ruinsList ) do

        self:SetEntitySelectedMaterial( ruinEntity, "hologram/grey" )
    end

    self.previousMarkedRuins = ruinsList
end

function tool_highlight_ruins:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local ruinsList = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for ruinEntity in Iter( ruinsList ) do

        if ( IndexOf( result, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetOrCreateDatabase( ruinEntity )
        if ( database == nil ) then
            goto continue
        end

        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local ruinsBlueprint = database:GetString("blueprint")
        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto continue
        end

        Insert( result, ruinEntity )

        ::continue::
    end

    return result
end

function tool_highlight_ruins:OnRelease()

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do
            EntityService:RemoveMaterial( ruinEntity, "selected" )
            local children = EntityService:GetChildren( ruinEntity, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
    end
    self.previousMarkedRuins = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

function tool_highlight_ruins:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

return tool_highlight_ruins