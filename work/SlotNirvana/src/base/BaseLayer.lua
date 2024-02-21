--[[
    基础图层:统一处理layer类界面的通用逻辑
    1、显示和关闭界面动画
        1）默认有动画，可使用 setShowActionEnabled 或 setHideActionEnabled 选择是否启用动画
        2）动画后回调逻辑，分别继承拓展 showActionCallback 和 hideActionCallback 方法
        3）通过修改 xxxxLayer.ActionType 的值选择使用的动画，可选 "Common" 或 "Activity"
        4）若使用TimeLine动画替代通用动画，则分别覆盖重写 playShowAction 和 playHideAction 方法，
        并在动画结束后，调用动画结束回调 showActionCallback 和 hideActionCallback 方法
    2、处理layer适配缩放
    3、关闭界面统一使用closeUI方法，上层非特殊需求，不用调用 removeFromParent 方法
    4、播放动画过程中的点击事件阻塞。
    author: 徐袁
    time: 2021-01-08 14:26:01
]]
local BaseLayer = class("BaseLayer", BaseView)
-- 刘海位置索引
GD.BANG_POS = {
    TOP = 1,
    BOTTOM = 2,
    LEFT = 3,
    RIGHT = 4
}
-- 弹出位置/地点
GD.PopSite = {
    Push = "PushCtrl",
    Slot = "MachCtrl"
}
-- 显示和移除事件
ViewEventType.NOTIFY_ENTER_LAYER = "NotifyEnterLayer"
ViewEventType.NOTIFY_EXIT_LAYER = "NotifyExitLayer"
ViewEventType.NOTIFY_CLEAN_UP_LAYER = "NotifyCleanUpLayer"

-- 1、"Common"通用动画
-- 2、"Activity"活动动画
BaseLayer.ActionType = "Common"

BaseLayer.ResolutionPolicy = {
    SHOW_ALL = "SHOW_ALL",
    FIXED_HEIGHT = "FIXED_HEIGHT",
    FIXED_WIDTH = "FIXED_WIDTH"
}

-- 发送lua异常到bugly
local _sendLuaException = function(errMsg)
    if DEBUG ~= 0 then
        assert(nil, errMsg)
    else
        local versionCode = 0
        if util_getUpdateVersionCode then
            versionCode = util_getUpdateVersionCode(false)
        end
        local _errMsg = "V" .. tostring(versionCode) .. " " .. tostring(errMsg)
        if MARKETSEL and device.platform == "android" then
            _errMsg = tostring(MARKETSEL) .. " " .. _errMsg
        end
        gLobalBuglyControl:luaException(tostring(_errMsg), debug.traceback())
    end
end

function BaseLayer:ctor(...)
    BaseLayer.super.ctor(self, ...)

    -- 需要显示layer动作
    self.m_isShowActionEnabled = true
    -- 需要隐藏layer动作
    self.m_isHideActionEnabled = true

    self.m_isShowing = false
    self.m_isHiding = false

    -- 播放动画的节点
    self.m_actionNodeNames = {}

    -- 是否暂停老虎机轮盘
    self.m_isPauseSlotsEnabled = false
    -- 显示位置/场景
    self.m_popSite = ""
    -- 默认不启用系统返回键
    self.m_isKeyBackEnabled = false
    -- 默认有遮罩
    self.m_isMaskEnabled = true
    -- 是否忽略缩放
    self.m_isIgnoreAutoScale = false

    -- 横屏csb
    self.m_csbLandscape = nil
    -- 竖屏csb
    self.m_csbPortrait = nil
    -- 使用竖屏csb
    self.m_usedPortraitCsb = false

    -- 背景音乐路径
    self.m_bgmPath = nil
    self.m_bgmEnabled = true

    -- 是否显示竖屏视图
    self.m_isShownAsPortrait = nil

    -- 显示时背景透明度
    self.m_maskBgOpacity = nil
    -- 背景隐藏延时
    self.m_maskHideDelay = 0

    -- 隐藏回调
    self.m_hideCallbackFunc = nil

    -- 是否隐藏大厅
    self.m_isHideLobby = false

    -- root的初始设计大小
    self.m_rootDesignSize = nil

    -- root容器适配模式
    self.m_resolutionPolicy = self.ResolutionPolicy.SHOW_ALL
    -- onEnter时刷新适配的节点
    self.m_doLayoutNodeByOnEnter = nil

    -- 是否有引导
    self.m_isHasGuide = false

    self.m_needAdaptiveBang = false

    -- 刘海屏适配节点
    self:initAdaptiveBandNodes()

    -- 默认界面可以相应 onKeyBack
    self:setCanAddKeyBack(true)

    self:addActionNodeName("root")
