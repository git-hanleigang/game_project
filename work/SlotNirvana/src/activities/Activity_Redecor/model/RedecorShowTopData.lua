-- 装修活动 排行榜数据管理类

local BaseActivityData = require("baseActivity.BaseActivityData")
local RedecorShowTopData = class("RedecorShowTopData", BaseActivityData)

function RedecorShowTopData:ctor()
    RedecorShowTopData.super.ctor(self)
    self.p_open = true
end

-- TODO 排行榜轮播图的显示逻辑需要处理
function RedecorShowTopData:checkOpenLevel()
    if not RedecorShowTopData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    return true
end

function RedecorShowTopData:getSysOpenLv()
    local lv = globalData.constantData.ACTIVITY_OPEN_LEVEL

    local actConfig = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.Redecor)
    if actConfig and actConfig.p_openLevel then
        lv = actConfig.p_openLevel
    end

    -- 该玩家 本活动是否忽略等级
    local bIgnoreActLv = globalData.constantData:checkIsIgnoreActLevel()
    if bIgnoreActLv and G_GetMgr(ACTIVITY_REF.Redecor):isRunning() then
        return 1
    end

    return lv
end

return RedecorShowTopData
