--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-22 17:39:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-22 17:41:51
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/model/PiggyClickerCalcData.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-13 11:44:18
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-13 11:44:42
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/model/PiggyClickerCalcData.lua
Description: 快速点击小游戏 计算系数数据
--]]
local PiggyClickerCalcData = class("PiggyClickerCalcData")

function PiggyClickerCalcData:ctor()
    self.m_bPay = false
    self.m_coeList = {} -- 各种计算系数集合
    self.m_coeIntervalList = {}
    self.m_freeCoinsMultiply = 0  -- 免费计算金币的值
    self.m_freeGemMultiply = 0  -- 免费计算宝石的值
    self.m_payCoinsMultiply = 0  -- 付费计算宝石的值
    self.m_payGemMultiply = 0  -- 付费计算宝石的值
end

-- local calcInfo = {
    -- clickInterval       = _data.clickInterval or 0, --点击间隔
    --     coeList             = _data.coe or {}, -- 各种计算系数集合
--     freeCoinsMultiply   = tonumber(_data.freeCoinsMultiply) or 0, -- 免费计算金币的值
--     freeGemMultiply     = tonumber(_data.freeGemMultiply) or 0, -- 免费计算宝石的值
--     payCoinsMultiply    = tonumber(_data.payCoinsMultiply) or 0, -- 付费计算宝石的值
--     payGemMultiply      = tonumber(_data.payGemMultiply) or 0, -- 付费计算宝石的值
-- }
function PiggyClickerCalcData:parseData(_data, _bPay)
    self.m_bPay = _bPay
    self:parseCoeData(_data.coeList, _data.clickInterval)
    self.m_freeCoinsMultiply = _data.freeCoinsMultiply  -- 免费计算金币的值
    self.m_freeGemMultiply = _data.freeGemMultiply  -- 免费计算宝石的值
    self.m_payCoinsMultiply = _data.payCoinsMultiply  -- 付费计算宝石的值
    self.m_payGemMultiply = _data.payGemMultiply  -- 付费计算宝石的值
end

-- 解析各种计算系数集合
function PiggyClickerCalcData:parseCoeData(_list, _clickInterval)
    self.m_coeList = {}
    self.m_coeIntervalList = {}
    for _, _data in ipairs(_list) do
        local info = {}
        info.m_intervalTime = ((_data.interval or 0) - 1) * _clickInterval-- 间隔
        info.m_coeA = tonumber(_data.coeA) or 0 -- 计算系数A
        info.m_coeB = tonumber(_data.coeB) or 0 -- 计算系数B
        info.m_coinsCoe = tonumber(_data.coinsCoe) or 0 -- 金币奖励计算系数
        info.m_gemsCoe = tonumber(_data.gemsCoe) or 0 -- 宝石奖励计算系数    
        table.insert(self.m_coeList, info)
        table.insert(self.m_coeIntervalList, info.m_intervalTime)
    end
end

-- 各种计算系数集合
function PiggyClickerCalcData:getCoeList()
    return self.m_coeList
end
function PiggyClickerCalcData:getCoeInfo(_interval)
    local info = {} 
    local interval = 0
    for i=#self.m_coeList, 1, -1 do
        info = self.m_coeList[i]
        if _interval >= info.m_intervalTime then
            break
        end
    end
    
    return info
end

-- 获取间隔时间 列表
function PiggyClickerCalcData:getCoeIntervalList()
    return self.m_coeIntervalList
end

-- 计算本次点击 掉落货币
function PiggyClickerCalcData:calcHitDropValue(_hitCount, _interval)
    local coeInfo = self:getCoeInfo(_interval)
    if not next(coeInfo) then
        return util_random(0,1), 0
    end

    -- reward_usd = b/(hitCount+a)^2
    local rewardUsd = tonumber(string.format("%.5f", coeInfo.m_coeB / math.pow(_hitCount + coeInfo.m_coeA, 2)))

    local coinsMul = self.m_bPay and self.m_payCoinsMultiply or self.m_freeCoinsMultiply
    local dropCoins = rewardUsd * coeInfo.m_coinsCoe * coinsMul

    local gemsMul = self.m_bPay and self.m_payGemMultiply or self.m_freeGemMultiply
    local dropGems = rewardUsd * coeInfo.m_gemsCoe * gemsMul

    -- print("cxc_coe_", coeInfo.m_coeA, coeInfo.m_coeB, coeInfo.m_coinsCoe, coeInfo.m_gemsCoe, coinsMul, gemsMul)
    return dropCoins, dropGems
end

return PiggyClickerCalcData