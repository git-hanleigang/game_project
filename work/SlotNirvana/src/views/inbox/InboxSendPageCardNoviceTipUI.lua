--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-06 11:12:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-06 11:28:13
FilePath: /SlotNirvana/src/views/inbox/InboxSendPageCardNoviceTipUI.lua
Description: 邮箱送卡 新手期集卡提示气泡
--]]
local InboxSendPageCardNoviceTipUI = class("InboxSendPageCardNoviceTipUI", BaseView)

function InboxSendPageCardNoviceTipUI:getCsbName()
    return "InBox/FBCard/InboxPage_send_card_novice_tip.csb"
end

function InboxSendPageCardNoviceTipUI:initUI()
    InboxSendPageCardNoviceTipUI.super.initUI(self)

    self:setVisible(false)
    self:setName("InboxSendPageCardNoviceTipUI")
end

function InboxSendPageCardNoviceTipUI:showTip()
    self:setVisible(true)
    self:runCsbAction("show", false, function()
        performWithDelay(self, function()
            self:hideTip()
        end, 3)
    end, 60)
end

function InboxSendPageCardNoviceTipUI:hideTip()
    self:stopAllActions()
    self:runCsbAction("hide", false, function()
        self:setVisible(false)
    end, 60)
end

function InboxSendPageCardNoviceTipUI:switchVisible()
    if self:isVisible() then
        self:hideTip()
    else
        self:showTip()
    end
end

return InboxSendPageCardNoviceTipUI