require("lua/utils/table_utils.lua")

function StringToMissionStatus( mission_result_string )
	if ( not Assert ( type(mission_result_string) == 'string' , "ERROR : Only string conversion supported in StringToMissionStatus, invalid parameter: " .. tostring(mission_result_string) ) )
	then
		return MISSION_STATUS_NONE
	end	
	
	local mapper = 
	{ 
		[ "win" ]  			= MISSION_STATUS_WIN,
		[ "lose" ] 		 	= MISSION_STATUS_LOSE,
		[ "in_progress" ] 	= MISSION_STATUS_IN_PROGRESS,
		[ "none" ] 			= MISSION_STATUS_NONE,
	};
	
	local result = mapper[mission_result_string];
	if ( not Assert( result ~= nil, "ERROR : No mission status: " .. mission_result_string ) )
	then
		return MISSION_STATUS_NONE
	end	

	return result;
end

function StringToObjectiveStatus( objective_status_string )
	if ( not Assert ( type(objective_status_string) == 'string' , "ERROR : Only string conversion supported in StringToObjectiveStatus, invalid parameter: " .. tostring(mission_result_string) ) )
	then
		return OS_IN_PROGRESS
	end	
	
	local objectiveMapper = { 
		[ "OBJECTIVE_IN_PROGRESS" ]  	= OBJECTIVE_IN_PROGRESS,
		[ "OBJECTIVE_SUCCESS" ]  		= OBJECTIVE_SUCCESS,
		[ "OBJECTIVE_SILENT_REMOVE" ]  	= OBJECTIVE_SILENT_REMOVE,
		[ "OBJECTIVE_FAILED" ]  		= OBJECTIVE_FAILED
	}

	local result = objectiveMapper[objective_status_string];
	if ( not Assert( result ~= nil, "ERROR : No objective status: '" .. objective_status_string .. "' result: " .. tostring(result)  ) )
	then
		return OS_IN_PROGRESS
	end	

	return result;
end


function StringToCampaignStatus( campaign_status_string )
	if ( not Assert ( type(campaign_status_string) == 'string' , "ERROR : Only string conversion supported in StringToCampaignStatus, invalid parameter: " .. tostring(campaign_status_string) ) )
	then
		return CAMPAIGN_RESULT_MENU
	end	
	
	local campaignMapper = { 
		[ "MENU" ]  	= CAMPAIGN_RESULT_MENU,
		[ "REMAIN" ]  		= CAMPAIGN_RESULT_REMAIN,
		[ "OTHER_MISSION" ]  	= CAMPAIGN_RESULT_OTHER_MISSION,
	}

	local result = campaignMapper[campaign_status_string];
	if ( not Assert( result ~= nil, "ERROR : No campaign status: '" .. campaign_status_string .. "' result: " .. tostring(result)  ) )
	then
		return CAMPAIGN_RESULT_MENU
	end	

	return result;
end


function StringToItemRarity( item_rarity_string )
	if ( not Assert ( type(item_rarity_string) == 'string' , "ERROR : Only string conversion supported in StringToItemRarity, invalid parameter: " .. tostring(item_rarity_string) ) )
	then
		return WR_STANDARD
	end	
	
	local itemMapper = { 
		[ "STANDARD" ] = WR_STANDARD,
		[ "ADVANCED" ] = WR_ADVANCED,
		[ "SUPERIOR" ] = WR_SUPERIOR,
		[ "EXTREME" ]  = WR_EXTREME,
	}

	local result = itemMapper[item_rarity_string];
	if ( not Assert( result ~= nil, "ERROR : No item  rarity: '" .. item_rarity_string .. "' result: " .. tostring(result)  ) )
	then
		return WR_STANDARD
	end	

	return result;
end