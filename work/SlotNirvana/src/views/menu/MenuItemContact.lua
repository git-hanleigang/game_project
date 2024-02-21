--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = require("views.menu.BaseMenuItem")
local MenuItemContact = class("MenuItemContact", BaseMenuItem)

function MenuItemContact:initUI(bDeluxe)
    MenuItemContact.super.initUI(self, bDeluxe)
    self:updateNewMessageUi(globalData.newMessageNums)
end

function MenuItemContact:initView(bDeluxe)
    MenuItemContact.super.initView(self, bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spItemN, "Option/ui/btn_contact_up1.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_contact_down1.png")
    else
        util_changeTexture(self.m_spItemN, "Option/ui/btn_contact_up.png")
        util_changeTexture(self.m_spItemD, "Option/ui/btn_contact_down.png")
    end
end

function MenuItemContact:onEnter()
    MenuItemContact.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(Target, _popType)
            self:openRobot(_popType)
        end,
        ViewEventType.NOTIFY_OPEN_ROBOT
    )
end

function MenuItemContact:clickFunc(sender)
    MenuItemContact.super.clickFunc(self, sender)
    self:onClickContact()
end

function MenuItemContact:onClickContact()
    globalData.newMessageNums = nil

    performWithDelay(
        self,
        function()
            globalData.skipForeGround = true

            local bVersion = util_isSupportVersion("1.2.9")
            if device.platform == "android" then
                bVersion = util_isSupportVersion("1.3.0")
            end
            if bVersion then
                self:openRobot()
            else
                xcyy.GameBridgeLua:sendEmail()
            end
        end,
        0.2
    )
end

-- 开启客服界面
function MenuItemContact:openHelp(_popType)
    self:updateNewMessageUi(globalData.newMessageNums)
    globalPlatformManager:openAIHelpFAQ(_popType)
end

function MenuItemContact:openRobot(_popType)
    self:updateNewMessageUi(globalData.newMessageNums)
    globalPlatformManager:openAIHelpRobot(_popType)
end

return MenuItemContact
