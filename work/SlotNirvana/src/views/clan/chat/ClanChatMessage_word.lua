--[[
Author: cxc
Date: 2021-02-19 20:08:45
LastEditTime: 2021-02-26 14:22:13
LastEditors: Please set LastEditors
Description: 聊天 cell 内容
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMessage_word.lua
--]]
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanChatMessageBase = util_require("views.clan.chat.ClanChatMessageBase")
local ClanChatMessage_word = class("ClanChatMessage_word", ClanChatMessageBase)

local emoji_path = "#Club/ui_new/chat/"

local EMOJI_SPINE_PATH_LIST = {
    "congrats",
    "friendme",
    "goodluck",
    "great",
    "helpme",
    "solucky",
    "sorry",
    "thanks",
    "welcome",
    "wow"
}

local item_height_min = 30 -- 显示文本最小高度
local item_width_max = 660 -- 最大显示长度

function ClanChatMessage_word:initUI(data)
    ClanChatMessageBase.initUI(self, data)
end

function ClanChatMessage_word:getCsbPath()
    if self:isMyMessage() then
        return "Club/csd/Chat_New/Club_wall_chatbubble_word_self.csb"
    else
        return "Club/csd/Chat_New/Club_wall_chatbubble_word_other.csb"
    end
end

function ClanChatMessage_word:readNodes()
    ClanChatMessageBase.readNodes(self)
    -- 读取和操作特殊的节点
end

function ClanChatMessage_word:updateContent()
    if string.find(self.data.content, "CustomizeEmoji_") then
        local icon_str = string.split(self.data.content, "CustomizeEmoji_")
        local icon_idx = icon_str[2]
        if icon_idx then
            self.font_word:setString("")
            if not self.m_emojiSpine then
                local spinePath = "Club/spine/emoji/" .. EMOJI_SPINE_PATH_LIST[tonumber(icon_idx)]
                local spine = util_spineCreate(spinePath, true, true, 1)
                spine:addTo(self.sp_qipao)
                self.m_emojiSpine = spine
                self.m_emojiSize = cc.size(156, 156)
            end
            return
        end
    end
    -- util_AutoLine(self.font_word, self.data.content, item_width_max, true)
    self.font_word:setString(self.data.content)
    if self.font_word:getContentSize().width > item_width_max then
        self.font_word:ignoreContentAdaptWithSize(true)
        self.font_word:setTextAreaSize(cc.size(item_width_max, 0))
    end
    self.font_word:enableOutline(self.font_word:getTextColor(), 1)
end

function ClanChatMessage_word:resetPosition()
    ClanChatMessageBase.resetPosition(self)
    if self.m_emojiSize and self.m_emojiSpine then
        local bg_size = self.sp_qipao:getContentSize()
        local emojiSize = self.m_emojiSize
        self.m_emojiSpine:setPosition(cc.p(bg_size.width / 2, emojiSize.height / 2 + self.item_offset2Edge))
    end
end

function ClanChatMessage_word:getInnerSize()
    if self.m_emojiSize then
        return cc.size(156, 156)
    end

    local word_size = self.font_word:getContentSize()
    word_size.width = word_size.width * self.font_word:getScaleX()
    if word_size.height < item_height_min then
        word_size.height = item_height_min
    end
    if word_size.width > item_width_max then
        word_size.width = item_width_max
    end
    word_size.height = word_size.height * self.font_word:getScaleY()
    return word_size
end

function ClanChatMessage_word:onEnter()
    ClanChatMessage_word.super.onEnter(self)
    if self.m_emojiSpine then
        util_spinePlay(self.m_emojiSpine, "start", true)
    end
end

return ClanChatMessage_word