end

-- 刘海屏适配节点
function BaseLayer:initAdaptiveBandNodes()
    self.m_needAdaptiveBangNodes = {
        [1] = {}, -- 上边
        [2] = {}, -- 下边
        [3] = {}, -- 左边
        [4] = {} -- 右边
    }
end

function BaseLayer:initUI(...)
    if self.m_isShownAsPortrait == nil then
        -- 没有设置则用当前的
        self.m_isShownAsPortrait = self:isPortraitScreen()
    end

    if BaseLayer.super.initUI then
        BaseLayer.super.initUI(self, ...)
    end

    -- 适配
    local isAutoScale = true
    local ratioIdx = CC_RESOLUTION_RATIO
    if self.m_isShownAsPortrait == true then
        local _designSize = self:_getLayerDesignSize()
        local ratio = _designSize.width / _designSize.height
        if ratio <= 1.34 then
            ratioIdx = 2
        elseif ratio >= 1.78 then
            ratioIdx = 3
        end
    end

    if ratioIdx == 3 then
        isAutoScale = false
    end

    --兼容热更问题
    if self.setAutoScale then
        self:setAutoScale(isAutoScale)
    end

    self:initView(...)
end

-- 初始化界面显示
function BaseLayer:initView(...)
end

-- 获得csb资源目录
function BaseLayer:getCsbName()
    local _csbName = nil
    if self.m_isShownAsPortrait == true and self.m_csbPortrait then
        -- 竖屏且存在竖屏资源
        _csbName = self.m_csbPortrait
        self.m_usedPortraitCsb = true
    else
        _csbName = self.m_csbLandscape
        self.m_usedPortraitCsb = false
    end

    return _csbName
end

-- 屏幕是否竖版
function BaseLayer:isPortraitScreen()
    return RotateScreen:getInstance():isPortraitScreen()
end

-- 窗口是否竖版
function BaseLayer:isPortraitWindow()
    return globalData.slotRunData.isPortrait
end

--[[
    @desc: 设置界面动作类型
    @actionType: 动画类型
    @startPos: 开始位置
]]
function BaseLayer:setActionType(actionType, startPos)
    if actionType == "Curve" and not startPos then
        self.ActionType = "Common"
    else
        self.ActionType = actionType or "Common"
        self:setRootStartPos(startPos)
    end
end

function BaseLayer:setHasGuide(isHas)
    self.m_isHasGuide = isHas
end

--[[
    @desc: 添加播放动画的节点
    @name: 节点名
]]
function BaseLayer:addActionNodeName(name)
    if not name or type(name) ~= "string" then
        return
    end

    self.m_actionNodeNames[name] = true
end

-- 设置适配模式
function BaseLayer:setResolutionPolicy(policy)
    self.m_resolutionPolicy = policy or self.ResolutionPolicy.SHOW_ALL
end

-- 设置横屏csb
function BaseLayer:setLandscapeCsbName(csb)
    self.m_csbLandscape = csb
end

-- 设置竖屏csb
function BaseLayer:setPortraitCsbName(csb)
    self.m_csbPortrait = csb
end

-- 设置显示为竖屏界面
function BaseLayer:setShownAsPortrait(isPortrait)
    if isPortrait == nil then
        self.m_isShownAsPortrait = self.m_isShownAsPortrait or self:isPortraitScreen()
    else
        self.m_isShownAsPortrait = isPortrait or false
    end
end

-- 获取是否显示为竖版界面
function BaseLayer:isShownAsPortrait()
    return self.m_isShownAsPortrait
end

-- 设置自动缩放
function BaseLayer:setAutoScale(isAutoScale)
    if isAutoScale == nil then
        -- BaseView里面创建调用的，不执行后面的方法
        return
    end

    -- if self.m_isIgnoreAutoScale then
    --     -- 忽略自动缩放
    --     isAutoScale = false
    -- end

    self.m_isAutoScale = isAutoScale

    util_csbScale(self.m_csbNode, self:getUIScalePro())
end

function BaseLayer:isAutoScale()
    if self:isIgnoreAutoScale() then
        -- 忽略自动缩放
        return false
    end

    return self.m_isAutoScale
end

