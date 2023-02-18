return function()
    local rules = require("lua/missions/survival/dom_survival_magma_rules_default.lua")()

	rules.buildingsUpgradeStartsLogic = 
	{			
		{ name = "headquarters_lvl_2", logic = "logic/hq_upgrade/upgrade_lvl1_sandbox.logic" },   
		{ name = "headquarters_lvl_3", logic = "logic/hq_upgrade/upgrade_lvl1_sandbox.logic" },   
		{ name = "headquarters_lvl_4", logic = "logic/hq_upgrade/upgrade_lvl1_sandbox.logic" },   
	}

    return rules;
end