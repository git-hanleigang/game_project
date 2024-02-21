
-- 公会聊天 轮盘控件

local BaseView = util_require("base.BaseView")
-- 轮盘奖励
local ClanChatMessage_wheelItem = class("ClanChatMessage_wheel", BaseView)
local ChatManager = util_require("manager.System.ChatManager"):getInstance()

function ClanChatMessage_wheelItem:initUI( coins )
    self:createCsbNode("Club/csd/Chat_New/ClubChat_wheel_items.csb")
    self.font_num = self:findChild("font_num")
    if coins <= 0 then
        self.font_num:setString("?")
    else
        self.font_num:setString(util_formatCoins(coins, 3))
    end

    self.sp_coin = self:findChild("sp_jinbi")
end

function ClanChatMessage_wheelItem:getContentSize()
    local coin_size = self.sp_coin:getContentSize()
    local scaleX = self.sp_coin:getScaleX()
    local scaleY = self.sp_coin:getScaleY()
    return {width = coin_size.width * scaleX, height = coin_size.height * scaleY}
end





local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")
-- 轮盘
local ClanChatMessage_wheel = class("ClanChatMessage_wheel", BaseView)

-- 倍率随机表
local coins_bet = {0.1, 0.5, 0.6, 0.7, 0.8, 0.9, 1.1, 1.2, 1.3, 1.4, 1.5, 2, 5}

function ClanChatMessage_wheel:initUI( data )
    self:createCsbNode("Club/csd/Chat_New/ClubChat_wheel.csb")
    self:readNodes()

    local coins  = 0
    if data and data.coins then
        coins = tonumber(data.coins)
    end
    local panel_height = self.wheel_panel:getContentSize().height
    local item = self:createItem(coins)
    self.wheel_itemNode:addChild(item)
    item:setPosition(cc.p(0, panel_height/2))
end

function ClanChatMessage_wheel:readNodes()
    self.wheel_panel = self:findChild("wheel_panel")
    self.wheel_itemNode = self:findChild("wheel_itemNode")
    self.sp_wheel = self:findChild("sp_zhuanpan") 
end

function ClanChatMessage_wheel:setData( data )
    self.data = data
    self:createItems()
end

function ClanChatMessage_wheel:createItem( coins )
    local item = ClanChatMessage_wheelItem:create()
    if item.initData_ then
        item:initData_(coins)
    end
    return item
end

function ClanChatMessage_wheel:createItems()
    self.wheel_itemNode:removeAllChildren() 

    local panel_height = self.wheel_panel:getContentSize().height
    local item = self:createItem(tonumber(self.data.coins))
    self.wheel_itemNode:addChild(item)
    item:setPosition(cc.p(0, panel_height/2))
    if tonumber(self.data.coins) > 0 then
        local new_bets = clone(coins_bet)
        randomShuffle(new_bets)
        -- 只取前五个
        for i=1,5 do
            local bet = new_bets[i]
            local coins = tonumber(self.data.coins) * bet

            local item = self:createItem(coins)
            self.wheel_itemNode:addChild(item)
            
            item:setPosition(cc.p(0, panel_height*i+panel_height/2))
        end
        self.wheel_itemNode:setPositionY(-panel_height*6)
    end
end

function ClanChatMessage_wheel:play(bFast)
    local play_time = 0.5
    local posX = self.wheel_itemNode:getPositionX()
    self.wheel_itemNode:runAction(cc.MoveTo:create(play_time, cc.p(posX,0)))
    util_performWithDelay(self, function()
        self:onPlayOver(bFast)
    end, play_time)
end

-- 转完轮盘 显示结果 飞金币
function ClanChatMessage_wheel:onPlayOver(bFast)
    if not bFast then
        -- 一键领取不飞金币
        self:flyCoins()
    end
    gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.CHAT_REWARD_WHEEL_PLAYOVER)
end

function ClanChatMessage_wheel:flyCoins()
    local curChatShowTag = ChatManager:getCurChatTag()
    if self.data and self.data.m_listType ~= curChatShowTag then
        -- 不再当前页签不飞金币
        return
    end

    if self.sp_wheel and self.data and self.data.coins > 0 then 
        local senderSize = self.sp_wheel:getContentSize()
        local startPos = self.sp_wheel:convertToWorldSpace(cc.p(senderSize.width / 2,senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(startPos,endPos,baseCoins,self.data.coins)
    end
end

function ClanChatMessage_wheel:getContentSize()
    local wheel_size = self.sp_wheel:getContentSize()
    wheel_size.width = wheel_size.width * self.sp_wheel:getScaleX()
    wheel_size.height = wheel_size.height * self.sp_wheel:getScaleY()
    return wheel_size
end

return ClanChatMessage_wheel