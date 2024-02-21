--
--CSB 界面父类
--
local ResCacheMgr = require("GameInit.ResCacheMgr.ResCacheMgr")
local BaseView = class("BaseView", cc.Node)
BaseView.m_baseFilePath = nil
BaseView.m_baseData = nil
BaseView.m_csbNode = nil
BaseView.m_csbAct = nil
BaseView.m_csbOwner = nil
BaseView.m_overFunc = nil
BaseView.m_isCsbPathLog = true --是否打印创建的csb 路径
BaseView.m_isShowActionEnabled = true
BaseView.m_isHideActionEnabled = true

function BaseView:ctor()
    self.m_isShowActionEnabled = true
    self.m_isHideActionEnabled = true

    -- root节点开始位置
    self.m_rootStartPos = nil

    self.m_buttonStatusList = {}

    self.m_plistInfos = {}

    self.m_clickSounds = {}
    -- 默认关闭音效
    self:addClickSound({"btn_close", "btnClose", "Button_close"}, SOUND_ENUM.SOUND_HIDE_VIEW)

    self:initBaseView()
end

function BaseView:insertPlistInfo(path)
    if type(path) ~= "string" then
        return
    end

    local _mgr = ResCacheMgr:getInstance()
    if _mgr then
        _mgr:insertPlistInfo(path)
        table.insert(self.m_plistInfos, path)
    end
end

function BaseView:mergePlistInfos(tbPath)
    if type(tbPath) ~= "table" then
        return
    end

    local _mgr = ResCacheMgr:getInstance()
    if _mgr then
        _mgr:mergePlistInfos(tbPath)
        table.insertto(self.m_plistInfos, tbPath)
    end
end

function BaseView:clearPlists()
    local _mgr = ResCacheMgr:getInstance()
    if _mgr then
        for i = 1, #self.m_plistInfos do
            _mgr:removeRes(self.m_plistInfos[i])
        end
        self.m_plistInfos = {}
    end
end

--清理资源目前没有调用
function BaseView:purge()
    self.m_csbOwner = nil
end
--初始化数据 通过 util_createView 创建的view会自动调用
function BaseView:initData_(...)
    self.m_baseData = {...}
    if self.initDatas then
        self:initDatas(...)
    end
    if self.initUI then
        self:initUI(...)
    end
end

function BaseView:initDatas(...)
end

function BaseView:initUI(...)
    local _csb = self:getCsbName()
    if _csb then
        self:createCsbNode(_csb)
    end
end

function BaseView:initBaseView()
    self:registerScriptHandler(
        function(event)
            if tolua.isnull(self) then
                return
            end
            if event == "enter" then
                if self.onBaseEnter then
                    self:onBaseEnter()
                end
            elseif event == "exit" then
                if self.onBaseExit then
                    self:onBaseExit()
                end
            elseif event == "cleanup" then
                self:onCleanup()
            elseif event == "exitTransitionStart" then
                self:onExitStart()
            elseif event == "enterTransitionFinish" then
                self:onEnterFinish()
                self:adaptivePos()
            end
        end
    )
    self.m_csbOwner = {}
end

--窗口关闭时的回调
function BaseView:setOverFunc(func)
    if isMac() then
        if self.m_overFunc then
            assert(nil, "overFunc has existed!!!!")
        end
    end
    self.m_overFunc = func
end

function BaseView:onBaseEnter()
    self:initSpineUI()
    if self.onEnter then
        self:onEnter()
    end
end

function BaseView:initSpineUI()
    
end

function BaseView:onEnterFinish()

end

function BaseView:onExitStart()

end

function BaseView:adaptivePos()
    
end

function BaseView:onBaseExit()
    -- globalEventKeyControl:removeKeyBack(self)
    if self.onHangExit then
        self:onHangExit()
    end
    --外挂的退出接口
    if self.onExit then
        self:onExit()
    end
    -- if self.m_overFunc then
    --     self.m_overFunc()
    --     self.m_overFunc = nil
    -- end
end

function BaseView:onEnter()
end

function BaseView:onExit()
    self:clearPlists()
    gLobalNoticManager:removeAllObservers(self)
end

function BaseView:setVisible(isVisible)
    cc.Node.setVisible(self, isVisible)
end

function BaseView:removeFromParent(...)
    if tolua.isnull(self) then
        return
    end
    if self.m_overFunc then
        self.m_overFunc()
        self.m_overFunc = nil
    end

    cc.Node.removeFromParent(self, ...)
end

function BaseView:onCleanup()
    
end

