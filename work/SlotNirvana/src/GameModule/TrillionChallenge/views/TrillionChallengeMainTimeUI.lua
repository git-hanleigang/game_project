--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:31:04
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/TrillionChallengeMainTimeUI.lua
Description: 亿万赢钱挑战 倒计时UI
--]]
local TrillionChallengeMainTimeUI = class("TrillionChallengeMainTimeUI", BaseView)

function TrillionChallengeMainTimeUI:getCsbName()
    return "Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main_time.csb"
end

function TrillionChallengeMainTimeUI:initCsbNodes()
    self._lbTime = self:findChild("lb_time")
end

function TrillionChallengeMainTimeUI:initUI()
    TrillionChallengeMainTimeUI.super.initUI(self)

    self._data = G_GetMgr(G_REF.TrillionChallenge):getRunningData()

    -- 倒计时
    self:updateTimeUI()
    schedule(self, util_node_handler(self, self.updateTimeUI), 1)
end

function TrillionChallengeMainTimeUI:updateTimeUI()
    local expireAt = self._data:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self._lbTime:setString(timeStr)

    if bOver then
        self:stopAllActions()
        self:closeMainLayer()
    end
end

function TrillionChallengeMainTimeUI:closeMainLayer()
    local mainLayer = gLobalViewManager:getViewByName("TrillionChallengeMainLayer")
    if mainLayer then
        mainLayer:closeUI()
    end
end

return TrillionChallengeMainTimeUI