--[[--
    没有FaceBook登陆时 显示的界面
]]
local BaseView = util_require("base.BaseView")
local InboxPage_send_noFBLogin = class("InboxPage_send_noFBLogin", BaseView)

function InboxPage_send_noFBLogin:initUI()
    self:createCsbNode("InBox/FBCard/InboxPage_Send_NoFBLogin.csb")
end

function InboxPage_send_noFBLogin:updateUI()
    
end

function InboxPage_send_noFBLogin:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_fbConnect" then
        self:gotoFBConnect()
    end
end

function InboxPage_send_noFBLogin:gotoFBConnect()
    -- FB登陆
    if gLobalSendDataManager:getIsFbLogin() == false then
        if globalFaceBookManager:getFbLoginStatus() then
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Inbox)

        else
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
	    end
    else
        globalFaceBookManager:fbLogOut()
        gLobalSendDataManager:getNetWorkLogon():logoutGame()
    end    
end

return InboxPage_send_noFBLogin