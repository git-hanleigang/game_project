--[[
    
]]
local SettingsLayerItem = class("SettingsLayerItem", BaseView)

local FB_FUNS_URL = "https://www.facebook.com/CashTornadoSlots"
-- local FB_COMMUNITY_PAGE_ID = "725940274524191"

function SettingsLayerItem:initUI(_path)
    self.m_path = _path
    local csbName = "Option/node_" .. _path .. ".csb"
    self:createCsbNode(csbName, false)
    self:initTokenUI()
    self:refreshView()
    self:setFbBtnStatus()
    self:setAppleBtnStatus()
    self:setNotificationStatus()
    self:setBtnSwallow()
    self:initChkPrivacy()
end

function SettingsLayerItem:initCsbNodes()
    self.m_btn_fbOut = self:findChild("btn_fb_out")
    self.m_btn_fbConnect = self:findChild("btn_fb_connect")
    self.m_sp_musicOff = self:findChild("spr_music_off")
    self.m_sp_soundOff = self:findChild("spr_sound_off")
    self.m_sp_championOff = self:findChild("spr_champion_off")
    self.m_lb_userID = self:findChild("user_id")
    self.m_btn_apple = self:findChild("btn_apple")
    self.m_btnPricy = self:findChild("btn_privacy")
    if self.m_btnPricy then
        self.m_btnPricy:setSwallowTouches(false)
    end
    self.m_sp_shakeOff = self:findChild("spr_vibration_off")
end