--绑定csbOwner 与按钮监听
function BaseView:bindingEvent(root)
    if not root then
        return
    end

    --绑定按钮监听
    if tolua.type(root) == "ccui.Button" then
        if root:getName() == "commonButton" and root:getParent() then
            root:setName(root:getParent():getName())
            self:bindingDefaultButtonLabel(root)
        end
        self:addClick(root)
    elseif tolua.type(root) == "ccui.ListView" and root.onUpdateCheckVisible then
        root:onUpdateCheckVisible()
    end

    local name = root:getName()
    self.m_csbOwner[name] = root

    local child_list = root:getChildren()
    for _, node in pairs(child_list) do
        self:bindingEvent(node)
    end
end

function BaseView:setSwallowTouches(flag, btnFlag, root)
    local root = root or self.m_csbNode
    if not root then
        return
    end

    if root.setSwallowTouches and (root.isTouchEnabled and root:isTouchEnabled()) and (btnFlag or tolua.type(root) ~= "ccui.Button") then
        root:setSwallowTouches(flag)
    end

    local child_list = root:getChildren()
    for _, node in pairs(child_list) do
        self:setSwallowTouches(flag, btnFlag, node)
    end
end

--创建csb节点
function BaseView:createCsbNode(filePath, isAutoScale)
    self.m_baseFilePath = filePath
    local fullPath = cc.FileUtils:getInstance():fullPathForFilename(filePath)
    -- print("fullPath =".. fullPath)

    self.m_csbNode, self.m_csbAct = util_csbCreate(self.m_baseFilePath, self.m_isCsbPathLog)
    self:addChild(self.m_csbNode)
    self:bindingEvent(self.m_csbNode)
    self:pauseForIndex(0)
    self:setAutoScale(isAutoScale)

    self:initCsbNodes()
end

-- 设置自动缩放
function BaseView:setAutoScale(isAutoScale)
    self.m_isAutoScale = isAutoScale
    if isAutoScale then
        -- if tolua.type(self.m_csbNode)=="cc.Layer" then
        util_csbScale(self.m_csbNode, self:getUIScalePro())
    -- end
    end
end

-- 初始化节点
function BaseView:initCsbNodes()
end

-- 设置自动缩放
function BaseView:setAutoScaleEnabled(flag)
    if flag then
        util_csbScale(self.m_csbNode, self:getUIScalePro())
    else
        util_csbScale(self.m_csbNode, 1)
    end
    self.m_isAutoScale = flag
end

-- 修改显示区域大小
function BaseView:changeVisibleSize(_size)
    if not self.m_csbNode then
        return
    end
    -- 修改显示区域大小
    self.m_csbNode:setContentSize(_size)
    -- 刷新适配
    ccui.Helper:doLayout(self.m_csbNode)
end

-- 通用展示音效
function BaseView:setCommonShowSound(_path)
    self.m_commonShowSound = _path
end

