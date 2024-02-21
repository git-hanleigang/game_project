--[[
Author: cxc
Date: 2021-05-31 14:52:49
LastEditTime: 2021-07-23 16:41:30
LastEditors: Please set LastEditors
Description: 设置界面
FilePath: /SlotNirvana/src/views/setting/SettingsLayerNew.lua
--]]
local SettingsLayerNew = class("SettingsLayerNew", BaseLayer)

--测试加速
SettingsLayerNew.m_timeSaleList = {1, 3, 5, 10, 15} --加速列表
SettingsLayerNew.m_timeSaleIndex = 1 --加速索引

function SettingsLayerNew:ctor()
    SettingsLayerNew.super.ctor(self)

    -- 横屏资源
    self:setLandscapeCsbName("Option/OptionSettingLayer_New.csb")
    -- 竖屏资源
    self:setPortraitCsbName("Option/OptionSettingLayer_New_Portrait.csb")
    self:setPauseSlotsEnabled(true)
end

function SettingsLayerNew:initCsbNodes()
    self.m_list = self:findChild("ListView_content")
end

function SettingsLayerNew:initUI()
    SettingsLayerNew.super.initUI(self)

    self:initDebugUI()
    self:initTableView()
end
------------------------- init -------------------------
function SettingsLayerNew:initDebugUI()
    -- 标题触摸
    local spTitle = self:findChild("sp_title")
    local btnTitle = util_makeTouch(spTitle, "btn_title")
    btnTitle:setAnchorPoint(0, 0)
    btnTitle:addTo(spTitle)
    self:addClick(btnTitle)

    -- appVersion 触摸
    local lbAppVersion = self:findChild("lb_appVersion")
    local AppVersion = util_makeTouch(lbAppVersion, "btn_appVersion")
    AppVersion:setAnchorPoint(0, 0)
    AppVersion:addTo(lbAppVersion)
    self:addClick(AppVersion)

    -- 设置版本号
    local curAppVer = util_getAppVersionCode()
    local fieldValue = util_getUpdateVersionCode(false)
    local verStr = "Version: " .. curAppVer .. "_v" .. fieldValue
    --检测如果是70服添加小版本号
    if not CC_IS_RELEASE_NETWORK then
        local curServerMode = gLobalDataManager:getStringByField("ResServerMode", "")
        if curServerMode == 3 then
            local curCode70 = gLobalDataManager:getNumberByField("release_update_version", 0) -- 获取本地70小版本号
            verStr = verStr .. "_" .. curCode70
        end
    end
    lbAppVersion:setString(verStr)

    -- 设置资源版本号
    self.m_csbOwner["lb_resVersion"]:setVisible(false)
    -- self.m_csbOwner["lb_resVersion"]:setString("Res_Version: v" .. fieldValue)

    if DEBUG == 2 then
        -- 清除缓存
        self:createCustomLabelTouch("清除缓存", "clearData", cc.p(display.cx, display.cy + 50))

        -- 当前使用内存
        self:createCustomLabelTouch("已使用内存", "mmUsage", cc.p(150, display.height - 150))

        --加速
        local scheduler = cc.Director:getInstance():getScheduler()
        local timeSale = scheduler:getTimeScale()
        for i = 1, #self.m_timeSaleList do
            if self.m_timeSaleList[i] == timeSale then
                self.m_timeSaleIndex = i
                break
            end
        end
        self.m_timeLabel = self:createCustomLabelTouch("游戏加速:X" .. timeSale, "timeScale", cc.p(display.cx, display.cy - 50))
        if util_isSupportVersion("1.8.1", "mac") or util_isSupportVersion("1.9.1", "ios") or util_isSupportVersion("1.8.8", "android") then
            -- gridNode测试
            self:createCustomLabelTouch("gridNode测试", "gridNode", cc.p(display.cx, display.cy ))
        end
        -- bigwin测试
        self:createCustomLabelTouch("bigwin测试", "bigwin", cc.p(display.cx, display.cy + 150))

        -- 测试内购专用
        self:createCustomLabelTouch("是否跳过服务器", "skipserver", cc.p(display.cx - 300, display.cy - 100))
        self:createCustomLabelTouch("是否直接验证成功", "buysuccess", cc.p(display.cx - 300, display.cy - 170))
        self:createCustomLabelTouch("清除本地掉单文件", "cleanfile", cc.p(display.cx - 300, display.cy - 240))
        self:createCustomLabelTouch("补单是否跳过服务器", "reskipserver", cc.p(display.cx - 300, display.cy + 140))
        self:createCustomLabelTouch("补单是否直接验证成功", "rebuysuccess", cc.p(display.cx - 300, display.cy + 70))
        self:createCustomLabelTouch("是否打开SDK内购:" .. tostring(not CC_IS_TEST_BUY), "switchBuy", cc.p(display.cx, display.cy + 300))
        self:createCustomLabelTouch("是否打开FB打点日志:" .. tostring(CC_IS_PLATFORM_SENDLOG), "switchFbLog", cc.p(display.cx - 50, display.cy + 250))
        self:createCustomLabelTouch("显示日志", "showFbLog", cc.p(display.cx + 250, display.cy + 250))
        self:createCustomLabelTouch("xcyyUDID:" .. xcyy.GameBridgeLua:getDeviceUuid(), "nodeUdid1", cc.p(display.cx, 100), false)
        self:createCustomLabelTouch("UDID:" .. gLobalSendDataManager:getDeviceUuid(), "nodeUdid", cc.p(display.cx, 60), false)
        self:createCustomLabelTouch("DeviceID:" .. gLobalSendDataManager:getDeviceId(), "nodeDevice", cc.p(display.cx, 20), false)
        local safeInfo, oriS = util_getSafeAreaInfoList()
        self:createCustomLabelTouch(string.format("刘海:{%s,%s,%s,%s}_%s", safeInfo[1], safeInfo[2], safeInfo[3], safeInfo[4], oriS) , "liuhai", cc.p(display.cx, display.height - 20), false)
        self:createCustomLabelTouch(string.format("关卡spinOver忽略系统弹板开关: ".. tostring(globalMachineController:getIgnorePopCorEnabled())), "spinOverLayer", cc.p(display.cx-300, display.height - 50))

        self:createCustomEditBox("跳转关卡", cc.p(display.cx, display.cy - 100),"输入关卡ID",function(event)
            local sender = event.target
            local name = event.name
            if name == "ended" then  
                local str = sender:getText()
                local strLen = string.len(str)
                if strLen >= 5 then
                    local id = tonumber(str) 
                    if id and id > 0 then
                        CC_IS_TEST_LEVEL_ID = id
                        util_TestGotoLevel()
                    end
                end
                sender:setText("")
            end
        end)

        -- 关卡配置debug 输入框
        self:cerateSlotDebugInputUI()

        self:updateIapButtonLabel()
    end
