---
-- Loading 界面，检测是否需要热更
--
-- ios fix
local LogonLoading = class("LogonLoading", BaseLayer)
local LoadingControl = require("views.loading.LoadingControl")
LogonLoading.m_loadingBar = nil
LogonLoading.m_autoLoginStatus = nil --上次登录状态
local AUTO_LOGIN_STATUS = {
    FIRST = -1, --首次自动进入
    CHOOSE = 1, --显示引导
    FB = 2, --fb登录
    APPLE = 3, --苹果appid登录
    GUAST = 4 --游客登陆
}

function LogonLoading:initDatas(params)
    self.m_loginFalied = false
    params = params or {}
    self.m_isRestartGame = params.isRestartGame or false
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)

    if not self.m_isRestartGame then
        self:initEnterLog()
    end

    self:setLandscapeCsbName("Logon/LogonView.csb")
end

function LogonLoading:initUI(data)
    -- setDefaultTextureType("RGBA8888", nil)

    LogonLoading.super.initUI(self, data)

    self.m_fb_guang = self:findChild("FB_guang")
    -- self.m_posNode = cc.Node:create()
    -- self:addChild(self.m_posNode)
    self.m_loadingBar = self:findChild("bar")
    self.btnAppleLogin = self:findChild("btn_apple")
    self.m_node_test = self:findChild("node_test")
    if self.m_node_test then
        self.m_node_test:setVisible(false)
    end

    -- self:playEnterGame()
    -- self:updateLogonBg()
    self:checkAppleLoginAuth()

    release_print("LogonLoading:initUI")
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
    -- setDefaultTextureType("RGBA4444", nil)
end

--设置上次登录状态
function LogonLoading:setAutoLoginStatus(status)
    self.m_autoLoginStatus = status
    gLobalDataManager:setNumberByField("autoLoginStatus", status)
end

--获得上次登录状态
function LogonLoading:getAutoLoginStatus()
    if not self.m_autoLoginStatus then
        self.m_autoLoginStatus = gLobalDataManager:getNumberByField("autoLoginStatus", -1)
    end
    return self.m_autoLoginStatus
end

function LogonLoading:initEnterLog()
    local loadStatus = gLobalDataManager:getNumberByField("ReStartGameStatus", 2)
    gLobalDataManager:setNumberByField("ReStartGameStatus", 2)
    if loadStatus == 1 then
        --热更重启
        gLobalSendDataManager:getLogGameLoad():setStartType(1, true)
    elseif loadStatus == 2 then
        --正常进入游戏
        gLobalSendDataManager:getLogGameLoad():setStartType(1)
    elseif loadStatus == 3 then
        --更新失败重新进入游戏
        gLobalSendDataManager:getLogGameLoad():setStartType(3)
    elseif loadStatus == 4 then
        --后台超时进入游戏
        gLobalSendDataManager:getLogGameLoad():setStartType(2)
    end
end

function LogonLoading:initFBLight()
end

-- 刷新登陆背景主题
function LogonLoading:updateLogonBg()
    local weekType = LoadingControl:getInstance():getShowDataWeekType()
    
    local logonBg = self:getChildByName("LogonBgView")
    local isChange = globalData.GameConfig:isLoginThemeChange()
    if logonBg and isChange then
        logonBg:closeUI()
        logonBg = nil
    end

    if not logonBg then
        logonBg = util_createView("views.logon.LogonBgView")
        logonBg:setName("LogonBgView")
        self:addChild(logonBg, -1)
    end
    
end

function LogonLoading:playEnterGame()
    if self.m_fb_guang then
        self.m_fb_guang:setVisible(false)
    end
    self:runCsbAction("enter_game")
end

function LogonLoading:playButton()
    self:initFBLight()
    self:updateAppleBtnStatus()
    --
    local actName = "button_2"
    if self.btnAppleLogin:isVisible() then
        actName = "button_3"
    end
    self:runCsbAction(actName)
end

-- 设置测试状态
function LogonLoading:setTestState(isTest)
    if self.m_node_test then
        self.m_node_test:setVisible(isTest)
    end

    if isTest then
        local testNode = self.m_node_test:getChildByName("Logon_Test")
        if not testNode then
            testNode = util_createView("views.logon.LogonTest", self)
            testNode:setName("Logon_Test")
            self.m_node_test:addChild(testNode)
        end
    end
