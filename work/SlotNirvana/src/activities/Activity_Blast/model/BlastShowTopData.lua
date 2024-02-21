
-- blast 排行榜数据类

local BaseActivityData = require("baseActivity.BaseActivityData")
local BlastShowTopData = class("BlastShowTopData", BaseActivityData)

function BlastShowTopData:ctor()
    BlastShowTopData.super.ctor(self)
    self.p_open = true
end

-- TODO 排行榜轮播图的显示逻辑需要处理 
function BlastShowTopData:checkOpenLevel()
    if not BaseActivityData.checkOpenLevel(self) then
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

return BlastShowTopData
