--[[
Author: cxc
Date: 2021-11-09 11:51:57
LastEditTime: 2021-11-09 11:53:50
LastEditors: your name
Description: 公会集卡收集齐奖励
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMessage_chipsRewards.lua
--]]
local ClanChatMessage_purchase = util_require("views.clan.chat.ClanChatMessage_purchase")
local ClanChatMessage_chipsRewards = class("ClanChatMessage_chipsRewards", ClanChatMessage_purchase)

function ClanChatMessage_chipsRewards:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_chipsRewards.csb"
end

function ClanChatMessage_chipsRewards:readNodes()
    ClanChatMessage_chipsRewards.super.readNodes(self)

    self.font_album = self:findChild("font_word") --卡册名字
    self.sp_album_default = self:findChild("sp_album_default") --卡册图片默认
    self.sp_album = self:findChild("sp_album") --卡册图片
end

function ClanChatMessage_chipsRewards:updateUI()
    ClanChatMessage_chipsRewards.super.updateUI(self)

    local name = self.data.nickname
    if string.len(name) <= 0 then
        name = "someone"
    end
    self.font_name:setString(name)
    
    self.font_word:setVisible(true)
    self.font_name:setVisible(true)

    -- 解析卡册数据
    local albumName = ""
    local albumId = ""
    if self.data.content and #self.data.content > 0 then
        local info = cjson.decode(self.data.content)
        albumName = info.CardClanName or ""
        albumId = info.CardClanId or ""
    end

    local content = "Collect all chips of the"
    if albumName == "" then
        content = "Collect all chips in"
        albumName = "an"
    end
    
    self.font_word_desc:setString(content)
    self.font_album:setString(albumName .. " Album!")
    util_scaleCoinLabGameLayerFromBgWidth(self.font_album, 290)

    local iconPath = ""
    if albumId ~= "" and CardResConfig then
        if CardSysRuntimeMgr:isObsidianCardWithCardId(albumId) then
            iconPath = CardResConfig.getObsidianCardClanIcon(albumId)
        else
            iconPath = CardResConfig.getCardClanIcon(albumId)
        end
        self.sp_album_default:setVisible(false)
        self.sp_album:setVisible(true)
        util_changeTexture(self.sp_album, iconPath)
    else
        self.sp_album_default:setVisible(true)
        self.sp_album:setVisible(false)
    end
end

return ClanChatMessage_chipsRewards