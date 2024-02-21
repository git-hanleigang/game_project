--[[
    Lottery乐透
]]
local LotteryOpenSourceManager = class("LotteryOpenSourceManager", BaseActivityControl)

function LotteryOpenSourceManager:ctor()
    LotteryOpenSourceManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LotteryOpenSource)
end

-- 显示乐透来源弹板
function LotteryOpenSourceManager:popLotteryOpenSourceLayer()
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByExtendData("Activity_Lottery_Open_source") then
        return false
    end
    local view = util_createView("Activity.Activity_Lottery_Open_source")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return true
end


return LotteryOpenSourceManager
