return function()
    local rules = require("lua/missions/survival/v2/dom_survival_swamp_rules_default.lua")()

	rules.buildingsUpgradeStartsLogic = 
	{			

	}

    return rules;
end