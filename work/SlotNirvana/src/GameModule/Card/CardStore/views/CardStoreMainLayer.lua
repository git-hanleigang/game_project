-- 卡牌商店 主界面

local CardStoreMainLayer = class("CardStoreMainLayer", BaseLayer)

function CardStoreMainLayer:ctor()
    CardStoreMainLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.MainUI)
    self:setExtendData("CardStoreMainLayer")

    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
end

function CardStoreMainLayer:initCsbNodes()
    self.node_logo = self:findChild("node_logo")
    self.node_npc = self:findChild("node_npc")
    self.node_gem = self:findChild("node_gem")
    self.node_ticket1 = self:findChild("node_ticket1")
    self.node_ticket2 = self:findChild("node_ticket2")
    self.node_time = self:findChild("node_time")

    self.node_normal = {}
    self.node_golden = {}
    for i = 1, 8 do
        local node_reward = self:findChild("node_reward" .. i)
        if node_reward then
            if i <= 4 then
                table.insert(self.node_normal, node_reward)
            else
                table.insert(self.node_golden, node_reward)
            end
        end
    end

    self.node_blind = {}
    for i = 1, 3 do
        local node_blind = self:findChild("node_box" .. i)
        if node_blind then
            table.insert(self.node_blind, node_blind)
        end
    end
end

function CardStoreMainLayer:initView()
    self:initTitle()
    self:initGift()
    self:initNpc()
    self:initItems()
    --self:initBoxes()
    self:initTimer()
end

-- 初始化顶部条
function CardStoreMainLayer:initTitle()
    local gem_title = util_createView("GameModule.Card.CardStore.views.CardStoreTitle", 3)
    if gem_title then
        gem_title:addTo(self.node_gem)
        self.gem_title = gem_title
    end

    local normal_title = util_createView("GameModule.Card.CardStore.views.CardStoreTitle", 1)
    if normal_title then
        normal_title:addTo(self.node_ticket1)
        self.normal_title = normal_title
    end

    local golden_title = util_createView("GameModule.Card.CardStore.views.CardStoreTitle", 2)
    if golden_title then
        golden_title:addTo(self.node_ticket2)
        self.golden_title = golden_title
    end
end

-- 初始化免费道具
function CardStoreMainLayer:initGift()
    local gift_item = util_createView("GameModule.Card.CardStore.views.CardStoreGift")
    if gift_item then
        gift_item:addTo(self.node_logo)
        self.gift_item = gift_item
    end
end

-- 初始化npc
function CardStoreMainLayer:initNpc()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    local spine_npc = util_spineCreate(p_config.npc, true, true, 1)
    if spine_npc then
        spine_npc:addTo(self.node_npc)
        util_spinePlay(spine_npc, "idle", true)
    end
end

-- 初始化商品列表
function CardStoreMainLayer:initItems()
    self.normalItems = {}
    self.goldenItems = {}

    if not self.store_data then
        return
    end

    local normalItems = self.store_data:getNormalItems()
    if normalItems and table.nums(normalItems) > 0 then
        for i, node in ipairs(self.node_normal) do
            local data = normalItems[i]
            local item = util_createView("GameModule.Card.CardStore.views.CardStoreItem", i, "NORMAL")
            if item then
                item:addTo(node)
                table.insert(self.normalItems, item)
            end
        end
    end

    local goldenItems = self.store_data:getGoldenItems()
    if goldenItems and table.nums(goldenItems) > 0 then
        for i, node in ipairs(self.node_golden) do
            local data = goldenItems[i]
            local item = util_createView("GameModule.Card.CardStore.views.CardStoreItem", i, "GOLDEN")
            if item then
                item:addTo(node)
                table.insert(self.goldenItems, item)
            end
        end
    end
end

-- 初始化盲盒
--function CardStoreMainLayer:initBoxes()
--    self.blindItems = {}
--    if not self.store_data then
--        return
--    end
--    local blindItems = self.store_data:getBlindItems()
--    for i, node in ipairs(self.node_blind) do
--        local data = blindItems[i]
--        local item = util_createView("GameModule.Card.CardStore.views.CardStoreBlind", i, "BLIND")
--        if item then
--            item:addTo(node)
--            table.insert(self.blindItems, item)
--        end
--    end
--end

function CardStoreMainLayer:initTimer()
    local timer = util_createView("GameModule.Card.CardStore.views.CardStoreTimer")
    if timer then
        timer:addTo(self.node_time)
        self.timer = timer
    end
end

