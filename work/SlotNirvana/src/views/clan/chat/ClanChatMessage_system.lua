

-- 公会聊天 系统提示

local ChatConfig = util_require("data.clanData.ChatConfig")
local BaseView = util_require("base.BaseView")
local ClanChatMessage_system = class("ClanChatMessage_system", BaseView)

local item_width_max = 820
local item_offset2Edge = 20  -- 距离边界的偏移值

function ClanChatMessage_system:initUI( data )
    self:setData(data)
    self:createCsbNode("Club/csd/Chat_New/Club_wall_chatbubble_system.csb")
    self:readNodes()
    self:updateUI()
end

function ClanChatMessage_system:readNodes()
    self.font_word = self:findChild("font_word")
end

function ClanChatMessage_system:setData( data )
    if not data then
        return
    end
    self.data = data
end

function ClanChatMessage_system:getMessageId()
    return self.data.msgId
end

function ClanChatMessage_system:updateUI()
    if self.data.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT then
        self.data.content = "Wow!You hit a jackpot.Your team members can also get a reward!"
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.CARD_CLAN then
        if self.data.content and string.find(self.data.content, "CardClanName") then
            local info = cjson.decode(self.data.content)
            local name = info.CardClanName or "chips"
            self.data.content = string.format("Wow!You completed a set of %s! Your team members can also get a reward!", name)
        end
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.CASHBONUS_JACKPOT then
        self.data.content = "Wow!You hit a jackpot in the Cash Wheel.Your team members can also get a reward!"
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.PURCHASE then
        self.data.content = "Thank you for the purchase. Other team members can also get a reward!"
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.LOTTERY then
        self.data.content = "Congratulations on winning the lottery.Your team members can also get a reward!"
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.AVATAR_FRAME then
        self.data.content = "Wow! You got a new frame.Your team members can also get a reward!"
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.RED_PACKAGE_COLLECT then
        self.data.content = string.format("\"%s\" said thanks for your gift!", self.data.nickname)
    end

    util_AutoLine(self.font_word, self.data.content, item_width_max, true)
    self.font_word:enableOutline(self.font_word:getTextColor(), 1)
end

function ClanChatMessage_system:getContentSize()
    local bg_size = self.font_word:getContentSize()
    return {width = bg_size.width * self.font_word:getScaleX(), height = bg_size.height * self.font_word:getScaleY() + item_offset2Edge}
end


return ClanChatMessage_system
