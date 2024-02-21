--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:08
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:21:19
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/model/TomorrowGiftData.lua
Description: 次日礼物 数据
--]]
local TomorrowGiftLevel = class("TomorrowGiftLevel")
function TomorrowGiftLevel:ctor(_levelData, _idx)
    self.m_idx = _idx
    self.m_multiple = tonumber(_levelData.multiple) or 0 --奖励倍数
    self.m_spinCount = _levelData.spin or 0  --Spin次数
end

function TomorrowGiftLevel:getIdx()
    return self.m_idx
end
function TomorrowGiftLevel:getMultiple()
    return self.m_multiple
end
function TomorrowGiftLevel:getSpinCount()
    return self.m_spinCount
end


local BaseGameModel = util_require("GameBase.BaseGameModel")
local TomorrowGiftData = class("TomorrowGiftData", BaseGameModel)

function TomorrowGiftData:parseData(_data)
    if not _data then
        return
    end

    self.m_open = true
    self.m_collectMills = tonumber(_data.collectMills) or 0 --可以领取奖励的时间倒计时
    self.m_collectAt = tonumber(_data.collectAt) or 0  --可以领取奖励的时间
    self.m_baseCoins = tonumber(_data.coins) or 0  --奖励金币
    self.m_spinTimes = _data.spinTimes or 0  --积累Spin次数

    -- 奖励等级
    self:parseLevelData(_data.levels or {})
end

function TomorrowGiftData:parseLevelData(_list)
    self.m_levelList = {}
    local totalCount = #_list
    for _idx = 1, #_list do
        local levelData = _list[_idx]
        local idx = totalCount - _idx + 1
        local data = TomorrowGiftLevel:create(levelData, idx)
        self.m_levelList[idx] = data
    end
end

function TomorrowGiftData:getUnlockTime()
    return math.floor((self.m_collectAt or 0) * 0.001)
end
function TomorrowGiftData:getCoins()
    return self.m_baseCoins or 0
end
function TomorrowGiftData:getSpinTimes()
    return self.m_spinTimes or 0
end
function TomorrowGiftData:getLevelList()
    return self.m_levelList or {}
end

function TomorrowGiftData:isRunning()
    return self.m_open and not self.p_isCompleted
end

function TomorrowGiftData:updateSpinGiftData(_data)
    self.m_baseCoins = tonumber(_data.coins) or 0  --奖励金币
    self.m_spinTimes = _data.spinTimes or 0  --积累Spin次数
end

-- 解锁档位 idx
function TomorrowGiftData:getUnlockLevelData()
    local levelData
    local levelList = self:getLevelList()
    local curSpinTimes = self:getSpinTimes()
    for i=1, #levelList do
        local data = levelList[i]
        local spinCount = data:getSpinCount()
        if curSpinTimes >= spinCount then
            levelData = data
            break
        end
    end

    return levelData
end

function TomorrowGiftData:checkIsUnlock()
    local unlockTIme = self:getUnlockTime()
    return unlockTIme <= util_getCurrnetTime()
end

return TomorrowGiftData