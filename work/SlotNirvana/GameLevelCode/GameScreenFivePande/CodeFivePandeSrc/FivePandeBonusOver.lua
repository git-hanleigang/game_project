---
--smy
--2018年4月26日
--BonusOver.lua

local BonusOver = class("BonusOver",util_require("base.BaseView"))

function BonusOver:initUI()

    self:createCsbNode("FivePande/BonusReward.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
end

function BonusOver:initViewData(pool,mul,total,callBackFun,isContinue)
    self.m_serverWinCoins = total
    self.m_isContinue=isContinue
    self.m_callFunc=callBackFun

    self.m_csbOwner["m_lb_count"]:setString(util_formatCoins(pool,30)) -- util_formatCoins(pool,9)
    self.m_csbOwner["m_lb_mul"]:setString("*"..mul)
    self.m_csbOwner["m_lb_total"]:setString(util_formatCoins(total,30)) -- util_formatCoins(total,9)

    self:updateLabelSize({label=self.m_csbOwner["m_lb_count"],sx=1.1,sy=1.1},399)
    self:updateLabelSize({label=self.m_csbOwner["m_lb_total"],sx=1.43,sy=1.43},301)

    
end

function BonusOver:onEnter()
    self:runCsbAction("actionframe")
end

function BonusOver:onExit()
    self.m_callFunc = nil

    scheduler.unschedulesByTargetName("FivePande_BonusOver")
end


function BonusOver:clickFunc(sender )
    sender:setTouchEnabled(false)
    self:runCsbAction("end")
    local nDelayTime =  0.5
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    scheduler.performWithDelayGlobal(function()
        -- 通知UI钱更新
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalNoticManager:postNotification("updateNotifyFsTopCoins",self.m_serverWinCoins)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
        end
        if self.m_callFunc then
            self.m_callFunc()
        end
    end, nDelayTime,"FivePande_BonusOver")
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return BonusOver