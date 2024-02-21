
-- 聊天领奖 充值奖励

local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

local BaseView = util_require("base.BaseView")
local ClanChatMessage_purchase = class("ClanChatMessage_purchase", BaseView)

local item_width_max = 474  -- 文本最大宽度

function ClanChatMessage_purchase:initUI(data)
    self:setData(data)

    local csbName = self:getCsbPath()
    if csbName then
        self:createCsbNode(csbName)
        self:readNodes()
        self:updateUI()
    end
end

function ClanChatMessage_purchase:getCsbPath()
    return "Club/csd/Chat_New/Club_wall_chatbubble_purchaseRewards.csb"
end

function ClanChatMessage_purchase:readNodes()
    -- 读取和操作特殊的节点
    self.sp_tiaofu = self:findChild("sp_tiaofu")            -- 底板
    self.font_word = self:findChild("font_word")
    self.font_name = self:findChild("font_name")            -- name
    self.font_word_desc = self:findChild("font_word_desc")  -- 描述文本

    self.sp_coindiban = self:findChild("sp_coindiban")      -- 奖励底板
    self.font_coinword = self:findChild("font_coinword")    -- 奖励文本
    
    self.btn_collect = self:findChild("btn_collect")        -- 领奖按钮
    self.sp_timer = self:findChild("sp_timer")              -- 消息倒计时底板
    self.font_timer = self:findChild("font_timer")          -- 消息倒计时
    self.sp_duihao = self:findChild("sp_duihao")            -- 已经领取的状态
end

function ClanChatMessage_purchase:setData( data )
    if not data then
        return
    end
    self.data = data
end

function ClanChatMessage_purchase:getMessageId()
    return self.data.msgId
end

function ClanChatMessage_purchase:updateUI()
    self:updateBtnState()
    
    -- local name = self.data.nickname
    -- if string.len(name) <= 0 then
    --     name = "someone"
    -- end
    -- self.font_name:setString(name)
    -- local content = "for the purchase. Other team members can also get a reward!"
    -- util_AutoLine(self.font_word_desc, content, item_width_max, true)

    self.font_word:setVisible(false)
    self.font_name:setVisible(false)
    local content = "A TEAM MEMBER'S PURCHASE\nEARNS SPECIAL REWARDS\nFOR THE REST, THANKS."
    self.font_word_desc:setString(content)
    self.font_word_desc:setPositionY(63)

    self.sp_coindiban:setVisible(self.data.status == 1)
    self.font_coinword:setString(util_formatCoins(self.data.coins, 3))
    self.sp_duihao:setVisible(self.data.status == 1)
    self.sp_timer:setVisible(self.data.status == 0)
end

function ClanChatMessage_purchase:updateBtnState()
    self.btn_collect:setVisible(self.data.status == 0)
    -- self.btn_collect:setTouchEnabled(self.data.status == 0)
    -- self.btn_collect:setBright(self.data.status == 0 )
    self:setButtonLabelDisEnabled("btn_collect", self.data.status == 0 )
    if self.data.effecTime and self.data.effecTime > 0 then
        -- local left_time = self.data.effecTime/1000 - os.time()
        local left_time =  util_getLeftTime(self.data.effecTime)
        if left_time <= 0 then
            -- self.btn_collect:setTouchEnabled(false)
            -- self.btn_collect:setBright(false)
            self:setButtonLabelDisEnabled("btn_collect", false )
        end
    end
end


function ClanChatMessage_purchase:onEnter()
    if self.data.status == 0 then
        self.m_bUpdateUISec = true
        self:updateLeftTime()

        if self.btn_collect:isVisible() and self.btn_collect:isTouchEnabled() then
            -- 可领取的 状态发生变化时 通知更新一键领取状态
            self.m_bCanNotifyEvt = true
        end
    else
        self.sp_timer:setVisible(false)
        self.font_timer:setString("")
    end

    -- 注册 领取事件
    if self.data.status == 0 and self.data.msgId and self.data.extra and self.data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self,data)
            if data.result.msgId == self.data.msgId then
                self.data.coins = tonumber(data.coins)
                self:onRewardCollected(true)
            end
        end,ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI)
    end
end

function ClanChatMessage_purchase:updateLeftTime()
    if self.data.effecTime and self.data.effecTime > 0 then
        -- local left_time = self.data.effecTime/1000 - os.time()
        local left_time = util_getLeftTime(self.data.effecTime)
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
            self.sp_timer:setVisible(false)
        end
        self.font_timer:setString(time_str)

        self:updateBtnState()
    end
end

function ClanChatMessage_purchase:flyCoins(bFast)
    local curChatShowTag = ChatManager:getCurChatTag()
    if bFast or (self.data and self.data.m_listType ~= curChatShowTag) then
        -- 不再当前页签不飞金币
        return
    end

    if self.font_coinword and self.data and self.data.coins > 0 then 
        local senderSize = self.font_coinword:getContentSize()
        local startPos = self.font_coinword:convertToWorldSpace(cc.p(senderSize.width / 2,senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(startPos,endPos,baseCoins,self.data.coins)
    end
end

function ClanChatMessage_purchase:onRewardCollected(bFast)
    self.data.status = 1
    self:updateUI()

    self:flyCoins(bFast)
    
    -- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
    -- if not bFast and not self.data.msgId and self.data.coins > 0 then
    --     ChatManager:sendCollect( self.data.msgId, self.data.coins )
    -- end
end

function ClanChatMessage_purchase:clickFunc( sender )
    local senderName = sender:getName()
    if senderName == "btn_collect" then
        if self.data.status == 1 then
            self.btn_collect:setVisible(false)
            -- self.btn_collect:setTouchEnabled(false)
            -- self.btn_collect:setBright(false)
            self:setButtonLabelDisEnabled("btn_collect", false)
            self.sp_duihao:setVisible(true)
            return
        end
        if self.data.msgId and self.data.extra and self.data.extra.randomSign then
            ClanManager:requestChatReward( self.data.msgId, self.data.extra.randomSign )
            gLobalNoticManager:addObserver(self,function(self,data)
                if data.result.msgId == self.data.msgId then
                    self.data.coins = tonumber(data.coins)
                    self:onRewardCollected()
                end
                gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
            end,ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    end
end

function ClanChatMessage_purchase:getContentSize()
    local bg_size = self.sp_tiaofu:getContentSize()
    local scaleX = self.sp_tiaofu:getScaleX()
    local scaleY = self.sp_tiaofu:getScaleY()
    return {width = bg_size.width * scaleX, height = bg_size.height * scaleY}
end

-- 更新一键领取view 状态
function ClanChatMessage_purchase:notifyFastCollectViewSwitchState()
    if not self.m_bCanNotifyEvt then
        return
    end

    self.m_bCanNotifyEvt = false
    gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.SWITCH_FAST_COLLECT_VIEW_STATE)
end

-- 子类从写 定时器一秒调用一次
function ClanChatMessage_purchase:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTime()
end

return ClanChatMessage_purchase
