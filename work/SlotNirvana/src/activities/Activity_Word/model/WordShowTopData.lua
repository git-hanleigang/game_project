-- word活动 排行榜数据管理类

local BaseActivityData = require("baseActivity.BaseActivityData")
local WordShowTopData = class("WordShowTopData", BaseActivityData)

function WordShowTopData:ctor()
    WordShowTopData.super.ctor(self)
    self.p_open = true
end

-- TODO 排行榜轮播图的显示逻辑需要处理
function WordShowTopData:checkOpenLevel()
    if not WordShowTopData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    local needLevel = globalData.constantData.ACTIVITY_OPEN_LEVEL or 20
    if needLevel > curLevel then
        return false
    end

    return true
end

return WordShowTopData
