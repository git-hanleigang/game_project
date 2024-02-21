-- 农场

local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_FarmNode = class("LobbyBottom_FarmNode", BaseLobbyNodeUI)

function LobbyBottom_FarmNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_FarmNode.csb"
end

function LobbyBottom_FarmNode:initUI(data)
    LobbyBottom_FarmNode.super.initUI(self)

    self:updateRedPointNum()
end

function LobbyBottom_FarmNode:updateLeftTime()
    local gameData = G_GetMgr(G_REF.Farm):getRunningData()
    if gameData then
        self:updateRedPointNum()

        local expireAt = gameData:getExpireAt()
        if expireAt and expireAt > 0 then
            self.m_lock:setVisible(false)
            local days = util_leftDays(expireAt / 1000, true)
            if days <= 7 then
                self.m_timeBg:setVisible(true)
                local strLeftTime = util_daysdemaining(expireAt / 1000, true)
                self.m_djsLabel:setString(strLeftTime)
            else
                self.m_timeBg:setVisible(false)
            end
        else
            self.m_lock:setVisible(false)
            self.m_timeBg:setVisible(false)
            self:closeLobbyNode()
        end
    else
        self.m_lock:setVisible(true)
        self.m_timeBg:setVisible(false)
        self.m_spRedPoint:setVisible(false)
        self:closeLobbyNode()
    end
end

function LobbyBottom_FarmNode:updateRedPointNum()
    local num = 0
    local gameData = G_GetMgr(G_REF.Farm):getRunningData()
    if gameData then
        num = gameData:getRipeCropNum()
    end
    self.m_spRedPoint:setVisible(num > 0)
    self.m_labelActivityNums:setString(num)
end

--
function LobbyBottom_FarmNode:clickFunc(sender)
    local gameData = G_GetMgr(G_REF.Farm):getRunningData()
    if gameData then
        if self.m_LockState then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tips_msg)
            return
        end
        if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:showTips(self.m_tipsNode_downloading)
            return
        end
        self:openLayerSuccess()
        G_GetMgr(G_REF.Farm):sendStealRecord(1)
    else
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
    end
end

function LobbyBottom_FarmNode:getSysOpenLv()
    local gameData = G_GetMgr(G_REF.Farm):getRunningData()
    if gameData then
        return gameData:getOpenLevel()
    else
        return 50
    end
end

function LobbyBottom_FarmNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_FarmNode:getBottomName()
    return "Farm"
end

function LobbyBottom_FarmNode:getDownLoadKey()
    return "Farm"
end

function LobbyBottom_FarmNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/Farm_icon2.png"
end

function LobbyBottom_FarmNode:getProcessBgOffset()
    return 0, 0
end

function LobbyBottom_FarmNode:showFarmLayer(_params)
    if _params then
        if _params.code then
            gLobalViewManager:showReConnect()
            return
        end
        
        G_GetMgr(G_REF.Farm):showMainLayer(true, _params)
    end
end

function LobbyBottom_FarmNode:onEnter()
    LobbyBottom_FarmNode.super.onEnter(self)

    gLobalNoticManager:addObserver(self, self.showFarmLayer, ViewEventType.NOTIFY_ACTIVITY_FARM_STEAL_RECORD)
end

return LobbyBottom_FarmNode
