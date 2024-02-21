--[[
Author: cxc
Date: 2022-01-10 16:46:31
LastEditTime: 2022-01-10 16:47:01
LastEditors: your name
Description: Lottery乐透 挑战活动 任务cell基类
FilePath: /SlotNirvana/src/activities/Activity_LotteryChallenge/base/LotteryChallengeBaseTaskCell.lua
--]]
local LotteryChallengeBaseTaskCell = class("LotteryChallengeBaseTaskCell", BaseView)

function LotteryChallengeBaseTaskCell:ctor(_taskCur, _taskData)
    LotteryChallengeBaseTaskCell.super.ctor(self)

    self.m_taskCur = _taskCur or 0 -- 当前完成的任务数
    self.m_taskData = _taskData
    self.m_taskRewardCoins = 0
end

function LotteryChallengeBaseTaskCell:getCsbName()
    return ""
end

function LotteryChallengeBaseTaskCell:initCsbNodes()
    self.m_lbTaskProg = self:findChild("lb_task") -- 任务进度
    -- self.m_lbCoinsNoraml = self:findChild("lb_coinNoraml") -- 金币lb
    -- self.m_lbCoinsCollect = self:findChild("lb_coinCollect") -- 金币lb
    self.m_nodeItems = self:findChild("node_items")
end

function LotteryChallengeBaseTaskCell:initUI()
    LotteryChallengeBaseTaskCell.super.initUI(self)

    -- 任务进度
    local taskNeed = self.m_taskData:getTaskNeed()
    if self.m_lbTaskProg then
        self.m_lbTaskProg:setString(self.m_taskCur .. "/" .. taskNeed)
    end

    -- -- 金币奖励
    -- self.m_taskRewardCoins = self.m_taskData:getRewardCoins() 
    -- if self.m_lbCoinsNoraml and self.m_lbCoinsCollect then
    --     self.m_lbCoinsNoraml:setString(self.m_taskRewardCoins)
    --     self.m_lbCoinsCollect:setString(self.m_taskRewardCoins)
    -- end

    -- 奖励道具
    local itemDataList = self.m_taskData:getRewardItems()
    local designW = 90
    local defaultW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local shopItemUI = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.TOP, designW/defaultW, designW)
    self.m_nodeItems:addChild(shopItemUI)

    -- 动效
    local bCollected = self.m_taskData:isCollected() 
    local actName = "idle1"
    if self.m_taskCur >= taskNeed then
        actName = bCollected and "idle3" or "idle1"
    end
    self:runCsbAction(actName, true)
end

-- 播放完成未领奖 特效
function LotteryChallengeBaseTaskCell:playUnCollectedAct()
    self:runCsbAction("openlock", false, function()
        self:runCsbAction("idle2", true)
    end)
end

function LotteryChallengeBaseTaskCell:collectedSuccessEvt(_collectCoins)
    _collectCoins = _collectCoins or 0

    self:runCsbAction("dagou", false, function()
        self:runCsbAction("idle3", true)

        self:flyCoins(_collectCoins)
    end, 60)

end

function LotteryChallengeBaseTaskCell:flyCoins(_coins)
    if not _coins or _coins <= 0 then
        return
    end
    
    local endPos = globalData.flyCoinsEndPos
    local btnCollect =  self:findChild("sp_coinCollect") or self
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local baseCoins = globalData.topUICoinCount 
    gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,_coins)
end

return LotteryChallengeBaseTaskCell