-- 获得Layer设计大小
function BaseLayer:_getLayerDesignSize()
    if self.m_isShownAsPortrait == self:isPortraitWindow() then
        return DESIGN_SIZE
    else
        return cc.size(DESIGN_SIZE.height, DESIGN_SIZE.width)
    end
end

-- 获得Layer显示大小
function BaseLayer:_getLayerDisplaySize(size)
    local _disSize = nil
    if not size then
        if self.m_isShownAsPortrait == self:isPortraitWindow() then
            _disSize = display.size
        else
            _disSize = cc.size(display.size.height, display.size.width)
        end
    else
        _disSize = size
    end

    -- 背景图片大小
    local _fsSize = self:_getFsBgSize()
    if _fsSize then
        -- 屏幕设计大小
        -- local _desgSize = self:_getLayerDesignSize()
        -- 屏幕大小
        local _disW = _disSize.width
        local _disH = _disSize.height

        local _fsW = _fsSize.width
        local _fsH = _fsSize.height
        -- 最终的屏幕大小
        local _finW = math.min(_disW, _fsW)
        local _finH = math.min(_disH, _fsH)

        return cc.size(_finW, _finH)
    else
        return _disSize
    end
end

-- 全屏背景大小
function BaseLayer:_getFsBgSize()
    local bgSize = nil
    local fs_bg = self:findChild("fs_bg")
    if fs_bg then
        bgSize = fs_bg:getContentSize()
    end
    return bgSize
end

-- 通过适配模式获得缩放值
function BaseLayer:getScaleByPolicy(scaleWidth, scaleHeight, resolutionPolicy)
    local _scale = 1
    if not resolutionPolicy or resolutionPolicy == self.ResolutionPolicy.SHOW_ALL then
        _scale = math.min(math.min(scaleWidth, scaleHeight), 1)
    elseif resolutionPolicy == self.ResolutionPolicy.FIXED_WIDTH then
        _scale = scaleWidth
    elseif resolutionPolicy == self.ResolutionPolicy.FIXED_HEIGHT then
        _scale = scaleHeight
    end
    return _scale
end

-- 不同大小layer缩放比例
function BaseLayer:_getScale(_size, _designSize)
    if not self:isAutoScale() then
        return 1
    else
        local scaleWidth = 1
        local scaleHeight = 1
        -- layer显示的横竖屏状态和当前屏幕横竖屏状态一致
        if self.m_isShownAsPortrait == self.m_usedPortraitCsb then
            -- 使用的资源也与layer显示的横竖屏状态一致
            scaleWidth = _size.width / _designSize.width
            scaleHeight = _size.height / _designSize.height
        else
            scaleWidth = _size.width / _designSize.height
            scaleHeight = _size.height / _designSize.width
        end

        return self:getScaleByPolicy(scaleWidth, scaleHeight, self.m_resolutionPolicy)
    end
end

-- 适配方案
function BaseLayer:getUIScalePro(_size)
    local _scale = 1
    local scaleWidth = 1
    local scaleHeight = 1
    local designSize = self:_getLayerDesignSize()
    _size = self:_getLayerDisplaySize(_size)

    -- local _getScale = function(_designSize)
    --     if not self:isAutoScale() then
    --         return 1
    --     else
    --         -- layer显示的横竖屏状态和当前屏幕横竖屏状态一致
    --         if self.m_isShownAsPortrait == self.m_usedPortraitCsb then
    --             -- 使用的资源也与layer显示的横竖屏状态一致
    --             scaleWidth = _size.width / _designSize.width
    --             scaleHeight = _size.height / _designSize.height
    --         else
    --             scaleWidth = _size.width / _designSize.height
    --             scaleHeight = _size.height / _designSize.width
    --         end
    --         -- return math.min(math.min(scaleWidth, scaleHeight), 1)
    --         return self:getScaleByPolicy(scaleWidth, scaleHeight, self.m_resolutionPolicy)
    --     end
    -- end

    -- 判断root节点
    local rootNode = self:findChild("root")
    if rootNode and tolua.type(rootNode) == "ccui.Layout" then
        local _rootSize = nil
        -- if not self.m_isShownAsPortrait then
        --     -- 横屏使用设计大小
        --     _rootSize = self:_getLayerDesignSize()
        -- else
        _rootSize = rootNode:getContentSize()
        -- end
        if not self.m_rootDesignSize then
            -- 设置root的初始设计大小
            self.m_rootDesignSize = _rootSize
        end
        -- if _rootSize.width ~= designSize.width or _rootSize.height ~= designSize.height then
        -- 初始root设计大小设置为设计分辨率，用于接下来的统一缩放判断
        designSize = self.m_rootDesignSize
        local isRootChanged = (_rootSize.width ~= _size.width) or (_rootSize.height ~= _size.height)
        if isRootChanged then
            local _scaleW = _size.width / designSize.width
            local _scaleH = _size.height / designSize.height
            if _scaleW ~= _scaleH then
                -- 横竖不等比，需要缩放
                self.m_isAutoScale = true

                -- 获得屏幕缩放
                if not self:isAutoScale() then
                    _scale = 1
                else
                    scaleWidth = _size.width / designSize.width
                    scaleHeight = _size.height / designSize.height
                    _scale = self:getScaleByPolicy(scaleWidth, scaleHeight, self.m_resolutionPolicy)
                end
            end

            -- 将root设置成屏幕大小
            rootNode:setContentSize(cc.size(_size.width / _scale, _size.height / _scale))
            -- 对root内的节点重新适配
            -- ccui.Helper:doLayout(rootNode)
            self.m_doLayoutNodeByOnEnter = rootNode
        else
            -- 获得屏幕缩放
            _scale = self:_getScale(_size, designSize)
        end
    else
        _scale = self:_getScale(_size, designSize)
    end

    return _scale
