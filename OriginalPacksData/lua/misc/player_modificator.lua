local drone_spawner = require("lua/items/drone_spawner.lua")
class 'player_modificator' ( drone_spawner )

function player_modificator:__init()
	drone_spawner.__init(self,self)
end

function player_modificator:EnsureUniqueModificator()
    local mod_group = EntityService:GetGroup(self.entity)
    if mod_group == "" then
        return
    end

    local children = EntityService:GetChildren( self.parent, true )
    for child in Iter( children ) do
        local child_group = EntityService:GetGroup(self.entity)
        if child_group == mod_group and child ~= self.entity then
            EntityService:RemoveEntity( child )
        end
    end
end

function player_modificator:init()
    drone_spawner.init(self)

    self.parent = EntityService:GetParent(self.entity)
    while EntityService:HasComponent(self.parent, "ParentComponent") do
        self.parent = EntityService:GetParent(self.parent)
    end

    self.mods = {}
    if not EntityService:HasComponent(self.parent, "EntityStatComponent") then
        return
    end

    if not Assert( self.parent ~= INVALID_ID, "ERROR: player_modificator script of: " .. EntityService:GetBlueprintName(self.entity) .. " must be used as a child entity!") then
        return
    end

    self.mods = self.data:GetStringKeys()
    for mod_type in Iter(self.mods) do
        if EntityModType[mod_type] then
            EntityService:AddEntityMod(self.parent, tostring(self.entity), mod_type, self.data:GetString(mod_type))
        end
    end
end

function player_modificator:OnLoad()
    self.mods = self.mods or {}

    drone_spawner.OnLoad(self)
end

function player_modificator:OnRelease()
    if EntityService:IsAlive( self.parent ) then
        for mod_type in Iter(self.mods) do
            if EntityModType[mod_type] then
                EntityService:RemovEntityMod(self.parent, tostring(self.entity), mod_type)
            end
        end
    end

    drone_spawner.OnRelease(self)
end

return player_modificator