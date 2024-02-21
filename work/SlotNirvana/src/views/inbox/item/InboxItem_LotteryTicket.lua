--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{dhs}
    time:2021-11-19 15:39:58
    filepath:/SlotNirvana/src/views/inbox/InboxItem_LotteryTicket.lua
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")

local InboxItem_LotteryTicket = class("InboxItem_LotteryTicket", InboxItem_base)

function InboxItem_LotteryTicket:getCsbName()
    return "InBox/InboxItem_LotteryTicket.csb"
end
-- 描述说明
function InboxItem_LotteryTicket:getDescStr()
    return "SPECIAL LOTTERY", "It can be used in a new issue"
end

function InboxItem_LotteryTicket:initView()
    self:initTime()
    self:initDesc()
    self:initLotteryNum()
end

function InboxItem_LotteryTicket:collectMailSuccess()
    self:removeSelfItem()
    self:gainRewardSuccess()
end

function InboxItem_LotteryTicket:initLotteryNum()
    local reward = nil
    local collecData = G_GetMgr(G_REF.Inbox):getSysRunData()
    if not collecData then
        return
    end
    local mailData = collecData:getMailData()
    for i = 1, #mailData do
        if mailData[i].type == InboxConfig.TYPE_NET.LotteryTicket then
            local awards = mailData[i].awards
            if awards ~= nil then
                if awards.items ~= nil then
                    reward= {}
                    for i = 1, #awards.items do
                        reward[i] = awards.items[i].id
                    end
                    self.m_ticketsList = reward
                end
            end
            break
        end
    end
end

-- 领取成功
function InboxItem_LotteryTicket:gainRewardSuccess()
    --TODO 领取奖励后需要弹框操作
    local tickets = 0
    local ticketsList = self:initLotteryNum()
    if self.m_ticketsList and  #self.m_ticketsList > 0 then
        tickets = #self.m_ticketsList
    end

    G_GetMgr(G_REF.Lottery):showTicketView(nil, nil,tickets)
end

return InboxItem_LotteryTicket
