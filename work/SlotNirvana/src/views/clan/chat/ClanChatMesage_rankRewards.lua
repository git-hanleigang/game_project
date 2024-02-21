--[[
Author: cxc
Date: 2022-02-25 15:33:22
LastEditTime: 2022-02-25 15:33:23
LastEditors: cxc
Description: 公会排行榜 结算奖励
FilePath: /SlotNirvana/src/views/clan/chat/ClanChatMesage_rankRewards.lua
--]]
local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ShopItem = util_require("data.baseDatas.ShopItem")

local ClanChatMesage_rankRewards = class("ClanChatMesage_rankRewards", BaseView)

function ClanChatMesage_rankRewards:initDatas(_data)
    ClanChatMesage_rankRewards.super.initDatas(self)

    self.m_data = _data
    self.m_bgHeight = 0
end

function ClanChatMesage_rankRewards:initCsbNodes()
    self.m_lbRank = self:findChild("lb_rank")
    self.m_lbCoins = self:findChild("lb_shuzi")
    self.m_nodeTime = self:findChild("sp_timer")
    self.m_lbTime = self:findChild("font_timer")
    self.m_spCollectedSign = self:findChild("sp_duihao")
    self.m_spBg = self:findChild("sp_tiaofu")
    self.m_bgHeight = self.m_spBg:getContentSize().height
    self.m_btnCollect = self:findChild("btn_collect")
end

function ClanChatMesage_rankRewards:initUI(...)
    ClanChatMesage_rankRewards.super.initUI(self)

    -- 时间
    self:initLeftTimeUI()

    -- 排名lb
    self:initRankLbUI()

    self:initRankRewardUI()

    self:updateUI()
end

function ClanChatMesage_rankRewards:onEnter()
    ClanChatMesage_rankRewards.super.onEnter(self)
   
    -- 注册 领取事件
    if self.m_data.status == 0 and self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self, data)
            if data.result.msgId == self.m_data.msgId then
                self.m_data.coins = tonumber(data.coins) or 0
                -- self.m_rewardItemList = data.items
                self.m_highLimitPoints = tonumber(data.points) or 0
                self:onRewardCollected(true)
            end
        end, ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI)
    end
end

function ClanChatMesage_rankRewards:getCsbName()
    return "Club/csd/Chat_New/Club_wall_chatbubble_team_rank.csb"
end

-- 排名lb
function ClanChatMesage_rankRewards:initRankLbUI()
    local rank = 0
    self.m_itemList = {}
    if self.m_data.content and #self.m_data.content > 0 then
        local info = cjson.decode(self.m_data.content)
        rank = tonumber(info.rank) or 0
        -- local items = info.items or {}
        -- for i=1, #items do
        --     local itemData = items[i]
        --     local rewardItem = ShopItem:create()
        --     rewardItem:parseData(itemData)
        --     table.insert(self.m_itemList, rewardItem)
        -- end
        local highLimitPointsList = info.memberPoints or {}
        local selfPoints = highLimitPointsList[globalData.userRunData.userUdid] or 0
        if tonumber(selfPoints) > 0 then
            local itemData = gLobalItemManager:createLocalItemData("DeluxeClub", tonumber(selfPoints))
            table.insert(self.m_itemList, itemData)
        end
    end
    self.m_lbRank:setString(rank)
end

function ClanChatMesage_rankRewards:updateRankRewardUIVisible()
    local bShowCoins = self.m_data.status == 1
    local nodeTitle = self:findChild("sp_title")
    local nodeCoins = self:findChild("sp_di")
    
    nodeTitle:setPositionY(bShowCoins and self.m_bgHeight * 0.68 or self.m_bgHeight * 0.5)
    nodeCoins:setVisible(bShowCoins)
end

