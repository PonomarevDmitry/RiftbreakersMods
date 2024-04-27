local building = require("lua/buildings/building.lua")
require("lua/utils/reflection.lua")
require("lua/utils/string_utils.lua")

class 'mass_disassembly' ( building )

function mass_disassembly:__init()
    building.__init(self,self)
end

function mass_disassembly:OnInit()

    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end

function mass_disassembly:OnInteractWithEntityRequest( event )

    local player = event:GetOwner()

    local hashItems,hasItems = self:GetModsToDisassebly()
    if ( hasItems == false ) then
        return
    end


    local inventoryComponent = EntityService:GetComponent(player, "InventoryComponent")
    if ( inventoryComponent == nil ) then
        return
    end

    local inventoryComponentRef = reflection_helper( inventoryComponent )

    while ( inventoryComponentRef.reference_entity ~= nil and inventoryComponentRef.reference_entity.id ~= INVALID_ID ) do

        inventoryComponent = EntityService:GetComponent(inventoryComponentRef.reference_entity.id, "InventoryComponent")

        if ( inventoryComponent == nil ) then
            inventoryComponentRef = nil
            break
        end

        inventoryComponentRef = reflection_helper( inventoryComponent )
    end

    if ( inventoryComponentRef == nil or inventoryComponentRef.inventory == nil or inventoryComponentRef.inventory.items == nil ) then
        return
    end



    local inventoryItems = inventoryComponentRef.inventory.items

    for itemNumber=1,inventoryItems.count do

        local itemEntity = inventoryItems[itemNumber]

        if ( itemEntity == nil or itemEntity.id == nil) then
            goto continue
        end

        if ( not EntityService:IsAlive( itemEntity.id )) then
            goto continue
        end

        local itemBlueprintName = EntityService:GetBlueprintName(itemEntity.id)
        if ( hashItems[itemBlueprintName] == nil ) then
            goto continue
        end

        if ( IndexOf( hashItems[itemBlueprintName], itemEntity.id ) ~= nil ) then
            goto continue
        end

        Insert(hashItems[itemBlueprintName], itemEntity.id)

        ::continue::
    end

    local resourcesValues = {}

    for itemBlueprintName, itemList in pairs( hashItems ) do

        local blueprint = ResourceManager:GetBlueprint( itemBlueprintName )
        if ( blueprint ~= nil ) then

            local costDesc = blueprint:GetComponent("CostDesc")
            if ( costDesc ~= nil ) then

                local costDescRef = reflection_helper(costDesc)
                if ( costDescRef ~= nil and costDescRef.account ~= nil ) then

                    local account = costDescRef.account

                    if ( account.count > 0 ) then

                        for i = 1,account.count do

                            local researchCost = account[i]

                            if ( researchCost ~= nil and researchCost.resource ~= nil and researchCost.resource ~= "" and researchCost.count ~= nil and researchCost.count > 0 ) then

                                local sum = (researchCost.count / 2) * #itemList

                                resourcesValues[researchCost.resource] = resourcesValues[researchCost.resource] or 0

                                resourcesValues[researchCost.resource] = resourcesValues[researchCost.resource] + sum
                            end
                        end
                    end
                end
            end
        end

        for itemEntity in Iter(itemList) do
            EntityService:RemoveEntity( itemEntity )
        end
    end

    for resource, sum in pairs( resourcesValues ) do

        PlayerService:AddResourceAmount( resource, sum )
    end

    EffectService:SpawnEffect(self.entity, "effects/enemies_lesigian/lightning_explosion")
end

function mass_disassembly:GetModsToDisassebly()

    local hasItems = false
    local hashItems = {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local blueprintName = EntityService:GetBlueprintName(modItem)

                hashItems[blueprintName] = hashItems[blueprintName] or {}

                hasItems = true

                Insert(hashItems[blueprintName], modItem)

                QueueEvent( "EquipmentChangeRequest", self.entity, slot.name, 0, INVALID_ID )
            end
        end
    end

    return hashItems, hasItems
end

return mass_disassembly