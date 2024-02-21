--[[--
    装修活动大厅图标
]]
local BaseActLobbyNodeUI = util_require("baseActivity.BaseActLobbyNodeUI")
local Activity_RedecorLobbyNode = class("Activity_RedecorLobbyNode", BaseActLobbyNodeUI)

function Activity_RedecorLobbyNode:ctor()
    -- 初始化多主题逻辑
    local themeLogic = G_GetMgr(ACTIVITY_REF.Redecor):getThemeLogic()
    if themeLogic then
        self.m_themeCsbCfg = themeLogic:getCsbCfg()
        self.m_themeImgCfg = themeLogic:getImgCfg()
        self.m_themeTxtCfg = themeLogic:getTxtCfg()
    else
        assert(false, "!!!Activity_RedecorLobbyNode themeLogic is nil")
        return
    end
    Activity_RedecorLobbyNode.super.ctor(self)
end

function Activity_RedecorLobbyNode:initUI(data)
    Activity_RedecorLobbyNode.super.initUI(self, data)
    self:initUnlockUI()
end

function Activity_RedecorLobbyNode:getCsbName()
    return self.m_themeCsbCfg.lobbyNode
end

function Activity_RedecorLobbyNode:initCsbNodes()
    self.lb_loading = self:findChild("lb_loading") -- 下载中描述文本
    self.lb_unlock = self:findChild("lb_unlock") -- 未解锁描述文本
end

function Activity_RedecorLobbyNode:initView()
    Activity_RedecorLobbyNode.super.initView(self)

    self.btnFunc:loadTextureNormal(self.m_themeImgCfg.lobbyBtnFunc, UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTexturePressed(self.m_themeImgCfg.lobbyBtnFuncGrey, UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTextureDisabled(self.m_themeImgCfg.lobbyBtnFuncGrey, UI_TEX_TYPE_LOCAL)

    self.m_lockIocn:setTexture(self.m_themeImgCfg.lobbyLockIcon)

    self.lb_loading:setString(self.m_themeTxtCfg.lobbyFntLoading)
    self.lb_unlock:setString(self.m_themeTxtCfg.lobbyFntUnlock)

    -- 根据图片大小 重置按钮尺寸
    if self.btnFunc then
        local size = self.btnFunc:getNormalTextureSize()
        self.btnFunc:setContentSize(size)
    end
end

function Activity_RedecorLobbyNode:openRedecorMainUI()
    self:registRedecorPopupLog()

    local themeName = G_GetMgr(ACTIVITY_REF.Redecor):getThemeName()
    gLobalActivityManager:showActivityMainView(themeName, "RedecorMainUI", nil, nil)
    self:openLayerSuccess()
end

--点击了活动node
function Activity_RedecorLobbyNode:clickLobbyNode()
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local _Data = G_GetMgr(ACTIVITY_REF.Redecor):getRunningData()
    if not _Data then
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
    local unLockLevel = self:getSysOpenLv() -- globalData.constantData.ACTIVITY_OPEN_LEVEL
    if curLevel < unLockLevel then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    local dl_key = self:getDownLoadKey()
    if globalDynamicDLControl:checkDownloading(dl_key) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    -- 新手引导 1 结束
    local RedecorGuideControl = util_getRequireFile("Activity/RedecorCode/GuideUI/RedecorGuideControl")
    if RedecorGuideControl then
        RedecorGuideControl:getInstance():stopGuide(1)
    end
    self:openRedecorMainUI()
end

function Activity_RedecorLobbyNode:getDownLoadKey()
    return self:getThemeName()
end

function Activity_RedecorLobbyNode:getThemeName()
    local themeName = nil
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.Redecor)
    if config then
        themeName = config:getThemeName()
    else
        themeName = "Activity_Redecor"
    end
    return themeName
end

-- 下载进度条节点资源
function Activity_RedecorLobbyNode:getProgressPath()
    return self.m_themeImgCfg.lobbyProgressIcon
end

function Activity_RedecorLobbyNode:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function Activity_RedecorLobbyNode:getBottomName()
    return "REDECOR"
end

function Activity_RedecorLobbyNode:updateLeftTime()
    Activity_RedecorLobbyNode.super.updateLeftTime(self)
    self:updateLabelSize({label = self.m_djsLabel}, 85)

    -- 显示红点
    if self.m_spRedPoint and self.m_labelActivityNums then
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local redNum = gameData:getLobbyRedNum()
            if redNum > 0 then
                self.m_spRedPoint:setVisible(true)
                self.m_labelActivityNums:setString(redNum)
                -- 动态更改label尺寸
                local rp_size = self.m_spRedPoint:getContentSize()
                -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
                self:updateLabelSize({label = self.m_labelActivityNums}, rp_size.width - 15)
            else
                self.m_spRedPoint:setVisible(false)
            end
        else
            -- 隐藏
            self.m_spRedPoint:setVisible(false)
        end
    end
end

function Activity_RedecorLobbyNode:getGameData()
    return G_GetMgr(ACTIVITY_REF.Redecor):getRunningData()
end

-- 记录打点信息
function Activity_RedecorLobbyNode:registRedecorPopupLog()
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", "RedecorateLobbyIcon")
end

-- 获取活动引用名
function Activity_RedecorLobbyNode:getActRefName()
    return ACTIVITY_REF.Redecor
end

-- 获取默认的解锁文本
function Activity_RedecorLobbyNode:getDefaultUnlockDesc()
    return self.m_themeTxtCfg.lobbyFntUnlock .. self:getSysOpenLv()
end

function Activity_RedecorLobbyNode:registerListener()
    Activity_RedecorLobbyNode.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not (params and params.stepId) then
                return
            end
            if params.stepId == 1 then
                local rScale = self:getUIScalePro()
                local RedecorGuideControl = util_getRequireFile("Activity/RedecorCode/GuideUI/RedecorGuideControl")
                if RedecorGuideControl then
                    RedecorGuideControl:getInstance():highLightNode(self.m_csbNode, rScale)
                end
            end
        end,
        ViewEventType.REDECOR_GUIDE_STEP_START
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not (params and params.stepId) then
                return
            end
            if params.stepId == 1 then
                local RedecorGuideControl = util_getRequireFile("Activity/RedecorCode/GuideUI/RedecorGuideControl")
                if RedecorGuideControl then
                    RedecorGuideControl:getInstance():resetHighLightNode(self.m_csbNode, self)
                end
            end
        end,
        ViewEventType.REDECOR_GUIDE_STEP_STOP
    )
end
return Activity_RedecorLobbyNode
