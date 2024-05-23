g_throttler = {}

function SetTargetFinderThrottler( lock_name, limit )
	g_throttler[ lock_name ] = { time = 0, requests = 0, requests_limit = limit }
end

function IsRequestThrottled( lock_name )
	if g_throttler[ lock_name ] == nil then
		return false
	end
	
	local time = GetLogicTime()

	local state = g_throttler[ lock_name ];
	if state.time ~= time then
		state.time = time
		state.requests = 0
	end

	state.requests = state.requests + 1
	return state.requests > state.requests_limit
end