-- 新游戏包里 tokenUI
function SettingsLayerItem:initTokenUI()
    local textFieldToken = self:findChild("TextField_token")
    local btnLogin = self:findChild("btn_login")

    if tolua.isnull(textFieldToken) or tolua.isnull(btnLogin) then
        return
    end
    textFieldToken:setMaxLength(16) -- 最多16位
    self.m_editBoxToken =
        util_convertTextFiledToEditBox(
        textFieldToken,
        nil,
        function(strEventName, pSender)
            local text = pSender:getText()
            if strEventName == "return" then
                local filterStr = string.gsub(text, "[^%w^%p]", "")
                pSender:setText(filterStr)
                text = filterStr
            end
            btnLogin:setEnabled(#text > 0)
        end
    )
    btnLogin:setEnabled(false)
    self:registerListenerToken()
end

--切换fb按钮状态
function SettingsLayerItem:setFbBtnStatus()
    if self.m_btn_fbOut and self.m_btn_fbConnect then
        local isFBLogin = gLobalSendDataManager:getIsFbLogin()
        self.m_btn_fbOut:setVisible(isFBLogin)
        self.m_btn_fbConnect:setVisible(not isFBLogin)
        self:registerListenerFB()
    end
end

--切换apple按钮状态
function SettingsLayerItem:setAppleBtnStatus()
    if not self.m_btn_apple then
        return
    end

    local loginType = gLobalSendDataManager:getLogGameLoad():getLoginType()
    local LanguageKey = "SettingsLayerItem:btn_apple_in"
    if loginType == "APPLE" then
        LanguageKey = "SettingsLayerItem:btn_apple_out"
    end
    local labelString = gLobalLanguageChangeManager:getStringByKey(LanguageKey)
    self:setButtonLabelContent("btn_apple", labelString)
end

-- 通知状态
function SettingsLayerItem:setNotificationStatus()
    if util_isSupportVersion("1.9.4", "android") or util_isSupportVersion("1.9.9", "ios") then
        local sp = self:findChild("spr_notification_off")
        if sp then
            local notify = globalDeviceInfoManager:isNotifyEnabled()
            sp:setVisible(not notify)
        end
    end
end

-- 刷新界面
function SettingsLayerItem:refreshView()
    if self.m_sp_musicOff then
        local musicOn = gLobalDataManager:getBoolByField(kMusic_Backgroud_Switch, true)
        self.m_sp_musicOff:setVisible(not musicOn)
    end

    if self.m_sp_soundOff then
        local soundOn = gLobalDataManager:getBoolByField(kSound_Effect_switdh, true)
        self.m_sp_soundOff:setVisible(not soundOn)
    end

    if self.m_sp_championOff then
        local championOn = gLobalDataManager:getBoolByField(WINNER_NOTIFICATIONS, true)
        self.m_sp_championOff:setVisible(not championOn)
    end

    if self.m_lb_userID then
        self.m_lb_userID:setString(globalData.userRunData.loginUserData.displayUid)
    end
    if self.m_sp_shakeOff then
        local shakeOn = gLobalDataManager:getBoolByField("isDeviceVibrate", true)
        self.m_sp_shakeOff:setVisible(not shakeOn)
    end
end

function SettingsLayerItem:initChkPrivacy()
    if not self.m_btnPricy then
        return
    end

    self:setButtonLabelContent("btn_privacy", "START")
end

function SettingsLayerItem:clickFunc(_sander)
    local name = _sander:getName()
    if name == "btn_music" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:musicBtnTouchEvent()
    elseif name == "btn_fb_out" or name == "btn_fb_connect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalViewManager:addLoadingAnima(false, nil, 5)
        performWithDelay(
            self,
            function()
                self:fbBtnTouchEvent()
            end,
            0.2
        )
    elseif name == "btn_fenpage" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendClickFbUrlLog()
        -- cc.Application:getInstance():openURL(FB_FUNS_URL)
        globalPlatformManager:openFB(globalData.constantData:getFbFansUrl())
    elseif name == "btn_sound" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:soundBtnTouchEvent()
    elseif name == "btn_champion" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:winnerNotifyTouchEvent()
    elseif name == "btn_copy" then
         gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
         xcyy.GameBridgeLua:copyToClipboard(globalData.userRunData.loginUserData.displayUid)
    elseif name == "btn_login" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if tolua.isnull(self.m_editBoxToken) then
            return
        end
        -- 发请求绑定 token
        local tokenStr = self.m_editBoxToken:getText()
        if #tokenStr <= 0 then
            return
        end
        gLobalSendDataManager:getNetWorkLogon():sendGuestBindTokenReq(tokenStr)
    elseif name == "btn_fixup" then
        local view = util_createView("views.setting.SettingsLayerFix")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    elseif name == "btn_apple" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickAppleBtnEvt()     
    elseif name == "btn_delete" then
        gLobalViewManager:showDialog("Dialog/DeleteAccount_check.csb",function()
            globalPlatformManager:deleteAccount()
        end, nil, nil, nil)
    elseif name == "btn_log" then
        --查看日志
        local view = util_createView("views.setting.CheckLogLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    elseif name == "btn_privacy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalAdsControl:checkConsentFlow()
    elseif name == "btn_vibration" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:shakeBtnTouchEvent()
    elseif name == "btn_notification" then
        if util_isSupportVersion("1.9.4", "android") or util_isSupportVersion("1.9.9", "ios") then
            globalXSDKDeviceInfoManager:goToNotificationSettings()
        end
    end
end

-- 设置音乐
function SettingsLayerItem:musicBtnTouchEvent()
    local musicStatus = gLobalDataManager:getBoolByField(kMusic_Backgroud_Switch, true)
    if musicStatus == false or musicStatus == nil then
        gLobalDataManager:setBoolByField(kMusic_Backgroud_Switch, true)

        gLobalSoundManager:restartBgMusic()

        self.m_csbOwner["spr_music_off"]:setVisible(false)
        musicStatus = true
    else
        gLobalDataManager:setBoolByField(kMusic_Backgroud_Switch, false)

        gLobalSoundManager:stopBgMusic()

        self.m_csbOwner["spr_music_off"]:setVisible(true)
        musicStatus = false
    end
end

-- 设置音效
function SettingsLayerItem:soundBtnTouchEvent()
    local soundStatus = gLobalDataManager:getBoolByField(kSound_Effect_switdh, true)
    if soundStatus == false or soundStatus == nil then
        gLobalDataManager:setBoolByField(kSound_Effect_switdh, true)
        self.m_csbOwner["spr_sound_off"]:setVisible(false)
    else
        gLobalDataManager:setBoolByField(kSound_Effect_switdh, false)
        self.m_csbOwner["spr_sound_off"]:setVisible(true)
    end
end

-- fb 点击事件
function SettingsLayerItem:fbBtnTouchEvent()
    if globalFaceBookManager:getFbLoginStatus() then
        globalFaceBookManager:fbLogOut()
        gLobalSendDataManager:getNetWorkLogon():logoutGame()
    else
        globalData.skipForeGround = true
        gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos = LOG_ENUM_TYPE.BindFB_Settings
        globalFaceBookManager:fbLogin()
        release_print("xcyy : SettingLayer FbLoginBtn Click")
    end
end

-- 设置是否大奖推送
function SettingsLayerItem:winnerNotifyTouchEvent()
    --默认值
    local defalueFlag = false
    if globalData.constantData.WINNER_NOTIFICATIONS_FLAG and globalData.constantData.WINNER_NOTIFICATIONS_FLAG == 1 then
        defalueFlag = true
    end
    local winnerStatus = gLobalDataManager:getBoolByField(WINNER_NOTIFICATIONS, defalueFlag)
    if winnerStatus == false or winnerStatus == nil then
        gLobalDataManager:setBoolByField(WINNER_NOTIFICATIONS, true)
        self.m_csbOwner["spr_champion_off"]:setVisible(false)
        globalData.jackpotPushFlag = true
    else
        gLobalDataManager:setBoolByField(WINNER_NOTIFICATIONS, false)
        self.m_csbOwner["spr_champion_off"]:setVisible(true)
        globalData.jackpotPushFlag = false
    end
end

function SettingsLayerItem:registerListenerFB()
    gLobalNoticManager:addObserver(
        self,
        function(self, bLogonOutStatus)
            self:setFbBtnStatus()
            gLobalViewManager:removeLoadingAnima()
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(data)
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD,
        true
    )

    --服务器返回成功消息
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            self:setFbBtnStatus()
            gLobalViewManager:removeLoadingAnima()
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS,
        true
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

function SettingsLayerItem:checkFBLoginState(loginInfo)
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
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        elseif loginState == 0 then
            --失败
        else
        end
    else
        if loginInfo then
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        end
    end
end

function SettingsLayerItem:registerListenerToken()
    -- 游客用户绑定token成功 重新登录游戏
    gLobalNoticManager:addObserver(
        self,
        function(target, uuid)
            -- gLobalSendDataManager:saveDeviceUuid(uuid)
            gLobalViewManager:removeLoadingAnima()
        end,
        ViewEventType.GUEST_USER_BIND_TOKEN_SUCCESS,
        true
    )
end

function SettingsLayerItem:loginFail(_errorData)
    -- 登录失败 -- 添加提示界面 
    local view = util_createView("views.logon.Logonfailure", true)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
    view:setFailureDescribe(_errorData)
end

-- function SettingsLayerItem:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

-- 发送弹板log
function SettingsLayerItem:sendClickFbUrlLog()
    local layerActType = "SettingFB" -- 加好友弹板

    gLobalSendDataManager:getLogFbFun():sendFbActLog(layerActType, "Click", nil, "Setting")
end

-- 点击苹果 按钮
function SettingsLayerItem:clickAppleBtnEvt()
    local loginType = gLobalSendDataManager:getLogGameLoad():getLoginType()
    if loginType == "APPLE" then
        self:signUpWithApple()
    else
        self:signInWithApple()
        
    end
end
-- 登出苹果
function SettingsLayerItem:signUpWithApple()
    -- 清除 apple登录 userid
    gLobalDataManager:setStringByField("luaappleuserid", "")
    gLobalSendDataManager:getNetWorkLogon():logoutGame()
end
-- 登录苹果
function SettingsLayerItem:signInWithApple()
    local function appleLoginCallBack(param)
        local paramInfo = loadstring(param)()
        local flag = paramInfo.flag
        if flag == 1 then
            local saveInfo = {
                user = paramInfo.user,
                token = paramInfo.token
            }
            gLobalDataManager:setStringByField("luaappleuserid", paramInfo.user)
            local loginType = gLobalSendDataManager:getLogGameLoad():getLoginType()
            if globalFaceBookManager:getFbLoginStatus() then
                gLobalDataManager:setStringByField("TryAutoAppleLoginInfo", json.encode(saveInfo))
                globalFaceBookManager:fbLogOut()
            elseif loginType == "GUEST" then
                gLobalDataManager:setStringByField("TryAutoAppleLoginInfo", json.encode(saveInfo))
            end
            gLobalSendDataManager:getNetWorkLogon():logoutGame()
        end
    end
    xcyy.GameBridgeLua:appleIDLogin(appleLoginCallBack)
end

function SettingsLayerItem:setBtnSwallow()
    local btn_music = self:findChild("btn_music")
    if btn_music then
        btn_music:setSwallowTouches(false)
    end

    local btn_fb_out = self:findChild("btn_fb_out")
    if btn_fb_out then
        btn_fb_out:setSwallowTouches(false)
    end

    local btn_fb_connect = self:findChild("btn_fb_connect")
    if btn_fb_connect then
        btn_fb_connect:setSwallowTouches(false)
    end

    local btn_fenpage = self:findChild("btn_fenpage")
    if btn_fenpage then
        btn_fenpage:setSwallowTouches(false)
    end

    local btn_sound = self:findChild("btn_sound")
    if btn_sound then
        btn_sound:setSwallowTouches(false)
    end

    local btn_champion = self:findChild("btn_champion")
    if btn_champion then
        btn_champion:setSwallowTouches(false)
    end

    local btn_copy = self:findChild("btn_copy")
    if btn_copy then
        btn_copy:setSwallowTouches(false)
    end

    local btn_login = self:findChild("btn_login")
    if btn_login then
        btn_login:setSwallowTouches(false)
    end

    local btn_fixup = self:findChild("btn_fixup")
    if btn_fixup then
        btn_fixup:setSwallowTouches(false)
    end

    local btn_apple = self:findChild("btn_apple")
    if btn_apple then
        btn_apple:setSwallowTouches(false)
    end

    local btn_delete = self:findChild("btn_delete")
    if btn_delete then
        btn_delete:setSwallowTouches(false)
    end

    local btn_notification = self:findChild("btn_notification")
    if btn_notification then
        btn_notification:setSwallowTouches(false)
    end
end


-- 设置音效
function SettingsLayerItem:shakeBtnTouchEvent()
    local key_switch = "isDeviceVibrate"
    local soundStatus = gLobalDataManager:getBoolByField(key_switch, true)
    if soundStatus == false or soundStatus == nil then
        gLobalDataManager:setBoolByField(key_switch, true)
        self.m_csbOwner["spr_vibration_off"]:setVisible(false)
    else
        gLobalDataManager:setBoolByField(key_switch, false)
        self.m_csbOwner["spr_vibration_off"]:setVisible(true)
    end
end

function SettingsLayerItem:onEnter()
    SettingsLayerItem.super.onEnter(self)

    if self.m_path == "notification" then
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                self:setNotificationStatus()
            end,
            ViewEventType.COMMON_FORE_GROUND
        )
    end
end

return SettingsLayerItem
