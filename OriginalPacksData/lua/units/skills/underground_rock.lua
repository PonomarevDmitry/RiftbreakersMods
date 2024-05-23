local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_underground_rock' ( base_skill )

function skill_underground_rock:__init()
	base_skill.__init(self, self)
end

function skill_underground_rock:OnInit()
	self.rockBp			    = self.data:GetString( "rock_bp" )
	self.warningBp		    = self.data:GetString( "warning_bp" )
	self.warningRadius	    = self.data:GetFloat( "warning_radius" )
	self.spawnMinTime	    = self.data:GetFloat( "spawn_min_time" )
	self.spawnMaxTime	    = self.data:GetFloat( "spawn_max_time" )
	self.rocksInOneSpawn	= self.data:GetInt( "rocks_in_one_spawn" )
	self.delayMin			= self.data:GetFloat( "delay_min" )
	self.delayMax			= self.data:GetFloat( "delay_max" )
	self.delayOffset		= self.data:GetFloat( "delay_offset" )	
	self.offset			    = self.data:GetFloat( "offset" )
	self.spread				= self.data:GetFloat( "spread" )

    self.spawnerWarning = self:CreateStateMachine()
    self.spawnerWarning:AddState( "spawn_warning", { execute="OnExecuteSpawnWarning" } )

	self.spawnerRocks = self:CreateStateMachine()
	self.spawnerRocks:AddState( "spawn_rocks", { execute="OnExecuteSpawnRocks" } )

	self.spawnerDelay = self:CreateStateMachine()
	self.spawnerDelay:AddState( "spawn_delays", { execute="OnExecuteSpawnDelay" } )

	self:SetSpawnTime()

	self.rocks = {}
	self.delays = {}
end

function skill_underground_rock:SetSpawnTime()
	self.spawnTimer = RandFloat( self.spawnMinTime, self.spawnMaxTime );
end

function skill_underground_rock:IsDistinctEnough( newNumber, existingNumbers, minDifference )
    for _, num in ipairs( existingNumbers ) do
        if math.abs( newNumber - num ) < minDifference then
            return false
        end
    end
    return true
end

function skill_underground_rock:GenerateUniqueDelays( count )
    
	local minDifference = ( self.delayOffset / count ) / 2.0

	local numbers = {}
    while #numbers < count do
        local newNumber
        repeat
            newNumber = RandFloat( 0.0, self.delayOffset )
        until self:IsDistinctEnough( newNumber, numbers, minDifference )
        table.insert( numbers, newNumber )
    end
    return numbers
end


function skill_underground_rock:OnExecuteSpawnWarning( state, dt )
	self.spawnTimer = self.spawnTimer - dt

	if ( self.spawnTimer <= 0.0 ) then

		if ( self.currentTarget ~= INVALID_ID ) then
			local uniqueDelays = self:GenerateUniqueDelays( self.rocksInOneSpawn ) 

			for i = 1, self.rocksInOneSpawn, 1 do 
		
				local origin = EntityService:GetPosition( self.currentTarget )
				origin.x = origin.x + RandFloat( -self.spread, self.spread );
				origin.z = origin.z + RandFloat( -self.spread, self.spread );
			
				local delay = RandFloat( self.delayMin, self.delayMax );

				local delayData = {}
				delayData.origin = origin
				delayData.spawnTimer = delay
				delayData.delay = uniqueDelays[i];

				table.insert( self.delays, delayData )
			end
		end

		self:SetSpawnTime()		
	end

end

function skill_underground_rock:OnExecuteSpawnDelay( state, dt )
	for i = #self.delays, 1, -1  do 
		self.delays[i].delay = self.delays[i].delay - dt

		if ( self.delays[i].delay <= 0.0 ) then
			
			local delayData = self.delays[i]

			WeaponService:SpawnDangerMarker( self.warningBp, delayData.origin, self.warningRadius, delayData.spawnTimer )

			local rockData = {}
			rockData.origin = delayData.origin
			rockData.spawnTimer = delayData.spawnTimer

			table.remove( self.delays, i )

			table.insert( self.rocks, rockData )		
		end
	end
end

function skill_underground_rock:OnExecuteSpawnRocks( state, dt )
	for i = #self.rocks, 1, -1  do 
		self.rocks[i].spawnTimer = self.rocks[i].spawnTimer - dt

		if ( self.rocks[i].spawnTimer <= 0.0 ) then
			local origin = self.rocks[i].origin
			local rock = EntityService:SpawnEntity( self.rockBp, origin.x, origin.y + self.offset, origin.z, "" )
			EntityService:SetTeam( rock, EntityService:GetTeam( self.entity ) )

			table.remove( self.rocks, i )
		end
	end
end

function skill_underground_rock:StopSpawner( spawner )
	local state  = spawner:GetState( spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end


function skill_underground_rock:OnUnitAggressiveStateEvent( evt )
	self.spawnerWarning:ChangeState( "spawn_warning" )
	self.spawnerRocks:ChangeState( "spawn_rocks" )
	self.spawnerDelay:ChangeState( "spawn_delays" )

	self.spawnTimer = 0.0
end

function skill_underground_rock:OnUnitNotAggressiveStateEvent( evt )
	self:StopSpawner( self.spawnerWarning )
	self:StopSpawner( self.spawnerRocks )
	self:StopSpawner( self.spawnerDelay )
end

function skill_underground_rock:OnUnitDeadStateEvent( evt )
	EntityService:RemoveEntity( self.entity )
end

return skill_underground_rock