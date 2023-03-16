local Research = require("lua/utils/researches_unlock_custom_trees_utils.lua")

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    Research:CheckResearches()
end)