end

function SettingsLayerNew:initTableView()
    local bShowTokenUI = gLobalSendDataManager:checkIsShowTokenUI()
    local bShowAppleBtn = self:checkCanShowAppleBtn()
    local contentList = {"uid", "bgm", "se", "vibration", "winner", "fbconnect", "fanpage", "fixup", "delete"}
    if bShowAppleBtn then
        contentList = {"uid", "bgm", "se", "vibration", "winner", "appleconnect", "fbconnect", "fanpage", "fixup", "delete"}
    end
    if bShowTokenUI or DEBUG == 2 then
        table.insert(contentList, 1, "token")
    end
    if DEBUG == 2 then
        table.insert(contentList, "log")
    end

    if util_isSupportVersion("1.9.4", "android") or util_isSupportVersion("1.9.9", "ios") then
        table.insert(contentList, 5, "notification")
    end
    
    if gLobalAdsControl:isUserGDPR() then
        table.insert(contentList, "privacy")
    end

    for i, v in ipairs(contentList) do
        local cell = util_createView("views.setting.SettingsLayerItem", v)
        local cellLayout = ccui.Layout:create()
        cellLayout:setContentSize({width = 1029, height = 93})
        cellLayout:addChild(cell)
        self.m_list:pushBackCustomItem(cellLayout)
        -- local fenge = util_createView("views.setting.SettingsLayerItem", "fenge")
        -- local fengeLayout = ccui.Layout:create()
        -- fengeLayout:setContentSize({width = 1016, height = 6})
        -- fengeLayout:addChild(fenge)
        -- self.m_list:pushBackCustomItem(fengeLayout)
    end
