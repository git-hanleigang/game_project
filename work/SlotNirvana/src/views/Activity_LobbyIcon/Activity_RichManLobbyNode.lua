local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_RichManLobbyNode = class("Activity_RichManLobbyNode", BaseActLobbyNodeUI)

function Activity_RichManLobbyNode:initUI(data)
    Activity_RichManLobbyNode.super.initUI(self, data)

    self:initUnlockUI()
end

function Activity_RichManLobbyNode:openRichManSelectUI()
    -- gLobalActivityManager:showActivityMainView("Activity_RichMan", "RichManMain", nil, nil)
    local _view = G_GetMgr(ACTIVITY_REF.RichMan):showMainLayer()
    if _view then
        self:openLayerSuccess()
    end
end

--点击了活动node
function Activity_RichManLobbyNode:clickLobbyNode()
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

    local _richManData = self:getGameData()
    if not _richManData then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if not globalDynamicDLControl:checkDownloaded("Activity_RichMan") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    self:openRichManSelectUI()
end

function Activity_RichManLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_RichManLobbyNode.csb"
end

function Activity_RichManLobbyNode:getDownLoadKey()
    return "Activity_RichMan"
end

function Activity_RichManLobbyNode:getProgressPath()
    return "Activity_LobbyIconRes/ui/richMan_node.png"
end

function Activity_RichManLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_RichManLobbyNode:getBottomName()
    return "RACE"
end

function Activity_RichManLobbyNode:updateLeftTime()
    Activity_RichManLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if not gameData or not gameData:isRunning() then
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
            return
        end

        local dices = gameData:getLeftDices()
        if not dices or dices <= 0 then
            self.m_spRedPoint:setVisible(false)
            return
        end

        self.m_spRedPoint:setVisible(true)
        self.m_labelActivityNums:setString(dices)

        local rp_size = self.m_spRedPoint:getContentSize()
        -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
        -- self:updateLabelSize({label = self.m_labelActivityNums}, rp_size.width-15)
        util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
    end
end

function Activity_RichManLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.RichMan):getRunningData()
end

-- 获取活动引用名
function Activity_RichManLobbyNode:getActRefName()
    return ACTIVITY_REF.RichMan
end

-- 获取默认的解锁文本
function Activity_RichManLobbyNode:getDefaultUnlockDesc()
    return "UNLOCK TREASURE AT LEVEL " .. self:getSysOpenLv()
end

return Activity_RichManLobbyNode
