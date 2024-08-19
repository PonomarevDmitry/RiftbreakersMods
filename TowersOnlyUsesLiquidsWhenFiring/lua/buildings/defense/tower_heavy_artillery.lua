local tower = require("lua/buildings/defense/tower.lua")
require("lua/utils/table_utils.lua")

class 'tower_heavy_artillery' ( tower )

function tower_heavy_artillery:__init()
    tower.__init(self,self)
end

function tower_heavy_artillery:OnInit()
    tower.OnInit(self)

    self:RegisterHandler( self.entity, "TurretEvent", "OnTurretEvent" )

    self:ChangeWorkingCoefficient()
end

function tower_heavy_artillery:OnLoad()

    if ( tower.OnLoad ) then
        tower.OnLoad(self)
    end

    self:RegisterHandler( self.entity, "TurretEvent", "OnTurretEvent" )

    self:ChangeWorkingCoefficient()
end

function tower_heavy_artillery:OnActivate()

    if ( tower.OnActivate ) then
        tower.OnActivate(self)
    end

    self:ChangeWorkingCoefficient()
end

function tower_heavy_artillery:OnDeactivate()

    if ( tower.OnDeactivate ) then
        tower.OnDeactivate(self)
    end

    self:ChangeWorkingCoefficient()
end

function tower_heavy_artillery:OnBuildingEnd()

    if ( tower.OnBuildingEnd ) then
        tower.OnBuildingEnd(self)
    end

    self:ChangeWorkingCoefficient()
end

function tower_heavy_artillery:OnTurretEvent( evt )

    if( evt:GetTurretEntity() ~= self.entity ) then
        Assert(false,"ERROR: invalid turret event")
        return
    end

    self:ChangeWorkingCoefficient()
end

function tower_heavy_artillery:ChangeWorkingCoefficient()

    local targetEnt = WeaponService:GetTurretTarget( self.entity )
    if ( targetEnt ~= INVALID_ID ) then
        BuildingService:AddConverterCostModifier( self.entity, 1, "working_coefficient" )
    else
        BuildingService:AddConverterCostModifier( self.entity, 0.004, "working_coefficient" )
    end
end

return tower_heavy_artillery
