--浇花系统宣传图
local LegendaryWinMgr = class("LegendaryWinMgr", BaseActivityControl)

function LegendaryWinMgr:ctor()
    LegendaryWinMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LegendaryWin)
end

return LegendaryWinMgr
