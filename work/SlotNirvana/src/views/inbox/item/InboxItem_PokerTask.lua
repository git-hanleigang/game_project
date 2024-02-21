--[[
    扑克任务邮件
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_PokerTask = class("InboxItem_PokerTask", InboxItem_base)

function InboxItem_PokerTask:initData()
    InboxItem_PokerTask.super.initData(self)
    self:initDropNextEvent()
end

-- 描述说明
function InboxItem_PokerTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

function InboxItem_PokerTask:initDropNextEvent()
    local _doFuncList = {}
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerDropCards)
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerMergeBagView)
    self.m_dropFuncList = _doFuncList
end

-- 检测 list 调用方法
function InboxItem_PokerTask:triggerNextFunc()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        self:removeSelfItem()
        return
    end
    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉落卡牌
function InboxItem_PokerTask:triggerDropCards()
    if CardSysManager:needDropCards("Poker Mission") == true then
        CardSysManager:doDropCards(
            "Poker Mission",
            function()
                if not tolua.isnull(self) and self.triggerNextFunc then
                    self:triggerNextFunc()
                end
            end
        )
    else
        self:triggerNextFunc()
    end
end

-- 检测掉落 合成福袋
function InboxItem_PokerTask:triggerMergeBagView()
    local mergeBagList = self:getMergeBagList()
    G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):popMergePropsBagRewardPanel(
        mergeBagList,
        function()
            if not tolua.isnull(self) and self.triggerNextFunc then
                self:triggerNextFunc()
            end
        end
    )
end

-- 检测高倍场体验卡
function InboxItem_PokerTask:triggerDeluxeCard()
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM,
        function()
            if not tolua.isnull(self) and self.triggerNextFunc then
                self:triggerNextFunc()
            end
        end
    )
end

function InboxItem_PokerTask:getCsbName()
    return "InBox/InboxItem_PokerMission.csb"
end

-- 合成福袋的数据
function InboxItem_PokerTask:getMergeBagList()
    local list = {}
    if self.m_mailData.awards and self.m_mailData.awards.items and #self.m_mailData.awards.items > 0 then
        for i = 1, #self.m_mailData.awards.items do
            local tempData = ShopItem:create()
            tempData:parseData(self.m_mailData.awards.items[i])
            if string.find(tempData.p_icon, "Pouch") then
                table.insert(list, tempData)
            end
        end
    end
    return list
end

function InboxItem_PokerTask:collectMailSuccess()
    if self.m_coins > 0 then 
        self:flyBonusGameCoins(
            function()
                if not tolua.isnull(self) and self.triggerNextFunc then
                    self:triggerNextFunc()
                end
            end
        )
    else
        self:triggerNextFunc()
    end
end

return InboxItem_PokerTask
