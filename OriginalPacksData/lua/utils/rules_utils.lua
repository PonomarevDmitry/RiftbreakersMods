function GetRulesForDifficulty( name )
	if ( DifficultyService:IsCustomDifficulty() == true ) then
		local customScriptname = name .. "custom.lua"

		LogService:Log( "GetRulesForDifficulty - searching for : " .. customScriptname )	

		if ( ResourceManager:ResourceExists( "LuaScript", customScriptname ) == true ) then
			LogService:Log( "GetRulesForDifficulty - found : " .. customScriptname )
			return ( customScriptname )
		else
			LogService:Log( "GetRulesForDifficulty - failed. Setting default : " .. name .. "default.lua" )
			return ( name .. "default.lua" )
		end
	else
		local difficulty = DifficultyService:GetCurrentDifficultyName()
		LogService:Log( "GetRulesForDifficulty - searching for : " .. name .. difficulty .. ".lua" )	

		if ( ResourceManager:ResourceExists( "LuaScript", name .. difficulty .. ".lua" ) == true ) then
			LogService:Log( "GetRulesForDifficulty - found : " .. name .. difficulty .. ".lua" )
			return ( name .. difficulty .. ".lua" )
		else
			LogService:Log( "GetRulesForDifficulty - failed. Setting default : " .. name .. "default.lua" )
			return ( name .. "default.lua" )
		end
	end
end

function GetRulesForCustomDifficulty( name )
	local difficulty = DifficultyService:GetWaveStrength()
	LogService:Log( "GetRulesForCustomDifficulty - searching for : " .. name .. difficulty .. ".lua" )	

	if ( ResourceManager:ResourceExists( "LuaScript", name .. difficulty .. ".lua" ) == true ) then
		LogService:Log( "GetRulesForCustomDifficulty - found : " .. name .. difficulty .. ".lua" )
		return ( name .. difficulty .. ".lua" )
	else
		LogService:Log( "GetRulesForCustomDifficulty - failed. Setting default : " .. name .. "default.lua" )
		return ( name .. "default.lua" )
	end
end