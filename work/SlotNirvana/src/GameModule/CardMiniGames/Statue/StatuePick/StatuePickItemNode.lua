--[[
    
    author:徐袁
    time:2021-03-20 18:22:13
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseView = require("base.BaseView")
local StatuePickItemNode = class("StatuePickItemNode", BaseView)

function StatuePickItemNode:ctor()
    StatuePickItemNode.super.ctor(self)

    self.m_isOpened = nil
    -- 箱子缓存数据
    self.m_cacheRewardInfo = nil
    -- 是否在升级
    self.m_isInLvUp = false
end

function StatuePickItemNode:initUI(index)
    self.m_index = index or 1

    StatuePickItemNode.super.initUI(self)

    self:initView()
end

--[[
    @desc: 获取csb路径
    author:徐袁
    time:2021-03-20 18:22:13    
    @return:
]]
function StatuePickItemNode:getCsbName()
    return "CardRes/season202102/Statue/StatuePickItem.csb"
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-20 18:22:13
    @return:
]]
function StatuePickItemNode:initCsbNodes()
    self.m_spBox = self:findChild("sp_baoxiang")
    self.m_spBoxLv = {}
    self.m_spBoxOpen = {}
    for i = 1, 3 do
        self.m_spBoxLv[i] = self:findChild("box_Lv" .. i)
        self.m_spBoxOpen[i] = self:findChild("sp_Lv" .. i .. "_open")
    end
    self.m_nodeReward = self:findChild("node_rewards")
    self.m_nodeItem = self:findChild("node_items")
    self.m_palTouch = self:findChild("touch")
    self:addClick(self.m_palTouch)

    -- 子节点跟随显隐
    self.m_nodeReward:setCascadeOpacityEnabled(true)
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-20 18:22:13
    @return:
]]
function StatuePickItemNode:initView()
    self:setOpenStatus(false)
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-20 18:22:13
    @return:
]]
function StatuePickItemNode:updateView()
    self:updateBoxInfo()
end

-- 更新缓存数据
function StatuePickItemNode:updateCacheData()
    -- 更新缓存数据
    self.m_cacheRewardInfo = clone(StatuePickGameData:getBoxReward(self.m_index))
end

function StatuePickItemNode:onEnter()
    StatuePickItemNode.super.onEnter(self)

    -- PICKS数量没了
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:setTouchEnabled(false)
        end,
        ViewEventType.STATUS_PICK_PICKS_FINISHED
    )

    -- 购买PICKS数量结果
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuccess = params.result or false
            if isSuccess then
                self:setTouchEnabled(true)
            end
        end,
        ViewEventType.STATUS_PICK_BUY_PICKS_RESULT
    )
end

function StatuePickItemNode:onExit()
    StatuePickItemNode.super.onExit(self)
end

function StatuePickItemNode:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "touch" then
        -- self:runCsbAction("idle0", false, nil, 60)
        StatuePickControl:requestOpenBox(self.m_index)
    end
end

-- 打开箱子
function StatuePickItemNode:openBox(picks)
    if self.m_isOpened then
        return
    end

    self:updateCacheData()
    self:updateRewardInfo()

    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePickBoxOpen)
    self:runCsbAction(
        "actionframe",
        false,
        function()
            self:setOpenStatus(true)
            if picks ~= nil and picks <= 0 then
                -- 检查Picks次数
                StatuePickControl:checkPicks()
            end
        end,
        60
    )
end

-- 设置箱子打开状态
function StatuePickItemNode:setOpenStatus(_isOpened)
    if self.m_isOpened ~= _isOpened then
        if _isOpened then
            -- local rewardInfo = StatuePickGameData:getBoxReward(self.m_index)
            local rewardInfo = self.m_cacheRewardInfo
            if rewardInfo then
                self:setRewardStatus(rewardInfo)
            end
        else
            -- self:runCsbAction("idle", true)
        end
    end

    self.m_isOpened = _isOpened
end

-- 设置奖励显示状态
function StatuePickItemNode:setRewardStatus(rewardInfo)
    if not rewardInfo then
        return
    end

    local hasReward = rewardInfo:isHasReward()
    if hasReward then
        self:runCsbAction("idle2", true, nil, 60)
    else
        self:runCsbAction("idle_open", true, nil, 60)
    end

    self.m_spBox:setVisible(not hasReward)
    self.m_nodeReward:setVisible(hasReward)
end

-- 显示相应等级的箱子
function StatuePickItemNode:updateBoxInfo()
    if self.m_isInLvUp then
        return
    end

    self:updateCacheData()
    local rewardInfo = self.m_cacheRewardInfo
    if not rewardInfo then
        return
    end

    local index = 1
    local isFree = rewardInfo:isFree()
    if not isFree then
        index = 3
    end
    for i = 1, #self.m_spBoxLv do
        if i == index then
            self.m_spBoxLv[i]:setVisible(true)
        else
            self.m_spBoxLv[i]:setVisible(false)
        end
    end
end

