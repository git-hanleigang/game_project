
-- 公会聊天 领取jackpot奖励控件

local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")
local ClanChatMessageBase = util_require("views.clan.chat.ClanChatMessageBase")
local ClanChatMessage_reward = class("ClanChatMessage_reward", ClanChatMessageBase)

local item_width_min = 520 -- 最小显示长度
local item_width_max = 660  -- 最大显示长度

function ClanChatMessage_reward:initUI( data )
    ClanChatMessageBase.initUI(self, data)
end

function ClanChatMessage_reward:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_jackpotwheel.csb"
end

function ClanChatMessage_reward:readNodes()
    ClanChatMessageBase.readNodes(self)
    -- 读取和操作特殊的节点
    self.node_wheel = self:findChild("node_wheel")  -- 轮盘节点
    self.btn_send = self:findChild("btn_send")      -- 领奖按钮
    self.sp_duihao = self:findChild("sp_duihao")    -- 已经领取的状态
    self.time_bg = self:findChild("time_bg")    -- 消失倒计时
    self.left_time = self:findChild("left_time")    -- 消失倒计时
    
    self.node_wheel_posy = self.node_wheel:getPositionY()
    self.btn_send_posy = self.btn_send:getPositionY()
    self.sp_duihao_posy = self.sp_duihao:getPositionY()
    self.time_bg_posy = self.time_bg:getPositionY()
    self:initWheel()
end

-- 创建轮盘
function ClanChatMessage_reward:initWheel()
    local wheel = util_createFindView("views/clan/chat/ClanChatMessage_wheel", self.data)
    assert(wheel, "工会聊天的轮盘创建失败了")
    self.node_wheel:addChild(wheel)
    self.wheel = wheel
end

function ClanChatMessage_reward:updateContent()
    self:updateRewardLbUI()

    self.node_wheel:setPositionY(self.node_wheel_posy + self.item_offset2Edge)
    self.btn_send:getParent():setPositionY(self.btn_send_posy + self.item_offset2Edge)
    self.sp_duihao:setPositionY(self.sp_duihao_posy + self.item_offset2Edge)
    self.time_bg:setPositionY(self.time_bg_posy + self.item_offset2Edge)

    self.btn_send:setVisible(self.data.status == 0)
    self.sp_duihao:setVisible(self.data.status == 1)
end

function ClanChatMessage_reward:updateRewardLbUI()
    local content = ""
    if self.data.messageType == ChatConfig.MESSAGE_TYPE.JACKPOT then
        local name = "game"
        if self.data.content and #self.data.content > 0 then
            local info = cjson.decode(self.data.content)
            name = info.game or "game"
        end
        content = "Won a jackpot in " .. name
    elseif self.data.messageType == ChatConfig.MESSAGE_TYPE.CASHBONUS_JACKPOT then
        content = "Won a jackpot in CASH WHEEL"
    else
        content = "This is an unknown type"
    end

    util_AutoLine(self.font_word, content, item_width_max, true)
end

function ClanChatMessage_reward:clickFunc( sender )
    local senderName = sender:getName()
    if senderName == "btn_send" then
        if self.data.status == 1 then
            -- self.btn_send:setTouchEnabled(false)
            -- self.btn_send:setBright(false)
            self:setButtonLabelDisEnabled("btn_send", false)
            self.sp_duihao:setVisible(true)
            return
        end
        if self.data.msgId and self.data.extra and self.data.extra.randomSign then
            ClanManager:requestChatReward( self.data.msgId, self.data.extra.randomSign )
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    elseif senderName == "layout_touch" then
       if self.data.sender == globalData.userRunData.userUdid then
           G_GetMgr(G_REF.UserInfo):showMainLayer()
       else
           G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.data.sender, "","",self.data.frameId)
       end
    end
end

function ClanChatMessage_reward:onRewardReceived(data, bFast)
    gLobalNoticManager:addObserver(self,function(self,data)
        self:onRewardCollected()
        gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.CHAT_REWARD_WHEEL_PLAYOVER)
    end,ChatConfig.EVENT_NAME.CHAT_REWARD_WHEEL_PLAYOVER)

    self.data.coins = tonumber(data.coins)
    self.wheel:setData(self.data)
    self.wheel:play(bFast)

    -- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
    -- if self.data.coins > 0 and not bFast then
    --     ChatManager:sendCollect( self.data.msgId, self.data.coins )
    -- end
