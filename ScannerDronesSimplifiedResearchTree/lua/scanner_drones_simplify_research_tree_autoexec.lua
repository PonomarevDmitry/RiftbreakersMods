require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local supported_research_list = {

    {
        ["name"] = "gui/menu/research/name/scanner_equipment_standard",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_standard",
    },

    {
        ["name"] = "gui/menu/research/name/scanner_equipment_advanced",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_advanced",
    },

    {
        ["name"] = "gui/menu/research/name/scanner_equipment_superior",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_superior",
    },

    {
        ["name"] = "gui/menu/research/name/scanner_equipment_extreme",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_extreme ",
    },

    

    {
        ["name"] = "gui/menu/research/name/detector_equipment_standard",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_standard",
    },

    {
        ["name"] = "gui/menu/research/name/detector_equipment_advanced",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_advanced",
    },

    {
        ["name"] = "gui/menu/research/name/detector_equipment_superior",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_superior",
    },

    {
        ["name"] = "gui/menu/research/name/detector_equipment_extreme",
        ["remove"] = "gui/menu/research/name/mech_upgrade_combat_drones_extreme ",
    },
}

local scanner_drones_simplify_research_tree_autoexec = function()

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )
    if ( researchComponent == nil ) then
        return
    end


    

    local researchComponentRef = reflection_helper( researchComponent )

    local hashResearching = {}
    local hashResearched = {}
    local hashCanBeResearched = {}
    local hashCanBeTestedForResearched = {}

    if ( researchComponentRef.researching ) then

        for i=1,researchComponentRef.researching.count do

            local tempName = researchComponentRef.researching[i]

            if ( tempName ~= "" ) then

                hashResearching[tempName] = true
            end
        end
    end
    

    if ( researchComponentRef.researched ) then

        for i=1,researchComponentRef.researched.count do

            local tempName = researchComponentRef.researched[i]

            if ( tempName ~= "" ) then

                hashResearched[tempName] = true
            end
        end
    end
    

    if ( researchComponentRef.can_be_researched ) then

        for i=1,researchComponentRef.can_be_researched.count do

            local tempName = researchComponentRef.can_be_researched[i]

            if ( tempName ~= "" ) then

                hashCanBeResearched[tempName] = true
            end
        end
    end
    

    if ( researchComponentRef.can_be_tested_for_researched ) then
    
        for i=1,researchComponentRef.can_be_tested_for_researched.count do
    
            local tempName = researchComponentRef.can_be_tested_for_researched[i]
    
            if ( tempName ~= "" and tempName.hash and tempName.hash ~= "" ) then
    
                hashCanBeTestedForResearched[tempName] = true
            end
        end
    end

    local IsRequiredResearched = function( node )

        local requirements = node.requirements

        for k=1,requirements.count do

            local requirement = requirements[k]

            local nameHash = CalcHash(requirement.research_name)

            if ( hashResearched[nameHash] == nil ) then
                return false
            end
        end

        return true
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

        local nameHash = CalcHash(name)

        if ( hashCanBeTestedForResearched[nameHash] == true ) then
            return true
        end

        return false
    end





    local targetCategory = "gui/menu/research/category_scanner_drones"

    local listChangedResearchs = {}

    local categoryContainer = researchComponent:GetField("research"):ToContainer()

    local canBeTestedContainer = researchQueueComponent:GetField("can_be_tested_for_researched"):ToContainer()



    for i=0,categoryContainer:GetItemCount()-1 do

        local category = categoryContainer:GetItem(i)

        local categoryName = category:GetField("category"):GetValue()
            
        if ( categoryName == targetCategory ) then

            local nodesContainer = category:GetField("nodes"):ToContainer()

            for i=0,nodesContainer:GetItemCount()-1 do

                local node = nodesContainer:GetItem(i)

                local researchName = node:GetField("research_name"):GetValue()
            
                for _, item in ipairs(supported_research_list) do

                    if ( researchName == item.name ) then

                        local researchChanged = false

                        local requirementsContainer = node:GetField("requirements"):ToContainer()

                        for i=0,requirementsContainer:GetItemCount()-1 do

                            local requirement = requirementsContainer:GetItem(i)

                            local requirementResearchName = requirement:GetField("research_name"):GetValue()

                            if ( requirementResearchName == item.remove ) then

                                LogService:Log("Removing  item.remove" .. item.remove .. " from " .. item.name )

                                requirementsContainer:EraseItem( i )

                                break
                            end
                        end

                        if ( researchChanged ) then

                            if ( not IsReseachInSomeList( researchName ) ) then

                                if ( IsRequiredResearched( reflection_helper(node) ) ) then

                                    --LogService:Log("Adding to can_be_tested_for_researched " .. researchName )
                                    --
                                    --local newStringHash = canBeTestedContainer:CreateItem()
                                    --
                                    --newStringHash:GetField("hash"):SetValue(tostring(CalcHash(researchName)))
                                end
                            end
                        end

                        break
                    end
                end
            end
        end
    end
    
    --LogService:Log(tostring("researching " .. tostring(researchComponentRef.researching)))
    --LogService:Log(tostring("researched " .. tostring(researchComponentRef.researched)))
    --LogService:Log(tostring("can_be_researched " .. tostring(researchComponentRef.can_be_researched)))
    --LogService:Log(tostring("can_be_tested_for_researched " .. tostring(researchComponentRef.can_be_tested_for_researched)))
end

--RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
--
--    scanner_drones_simplify_research_tree_autoexec()
--end)
--
--RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)
--
--    scanner_drones_simplify_research_tree_autoexec()
--end)
--
--RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)
--
--    scanner_drones_simplify_research_tree_autoexec()
--end)