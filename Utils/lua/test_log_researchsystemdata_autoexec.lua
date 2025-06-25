require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_researchsystemdata", function( args )

    local researchSystemDataComponent = EntityService:GetSingletonComponent("ResearchSystemDataComponent")

    if ( researchSystemDataComponent == nil ) then

        LogService:Log("ResearchSystemDataComponent is nil")
        return
    end

    -- | [bool](/riftbreaker-wiki/docs/game-reflection/components/bool/) | laboratory_build |
    -- | [bool](/riftbreaker-wiki/docs/game-reflection/components/bool/) | communications_hub_build |
    -- | [TeamId](/riftbreaker-wiki/docs/game-reflection/classes/team_id/) | team_id |
    -- | Container< [ResearchTree](/riftbreaker-wiki/docs/game-reflection/classes/research_tree/) > | research |
    -- | [String](/riftbreaker-wiki/docs/game-reflection/components/string/) | editor |
    -- | Container< [StringHash](/riftbreaker-wiki/docs/game-reflection/classes/string_hash/) > | can_be_tested_for_researched |
    -- | [String](/riftbreaker-wiki/docs/game-reflection/components/string/) | research_tree |
    -- | Container< [ResearchInfo](/riftbreaker-wiki/docs/game-reflection/classes/research_info/) > | additional_trees |
    -- | Container< [Pair_String_float](/riftbreaker-wiki/docs/game-reflection/classes/pair__string_float/) > | research_times |
    -- | [uint64](/riftbreaker-wiki/docs/game-reflection/components/uint64/) | version |
    -- | Container< [String](/riftbreaker-wiki/docs/game-reflection/components/string/) > | researched |
    -- | Container< [String](/riftbreaker-wiki/docs/game-reflection/components/string/) > | can_be_researched |
    -- | Container< [String](/riftbreaker-wiki/docs/game-reflection/components/string/) > | researching |
    -- | Container< [String](/riftbreaker-wiki/docs/game-reflection/components/string/) > | new_researches |
    -- | Container< [String](/riftbreaker-wiki/docs/game-reflection/components/string/) > | hilight_research |

    local researchSystemDataComponentRef = reflection_helper( researchSystemDataComponent )

    if ( researchSystemDataComponentRef.research_tree ) then

        LogService:Log("research_tree " .. tostring(research_tree))
    end

    if ( researchSystemDataComponentRef.research and researchSystemDataComponentRef.research.count > 0 ) then

        for i=1,researchSystemDataComponentRef.research.count do

            local research = researchSystemDataComponentRef.research[i]

            LogService:Log("research[" .. tostring(i) .. "] " .. tostring(research))
        end
    end

    if ( researchSystemDataComponentRef.can_be_tested_for_researched and researchSystemDataComponentRef.can_be_tested_for_researched.count > 0 ) then

        for i=1,researchSystemDataComponentRef.can_be_tested_for_researched.count do

            local can_be_tested_for_researched = researchSystemDataComponentRef.can_be_tested_for_researched[i]

            LogService:Log("can_be_tested_for_researched[" .. tostring(i) .. "] " .. tostring(can_be_tested_for_researched))
        end
    end

    if ( researchSystemDataComponentRef.additional_trees and researchSystemDataComponentRef.additional_trees.count > 0 ) then

        for i=1,researchSystemDataComponentRef.additional_trees.count do

            local additional_trees = researchSystemDataComponentRef.additional_trees[i]

            LogService:Log("additional_trees[" .. tostring(i) .. "] " .. tostring(additional_trees))
        end
    end

    if ( researchSystemDataComponentRef.research_times and researchSystemDataComponentRef.research_times.count > 0 ) then

        for i=1,researchSystemDataComponentRef.research_times.count do

            local research_times = researchSystemDataComponentRef.research_times[i]

            LogService:Log("research_times[" .. tostring(i) .. "] " .. tostring(research_times))
        end
    end

    if ( researchSystemDataComponentRef.researched and researchSystemDataComponentRef.researched.count > 0 ) then

        for i=1,researchSystemDataComponentRef.researched.count do

            local researched = researchSystemDataComponentRef.researched[i]

            LogService:Log("researched[" .. tostring(i) .. "] " .. tostring(researched))
        end
    end

    if ( researchSystemDataComponentRef.can_be_researched and researchSystemDataComponentRef.can_be_researched.count > 0 ) then

        for i=1,researchSystemDataComponentRef.can_be_researched.count do

            local can_be_researched = researchSystemDataComponentRef.can_be_researched[i]

            LogService:Log("can_be_researched[" .. tostring(i) .. "] " .. tostring(can_be_researched))
        end
    end

    if ( researchSystemDataComponentRef.researching and researchSystemDataComponentRef.researching.count > 0 ) then

        for i=1,researchSystemDataComponentRef.researching.count do

            local researching = researchSystemDataComponentRef.researching[i]

            LogService:Log("researching[" .. tostring(i) .. "] " .. tostring(researching))
        end
    end

    if ( researchSystemDataComponentRef.new_researches and researchSystemDataComponentRef.new_researches.count > 0 ) then

        for i=1,researchSystemDataComponentRef.new_researches.count do

            local new_researches = researchSystemDataComponentRef.new_researches[i]

            LogService:Log("new_researches[" .. tostring(i) .. "] " .. tostring(new_researches))
        end
    end

    if ( researchSystemDataComponentRef.hilight_research and researchSystemDataComponentRef.hilight_research.count > 0 ) then

        for i=1,researchSystemDataComponentRef.hilight_research.count do

            local hilight_research = researchSystemDataComponentRef.hilight_research[i]

            LogService:Log("hilight_research[" .. tostring(i) .. "] " .. tostring(hilight_research))
        end
    end

end)