end

-- 修改显示区域大小
function BaseLayer:changeVisibleSize(_size)
    if not self.m_csbNode then
        return
    end
    -- 修改显示区域大小
    self.m_csbNode:setContentSize(_size)
    util_csbScale(self.m_csbNode, self:getUIScalePro(_size))

    if self:getParent() then
        -- 界面已经加载，立即刷新适配
        ccui.Helper:doLayout(self.m_csbNode)
    else
        self.m_doLayoutNodeByOnEnter = self.m_csbNode
    end
end

function BaseLayer:toDoLayout()
    if not tolua.isnull(self.m_doLayoutNodeByOnEnter) then
        ccui.Helper:doLayout(self.m_doLayoutNodeByOnEnter)
        self.m_doLayoutNodeByOnEnter = nil
    end
end

-- 设置是否暂停老虎机
function BaseLayer:setPauseSlotsEnabled(enabled)
    self.m_isPauseSlotsEnabled = enabled
end

-- 是否暂停老虎机
function BaseLayer:isPauseSlotsEnabled()
    return self.m_isPauseSlotsEnabled
end

-- 设置显示/弹出的场景/位置
function BaseLayer:setPosSite(site)
    self.m_popSite = site or ""
end

-- 设置大厅显示状态
function BaseLayer:setHideLobbyEnabled(isHide)
    self.m_isHideLobby = isHide
end

-- 是否显示大厅
function BaseLayer:isHideLobbyEnabled()
    return self.m_isHideLobby
end

-- 设置显示时背景透明度
function BaseLayer:setShowBgOpacity(value)
    value = value or 192
    self.m_maskBgOpacity = math.max(math.min(value, 255), 0)
    if self.m_baseMaskUI then
        self.m_baseMaskUI:setOpacity(value)
    end
end

-- 设置背景隐藏动画延时
function BaseLayer:setMaskHideDelay(delay)
    self.m_maskHideDelay = delay
end

-- 背景音乐路径
function BaseLayer:setBgm(path)
    if not path then
        return
    end
    if type(path) ~= "string" then
        assert(nil, "bgm path:" .. tostring(path) .. " is not string!!!")
        return
    end

    if not self.m_bgmEnabled then
        return
    end

    -- path = path or ""
    if self.m_bgmPath ~= nil and self.m_bgmPath ~= path then
        gLobalSoundManager:changeSubmodBgm(path, self.__cname, self:getLocalZOrder())
    end
    self.m_bgmPath = path
end

function BaseLayer:setBgmVolume(volume)
    local bgmPath = self:getBgMusicPath()
    if not bgmPath then
        return
    end

    gLobalSoundManager:setSubmodBgmVolume(volume, self.__cname)
end

function BaseLayer:getBgMusicPath()
    return self.m_bgmPath
end

function BaseLayer:setBgmEnabled(isEnabled)
    self.m_bgmEnabled = isEnabled
end