-- 重置
function CardStoreMainLayer:onReset()
    if self.normal_title and not tolua.isnull(self.normal_title) then
        self.normal_title:onRefresh()
    end

    if self.golden_title and not tolua.isnull(self.golden_title) then
        self.golden_title:onRefresh()
    end

    if self.gift_item and not tolua.isnull(self.gift_item) then
        self.gift_item:onReset()
    end

    for i, item in ipairs(self.normalItems) do
        if item and not tolua.isnull(item) then
            item:onReset(true)
        end
    end

    for i, item in ipairs(self.goldenItems) do
        if item and not tolua.isnull(item) then
            item:onReset(true)
        end
    end

    --for i, item in ipairs(self.blindItems) do
    --    if item and not tolua.isnull(item) then
    --        item:onRefresh()
    --    end
    --end

    if self.timer and not tolua.isnull(self.timer) then
        self.timer:onRefresh()
    end
end

-- 刷新
function CardStoreMainLayer:onRefresh()
    if self.normal_title and not tolua.isnull(self.normal_title) then
        self.normal_title:onRefresh()
    end

    if self.golden_title and not tolua.isnull(self.golden_title) then
        self.golden_title:onRefresh()
    end

    if self.gift_item and not tolua.isnull(self.gift_item) then
        self.gift_item:onRefresh()
    end

    for i, item in ipairs(self.normalItems) do
        if item and not tolua.isnull(item) then
            item:onRefresh()
        end
    end

    for i, item in ipairs(self.goldenItems) do
        if item and not tolua.isnull(item) then
            item:onRefresh()
        end
    end

    --for i, item in ipairs(self.blindItems) do
    --    if item and not tolua.isnull(item) then
    --        item:onRefresh()
    --    end
    --end

    if self.timer and not tolua.isnull(self.timer) then
        self.timer:onRefresh()
    end
end

function CardStoreMainLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
    self:showGuide()
end

function CardStoreMainLayer:showGuide()
    if not self.store_data then
        return
    end
    if not self.store_data:isShowGuide() then
        return
    end
    local guide_layer = util_createView("GameModule.Card.CardStore.views.CardStoreGuideLayer")
    if guide_layer then
        gLobalViewManager:showUI(guide_layer, ViewZorder.ZORDER_UI)
    end
end

function CardStoreMainLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_info" then
        self:showInfo()
    elseif name == "btn_boxInfo" then
    --self:showBoxInfo()
    end
end

-- 显示玩法介绍面板
function CardStoreMainLayer:showInfo()
    G_GetMgr(G_REF.CardStore):showInfoLayer()
end

--function CardStoreMainLayer:showBoxInfo()
--    G_GetMgr(G_REF.CardStore):showBlindInfoLayer()
--end

function CardStoreMainLayer:onEnter()
    CardStoreMainLayer.super.onEnter(self)
    -- 监听进度事件
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:onRefresh()
        end,
        ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH
    )
    -- 监听进度事件
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:onReset()
        end,
        ViewEventType.NOTIFY_EVENT_CARD_STORE_RESET
    )
    -- 监听进度事件
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if not tolua.isnull(self) then
                if params[1] == "success" then
                    if self.gift_item and not tolua.isnull(self.gift_item) then
                        self.gift_item:onRefresh()
                    end
                else
                end
            end
        end,
        ViewEventType.NOTIFY_ADS_CARDSTORECD
    )
    --self:showRewardTest()
end

function CardStoreMainLayer:showRewardTest()
    if DEBUG ~= 2 then
        return
    end
    local data = {
        cardDropInfoResultList = {},
        num = 1,
        rewardType = "ITEM",
        shopItemResultList = {
            {
                activityId = "-1",
                description = "lottery卷每日任务奖励",
                icon = "Lottery_icon",
                id = 940002,
                expireAt = 0,
                item = 0,
                itemInfo = {
                    createTime = 1652343574000,
                    description = "",
                    icon = "/XX/XX.png",
                    id = 309,
                    duration = -1,
                    linkId = "-1",
                    name = "LOTTERY TICKET",
                    subtitle = "+%s",
                    type2 = 1,
                    type1 = 1,
                    lastUpdateTime = 1652343574000
                }
            },
            num = 1,
            buff = 0,
            mark = "2",
            type = "Item"
        }
    }
    G_GetMgr(G_REF.CardStore):showRewardLayer(data)
end

function CardStoreMainLayer:closeUI()
    G_GetMgr(G_REF.CardStore):resetLogEnterType()
    CardStoreMainLayer.super.closeUI(self, nil)
end

return CardStoreMainLayer
