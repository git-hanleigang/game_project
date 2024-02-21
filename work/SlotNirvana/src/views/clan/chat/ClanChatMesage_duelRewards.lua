--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-02 14:08:22
]]
local ChatConfig = util_require("data.clanData.ChatConfig")
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ShopItem = util_require("data.baseDatas.ShopItem")

local ClanChatMesage_duelRewards = class("ClanChatMesage_duelRewards", BaseView)

local DUEL_DESCRIBE = {
    {txt = ""},
    {txt = "Congrats! Your team won the Duel.\nHere is a reward for your contribution. Thank you!", color = cc.c3b(255, 220, 0)}, -- 赢了有奖
    {txt = "Congrats! Your team won the Team Duel.", color = cc.c3b(255, 220, 0)}, -- 赢了没奖
    {txt = "Sorry, Your team lost the Team Duel.", color = cc.c3b(255, 220, 0)} -- 输了（没奖）
}

local item_offset2Edge = 20 -- 距离边界的偏移值

function ClanChatMesage_duelRewards:initDatas(_data)
    ClanChatMesage_duelRewards.super.initDatas(self)

    self.m_data = _data
    self.m_bgHeight = 0
    self.m_members = {}
    self.m_itemList = {}
    self.m_propsBagList = {}
    self.m_status = false
    self.m_isHasReward = false
end

function ClanChatMesage_duelRewards:initCsbNodes()
    self.m_lbTaskDesc = self:findChild("lb_taskDesc")
    self.m_lbCoins = self:findChild("lb_shuzi")
    self.m_nodeTime = self:findChild("sp_timer")
    self.m_lbTime = self:findChild("font_timer")
    self.m_spCollectedSign = self:findChild("sp_duihao")
    self.m_spBg = self:findChild("sp_tiaofu")
    self.m_bgHeight = self.m_spBg:getContentSize().height
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_font_word = self:findChild("font_word")
end

function ClanChatMesage_duelRewards:initUI(...)
    ClanChatMesage_duelRewards.super.initUI(self)

    -- 时间
    self:initLeftTimeUI()

    -- 信息
    self:initItemList()

    self:updateUI()
end

function ClanChatMesage_duelRewards:onEnter()
    ClanChatMesage_duelRewards.super.onEnter(self)

    -- 注册 领取事件 0:未领取，1:已领取
    if self.m_data.status == 0 and self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
        gLobalNoticManager:addObserver(
            self,
            function(self, data)
                if data.result.msgId == self.m_data.msgId then
                    self.m_data.coins = tonumber(data.coins) or 0
                    self.m_rewardItemList = data.items
                    self:onRewardCollected(true)
                end
            end,
            ChatConfig.EVENT_NAME.UPDATE_CHAT_REWARD_UI
        )
    end
end

function ClanChatMesage_duelRewards:getCsbName()
    return "Club/csd/Chat_New/Club_wall_chatbubble_team_duel.csb"
end

-- 信息
function ClanChatMesage_duelRewards:initItemList()
    if self.m_data.content and #self.m_data.content > 0 then
        local info = cjson.decode(self.m_data.content)
        self.m_members = info.members or {}
        self.m_status = info.status or false
        if self.m_status then -- 公会胜利
            for k, v in pairs(self.m_members) do
                if k == globalData.userRunData.userUdid then
                    self.m_isHasReward = true
                    -- 道具奖励
                    local items = v.items or {}
                    for i = 1, #items do
                        local itemData = items[i]
                        local rewardItem = ShopItem:create()
                        rewardItem:parseData(itemData)
                        table.insert(self.m_itemList, rewardItem)
                    end
                    break
                end
            end
        end

        local describeInx = 1 -- 默认是空 “”
        self.m_spBg:setVisible(self.m_isHasReward)
        if self.m_isHasReward then
            describeInx = 2
            self.m_font_word:setPositionY(-66)
        else
            describeInx = self.m_status and 3 or 4
            self.m_font_word:setPositionY(0)
        end
        local describe = DUEL_DESCRIBE[describeInx].txt
        local color = DUEL_DESCRIBE[describeInx].color
        self.m_font_word:setString(describe)
        if color then
            self.m_font_word:setColor(color)
        end
    end
end

function ClanChatMesage_duelRewards:updateRewardUIVisible()
    local bShowCoins = self.m_data.status == 1
    local nodeCoins = self:findChild("sp_di")
    self.m_lbTaskDesc:setPositionY(bShowCoins and self.m_bgHeight * 0.74 or self.m_bgHeight * 0.5)
    nodeCoins:setVisible(bShowCoins)
end

