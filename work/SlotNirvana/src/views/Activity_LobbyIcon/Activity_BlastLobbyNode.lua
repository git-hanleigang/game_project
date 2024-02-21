-- blast 活动大厅图标

local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_BlastLobbyNode = class("Activity_BlastLobbyNode", BaseActLobbyNodeUI)

local res_config = {
    -- 常规主题
    Activity_Blast = {
        common_icon = "Activity_LobbyIconRes/ui/blastO1.png",
        pressed_icon = "Activity_LobbyIconRes/ui/blastO.png",
        loading_str = "OCEAN BLAST ARE DOWNLOADING"
    },
    -- 万圣节主题
    Activity_BlastHalloween = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_Halloween.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_Halloween_Black.png",
        loading_str = "CREEPY BLAST ARE DOWNLOADING"
    },
    -- 感恩节主题
    Activity_BlastThanksGiving = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_ThanksGiving.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_ThanksGiving_Black.png",
        loading_str = "THANKSGIVING BLAST ARE DOWNLOADING"
    },
    -- 圣诞节主题
    Activity_BlastChristmas = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_Christmas2021.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_Christmas2021_Black.png",
        loading_str = "CHRISTMAS BLAST ARE DOWNLOADING"
    },
    -- 复活节主题
    Activity_BlastEaster = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_Easter.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_Easter_black.png",
        loading_str = "SPRING BLAST ARE DOWNLOADING"
    },
    -- 三周年主题
    Activity_Blast3RD = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_3RD.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_3RD_Black.png",
        loading_str = "3RD BLAST ARE DOWNLOADING"
    },
    -- 阿凡达主题
    Activity_BlastBlossom = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_Blossom.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_Blossom_Black.png",
        loading_str = "BLOSSOM BLAST ARE DOWNLOADING"
    },
    -- 人鱼主题
    Activity_BlastMermaid = {
        common_icon = "Activity_LobbyIconRes/ui/Blast_Mermaid.png",
        pressed_icon = "Activity_LobbyIconRes/ui/Blast_Mermaid_Black.png",
        loading_str = "MERMAID BLAST ARE DOWNLOADING"
    }
}

function Activity_BlastLobbyNode:initView()
    BaseActLobbyNodeUI.super.initView(self)
    self.lb_loading = self:findChild("lb_loading") -- 下载中描述文本
    self.lb_unlock = self:findChild("lb_unlock") -- 未解锁描述文本

    local themeName = self:getThemeName()
    local theme_res = res_config[themeName]
    if theme_res then
        self.btnFunc:loadTextureNormal(theme_res.common_icon, UI_TEX_TYPE_LOCAL)
        self.btnFunc:loadTexturePressed(theme_res.pressed_icon, UI_TEX_TYPE_LOCAL)
        self.btnFunc:loadTextureDisabled(theme_res.pressed_icon, UI_TEX_TYPE_LOCAL)

        self.m_lockIocn:setTexture(theme_res.common_icon)
        self.lb_loading:setString(theme_res.loading_str)
    end

    -- 根据图片大小 重置按钮尺寸
    if self.btnFunc then
        local size = self.btnFunc:getNormalTextureSize()
        self.btnFunc:setContentSize(size)
    end

    self:initUnlockUI()
    if self.m_isNewUser then
        self.m_lock:setVisible(false)
        self:showDownTimer()
    end
end

function Activity_BlastLobbyNode:updateView()
    -- 单纯重写 防止父类调用
    BaseActLobbyNodeUI.super.updateView(self)
    self.btnFunc:setOpacity(255)
    self.m_lockIocn:setVisible(false)
end
function Activity_BlastLobbyNode:openBlastSelectUI()
    self:registBlastPopupLog()
    gLobalActivityManager:showActivityMainView("Activity_Blast", "BlastMainUI", nil, nil)
    self:openLayerSuccess()
end

--点击了活动node
function Activity_BlastLobbyNode:clickLobbyNode()
    local gameData = G_GetMgr(ACTIVITY_REF.Blast):getRunningData()
    local over = G_GetMgr(ACTIVITY_REF.Blast):getNewUserOver()
    if over and CardSysManager and CardSysManager:isNovice() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:findChild("lb_loading"):setString("COMPLETE TORNADO ALBUM TO UNLOCK")
        self:showTips(self.m_tipsNode_downloading)
        return
    end
    local level = self:getSysOpenLv()
    print("level------------",level)
    if globalData.constantData.NoviceNewUserBlastSwitch and globalData.constantData.NoviceNewUserBlastSwitch == "1" and not G_GetMgr(ACTIVITY_REF.Blast):getNewUserOver() then
        if globalData.userRunData.levelNum < level then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:findChild("Sprite_3"):setString("REACH LEVEL " .. level .. " TO UNLOCK")
            self:showTips(self.m_tips_commingsoon_msg)
            return
        end
    end
    if gameData and gameData:getNewUser() then
    elseif self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end
    
    local _BlastData = G_GetMgr(ACTIVITY_REF.Blast):getRunningData()
    if _BlastData == nil then
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
    if globalDynamicDLControl:checkDownloading(dl_key) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end
    if gameData and gameData:getNewUser() then
        self:registBlastPopupLog()
        G_GetMgr(ACTIVITY_REF.Blast):showMainLayer()
        self:openLayerSuccess()
    else
        self:openBlastSelectUI()
    end
