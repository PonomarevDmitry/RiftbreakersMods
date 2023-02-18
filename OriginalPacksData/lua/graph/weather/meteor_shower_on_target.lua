local finder_base = require("lua/graph/utils/utils_finder.lua");
class 'meteor_shower_on_target' ( finder_base )

function meteor_shower_on_target:__init()
	finder_base.__init(self,self)
end

function meteor_shower_on_target:init()
    finder_base.init(self)
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", enter="OnEnterWait", exit= "OnExitWait" } )
end

function meteor_shower_on_target:OnEntitiesFound( entities)
    if ( self.fsm:GetCurrentState() ~= "") then
        return
    end
    if (#entities == 0 ) then
        Assert(false, "Missing target to spawn meteor tower!")
	    self:SetFinished("false")
        return
    end
	local blueprint			= self.data:GetString( "blueprint" )
	local type				= "in_place"
	local warningBp		    = self.data:GetStringOrDefault( "warning_bp", "" )
	local duration			= self.data:GetInt( "duration" )
	local durationMax		= self.data:GetIntOrDefault( "duration_max", 90 )
	local spawnTime			= self.data:GetFloat( "spawn_time" )
	local delay				= self.data:GetFloatOrDefault( "delay", 0.0 )
	local radius			= self.data:GetInt( "radius" )
	local meteorsInOneSpawn	= self.data:GetInt( "meteors_in_one_spawn" )

	self.timer = math.random( duration, durationMax )

	MeteorService:SpawnMeteorShower( entities[1], blueprint, self.timer, spawnTime, radius, meteorsInOneSpawn, delay, warningBp, type )

	self.fsm:ChangeState( "wait" )
end

function meteor_shower_on_target:OnEnterWait( state )
    state:SetDurationLimit( self.timer )
end

function meteor_shower_on_target:OnExitWait( state )
	self:SetFinished("true")
end

return meteor_shower_on_target