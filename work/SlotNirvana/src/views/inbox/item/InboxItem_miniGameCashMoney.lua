--[[
Author: dhs
Date: 2022-04-28 14:52:28
LastEditTime: 2022-05-16 14:25:01
LastEditors: bogon
Description: CashMoney 通用道具化 邮件
FilePath: /SlotNirvana/src/views/inbox/CashMoneyPurchaseLayer.lua
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_miniGameCashMoney = class("InboxItem_miniGameCashMoney", InboxItem_base)

function InboxItem_miniGameCashMoney:getCsbName()
    return "InBox/InboxItem_CashMoney.csb"
end
-- 描述说明
function InboxItem_miniGameCashMoney:getDescStr()
    return "CASH MONEY", "Play and win big prize!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_miniGameCashMoney:getExpireTime()
--     local gameId = self.m_mailData.gameId
--     local currGameData = G_GetMgr(G_REF.CashMoney):getDataByGameId(gameId)
--     if currGameData then
--         self.m_gameId = gameId
--         local time = currGameData:getExpireAt()
--         time = time / 1000
--         return time
--     else
--         return 0
--     end
-- end

function InboxItem_miniGameCashMoney:initView()
    self.m_gameId = self.m_mailData.m_gameId
    InboxItem_miniGameCashMoney.super.initView(self)
end

function InboxItem_miniGameCashMoney:clickFunc(sender)
    -- 判断资源是否下载
    if not G_GetMgr(G_REF.CashMoney):isDownloadRes() then
        return
    end

    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
        -- 获取数据
        local dataType = G_GetMgr(G_REF.CashMoney):getDataType()
        local gameType = G_GetMgr(G_REF.CashMoney):getGameType()
        local gameData = G_GetMgr(G_REF.CashMoney):getPlayStatusGameData(dataType.PUT)
        if gameData then
            --
            local isReward = gameData:getRewardStatus() -- 是否完成普通版
            local isMark = gameData:getMarkStatus() -- 是否带付费项
            local isPay = gameData:getPayStatus() -- 是否购买过付费版次数
            local type = gameType.NORMAL
            if isMark then
                if isReward or isPay then
                    type = gameType.PAID
                end
            end
            local viewData = {
                gameData = gameData,
                isReconnc = true
            }

            G_GetMgr(G_REF.CashMoney):showCashMoneyGameView(viewData, type, self.m_callBack)
        else
            self:registerListener()
            local data = G_GetMgr(G_REF.CashMoney):getData()
            if data then
                -- 获取来源为PUT的投放游戏数据
                local gameList = data:getGameListByType(dataType.PUT)
                if table.nums(gameList) > 0 then
                    for i, v in pairs(gameList) do
                        self.m_gameId = v.gameData:getGameId()
                        
                        G_GetMgr(G_REF.CashMoney):sendPlay(self.m_gameId)
                        break
                    end
                else
                    self:closeUI()
                end
            end
        end
    end
end

function InboxItem_miniGameCashMoney:closeInbox()
    local btn_collect = self:findChild("btn_inbox")
    btn_collect:setTouchEnabled(false)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

function InboxItem_miniGameCashMoney:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.success then
                local data = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)
                local gameType = G_GetMgr(G_REF.CashMoney):getGameType()
                local viewData = {
                    gameData = data,
                    isReconnc = false
                }
                G_GetMgr(G_REF.CashMoney):showCashMoneyGameView(viewData, gameType.NORMAL)
                self:closeInbox()
            else
                G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
            end
        end,
        ViewEventType.NOTIFY_CASH_MONEY_PLAY
    )
end

function InboxItem_miniGameCashMoney:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_miniGameCashMoney
