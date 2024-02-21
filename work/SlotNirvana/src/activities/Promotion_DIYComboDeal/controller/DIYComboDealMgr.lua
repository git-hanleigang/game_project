
local DIYComboDealMgr = class("DIYComboDealMgr", BaseActivityControl)

function DIYComboDealMgr:ctor()
    DIYComboDealMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DIYComboDeal)
end

function DIYComboDealMgr:getPopPath(popName)
    return "Promotion_DIYComboDeal/" .. popName
end

return DIYComboDealMgr