end

function LogonLoading:onEnter()
    release_print("LogonLoading:onEnter start!!!")
    LogonLoading.super.onEnter(self)

    self:updateLogonBg()
    self:playEnterGame()

    release_print("change viewLayer parent start!!!")
    local viewLayer = nil
    if gLobalViewManager.getViewLayer then
        viewLayer = gLobalViewManager:getViewLayer()
    else
        viewLayer = gLobalViewManager.p_ViewLayer
    end
    if (not tolua.isnull(viewLayer)) then
        viewLayer:removeAllChildren()
        if viewLayer:getParent() ~= nil then
            viewLayer:removeFromParent(false)
        end
        self:addChild(viewLayer, 20, 20)
    end
    release_print("change viewLayer parent end!!!")

    local nodeSpine = self:findChild("node_spine")
    if not tolua.isnull(nodeSpine) then
        nodeSpine:removeAllChildren()
    end

    if not self.m_isRestartGame then
        self:initLogonUpgradeView()

        if not CC_IS_RELEASE_NETWORK then
            self:setTestState(true)
            local _logonTest = self.m_node_test:getChildByName("Logon_Test")
            if _logonTest then
                _logonTest:updateTestView(self.m_isUpdateRestart)
            end
        else
            --显示loading
            self:checkUpgrade()
        end

        -- setDefaultTextureType("RGBA4444", nil)

        -- 这个事件需要在这注册
        gLobalNoticManager:addObserver(
            self,
            function(target, data)
                self:showLogonView()
            end,
            ViewEventType.NOTIFY_ATTRACKING_CALLBACK
        )

        gLobalNoticManager:addObserver(
            self,
            function(target, errorMsg)
                if not tolua.isnull(self) and self.m_loginFalied then
                    self:showLuaErrorDialog(errorMsg)
                end
            end,
            ViewEventType.NOTIFI_LUA_ERROR
        )

        gLobalNoticManager:addObserver(
            self,
            function()
                self:updateLogonBg()
            end,
            HTTP_MESSAGE_TYPES.HTTP_TYPE_GLOBALCONFIG_SUCCESS
        )

        if DEBUG == 2 then
            self:registerTouchEvent()
        end
    end
    release_print("LogonLoading:onEnter end!!!")
end

--[[
    @desc: 初始化 loading更新界面
    time:2019-03-07 11:40:29
    @return:
]]
function LogonLoading:initLogonUpgradeView()
    local loadBarView = util_createView("views.logon.LogonUpgradeView")
    if loadBarView and self.m_loadingBar then
        loadBarView:setName("LogonUpgradeView")
        self.m_loadingBar:addChild(loadBarView)
        self.m_loadingBar:setVisible(false)
        -- 是否更新后重启
        self.m_isUpdateRestart = loadBarView.m_isUpdateReStartGame
    end
end

function LogonLoading:checkUpgrade()
    self:setTestState(false)

    if self.m_loadingBar then
        self.m_loadingBar:setVisible(true)

        local loadBarView = self.m_loadingBar:getChildByName("LogonUpgradeView")
        if loadBarView then
            local callback = function()
                loadBarView:checkUpgrade(
                    self,
                    function()
                        if not tolua.isnull(loadBarView) then
                            loadBarView:removeFromParent()
                        end
                        if not tolua.isnull(self) and self.__cname == "LogonLoading" then
                            -- 目前只针对ios 修改为先检测 ATT授权状态 csc 2021-02-26 15:19:18
                            if device.platform == "ios" or device.platform == "mac" then
                                self:checkATTrackingStatus()
                            else
                                self:showLogonView()
                            end
                        end
                    end
                )
            end
            callback()
        end
    end
end

function LogonLoading:showLogonView()
    gLobalSendDataManager:getLogGameLoad():sendNewLog(10)
    --新GameLoadLog
    local GameStart = util_pcallRequire("GameStart")
    if GameStart then
        GameStart:getInstance():initGame()
    end

    self:registerLoginInfo()
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():setLoginStatus("Tap")

    self:showLoginEntrance()
end

