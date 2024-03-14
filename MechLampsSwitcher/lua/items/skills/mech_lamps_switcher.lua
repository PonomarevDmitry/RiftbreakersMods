local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'mech_lamps_switcher' ( item )

function mech_lamps_switcher:__init()
    item.__init(self,self)
end

function mech_lamps_switcher:OnEquipped()
end

function mech_lamps_switcher:OnActivate()

    if ( self.owner == nil or self.owner == INVALID_ID ) then
        return
    end
    if ( EffectService:HasEffectByGroup(self.owner, "sunset_night_sunrise") ) then

        EffectService:DestroyEffectsByGroup(self.owner, "sunset_night_sunrise")
    else

        EffectService:AttachEffects(self.owner, "sunset_night_sunrise")
    end
end

function mech_lamps_switcher:OnDeactivate()
    return true
end

return mech_lamps_switcher