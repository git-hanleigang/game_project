--[[--
    send页签中入口cell
]]
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseGift_cell = class("InboxPage_send_chooseGift_cell", BaseView)
function InboxPage_send_chooseGift_cell:initUI(type, mainClass)
    self.m_type = type
    self.m_mainClass = mainClass
    self:createCsbNode("InBox/FBCard/InboxPage_Send_ChooseGift_cell.csb")

    self:updateView()
end

function InboxPage_send_chooseGift_cell:initCsbNodes()
    self.btn_coins = self:findChild("btn_coins")
    self.btn_chips = self:findChild("btn_chips")
    self.Node_pro = self:findChild("Node_pro")
    self.node_coins = self:findChild("lb_pro_coins")
    self.node_chips = self:findChild("lb_pro_chips")
    self.countCoins_lb = self:findChild("lb_countCoins")
    self.proCoins_lb = self:findChild("lb_curProCoins")
    self.countChips_lb = self:findChild("lb_countChips")
    self.proChops_lb = self:findChild("lb_curProChips")
    
    self.Node_time = self:findChild("Node_time")
    self.time_des_coins = self:findChild("lb_time_coins")
    self.time_des_chips = self:findChild("lb_time_chips")
    self.time_lb = self:findChild("lb_time")
    self.time_lb:setString("00:00:00")
end

function InboxPage_send_chooseGift_cell:updateView()
    self.node_coins:setVisible(self.m_type == "COIN")
    self.node_chips:setVisible(self.m_type == "CARD")
    self.time_des_coins:setVisible(self.m_type == "COIN")
    self.time_des_chips:setVisible(self.m_type == "CARD")
end

function InboxPage_send_chooseGift_cell:updateUI()
    self:setBtnShow()
    if self:isSatisfyLevel() then -- 判断是否满足等级要求
        if self:isBeyondLimitNum() then -- 判断是否超出赠送次数要求
            self:setBtnState(false)
            self:showTime()
        else
            self:setBtnState(true)
            self:showPro()
        end
    else
        self:setBtnState(false)
        self:showPro()
    end
    self:checkAddNoviceCardTipUI()
end

-- 集卡新手期期间 点击提示要先完成新手集卡
function InboxPage_send_chooseGift_cell:checkAddNoviceCardTipUI()
    local bCardNovice = CardSysManager:isNovice()
    if not bCardNovice then
        return
    end
    local tipUI = self:getChildByName("InboxSendPageCardNoviceTipUI")
    if not tipUI then
        tipUI = util_createView("views.inbox.InboxSendPageCardNoviceTipUI")
        self:addChild(tipUI)
    end
    self.m_cardNoviceTipUI = tipUI
end

function InboxPage_send_chooseGift_cell:isSatisfyLevel()
    local limitLv = G_GetMgr(G_REF.Inbox):getFriendRunData():getLimitLevel(self.m_type)
    if globalData.userRunData.levelNum >= limitLv then
        return true
    end
    return false
end

function InboxPage_send_chooseGift_cell:isBeyondLimitNum()
    local recList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordListBySendType(self.m_type)
    local limitNum = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendLimitBySendType(self.m_type)
    local cur, max = #recList, limitNum
    if cur >= max then
        return true
    end
    return false
end

function InboxPage_send_chooseGift_cell:setBtnShow()
    self.btn_coins:setVisible(self.m_type == "COIN")
    self.btn_chips:setVisible(self.m_type == "CARD")
end

function InboxPage_send_chooseGift_cell:setBtnState(state)
    if self.m_type == "COIN" then
        self.btn_coins:setTouchEnabled(state)
        self.btn_coins:setBright(state)
    elseif self.m_type == "CARD" then
        -- 集卡新手期期间 按钮压暗 点击提示要先完成新手集卡
        local bCardNovice = CardSysManager:isNovice()
        if bCardNovice then
            self.btn_chips:setBright(false)
            self.btn_chips:setTouchEnabled(true)
            return
        end

        -- 赛季间歇期不能送卡处理
        if state == true then
            if not CardSysManager:hasSeasonOpening() then
                self.btn_chips:setTouchEnabled(state)
                self.btn_chips:setBright(state)
                return
            end
        end

        self.btn_chips:setTouchEnabled(state)
        self.btn_chips:setBright(state)
    end
end

