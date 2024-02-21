local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_PipeConnectLobbyNode = class("Activity_PipeConnectLobbyNode", BaseActLobbyNodeUI)

function Activity_PipeConnectLobbyNode:initUI(data)
    Activity_PipeConnectLobbyNode.super.initUI(self, data)
    self:initUnlockUI()
end

function Activity_PipeConnectLobbyNode:registerListener()
    Activity_PipeConnectLobbyNode.super.registerListener(self)
end

--点击了活动node
function Activity_PipeConnectLobbyNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end
    if globalDynamicDLControl:checkDownloading("Activity_PipeConnect") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end
    self:openPcont()
end

function Activity_PipeConnectLobbyNode:openPcont()
    --进入接水管游戏选择界面
    G_GetMgr(ACTIVITY_REF.PipeConnect):showSelectLayer()
    self:openLayerSuccess()
end

function Activity_PipeConnectLobbyNode:onEnter()
    Activity_PipeConnectLobbyNode.super.onEnter(self)
end

function Activity_PipeConnectLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_PipeConnectNode.csb"
end

function Activity_PipeConnectLobbyNode:getDownLoadKey()
    return "Activity_PipeConnect"
end

function Activity_PipeConnectLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/PipeConnect_icon1.png"
end

function Activity_PipeConnectLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_PipeConnectLobbyNode:getBottomName()
    return "PIPE"
end

function Activity_PipeConnectLobbyNode:updateLeftTime()
    Activity_PipeConnectLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local LeftBalls = gameData:getPipes()
            if LeftBalls > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(LeftBalls)
                -- self:updateLabelSize({label = self.m_labelActivityNums}, 35)
                util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
            else
                self.m_spRedPoint:setVisible(false)
            end
        else
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
        end
    end
end

function Activity_PipeConnectLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.PipeConnect):getRunningData()
end

-- 获取活动引用名
function Activity_PipeConnectLobbyNode:getActRefName()
    return ACTIVITY_REF.PipeConnect
end

-- 获取默认的解锁文本
function Activity_PipeConnectLobbyNode:getDefaultUnlockDesc()
    local lv = self:getNewUserLv()
    if lv then
        return lv
    else
        return "UNLOCK PIPECONNECT LINK AT LEVEL " .. self:getSysOpenLv()
    end
end

function Activity_PipeConnectLobbyNode:updateView()
    Activity_PipeConnectLobbyNode.super.updateView(self)

    self.m_lockIocn:setVisible(false) -- 锁定icon
    self.btnFunc:setOpacity(255)
end

return Activity_PipeConnectLobbyNode
