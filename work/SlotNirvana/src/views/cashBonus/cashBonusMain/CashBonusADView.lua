--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-23 15:33:21
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-23 15:33:24
FilePath: /SlotNirvana/src/views/cashBonus/cashBonusMain/CashBonusADView.lua
Description: 这是CashBonus主界面里右上角的广告入口
--]]
local CashBonusADView = class("CashBonusADView",BaseView)

function CashBonusADView:getCsbName()
    return "NewCashBonus/CashBonusNew/Ad_challenge_icon.csb"
end

function CashBonusADView:ctor()
    CashBonusADView.super.ctor(self)
end

function CashBonusADView:initCsbNodes()
    self.m_watchProgress = self:findChild("progress")
    self.m_txt_progress = self:findChild("txt_progress")
end

function CashBonusADView:initUI()
    CashBonusADView.super.initUI(self)
    self:RefreshNode()
end

function CashBonusADView:playADAction()
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end,60)
end

function CashBonusADView:playADOverAction(_call)
    self:runCsbAction("over",false,function ()
        if _call then
            _call()
        end
    end,60)
end

-- 刷新数据
function CashBonusADView:RefreshNode()

    local currentWatchCount =  globalData.AdChallengeData.m_currentWatchCount
    local maxWatchCount =  globalData.AdChallengeData.m_maxWatchCount
    if currentWatchCount > maxWatchCount then
        currentWatchCount = maxWatchCount
    end
    local rate = currentWatchCount / maxWatchCount * 100
    self.m_watchProgress:setPercent(rate)
    self.m_txt_progress:setString(currentWatchCount.."/"..maxWatchCount)
end

function CashBonusADView:zeroRefresh()
    if globalData.AdChallengeData:isHasAdChallengeActivity() and gLobalAdChallengeManager:checkOpenLevel() then
        
    else
        -- 这里是移除这个节点
        self:runCsbAction("over",false,function ()
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end,60)
    end
end

function CashBonusADView:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_go" then
        gLobalAdChallengeManager:showMainLayer()
    end
end

function CashBonusADView:onEnter()
    CashBonusADView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function()
            self:RefreshNode()
        end,
        ViewEventType.NOTIFY_ADS_REWARDS_END
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:zeroRefresh()
        end,
        ViewEventType.NOTIFY_AFTER_REQUEST_ZERO_REFRESH
    )
end

function CashBonusADView:onExit()
    gLobalNoticManager:removeAllObservers()
end

return CashBonusADView

