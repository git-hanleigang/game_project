local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_WorldTripLobbyNode = class("Activity_WorldTripLobbyNode", BaseActLobbyNodeUI)

function Activity_WorldTripLobbyNode:initUI(data)
    Activity_WorldTripLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

function Activity_WorldTripLobbyNode:openSelectUI()
    local _view = G_GetMgr(ACTIVITY_REF.WorldTrip):showLevelLayer()
    if _view then
        self:openLayerSuccess()
    end
end

--点击了活动node
function Activity_WorldTripLobbyNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local unLockLevel = self:getSysOpenLv()
    local curLevel = globalData.userRunData.levelNum
    if curLevel < unLockLevel then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local gameData = self:getGameData()
    if not gameData then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    local dl_key = self:getDownLoadKey()
    if not dl_key or not globalDynamicDLControl:checkDownloaded(dl_key) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    self:openSelectUI()
end

function Activity_WorldTripLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_WorldTripLobbyNode.csb"
end

function Activity_WorldTripLobbyNode:getDownLoadKey()
    return "Activity_WorldTrip"
end

function Activity_WorldTripLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/WorldTrip_1.png"
end

function Activity_WorldTripLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_WorldTripLobbyNode:getBottomName()
    return "WORLD TRIP"
end

function Activity_WorldTripLobbyNode:updateLeftTime()
    Activity_WorldTripLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if not gameData or not gameData:isRunning() then
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
            return
        end

        local dices = gameData:getDices()
        if not dices or dices <= 0 then
            self.m_spRedPoint:setVisible(false)
            return
        end

        self.m_spRedPoint:setVisible(true)
        self.m_labelActivityNums:setString(dices)
        util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
    end
end

function Activity_WorldTripLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.WorldTrip):getRunningData()
end

-- 获取活动引用名
function Activity_WorldTripLobbyNode:getActRefName()
    return ACTIVITY_REF.WorldTrip
end

-- 获取默认的解锁文本
function Activity_WorldTripLobbyNode:getDefaultUnlockDesc()
    local lv = self:getNewUserLv()
    if lv then
        return lv
    else
        return "UNLOCK WORD TORNADO AT LEVEL " .. self:getSysOpenLv()
    end
end

return Activity_WorldTripLobbyNode
