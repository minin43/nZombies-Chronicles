-- File created by Ethorbit because TFA updates fuck with nZombies

-- They clearly don't test wether or not their own compatibility works
-- so here, I'll do it for them.
local SWEP = FindMetaTable("Weapon")

-- This is Old TFA's version of ClearStatCache,

-- I'm adding this because everybody calls this function
-- in their OnPaP weapons and New TFA has made it problematic
-- for that.
function SWEP:ClearStatCache(vn)
    if !self.StatCache or !self.StatCache2 then return end -- Just in case another update..

    if vn then
        self.StatCache[vn] = nil
        self.StatCache2[vn] = nil
    else
        table.Empty(self.StatCache)
        table.Empty(self.StatCache2)
    end
end