function LogonLoading:showLoginEntrance()
    -- test
    -- 1
    -- gLobalDataManager:setStringByField(FB_USERID, "4450268538403343")
    -- gLobalDataManager:setStringByField(FB_NAME, "Sheryl Berkoff")
    -- gLobalDataManager:setStringByField(FB_TOKEN, "EAARwRurxhYABADhYJDThOeDdyWT1NbeEjCaPcR10rabeeEBFyx0w3pcVmdA7gEmn9ZCQHy5ZB3LHLsHo9L5RWJP3aDLJ8F7HFK2zqwI2QjuVfrZBeYGXaKTZCsatvp14BjtZCPzcvUSHihvboRotD68XM3vsNJEXC6vRKmhZA3l7bxdtL5IRWKzzG9KJzuewQ0kLrviHJMP5ZCSa75eO1dKfpfyGFOKEZCRxEOUP1KYUiZAKxV05ROkZAhPc1Hkzzxl98ZD")
    -- 2
    -- gLobalDataManager:setStringByField(FB_USERID, "1031718613843991")
    -- gLobalDataManager:setStringByField(FB_NAME, "Sichao Chen")
    -- gLobalDataManager:setStringByField(FB_TOKEN, "EAARwRurxhYABANvBqt78VKrQ72evLwYtZAFklZCFtgs0tr5dZCTo3vasXaRFXGhdu8aHfwKZA17pRKCwaDdqAWgKqCQCCbYDLfB9UZAV2GY4L9TXZAIS9Kp2LTfWtMRBB6GN0sPIhbv1RIdoUCKehWcExirymzRHsReEWJXqFThXrwOBZBnZB0X49EwbGKaPVANDItsRZBu2cjLfuvr3VQRz0zngVaquOdqaX8r0Fd2yUMVPLwAyARLBzJbxhbrgst1cZD")
    --
    local tryAutoAppleLoginInfo = self:getTryAutoAppleLoginInfo()
    if tryAutoAppleLoginInfo then
        gLobalDataManager:setStringByField("TryAutoAppleLoginInfo", "")
        self:playEnterGame()
        gLobalSendDataManager:getNetWorkLogon():appleLoginGame(tryAutoAppleLoginInfo.user, tryAutoAppleLoginInfo.token)
        self:setAutoLoginStatus(AUTO_LOGIN_STATUS.APPLE)
    elseif globalFaceBookManager:getFbLoginStatus() then
        release_print("globalFaceBookManager:getFbLoginStatus()")
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():setLoginStatus("Auto")
        gLobalSendDataManager:getLogGameLoad():sendNewLog(11)
        gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Login)
        self:playEnterGame()
        self:setAutoLoginStatus(AUTO_LOGIN_STATUS.FB)
    else
        local status = self:getAutoLoginStatus()
        if status == AUTO_LOGIN_STATUS.FIRST then
            --首次自动游客登陆
            self:loginGuest()
            self:setAutoLoginStatus(AUTO_LOGIN_STATUS.CHOOSE)
            release_print("login_test    first!!!")
        else
            local _loginFunc = function()
                local strData = gLobalDataManager:getStringByField("LeveToLobbyRestartInfo", "{}")
                local jsonData = cjson.decode(strData)
                if next(jsonData) then
                    gLobalDataManager:setStringByField("LeveToLobbyRestartInfo", "{}")
                    self:loginGuest()
                else
                    self:playButton()
                end
            end

            if self:isSingInDef("Guest") then
                local _fbToken = gLobalDataManager:getStringByField(FB_TOKEN, "")
                local _fbUdid = gLobalDataManager:getStringByField(FB_USERID, "")
                if _fbToken ~= "" and _fbUdid ~= "" then
                    -- 有fb信息，显示FB登录选项
                    release_print("login_test    FB BUTTON!!!")
                    self:playButton()
                else
                    release_print("login_test    Guest!!!")
                    self:loginGuest()
                end
            else
                _loginFunc()
            end
        end
        gLobalDataManager:setBoolByField("NoFbAutoLogin", true)
    end

    globalLocalPushManager:sendLocalPushLogWaitLogonReq() -- 点击通知发送等待登录报送报送
end

function LogonLoading:isSingInDef(_type)
    _type = _type or ""
    if globalData and globalData.GameConfig then
        local info = globalData.GameConfig:getClientCfg("signInDef", "")
        if info and info:getValue() == _type then
            return true
        end
    end
    return false
end