-- 奖励
function ClanChatMesage_rankRewards:initRankRewardUI()
    -- 金币
    local coins = tonumber(self.m_data.coins) or 0
    self.m_lbCoins:setString(util_formatCoins(coins, 6))
    
    -- 道具
    local nodeItem = self:findChild("node_item")
    local itemList = self.m_itemList or {}
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP, 0.7, width, true)
	nodeItem:addChild(itemNode)

    -- 居中排列
    local alignUIList = {
        {node = self:findChild("sp_coins")},
        {node = self.m_lbCoins, alignX = 5, alignY = 2},
    }
    if #itemList > 0 then
        table.insert(alignUIList, {node = self:findChild("sp_add"), alignX = 5})
        table.insert(alignUIList, {node = nodeItem, alignX = 5, size = cc.size(#itemList * width, width), alignY = width*0.1})
    else
        self:findChild("sp_add"):setVisible(false)
    end
    util_alignCenter(alignUIList)
end

function ClanChatMesage_rankRewards:updateUI()
    -- 按钮触摸显隐
    self:updateBtnUI()

    -- 奖励
    self:updateRankRewardUIVisible()
end

-- 按钮触摸显隐
function ClanChatMesage_rankRewards:updateBtnUI()
    local bVisible = self.m_data.status == 0
    self.m_btnCollect:setVisible(bVisible)
    self.m_spCollectedSign:setVisible(not bVisible)
    if not bVisible then
        return
    end

    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        self:setButtonLabelDisEnabled("btn_collect",  self.m_data.status == 0 )
    end
    local left_time =  util_getLeftTime(self.m_data.effecTime)
    self:setButtonLabelDisEnabled("btn_collect", left_time > 0 )
end

-- 时间
function ClanChatMesage_rankRewards:initLeftTimeUI()
    local bVisible = self.m_data.status == 0
    self.m_nodeTime:setVisible(bVisible)
    if not bVisible then
        self.m_bUpdateUISec = false
        return
    end

    self.m_bUpdateUISec = true
    self:updateLeftTimeUI()
end
function ClanChatMesage_rankRewards:updateLeftTimeUI()
    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        local timeStr, bOver = util_daysdemaining(self.m_data.effecTime * 0.001)
        if bOver or  self.m_data.status == 1 then
            self.m_bUpdateUISec = false
            self.m_nodeTime:setVisible(self.m_data.status == 0)
            self:updateBtnUI()
            gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.SWITCH_FAST_COLLECT_VIEW_STATE)
        end
        self.m_lbTime:setString(timeStr)
        return
    end

    self.m_bUpdateUISec = false
end

-- 子类从写 定时器一秒调用一次
function ClanChatMesage_rankRewards:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTimeUI()
end

function ClanChatMesage_rankRewards:onRewardCollected(bFast)
    self.m_data.status = 1
    self:initRankRewardUI()
    self:updateLeftTimeUI()
    self:updateUI()

    self:flyCoins(bFast)
end

function ClanChatMesage_rankRewards:flyCoins(bFast)
    local curChatShowTag = ChatManager:getCurChatTag()
    if bFast or (self.m_data and self.m_data.m_listType ~= curChatShowTag) then
        -- 不再当前页签不飞金币
        return
    end

    -- if self.m_rewardItemList and #self.m_rewardItemList > 0 then
    if self.m_highLimitPoints and self.m_highLimitPoints > 0 then
        local itemList = {}
        if self.m_data and self.m_data.coins > 0 then
            local coinItemData = gLobalItemManager:createLocalItemData("Coins", self.m_data.coins)
            table.insert(itemList, coinItemData)
        end

        local itemData = gLobalItemManager:createLocalItemData("DeluxeClub", self.m_highLimitPoints)
        table.insert(itemList, itemData)

        -- for i = 1, #self.m_rewardItemList do
        --     local itemData = self.m_rewardItemList[i]
        --     local rewardItem = ShopItem:create()
        --     rewardItem:parseData(itemData)
        --     table.insert(itemList, rewardItem)
        -- end
        local view = gLobalItemManager:createRewardLayer(itemList, function()
            if not CardSysManager:needDropCards("Clan Rank") then
                return
            end
        
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Clan Rank")
        end, self.m_data.coins, true)
        if view then 
            gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
            return
        end
    end

    if self.m_lbCoins and self.m_data and self.m_data.coins > 0 then 
        local senderSize = self.m_lbCoins:getContentSize()
        local startPos = self.m_lbCoins:convertToWorldSpace(cc.p(senderSize.width / 2,senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(startPos,endPos,baseCoins,self.m_data.coins)
    end
end

function ClanChatMesage_rankRewards:clickFunc( sender )
    local senderName = sender:getName()
    if senderName == "btn_collect" then
        if self.m_data.status == 1 then
            self.m_btnCollect:setVisible(false)
            self:setButtonLabelDisEnabled("btn_collect", false)
            self.m_spCollectedSign:setVisible(true)
            return
        end
        if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
            ClanManager:requestChatReward( self.m_data.msgId, self.m_data.extra.randomSign )
            gLobalNoticManager:addObserver(self,function(self,data)
                if data.result.msgId == self.m_data.msgId then
                    self.m_data.coins = tonumber(data.coins) or 0
                    -- self.m_rewardItemList = data.items
                    self.m_highLimitPoints = tonumber(data.points) or 0
                    self:onRewardCollected()
                end
                
                gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
            end,ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    end
end

function ClanChatMesage_rankRewards:getContentSize()
    local bg_size = self.m_spBg:getContentSize()
    local scaleX = self.m_spBg:getScaleX()
    local scaleY = self.m_spBg:getScaleY()
    return {width = bg_size.width * scaleX, height = bg_size.height * scaleY}
end

function ClanChatMesage_rankRewards:setData( data )
    if not data then
        return
    end
    self.m_data = data
end


function ClanChatMesage_rankRewards:getMessageId()
    return self.m_data.msgId
end

return ClanChatMesage_rankRewards