function BaseLayer:onEnter()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ENTER_LAYER, {cname = self.__cname, zOrder = self:getLocalZOrder()})
    BaseLayer.super.onEnter(self)
    if self._bCanAddKeyBack then
        globalEventKeyControl:addKeyBack(self)
    end
    self:toDoLayout()
    self:registerListener()
    if self:isShowActionEnabled() then
        -- 显示动画
        self:_addBlockMask()
        self.m_isShowing = true
        self:playShowAction()
    else
        self:maskShow(0)
        self:_onEnterOver()
    end

    if self:isPauseSlotsEnabled() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    end

    self:startBgm()
end

function BaseLayer:onEnterFinish()
    BaseLayer.super.onEnterFinish(self)
    self:updateAdaptiveInfos()
end

function BaseLayer:startBgm()
    -- 背景音乐
    local bgMusicPath = self:getBgMusicPath()
    if self.m_bgmEnabled and bgMusicPath then
        gLobalSoundManager:playSubmodBgm(bgMusicPath, self.__cname, self:getLocalZOrder())
    end
end

function BaseLayer:onExit()
    BaseLayer.super.onExit(self)
    globalEventKeyControl:removeKeyBack(self)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EXIT_LAYER, {cname = self.__cname, zOrder = self:getLocalZOrder()})
    -- if self:isPauseSlotsEnabled() and gLobalViewManager:isPauseAndResumeMachine(self) then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
    -- end
    self:removeBgm()
    self:initAdaptiveBandNodes()
end

function BaseLayer:removeBgm()
    -- 移除背景音乐
    local bgMusicPath = self:getBgMusicPath()
    if bgMusicPath then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESET_BG_MUSIC)
        gLobalSoundManager:removeSubmodBgm(self.__cname)
    end
end

function BaseLayer:onCleanup()
    BaseLayer.super.onCleanup(self)
    if self:isPauseSlotsEnabled() and gLobalViewManager:isPauseAndResumeMachine(self) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
    end

    if self.m_popSite == PopSite.Slot then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    elseif self.m_popSite == PopSite.Push then
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLEAN_UP_LAYER, {cname = self.__cname, zOrder = self:getLocalZOrder()})
end

-- 注册消息事件
function BaseLayer:registerListener()
    local _isPortrait = self:isPortraitWindow()
    if _isPortrait ~= self.m_isShownAsPortrait then
        gLobalNoticManager:addObserver(
            self,
            function()
                self:changeVisibleSize(display.size)
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end

    if self.m_isHasGuide then
        gLobalNoticManager:addObserver(
            self,
            function(target, params)
                params = params or {}
                local luaName = params.luaName or ""
                if luaName ~= self.__cname then
                    return
                end

                local stepId = params.stepId or ""
                local guideName = params.guideName or ""
                self:triggerGuideStep(guideName, stepId)
            end,
            "notify_doGuideStep"
        )

        gLobalNoticManager:addObserver(
            self,
            function(target, params)
                params = params or {}
                local luaName = params.luaName or ""
                if luaName ~= self.__cname then
                    return
                end
                local guideName = params.guideName or ""
                self:triggerGuideOverOfGuideName(guideName)
            end,
            "notify_GuideName_Over"
        )
    end

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:adaptivePos()
        end,
        ViewEventType.NOTIFY_ROTATE_SCREEN_COMPLETED
    )
end

function BaseLayer:triggerGuideStep(guideName, stepId)
end

function BaseLayer:triggerGuideOverOfGuideName(guideName)
end

--[[
    @desc: 添加阻塞遮罩
    author:{author}
    time:2021-02-06 20:46:55
    @return:
]]
function BaseLayer:_addBlockMask()
    local _blockMask, _ = self:getBlockMask()
    if tolua.isnull(_blockMask) then
        _blockMask = util_newMaskLayer()
        _blockMask:setOpacity(0)
        _blockMask:setName("BaseLayerMask")
        self:addChild(_blockMask, 9999)
        self:setBlockMaskCount(1)
    else
        self:changeBlockMaskCount(1)
    end
end

function BaseLayer:getBlockMask()
    return self:getChildByName("BaseLayerMask"), (self.m_maskRefCount or 0)
end

function BaseLayer:setBlockMaskCount(count)
    self.m_maskRefCount = math.max(0, (count or 0))
end

function BaseLayer:changeBlockMaskCount(num)
    self.m_maskRefCount = math.max(0, (self.m_maskRefCount or 0) + num)
end

--[[
    @desc: 移除阻塞遮罩
    author:{author}
    time:2021-02-06 20:48:47
    @return:
]]
function BaseLayer:_removeBlockMask()
    local _blockMask, _refCount = self:getBlockMask()
    if not tolua.isnull(_blockMask) then
        if _refCount > 1 then
            self:changeBlockMaskCount(-1)
        else
            _blockMask:removeFromParent()
            self:setBlockMaskCount(0)
        end
    end
