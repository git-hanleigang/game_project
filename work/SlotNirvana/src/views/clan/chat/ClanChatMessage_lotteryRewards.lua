--[[
Author: cxc
Date: 2021-12-13 11:28:00
LastEditTime: 2021-12-13 11:28:22
LastEditors: your name
Description: 公会乐透中奖奖励
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMessage_lotteryRewards.lua
--]]

local ClanChatMessage_purchase = util_require("views.clan.chat.ClanChatMessage_purchase")
local ClanChatMessage_lotteryRewards = class("ClanChatMessage_lotteryRewards", ClanChatMessage_purchase)

local PrizeTypeName = {"FIRST", "SECOND", "THIRD", "4TH", "5TH", "6TH", "7TH", "8TH", "GRAND"}

function ClanChatMessage_lotteryRewards:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_lotteryRewards.csb"
end

function ClanChatMessage_lotteryRewards:readNodes()
    ClanChatMessage_lotteryRewards.super.readNodes(self)

    self.lbPrizeName = self:findChild("font_word_desc") --奖励名称
    self.lbPrizePeriod = self:findChild("font_word") --奖励期号
end

function ClanChatMessage_lotteryRewards:updateUI()
    ClanChatMessage_lotteryRewards.super.updateUI(self)

    local name = self.data.nickname
    if string.len(name) <= 0 then
        name = "someone"
    end
    self.font_name:setString(name)
    
    self.font_word:setVisible(true)
    self.font_name:setVisible(true)
    
    local prizeName = ""
    local period = ""
    if self.data.content and #self.data.content > 0 then
        local info = cjson.decode(self.data.content)
        prizeName = "Win the " .. self:getPrizeTypeName(info.LotteryRewardType) .. " prize"
        period =  "in " .. (info.period or "") .. " Lottery"
    end

    self.lbPrizeName:setString(prizeName)
    self.lbPrizePeriod:setString(period)
    util_scaleCoinLabGameLayerFromBgWidth(self.lbPrizeName, 290)
    util_scaleCoinLabGameLayerFromBgWidth(self.lbPrizePeriod, 290)
end

function ClanChatMessage_lotteryRewards:getPrizeTypeName(_number)
    _number = tonumber(_number) or 0
    if _number == 0 then 
        return ""
    end

    if _number == 99 then
        -- 头奖
        return "GRAND"
    end

    return (PrizeTypeName[_number] or "")
end

return ClanChatMessage_lotteryRewards