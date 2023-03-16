require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local Research = {}

function Research:FindResearchNodesWithBlueprintAward( blueprint_name )
    local nodes = {}

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )
    local categories = researchComponent.research
    for i=1,categories.count do
        local category = categories[i]
        local category_nodes = category.nodes
        for j=1,category_nodes.count do
            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do
                local award = awards[k]
                if award.blueprint == blueprint_name then
                    Insert( nodes, node.research_name )
                end
            end
        end
    end

    return nodes
end

function Research:FindChildNodesWithFlag(research_name, flag)
    local nodes = {}

    local IsNodeDependantOnMe = function( node )
        local requirements = node.requirements
        for i=1,requirements.count do
            local requirement = requirements[i]
            if requirement.research_name == research_name then
                return true
            end
        end

        return false
    end

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )
    local categories = researchComponent.research
    for i=1,categories.count do
        local category = categories[i]
        local category_nodes = category.nodes
        for j=1,category_nodes.count do
            local node = category_nodes[j]

            local is_valid = flag ~= 0 or bit.band( node.research_flags, flag ) == flag;
            if is_valid and IsNodeDependantOnMe( node ) then
                Insert( nodes, node.research_name )
            end
        end
    end

    return nodes
end

function Research:IsResearching( researchComponentRef, researchName )

    for i=1,researchComponentRef.researching.count do

        local researchingName = researchComponentRef.researching[i]

        if ( researchingName ~= "" and researchingName == researchName ) then

            return true
        end
    end

    return false
end

function Research:IsResearched( researchComponentRef, researchName )

    for i=1,researchComponentRef.researched.count do

        local researchedName = researchComponentRef.researched[i]

        if ( researchedName ~= "" and researchedName == researchName ) then

            return true
        end
    end

    return false
end

function Research:CanBeResearched( researchComponentRef, researchName )

    for i=1,researchComponentRef.can_be_researched.count do

        local researchingName = researchComponentRef.can_be_researched[i]

        if ( researchingName ~= "" and researchingName == researchName ) then

            return true
        end
    end

    return false
end

function Research:CanBeTestedForResearched( researchComponentRef, researchName )

    for i=1,researchComponentRef.can_be_tested_for_researched.count do

        local researchingName = researchComponentRef.can_be_tested_for_researched[i]

        if ( researchingName ~= "" and researchingName == researchName ) then

            return true
        end
    end

    return false
end

function Research:AddToCanBeTestedForResearchArray( researchNameArray )

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )

    local researchComponentRef = reflection_helper( researchComponent )

    for i=1,#researchNameArray do

        local researchName = researchNameArray[i]

        Research:AddToCanBeTestedForResearchComp( researchName, researchComponent, researchComponentRef )
    end
end

function Research:AddToCanBeTestedForResearch( researchName )

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )

    local researchComponentRef = reflection_helper( researchComponent )

    Research:AddToCanBeTestedForResearchComp( researchName, researchComponent, researchComponentRef )
end

function Research:AddToCanBeTestedForResearchComp( researchName, researchComponent, researchComponentRef )

    local isResearching = Research:IsResearching( researchComponentRef, researchName )
    if ( isResearching ) then
        return
    end

    local isResearched = Research:IsResearched( researchComponentRef, researchName )
    if ( isResearched ) then
        return
    end

    local canBeResearched = Research:CanBeResearched( researchComponentRef, researchName )
    if ( canBeResearched ) then
        return
    end

    local canBeTestedForResearched = Research:CanBeTestedForResearched( researchComponentRef, researchName )
    if ( canBeTestedForResearched ) then
        return
    end

    local canBeTestedContainer = researchComponent:GetField("can_be_tested_for_researched"):ToContainer()

    local item = canBeTestedContainer:CreateItem()

    item:SetValue(researchName)
end

function Research:CheckResearches()

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )
    local researchComponentRef = reflection_helper( researchComponent )

    local hashResearching = {}
    local hashResearched = {}
    local hashCanBeResearched = {}
    local hashCanBeTestedForResearched = {}

    for i=1,researchComponentRef.researching.count do

        local tempName = researchComponentRef.researching[i]

        if ( tempName ~= "" ) then

            hashResearching[tempName] = true
        end
    end

    for i=1,researchComponentRef.researched.count do

        local tempName = researchComponentRef.researched[i]

        if ( tempName ~= "" ) then

            hashResearched[tempName] = true
        end
    end

    for i=1,researchComponentRef.can_be_researched.count do

        local tempName = researchComponentRef.can_be_researched[i]

        if ( tempName ~= "" ) then

            hashCanBeResearched[tempName] = true
        end
    end

    for i=1,researchComponentRef.can_be_tested_for_researched.count do

        local tempName = researchComponentRef.can_be_tested_for_researched[i]

        if ( tempName ~= "" ) then

            hashCanBeTestedForResearched[tempName] = true
        end
    end

    local IsReseachInSomeList = function( name )

        if ( hashResearching[name] == true ) then
            return true
        end

        if ( hashResearched[name] == true ) then
            return true
        end

        if ( hashCanBeResearched[name] == true ) then
            return true
        end

        if ( hashCanBeTestedForResearched[name] == true ) then
            return true
        end

        return false
    end

    local IsRequiredResearched = function( node )

        local requirements = node.requirements

        for k=1,requirements.count do

            local requirement = requirements[k]

            if ( hashResearched[requirement.research_name] == nil ) then
                return false
            end
        end

        return true
    end

    local canBeTestedContainer = researchComponent:GetField("can_be_tested_for_researched"):ToContainer()

    local categories = researchComponentRef.research

    for i=1,categories.count do

        local category = categories[i]

        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            if ( not IsReseachInSomeList( node.research_name ) ) then

                if ( IsRequiredResearched( node ) ) then

                    --LogService:Log("Adding to can_be_tested_for_researched " .. node.research_name )

                    local item = canBeTestedContainer:CreateItem()

                    item:SetValue(node.research_name)
                end
            end
        end
    end
end

return Research;