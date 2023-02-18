class 'spawner' ( LuaEntityObject )

function spawner:__init()
	LuaEntityObject.__init(self, self)
end

function spawner:init()
	self:RegisterHandler( self.entity, "DestroyRequest",	  "OnDestroyRequest" )
	self:RegisterHandler( self.entity, "SpawnerInfoRequest",  "OnSpawnerInfoRequest" )

	local currentDifficulty = DifficultyService:GetCurrentDifficultyName()

	local bpName = UnitSpawnerService:GetSpawnBlueprintName( self.entity )
	local bpNameAlpha = bpName .. "_alpha"
	local bpNameUltra = bpName .. "_ultra"

	if ( ( currentDifficulty == "hard" ) and ( EntityService:IsBlueprintExist( bpNameAlpha ) == true ) ) then
		UnitSpawnerService:ReplaceSpawnBlueprint( self.entity, bpNameAlpha )
	elseif ( (  currentDifficulty == "brutal" ) and ( EntityService:IsBlueprintExist( bpNameUltra ) == true ) ) then
		UnitSpawnerService:ReplaceSpawnBlueprint( self.entity, bpNameUltra )
	end
end

function spawner:OnDestroyRequest( evt )
	AnimationService:StopAnim( self.entity , "working" )	
	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(), "wreck_big", 0 )
end

function spawner:OnSpawnerInfoRequest( evt )
	SoundService:PlayAnnouncement( "voice_over/announcement/warning_nest_wave_spawn", 20 )
end

return spawner