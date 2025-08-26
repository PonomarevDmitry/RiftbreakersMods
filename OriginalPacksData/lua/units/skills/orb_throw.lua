local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_orb_throw' ( base_skill )

function skill_orb_throw:__init()
	base_skill.__init(self, self)
end

function skill_orb_throw:OnInit()
	self.orbBp			    = self.data:GetString( "orb_bp" )
	self.warningBp		    = self.data:GetString( "warning_bp" )
	self.warningRadius	    = self.data:GetFloat( "warning_radius" )
	self.spawnMinTime	    = self.data:GetFloat( "spawn_min_time" )
	self.spawnMaxTime	    = self.data:GetFloat( "spawn_max_time" )
	self.orbsInOneSpawn		= self.data:GetInt( "orbs_in_one_spawn" )
	self.delayMin			= self.data:GetFloat( "delay_min" )
	self.delayMax			= self.data:GetFloat( "delay_max" )
	self.delayOffset		= self.data:GetFloat( "delay_offset" )	
	self.spread				= self.data:GetFloat( "spread" )

    self.spawnerWarning = self:CreateStateMachine()
    self.spawnerWarning:AddState( "spawn_warning", { execute="OnExecuteSpawnWarning" } )

	self.spawnerOrbs = self:CreateStateMachine()
	self.spawnerOrbs:AddState( "spawn_orbs", { execute="OnExecuteSpawnOrbs" } )

	self.spawnerDelay = self:CreateStateMachine()
	self.spawnerDelay:AddState( "spawn_delays", { execute="OnExecuteSpawnDelay" } )

	self:SetSpawnTime()

	self.orbs = {}
	self.delays = {}
end

function skill_orb_throw:SetSpawnTime()
	self.spawnTimer = RandFloat( self.spawnMinTime, self.spawnMaxTime );
end

function skill_orb_throw:IsDistinctEnough( newNumber, existingNumbers, minDifference )
    for _, num in ipairs( existingNumbers ) do
        if math.abs( newNumber - num ) < minDifference then
            return false
        end
    end
    return true
end

function skill_orb_throw:GenerateUniqueDelays( count )   
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


function skill_orb_throw:OnExecuteSpawnWarning(state, dt)
	self.spawnTimer = self.spawnTimer - dt

	if (self.spawnTimer <= 0.0) then

		if (self.currentTarget ~= INVALID_ID) then
			local uniqueDelays = self:GenerateUniqueDelays(self.orbsInOneSpawn) 

			for i = 1, self.orbsInOneSpawn, 1 do 		
				local origin
				local validOrigin = false

				local attempts = 0

				repeat

					origin = EntityService:GetPosition(self.currentTarget)
					origin.x = origin.x + RandFloat(-self.spread, self.spread)
					origin.z = origin.z + RandFloat(-self.spread, self.spread)

					attempts = attempts + 1

					validOrigin = true
					for _, delayData in ipairs(self.delays) do
						local existingOrigin = delayData.origin
						local distanceSquared = ( origin.x - existingOrigin.x ) ^ 2 + ( origin.z - existingOrigin.z ) ^ 2
						if distanceSquared < 100 then
							validOrigin = false
							break
						end
					end
				until ( validOrigin and UnitService:IsOnNavigationFreeSpace( origin ) ) or attempts >= 5

				if ( UnitService:IsOnNavigationFreeSpace( origin ) == true ) then
					local delay = RandFloat( self.delayMin, self.delayMax )

					local delayData = {}
					delayData.origin = origin
					delayData.spawnTimer = delay
					delayData.delay = uniqueDelays[i]

					table.insert( self.delays, delayData )
				end
			end

			self:SetSpawnTime()		
		end
	end
end


function skill_orb_throw:OnExecuteSpawnDelay( state, dt )

	for i = #self.delays, 1, -1  do 
		self.delays[i].delay = self.delays[i].delay - dt

		if ( self.delays[i].delay <= 0.0 ) then
			
			local delayData = self.delays[i]

			WeaponService:SpawnDangerMarker( self.warningBp, delayData.origin, self.warningRadius, delayData.spawnTimer )

			local rockData = {}
			rockData.origin = delayData.origin
			rockData.spawnTimer = delayData.spawnTimer

			table.remove( self.delays, i )

			table.insert( self.orbs, rockData )		
		end
	end
end

function skill_orb_throw:OnExecuteSpawnOrbs( state, dt )
	for i = #self.orbs, 1, -1  do 
		self.orbs[i].spawnTimer = self.orbs[i].spawnTimer - dt

		if ( self.orbs[i].spawnTimer <= 0.0 ) then
			local endOrigin = self.orbs[i].origin
			local startOrigin = EntityService:GetPosition( EntityService:GetParent( self.entity ) )
			local orb = EntityService:SpawnEntity( self.orbBp, endOrigin.x, endOrigin.y, endOrigin.z, "" )
			EntityService:SetTeam( orb, EntityService:GetTeam( self.entity ) )
			EntityService:SetVisible( orb, false )
            local db = EntityService:GetDatabase( orb )
            db:SetVector( "start_origin", startOrigin )
			db:SetVector( "end_origin", endOrigin )

			table.remove( self.orbs, i )
		end
	end
end

function skill_orb_throw:StopSpawner( spawner )
	local state  = spawner:GetState( spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end


function skill_orb_throw:OnUnitAggressiveStateEvent( evt )
	self.spawnerWarning:ChangeState( "spawn_warning" )
	self.spawnerOrbs:ChangeState( "spawn_orbs" )
	self.spawnerDelay:ChangeState( "spawn_delays" )

	self.spawnTimer = 0.0
end

function skill_orb_throw:OnUnitNotAggressiveStateEvent( evt )
	self:StopSpawner( self.spawnerWarning )
	self:StopSpawner( self.spawnerOrbs )
	self:StopSpawner( self.spawnerDelay )
end

function skill_orb_throw:OnUnitDeadStateEvent( evt )
	EntityService:RemoveEntity( self.entity )
end

return skill_orb_throw