function LogonLoading:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    if name == "btn_fb" then -- 点击fb 登录
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():setLoginType("FB")
        self.m_isFb = true
        release_print("btn_fb")
        self:playEnterGame()
        if globalFaceBookManager:getFbLoginStatus() then
            gLobalViewManager:addLoadingAnima()
            release_print("xcyy : FbLoginStatus")
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Login)
        else
            if self:isSingInDef("Guest") then
                local _fbToken = gLobalDataManager:getStringByField(FB_TOKEN, "")
                local _fbUdid = gLobalDataManager:getStringByField(FB_USERID, "")
                if _fbToken ~= "" and _fbUdid ~= "" then
                    local splunkMsg = "FB signin info:"
                    splunkMsg = splunkMsg .. ("fb_token:" .. _fbToken .. "|")
                    splunkMsg = splunkMsg .. ("fb_udid:" .. _fbUdid .. "|")
                    local _fbName = gLobalDataManager:getStringByField(FB_NAME, "")
                    splunkMsg = splunkMsg .. ("fb_name:" .. _fbName .. "|")
                    local _fbEmail = gLobalDataManager:getStringByField(FB_EMAIL, "")
                    splunkMsg = splunkMsg .. ("fb_email:" .. _fbEmail .. "|")

                    util_sendToSplunkMsg("fb_force_enter", splunkMsg)
                    release_print(splunkMsg)

                    gLobalViewManager:addLoadingAnima()
                    release_print("xcyy : FbLoginStatus")
                    gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Login)
                end
            else
                gLobalViewManager:addLoadingAnima()
                printInfo("xcyy :FB回调")
                globalFaceBookManager:fbLogin()
            end
        end
        self:setAutoLoginStatus(AUTO_LOGIN_STATUS.FB)
    elseif name == "btn_apple" then
        gLobalSendDataManager:getLogGameLoad():setLoginType("APPLE")
        self:loginAppleID()
    elseif name == "btn_link1" then
        cc.Application:getInstance():openURL(PRIVACY_POLICY)
    elseif name == "btn_link2" then
        cc.Application:getInstance():openURL(TERMS_OF_SERVICE)
    elseif name == "btn_contactus" then
        self:contactUS()
    else
        -- 点击guest 登录
        self:loginGuest()
    end
end

function LogonLoading:loginGuest()
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():setLoginType("GUEST")
    gLobalSendDataManager:getLogGameLoad():sendNewLog(11)
    self.m_isFb = false
    self:playEnterGame()
    gLobalSendDataManager:getNetWorkLogon():loginGame(false, false)
    self:setAutoLoginStatus(AUTO_LOGIN_STATUS.GUAST)
end

---
--注册登录事件
function LogonLoading:registerLoginInfo()
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()
            self.m_loginFalied = true
            self:loginFail(data)
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD
    )

    --服务器返回成功消息
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalSendDataManager:getLogGameLoad():sendNewLog(12.1)
            -- gLobalViewManager:removeLoadingAnima()
            self.m_loginFalied = false
            gLobalNoticManager:removeObserver(self, HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS)
            local GameStart = util_pcallRequire("GameStart")
            if GameStart then
                GameStart:getInstance():gotoGame()
            end
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS
    )

    ---fb登陆成功回调
    gLobalNoticManager:addObserver(
        self,
        function(Target, loginInfo)
            self:checkFBLoginState(loginInfo)
        end,
        GlobalEvent.FB_LoginStatus,
        true
    )
end

function LogonLoading:loginFail(errorData)
    -- 登录失败 -- 添加提示界面
    local view = util_createView("views.logon.Logonfailure", self.m_isFb)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
        view:setFailureDescribe(errorData)
        if self:isSingInDef("Guest") then
            view:setOverFunc(
                function()
                    util_restartGame(nil, true)
                end
            )
        else
            self:playButton()
        end
    end
end

function LogonLoading:checkFBLoginState(loginInfo)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end
    gLobalViewManager:removeLoadingAnima()
    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
        local loginState = loginInfo.state
        local msg = loginInfo.message
        --成功
        if loginState == 1 then
            --取消
            gLobalSendDataManager:getLogGameLoad():sendNewLog(11)
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Login)
        elseif loginState == 0 then
            --失败
            self:playButton()
        else
            gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
            self:loginFail(nil)
        end
    else
        if loginInfo then
            gLobalSendDataManager:getLogGameLoad():sendNewLog(11)
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Login)
        else
            gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
            self:loginFail(nil)
        end
    end
