--[[
    排行榜段位列表信息
    author:徐袁
    time:2020-12-21 14:38:29
]]
local LeagueDivisionInfo = class("LeagueDivisionInfo")

function LeagueDivisionInfo:ctor()
    self.m_level = 0
    -- 商店加成
    self.m_storeCoinsFactor = nil
    -- cashBonus加成
    self.m_cashBonusFactor = nil
end

function LeagueDivisionInfo:parseData(data)
    if not data then
        return
    end

    self.m_level = data.level
    self.m_division = data.division
    -- 商店加成
    self.m_storeCoinsFactor = data.storeDiscount
    -- cashBonus加成
    self.m_cashBonusFactor = data.cashBonusDiscount
end

function LeagueDivisionInfo:getLv()
    return self.m_level
end

function LeagueDivisionInfo:getDivision()
    return self.m_division
end

function LeagueDivisionInfo:getCoinsFactor()
    return tonumber(self.m_storeCoinsFactor or 0)
end

function LeagueDivisionInfo:getCashBonusFactor()
    return tonumber(self.m_cashBonusFactor or 0)
end

return LeagueDivisionInfo
