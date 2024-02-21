--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:08
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 15:41:58
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftTaskUI.lua
Description: 次日礼物主界面 任务UI
--]]
local TomorrowGiftTaskUI = class("TomorrowGiftTaskUI", BaseView)

function TomorrowGiftTaskUI:getCsbName()
    return "Activity/TomorrowGift/csb/TomorrowGift_ExtraBonus.csb"
end

function TomorrowGiftTaskUI:initUI(_data, _unlockIdx)
    TomorrowGiftTaskUI.super.initUI(self)
    self.m_data = _data
    self.m_unlockIdx = _unlockIdx

    -- 当前spin的次数
    self:initCurSpinUI()
    -- 任务 信息
    self:initTaskUI()

    self:runCsbAction("idle", true)
end

-- 当前spin的次数
function TomorrowGiftTaskUI:initCurSpinUI()
    local lbSpinCount = self:findChild("lb_spin")
    local limitW = lbSpinCount:getContentSize().width
    local count =  self.m_data:getSpinTimes() 
    lbSpinCount:setString(count)
    util_scaleCoinLabGameLayerFromBgWidth(lbSpinCount, limitW, 1)
end

-- 任务 信息
function TomorrowGiftTaskUI:initTaskUI()
    local levelList = self.m_data:getLevelList() 
    for i=1, 5 do
        local node = self:findChild("node_arrow" .. i)
        local particle = self:findChild("ef_once_" .. i)
        if particle then
            particle:setVisible(false)
        end
        local levelData = levelList[i]
        self:updateTaskSingleInfoUI(levelData)
        node:setVisible(levelData ~= nil)
    end
end
function TomorrowGiftTaskUI:updateTaskSingleInfoUI(_levelData)
    if not _levelData then
        return
    end
    -- 达标的显示红色
    local idx = _levelData:getIdx()
    local spBlue = self:findChild("sp_arrowB".. idx)
    local spRed = self:findChild("sp_arrowR".. idx)
    spBlue:setVisible(idx ~= self.m_unlockIdx)
    spRed:setVisible(idx == self.m_unlockIdx)
    local spLock = self:findChild("sp_lock" .. idx)
    spLock:setVisible(idx ~= self.m_unlockIdx) --锁显示

    -- 奖励倍数
    local multiple = math.floor(_levelData:getMultiple() * 100)
    local lbMulti = self:findChild("lb_percent" .. idx)
    local limitMultipleW = lbMulti:getContentSize().width
    lbMulti:setString("" .. multiple .. "%")
    util_scaleCoinLabGameLayerFromBgWidth(lbMulti, limitMultipleW, 1)
    -- 任务spin 次数
    local spinCount = _levelData:getSpinCount()
    local lbCount = self:findChild("lb_count" .. idx)
    local limitCountW = lbCount:getContentSize().width
    lbCount:setString(spinCount)
    util_scaleCoinLabGameLayerFromBgWidth(lbCount, limitCountW, 1)
end

-- 活动 解锁的 任务UI 世界坐标
function TomorrowGiftTaskUI:getUnlockFlyPosW()
    local node = self:findChild("node_flyRef" .. self.m_unlockIdx)
    if not node then
        return
    end
    local particle = self:findChild("ef_once_" .. self.m_unlockIdx)
    if particle then
        particle:setVisible(true)
        particle:start()
    end
    return node:convertToWorldSpace(cc.p(0, 0))
end

return TomorrowGiftTaskUI