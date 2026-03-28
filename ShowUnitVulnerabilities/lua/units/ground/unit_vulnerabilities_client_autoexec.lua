if ( not is_client ) then
    return
end

require("lua/units/units_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

local FindMenuEntity = function(entity, menuBlueprintName)

    local children = EntityService:GetChildren( entity, true )

    for child in Iter(children) do
        local blueprintName = EntityService:GetBlueprintName( child )
        if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == entity ) then

            return child
        end
    end

    return nil
end

local GetGlobalMenuEntity = function(globalVulnerabilitiesMenuCache, blueprintName)

    local menuEntity = globalVulnerabilitiesMenuCache[blueprintName]

    if ( menuEntity == nil or menuEntity == INVALID_ID ) then
        return nil
    end

    if ( not EntityService:IsAlive( menuEntity ) ) then
        return nil
    end

    local parent = EntityService:GetParent( menuEntity )

    if ( parent == nil or parent == INVALID_ID ) then
        return nil
    end

    if ( not EntityService:IsAlive( parent ) ) then
        return nil
    end

    if ( EntityService:HasComponent(parent, "IsVisibleComponent") ) then
        return menuEntity
    end

    return nil
end

local SetMenuValues = function(menuEntity, vulnerabilities)

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB == nil ) then
        return
    end

    menuDB:SetInt("menu_visible", 1)

    local maxMenuDamageLines = 9

    for damageNumber=1,maxMenuDamageLines do

        local slotNumber = tostring(damageNumber)

        menuDB:SetInt("damage_visible_" .. slotNumber, 0)
        menuDB:SetString("damage_type_" .. slotNumber, "")
        menuDB:SetString("damage_name_" .. slotNumber, "")
    end

    local count = math.min(#vulnerabilities, maxMenuDamageLines)

    for damageNumber=1,count do

        local damage = vulnerabilities[damageNumber]

        local name = string.format("%d", damage.current_value * 100) .. "${gui/menu/inventory/units_percent}"

        local slotNumber = tostring(damageNumber)

        menuDB:SetInt("damage_visible_" .. slotNumber, 1)
        menuDB:SetString("damage_type_" .. slotNumber, damage.type)
        menuDB:SetString("damage_name_" .. slotNumber, name)
    end
end

local GetVulnerabilities = function(resistanceComponentRef)

    local result = {}

    local resistances = resistanceComponentRef.resistances

    for i=1,resistances.count do
        local item = resistances[i]

        if ( item.value.current_value ~= 1 ) then
            
            local damage = {}
            damage.type = item.key
            damage.current_value = item.value.current_value

            Insert(result, damage)
        end
    end

    local sorter = function( damage1, damage2 )

        if (damage1.current_value ~= damage2.current_value) then

            return damage1.current_value > damage2.current_value
        end

        return damage1.type:upper() < damage2.type:upper()
    end

    table.sort(result, sorter)
    
    return result
end

local GetResistanceToDamage = function(damageType, resistanceComponentRef)

    local resistances = resistanceComponentRef.resistances

    for i=1,resistances.count do
        local item = resistances[i]

        if ( item.key == damageType ) then
            return item.value.current_value
        end
    end
    
    return 1
end

local CreateVulnerabilitiesMenu = function(entity, blueprintName, vulnerabilities, menuBlueprintName)

    local team = EntityService:GetTeam( entity )
    local menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, entity, team)

    local sizeSelf = EntityService:GetBoundsSize( entity )

    local height = sizeSelf.y

    if ( string.find(blueprintName, "units/ground/spawner" ) == nil ) then
        height = math.min(height, 12) 
    end

    EntityService:SetPosition( menuEntity, 0, height, 0 )

    SetMenuValues(menuEntity, vulnerabilities)

    return menuEntity
end

local ShowVulnerabilitiesMenu = function(entity, ignoreOther)

    ignoreOther = ignoreOther or false

    local blueprintName = EntityService:GetBlueprintName( entity )

    -- Only on Units
    if ( string.find(blueprintName, "units/ground/" ) == nil ) then
        return 
    end

    if ( not EntityService:HasComponent(entity, "IsVisibleComponent") ) then
        return
    end

    local resistanceComponent = EntityService:GetComponent(entity, "ResistanceComponent")
    if ( resistanceComponent == nil ) then
        return
    end

    local resistanceComponentRef = reflection_helper(resistanceComponent)

    --local damageType = evt:GetDamageType()
    --
    --local currentResistance = GetResistanceToDamage(damageType, resistanceComponentRef)
    --if ( currentResistance > 1 ) then
    --	return
    --end

    globalVulnerabilitiesMenuCache = globalVulnerabilitiesMenuCache or {}

    local menuBlueprintName = "misc/unit_vulnerabilities_menu"

    local menuEntity = FindMenuEntity(entity, menuBlueprintName)

    local vulnerabilities = GetVulnerabilities(resistanceComponentRef)

    if ( menuEntity ~= nil ) then

        EntityService:CreateOrSetLifetime( menuEntity, 5.0, "normal" )

        SetMenuValues(menuEntity, vulnerabilities)

        if ( ignoreOther == false ) then

            globalVulnerabilitiesMenuCache[blueprintName] = menuEntity
        end

    else

        if ( ignoreOther == false ) then
            menuEntity = GetGlobalMenuEntity(globalVulnerabilitiesMenuCache, blueprintName)
        end

        if ( menuEntity == nil ) then

            menuEntity = CreateVulnerabilitiesMenu(entity, blueprintName, vulnerabilities, menuBlueprintName)

            if ( ignoreOther == false ) then
                globalVulnerabilitiesMenuCache[blueprintName] = menuEntity
            end
        end
    end
end



RegisterGlobalEventHandler("DamageEvent", function(evt)

    if ( not is_client ) then
        return
    end

    if not evt:GetDamageOverTime() then

        local owner = evt:GetOwner()
        if ( owner == nil or owner == INVALID_ID ) then
            return
        end

        local ownerBlueprintName = EntityService:GetBlueprintName( owner )
        if ( ownerBlueprintName ~= "player/character" ) then
            return
        end

        local entity = evt:GetEntity()

        ShowVulnerabilitiesMenu(entity, false)
    end
end)



RegisterGlobalEventHandler("DestroyRequest", function(evt)

    if ( not is_client ) then
        return
    end

    local entity = evt:GetEntity()

    local menuEntity = FindMenuEntity(entity, "misc/unit_vulnerabilities_menu")
    if ( menuEntity ~= nil ) then
        EntityService:CreateOrSetLifetime( menuEntity, 3, "normal" )
    end
end)



RegisterGlobalEventHandler("SelectEntityRequest", function(evt)

    if ( not is_client ) then
        return
    end

    local entity = evt:GetEntity()

    if ( entity == nil or entity == INVALID_ID ) then
        return
    end

    local entityBlueprintName = EntityService:GetBlueprintName( entity )

    local stringNumber = string.find( entityBlueprintName, "units/ground/" )

    if ( stringNumber ~= 1 ) then
        return
    end

    ShowVulnerabilitiesMenu(entity, true)

end)