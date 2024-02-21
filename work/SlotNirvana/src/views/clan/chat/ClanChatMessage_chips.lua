--[[
Author: cxc
Date: 2021-02-19 20:08:45
LastEditTime: 2021-02-26 14:22:13
LastEditors: Please set LastEditors
Description: 聊天 cell 内容
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMessage_chips.lua
--]]

local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")
local ClanChatMessageBase = util_require("views.clan.chat.ClanChatMessageBase")
local ClanChatMessage_chips = class("ClanChatMessage_chips", ClanChatMessageBase)
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local word_width_max = 260
 
local chip_debug = false

function ClanChatMessage_chips:initUI( data )
    ClanChatMessageBase.initUI(self, data)

    self.onAnimation = false
    self:resetCardData()
end

function ClanChatMessage_chips:readNodes()
    ClanChatMessageBase.readNodes(self)
    -- 卡牌节点
    self.node_chips = self:findChild("node_chips")
    self.sp_duihao = self:findChild("sp_duihao")
    local btn_send = self:findChild("btn_send")
    if btn_send then
        self.btn_send = btn_send
    end
    local sp_bubble = self:findChild("sp_bubble")
    if sp_bubble then
        self.sp_bubble = sp_bubble
    end
    
    self.word_width = self.font_word:getContentSize().width * self.font_word:getScaleX()
    self.item_width_max = self.bubbleBgSize.width - self.item_offset2Edge * 2
    self.item_height_max = self.bubbleBgSize.height - self.item_offset2Edge

    self.node_chips_posx = self.node_chips:getPositionX()
    self.sp_duihao_posx = self.sp_duihao:getPositionX()
    if self.btn_send then
        self.btn_send_posx = self.btn_send:getPositionX()
    end
end

function ClanChatMessage_chips:getCsbPath()
    if self:isMyMessage() then
        return "Club/csd/Chat_New/Club_wall_chatbubble_chips_self.csb"
    else
        return "Club/csd/Chat_New/Club_wall_chatbubble_chips_other.csb"
    end
end

function ClanChatMessage_chips:setData(data)
    ClanChatMessageBase.setData(self, data)
    self:resetCardData()
end

function ClanChatMessage_chips:resetCardData()
    if self.data.content and self.data.content ~= "" then
        local chipData = cjson.decode(self.data.content)
        if chipData.card then
            self.cardData = chipData.card
        end
    end
end

function ClanChatMessage_chips:updateContent()
    if self.data.status == 0 then
        if chip_debug then
            local count = self:getCardCount()
            if not count then
                count = "nil"
            end
            self.font_word:setString("Can you send me " .. count)
        else
            self.font_word:setString("Can you send me")
        end
    else
        local name = "someone"
        if self.data.extendData and self.data.extendData.senderName then
            name = self.data.extendData.senderName
        end
        local content = string.format("Thank %s for sending me", name)
        util_AutoLine(self.font_word, content, word_width_max, true)
    end
    self.font_word:enableOutline(self.font_word:getTextColor(), 1)
    
    if not self.chipItem then
        if self.cardData then
            local cardData = clone(self.cardData)
            cardData.count = 1
            local chipItem = util_createView("GameModule.Card.season201903.MiniChipUnit")
            chipItem:playIdle()
            chipItem:reloadUI(cardData, true)
            chipItem:addTo(self.node_chips)
            chipItem:setScale(0.25)
            self.chipItem = chipItem
        end
    end
    

    self.sp_duihao:setVisible(self.data.status == 1)
    self:updateBtnState()
end

function ClanChatMessage_chips:updateBtnState()
    if not self.btn_send then
        return
    end

    self.btn_send:setVisible(self.data.status == 0)
    -- self.btn_send:setTouchEnabled(self.data.status == 0)
    -- self.btn_send:setBright(self:canSendCard())
    self:setButtonLabelDisEnabled("btn_send", self:canSendCard())

    local btnBubble = self:findChild("btn_bubble")
    if btnBubble then
        btnBubble:setVisible(self.data.status == 0 and not self:canSendCard())
    end
end

