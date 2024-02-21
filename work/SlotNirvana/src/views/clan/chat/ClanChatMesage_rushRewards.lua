--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-02 14:08:22
]]
local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = util_require("data.clanData.ChatConfig")
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ShopItem = util_require("data.baseDatas.ShopItem")

local ClanChatMesage_rushRewards = class("ClanChatMesage_rushRewards", BaseView)

function ClanChatMesage_rushRewards:initDatas(_data)
    ClanChatMesage_rushRewards.super.initDatas(self)

    self.m_data = _data
    self.m_bgHeight = 0
end

function ClanChatMesage_rushRewards:initCsbNodes()
    self.m_lbTaskDesc = self:findChild("lb_taskDesc")
    self.m_lbCoins = self:findChild("lb_shuzi")
    self.m_nodeTime = self:findChild("sp_timer")
    self.m_lbTime = self:findChild("font_timer")
    self.m_spCollectedSign = self:findChild("sp_duihao")
    self.m_spBg = self:findChild("sp_tiaofu")
    self.m_bgHeight = self.m_spBg:getContentSize().height
    self.m_btnCollect = self:findChild("btn_collect")
end

function ClanChatMesage_rushRewards:initUI(...)
    ClanChatMesage_rushRewards.super.initUI(self)

    -- 时间
    self:initLeftTimeUI()

    -- 任务desc lb
    self:initItemList()

    self:updateUI()
end

function ClanChatMesage_rushRewards:onEnter()
    ClanChatMesage_rushRewards.super.onEnter(self)
   
    -- 注册 领取事件
    if self.m_data.status == 0 and self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self, data)
            if data.result.msgId == self.m_data.msgId then
                self.m_data.coins = tonumber(data.coins) or 0
                self.m_rewardItemList = data.items
                self:onRewardCollected(true)
            end
        end, ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI)
    end
end

function ClanChatMesage_rushRewards:getCsbName()
    return "Club/csd/Chat_New/Club_wall_chatbubble_team_rush.csb"
end

-- 任务desc lb
function ClanChatMesage_rushRewards:initItemList()
    local taskIdx = 0
    self.m_itemList = {}
    if self.m_data.content and #self.m_data.content > 0 then
        local info = cjson.decode(self.m_data.content)
        taskIdx = tonumber(info.taskSeq) or 0
        local items = info.items or {}
        for i=1, #items do
            local itemData = items[i]
            local rewardItem = ShopItem:create()
            rewardItem:parseData(itemData)
            table.insert(self.m_itemList, rewardItem)
        end
        -- local highLimitPointsList = info.memberPoints or {}
        -- local selfPoints = highLimitPointsList[globalData.userRunData.userUdid] or 0
        -- if tonumber(selfPoints) > 0 then
        --     local itemData = gLobalItemManager:createLocalItemData("DeluxeClub", tonumber(selfPoints))
        --     table.insert(self.m_itemList, itemData)
        -- end
    end

    local str = "TEAM RUSH REWARDS"
    if taskIdx > 0 then
        str = string.format("TEAM RUSH %d REWARDS", taskIdx)
    end
    self.m_lbTaskDesc:setString(str)
end

function ClanChatMesage_rushRewards:updateRewardUIVisible()
    local bShowCoins = self.m_data.status == 1
    local nodeCoins = self:findChild("sp_di")
    
    self.m_lbTaskDesc:setPositionY(bShowCoins and self.m_bgHeight * 0.68 or self.m_bgHeight * 0.5)
    nodeCoins:setVisible(bShowCoins)
end

-- 奖励
function ClanChatMesage_rushRewards:updateRushRewardUI()
    -- 金币
    local coins = tonumber(self.m_data.coins) or 0
    self.m_lbCoins:setString(util_formatCoins(coins, 6))
    
    -- 道具
    local nodeItem = self:findChild("node_item")
    nodeItem:removeAllChildren()
    local itemList = self.m_itemList or {}
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP, 0.5, width, true)
	nodeItem:addChild(itemNode)

    -- 居中排列
    local alignUIList = {
        {node = self:findChild("sp_coins")},
        {node = self.m_lbCoins, alignX = 5},
    }
    if #itemList > 0 then
        table.insert(alignUIList, {node = self:findChild("sp_add"), alignX = 5})
        table.insert(alignUIList, {node = nodeItem, alignX = 5, size = cc.size(#itemList * width*0.5, width*0.5)})
    else
        self:findChild("sp_add"):setVisible(false)
    end
    util_alignCenter(alignUIList)
end

function ClanChatMesage_rushRewards:updateUI()
    -- 按钮触摸显隐
    self:updateBtnUI()

    self:updateRushRewardUI()

    -- 奖励
    self:updateRewardUIVisible()
end

-- 按钮触摸显隐
function ClanChatMesage_rushRewards:updateBtnUI()
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
function ClanChatMesage_rushRewards:initLeftTimeUI()
    local bVisible = self.m_data.status == 0
    self.m_nodeTime:setVisible(bVisible)
    if not bVisible then
        self.m_bUpdateUISec = false
        return
    end

    self.m_bUpdateUISec = true
    self:updateLeftTimeUI()
end
function ClanChatMesage_rushRewards:updateLeftTimeUI()
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
function ClanChatMesage_rushRewards:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTimeUI()
end

function ClanChatMesage_rushRewards:onRewardCollected(bFast)
    self.m_data.status = 1
    self:updateRushRewardUI()
    self:updateLeftTimeUI()
    self:updateUI()

    self:flyCoins(bFast)
end

function ClanChatMesage_rushRewards:flyCoins(bFast)
    ClanManager:sendClanInfo()
    local curChatShowTag = ChatManager:getCurChatTag()
    if bFast or (self.m_data and self.m_data.m_listType ~= curChatShowTag) then
        -- 不再当前页签不飞金币
        return
    end

    if self.m_rewardItemList and #self.m_rewardItemList > 0 then
        local itemList = {}
        if self.m_data and self.m_data.coins > 0 then
            local coinItemData = gLobalItemManager:createLocalItemData("Coins", self.m_data.coins)
            table.insert(itemList, coinItemData)
        end

        for i = 1, #self.m_rewardItemList do
            local itemData = self.m_rewardItemList[i]
            local rewardItem = ShopItem:create()
            rewardItem:parseData(itemData)
            table.insert(itemList, rewardItem)
        end
        local view = gLobalItemManager:createRewardLayer(itemList, function()
            if not CardSysManager:needDropCards("Clan Rush") then
                return
            end
        
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Clan Rush")
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

function ClanChatMesage_rushRewards:clickFunc( sender )
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
                    self.m_rewardItemList = data.items
                    self:onRewardCollected()
                end
                
                gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
            end,ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    end
end

function ClanChatMesage_rushRewards:getContentSize()
    local bg_size = self.m_spBg:getContentSize()
    local scaleX = self.m_spBg:getScaleX()
    local scaleY = self.m_spBg:getScaleY()
    return {width = bg_size.width * scaleX, height = bg_size.height * scaleY}
end

function ClanChatMesage_rushRewards:setData( data )
    if not data then
        return
    end
    self.m_data = data
end


function ClanChatMesage_rushRewards:getMessageId()
    return self.m_data.msgId
end

return ClanChatMesage_rushRewards