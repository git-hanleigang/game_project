--[[
    
    author:徐袁
    time:2021-03-19 20:20:32
]]
local StatuePickCollectLayer = class("StatuePickCollectLayer", BaseLayer)

function StatuePickCollectLayer:initDatas()
    self.m_dropFuncList = {}
    self:setLandscapeCsbName("CardRes/season202102/Statue/StatuePickCollectLayer.csb")

    -- self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    -- self:setPauseSlotsEnabled(true)
    self:setExtendData("StatuePickCollectLayer")
end

function StatuePickCollectLayer:getRewardData()
    return require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickRewardData"):getInstance()
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-19 20:20:32
    @return:
]]
function StatuePickCollectLayer:initCsbNodes()
    -- self.m_fntCoins = self:findChild("font_coin")
    self.m_nodeReward = self:findChild("node_reward")
    self.m_nodeReward:setScale(0.7)

    self.m_btnCollect = self:findChild("btn_collect")
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-19 20:20:32
    @return:
]]
function StatuePickCollectLayer:initView()
    -- self.m_fntCoins:setString("")
    self:runCsbAction("idle", true)
    self:initDropList()
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-19 20:20:32
    @return:
]]
function StatuePickCollectLayer:updateView()
    self:updateRewards()
end

-- 注册消息事件
function StatuePickCollectLayer:registerListener()
    StatuePickCollectLayer.super.registerListener(self)
end

function StatuePickCollectLayer:onEnter()
    StatuePickCollectLayer.super.onEnter(self)
    self:updateView()
end

function StatuePickCollectLayer:onExit()
    StatuePickCollectLayer.super.onExit(self)
end

-- layer显示完成的回调
function StatuePickCollectLayer:onShowedCallFunc()
end

function StatuePickCollectLayer:onClickMask()
    self:collectReward()
end

function StatuePickCollectLayer:clickFunc(sender)
    local senderName = sender:getName()

    if senderName == "btn_collect" then
        self:collectReward()
    end
end

function StatuePickCollectLayer:setBtnEnabled(isEnabled)
    self.m_btnCollect:setTouchEnabled(isEnabled)
end

-- 领取奖励
function StatuePickCollectLayer:collectReward()
    if not self.m_btnCollect:isTouchEnabled() then
        return
    end

    self:setBtnEnabled(false)

    local rewardData = self:getRewardData()
    -- 播放飞金币动画
    local coins = rewardData:getCoins()
    local gems = rewardData:getGems()
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
        local flyList = {}
        if coins > 0 then
            -- local startPos = self.m_coinNode:convertToWorldSpace(cc.p(0, 0))
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        if gems > 0 then
            -- local startPos = self.m_gemNode:convertToWorldSpace(cc.p(0, 0))
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = gems, startPos = startPos})
        end

        cuyMgr:playFlyCurrency(
            flyList,
            function()
                self:triggerDropFuncNext()
            end
        )
    else
        if coins > 0 then
            self:pubPlayFlyCoin(coins, handler(self, self.triggerDropFuncNext))
        else
            self:triggerDropFuncNext()
        end
    end
end

-- 刷新奖励信息
function StatuePickCollectLayer:updateRewards()
    self.m_nodeReward:removeAllChildren()

    -- 创建奖励节点
    local rewardList = {}

    local rewardData = self:getRewardData()

    -- 金币
    local coins = rewardData:getCoins()
    if coins > 0 then
        local iconCoins = gLobalItemManager:createLocalItemData("Coins", coins)
        table.insert(rewardList, iconCoins)
    end
    -- 道具
    local items = rewardData:getItems() or {}
    for i = 1, #items do
        local itemData = items[i]
        table.insert(rewardList, itemData)
    end

    -- 宝石
    local gems = rewardData:getGems()
    if gems > 0 then
        -- 显示宝石
        local gemCoins = gLobalItemManager:createLocalItemData("Gem", gems, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
        table.insert(rewardList, gemCoins)
    end

    -- 卡包
    local _cpCount = #rewardData:getDropCards()
    if _cpCount > 0 then
        local _packet = gLobalItemManager:createLocalItemData("Card_Statue_Package", _cpCount, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})

        table.insert(rewardList, _packet)
    end

    -- local _nodeItem = gLobalItemManager:addPropNodeList(rewardList, nil, 0.7)
    local _nodeItem = gLobalItemManager:createRewardListView(rewardList)
    self.m_coinNode = _nodeItem:findCell("Coins")
    self.m_gemNode = _nodeItem:findCell("Gem")
    if _nodeItem then
        self.m_nodeReward:addChild(_nodeItem)
    end
end

function StatuePickCollectLayer:pubPlayFlyCoin(_totalCoins, _flyCoinsEndCall)
    local coinNode = self.m_coinNode
    if coinNode then
        local coinNodeWidth = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
        local startPos = coinNode:convertToWorldSpace(cc.p(0, 0))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        globalData.userRunData:setCoins(globalData.userRunData.coinNum + _totalCoins)
        view:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            _totalCoins,
            function()
                if not tolua.isnull(self) then
                    if _flyCoinsEndCall ~= nil then
                        _flyCoinsEndCall()
                    end
                end
            end
        )
    else
        if _flyCoinsEndCall ~= nil then
            _flyCoinsEndCall()
        end
    end
end

-- 检测掉卡
function StatuePickCollectLayer:dropCrads()
    local rewardData = self:getRewardData()
    local drops = rewardData:getDropCards()
    for i = 1, #drops do
        local dropData = drops[i]
        if dropData and dropData.clanReward and #dropData.clanReward > 0 then
            for j = 1, #dropData.clanReward do
                if dropData.clanReward[j].coins and dropData.clanReward[j].coins > 0 then
                    local clanCoins = dropData.clanReward[j].coins
                    -- local buffDoubleCoins = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_COMPLETE_COIN_BONUS)
                    -- if buffDoubleCoins and buffDoubleCoins > 0 then
                    --     clanCoins = dropData.clanReward[j].coins * buffDoubleCoins
                    -- end
                    globalData.userRunData:setCoins(globalData.userRunData.coinNum + clanCoins)
                end
            end
        end
    end
    CardSysManager:doDropCardsData(drops, false)
    if CardSysManager:needDropCards("Card Picks") == true then
        CardSysManager:doDropCards("Card Picks")
    end
end

function StatuePickCollectLayer:closeUI()
    local callback = function()
        self:dropCrads()
        gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_COLLECT_REWARD_COMPLETED)
    end
    StatuePickCollectLayer.super.closeUI(self, callback)
end

------------------------------------------------ 领取掉落 检测list ------------------------------------------------
-- 初始化 list
function StatuePickCollectLayer:initDropList()
    local _dropFuncList = {}

    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.closeUI)

    self.m_dropFuncList = _dropFuncList
end

-- 检测 list 调用方法
function StatuePickCollectLayer:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        return
    end

    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测高倍场体验卡
function StatuePickCollectLayer:triggerDeluxeCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, handler(self, self.triggerDropFuncNext))
end
------------------------------------------------ 领取掉落 检测list ------------------------------------------------

return StatuePickCollectLayer
