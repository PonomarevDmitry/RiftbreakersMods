local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_eggs' ( base_skill )

function skill_eggs:__init()
	base_skill.__init(self, self)
end



function skill_eggs:OnInit()
    self.canSpawnEggs = false
    UnitSpawnerService:DisableUnitSpawner( self.entity )
end

function skill_eggs:OnUnitAggressiveStateEvent( evt )
    self.canSpawnEggs = true

    if ( self.currentTarget ~= INVALID_ID ) then
        UnitSpawnerService:EnableUnitSpawner( self.entity )
    end
end

function skill_eggs:OnUnitNotAggressiveStateEvent( evt )
    self.canSpawnEggs = false
	UnitSpawnerService:DisableUnitSpawner( self.entity )
end

function skill_eggs:OnUnitDeadStateEvent( evt )
	EntityService:RemoveEntity( self.entity )
end

function skill_eggs:TargetHasChangedEvent( evt )

    if ( self.canSpawnEggs == false ) then
        return
    end
    
    LogService:Log( "self.targetCorpsesExist = false" )

    if ( self.currentTarget == INVALID_ID ) then
        UnitSpawnerService:DisableUnitSpawner( self.entity )
    else
        UnitSpawnerService:EnableUnitSpawner( self.entity )
    end

end

return skill_eggs