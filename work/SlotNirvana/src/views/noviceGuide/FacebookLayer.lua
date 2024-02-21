local FacebookLayer = class("FacebookLayer", util_require("base.BaseView"))
function FacebookLayer:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("NoviceGuide/FBLayer.csb", isAutoScale)

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
            end
        )
    else
        self:runCsbAction("show")
    end
end

function FacebookLayer:onKeyBack()
end

function FacebookLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_close" or name == "btn_no" then
        self:closeUI()
    elseif name == "btn_facebook" then
        self:MyclickFunc()
    end
end

function FacebookLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                self:removeFromParent()
            end
        )
    else
        self:runCsbAction(
            "over",
            false,
            function()
                self:removeFromParent()
            end
        )
    end
end

function FacebookLayer:MyclickFunc()
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

function FacebookLayer:clickFaceBook()
    if gLobalSendDataManager:getIsFbLogin() == false then --是否登陆facebook
        if globalFaceBookManager:getFbLoginStatus() then --条件1
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        else
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
        end
    end
end

function FacebookLayer:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function FacebookLayer:onEnter()
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

function FacebookLayer:loginFail(errorData)
    -- 登录失败 -- 添加提示界面 
    local view = util_createView("views.logon.Logonfailure", true)
    view:setFailureDescribe(errorData)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
    self:closeUI()
end

function FacebookLayer:checkFBLoginState(loginInfo)
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

return FacebookLayer