--通用展示
--放大和渐隐出现
function BaseView:commonShow(root, doFunc)
    if self.m_isShowActionEnabled and root then
        local soundPath = self.m_commonShowSound or "Sounds/soundOpenView.mp3"
        gLobalSoundManager:playSound(soundPath)

        util_setCascadeOpacityEnabledRescursion(root, true)

        local scale = root:getScale()
        root:setScale(0.8 * scale)

        local actionList = {}
        -- actionList[#actionList + 1] = cc.EaseSineInOut:create(cc.ScaleTo:create(14 / 60, scale * 1.1))
        -- actionList[#actionList + 1] = cc.EaseSineIn:create(cc.ScaleTo:create(6 / 60, scale * 0.95))
        -- actionList[#actionList + 1] = cc.EaseSineOut:create(cc.ScaleTo:create(8 / 60, scale))
        actionList[#actionList + 1] = cc.EaseSineInOut:create(cc.ScaleTo:create(12 / 60, scale * 1.02))
        actionList[#actionList + 1] = cc.EaseSineInOut:create(cc.ScaleTo:create(8 / 60, scale * 0.99))
        actionList[#actionList + 1] = cc.ScaleTo:create(6 / 60, scale)
        if doFunc then
            actionList[#actionList + 1] = cc.CallFunc:create(doFunc)
        end
        local seq = cc.Sequence:create(actionList)
        root:runAction(seq)

        root:setOpacity(0)
        local actionList2 = {}
        actionList2[#actionList2 + 1] = cc.FadeTo:create(10 / 60, 255)
        local seq2 = cc.Sequence:create(actionList2)
        root:runAction(seq2)

        self:maskShow(20 / 60)
    else
        if doFunc then
            doFunc()
        end
    end
end

--通用隐藏
function BaseView:commonHide(root, doFunc)
    if self.m_isHideActionEnabled and root then
        -- gLobalSoundManager:playSound("Sounds/soundHideView.mp3")

        util_setCascadeOpacityEnabledRescursion(root, true)
        -- 缩放界面的时候,不应该让子节点透明度全都恢复成255,只保留跟随就行了 -csc 2020年11月27日18:21:50
        -- util_setChildNodeOpacity(root,255)
        local scale = root:getScale()
        local actionList = {}
        actionList[#actionList + 1] = cc.EaseSineOut:create(cc.ScaleTo:create(6 / 60, scale * 1.02))
        -- actionList[#actionList + 1] = cc.ScaleTo:create(10 / 60, scale * 1.1)
        local act1 = cc.EaseSineInOut:create(cc.ScaleTo:create(14 / 60, scale * 0.9))
        local act2 = cc.FadeTo:create(10 / 60, 0)
        local delay = cc.DelayTime:create(4 / 60)
        local delaySeq = cc.Sequence:create(delay, act2)
        actionList[#actionList + 1] = cc.Spawn:create(act1, delaySeq)
        if doFunc then
            actionList[#actionList + 1] = cc.CallFunc:create(doFunc)
        end
        local seq = cc.Sequence:create(actionList)
        root:runAction(seq)
        self:maskHide(12 / 60)
    else
        if doFunc then
            doFunc()
        end
    end
end

-- 设置root开始坐标
function BaseView:setRootStartPos(startPos)
    if not startPos then
        return
    end

    self.m_rootStartPos = startPos
end

-- 曲线展示效果
function BaseView:curveShow(root, doFunc)
    if self.m_isShowActionEnabled and root then
        if not self.m_rootStartPos then
            self:commonShow(root, doFunc)
            return
        end
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")

        util_setCascadeOpacityEnabledRescursion(root, true)

        local scale = root:getScale()
        -- 初始化缩放h和坐标
        root:setScale(0.3 * scale)
        -- 设置界面开始位置
        root:setPosition(self.m_rootStartPos)

        local moveToAct = cc.EaseQuinticActionOut:create(cc.MoveTo:create(22 / 60, display.center))
        local scaleToAct = cc.EaseCircleActionOut:create(cc.ScaleTo:create(22 / 60, scale))

        local actionList = {}
        actionList[#actionList + 1] = cc.Spawn:create(moveToAct, scaleToAct)
        -- actionList[#actionList + 1] = cc.ScaleTo:create(14 / 60, scale)
        if doFunc then
            actionList[#actionList + 1] = cc.CallFunc:create(doFunc)
        end
        local seq = cc.Sequence:create(actionList)
        root:runAction(seq)

        root:setOpacity(0)
        local actionList2 = {}
        actionList2[#actionList2 + 1] = cc.FadeTo:create(22 / 60, 255)
        local seq2 = cc.Sequence:create(actionList2)
        root:runAction(seq2)

        self:maskShow(22 / 60)
    else
        if doFunc then
            doFunc()
        end
    end
end

-- 设置开启弹板打开动画
function BaseView:setShowActionEnabled(flag)
    self.m_isShowActionEnabled = flag
end

function BaseView:isShowActionEnabled()
    return self.m_isShowActionEnabled
end

-- 设置开启弹板关闭动画
function BaseView:setHideActionEnabled(flag)
    self.m_isHideActionEnabled = flag
end

function BaseView:isHideActionEnabled()
    return self.m_isHideActionEnabled
end

--通用展示
--活动界面出现方式
function BaseView:activityShow(root, doFunc)
    if self.m_isShowActionEnabled and root then
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")

        local scale = root:getScale()
        root:setScale(0.01)
        local actionList = {}
        actionList[#actionList + 1] = cc.EaseSineIn:create(cc.ScaleTo:create(15 / 60, scale * 1.1))
        actionList[#actionList + 1] = cc.DelayTime:create(1 / 60)
        actionList[#actionList + 1] = cc.EaseSineOut:create(cc.ScaleTo:create(6 / 60, scale))
        if doFunc then
            actionList[#actionList + 1] = cc.CallFunc:create(doFunc)
        end
        local seq = cc.Sequence:create(actionList)
        -- root:runAction(seq)

        util_setCascadeOpacityEnabledRescursion(root, true)
        root:setOpacity(0)
        local actionList2 = {}
        actionList2[#actionList2 + 1] = cc.FadeTo:create(15 / 60, 255)
        local seq2 = cc.Sequence:create(actionList2)
        -- root:runAction(seq2)
        local spawn = cc.Spawn:create(seq, seq2)
        root:runAction(spawn)

        self:maskShow(15 / 60)
    else
        if doFunc then
            doFunc()
        end
    end
end

--通用隐藏
--活动类弹板隐藏方式
function BaseView:activityHide(root, doFunc)
    if self.m_isHideActionEnabled and root then
        -- gLobalSoundManager:playSound("Sounds/soundHideView.mp3")

        local scale = root:getScale()
        local actionList = {}
        actionList[#actionList + 1] = cc.EaseQuarticActionIn:create(cc.ScaleTo:create(16 / 60, scale * 0.65))
        if doFunc then
            actionList[#actionList + 1] = cc.CallFunc:create(doFunc)
        end
        local seq = cc.Sequence:create(actionList)
        -- root:runAction(seq)

        util_setCascadeOpacityEnabledRescursion(root, true)
        -- root:setOpacity(255)
        local actionList2 = {}
        actionList2[#actionList2 + 1] = cc.DelayTime:create(5 / 60)
        actionList2[#actionList2 + 1] = cc.FadeOut:create(10 / 60)
        local seq2 = cc.Sequence:create(actionList2)
        local spawn = cc.Spawn:create(seq, seq2)
        root:runAction(spawn)
        self:maskHide(15 / 60)
    else
        if doFunc then
            doFunc()
        end
    end
end

--遮罩显示
function BaseView:maskShow(time, opacity)
    opacity = opacity or 192
    time = time or 0

    self.m_baseMaskUI = util_newMaskLayer()
    if self.m_baseMaskUI then
        self.m_baseMaskUI:onTouch(
            function(event)
                if event.name == "ended" then
                    if self.onClickMask then
                        self:onClickMask(cc.p(event.x, event.y))
                    end
                end
                return true
            end,
            false,
            true
        )
        self:addChild(self.m_baseMaskUI, -1)
        if time > 0 then
            self.m_baseMaskUI:setOpacity(0)
            local actionList = {}
            actionList[#actionList + 1] = cc.FadeTo:create(time, opacity)
            local seq = cc.Sequence:create(actionList)
            self.m_baseMaskUI:runAction(seq)
        else
            self.m_baseMaskUI:setOpacity(opacity)
        end
    end
end

--遮罩隐藏
function BaseView:maskHide(time, opacity, delay)
    if self.m_baseMaskUI then
        opacity = opacity or 192
        time = time or 0
        delay = delay or 0

        self.m_baseMaskUI:onTouch(
            function(event)
                return true
            end,
            false,
            true
        )
        addExitListenerNode(
            self.m_baseMaskUI,
            function()
                self.m_baseMaskUI = nil
            end
        )
        if time > 0 or delay > 0 then
            self.m_baseMaskUI:setOpacity(opacity)
            local actionList = {}
            if delay > 0 then
                actionList[#actionList + 1] = cc.DelayTime:create(delay)
            end
            actionList[#actionList + 1] = cc.FadeTo:create(time, 0)
            local seq = cc.Sequence:create(actionList)
            self.m_baseMaskUI:runAction(seq)
        else
            self.m_baseMaskUI:setOpacity(0)
        end
    end
end

--[[
    @desc: 背景遮罩触摸
    author:{author}
    time:2022-03-02 17:47:39
    @return:
]]
function BaseView:onClickMask(pos)
end

--设置缩放使用最大或者最小
function BaseView:setScaleForResolution(min)
    local x = display.width / DESIGN_SIZE.width
    local y = display.height / DESIGN_SIZE.height
    local pro = x / y
    local scale = 1
    if min then
        scale = math.min(x, y)
    else
        scale = math.max(x, y)
    end
    self.m_csbNode:setScale(scale)
end

--获取csbNode缩放大小
function BaseView:getCsbNodeScale()
    return self.m_csbNode:getScale()
end

function BaseView:setCsbNodeScale(scale)
    self.m_csbNode:setScale(scale)
end

--适配方案
function BaseView:getUIScalePro()
    local x = display.width / DESIGN_SIZE.width
    local y = display.height / DESIGN_SIZE.height
    local pro = x / y
    if globalData.slotRunData.isPortrait == true then
        pro = 0.7
    -- pro = display.height/DESIGN_SIZE.height
    -- if pro > 1 then
    --     pro = 1
    -- end
    end
    return pro
end
--播放动画
function BaseView:runCsbAction(key, loop, func, fps)
    util_csbPlayForKey(self.m_csbAct, key, loop, func, fps)
end

--循环播放间隔走配置
function BaseView:runCsbLoopAction(key, interval, fps)
    local function callback()
        util_csbPlayForKey(self.m_csbAct, key, false, nil, fps)
    end

    local delay = cc.Sequence:create(cc.CallFunc:create(callback), cc.DelayTime:create(interval))
    self:runAction(cc.RepeatForever:create(delay))
end

--暂停到某一帧
function BaseView:pauseForIndex(index)
    if not index then
        index = 0
    end
    util_csbPauseForIndex(self.m_csbAct, index)
end
--根据名称寻找子节点
function BaseView:findChild(name)
    return self.m_csbOwner[name]
end
--添加按钮监听ccui.Button自动添加layout 或图片需要手动添加
function BaseView:addClick(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.baseTouchEvent))
end

--调整label大小 info={label=cc.label,sx=1,sy=1} length=宽度限制 otherInfo={info1,info2,info3,...}
function BaseView:updateLabelSize(info, length, otherInfo)
    local _label = info.label
    if _label.mulNode then
        _label = _label.mulNode
    end
    local width = _label:getContentSize().width
    local scale = length / width
    if width <= length then
        scale = 1
    end

    _label:setScaleX(scale * (info.sx or 1))
    _label:setScaleY(scale * (info.sy or 1))
    if otherInfo and #otherInfo > 0 then
        for k, orInfo in ipairs(otherInfo) do
            orInfo.label:setScaleX(scale * (orInfo.sx or 1))
            orInfo.label:setScaleY(scale * (orInfo.sy or 1))
        end
    end
end

function BaseView:closeUI()
end

function BaseView:hidePartiicles(node_name)
    if not node_name then
        for i, node in pairs(self.m_csbOwner) do
            if not tolua.isnull(node) and node[".classname"] == "cc.ParticleSystemQuad" then
                node:setVisible(false)
            end
        end
    else
        local node = self:findChild(node_name)
        if not tolua.isnull(node) and node[".classname"] == "cc.ParticleSystemQuad" then
            node:setVisible(false)
        end
    end
end

--点击监听
function BaseView:clickStartFunc(sender)
end
--移动监听
function BaseView:clickMoveFunc(sender)
end
--结束监听
function BaseView:clickEndFunc(sender)
end

--默认按钮监听回调
function BaseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

--[[
    @desc: 添加点击音效
    author:{author}
    time:2022-08-09 15:16:41
    --@btnName:
	--@soundPath: 
    @return:
]]
function BaseView:setClickSound(clickName, soundPath)
    self:addClickSound(clickName, soundPath)
end
function BaseView:addClickSound(clickName, soundPath)
    clickName = clickName or ""
    soundPath = soundPath or ""
    if clickName == "" or soundPath == "" then
        return
    end
    if type(clickName) == "string" then
        self.m_clickSounds[clickName] = soundPath
    elseif type(clickName) == "table" then
        for _, _val in ipairs(clickName) do
            self.m_clickSounds["" .. _val] = soundPath
        end
    end
end

function BaseView:clickSound(sender)
    local name = sender:getName()
    local soundPath = self.m_clickSounds[name] or ""
    if soundPath ~= "" then
        gLobalSoundManager:playSound(soundPath)
    end
end

function BaseView:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:setButtonStatusByBegan(sender)
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:setButtonStatusByMoved(sender)
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc then
            return
        end
        self:setButtonStatusByEnd(sender)
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        local offy = math.abs(endPos.y - beginPos.y)
        if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil then
            self:clickSound(sender)
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickEndFunc then
            return
        end
        self:clickEndFunc(sender, eventType)
    end
end
--更新属性
function BaseView:updateOwnerVar(ownerlist)
    if not ownerlist or type(ownerlist) ~= "table" then
        return
    end
    for ownerKey, value in pairs(ownerlist) do
        local ccbOwnerNode = self.m_csbOwner[ownerKey]
        if ccbOwnerNode then
            self:setOwnerForType(ccbOwnerNode, value)
        else
            print("updateOwnerVar not key=" .. ownerKey)
        end
    end
end
--设置属性
function BaseView:setOwnerForType(node, value)
    if tolua.type(node) == "cc.Label" or tolua.type(node) == "ccui.TextBMFont" or tolua.type(node) == "ccui.Text" or tolua.type(node) == "ccui.TextAtlas" then
        node:setString(value)
    end
    if tolua.type(node) == "cc.Node" then
        node:addChild(value)
    end
end

function BaseView:setExtendData(data)
    self.extendData = data
end

function BaseView:getExtendData()
    return self.extendData
end

--csb名称，用来动态下载的文件是否存在
function BaseView:getCsbName()
    return nil
end

function BaseView:isCsbExist()
    local csbName = self:getCsbName()
    return csbName ~= nil and util_IsFileExist(csbName)
end

function BaseView:getRotateBackScaleFlag()
    return true
end

function BaseView:setCloseVisible(flag)
    if self.m_btnClose then
        self.m_btnClose:setVisible(flag)
    end
end

----------------------------- 按钮统一化功能  S ----------------------
--[[
    @desc: 外部接口, 用于设置按钮显示图片
    --@_buttonName: 按钮名称
    --@_imageName: 图片资源路径
]]
function BaseView:setButtonImage(_buttonName, _imageName)
    if self.m_buttonStatusList[_buttonName] and util_IsFileExist(_imageName) then
        local button = self.m_buttonStatusList[_buttonName].button
        button:loadTextureNormal(_imageName)
        button:loadTexturePressed(_imageName)

        local param = self.m_buttonStatusList[_buttonName].param
        if param.sp_clip and param.sp_clip.node then
            util_changeTexture(param.sp_clip.node, _imageName)
            param.sp_clip.node:setContentSize(button:getContentSize())
            param.mask = nil
        end
    end
end
--[[
    @desc: 外部接口, 用于开启按钮序列帧动画
    --@_buttonName: 按钮名称
    --@_animationName: 序列帧动画名称(默认：idle)
    --@_loop: 是否循环
]]
function BaseView:startButtonAnimation(_buttonName, _animationName, _loop)
    if self.m_buttonStatusList[_buttonName] then
        local button = self.m_buttonStatusList[_buttonName].button
        if _animationName == "breathe" then
            local parent = button:getParent()
            local action1 = cc.ScaleTo:create(1, 1.05)
            local action2 = cc.ScaleTo:create(1, 1)
            local sequence = cc.Sequence:create({action1, action2})
            local action = cc.EaseInOut:create(sequence, 1)
            parent:runAction(cc.RepeatForever:create(action))
        else
            local animName = _animationName or "idle"
            local loop = _loop == nil and true or _loop
            local parent = button:getParent()
            if parent then
                local act = parent:getActionByTag(parent:getTag())
                act:play(animName, loop)
            end
        end
    end
end
--[[
    @desc: 外部接口, 设置按钮文本
    --@_buttonName: 按钮名称
    --@_content: 文本内容
    --@_labelName: 文本节点名称(默认 label_1)
]]
function BaseView:setButtonLabelContent(_buttonName, _content, _labelName, _noTrim)
    if self.m_buttonStatusList[_buttonName] == nil then
        return
    end

    local button = self.m_buttonStatusList[_buttonName].button
    local buttonSize = button:getContentSize()
    local param = self.m_buttonStatusList[_buttonName].param
    local labelName = _labelName or "label_1"
    local labelInfo = param[labelName]
    if labelInfo then
        local lineNum = util_AutoLine(labelInfo.node, _content, buttonSize.width * 0.9, true, _noTrim)
        local labelHeight = labelInfo.node:getContentSize().height
        if lineNum > 1 then
            local config = labelInfo.node:getVirtualRenderer():getTTFConfig()
            labelInfo.node:getVirtualRenderer():setLineHeight(config.fontSize * 0.8)
            labelHeight = labelHeight * 0.8
            labelInfo.node:setPositionY(labelInfo.node:getPositionY() + labelHeight * 0.2 / lineNum)
        end
        if labelHeight > buttonSize.height * 0.9 then
            labelInfo.node:setScale(buttonSize.height * 0.9 / labelHeight)
        end
        if param.button_icon then
            self:iconLabelAlignCenter(param.button_icon.node, labelInfo.node)
        end
    end
end
--[[
    @desc: 外部接口, 设置按钮是否启用状态
    --@_buttonName:按钮名称
	--@_enabled: 启用状态
	--@_labelParams: 自定义文字属性(一个table)(TextBMFont类型只需 textColor) 
    {
        textColor    -- 文本颜色
        shadowColor  -- 阴影颜色
        shadowOffset -- 阴影偏移量
        outlineColor -- 描边颜色
        outlineSize  -- 描边宽度
        effectColor  -- 效果颜色
        effectType   -- 效果类型  
    }
]]
function BaseView:setButtonLabelDisEnabled(_buttonName, _enabled, _labelParams)
    -- assert( lbNameList," !! lbNameList is nil !! " )
    if self.m_buttonStatusList[_buttonName] then
        local button = self.m_buttonStatusList[_buttonName].button
        button:setTouchEnabled(_enabled)
        self:setButtonLabelAction(button, not _enabled)
    end
end
--[[
    @desc: 外部接口, 获取按钮节点信息
    --@_buttonName:按钮名称
--]]
function BaseView:getCommonButtonInfo(_buttonName)
    return self.m_buttonStatusList[_buttonName]
end
--[[
    @desc: 界面创建自动将通用按钮下的所有节点进行绑定
    --@_button: 按钮节点
]]
function BaseView:getLanguageString(buttonName)
    local labelString = ""
    if gLobalLanguageChangeManager then
        local LanguageKeyPrefix = self:getLanguageTableKeyPrefix()
        if LanguageKeyPrefix then
            local LanguageKey = LanguageKeyPrefix .. ":" .. buttonName
            labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey)
        else
            local LanguageKey = self.__cname .. ":" .. buttonName
            labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey)
            if labelString == nil or labelString == "" then
                local csbName = self:getCsbName() or self.m_baseFilePath
                local pathList = string.split(csbName, "/")
                if pathList and table.nums(pathList) > 0 then
                    local name = pathList[table.nums(pathList)]
                    local key = name .. ":" .. buttonName
                    labelString = gLobalLanguageChangeManager:getStringByKey(key)
                end
            end
        end
    end
    return labelString
end
function BaseView:bindingChildren(node, labelString, param)
    local child_list = node:getChildren() -- 获取全部的子节点
    for k, childNode in pairs(child_list) do
        local nodeName = childNode:getName()
        param[nodeName] = {
            node = childNode,
            nodeName = nodeName,
            nodeType = tolua.type(childNode)
        }

        if tolua.type(childNode) == "ccui.Text" then
            param[nodeName].textColor = childNode:getTextColor()
            param[nodeName].shadowColor = childNode:getShadowColor()
            param[nodeName].shadowOffset = childNode:getShadowOffset()
            param[nodeName].outlineColor = childNode:getEffectColor()
            param[nodeName].outlineSize = childNode:getOutlineSize()
            param[nodeName].effectType = childNode:getLabelEffectType()
            param[nodeName].effectColor = childNode:getEffectColor()
            if labelString and labelString ~= "" then
                childNode:setString(labelString)
            end
        elseif tolua.type(childNode) == "ccui.TextBMFont" then
            param[nodeName].textColor = childNode:getVirtualRenderer():getColor()
            if labelString and labelString ~= "" then
                childNode:setString(labelString)
            end
        end
        self:bindingChildren(childNode, labelString, param)
    end
end
function BaseView:iconLabelAlignCenter(_icon, _label)
    local text = _label:getString()
    _label:setString(" ")
    local alignX = _label:getContentSize().width
    _label:setString(text)

    local uiList = {}
    local iconY = _icon:getPositionY()
    local labelY = _label:getPositionY()
    table.insert(uiList, {node = _icon})
    table.insert(uiList, {node = _label, alignY = labelY - iconY, alignX = alignX})
    util_alignCenter(uiList)
end
function BaseView:bindingDefaultButtonLabel(_button)
    assert(_button, " !! _button is nil !! ")
    local labelString = ""
    local buttonName = _button:getName()
    labelString = self:getLanguageString(buttonName)
    -- 这里需要单独记录文本颜色
    local param = {}
    self:bindingChildren(_button, labelString, param)

    if param.sp_clip and param.sp_clip.node then
        param.sp_clip.node:setVisible(false)
    end

    if param.button_icon and param.label_1 then
        self:iconLabelAlignCenter(param.button_icon.node, param.label_1.node)
    end

    -- 根据传进的按钮名进行绑定
    local buttonName = _button:getName()
    self.m_buttonStatusList[buttonName] = {button = _button, param = param}
end

--[[
    @desc: 处理按钮的文本行为
    --@_buttonSender: 点击的按钮
	--@_isPressed: 是否点击按下
]]
function BaseView:setButtonLabelAction(_buttonSender, _isPressed)
    assert(_buttonSender, " !! sender is nil !! ")
    local buttonName = _buttonSender:getName()
    if self.m_buttonStatusList[buttonName] == nil then
        return
    end
    if not _buttonSender:isVisible() then
        -- 按钮未显示， mask也不要显示不能直接return了
        _isPressed = false
    end
    -- 取出按钮 和 行为参数
    local button = self.m_buttonStatusList[buttonName].button
    local param = self.m_buttonStatusList[buttonName].param
    if _isPressed then
        if param.mask then
            if param.sp_clip and param.sp_clip.node then
                param.sp_clip.node:setVisible(true)
            end
            param.mask:setVisible(true)
        else
            local size = _buttonSender:getContentSize()
            local layer = cc.LayerColor:create(cc.c3b(0, 0, 0), size.width, size.height)
            layer:setOpacity(76.5)

            local clip_node = cc.ClippingNode:create()
            local clip_shape = param.sp_clip.node
            clip_shape:setVisible(true)
            clip_node:setAlphaThreshold(0)
            clip_node:setStencil(clip_shape)
            clip_node:addChild(layer)
            clip_node:setPosition(cc.p(-size.width / 2, -size.height / 2))
            _buttonSender:getParent():addChild(clip_node)
            param.mask = clip_node
        end
    else
        if param.mask then
            if param.sp_clip and param.sp_clip.node then
                param.sp_clip.node:setVisible(false)
            end
            param.mask:setVisible(false)
        end
    end
end
--[[
    @desc: 自定义按钮文本的行为变化控制:{ 点击 , 移动 , 抬起}
]]
function BaseView:setButtonStatusByBegan(sender)
    if tolua.type(sender) ~= "ccui.Button" then
        return
    end
    self:setButtonLabelAction(sender, true)
end

function BaseView:setButtonStatusByMoved(sender)
    if tolua.type(sender) ~= "ccui.Button" then
        return
    end
    local isHighlight = sender:isHighlighted()
    self:setButtonLabelAction(sender, isHighlight)
end

function BaseView:setButtonStatusByEnd(sender)
    if tolua.type(sender) ~= "ccui.Button" then
        return
    end
    self:setButtonLabelAction(sender, false)
end
-- 设定多语言表的key前缀
function BaseView:getLanguageTableKeyPrefix()
    return nil
end

-- 通用按钮的代币的icon显隐控制
-- _otherInfos = {{node = node, addX = addX, scale = scale}, ... }
function BaseView:setBtnBuckVisible(_btnNode, _buyType, _isVisible, _otherInfos)
    if _btnNode and not tolua.isnull(_btnNode) then
        if tolua.type(_btnNode) == "ccui.Button" then
            local spBuck = _btnNode:getChildByName("sp_buck")
            if spBuck then
                if _isVisible == nil then
                    _isVisible = G_GetMgr(G_REF.ShopBuck):isCommontBtnBuckVisible(_buyType)
                end
                spBuck:setVisible(_isVisible == true)
                -- 显示后特殊处理一些节点
                -- 如果 _otherInfos 不能满足需求，可以通过return返回值自己处理逻辑
                if _isVisible and _otherInfos and table.nums(_otherInfos) > 0 then
                    for i=1,#_otherInfos do
                        local otherNode = _otherInfos[i].node
                        local otherAddX = _otherInfos[i].addX
                        local otherScale = _otherInfos[i].scale
                        if otherNode and not tolua.isnull(otherNode) then
                            if otherAddX and otherAddX > 0 then
                                local mPosX = otherNode:getPositionX()
                                otherNode:setPositionX(mPosX + otherAddX)
                            end
                            if otherScale and otherScale > 0 then
                                otherNode:setScale(otherScale)
                            end
                        end
                    end
                end
                return _isVisible
            end
        end
    end
    return false
end
----------------------------- 按钮统一化功能  E ----------------------

-- 获得执行中的数据对象
-- function BaseView:getRunningData(refName)
--     local _data = self:getData(refName)

--     if not _data or (not _data.isRunning) or not _data:isRunning() then
--         return nil
--     end

--     return _data
-- end

return BaseView
--UI类型
-- cc.Sprite
-- cc.MenuItemImage
-- cc.ControlButton
-- cc.LayerColor
-- cc.Label
-- function
-- cc.Node
-- cc.ScrollView
-- cc.ParticleSystemQuad
-- cc.Label
-- cc.CCBAnimationManager
-- cc.Menu
-- ccui.Scale9Sprite
-- cc.Node
-- cc.Layer
-- cc.LayerGradient
-- cc.Label
-- cc.Node
-- cc.Sprite
-- cc.TMXTiledMap
-- cc.ParticleSystemQuad
-- ccui.Button
-- ccui.CheckBox
-- ccui.ImageView
--ccui.TextBMFont
-- ccui.Text
-- ccui.TextAtlas
-- ccui.Slider
-- ccui.TextField
-- ccui.ListView
-- ccui.PageView
-- ccui.Layout
-- ccui.ScrollView
-- ccs.ActionTimeline
