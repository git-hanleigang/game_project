local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_CoinPusherLobbyNode = class("Activity_CoinPusherLobbyNode", BaseActLobbyNodeUI)

local res_config = {
    -- 常规主题
    Activity_CoinPusher = {
        icon_normal  = "Activity_LobbyIconRes/ui/CoinPusher_node.png",
        icon_pressed = "Activity_LobbyIconRes/ui/CoinPusher_hui.png",
    },
    -- 复活节主题
    Activity_CoinPusher_Easter = {
        icon_normal  = "Activity_LobbyIconRes/ui/CoinPusher_EasterLogo.png",
        icon_pressed = "Activity_LobbyIconRes/ui/CoinPusher_EasterLogo2.png",
    },
    -- 独立日主题
    Activity_CoinPusher_Liberty = {
        icon_normal  = "Activity_LobbyIconRes/ui/CoinPusher_node.png",
        icon_pressed = "Activity_LobbyIconRes/ui/CoinPusher_hui.png",
    },
}

function Activity_CoinPusherLobbyNode:initUI(data)
    Activity_CoinPusherLobbyNode.super.initUI(self, data)
    self:initUnlockUI()

    -- 入口按钮 锁图按主题替换
    local themeName = self:getThemeName()
    local theme_res = res_config[themeName]
    if theme_res then
        self.btnFunc:loadTextureNormal(theme_res.icon_normal, UI_TEX_TYPE_LOCAL)
        self.btnFunc:loadTexturePressed(theme_res.icon_pressed, UI_TEX_TYPE_LOCAL)
        self.btnFunc:loadTextureDisabled(theme_res.icon_pressed, UI_TEX_TYPE_LOCAL)
        self.m_lockIocn:setTexture(theme_res.icon_normal)
    end
    -- 根据图片大小 重置按钮尺寸
    if self.btnFunc then
        local size = self.btnFunc:getNormalTextureSize()
        self.btnFunc:setContentSize(size)
    end
end

function Activity_CoinPusherLobbyNode:openCoinPusherSelectUI()
    self:registCoinPusherPopupLog()

    gLobalActivityManager:showActivityMainView("Activity_CoinPusher", "CoinPusherSelectUI", nil, nil)
    self:openLayerSuccess()
end

--点击了活动node
function Activity_CoinPusherLobbyNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local _CoinPusherData = self:getGameData()
    if _CoinPusherData == nil or _CoinPusherData:isRunning() == false then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    if self.m_commingSoon then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    local curLevel = globalData.userRunData.levelNum
    local unLockLevel = self:getSysOpenLv()
    if curLevel < unLockLevel then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    if globalDynamicDLControl:checkDownloading(self:getDownLoadKey()) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    local time = _CoinPusherData:getExpireAt()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local tempTime = time - curTime
    if tempTime > 5 then
        self:openCoinPusherSelectUI()
    end
end

function Activity_CoinPusherLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_CoinPusherNode.csb"
end

function Activity_CoinPusherLobbyNode:getThemeName()
    local themeName = nil
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.CoinPusher)
    if config then
        themeName = config:getThemeName()
    else
        themeName = "Activity_CoinPusher"
    end
    return themeName
end

function Activity_CoinPusherLobbyNode:getDownLoadKey()
    -- return "Activity_CoinPusher"
    return self:getThemeName()
end

function Activity_CoinPusherLobbyNode:getProgressPath()
    -- return "Activity_LobbyIconRes/ui/CoinPusher_node.png"
    local themeName = self:getThemeName()
    local config = res_config[themeName]
    if config and config.icon_normal then
        return config.icon_normal
    else
        local config = res_config["Activity_CoinPusher"]
        return config.icon_normal
    end
end

function Activity_CoinPusherLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_CoinPusherLobbyNode:getBottomName()
    return "COIN PUSHER"
end

function Activity_CoinPusherLobbyNode:updateLeftTime()
    BaseActLobbyNodeUI.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local coin = gameData:getPushes()
            if coin > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(coin)
                local rp_size = self.m_spRedPoint:getContentSize()
                -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
                -- self:updateLabelSize({label = self.m_labelActivityNums}, rp_size.width-15)
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

function Activity_CoinPusherLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.CoinPusher):getRunningData()
end

-- 记录打点信息
function Activity_CoinPusherLobbyNode:registCoinPusherPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "CoinPusherLobbyIcon")
end

-- 获取活动引用名
function Activity_CoinPusherLobbyNode:getActRefName()
    return ACTIVITY_REF.CoinPusher
end

-- 获取默认的解锁文本
function Activity_CoinPusherLobbyNode:getDefaultUnlockDesc()
    local lv = self:getNewUserLv()
    if lv then
        return lv
    else
        return "UNLOCK COIN PUSHER AT LEVEL " .. self:getSysOpenLv()
    end
end

return Activity_CoinPusherLobbyNode
