--[[
    大厅进入老虎机加载
    author: 徐袁
    time: 2021-05-27 10:46:45
]]
local LoadingControl = require("views.loading.LoadingControl")
local LoadingGameLayer = class("LoadingGameLayer", BaseLayer)

local loadingThemes = {
    normal = "Loading/LoadingLayer.csb",
    casino = "Loading/LoadingLayer_casino.csb",
    car = "Loading/LoadingLayer_car.csb",
    fuliman = "Loading/LoadingLayer_fuliman.csb"
}

--主题loading
-- local OPEN_THEME = true

function LoadingGameLayer:ctor(sceneType)
    LoadingGameLayer.super.ctor(self)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setPauseSlotsEnabled(true)
    self:setCanSendEnterLevelLogOnExit(false)
    
    if sceneType and sceneType == SceneType.Scene_Game then
        self:setLandscapeCsbName("Loading/LoadingLayer.csb")
    else
        local landscapeCsbPath = globalData.GameConfig:getLoadingThemeCsb(loadingThemes)
        self:setLandscapeCsbName(landscapeCsbPath)
    end
    self:setPortraitCsbName("Loading/LoadingLayerPortrait.csb")

    self.m_canShowFixBtn = true
    
    self.m_LogSlots = gLobalSendDataManager:getLogSlots()
end

function LoadingGameLayer:initCsbNodes()
    -- 返回按钮
    self.m_btnLoadingBack = self:findChild("Button_back")
    self.m_btnFix = self:findChild("btn_fix")
    self.m_nodeLodingBar = self:findChild("Node_loadingBar")
    -- self.m_lb_tip = self:findChild("lb_tip")
end

function LoadingGameLayer:initView()
    self.m_btnLoadingBack:setVisible(false)
    if self.m_btnFix then
        self.m_btnFix:setVisible(false)
    end
end

function LoadingGameLayer:getLoadingBar()
    -- cxc 2022-03-02 10:31:33 关卡返回大厅不显示 loadingbar
    if LoadingControl:getInstance():isCurSceneType(SceneType.Scene_Game) and LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Lobby) then
        return
    end

    local _loadingBar = self.m_nodeLodingBar:getChildByName("LoadingBarNode")
    if not _loadingBar then
        _loadingBar = util_createView("views.logon.LoadingBarNode")
        _loadingBar:setName("LoadingBarNode")
        _loadingBar:initTxtDL()
        self.m_nodeLodingBar:addChild(_loadingBar)
    end

    return _loadingBar
end

function LoadingGameLayer:onEnter()
    LoadingGameLayer.super.onEnter(self)
    -- 设置显示的横竖屏
    local isPortrait = globalData.slotRunData:isMachinePortrait()
    globalData.slotRunData:setFramePortrait(isPortrait)
    -- gLobalSoundManager:stopAllAuido()
    -- gLobalSoundManager:uncacheAll()

    self:initLoadingTips()
    self:changeGameBg()
    self:initFixBtnUI()
    -- self.m_loadingBar:initTxtDL()
end

function LoadingGameLayer:onExit()
    G_GetMgr(ACTIVITY_REF.CoinPusher):removeEnterLevelFlag()
    G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):removeEnterLevelFlag()
    if self.m_canSendEnterLevelLog then
        -- 界面消失报送
        LoadingControl:getInstance():sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.LOADING_LAYER_EXIT)
    end
    LoadingGameLayer.super.onExit(self)
end

function LoadingGameLayer:updatePercent(percent)
    local _loadingBar = self:getLoadingBar()
    if _loadingBar then
        _loadingBar:updatePercent(percent)
    end
end

function LoadingGameLayer:initTxtDL()
    local _loadingBar = self:getLoadingBar()
    if _loadingBar then
        _loadingBar:initTxtDL()
    end
end

function LoadingGameLayer:setDlNotify(txt)
    local _loadingBar = self:getLoadingBar()
    if _loadingBar then
        _loadingBar:setDlNotify(txt)
    end
end

function LoadingGameLayer:setDlBytes(txt)
    local _loadingBar = self:getLoadingBar()
    if _loadingBar then
        _loadingBar:setDlBytes(txt)
    end
end

function LoadingGameLayer:updateLoadingTip()
    local _loadingBar = self:getLoadingBar()
    if _loadingBar then
        _loadingBar:updateLoadingTip()
    end
end

function LoadingGameLayer:setBtnBackVisible(isVisible)
    if isVisible and not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then
        -- 金币宝箱引导未完成，不显示返回大厅按钮 
        return
    end
    self.m_btnLoadingBack:setVisible(isVisible)
    if not isVisible and self.m_btnFix then
        self.m_btnFix:setVisible(isVisible)
    end
end

