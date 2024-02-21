--[[--
    邮件页签-send
]]
local InboxPage_base = util_require("views.inbox.InboxPage_base")
local InboxPage_send = class("InboxPage_send", InboxPage_base)

-- 这里的每个界面都是互斥的
local UI_KEYS = {"NoVersion", "NoFBLogin", "ChooseGift", "ChooseFriend"}
local SENDPAGE_SHOW_STATE = {
    ["NoVersion"] = {des = "NoVersion", state = 1, luaName = "views.inbox.InboxPage_send_noVersion"},
    ["NoFBLogin"] = {des = "NoFBLogin", state = 2, luaName = "views.inbox.InboxPage_send_noFBLogin"},
    ["ChooseGift"] = {des = "ChooseGift", state = 3, luaName = "views.inbox.InboxPage_send_chooseGift"},
    ["ChooseFriend"] = {des = "ChooseFriend", state = 4, luaName = "views.inbox.InboxPage_send_chooseFriend"}
}

function InboxPage_send:initUI(mainClass, param)
    self.m_param = param
    InboxPage_base.initUI(self, mainClass)
end

function InboxPage_send:getCsbName()
    return "InBox/FBCard/InboxPage_Send.csb"
end

function InboxPage_send:clickFunc(sender)
    InboxPage_base.clickFunc(self, sender)
    local name = sender:getName()
end

function InboxPage_send:initView()
    self.m_sendNode = self:findChild("node_send")
    -- 初始化每个界面
    self.m_sendPageUIs = {}
    for i = 1, #UI_KEYS do
        local view = util_createView(SENDPAGE_SHOW_STATE[UI_KEYS[i]].luaName, self)
        self.m_sendNode:addChild(view)
        self.m_sendPageUIs[UI_KEYS[i]] = view
    end

    -- 跳转进入邮箱后，初始化发送类型
    if self.m_param and self.m_param.chooseState == "ChooseFriend" then
        if self:canSwithToChooseFriend(self.m_param.chooseType) then
            self:setSendType(self.m_param.chooseType)
        end
    end

    self:setState(self:getInitState())
    self:updateUIByState()
end

function InboxPage_send:updateUIByState()
    local state = self:getState()
    for UIKEY, view in pairs(self.m_sendPageUIs) do
        if UIKEY == state then
            view:setVisible(true)
            if view.updateUI then
                view:updateUI()
            end
        else
            view:setVisible(false)
        end
    end
end

function InboxPage_send:changeState(state)
    local curState = self:getState()
    if state == curState then
        return
    end
    self:setState(state)
    self:updateUIByState()
end

function InboxPage_send:updataInboxItem()
    InboxPage_base.updataInboxItem(self)
end

----------------------------------------------------------------------------------------------------
--[[--
    赠送类型:
        CARD 送卡
        COIN 送金币
]]
function InboxPage_send:setSendType(sendType)
    if not sendType then
        return
    end
    
    self.m_sendType = sendType
end

function InboxPage_send:getSendType()
    return self.m_sendType
end
----------------------------------------------------------------------------------------------------
--[[--
    当前显示的UI在哪一步
]]
function InboxPage_send:setState(state)
    self.m_showState = state
end

function InboxPage_send:getState()
    return self.m_showState
end
----------------------------------------------------------------------------------------------------

function InboxPage_send:canSwithToChooseFriend(sendType)
    if not sendType then
        return false
    end

    -- 等级限制
    local level = G_GetMgr(G_REF.Inbox):getFriendRunData():getLimitLevel(sendType)
    if globalData.userRunData.levelNum < level then
        return false
    end

    -- 次数限制
    local recList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordListBySendType(sendType)
    local limitNum = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendLimitBySendType(sendType)
    if #recList >= limitNum then
        return false
    end
    return true
end

function InboxPage_send:getInitState()
    if not G_GetMgr(G_REF.Inbox):getFriendRunData():isSatisfyVersion() then
        return "NoVersion"
    end
    if not G_GetMgr(G_REF.Inbox):getFriendRunData():isLoginFB() then
        return "NoFBLogin"
    end
    if self.m_param and self.m_param.chooseState == "ChooseFriend" then
        if self:canSwithToChooseFriend(self.m_param.chooseType) then
            return self.m_param.chooseState
        end
    end
    return "ChooseGift"
end

return InboxPage_send
