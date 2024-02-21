--[[
Author: cxc
Date: 2022-03-24 12:12:49
LastEditTime: 2022-03-24 12:12:50
LastEditors: cxc
Description: 3日行为付费聚合活动   base 主界面按钮 标题时间 什么的
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/WildChallengeActBaseOtherUI.lua
--]]
local WildChallengeActBaseOtherUI = class("WildChallengeActBaseOtherUI", BaseView)
local Config = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

function WildChallengeActBaseOtherUI:initDatas()
    self.m_actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getRunningData()
end

function WildChallengeActBaseOtherUI:initCsbNodes()
    self.m_btnClose = self:findChild("btn_X")
    self.m_lbTimeTip = self:findChild("Text_1")
    self.m_lbLeftTime = self:findChild("Text_2")

    self:addClickSound({"btn_X"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function WildChallengeActBaseOtherUI:initUI()
    WildChallengeActBaseOtherUI.super.initUI(self)

    -- 时间
    self:updateTimeUI()
    self.m_scheduler = schedule(self, handler(self, self.updateTimeUI), 1)

    self:changeVisibleSize()
    self:runCsbAction("idle", true)
end

-- 活动时间
function WildChallengeActBaseOtherUI:updateTimeUI()
    local days = util_leftDays(self.m_actData:getExpireAt(), true)
    local tipKey = "WildChallengeActBaseOtherUI_TimeTipOneDay"
    if days > 0 then
        tipKey = "WildChallengeActBaseOtherUI_TimeTipMoreDay"
    end
    local tipStr = gLobalLanguageChangeManager:getStringByKey(tipKey) or "END IN"
    if self.m_lbTimeTip then
        self.m_lbTimeTip:setString(tipStr)
    end

    local timeStr, bOver = util_daysdemaining(self.m_actData:getExpireAt(), true)
    self.m_lbLeftTime:setString(timeStr)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbLeftTime, 120)
    if bOver then
        self:clearScheduler()
    end
end

function WildChallengeActBaseOtherUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_X" then
        gLobalNoticManager:postNotification(Config.EVENT_NAME.WILD_CHALLENGE_COLSE_MIAN_LAYER)
    end
end

function WildChallengeActBaseOtherUI:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return WildChallengeActBaseOtherUI