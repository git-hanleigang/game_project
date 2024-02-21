--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-10-17 16:43:05
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local CardObsidianJackpotData = class("CardObsidianJackpotData", BaseActivityData)

-- configData.p_multiple = tonumber(_jpData[2]) --jackpot倍率
-- configData.p_initMin = tonumber(_jpData[3]) --初始最小值
-- configData.p_initMax = tonumber(_jpData[4]) --初始最大值
-- configData.p_increase = tonumber(_jpData[5]) --增加值
-- configData.p_resetMin = tonumber(_jpData[6]) --重置最小值
-- configData.p_resetMax = tonumber(_jpData[7]) --重置最大值
-- configData.p_resetTime = tonumber(_jpData[8]) --重置参考时间

function CardObsidianJackpotData:ctor()
    CardObsidianJackpotData.super.ctor(self)
    self.p_open = true
    self.m_isInitValue = false
    self.m_initAt = 0
    self.m_frameAddValue = 0
    self.m_initMinValue = 0
end

function CardObsidianJackpotData:parseData(_netData)
    CardObsidianJackpotData.super.parseData(self, _netData)
    self.p_jackpotCoins = _netData.jackpotCoins

    if self.m_isInitValue == false then
        self.m_isInitValue = true
        self:initValue()
    end
end

function CardObsidianJackpotData:initValue()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    self.m_initAt = curTime

    self.m_frameAddValue = self.p_jackpotCoins * (0.000001 * math.random(1, 4))

    self.m_initMinValue = self.p_jackpotCoins
end

function CardObsidianJackpotData:getTotalTimeFromStart()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local totolTime = curTime - self.m_initAt
    return totolTime
end

function CardObsidianJackpotData:getJackpotValue()
    local totalTime = self:getTotalTimeFromStart()
    local nowValue = self.m_initMinValue + totalTime*self.m_frameAddValue
    return nowValue
end

return CardObsidianJackpotData