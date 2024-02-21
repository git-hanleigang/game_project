--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-04-27 15:20:02
]]
local FBGuideLayerNew = class("FBGuideLayerNew", BaseLayer)

function FBGuideLayerNew:ctor()
    FBGuideLayerNew.super.ctor(self)

    self.m_isKeyBackEnabled = true

    self:setLandscapeCsbName("FbGuide/FbGuide.csb")
    self:setName("FBGuideLayerNew")
end

function FBGuideLayerNew:initCsbNodes()
    self.m_lb_coins = self:findChild("lb_shuzi_1") -- 金币
    self.m_sp_explain = self:findChild("sp_explain")
    self.m_btnClose = self:findChild("btn_close")
    self.m_node_reward = self:findChild("node_1")
    self.m_node_info = self:findChild("node_2")
    self.m_node_info:setVisible(false)
end

function FBGuideLayerNew:initDatas()
    self.m_coins = globalData.FBRewardData:getCoins()
    self.m_itmes = globalData.FBRewardData:getItems()
end

function FBGuideLayerNew:initView()
    -- 更新金币
    self.m_lb_coins:setString(util_formatMoneyStr(self.m_coins))
    self:setExtendData("FBGuideLayerNew")
    self:addTouchLayer()
end

function FBGuideLayerNew:addTouchLayer()
    -- 初始化触摸板 --
    local size = self.m_sp_explain:getContentSize()
    local touch = ccui.Layout:create()
    touch:setName("btn_info")
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(0.5, 0.5)
    touch:setContentSize(size)
    touch:setPosition(0, -339)
    self.m_node_reward:addChild(touch)
    self:addClick(touch)
end

function FBGuideLayerNew:onShowedCallFunc()
    self:runCsbAction("idle", true)

    -- performWithDelay(
    --     self.m_lb_coins,
    --     function()
    --         self.m_isTouch = false
    --     end,
    --     3
    -- )
end

function FBGuideLayerNew:registerListener()
    FBGuideLayerNew.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(data)
            self.m_isTouch = false
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD,
        true
    )

    --服务器返回成功消息
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
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

function FBGuideLayerNew:checkFBLoginState(loginInfo)
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

function FBGuideLayerNew:clickFunc(sender)
    -- if self.m_isTouch then
    --     return
    -- end

    local name = sender:getName()
    -- 尝试重新连接 network
    if name == "btn_close" then
        if not self.m_isAmin then
            -- self.m_isTouch = true
            self:closeSelf()
        end
    elseif name == "btn_fb" then
        if self.m_isTouch then
            return
        end
        self.m_isTouch = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalViewManager:addLoadingAnima(false, nil, 5)
        performWithDelay(
            self,
            function()
                self.m_isTouch = false
                self:fbBtnTouchEvent()
            end,
            0.2
        )
    elseif name == "btn_info" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showInfo()
    end
end

function FBGuideLayerNew:fbBtnTouchEvent()
    if gLobalSendDataManager:getIsFbLogin() == false then
        if globalFaceBookManager:getFbLoginStatus() then
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_GamePop)
        else
            printInfo("xcyy :FB回调")
            gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos = LOG_ENUM_TYPE.BindFB_GamePop
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
        end
    else
        self:closeSelf()
    end
end

function FBGuideLayerNew:showInfo()
    self.m_node_reward:setVisible(false)
    self.m_node_info:setVisible(true)
    self:runCsbAction("idle1", true)
end

function FBGuideLayerNew:loginFail(errorData)
    -- 登录失败 -- 添加提示界面 
    local view = util_createView("views.logon.Logonfailure", true)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
    view:setFailureDescribe(errorData)
end

function FBGuideLayerNew:closeSelf()
    self.m_isAmin = true
    self:closeUI(
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
    )
end

return FBGuideLayerNew