end

------------------------- init -------------------------

------------------------- update -------------------------
function SettingsLayerNew:updateTimeScale()
    local scheduler = cc.Director:getInstance():getScheduler()
    self.m_timeSaleIndex = self.m_timeSaleIndex + 1
    if self.m_timeSaleIndex > #self.m_timeSaleList then
        self.m_timeSaleIndex = 1
    end
    local timeSale = self.m_timeSaleList[self.m_timeSaleIndex]
    scheduler:setTimeScale(timeSale)
    globalData.timeScale = timeSale
    self.m_timeLabel:setString("游戏加速:X" .. timeSale)
end

function SettingsLayerNew:updateIapButtonLabel()
    local labelSkip = self:getChildByName("skipserver")
    local labelSuc = self:getChildByName("buysuccess")

    local skip, suc = gLobalIAPManager:getTestButton()
    labelSkip:setString("是否跳过服务器:" .. tostring(skip))
    labelSuc:setString("是否直接验证成功:" .. tostring(suc))

    local labelReSkip = self:getChildByName("reskipserver")
    local labelReSuc = self:getChildByName("rebuysuccess")

    local skip, suc = gLobalIAPManager:getTestReButton()
    labelReSkip:setString("补单是否跳过服务器:" .. tostring(skip))
    labelReSuc:setString("补单是否直接验证成功:" .. tostring(suc))
end
------------------------- update -------------------------

------------------------- debug方法 -------------------------
function SettingsLayerNew:openDebug()
    if globalData.openDebugCode == 0 then
        globalData.openDebugCode = 1
    else
        globalData.openDebugCode = 0
    end
    gLobalDataManager:setNumberByField("openDebugCode", globalData.openDebugCode)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_DEBUGLOG)
    --范铮说这个不需要请求服务器了
    -- gLobalSendDataManager:getNetWorkFeature():sendOpenDebugCode(
    --     globalData.openDebugCode,
    --     function()
    --         --发送成功保存
    --         gLobalDataManager:setNumberByField("openDebugCode", globalData.openDebugCode)
    --         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_DEBUGLOG)
    --     end,
    --     function()
    --         --发送失败读取配置
    --         globalData.openDebugCode = gLobalDataManager:getNumberByField("openDebugCode", 0)
    --     end
    -- )
end

-- 运营引导弹窗
function SettingsLayerNew:operateGuidePopupDebug()
    if DEBUG == 0 then
        return
    end

    local lbOGPopInfo = cc.LabelTTF:create("", "Arial", 28)
    lbOGPopInfo:setName("Lb_Slot_Spin_Over_Layer")
    lbOGPopInfo:addTo(gLobalViewManager.p_ViewLayer, 99999999)
    lbOGPopInfo:move(20, display.height - 40)
    lbOGPopInfo:setColor(cc.RED)
    lbOGPopInfo:setHorizontalAlignment(0)
    lbOGPopInfo:setAnchorPoint(cc.p(0, 1)) 

    lbOGPopInfo.updateStr = function(target)
        local archiveData = G_GetMgr(G_REF.OperateGuidePopup):getArchiveData()
        local siteCountInfo = archiveData._siteCountInfo or {}
        local siteCDInfo = archiveData._siteCDInfo or {}
        local popupCDInfo = archiveData._popupCDInfo or {}
        local str = "存档数据:\n"
        str = str .. "点位次数:\n"  .. (cjson.encode(siteCountInfo) or "") .. "\n"
        str = str .. "点位记录时间:\n"  .. (cjson.encode(siteCDInfo) or "") .. "\n"
        str = str .. "弹板记录时间:\n"  .. (cjson.encode(popupCDInfo) or "") .. "\n"
        str = str .. "spin次数:"  .. globalData.rateUsData.m_currentSpinNum
        target:setString(str)
    end
    util_schedule(lbOGPopInfo, util_node_handler(lbOGPopInfo, lbOGPopInfo.updateStr), 1)
end