end

--[[
    @desc: 播放显示动画
    author: 徐袁
    time: 2021-01-09 13:35:33
    @return: 
]]
function BaseLayer:playShowAction(userDefAction, ...)
    local className = self.__cname
    local callFunc = function()
        if not tolua.isnull(self) then
            self:showActionCallback()
            self:_onEnterOver()
        else
            -- local versionCode = 0
            -- if util_getUpdateVersionCode then
            --     versionCode = util_getUpdateVersionCode(false)
            -- end
            -- local errMsg = "V" .. tostring(versionCode) .. " 执行" .. className .. "的show回调时，C++对象被释放，请检查逻辑！！"
            -- gLobalBuglyControl:luaException(tostring(errMsg), debug.traceback())
            _sendLuaException("执行" .. className .. "的show回调时，C++对象被释放，请检查逻辑！！")
        end
    end

    if userDefAction and type(userDefAction) == "function" then
        local dt = unpack({...})
        self:maskShow(dt or (15 / 60))
        userDefAction(callFunc)
    elseif userDefAction and type(userDefAction) == "string" then
        local dt, fps = unpack({...})
        fps = fps or 60
        dt = dt or (15 / 60)
        self:maskShow(dt)
        self:runCsbAction(
            userDefAction,
            false,
            function()
                callFunc()
            end,
            fps
        )
    else
        for key, _ in pairs(self.m_actionNodeNames) do
            local keyNode = self:findChild(key)
            assert(keyNode, "通用动画必须有" .. key .. "根节点，请检查工程节点树！！！！")
            if keyNode then
                local _actionCallFunc = nil
                if key == "root" then
                    _actionCallFunc = function()
                        callFunc()
                    end
                end
                if self.ActionType == "Common" then
                    self:commonShow(keyNode, _actionCallFunc)
                elseif self.ActionType == "Curve" then
                    -- 曲线展示
                    self:curveShow(keyNode, _actionCallFunc)
                elseif self.ActionType == "Activity" then
                    self:activityShow(keyNode, _actionCallFunc)
                end
            end
        end
    end
end

--[[
    @desc: 显示动画回调
    author: 徐袁
    time: 2021-01-08 17:58:39
    @return: 
]]
function BaseLayer:showActionCallback()
    self.m_isShowing = false
    self:_removeBlockMask()
end

--[[
    @desc: layer显示完成的回调
    author: 徐袁
    time: 2021-03-17 16:07:26
    @return: 
]]
function BaseLayer:onShowedCallFunc()
end

function BaseLayer:_onEnterOver()
    -- 背景音乐
    -- local bgMusicPath = self:getBgMusicPath()
    -- if self.m_bgmEnabled and bgMusicPath then
    --     gLobalSoundManager:playSubmodBgm(bgMusicPath, self.__cname, self:getLocalZOrder())
    -- end

    self:onShowedCallFunc()

    if self.m_baseMaskUI then
        -- 有遮罩
        local _rootNode = self:findChild("root")
        if _rootNode and _rootNode.setSwallowTouches then
            -- 设置root层取消吞没事件
            _rootNode:setSwallowTouches(false)
        end
    end

    local isHideLobby = self:isHideLobbyEnabled()
    if isHideLobby then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_SHOW_VISIBLED, {isHideLobby = isHideLobby})
    end
end

function BaseLayer:isShowing()
    return self.m_isShowing
end

-- 显示背景遮罩
function BaseLayer:maskShow(time, opacity)
    if not self.m_isMaskEnabled then
        return
    end

    BaseLayer.super.maskShow(self, time, self.m_maskBgOpacity)
end

-- 隐藏背景遮罩
function BaseLayer:maskHide(time, opacity)
    if not self.m_isMaskEnabled then
        return
    end

    BaseLayer.super.maskHide(self, time, self.m_maskBgOpacity, self.m_maskHideDelay)
end

