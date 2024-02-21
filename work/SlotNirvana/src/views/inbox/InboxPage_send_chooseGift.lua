--[[--

]]
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseGift = class("InboxPage_send_chooseGift", BaseView)

local SEND_CHOOSE_GIFTS = {
    {type = "COIN", node = "Node_coins"},
    {type = "CARD", node = "Node_chips"}
}

function InboxPage_send_chooseGift:initUI(mainClass)
    self.m_mainClass = mainClass
    self:createCsbNode("InBox/FBCard/InboxPage_Send_ChooseGift.csb")
end

function InboxPage_send_chooseGift:updateUI()
    if not self.m_chooseGiftCells then
        self.m_chooseGiftCells = {}

        for i = 1, #SEND_CHOOSE_GIFTS do
            local parentNode = self:findChild(SEND_CHOOSE_GIFTS[i].node)
            local view = util_createView("views.inbox.InboxPage_send_chooseGift_cell", SEND_CHOOSE_GIFTS[i].type, self)
            parentNode:addChild(view)
            self.m_chooseGiftCells[i] = view
        end
    end

    for i = 1, #self.m_chooseGiftCells do
        self.m_chooseGiftCells[i]:updateUI()
    end
end

function InboxPage_send_chooseGift:chooseGift(sendType)
    -- 赛季结束的时候不能送卡
    if sendType == "CARD" and not CardSysManager:hasSeasonOpening() then
        return
    end
    -- G_GetMgr(G_REF.Inbox):getFriendNetwork():FBInbox_requestFBFriendInfo(
    --     sendType,
    --     function()
    --         if not tolua.isnull(self) then
    --             self.m_mainClass:setSendType(sendType)
    --             self.m_mainClass:changeState("ChooseFriend")
    --         end
    --     end
    -- )

    -- TODO 好友数据 需要获取当前页签符合条件的好友列表
    G_GetMgr(G_REF.Friend):pGetAllFriendList(
        function()
            -- 刷新界面数据
            if not tolua.isnull(self) then
                self.m_mainClass:setSendType(sendType)
                self.m_mainClass:changeState("ChooseFriend")
            end
        end
    )
end

return InboxPage_send_chooseGift