function SettingsLayerNew:slotFloatScaleDebug()
    if DEBUG == 0 then
        return
    end

    local ipTextField = ccui.TextField:create("关卡左右边条缩放值", "Arial", 40)
    ipTextField:setPlaceHolderColor(cc.c4b(255, 0, 0, 255))
    ipTextField:setAnchorPoint(cc.p(0, 1)) 
    ipTextField:move(20, display.height - 80)
    ipTextField:addTo(gLobalViewManager.p_ViewLayer, 99999999)
    ipTextField:onEvent(
        function(event)
            if event.name == "DETACH_WITH_IME" then
                local scaleNum = tonumber(ipTextField:getString()) or 1

                if gLobalViewManager:isLevelView() then
                    gLobalActivityManager:setSlotFloatLayerLeft(nil, scaleNum or 1)
                    gLobalActivityManager:setSlotFloatLayerRight(nil, scaleNum or 1)
                end

                local rightParent = gLobalViewManager:getViewLayer():getParent()
                if rightParent and rightParent:getChildByName("GameRightFrame") then
                    rightParent:getChildByName("GameRightFrame"):setScale(scaleNum or 1)
                end

                local mgr = G_GetMgr(G_REF.FloatView)
                if mgr and mgr._slotFloatLayer then
                    local leftView = mgr._slotFloatLayer:getFloatView("SlotLeftFloatView")
                    if leftView then
                        leftView:setScale(scaleNum or 1)
                        leftView._scale = scaleNum or 1
                        local size = leftView:getContentSize()
                        if leftView._scrlView then
                            size = leftView._scrlView:getContentSize()
                        elseif leftView._listView then
                            size = leftView._listView:getContentSize()
                        end
                        leftView:updateContentSize(size)
                    end
                end
            end
        end
    )
end

-- 宠物引导
function SettingsLayerNew:showPetGuideDebug()
    if DEBUG == 0 then
        return
    end

    local input = ccui.TextField:create("宠物引导步骤", "Arial", 40)
    input:setPlaceHolderColor(cc.c4b(0, 250, 0, 255))
    input:setAnchorPoint(cc.p(0, 1))
    input:move(40, display.height - 60)
    input:addTo(gLobalViewManager.p_ViewLayer, 99999999)
    input:setName("PetGuideStepInput")
    input:onEvent(
        function(event)

            if event.name == "DETACH_WITH_IME" then
                local str = input:getString()
                local _detailLayer = gLobalViewManager:getViewByName("SidekicksDetailLayer_1")
                local _mainLayer = gLobalViewManager:getViewByName("SidekicksMainLayer_1")
                if _detailLayer then
                    _detailLayer:dealGuideLogic((tonumber(str) or 1) - 1) 
                elseif _mainLayer then
                    _mainLayer:dealGuideLogic((tonumber(str) or 1) - 1) 
                end

            end
        end
    )
end

-- 创建 文本 加 触摸
function SettingsLayerNew:createCustomLabelTouch(_text, _nodeName, _pos, isTouch)
    -- 文本
    local label = cc.LabelTTF:create(_text, "Arial", 36)
    label:setName(_nodeName)
    label:addTo(self)
    label:move(_pos)
    label:setColor(cc.RED)
    -- 触摸
    local touch = util_makeTouch(label, "btn_" .. _nodeName)
    touch:setAnchorPoint(0, 0)
    touch:addTo(label)
    if isTouch or isTouch == nil then
        self:addClick(touch)
    end

    return label
end

-- 关卡配置debug 输入框
function SettingsLayerNew:cerateSlotDebugInputUI()
    local ipTextField = ccui.TextField:create("关卡配置Input", "Arial", 20)
    ipTextField:setPlaceHolderColor(cc.c4b(255, 0, 0, 255))
    ipTextField:move(cc.p(display.cx - 300, display.cy + 300))
    self:addChild(ipTextField)
    ipTextField:onEvent(
        function(event)
            if event.name == "DETACH_WITH_IME" then
                local str = ipTextField:getString()
                local ipPortT = string.split(str, ":")
                if str == "leveldebug" then
                    self:openDebug()
                elseif str == "OGPop" then
                    self:operateGuidePopupDebug()
                elseif str == "OSLRS" then
                    self:slotFloatScaleDebug()
                elseif str == "PETG" then
                    self:showPetGuideDebug()
                end
            end
        end
    )
end

