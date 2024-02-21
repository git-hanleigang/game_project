--
--大厅关卡容器节点 用来放JACKPOT 或者一列多个关卡情况
--
local LevelFaceBookNode = class("LevelFaceBookNode", util_require("base.BaseView"))
LevelFaceBookNode.m_touch = nil
LevelFaceBookNode.m_index = nil

function LevelFaceBookNode:initUI()
    self:createCsbNode("newIcons/Level_FaceBook.csb")
    self.m_content = self:findChild("content")
    if not self.m_content then
        release_print("not  content")
    end

    local size = self.m_content:getContentSize()
    self.m_contentLenX = size.width * 0.5
    self.m_contentLenY = size.height * 0.5
    local touch = self:makeTouch(self.m_content)
    self:addChild(touch, 1)
    self:addClick(touch)
    self.m_touch = touch

    self.m_lbsCoin = self:findChild("lb_shuzi2")
    self:updateFbReward()
end

function LevelFaceBookNode:updateFbReward()
    if self.m_lbsCoin then
        self.m_lbsCoin:setString(util_formatMoneyStr(globalData.FBRewardData:getCoins()))
    end
end

function LevelFaceBookNode:getContentLen()
    return self.m_contentLenX, self.m_contentLenY
end

function LevelFaceBookNode:getOffsetPosX()
    return self.m_contentLenX
end

function LevelFaceBookNode:updateUI()
end

--根据content大小创建按钮监听
function LevelFaceBookNode:makeTouch(content)
    local touch = ccui.Layout:create()
    touch:setName("touch")
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(true)
    touch:setAnchorPoint(0.5000, 0.5000)
    touch:setContentSize(content:getContentSize())
    touch:setClippingEnabled(false)
    touch:setBackGroundColorOpacity(0)
    return touch
end

--点击回调
function LevelFaceBookNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalViewManager:addLoadingAnima()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    performWithDelay(
        self,
        function()
            self:clickFaceBook()
        end,
        0.2
    )
end
function LevelFaceBookNode:MyclickFunc()
    gLobalViewManager:addLoadingAnima()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    performWithDelay(
        self,
        function()
            self:clickFaceBook()
        end,
        0.2
    )
end

function LevelFaceBookNode:clickFaceBook()
    if gLobalSendDataManager:getIsFbLogin() == false then --是否登陆facebook
        if globalFaceBookManager:getFbLoginStatus() then --条件1
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Banner)
        else
            gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos = LOG_ENUM_TYPE.BindFB_Banner
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
        end
    end
end

function LevelFaceBookNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function LevelFaceBookNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(data)
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD,
        true
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

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            self:updateFbReward()
        end,
        ViewEventType.NOTIFY_FBREWARD_UPDATE
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

function LevelFaceBookNode:loginFail(errorData)
    -- 登录失败 -- 添加提示界面 
    local view = util_createView("views.logon.Logonfailure", true)
    view:setFailureDescribe(errorData)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
end

function LevelFaceBookNode:checkFBLoginState(loginInfo)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end
    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
        local loginState = loginInfo.state
        local msg = loginInfo.message
        --成功
        if loginState == 1 then
            --取消
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        elseif loginState == 0 then
            --失败
            gLobalViewManager:removeLoadingAnima()
        else
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(nil)
        end
    else
        if loginInfo then
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        else
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(nil)
        end
    end
end

return LevelFaceBookNode