--[[
    @desc: 播放隐藏动画
    author: 徐袁
    time: 2021-01-09 13:35:57
    @userDefAction: 用户自定义动画
    @return: 
]]
function BaseLayer:playHideAction(userDefAction, ...)
    local className = self.__cname
    local callFunc = function()
        if not tolua.isnull(self) then
            self:hideActionCallback()
            if not tolua.isnull(self) then
                self:removeFromParent()
            else
                local errMsg = "执行" .. tostring(className) .. "的 removeFromParent 时，C++对象被释放，请检查逻辑！！"
                _sendLuaException(errMsg)
            end
        else
            local errMsg = "执行" .. tostring(className) .. "的 hide 回调时，C++对象被释放，请检查逻辑！！"
            _sendLuaException(errMsg)
        end
    end

    if userDefAction and type(userDefAction) == "function" then
        local dt = unpack({...})
        self:maskHide(dt or (15 / 60))
        -- 执行用户自定义动画
        userDefAction(callFunc)
    elseif userDefAction and type(userDefAction) == "string" then
        local dt, fps = unpack({...})
        fps = fps or 60
        dt = dt or (15 / 60)
        self:maskHide(dt)
        -- 执行用户自定义动画
        self:runCsbAction(
            userDefAction,
            false,
            function()
                callFunc()
            end,
            fps
        )
    else
        for key, _ in pairs(self.m_actionNodeNames) do
            local keyNode = self:findChild(key)
            assert(keyNode, "通用动画必须有" .. key .. "根节点，请检查工程节点树！！！！")
            if keyNode then
                local _actionCallFunc = nil
                if key == "root" then
                    _actionCallFunc = function()
                        callFunc()
                    end
                end

                if self.ActionType == "Common" or self.ActionType == "Curve" then
                    self:commonHide(keyNode, _actionCallFunc)
                elseif self.ActionType == "Activity" then
                    self:activityHide(keyNode, _actionCallFunc)
                end
            end
        end
    end
end

--[[
    @desc: 隐藏动画回调
    author: 徐袁
    time: 2021-01-08 17:59:15
    @return: 
]]
function BaseLayer:hideActionCallback()
    self:_removeBlockMask()
    if self.m_hideCallbackFunc then
        if type(self.m_hideCallbackFunc) == "function" then
            self.m_hideCallbackFunc()
            self.m_hideCallbackFunc = nil
        else
            local className = self.__cname
            local errMsg = tostring(className) .. "的 hideCallback 类型不是function，请检查上层逻辑！！"
            _sendLuaException(errMsg)
        end
    end
    self.m_isHiding = false
end

function BaseLayer:isHiding()
    return self.m_isHiding
end

--[[
    @desc: 关闭界面
    author: 徐袁
    time: 2021-01-09 13:24:44
    --@callbackFunc: 关闭layer回调
    @return: 
]]
function BaseLayer:closeUI(callbackFunc)
    if self:isHiding() then
        return
    end

    local isHideLobby = self:isHideLobbyEnabled()
    if isHideLobby then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_SHOW_VISIBLED, {isHideLobby = (not isHideLobby)})
    end

    if self:isHideActionEnabled() then
        self:_addBlockMask()
        self.m_isHiding = true
        -- 有关闭动画提前清除注册事件
        -- gLobalNoticManager:removeAllObservers(self)

        if callbackFunc then
            self.m_hideCallbackFunc = callbackFunc
        end
        self:playHideAction()
    else
        self:maskHide(0)
        -- 处理callbackFunc可能重复调用自身closeUI的情况
        self.m_isHiding = true
        if callbackFunc then
            callbackFunc()
        end
        self.m_isHiding = false

        if not tolua.isnull(self) then
            self:removeFromParent()
        else
            local errMsg = "执行 removeFromParent 时，C++对象被释放，请检查逻辑！！"
            _sendLuaException(errMsg)
        end
    end
end

function BaseLayer:removeFromParent(...)
    if DEBUG == 2 and self:isShowing() then
        local className = self.__cname or ""
        local errMsg = tostring(className) .. " is play showing, removeFromParent will go error!!"
        _sendLuaException(errMsg)
    end

    if not tolua.isnull(self) then
        BaseLayer.super.removeFromParent(self, ...)
    else
        -- assert(nil, "重复调用" .. className .. "的removeFromParent，请检查上层逻辑！！")
    end
end

-- 获得的关闭按钮
function BaseLayer:getBtnClose()
    return nil
end

-- 是否启用返回键功能
function BaseLayer:setKeyBackEnabled(isEnabled)
    self.m_isKeyBackEnabled = isEnabled
end

function BaseLayer:isKeyBackEnabled()
    return self.m_isKeyBackEnabled
end

-- 设置界面是否可以相应 onKeyBack
function BaseView:setCanAddKeyBack(_bCanOnKeyBack)
    self._bCanAddKeyBack = _bCanOnKeyBack