function SettingsLayerNew:createCustomEditBox(_nodeName, _pos,_placeHolder,_handFunc)
    local editBox = ccui.EditBox:create(cc.size(200,50),"res/sp_line_star.png")  --输入框尺寸，背景图片
    editBox:setFontSize(45)
    editBox:setAnchorPoint(0.5,0.5)
    editBox:setFontColor(cc.RED)
    editBox:setPlaceholderFontColor(cc.RED)
    editBox:setReturnType(cc.KEYBOARD_RETURNTYPE_SEND ) --输入键盘返回类型，done，send，go等
    editBox:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC) --输入模型，如整数类型，URL，电话号码等，会检测是否符合
    editBox:setPlaceHolder(_placeHolder) 
    if _handFunc then
        editBox:onEditHandler(_handFunc) 
    end
    
    self:addChild(editBox)
    editBox:setName(_nodeName)
    editBox:setPosition(_pos)
    return editBox
end

------------------------- debug方法 -------------------------

function SettingsLayerNew:clickFunc(sender)
    if DEBUG == 2 then
        self:clickFuncByDebug(sender)
    end
    self:clickFuncByRelease(sender)
end

function SettingsLayerNew:clickFuncByDebug(sender)
    local sBtnName = sender:getName()

    if sBtnName == "btn_clearData" then
        util_restartGame(
            function()
                --清除手机缓存
                util_removeAllLocalData()
            end
        )
    elseif sBtnName ==  "btn_gridNode" then
        self:testGridNode()
    elseif sBtnName == "btn_timeScale" then
        -- 加速减速
        self:updateTimeScale()
    elseif sBtnName == "btn_skipserver" then
        local skip, suc = gLobalIAPManager:getTestButton()
        skip = not skip
        gLobalIAPManager:testSetButton(skip, suc)
        self:updateIapButtonLabel()
    elseif sBtnName == "btn_buysuccess" then
        local skip, suc = gLobalIAPManager:getTestButton()
        suc = not suc
        gLobalIAPManager:testSetButton(skip, suc)
        self:updateIapButtonLabel()
    elseif sBtnName == "btn_reskipserver" then
        local skip, suc = gLobalIAPManager:getTestReButton()
        skip = not skip
        gLobalIAPManager:testSetReButton(skip, suc)
        self:updateIapButtonLabel()
    elseif sBtnName == "btn_rebuysuccess" then
        local skip, suc = gLobalIAPManager:getTestReButton()
        suc = not suc
        gLobalIAPManager:testSetReButton(skip, suc)
        self:updateIapButtonLabel()
    elseif sBtnName == "btn_cleanfile" then
        gLobalIAPManager:clearFailList()
    elseif sBtnName == "btn_bigwin" then
        self:showBigwin()
    elseif sBtnName == "btn_switchBuy" then
        CC_IS_TEST_BUY = not CC_IS_TEST_BUY
        local label = self:getChildByName("switchBuy")
        label:setString("是否打开SDK内购:" .. tostring(not CC_IS_TEST_BUY))
    elseif sBtnName == "btn_switchFbLog" then
        CC_IS_PLATFORM_SENDLOG = not CC_IS_PLATFORM_SENDLOG
        local label = self:getChildByName("switchFbLog")
        label:setString("是否打开FB打点日志:" .. tostring(CC_IS_PLATFORM_SENDLOG))
    elseif sBtnName == "btn_showFbLog" then
        if CC_IS_PLATFORM_SENDLOG then
            globalFireBaseManager:showLogLayer()
        end
    elseif sBtnName == "btn_mmUsage" then
        local platform = device.platform
        if platform == "ios" or platform == "android" then
            self:showMmUsageLayer()
        end
    elseif sBtnName == "btn_spinOverLayer" then
        local label = self:getChildByName("spinOverLayer")
        local bEnabled = globalMachineController:getIgnorePopCorEnabled()
        globalMachineController:setIgnorePopCorEnabled(not bEnabled)
        label:setString(string.format("关卡spinOver忽略系统弹板开关: ".. tostring(not bEnabled)))
    end
end