end

function LogonLoading:onKeyBack()
    local view =
        gLobalViewManager:showDialog(
        "Dialog/ExitGame_loading.csb",
        function()
            globalLocalPushManager:commonBackGround()
            if G_GetMgr(G_REF.OperateGuidePopup) then
                G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
            end
            local director = cc.Director:getInstance()
            director:endToLua()
        end,
        nil,
        false,
        nil,
        {
            {buttomName = "btn_ok", labelString = "QUIT"},
            {buttomName = "btn_reject", labelString = "LATER"}
        }
    )
    view:setLocalZOrder(40000)
end

function LogonLoading:updateAppleBtnStatus()
    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("SignInApple", "isSupportSignInApple", {})
        if ok then
            self.btnAppleLogin:setVisible(ret)
        else
            self.btnAppleLogin:setVisible(true)
        end
        -- local btnPath = self.appleAuthFlag and "Logon/ui/appleid_continue_with.png" or "Logon/ui/appleid_sign_in_with.png"
        -- self.btnAppleLogin:loadTextures(btnPath, btnPath, btnPath)
        local LanguageKey = "LogonLoading:btn_apple_in"
        if self.appleAuthFlag then
            LanguageKey = "LogonLoading:btn_apple_continue"
        end
        local labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey)
        self:setButtonLabelContent("btn_apple", labelString)
    else
        self.btnAppleLogin:setVisible(false)
    end
end

function LogonLoading:checkAppleLoginAuth()
    if device.platform == "ios" then
        local appleUserID = gLobalDataManager:getStringByField("luaappleuserid", "")
        self:setAppleAuthFlag(false)
        if appleUserID ~= "" then
            xcyy.GameBridgeLua:checkAppleAuthFlag(
                appleUserID,
                function(param)
                    local paramInfo = loadstring(param)()
                    if not tolua.isnull(self) then
                        self:setAppleAuthFlag(paramInfo.flag)
                    end
                end
            )
        end
    else
        self:setAppleAuthFlag(true)
    end
end

function LogonLoading:setAppleAuthFlag(flag)
    self.appleAuthFlag = flag
end

function LogonLoading:loginAppleID()
    if device.platform == "ios" then
        local function appleLoginCallBack(param)
            local paramInfo = loadstring(param)()
            local flag = paramInfo.flag
            if flag == -1 then
                --授权失败
                self:setAppleAuthFlag(false)
                gLobalViewManager:removeLoadingAnima()
            elseif flag == 0 or flag == 2 or flag == 3 then
                --授权成功（0:版本不支持iOS13以上的设备,2:读入iCloud信息(可获取paramInfo.user,paramInfo.password),3:未知类)
                self:loginGuest()
            elseif flag == 1 then
                --授权成功（输入账号密码）
                self:playEnterGame()
                gLobalDataManager:setStringByField("luaappleuserid", paramInfo.user)
                gLobalSendDataManager:getNetWorkLogon():appleLoginGame(paramInfo.user, paramInfo.token)
                self:setAutoLoginStatus(AUTO_LOGIN_STATUS.APPLE)
            end
        end
        xcyy.GameBridgeLua:appleIDLogin(appleLoginCallBack)
        gLobalViewManager:addLoadingAnima()
    end
end

function LogonLoading:getIosATTVer()
    local info = globalData.GameConfig:getClientCfg("iosATTVer")
    if info then
        return info:getValue()
    else
        return "1.5.9"
    end
end

-- ios审核版本号
function LogonLoading:getAuditVer()
    local auditVer = "9.9.9"
    -- local content = globalData.GameConfig.versionData
    local content = globalData.GameConfig:getVerInfo()
    if content then
        -- local iosContent = content["ios"]
        -- if iosContent then
        --     content = iosContent
        -- end
        -- 最新app version
        auditVer = content["audit_version"] or auditVer
    end
    -- release_print("auditVer:" .. auditVer)
    return auditVer
end

-- 是否是IOS审核版本
-- function LogonLoading:isIosAuditVer()
--     local atlVer = self:getAuditVer()
--     atlVer = util_convertAppCodeToNumber(atlVer)
--     local version = util_getAppVersionCode()
--     local curVer = util_convertAppCodeToNumber(version)
--     release_print("curVer:" .. curVer .. "  atlVer:"..atlVer)
--     return curVer > atlVer
-- end