end

function ClanChatMessage_reward:onRewardCollected()
    self.data.status = 1
    self.btn_send:setVisible(false)
    -- self.btn_send:setTouchEnabled(false)
    -- self.btn_send:setBright(false)
    self:setButtonLabelDisEnabled("btn_send", false)


    self.sp_duihao:setVisible(true)
end

function ClanChatMessage_reward:onEnter()
    if self.data.status == 0 then
        self.m_bUpdateUISec = true
        self:updateLeftTime()

        if self.btn_send:isVisible() and self.btn_send:isTouchEnabled() then
            -- 可领取的 状态发生变化时 通知更新一键领取状态
            self.m_bCanNotifyEvt = true
        end
    else
        self.time_bg:setVisible(false)
        self.left_time:setString("")
    end

    -- 注册 领取事件
    if self.data.status == 0 and self.data.msgId and self.data.extra and self.data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self,data)
            if data.result.msgId == self.data.msgId then
                self:onRewardReceived(data)
            end
        end,ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
    end
    -- 注册 领取事件
    if self.data.status == 0 and self.data.msgId and self.data.extra and self.data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self,data)
            if data.result.msgId == self.data.msgId then
                self:onRewardReceived(data, true)
            end
        end,ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI)
    end
end

function ClanChatMessage_reward:updateLeftTime() 
    if self.data.effecTime and self.data.effecTime > 0 then
        local left_time = self.data.effecTime/1000 - globalData.userRunData.p_serverTime/1000
        if left_time < 0 then
            left_time = 0
        end

        local time_str = ""
        if self.data.status == 0 then
            time_str = util_count_down_str(left_time)
        end
        
        local bl_stop = left_time <= 0 or self.data.status == 1
        if bl_stop then
            self:notifyFastCollectViewSwitchState()
            self.m_bUpdateUISec = false
        end
        if time_str == "" then
            self.time_bg:setVisible(false)
        end
        self.left_time:setString(time_str)

        if left_time <= 0 then
            -- self.btn_send:setTouchEnabled(false)
            -- self.btn_send:setBright(false)
            self:setButtonLabelDisEnabled("btn_send", false)
        end
    end
end

function ClanChatMessage_reward:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 跟父类的区别就是去掉了底边空白区域
function ClanChatMessage_reward:getBubbleSize()
    local content_size = self:getInnerSize()
    -- 计算文本显示区域
    content_size.width = content_size.width + self.item_offset2Edge * 2
    -- content_size.height = content_size.height + (self.bubbleBgSize.height - self.font_word_posy)

    local name_width = self.font_name:getContentSize().width * self.font_name:getScaleX()
    local time_width = self.font_time:getContentSize().width * self.font_time:getScaleX()
    local info_width = name_width + time_width + self.info_offset + self.item_offset2Edge * 2
    if content_size.width < info_width then
        content_size.width = info_width
    end
    return content_size
end

function ClanChatMessage_reward:getInnerSize()
    local bg_size = {}
    local word_size = self.font_word:getContentSize()
    local word_height = word_size.height * self.font_word:getScaleY()
    local word_toTopEdge = self.bubbleBgSize.height - self.font_word_posy
    local wheel_height = self.wheel:getContentSize().height

    bg_size.width = word_size.width * self.font_word:getScaleX()
    bg_size.height = word_height + wheel_height + word_toTopEdge

    if bg_size.width < item_width_min then
        bg_size.width = item_width_min
    elseif bg_size.width > item_width_max then
        bg_size.width = item_width_max
    end
    return bg_size
end

-- 更新一键领取view 状态
function ClanChatMessage_reward:notifyFastCollectViewSwitchState()
    if not self.m_bCanNotifyEvt then
        return
    end

    self.m_bCanNotifyEvt = false
    gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.SWITCH_FAST_COLLECT_VIEW_STATE)
end

-- 子类从写 定时器一秒调用一次
function ClanChatMessage_reward:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTime()
end

return ClanChatMessage_reward