function InboxPage_send_chooseGift_cell:showPro()
    -- 显示进度
    self.Node_pro:setVisible(true)
    self.Node_time:setVisible(false)

    -- self.pro_img_coins:setVisible(self.m_type == "COIN")
    -- self.pro_img_chips:setVisible(self.m_type == "CARD")

    local recList = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendRecordListBySendType(self.m_type)
    local limitNum = G_GetMgr(G_REF.Inbox):getFriendRunData():getSendLimitBySendType(self.m_type)
    local cur, max = #recList, limitNum

    local color = cc.c3b(167, 8, 158)
    local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if data then
        local sendNum = data:getSendNumsByType(self.m_type)
        if sendNum > 0 then
            max = math.max(sendNum, max)
        end
    end
    if self.m_type == "COIN" then 
        self.countCoins_lb:setString(max)
        self.proCoins_lb:setString(string.format("(%d/%d)", cur, max))
        self.countCoins_lb:setColor(color)
        self.proCoins_lb:setColor(color)
    elseif self.m_type == "CARD" then
        self.countChips_lb:setString(max)
        self.proChops_lb:setString(string.format("(%d/%d)", cur, max))
        self.countChips_lb:setColor(color)
        self.proChops_lb:setColor(color)
    end

    -- util_alignCenter(
    --     {
    --         {node = self.pro_lb_left},
    --         {node = self.pro_lb},
    --         {node = self.pro_lb_right}
    --     }
    -- )
end

function InboxPage_send_chooseGift_cell:showTime()
    -- 显示倒计时
    self.Node_time:setVisible(true)
    self.Node_pro:setVisible(false)
    -- self.time_des_coins:setVisible(self.m_type == "COIN")
    -- self.time_des_chips:setVisible(self.m_type == "CARD")
    self:updateCountdown(self.m_type)
end

-- 处理倒计时
function InboxPage_send_chooseGift_cell:updateCountdown(sendType)
    if self.m_CountdownTimer ~= nil then
        self:stopAction(self.m_CountdownTimer)
        self.m_CountdownTimer = nil
    end

    local time = G_GetMgr(G_REF.Inbox):getFriendRunData():getExpireAtBySendType(sendType)
    if time == nil then
        local expireAts = G_GetMgr(G_REF.Inbox):getFriendRunData():getExpireAt()
        if expireAts == nil then
            release_print("ERROR! expireAts = nil")
        else
            release_print(
                "ERROR! InboxPage_send_chooseGift_cell, time == nil, sendType = " ..
                    tostring(sendType) .. ", expireAts.COIN = " .. tostring(expireAts.COIN) .. ", expireAts.CARD = " .. tostring(expireAts.CARD)
            )
        end
    end
    local leftTime = time - globalData.userRunData.p_serverTime
    leftTime = math.floor(leftTime / 1000)
    if leftTime > 0 then
        self.time_lb:setString(util_count_down_str(leftTime))
    end

    self.m_CountdownTimer =
        schedule(
        self,
        function()
            -- local leftTime = util_get_today_lefttime()
            local leftTime = time - globalData.userRunData.p_serverTime
            leftTime = math.floor(leftTime / 1000)
            if leftTime == 0 then
                self:stopAction(self.m_CountdownTimer)
                self.m_CountdownTimer = nil

                -- 客户端手动清除数据
                G_GetMgr(G_REF.Inbox):getFriendRunData():clearExpireAt()
                G_GetMgr(G_REF.Inbox):getFriendRunData():clearSendRecordList()
                -- 刷新界面
                self:updateUI()
            elseif leftTime < 0 then
                self:stopAction(self.m_CountdownTimer)
                self.m_CountdownTimer = nil

                -- 客户端手动清除数据
                G_GetMgr(G_REF.Inbox):getFriendRunData():clearExpireAt()
                -- 刷新界面
                self:updateUI()
            else
                self.time_lb:setString(util_count_down_str(leftTime))
            end
        end,
        1
    )
end

function InboxPage_send_chooseGift_cell:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_coins" then
        self.m_mainClass:chooseGift(self.m_type)
    elseif name == "btn_chips" then
        -- 集卡新手期期间 按钮压暗 点击提示要先完成新手集卡
        local bCardNovice = CardSysManager:isNovice()
        if not bCardNovice then
            self.m_mainClass:chooseGift(self.m_type)
            return
        end

        -- 提示要先完成新手集卡 气泡
        if self.m_cardNoviceTipUI then
            self.m_cardNoviceTipUI:switchVisible()
        end

    end
end

return InboxPage_send_chooseGift_cell
