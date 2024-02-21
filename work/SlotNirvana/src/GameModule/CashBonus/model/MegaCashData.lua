--[[--
    钞票小游戏数据结构解析
]]
local MegaCashData = class("MegaCashData")

function MegaCashData:parseData(netData)
    self.p_maxCoins = tonumber(netData.maxCoins)
    self.p_baseCoins = tonumber(netData.baseCoins)
    self.p_processCurrent = tonumber(netData.processCurrent)
    self.p_processAll = tonumber(netData.processAll)
    self.p_leftPlayTimes = tonumber(netData.leftPlayTimes)
    self.p_cashMultiply = netData.cashMultiply
    self.p_result = {}
    if netData.result and #netData.result > 0 then
        for i = 1, #netData.result do
            self.p_result[#self.p_result + 1] = netData.result[i]
        end
    end

    if netData.totalCoins then
        self.p_totalCoins = tonumber(netData.totalCoins)
    end
    if netData.vipMultiply then
        self.p_vipMultiply = netData.vipMultiply
    end
    if netData.extend and netData.extend.highLimit then
        globalData.syncDeluexeClubData(netData.extend.highLimit)
    end

    -- 关卡比赛加成
    self.m_arenaMultiple = tonumber(netData.arenaMultiple) or 0
end

function MegaCashData:setMegaCashTakeData(isClickTake)
    if isClickTake[1] == "isClickTake" then
        self.extra_isClickTake = isClickTake[2]
    end
end

function MegaCashData:getMegaCashTakeData()
    return self.extra_isClickTake
end

function MegaCashData:getCashBonusDis()
    local value = math.max(self.m_arenaMultiple or 0, 0)
    if value > 0 then
        return (value + 100) / 100
    else
        return 0
    end
end

--金库是否可以收集  钞票游戏
function MegaCashData:canCollect()
    if not self.p_processCurrent or not self.p_processAll then
        return false
    end

    if self.p_processCurrent == self.p_processAll then
        return true
    end
    return false
end

return MegaCashData