end

function Activity_BlastLobbyNode:getCsbName()
    return "Activity_LobbyIconRes/Activity_BlastLobbyNode.csb"
end

function Activity_BlastLobbyNode:getDownLoadKey()
    local themeName = self:getThemeName()
    if themeName == "Activity_Blast" then
        -- 海洋主题
        return "Activity_Blast"
    elseif themeName == "Activity_BlastHalloween" then
        -- 万圣节主题
        return "Activity_BlastHalloween"
    elseif themeName == "Activity_BlastThanksGiving" then
        -- 感恩节主题
        return "Activity_BlastThanksGiving"
    elseif themeName == "Activity_BlastChristmas" then
        -- 圣诞节主题
        return "Activity_BlastChristmas"
    elseif themeName == "Activity_BlastEaster" then
        -- 复活节主题
        return "Activity_BlastEaster"
    elseif themeName == "Activity_Blast3RD" then
        -- 三周年主题
        return "Activity_Blast3RD"
    elseif themeName == "Activity_BlastBlossom" then
        --阿凡达主题
        return "Activity_BlastBlossom"
    elseif themeName == "Activity_BlastMermaid" then
        --人鱼主题
        return "Activity_BlastMermaid"
    end

    return "Activity_Blast"
end

function Activity_BlastLobbyNode:getThemeName()
    local themeName = nil
    local _data = self:getGameData()
    if _data and _data:getNewUser() then
        self.m_isNewUser = true
        themeName = "Activity_BlastBlossom"
    else
        self.m_isNewUser = false
        local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.Blast)
        if config then
            themeName = config:getThemeName()
        else
            themeName = "Activity_BlastBlossom"
        end
    end
    return themeName
end

-- 下载进度条节点资源
function Activity_BlastLobbyNode:getProgressPath()
    local themeName = self:getThemeName()
    local theme_res = res_config[themeName]
    if theme_res and theme_res.common_icon then
        return theme_res.common_icon
    end
end

function Activity_BlastLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_BlastLobbyNode:getBottomName()
    return "BLAST"
end

function Activity_BlastLobbyNode:updateLeftTime()
    BaseActLobbyNodeUI.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)
    -- 显示红点
    local gameData = self:getGameData()
    if self.m_spRedPoint and self.m_labelActivityNums then
        if gameData ~= nil and gameData:isRunning() then
            local coin = gameData:getPicks()
            if coin > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(coin)
                local rp_size = self.m_spRedPoint:getContentSize()
                -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
                -- self:updateLabelSize({label=self.m_labelActivityNums},rp_size.width-15)
                util_scaleCoinLabGameLayerFromBgWidth(self.m_labelActivityNums, 26)
            else
                self.m_spRedPoint:setVisible(false)
            end
        else
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
        end
    end
    if gameData ~= nil then
        if G_GetMgr(ACTIVITY_REF.Blast):getNewUserOver() and CardSysManager and CardSysManager:isNovice() then
            self.m_lock:setVisible(true)
        end
    end
end

function Activity_BlastLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.Blast):getRunningData()
end

-- 记录打点信息
function Activity_BlastLobbyNode:registBlastPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "BlastLobbyIcon")
end

-- 获取活动引用名
function Activity_BlastLobbyNode:getActRefName()
    return ACTIVITY_REF.Blast
end

-- 获取默认的解锁文本
function Activity_BlastLobbyNode:getDefaultUnlockDesc()
    local openLv = self:getSysOpenLv()

    return self.m_unlockstr or "COMPLETE VEGAS QUEST OR REACH LEVEL " .. globalData.constantData.ACTIVITY_OPEN_LEVEL .. " TO UNLOCK"
end

-- 获取 开启等级
function Activity_BlastLobbyNode:getSysOpenLv()
    self.m_unlockstr = "COMPLETE VEGAS QUEST OR REACH LEVEL " .. globalData.constantData.ACTIVITY_OPEN_LEVEL .. " TO UNLOCK"
    local gameData = G_GetMgr(ACTIVITY_REF.Blast):getRunningData()
    local level = Activity_BlastLobbyNode.super.getSysOpenLv(self)
    print("level--------------------",level)
    local my_level = globalData.userRunData.levelNum
    if globalData.constantData.NoviceNewUserBlastSwitch and globalData.constantData.NoviceNewUserBlastSwitch == "1" and not G_GetMgr(ACTIVITY_REF.Blast):getNewUserOver() then
        if my_level < globalData.constantData.NoviceBlastOpenLevel then
            level = globalData.constantData.NoviceBlastOpenLevel
            self.m_unlockstr = "REACH LEVEL " .. level .. " TO UNLOCK"
        else
            if gameData and gameData:getNewUser() then
                level = globalData.constantData.NoviceBlastOpenLevel
                self.m_unlockstr = "REACH LEVEL " .. level .. " TO UNLOCK"
            end
        end
    end
    return level
end

function Activity_BlastLobbyNode:onEnter()
    Activity_BlastLobbyNode.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_userover = true
            self.m_lock:setVisible(true)
        end,
        ViewEventType.NOTIFY_BLAST_GAME_OVER
    )
end

return Activity_BlastLobbyNode
