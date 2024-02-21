--[[
Author: cxc
Date: 2021-11-10 15:25:52
LastEditTime: 2021-11-10 15:28:13
LastEditors: your name
Description: 公会一键领取 view
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatCollectAllView.lua
--]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ChatConfig = util_require("data.clanData.ChatConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")
local ClanChatCollectAllView = class("ClanChatCollectAllView", BaseView)

function ClanChatCollectAllView:initUI()
    local csbName = "Club/csd/Chat_New/ClubWall_collectall.csb"
    self:createCsbNode(csbName)

    self.m_bHideActing = false
    self.m_propsBagList = {}
    self:setVisible(false)

    self:initView()
    self:updateUI()
    
    gLobalNoticManager:addObserver(self, "collectSuccessEvt", ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA_ALL) --一键领取成功
    gLobalNoticManager:addObserver(self, "switchStateEvt", ChatConfig.EVENT_NAME.SWITCH_FAST_COLLECT_VIEW_STATE) --更新一键领取view 状态
end

function ClanChatCollectAllView:initView()
    self.m_node_collect = self:findChild("node_collect")
    self.m_btn_collectall = self:findChild("btn_collectall")
    self.m_lb_collectall = self:findChild("lb_collectall")

    self.m_node_rewards = self:findChild("node_rewards")
    self.m_lb_rewards = self:findChild("lb_rewards")
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin_number = self:findChild("lb_coin_number")
end


function ClanChatCollectAllView:updateUI(_bSingleMessage)
    local msgIdList, randomSignList = ChatManager:getFastCollectGiftMsgIdAndSign()

    self.m_node_collect:setVisible(#msgIdList > 0 or _bSingleMessage)
    self.m_node_rewards:setVisible(#msgIdList <= 0 and not _bSingleMessage)

    self:setLbCollectAllStr(#msgIdList)
end

function ClanChatCollectAllView:setLbCollectAllStr(_num)
    if not _num or _num <= 0 then
        return
    end

    if _num > 1 then
        self.m_lb_collectall:setString(string.format("YOU HAVE %d UNCLAIMED REWARDS", _num))
    else
        self.m_lb_collectall:setString(string.format("YOU HAVE %d UNCLAIMED REWARD", _num))
    end
end

-- 显示
function ClanChatCollectAllView:playShowAct()
    self:setVisible(true)
    self.m_bHideActing = false
    if self.m_csbAct:isPlaying() then
        self.m_csbAct:pause()
        self:runCsbAction("idle", true)
        return
    end 

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
	end, 60)
end

-- 领奖完切换状态
function ClanChatCollectAllView:playSwitchAct()
    self:setVisible(true)
    self.m_bHideActing = true
    self:runCsbAction("actionframe", false, function()
        self.m_bHideActing = false
        self:updateUI()
        if self.m_node_rewards:isVisible() then
            performWithDelay(self, handler(self, self.playHideAct), 3)
            return
        end
        self:runCsbAction("idle", true)
        gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.CHECK_FAST_COLLECT_VIEW_VISIBLE)
	end, 60)
end

-- 隐藏
function ClanChatCollectAllView:playHideAct()
    if self.m_bHideActing then
        return
    end

    self.m_bHideActing = true
    self:runCsbAction("over", false, function()
        if not self.m_bHideActing then
            return
        end

        self.m_bHideActing = false
		self:setVisible(false)
	end, 60)
end

-- 获取 是否acting
function ClanChatCollectAllView:isActing()
    return self.m_bHideActing
end

function ClanChatCollectAllView:clickFunc( sender )
    if self.m_bHideActing then
        return
    end

    local senderName = sender:getName()
    if senderName == "btn_collectall" then
        local msgIdList, randomSignList = ChatManager:getFastCollectGiftMsgIdAndSign()
        ClanManager:requestCollectAllGiftReward(msgIdList, randomSignList)
    end
end

-- 一键领取成功evt
function ClanChatCollectAllView:collectSuccessEvt(_dataList)
    if not _dataList then
        return
    end

    local coins = 0
    local msgIdList = {}
    local coinsList = {}
    local coinsZeroLogList = {}
    self.m_rewardItemList = {}
    for _,data in ipairs(_dataList) do
        local msgCoins = tonumber(data.coins) or 0
        if msgCoins>0 and data.result and data.result ~= "" then
            coins = coins + msgCoins
            data.result = cjson.decode(data.result)
            if data.result.msgId and tonumber(data.coins) > 0 then
                table.insert(msgIdList, data.result.msgId)
                table.insert(coinsList, msgCoins)
                gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI, data)
            elseif data.result.msgId then
                table.insert(coinsZeroLogList, string.format("msg:%s coins is 0", data.result.msgId))
            end

            if data.result.msgId and data.items then
                table.insert(self.m_rewardItemList, data.items)
            end
        end
    end
    if #coinsZeroLogList > 0 then
        util_sendToSplunkMsg("TeamChatCollectReward", cjson.encode(coinsZeroLogList))
    end
    
    -- scoket 发送领取奖励消息 
    -- cxc 2021-11-19 15:31:36 废弃由服务器自己去同步
    -- ChatManager:sendFastCollectAll(msgIdList, coinsList)

    -- 飞金币
    if coins  > 0 then
        self:flyCoins(coins)
    end
    -- 调卡
    self:tryDropCards()
end

function ClanChatCollectAllView:flyCoins(_coins)
    local senderSize = self.m_btn_collectall:getContentSize()
    local startPos = self.m_btn_collectall:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount
    local view = gLobalViewManager:getFlyCoinsView()
    view:pubShowSelfCoins(true)
    view:pubPlayFlyCoin(startPos,endPos,baseCoins,_coins)

    self.m_lb_coin_number:setString(util_formatCoins(_coins, 4))
    util_alignCenter(
        {
            {node = self.m_lb_rewards, alignX = 15},
            {node = self.m_sp_coin, alignX = 15},
            {node = self.m_lb_coin_number, alignX = 15}
        }
    )
    self.m_node_rewards:setVisible(true)
    self:playSwitchAct()
end

function ClanChatCollectAllView:tryDropCards()
    -- 合成福袋
    self:initDropPropsBagLayer()
    local function dropClubMerge()
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        local cb = function()
            mergeManager:resetPropsBagTempList()
            globalDeluxeManager:dropExperienceCardItemEvt()
        end
        mergeManager:autoPopPropsBagLayer(cb)
    end

    -- 排行榜卡
    if CardSysManager:needDropCards("Clan Rank") then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Clan Rank")
    end

    -- rush卡
    if CardSysManager:needDropCards("Clan Rush") then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("Clan Rush")
    end

    -- duel卡
    if CardSysManager:needDropCards("Clan DUEL") then
        CardSysManager:doDropCards(
            "Clan DUEL",
            function()
                dropClubMerge()
            end
        )
    end
end

-- 尝试 掉落合成福袋
function ClanChatCollectAllView:initDropPropsBagLayer()
    if self.m_rewardItemList and #self.m_rewardItemList > 0 then
        -- 合成福包弹板
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        for i = 1, #self.m_rewardItemList do
            local list = self.m_rewardItemList[i]
            for i,v in ipairs(list) do
                local rewardItem = ShopItem:create()
                rewardItem:parseData(v)
                if string.find(rewardItem.p_icon, "Pouch") then
                    table.insert(self.m_propsBagList, rewardItem)
                end
            end
        end
        mergeManager:setPopPropsBagTempList(self.m_propsBagList)
    end
end

-- 更新一键领取view 状态
function ClanChatCollectAllView:switchStateEvt()
    local msgIdList, randomSignList = ChatManager:getFastCollectGiftMsgIdAndSign()
    self:updateUI(true)
    if #msgIdList > 0 then
        return
    end

    if not self.m_bHideActing and self:isVisible() then
        self:playHideAct()
    end
end

return ClanChatCollectAllView