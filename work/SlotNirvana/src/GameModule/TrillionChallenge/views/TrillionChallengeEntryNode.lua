--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:30:31
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/TrillionChallengeEntryNode.lua
Description: 亿万赢钱挑战 关卡 入口
--]]
local TrillionChallengeEntryNode = class("TrillionChallengeEntryNode", BaseView)
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")

function TrillionChallengeEntryNode:getCsbName()
    return "Activity/Activity_TrillionChallenge/csb/entry/TrillionChallenge_logo.csb"
end

function TrillionChallengeEntryNode:initCsbNodes()
    self._size = self:findChild("Node_PanelSize"):getContentSize()
end

function TrillionChallengeEntryNode:initUI()
    TrillionChallengeEntryNode.super.initUI(self)
    self._data = G_GetMgr(G_REF.TrillionChallenge):getRunningData()

    -- 排行
    self:updateRankUI()
    -- 倒计时
    schedule(self, util_node_handler(self, self.onUpdateDt), 1)

    self:runCsbAction("idle", true)
end

-- 排行
function TrillionChallengeEntryNode:updateRankUI()
    local lbRank = self:findChild("lb_rank")
    local rank = self._data:getCurRank()
    lbRank:setString(rank)
    util_scaleCoinLabGameLayerFromBgWidth(lbRank, 46, 1)
    lbRank:setVisible(rank > 0)
end

function TrillionChallengeEntryNode:getPanelSize()
    return {widht = self._size.width, height = self._size.height}
end

function TrillionChallengeEntryNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        G_GetMgr(G_REF.TrillionChallenge):showMainLayer()
    end
end

function TrillionChallengeEntryNode:onRankChangeEvt()
    self:updateRankUI()

    local rankUp = self._data:getRankUp()
    local csbName = "idle"
    if rankUp > 0 then
        csbName = "up"
    elseif rankUp < 0 then
        csbName = "down"
    end
    self:runCsbAction(csbName, true)
    self._data:setRankUp(0)
end

function TrillionChallengeEntryNode:onResetRankChangeEvt()
    self._data:setRankUp(0)
    self:runCsbAction("idle", true)
end

function TrillionChallengeEntryNode:onUpdateDt()
    if not G_GetMgr(G_REF.TrillionChallenge):isRunning() then
        self:stopAllActions()
        gLobalActivityManager:removeActivityEntryNode("TrillionChallenge")
    end
end

function TrillionChallengeEntryNode:onEnter()
    TrillionChallengeEntryNode.super.onEnter(self)

    gLobalNoticManager:addObserver(self, "onRankChangeEvt", TrillionChallengeConfig.EVENT_NAME.NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP) -- 更新入口排行变化
    gLobalNoticManager:addObserver(self, "onResetRankChangeEvt", TrillionChallengeConfig.EVENT_NAME.NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP_RESET) -- 更新入口排行变化
end

-- 监测 有小红点或者活动进度满了
function TrillionChallengeEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    local bProgMax = false
    return {bHadRed, bProgMax}
end

return TrillionChallengeEntryNode