-- 检测用户att授权状态
function LogonLoading:checkATTrackingStatus()
    -- csc 2021-10-20 12:28:03 新增1.6.4版本需求
    if util_isSupportVersion("1.6.4") then
        if gLobalDataManager:getBoolByField("ATTrackingSwitchFlagSaved", false) == false then
            -- 登录之后获取一次用户的 att 总开关状态并且记录到本地
            local attStatus = gLobalAdsControl:getAttStatus()
            gLobalDataManager:setBoolByField("ATTrackingSwitchFlagSaved", true)
            gLobalAdsControl:setAttSwtich(attStatus)
        -- release_print("----csc checkATTrackingStatus setAttSwtich = "..tostring(attStatus))
        end
    end

    -- 2021年08月23日 更新最新att 弹出系统版本走配表
    -- local iosAttVer = self:getIosATTVer()
    local iosAttVer = self:getAuditVer()
    if not util_isSupportVersion(iosAttVer) then
        release_print("----csc support" .. iosAttVer .. " = " .. tostring(not util_isSupportVersion(iosAttVer)))
        --满足版本了直接跳过
        self:showLogonView()
    else
        local isATTOver = gLobalDataManager:getBoolByField("checkATTrackingOver")
        -- 还没有更新到最新 app 但是是新号的情况, 当前还没触发过 loading
        -- 还是原先的版本,保留代码不变
        release_print("----csc unsupport " .. iosAttVer .. " checkATTrackingStatus ")
        if not gLobalAdsControl:getCheckATTFlag("loading", "1.4.7") or isATTOver then
            release_print("----csc unsupport " .. iosAttVer .. " checkATTrackingStatus loading 1.4.7 status == false")
            self:showLogonView()
        else
            release_print("----csc unsupport " .. iosAttVer .. " checkATTrackingStatus loading 1.4.7 status == true")
            -- 发送打点
            globalPlatformManager:checkATTrackingStatus(
                function(status)
                    -- 发送firebase打点
                    if status == "true" then
                        globalFireBaseManager:sendFireBaseLogDirect("AttrackingAllow", false)
                        -- 记录当前ATT 弹板已经不用再弹出了
                        gLobalDataManager:setBoolByField("checkATTrackingOver", true)
                    elseif status == "false" then
                        globalFireBaseManager:sendFireBaseLogDirect("AttrackingReject", false)
                    end
                    -- 无论Att 玩家选择了什么 都进大厅
                    release_print("----csc unsupport " .. iosAttVer .. " checkATTrackingLoadingStatus = " .. tostring(status) .. " att callback")
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ATTRACKING_CALLBACK)
                end
            )
        end
    end
end

--显示Lua报错对话框，点击重新热更
function LogonLoading:showLuaErrorDialog(errorMsg)
    local fixDialog = util_createView("views.dialogs.LoadingFixDialog", errorMsg)
    gLobalViewManager:showUI(fixDialog)
end

--点击contactUS按钮
function LogonLoading:contactUS()
    globalData.newMessageNums = nil
    globalData.skipForeGround = true
    globalPlatformManager:openAIHelpRobot("Login")
end

-- 设置界面切换苹果登录 记录的数据
function LogonLoading:getTryAutoAppleLoginInfo()
    local jsonStr = gLobalDataManager:getStringByField("TryAutoAppleLoginInfo", "")
    if not string.find(jsonStr, "user") then
        return
    end

    if not self.appleAuthFlag then
        return
    end

    local info = json.decode(jsonStr)
    return info
end

--增加长按手势 查看日志
function LogonLoading:registerTouchEvent()
    self.m_touchTime = 0
    self.m_startPos = nil
    local function onTouchBegan_callback(touch, event)
        --self:createScheduler()
        self.m_startPos = touch:getLocation()
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        local pos = touch:getLocation()
        if self.m_startPos then
            local p_X = pos.x - self.m_startPos.x
            local p_Y = self.m_startPos.y - pos.y
            if p_X >= 100 and p_Y >= 100 then
                local view = util_createView("views.setting.CheckLogLayer")
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
            self.m_startPos = nil
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

return LogonLoading
