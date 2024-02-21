--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-28 10:24:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-28 10:25:39
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMesage_JackpotShareSelf.lua
Description: jackpot大奖分享聊天数据 self
--]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatConfig = util_require("data.clanData.ChatConfig")
local ClanChatMessageBase = util_require("views.clan.chat.ClanChatMessageBase")
local ClanChatMesage_JackpotShareSelf = class("ClanChatMesage_JackpotShareSelf", ClanChatMessageBase)

function ClanChatMesage_JackpotShareSelf:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_grand_self.csb"
end

function ClanChatMesage_JackpotShareSelf:getDefaultImgPath()
    return "Club/ui_new/chat/img_grand_share_default_me.png"
end

function ClanChatMesage_JackpotShareSelf:readNodes()
    ClanChatMessageBase.readNodes(self)
    
    self.m_layoutShareImg = self:findChild("layout_shareImg")
    self.m_nodeShareImg = self:findChild("node_img")
    self:addClick(self.m_layoutShareImg)
    self.m_layoutShareImg:setSwallowTouches(false)

    self.m_wordSize = self.font_word:getContentSize()
    self.m_imgSize = self.m_layoutShareImg:getContentSize()
end

function ClanChatMesage_JackpotShareSelf:updateContent()
    self:updateRewardLbUI()
    self:updateShareImgUI()
end

-- 中奖 关卡lb
function ClanChatMesage_JackpotShareSelf:updateRewardLbUI()
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

    util_AutoLine(self.font_word, content, 400, true)
    self.m_wordSize = self.font_word:getContentSize()
end

-- 分享的图片
function ClanChatMesage_JackpotShareSelf:updateShareImgUI()
    if not self.m_imgPath then
        return
    end

    local sp = G_GetMgr(G_REF.MachineGrandShare):getShareImgSp(self.m_imgPath, self.m_imgSize, self:getDefaultImgPath(), true)
    self.m_nodeShareImg:addChild(sp)
    self.m_shareSprite = sp
end

function ClanChatMesage_JackpotShareSelf:clickFunc( sender )
    local senderName = sender:getName()
    if senderName == "layout_shareImg" and self.m_shareSprite and self.m_shareSprite:checkLoadUrlImgSuccess() then
       ClanManager:popGrandShareImgLayer(self.m_imgPath, self:getMessageId())
    end
end

function ClanChatMesage_JackpotShareSelf:resetPosition()
    ClanChatMesage_JackpotShareSelf.super.resetPosition(self)

    local content_size = self:getBubbleSize()
    self.font_word:setPositionX(content_size.width * 0.5)
    self.m_layoutShareImg:setPositionX(content_size.width * 0.5)

    local wordPosY = self.font_word:getPositionY()
    self.m_layoutShareImg:setPositionY(wordPosY - self.m_wordSize.height)
end

function ClanChatMesage_JackpotShareSelf:getInnerSize()
    return cc.size(self.bubbleBgSize.width, self.m_wordSize.height + self.m_imgSize.height)
end

return ClanChatMesage_JackpotShareSelf