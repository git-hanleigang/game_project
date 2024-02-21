-- 排行榜数据

local BaseActivityData = require("baseActivity.BaseActivityData")
local PokerShowTopData = class("PokerShowTopData", BaseActivityData)

function PokerShowTopData:ctor()
    PokerShowTopData.super.ctor(self)
    self.p_open = true
end

function PokerShowTopData:parseData(_data)
    PokerShowTopData.super.parseData(self, _data)
end

function PokerShowTopData:checkOpenLevel()
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

return PokerShowTopData
