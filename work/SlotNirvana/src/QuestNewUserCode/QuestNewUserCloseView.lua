-- Created by jfwang on 2019-05-21.
-- QuestNewUserCloseView
--
local QuestNewUserCloseView = class("QuestNewUserCloseView", util_require("base.BaseView"))

function QuestNewUserCloseView:initUI(callback, isEnd)
    self.m_callback = callback
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    if isEnd then
        self:createCsbNode("QuestNewUser/Activity/csb/NewUser_QuestLinkOver_1.csb", isAutoScale)
    else
        self:createCsbNode("QuestNewUser/Activity/csb/NewUser_QuestLinkOver.csb", isAutoScale)
    end

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
                self:runCsbAction("idle", true)
            end
        )
    else
        self:runCsbAction(
            "show",
            false,
            function()
                self:runCsbAction("idle", true)
            end
        )
    end
end

function QuestNewUserCloseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clicked then
        return
    end
    self.m_clicked = true
    if name == "Button_1" then
        self:closeUI()
    elseif name == "Button_2" then
        self:closeUI()
    end
end

function QuestNewUserCloseView:closeUI()
    if self.m_close then
        return
    end
    self.m_close = true
    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                if self.m_callback then
                    self.m_callback()
                end
                self:removeFromParent(true)
            end
        )
    else
        self:runCsbAction(
            "over",
            false,
            function()
                if self.m_callback then
                    self.m_callback()
                end
                self:removeFromParent(true)
            end,
            60
        )
    end
end

return QuestNewUserCloseView