function SettingsLayerNew:showMmUsageLayer()
    if not util_isSupportVersion("1.7.9", "ios") and not util_isSupportVersion("1.7.2", "android") then
        return
    end

    local _layer = display.getRunningScene():getChildByName("settingDebugLayer")
    if not _layer then
        _layer = cc.Layer:create()
        _layer:setName("settingDebugLayer")
        display.getRunningScene():addChild(_layer, 9999)

        local label = cc.Label:createWithSystemFont("", "Arial", 36)
        label:addTo(_layer)
        label:setPosition(cc.p(0, 200))
        label:setAnchorPoint(cc.p(0, 1))
        label:setColor(cc.c3b(152, 251, 152))
        label:enableShadow(cc.BLACK, cc.size(1, -1))
        local txtUsage = function()
            local mmUsage = "已使用内存:" .. globalPlatformManager:getMemoryUsageStr()
            label:setString(mmUsage)
        end

        schedule(
            label,
            function()
                txtUsage()
            end,
            2
        )

        txtUsage()
    else
        _layer:removeFromParent()
    end
end

-- ==================================================

function SettingsLayerNew:clickFuncByRelease(sender)
    local sBtnName = sender:getName()
    if sBtnName == "btn_close" then
        self:closeUI()
    elseif sBtnName == "btn_service" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        globalData.skipForeGround = true
        cc.Application:getInstance():openURL(TERMS_OF_SERVICE) -- URL 要更登录界面一样
    elseif sBtnName == "btn_policy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        globalData.skipForeGround = true
        cc.Application:getInstance():openURL(PRIVACY_POLICY) -- URL 要更登录界面一样
    end
end

function SettingsLayerNew:showBigwin()
    if not globalData.testWinType then
        globalData.testWinType = 1
    end
    self:closeUI()
    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg", globalData.testWinType)
    bigMegaWin:initViewData(
        10000000000,
        globalData.testWinType,
        function()
        end
    )
    gLobalViewManager:showUI(bigMegaWin, ViewZorder.ZORDER_UI)
    globalData.testWinType = globalData.testWinType + 1
    if globalData.testWinType > 4 then
        globalData.testWinType = 1
    end
end

-- 检查是否 要显示apple登录按钮
function SettingsLayerNew:checkCanShowAppleBtn()
    if device.platform ~= "ios" then
        return false
    end

    local ok, ret = luaCallOCStaticMethod("SignInApple", "isSupportSignInApple", {})
    if not ok or ret == false then
        return false
    end

    return true
end


function SettingsLayerNew:testGridNode()
    local sprite = util_createSprite("res/Loading/ui/loading_out_bg.jpg")
    sprite:setScaleX(0.5)
    sprite:setColor(cc.c3b(144, 144, 144))
    sprite:setOpacity(255)
    sprite:setPosition(display.center)
    local gridNode = cc.NodeGrid:create()
    local grid3d = cc.Grid3D:create(cc.size(51,51))
    grid3d:setActive(true)
    gridNode:setGrid(grid3d);
    gridNode:setTarget(sprite);
    gridNode:addChild(sprite)
    self:addChild(gridNode)

    local addTime = 0
    local i, j;
    local _radius = 300;
    local wave = 0.07;
    local  amplitude = 30;
    local _position = cc.p(display.width/2,display.height/2);
    local vect = {}
    local size = grid3d:getGridSize()
    util_schedule(gridNode, function()
        addTime = addTime + 0.1;
         
        for i=1,size.height do
            for j=1,size.width do
                local v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j));
                vect = {}
                vect.x = _position.x - v.x
                vect.y = _position.y - v.y
                local r = math.sqrt(vect.x*vect.x + vect.y*vect.y) 
                if r < _radius then
                    r = _radius - r 
                    local sinNum = math.sin( addTime * math.pi  + r * wave)
                    local curZ = sinNum * amplitude
                    v.z = v.z + curZ;
                end
                util_Grid3D_setVertex( grid3d,cc.p(i, j), v);
            end 
        end
    end, 1/60)
end

function SettingsLayerNew:onExit()
    SettingsLayerNew.super.onExit(self)

    if DEBUG == 2 and device.platform == "mac" then
        for path,v in pairs(package.loaded) do
            local targrtName = "SettingsLayerNew"
            local startIndex, endIndex = string.find(path, targrtName)
            if startIndex and endIndex then
                package.loaded[path] = nil
            end
        end
    end
end
return SettingsLayerNew