function ClanChatMessage_chips:resetPosition()
    ClanChatMessageBase.resetPosition(self)
    
    local width_offset = self:getWidthOffset()
    local sign_width = 0
    if self:isMyMessage() then
        if self.data.status == 0 then
            sign_width = self.sp_duihao:getContentSize().width * self.sp_duihao:getScaleX()
        end
    end
    self.node_chips:setPositionX(self.node_chips_posx + width_offset + sign_width)
    self.sp_duihao:setPositionX(self.sp_duihao_posx + width_offset)
    if self.sp_bubble then
        self.sp_bubble:setPositionX(self.sp_duihao_posx + width_offset + 70)
    end
    if self:findChild("node_send") then
        self:findChild("node_send"):setPositionX(self.sp_duihao_posx + width_offset)
    end
end

function ClanChatMessage_chips:getCardCount()
    if not self.cardData then
        return
    end
    
    local cardId = self.cardData.cardId
    if not cardId then
        return
    end

    local cardData = ChatManager:getCardDataById(cardId)
    if cardData and cardData.count then
        return cardData.count
    end
end

function ClanChatMessage_chips:canSendCard()
    local cardCount = self:getCardCount()
    -- 从202203赛季开始，只有一张卡，多余卡转换为商城积分
    if tonumber(self.cardData.albumId) < 202203 then
        if cardCount and cardCount > 1 then
            return true
        end
    else        
        if cardCount and cardCount > 0 then
            return true
        end
    end
    
    return false
end

function ClanChatMessage_chips:clickFunc( sender )
    local senderName = sender:getName()
    if senderName == "btn_send" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self:canSendCard() then
            ClanManager:requestCardGiven(self.data.sender, self.cardData.cardId, self.data.msgId)
        end
    elseif senderName == "btn_bubble" then
        if self.onAnimation == true then
            return
        end
        self.onAnimation = true
        self:runCsbAction("start", false, function()
            util_performWithDelay(self, function()
                self:runCsbAction("over", false)
                self.onAnimation = false
            end, 1)
        end)
    elseif senderName == "layout_touch" then
       if self.data.sender == globalData.userRunData.userUdid then
           G_GetMgr(G_REF.UserInfo):showMainLayer()
       else
           G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.sender, "","",self.data.frameId)
       end
    end
end

function ClanChatMessage_chips:getInnerSize()
    local size = {width = self.item_width_max, height = self.item_height_max}
    local word_width = self.font_word:getContentSize().width * self.font_word:getScaleX()
    local sign_width = 0
    if self:isMyMessage() then
        if self.data.status == 0 then
            sign_width = self.sp_duihao:getContentSize().width * self.sp_duihao:getScaleX()
        end
    end
    size.width = size.width - sign_width + (word_width - self.word_width)

    return size
end

-- 背景框大小
function ClanChatMessage_chips:getBubbleSize()
    local content_size = self:getInnerSize()
    -- 计算文本显示区域
    content_size.width = content_size.width + self.item_offset2Edge * 2
    content_size.height = content_size.height + self.item_offset2Edge
    
    local name_width = self.font_name:getContentSize().width * self.font_name:getScaleX()
    local time_width = self.font_time:getContentSize().width * self.font_time:getScaleX()
    local info_width = name_width + time_width + self.info_offset + self.item_offset2Edge * 2
    if content_size.width < info_width then
        content_size.width = info_width
    end
    return content_size
end

-- 背景框高度
function ClanChatMessageBase:getHeightOffset()
    local content_size = self:getBubbleSize()
    return content_size.height - self.bubbleBgSize.height
end

function ClanChatMessage_chips:onEnter()
    gLobalNoticManager:addObserver(self, function()
        self:updateUI()
    end, ChatConfig.EVENT_NAME.NOTIFY_CARD_DATA_READY)
    -- 送卡后更新卡的信息
    gLobalNoticManager:addObserver(self,function(self, singleCardData)
        if singleCardData and self.cardData and singleCardData.cardId == self.cardData.cardId then
            self:updateUI()
            self:setButtonLabelDisEnabled("btn_send", false)
        end
    end,ChatConfig.EVENT_NAME.NOTIFY_CARD_DATA_CHANGE)
    -- 卡 已经被其他玩家送了
    gLobalNoticManager:addObserver(self,function(self, _msgId)
        if _msgId  == self.data.msgId then
            self.data.status = 1
            self:updateUI()
            self:setButtonLabelDisEnabled("btn_send", false)
        end
    end,ChatConfig.EVENT_NAME.NOTIFY_CARD_HAD_SEND)
end

function ClanChatMessage_chips:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return ClanChatMessage_chips