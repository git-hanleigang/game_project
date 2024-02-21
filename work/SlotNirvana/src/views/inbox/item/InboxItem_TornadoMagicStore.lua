local InboxItem_TornadoMagicStore = class("InboxItem_TornadoMagicStore", util_require("views.inbox.item.InboxItem_baseReward"))
local ShopItem = require "data.baseDatas.ShopItem"

function InboxItem_TornadoMagicStore:getCardSource()
    return {"Tornado Magic Store"}
end

function InboxItem_TornadoMagicStore:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

function InboxItem_TornadoMagicStore:getDescStr()
    self.m_content = self.m_mailData.content
    if self.m_content and self.m_content ~= "" then
        self:setButtonLabelContent("btn_inbox", "SEE MORE")
    end
    return self.m_mailData.title or ""
end

function InboxItem_TornadoMagicStore:initData()
    InboxItem_TornadoMagicStore.super.initData(self)
    self:initDropNextEvent()
end

function InboxItem_TornadoMagicStore:initDropNextEvent()
    local _doFuncList = {}
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerDropCards)
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerMergeBagView)
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerDeluxeCard)
    self.m_dropFuncList = _doFuncList
end

-- 检测 list 调用方法
function InboxItem_TornadoMagicStore:triggerNextFunc()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        self:removeSelfItem()
        return
    end
    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉落卡牌
function InboxItem_TornadoMagicStore:triggerDropCards()
    local this = self
    if CardSysManager:needDropCards(self:getCardSource()[1]) == true then
        CardSysManager:doDropCards(
            self:getCardSource()[1],
            function()
                if not tolua.isnull(this) and this.triggerNextFunc then
                    self:triggerNextFunc()
                end
            end
        )
    else
        self:triggerNextFunc()
    end
end

-- 检测高倍场体验卡
function InboxItem_TornadoMagicStore:triggerDeluxeCard()
    local this = self
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM,
        function()
            if not tolua.isnull(this) and this.triggerNextFunc then
                this:triggerNextFunc()
            end
        end
    )
end

-- 检测掉落 合成福袋
function InboxItem_TornadoMagicStore:triggerMergeBagView()
    local this = self
    local mergeBagList = self:getMergeBagList()
    G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):popMergePropsBagRewardPanel(
        mergeBagList,
        function()
            if not tolua.isnull(this) and this.triggerNextFunc then
                this:triggerNextFunc()
            end
        end
    )
end

function InboxItem_TornadoMagicStore:getMergeBagList()
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

function InboxItem_TornadoMagicStore:collectMailSuccess()
    if toLongNumber(self.m_coins) > toLongNumber(0) then 
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

function InboxItem_TornadoMagicStore:removeSelfItem()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        InboxItem_TornadoMagicStore.super.removeSelfItem(self)
    end
end


return InboxItem_TornadoMagicStore