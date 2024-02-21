--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-28 11:37:26
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-28 11:41:48
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMesage_JackpotShareRewards.lua
Description: jackpot大奖分享聊天数据 other
--]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatConfig = util_require("data.clanData.ChatConfig")
local ClanChatMessageBase = util_require("views.clan.chat.ClanChatMessage_reward")
local ClanChatMesage_JackpotShareRewards = class("ClanChatMesage_JackpotShareRewards", ClanChatMessageBase)

function ClanChatMesage_JackpotShareRewards:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_grand_other.csb"
end

function ClanChatMesage_JackpotShareRewards:getDefaultImgPath()
    return "Club/ui_new/chat/img_grand_share_default_other.png"
end

function ClanChatMesage_JackpotShareRewards:readNodes()
    ClanChatMessageBase.readNodes(self)

    self.m_layoutShareImg = self:findChild("layout_shareImg")
    self.m_nodeShareImg = self:findChild("node_img")
    self:addClick(self.m_layoutShareImg)
    self.m_layoutShareImg:setSwallowTouches(false)
    self.m_wordSize = self.font_word:getContentSize()
end

function ClanChatMesage_JackpotShareRewards:resetPosition()
    ClanChatMesage_JackpotShareRewards.super.resetPosition(self)

    local content_size = self:getBubbleSize()
    self.font_word:setPositionX(content_size.width - self.item_offset2Edge)
end

function ClanChatMesage_JackpotShareRewards:updateContent()
    self:updateRewardLbUI()
    self:updateShareImgUI()

    self.btn_send:setVisible(self.data.status == 0)
    self.sp_duihao:setVisible(self.data.status == 1)
end

-- 中奖 关卡lb
function ClanChatMesage_JackpotShareRewards:updateRewardLbUI()
    local content = ""
    if self.data.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT_SHARE then
        local name = "game"
        if self.data.content and #self.data.content > 0 then
            local info = cjson.decode(self.data.content)
            name = info.game or "game"
            self.m_imgPath = info.path
        end
        content = "Won a jackpot in " .. name
    else
        content = "This is an unknown type"
    end

    self.font_word:ignoreContentAdaptWithSize(true)
    self.font_word:setTextAreaSize(cc.size(240, 0))
    self.font_word:setString(content)
    local wordSize = self.font_word:getContentSize()
    if wordSize.height > self.m_wordSize.height then
        local scale = self.m_wordSize.height / wordSize.height
        self.font_word:setTextAreaSize(cc.size(240 / scale, 0))
        self.font_word:setScale(scale)
    end
end

-- 分享的图片
function ClanChatMesage_JackpotShareRewards:updateShareImgUI()
    if not self.m_imgPath then
        return
    end

    local size = self.m_layoutShareImg:getContentSize()
    local sp = G_GetMgr(G_REF.MachineGrandShare):getShareImgSp(self.m_imgPath, size, self:getDefaultImgPath(), true)
    self.m_nodeShareImg:addChild(sp)
    self.m_shareSprite = sp
end

function ClanChatMesage_JackpotShareRewards:clickFunc( sender )
    ClanChatMesage_JackpotShareRewards.super.clickFunc(self, sender)

    local senderName = sender:getName()
    if senderName == "layout_shareImg" and self.m_shareSprite and self.m_shareSprite:checkLoadUrlImgSuccess() then
       ClanManager:popGrandShareImgLayer(self.m_imgPath, self:getMessageId())
    end
end

-- 跟父类的区别就是去掉了底边空白区域
function ClanChatMesage_JackpotShareRewards:getBubbleSize()
    local content_size = self:getInnerSize()
    return content_size
end

function ClanChatMesage_JackpotShareRewards:getInnerSize()
    return self.bubbleBgSize
end

return ClanChatMesage_JackpotShareRewards
