--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-29 15:44:12
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_EgyptCoinPusherLobbyNode = class("Activity_EgyptCoinPusherLobbyNode", BaseActLobbyNodeUI)

local res_config = {
    -- 常规主题
    Activity_EgyptCoinPusher = {
        icon_normal = "Activity_LobbyIconRes/ui/EgyptCoinPuhser_Logo.png",
        icon_pressed = "Activity_LobbyIconRes/ui/EgyptCoinPuhser_Logo2.png"
    }
}

function Activity_EgyptCoinPusherLobbyNode:initUI(data)
    Activity_EgyptCoinPusherLobbyNode.super.initUI(self, data)
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

function Activity_EgyptCoinPusherLobbyNode:updateView()
    -- 单纯重写 防止父类调用
    BaseActLobbyNodeUI.updateView(self)
    self.m_lockIocn:setVisible(false)
    self.btnFunc:setOpacity(255)
end

function Activity_EgyptCoinPusherLobbyNode:openCoinPusherSelectUI()
    self:registCoinPusherPopupLog()

    gLobalActivityManager:showActivityMainView("Activity_EgyptCoinPusher", "EgyptCoinPusherSelectUI", nil, nil)
    self:openLayerSuccess()
end

--点击了活动node
function Activity_EgyptCoinPusherLobbyNode:clickLobbyNode()
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

function Activity_EgyptCoinPusherLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_EgyptCoinPusherNode.csb"
end

function Activity_EgyptCoinPusherLobbyNode:getThemeName()
    local themeName = nil
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.EgyptCoinPusher)
    if config then
        themeName = config:getThemeName()
    else
        themeName = "Activity_EgyptCoinPusher"
    end
    return themeName
end

function Activity_EgyptCoinPusherLobbyNode:getDownLoadKey()
    return self:getThemeName()
end

function Activity_EgyptCoinPusherLobbyNode:getProgressPath()
    local themeName = self:getThemeName()
    local config = res_config[themeName]
    if config and config.icon_normal then
        return config.icon_normal
    else
        local config = res_config["Activity_EgyptCoinPusher"]
        return config.icon_normal
    end
end

function Activity_EgyptCoinPusherLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_EgyptCoinPusherLobbyNode:getBottomName()
    return "COIN EGYPT"
end

function Activity_EgyptCoinPusherLobbyNode:updateLeftTime()
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

function Activity_EgyptCoinPusherLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):getRunningData()
end

-- 记录打点信息
function Activity_EgyptCoinPusherLobbyNode:registCoinPusherPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "EgyptCoinPusherLobbyIcon")
end

-- 获取活动引用名
function Activity_EgyptCoinPusherLobbyNode:getActRefName()
    return ACTIVITY_REF.EgyptCoinPusher
end

-- 获取默认的解锁文本
function Activity_EgyptCoinPusherLobbyNode:getDefaultUnlockDesc()
    local lv = self:getNewUserLv()
    if lv then
        return lv
    else
        return "COMPLETE TORNADO QUEST OR REACH LV" .. self:getSysOpenLv() .. " TO UNLOCK"
    end
end

return Activity_EgyptCoinPusherLobbyNode