-- 初始化加载提示
function LoadingGameLayer:initLoadingTips()
    -- if LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Game) then
    --     self.m_lb_tip:setVisible(false)
    -- else
    -- self.m_loadingBar:setVisible(false)
    -- local index = math.random(1, #LOADING_TIPS)
    -- if self.m_lb_tip then
    --     self.m_lb_tip:setString(LOADING_TIPS[index])
    -- end
    -- schedule(
    --     self,
    --     function()
    --         local index = math.random(1, #LOADING_TIPS)
    --         if self.m_lb_tip then
    --             self.m_lb_tip:setString(LOADING_TIPS[index])
    --         end
    --     end,
    --     3
    -- )
    -- end
    -- self.m_lb_tip:setVisible(false)
end

-- fix显示 大厅进关卡卡20再显示
function LoadingGameLayer:initFixBtnUI()
    local bLobbyToGame = LoadingControl:getInstance():isCurSceneType(SceneType.Scene_Lobby) and LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Game)
    if self.m_btnFix and self.m_canShowFixBtn and bLobbyToGame then
        performWithDelay(
            self,
            function()
                self.m_btnFix:setVisible(true)
            end,
            20
        )
    end
end

-- 更新背景
function LoadingGameLayer:changeGameBg()
    --游戏背景
    local bg_game = self:findChild("bg_game")
    if LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Game) then
        self:runCsbAction("enter_game", false)
        local _machineData = LoadingControl:getInstance():getMachineData()
        if _machineData ~= nil and _machineData.p_levelName ~= nil then
            local _nodeInfo = self:findChild("Node_info")
            local _nodeLoadingInfo = self:getLoadingInfoNode()
            -- 不存在只替换图片
            self:changeBgTexture(bg_game, "tip")
            if not tolua.isnull(_nodeLoadingInfo) then
                -- 存在独立的loading脚本
                _nodeInfo:addChild(_nodeLoadingInfo)
            else
                local bg_icon = cc.Sprite:create()
                -- bg_game:getParent():addChild(bg_icon, 1)
                -- bg_icon:setPosition(bg_game:getPosition())
                if _nodeInfo then
                    _nodeInfo:addChild(bg_icon)
                    self:changeBgTexture(bg_icon, "icon")
                end
            end
            -- local scale = util_getAdaptDesignScale()
            -- bg_game:setScale(scale)
            -- bg_icon:setScale(scale)
        else
            if bg_game then
                bg_game:setVisible(false)
            end
        end
    else
        self:runCsbAction("loading", true)
        globalData.slotRunData:sortMachineDatas()
    end
end

-- 背景脚本
function LoadingGameLayer:getLoadingInfoNode()
    local _machineData = LoadingControl:getInstance():getMachineData()
    if not _machineData then
        return
    end

    local fileName = "" .. _machineData.p_levelName .. "_loading"
    local path = "GameLoading/" .. fileName
    return util_createFindView(path)
end

--切换背景资源
function LoadingGameLayer:changeBgTexture(img, key)
    if not img or not key then
        return
    end
    local _machineData = LoadingControl:getInstance():getMachineData()
    if not _machineData then
        return
    end

    local fileName = "" .. _machineData.p_levelName .. "_" .. key
    local isGroupA = globalData.GameConfig:checkLevelGroupA(_machineData.p_levelName)
    if isGroupA and key == "icon" then
        fileName = fileName .. "_abtest"
    end

    local path = "GameLoading/" .. fileName .. ".png"
    if util_IsFileExist(path) then
        util_changeTexture(img, path)
    -- else
    --     if CC_IS_READ_DOWNLOAD_PATH == false then
    --         --abtest
    --         local abKey = _machineData.p_levelName
    --         local data = globalData.GameConfig:checkABTestData(abKey)
    --         if data then
    --             path = "ABTest/" .. data.groupKey .. "/" .. abKey .. "/" .. abKey .. "_" .. key .. ".png"
    --         else
    --             path = abKey .. "/" .. abKey .. "_" .. key .. ".png"
    --         end
    --     else
    --         path = _machineData.p_levelName .. "/" .. _machineData.p_levelName .. "_" .. key .. ".png"
    --     end
    --     util_changeTexture(img, path)
    end
end

function LoadingGameLayer:loadingBackLobby(_bPressBack)
    -- self.m_clickBack = true
    if _bPressBack then
        LoadingControl:getInstance():sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.CANCEL)
    else
        LoadingControl:getInstance():sendEnterLevelLog(self.m_LogSlots.EnterLevelStepEnum.ERROR, self.m_LogSlots.EnterLevelStepErrorEnum.FIX_DOWNLOAD_BACK)
    end

    LoadingControl:getInstance():loadingBackLobby()
end

function LoadingGameLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if self.m_click then
        return
    end
    if name == "Button_back" then
        self.m_click = true
        self:loadingBackLobby(true)
    elseif name == "btn_fix" then
        self:popFixLevelResourcesView()
    end
end

function LoadingGameLayer:popFixLevelResourcesView()
    local _cb = function()
    end
    local bLobbyToGame = LoadingControl:getInstance():isCurSceneType(SceneType.Scene_Lobby) and LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Game)
    if bLobbyToGame then
        _cb = handler(self, self.loadingBackLobby)
    end

    local fixDialog = util_createView("views.dialogs.LoadingFixLevelResourcesDialog", _cb)
    self:addChild(fixDialog, ViewZorder.ZORDER_NETWORK)
end

-- 界面关闭是否需要报送
function LoadingGameLayer:setCanSendEnterLevelLogOnExit(_bEnable)
    self.m_canSendEnterLevelLog = _bEnable
end

return LoadingGameLayer