end

-- 是否添加遮罩
function BaseLayer:setMaskEnabled(isEnabled)
    self.m_isMaskEnabled = isEnabled
end

function BaseLayer:isMaskEnabled(isEnabled)
    return self.m_isMaskEnabled
end

-- 忽略缩放
function BaseLayer:setIgnoreAutoScale(isIgnore)
    self.m_isIgnoreAutoScale = isIgnore or false
end

function BaseLayer:isIgnoreAutoScale()
    return self.m_isIgnoreAutoScale
end

-- 系统返回键调用
function BaseLayer:onKeyBack(callbackFunc)
    if not self:isKeyBackEnabled() then
        return
    end

    if self:isShowing() or self:isHiding() then
        return
    end

    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        if callbackFunc then
            callbackFunc()
        end
    end
    self:closeUI(callFunc)
end

--[[
    设置需要适配的节点
    _bangPos: 刘海位置
        BANG_POS.TOP - 上边, 
        BANG_POS.BOTTOM - 下边, 
        BANG_POS.LEFT - 左边, 
        BANG_POS.RIGHT - 右边

]]
function BaseLayer:setAdaptiveNodes(_nodes, _bangPos)
    -- 添加到适配列表
    self.m_needAdaptiveBang = true
    local nodes = _nodes or {}
    for i, v in ipairs(nodes) do
        local x, y = v:getPosition()
        local info = {apNode = v, initX = x, initY = y}
        table.insert(self.m_needAdaptiveBangNodes[_bangPos], info)
    end
end
-- 更新适配刘海的节点信息
function BaseLayer:updateAdaptiveInfos()
    if not self.m_needAdaptiveBang then
        return
    end

    for i = 1, 4 do
        local infoList = self.m_needAdaptiveBangNodes[i] or {}

        for _, v in ipairs(infoList) do
            local _node = v.apNode
            if not tolua.isnull(_node) then
                local _x, _y = _node:getPosition()
                v.initX = _x
                v.initY = _y
            end
        end
    end
end

-- 刘海屏适配
function BaseLayer:bangScreenAdaptive()
    if not self.m_needAdaptiveBang then
        return
    end

    local height = util_getBangScreenHeight()
    local areaInfoList, oriState = util_getSafeAreaInfoList()
    local state = tonumber(oriState or 0)
    -- local height = tonumber(areaInfoList[state] or 0)
    if height > 0 then
        for i = 1, 4 do
            local infoList = self.m_needAdaptiveBangNodes[i] or {}
            local offsetX = 0
            local offsetY = 0
            if i == state then
                if i == BANG_POS.TOP then
                    offsetY = -height
                elseif i == BANG_POS.BOTTOM then
                    offsetY = height
                elseif i == BANG_POS.LEFT then
                    offsetX = height
                elseif i == BANG_POS.RIGHT then
                    offsetX = -height
                end
            end

            for _, v in ipairs(infoList) do
                local _node = v.apNode
                if not tolua.isnull(_node) then
                    _node:setPosition(v.initX + offsetX, v.initY + offsetY)
                end
            end
        end
    end
end

function BaseLayer:adaptivePos()
    self:bangScreenAdaptive()
end

-- 设置自动关闭界面(autoCloseTime默认5秒)
function BaseLayer:setAutoCloseUI(_autoCloseTime, _onTick, _autoCloseFunc)
    local autoCloseTime = _autoCloseTime or 5
    local onTick = _onTick or function()
        end
    local autoCloseFunc = _autoCloseFunc or function()
        end
    local onAutoCloseFunc = function()
        onTick(autoCloseTime)
        autoCloseTime = autoCloseTime - 1
        if autoCloseTime < 0 then
            autoCloseFunc()
        end
    end
    onAutoCloseFunc()
    self.m_autoCloseUITimer = schedule(self, onAutoCloseFunc, 1)
    local mask = util_newMaskLayer()
    mask:setOpacity(0)
    self:addChild(mask, 999)
    mask:onTouch(
        function(event)
            if event.name == "began" then
                self:stopAutoCloseUITimer()
                if not tolua.isnull(mask) then
                    mask:removeFromParent()
                end
            end
            return true
        end,
        false,
        false
    )
end

function BaseLayer:stopAutoCloseUITimer()
    if self.m_autoCloseUITimer then
        self:stopAction(self.m_autoCloseUITimer)
        self.m_autoCloseUITimer = nil
    end
end

return BaseLayer
