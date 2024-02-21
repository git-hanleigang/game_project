--浇花系统宣传图
local FlowerLoadingMgr = class("FlowerLoadingMgr", BaseActivityControl)

function FlowerLoadingMgr:ctor()
    FlowerLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FlowerLoading)
end

return FlowerLoadingMgr
