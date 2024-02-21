--[[--
    没有FaceBook登陆时 显示的界面
]]
local BaseView = util_require("base.BaseView")
local InboxPage_send_noVersion = class("InboxPage_send_noVersion", BaseView)

function InboxPage_send_noVersion:initUI()
    self:createCsbNode("InBox/FBCard/InboxPage_Send_NoVersion.csb")
end

function InboxPage_send_noVersion:updateUI()
    
end

function InboxPage_send_noVersion:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_update" then
        self:gotoUpdate()
    end
end

function InboxPage_send_noVersion:gotoUpdate()
    -- 跳转网页
    xcyy.GameBridgeLua:rateUsForSetting()
end

return InboxPage_send_noVersion