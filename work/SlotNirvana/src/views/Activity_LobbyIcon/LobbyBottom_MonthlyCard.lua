-- 月卡

local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_MonthlyCard = class("LobbyBottom_MonthlyCard", BaseLobbyNodeUI)

function LobbyBottom_MonthlyCard:getCsbName()
    return "Activity_LobbyIconRes/LobbyBottomMonthlyCard.csb"
end

function LobbyBottom_MonthlyCard:initUI(data)
    LobbyBottom_MonthlyCard.super.initUI(self)

    self:updateRedPointNum()
end

function LobbyBottom_MonthlyCard:unlockNodeVisible(index)
    for i = 1, 2 do
        if self:findChild("unlockNode" .. i) then
            self:findChild("unlockNode" .. i):setVisible(i == index)
        end
    end
end

function LobbyBottom_MonthlyCard:updateLeftTime()
    self:updateRedPointNum()
    self:updateTime()
end

function LobbyBottom_MonthlyCard:updateRedPointNum()
    local num = 0
    local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if data then
        local isHasReward, rewardNum = data:isHasReward()
        num = rewardNum
    end
    self.m_spRedPoint:setVisible(num > 0)
    self.m_labelActivityNums:setString(num)
end

function LobbyBottom_MonthlyCard:updateTime()
    local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if data then
        local expireAt = 0
        for i = 1, 2 do
            local info = data:getInfoByType(i)
            if info.expireAt > expireAt then
                expireAt = info.expireAt
            end
        end
        local strLeftTime, isOver = util_daysdemaining(expireAt, true)
        if isOver then
            self.m_timeBg:setVisible(false)
        else
            self.m_timeBg:setVisible(true)
            self.m_djsLabel:setString(strLeftTime)
        end
    else
        if self.m_timeBg:isVisible() then
            self.m_timeBg:setVisible(false)
        end
    end
end

--
function LobbyBottom_MonthlyCard:clickFunc(sender)
    local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if data then
        if self.m_LockState then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:unlockNodeVisible(1)
            self:showTips(self.m_tips_msg)
            return
        end
        if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tipsNode_downloading)
            return
        end
        G_GetMgr(G_REF.MonthlyCard):showMainLayer()
        self:openLayerSuccess()
    else
        local data = G_GetMgr(G_REF.MonthlyCard):getData()
        if data then
            local lv = self:getSysOpenLv()
            if lv > 25000 then
                self:unlockNodeVisible(2)
            else
                self:unlockNodeVisible(1)
            end
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tips_msg)
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tips_commingsoon_msg)
        end
    end
end

function LobbyBottom_MonthlyCard:getSysOpenLv()
    local data = G_GetMgr(G_REF.MonthlyCard):getData()
    if data then
        return data:getOpenLevel()
    else
        return 30
    end
end

function LobbyBottom_MonthlyCard:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_MonthlyCard:getBottomName()
    return "MONBADGE"
end

function LobbyBottom_MonthlyCard:getDownLoadKey()
    return "MonthlyCard"
end

function LobbyBottom_MonthlyCard:getProgressPath()
    return "Activity_LobbyIconRes/ui/monthly_elite2.png"
end

function LobbyBottom_MonthlyCard:getProcessBgOffset()
    return 0, 0
end

function LobbyBottom_MonthlyCard:onEnter()
    LobbyBottom_MonthlyCard.super.onEnter(self)
    gLobalNoticManager:addObserver(self, self.zeroPointRefresh, ViewEventType.NOTIFY_AFTER_REQUEST_ZERO_REFRESH)
end

function LobbyBottom_MonthlyCard:zeroPointRefresh()
    self:updateView()
end

return LobbyBottom_MonthlyCard
