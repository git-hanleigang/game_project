--[[
    扑克排行奖励
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_PokerRank = class("InboxItem_PokerRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_PokerRank:initData()
    InboxItem_PokerRank.super.initData(self)
    self:initDropNextEvent()
end

-- 描述说明
function InboxItem_PokerRank:getDescStr()
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --名次
        self.m_rankNum = extraData.rank
        local strRank = string.format("RANK %s REWARD",self.m_rankNum)
        return strRank
    end
    return ""
end

function InboxItem_PokerRank:initDropNextEvent()
    local _doFuncList = {}
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerDropCards)
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _doFuncList[#_doFuncList + 1] = handler(self, self.triggerMergeBagView)
    self.m_dropFuncList = _doFuncList
end

-- 检测 list 调用方法
function InboxItem_PokerRank:triggerNextFunc()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        self:removeInboxItem()
        return
    end
    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉落卡牌
function InboxItem_PokerRank:triggerDropCards()
    if CardSysManager:needDropCards("Poker Rank Reward") == true then
        CardSysManager:doDropCards(
            "Poker Rank Reward",
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
function InboxItem_PokerRank:triggerMergeBagView()
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
function InboxItem_PokerRank:triggerDeluxeCard()
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM,
        function()
            if not tolua.isnull(self) and self.triggerNextFunc then
                self:triggerNextFunc()
            end
        end
    )
end

function InboxItem_PokerRank:getCsbName()
    return "InBox/InboxItem_PokerRank.csb"
end

function InboxItem_PokerRank:collectMailSuccess()
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

return InboxItem_PokerRank
