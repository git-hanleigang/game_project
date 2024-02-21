--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:29:25
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/tournament/TrillionChallengeBubbleUI.lua
Description: 亿万赢钱挑战 任务宝箱 气泡
--]]
local TrillionChallengeBubbleUI = class("TrillionChallengeBubbleUI", BaseView)
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")

function TrillionChallengeBubbleUI:initDatas(_idx, _itemList) 
    TrillionChallengeBubbleUI.super.initDatas(self)

    self._itemList = _itemList or {}
    self._idx = _idx
end

function TrillionChallengeBubbleUI:getCsbName()
    return "Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main_tip.csb"
end

function TrillionChallengeBubbleUI:initUI() 
    TrillionChallengeBubbleUI.super.initUI(self)

    -- 奖励道具
    self:updateItemUI()
    self:setVisible(false)
end

-- 奖励道具
function TrillionChallengeBubbleUI:updateItemUI()
    local parent = self:findChild("node_item")
    local node = gLobalItemManager:addPropNodeList(self._itemList, ITEM_SIZE_TYPE.TOP)
    parent:addChild(node)
end

function TrillionChallengeBubbleUI:switchShowState()
    if self:isVisible() then
        self:playHideAct()
    else
        self:playShowAct()
    end
end

function TrillionChallengeBubbleUI:playShowAct()
    if self._bActing then
        return
    end
    self._bActing = true

    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self._bActing = false
        performWithDelay(self, util_node_handler(self, self.playHideAct), 2)
    end, 60)
    gLobalNoticManager:postNotification(TrillionChallengeConfig.EVENT_NAME.NOTIFY_TRILLION_CHALLENGE_HIDE_OTHER_BUBBLE, self._idx)
end

function TrillionChallengeBubbleUI:playHideAct()
    if self._bActing then
        return
    end
    self._bActing = true
    self:stopAllActions()

    self:setVisible(true)
    self:runCsbAction("over", false, function()
        self._bActing = false
        self:setVisible(false)
    end, 60)
end

function TrillionChallengeBubbleUI:onHideBubbleEvt(_idx)
    if _idx ~= self._idx and self:isVisible() then
        self:playHideAct()
    end
end

function TrillionChallengeBubbleUI:onEnter()
    TrillionChallengeBubbleUI.super.onEnter(self)

    gLobalNoticManager:addObserver(self, "onHideBubbleEvt", TrillionChallengeConfig.EVENT_NAME.NOTIFY_TRILLION_CHALLENGE_HIDE_OTHER_BUBBLE)
end

return TrillionChallengeBubbleUI