-- 更新箱子奖励信息
function StatuePickItemNode:updateRewardInfo()
    local rewardInfo = self.m_cacheRewardInfo
    if rewardInfo and rewardInfo:isHasReward() then
        -- 有奖励
        self:addRewardNode(rewardInfo)

        -- local index = 2
        -- local isFree = rewardInfo:isFree()
        -- if not isFree then
        --     index = 3
        -- end
        -- 不显示箱子打开的图片
        for i = 1, #self.m_spBoxOpen do
            self.m_spBoxOpen[i]:setVisible(false)
        end
        self.m_nodeReward:setVisible(true)
    else
        self.m_nodeReward:setVisible(false)
    end
end

-- 添加奖励节点
function StatuePickItemNode:addRewardNode(rewardInfo)
    self.m_nodeItem:removeAllChildren()
    -- local rewardInfo = StatuePickGameData:getBoxReward(self.m_index)
    if not rewardInfo then
        return
    end
    local fntScale = 1.6
    -- 创建奖励节点
    local rewardList = {}
    -- 金币
    local coins = rewardInfo:getCoins() or 0
    if coins > 0 then
        local itemData = ShopItem:create()
        itemData.p_fntConfig = {scale = fntScale}
        itemData.p_limit = 3
        local iconCoins = gLobalItemManager:createLocalItemData("Coins", coins, itemData)
        table.insert(rewardList, iconCoins)
    end

    -- 道具
    local items = rewardInfo:getItems() or {}
    if #items > 0 then
        for i = 1, #items do
            if items[i] then
                if not items[i].p_fntConfig then
                    items[i].p_fntConfig = {}
                end
                items[i].p_limit = 3
                items[i].p_fntConfig.scale = fntScale
            end
            table.insert(rewardList, items[i])
        end
    end

    -- 卡包
    if rewardInfo:getType() == "PACKAGE" then
        local itemData = ShopItem:create()
        itemData.p_fntConfig = {scale = fntScale}
        itemData.p_limit = 3
        local _packet = gLobalItemManager:createLocalItemData("Card_Statue_Package", nil, itemData)
        table.insert(rewardList, _packet)
    end

    -- 宝石
    local gems = rewardInfo:getGems() or 0
    if gems > 0 then
        -- 显示宝石
        local itemData = ShopItem:create()
        itemData.p_fntConfig = {scale = fntScale}
        itemData.p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}
        itemData.p_limit = 3
        local gemCoins = gLobalItemManager:createLocalItemData("Gem", gems, itemData)
        table.insert(rewardList, gemCoins)
    end

    local _nodeItem = gLobalItemManager:addPropNodeList(rewardList)
    self.m_nodeItem:addChild(_nodeItem)
    util_setCascadeOpacityEnabledRescursion(_nodeItem, true)
    util_setCascadeColorEnabledRescursion(_nodeItem, true)
end

-- 展示未开启的宝箱奖励
function StatuePickItemNode:showLockedBoxReward()
    if self.m_isOpened then
        return
    end

    -- local rewardInfo = StatuePickGameData:getBoxReward(self.m_index)
    local rewardInfo = self.m_cacheRewardInfo
    if rewardInfo and rewardInfo:isHasReward() then
        -- 有奖励
        self:addRewardNode(rewardInfo)
    end
    self.m_nodeReward:setVisible(true)

    self:runCsbAction(
        "zhanshi",
        false,
        function()
            self:resetLockedBoxReward()
        end,
        60
    )
end

-- 恢复未开启的宝箱奖励
function StatuePickItemNode:resetLockedBoxReward()
    if self.m_isOpened then
        return
    end

    self.m_nodeReward:setVisible(false)

    self:runCsbAction(
        "idle0",
        false,
        function()
        end,
        60
    )
end

-- 升级未开启的宝箱
function StatuePickItemNode:showLockedBoxLvUp()
    if self.m_isOpened then
        return
    end

    for i = 1, 3 do
        self.m_spBoxLv[i]:setVisible(true)
    end

    self.m_isInLvUp = true
    self:runCsbAction(
        "shengji2",
        false,
        function()
            self.m_isInLvUp = false
            self:updateBoxInfo()
        end,
        60
    )
end

function StatuePickItemNode:setTouchEnabled(isEnabled)
    self.m_palTouch:setTouchEnabled(isEnabled)
end

-- 获取动画时间
function StatuePickItemNode:getAnimSecs(key)
    return util_csbGetAnimTimes(self.m_csbAct, key, 60)
end

function StatuePickItemNode:playShakeAction()
    if self.m_isInLvUp == true then
        return
    end
    if not self.m_palTouch:isTouchEnabled() then
        return
    end
    self:runCsbAction(
        "idle",
        false,
        function()
            if StatuePickControl:getBoxInLevelup() then
                return
            end
            if self.m_isInLvUp == true then
                return
            end
            if not self.m_palTouch:isTouchEnabled() then
                return
            end
            self:runCsbAction("idle0", false, nil, 60)
        end,
        60
    )
end

return StatuePickItemNode
