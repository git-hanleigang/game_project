--浇花系统宣传图
local LuckyV2LoadingMgr = class("LuckyV2LoadingMgr", BaseActivityControl)

function LuckyV2LoadingMgr:ctor()
    LuckyV2LoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckyV2Loading)
end

function LuckyV2LoadingMgr:getPopPath(popName)
    return "Activity_LuckySpin_Loading/Activity/" .. popName
end

return LuckyV2LoadingMgr
