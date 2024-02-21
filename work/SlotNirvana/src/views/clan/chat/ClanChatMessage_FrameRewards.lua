--[[
Author: cxc
Date: 2021-11-09 11:51:57
LastEditTime: 2021-11-09 11:53:50
LastEditors: your name
Description: 头像框获得奖励
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMessage_FrameRewards.lua
--]]
local ClanChatMessage_purchase = util_require("views.clan.chat.ClanChatMessage_purchase")
local ClanChatMessage_FrameRewards = class("ClanChatMessage_FrameRewards", ClanChatMessage_purchase)

function ClanChatMessage_FrameRewards:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_frameRewards.csb"
end

function ClanChatMessage_FrameRewards:readNodes()
    ClanChatMessage_FrameRewards.super.readNodes(self)
    self.node_frame_icon = self:findChild("node_frame_icon")
end

function ClanChatMessage_FrameRewards:updateUI()
    ClanChatMessage_FrameRewards.super.updateUI(self)

    local name = self.data.nickname
    if string.len(name) <= 0 then
        name = "someone"
    end
    self.font_name:setString(name)
    
    self.font_word:setVisible(true)
    self.font_name:setVisible(true)
    
    if self.data.content and self.data.content ~= "" then
        local resdata = cjson.decode(self.data.content)
        local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(resdata.frame)
        if head_sprite then
            head_sprite:setScale(0.8)
            self.node_frame_icon:addChild(head_sprite)
        end
    end
end

return ClanChatMessage_FrameRewards