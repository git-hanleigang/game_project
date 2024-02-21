--浇花系统宣传图
local BlastBombMgr = class("BlastBombMgr", BaseActivityControl)

function BlastBombMgr:ctor()
    BlastBombMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BlastBombLoading)
end

return BlastBombMgr