-- 奖励
function ClanChatMesage_duelRewards:updateDuelRewardUI()
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
        {node = self.m_lbCoins, alignX = 5}
    }
    if #itemList > 0 then
        table.insert(alignUIList, {node = self:findChild("sp_add"), alignX = 5})
        table.insert(alignUIList, {node = nodeItem, alignX = 5, size = cc.size(#itemList * width * 0.5, width * 0.5)})
    else
        self:findChild("sp_add"):setVisible(false)
    end
    util_alignCenter(alignUIList)
end

function ClanChatMesage_duelRewards:updateUI()
    -- 按钮触摸显隐
    self:updateBtnUI()

    self:updateDuelRewardUI()

    -- 奖励
    self:updateRewardUIVisible()
end

-- 按钮触摸显隐
function ClanChatMesage_duelRewards:updateBtnUI()
    local bVisible = self.m_data.status == 0
    self.m_btnCollect:setVisible(bVisible)
    self.m_spCollectedSign:setVisible(not bVisible)
    if not bVisible then
        return
    end

    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        self:setButtonLabelDisEnabled("btn_collect", self.m_data.status == 0)
    end
    local left_time = util_getLeftTime(self.m_data.effecTime)
    self:setButtonLabelDisEnabled("btn_collect", left_time > 0)
end

-- 时间
function ClanChatMesage_duelRewards:initLeftTimeUI()
    local bVisible = self.m_data.status == 0
    self.m_nodeTime:setVisible(bVisible)
    if not bVisible then
        self.m_bUpdateUISec = false
        return
    end

    self.m_bUpdateUISec = true
    self:updateLeftTimeUI()
end

function ClanChatMesage_duelRewards:updateLeftTimeUI()
    if self.m_data.effecTime and self.m_data.effecTime > 0 then
        local timeStr, bOver = util_daysdemaining(self.m_data.effecTime * 0.001)
        if bOver or self.m_data.status == 1 then
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
function ClanChatMesage_duelRewards:updateUISec()
    if not self.m_bUpdateUISec then
        return
    end

    self:updateLeftTimeUI()
end

function ClanChatMesage_duelRewards:onRewardCollected(bFast)
    self.m_data.status = 1
    self:updateDuelRewardUI()
    self:updateLeftTimeUI()
    self:updateUI()

    self:flyCoins(bFast)
end

function ClanChatMesage_duelRewards:flyCoins(bFast)
    ClanManager:sendClanInfo()
    local curChatShowTag = ChatManager:getCurChatTag()
    if bFast or (self.m_data and self.m_data.m_listType ~= curChatShowTag) then
        -- 不再当前页签不飞金币
        return
    end

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
        local view =
            gLobalItemManager:createRewardLayer(
            itemList,
            function()
                if CardSysManager:needDropCards("Clan DUEL") then
                    CardSysManager:doDropCards(
                        "Clan DUEL",
                        function()
                            dropClubMerge()
                        end
                    )
                end
            end,
            self.m_data.coins,
            true
        )
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            return
        end
    end

    if self.m_lbCoins and self.m_data and self.m_data.coins > 0 then
        local senderSize = self.m_lbCoins:getContentSize()
        local startPos = self.m_lbCoins:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(startPos, endPos, baseCoins, self.m_data.coins)
    end
end

-- 尝试 掉落合成福袋
function ClanChatMesage_duelRewards:initDropPropsBagLayer()
    if self.m_rewardItemList and #self.m_rewardItemList > 0 then
        -- 合成福包弹板
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        for i, v in ipairs(self.m_rewardItemList ) do
            local rewardItem = ShopItem:create()
            rewardItem:parseData(v)
            if string.find(rewardItem.p_icon, "Pouch") then
                table.insert(self.m_propsBagList, rewardItem)
            end
        end
        mergeManager:setPopPropsBagTempList(self.m_propsBagList)
    end
end

function ClanChatMesage_duelRewards:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_collect" then
        if self.m_data.status == 1 then
            self.m_btnCollect:setVisible(false)
            self:setButtonLabelDisEnabled("btn_collect", false)
            self.m_spCollectedSign:setVisible(true)
            return
        end
        if self.m_data.msgId and self.m_data.extra and self.m_data.extra.randomSign then
            ClanManager:requestChatReward(self.m_data.msgId, self.m_data.extra.randomSign)
            gLobalNoticManager:addObserver(
                self,
                function(self, data)
                    if data.result.msgId == self.m_data.msgId then
                        self.m_data.coins = tonumber(data.coins) or 0
                        self.m_rewardItemList = data.items
                        self:onRewardCollected()
                    end

                    gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA)
                end,
                ChatConfig.EVENT_NAME.CHAT_REWARD_GETDATA
            )
        else
            printInfo("聊天发送领奖请求 信息不全 不能发送")
        end
    end
end

function ClanChatMesage_duelRewards:getContentSize()
    if self.m_isHasReward then
        local bg_size = self.m_spBg:getContentSize()
        local scaleX = self.m_spBg:getScaleX()
        local scaleY = self.m_spBg:getScaleY()
        local font_size = self.m_font_word:getContentSize()
        return {
            width = bg_size.width * scaleX,
            height = bg_size.height * scaleY + font_size.height + item_offset2Edge * 2
        }
    else
        local font_size = self.m_font_word:getContentSize()
        return {width = font_size.width, height = font_size.height + item_offset2Edge}
    end
end

function ClanChatMesage_duelRewards:setData(data)
    if not data then
        return
    end
    self.m_data = data
end

function ClanChatMesage_duelRewards:getMessageId()
    return self.m_data.msgId
end

return ClanChatMesage_duelRewards
