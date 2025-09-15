require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

function PatchJungleFindRareResources(self)
	if (CampaignService:GetCurrentMissionId() ~= "jungle_find_rare_resource") then
		return
	end
	-- Very bad
	local objectiveName = ObjectiveService:GetObjectiveUniqueNameFromObjectiveId(self.objective_id)
	if (string.match(objectiveName, "grow_trees.connect_water") and self.data:GetString("search_target_value") == "resource_marker") then
		self.data:SetString("search_target_value", "logic/position_rare_resource_deposit")
	end
end

function PatchStoryCampaign()
	local campaign_data = CampaignService:GetCampaignData()
	if campaign_data:GetIntOrDefault("campaign_patcher.version", 0) > 0 then
		return
	end
	
	campaign_data:SetInt("campaign_patcher.version", 1)

	local players = PlayerService:GetAllPlayers()
	if #players == 0 then return end

	local player_id = players[1]

	local mission_win_markers = {
		["acid_scouting"] = {
			research_id = "gui/menu/research/name/floor_acid"
		},
		["acid_find_samples"] = {
			local_objective = "research_lab",
		},
		["acid_find_new_resource"] = {
			research_id = "gui/menu/research/name/resource_handling_palladium"
		},
		["Acid Find Rare Resource"] = {
			local_objective = "find_rhodonite"
		},
		["acid_resource_outpost"] = {
			remain_on_win = true,
			campaign_data = "global.palladium_outpost_complete"
		},
		["desert_scouting"] = {
			research_id = "gui/menu/research/name/environmental_shielding_sun",

			local_objective = "mission_complete",
			local_objective_exists = true
		},
		["desert_find_samples"] = {
			local_objective = "mission_complete",
			local_objective_exists = true
		},
		["desert_find_new_resource"] = {
			research_id = "gui/menu/research/name/resource_handling_uranium"
		},
		["desert_find_rare_resource"] = {
			local_objective = "grow_trees"
		},
		["Desert Resource Outpost"] = {
			remain_on_win = true,
			campaign_data = "global.uranium_outpost_complete"
		},
		["magma_scouting"] = {
			research_id = "gui/menu/research/name/cryo_technology"
		},
		["magma_find_samples"] = {
			local_objective = "find_titanium"
		},
		["magma_find_new_resource"] = {
			research_id = "gui/menu/research/name/resource_handling_titanium"
		},
		["magma_find_rare_resource"] = {
			local_objective = "find_ferdonite"
		},
		["magma_resource_outpost"] = {
			remain_on_win = true,
			campaign_data = "global.titanium_outpost_complete"
		},
		["metallic_outpost"] = {
			remain_on_win = true,
			campaign_data = "global.alien_core_activated|global.alien_core_destroyed"
		},
		["metallic_crash_site"] = {
			local_objective = "mission_complete",
			local_objective_exists = true
		},
		["metallic_factory"] = {
			local_objective = "mission_complete",
			local_objective_exists = true
		},
		["metallic_lakes"] = {
			local_objective = "mission_complete",
			local_objective_exists = true
		},
		["caverns_jungle_entrance"] = {
			campaign_data = "global.caverns_jungle_entry"
		},
		["caverns_entrance"] = {
			research_id = "gui/menu/research/name/mech_weapons_pickaxe_standard"
		},
		["caverns_exploration"] = {
			local_objective = "cave_collapsing",
		},
		["caverns_tunnel"] = {
			local_objective = "exit",
		},
		["caverns_infestation"] = {
			research_id = "gui/menu/research/name/mech_weapons_sonic_fist_standard"
		},
		["caverns_outpost"] = {
			remain_on_win = true,
			campaign_data = "global.caverns_end&global.caverns_infestation_start"
		},
		["swamp_outpost"] = {
			remain_on_win = true,
			campaign_data = "global.swamp_end"
		},
		["swamp_harvest"] = {
			local_objective = "mission_complete",
			local_objective_exists = true
		},
		["swamp_thicket"] = {
			local_objective = "exit",
		},
		["swamp_meadow"] = {
			local_objective = "nuke",
		},
		["swamp_forest"] = {
			remain_on_win = true,
			research_id = "gui/menu/research/name/mech_weapons_root_gun_standard"
		},
		["swamp_forest_cave"] = {
			remain_on_win = true,

			local_objective = "exit",
			local_objective_exists = true
		},
		["swamp_freedom"] = {
			campaign_data = "global.swamp_freedom_complete"
		}
	}

	local current_mission_id = CampaignService:GetCurrentMissionId()
	for mission_id, data in pairs(mission_win_markers) do
		if CampaignService:IsMissionUnlocked( mission_id ) and CampaignService:GetMissionStatus( mission_id ) ~= MISSION_STATUS_WIN then
			local triggers_count = 0
			local triggers_met = 0

			if data.research_id ~= nil then
				triggers_count = triggers_count + 1
				if PlayerService:IsResearchManuallyUnlocked(player_id, data.research_id) then
					triggers_met = triggers_met + 1
				end
			end

			if data.campaign_data ~= nil then
				local keys = Split( data.campaign_data, "&" )
				for key in Iter(keys) do
					triggers_count = triggers_count + 1

					local any_met = false

					local any_keys = Split( key, "|" )
					for any_key in Iter(any_keys) do
						if campaign_data:GetStringOrDefault(any_key, "") == "true" then
							any_met = true
						end
					end

					if any_met then
						triggers_met = triggers_met + 1
					end
				end
			end

			if data.local_objective ~= nil then
				triggers_count = triggers_count + 1

				local objectives = ObjectiveService:FindMatchingLocalObjectiveIdsFromUniqueName(data.local_objective, mission_id)
				for objective_id in Iter(objectives) do
					local objective_status = ObjectiveService:GetObjectiveStatus( objective_id )
					if objective_status == OBJECTIVE_SUCCESS or ( data.local_objective_exists and objective_status ~= OBJECTIVE_FAILED ) then
						triggers_met = triggers_met + 1
					end
				end
			end

			if triggers_met > 0 and triggers_count == triggers_met then
				local can_remove_mission = not data.remain_on_win and not CampaignService:HasOutpostOnMission(player_id, mission_id) and current_mission_id ~= mission_id
				if can_remove_mission then
					CampaignService:RemoveMission(mission_id, MISSION_STATUS_WIN)
				else
					CampaignService:SetMissionStatus(mission_id, MISSION_STATUS_WIN)
				end
			end
		end
	end
end
