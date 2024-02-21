--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:40:37
    describe:小猪转盘-扇叶
]]
local GoodWheelPiggySlide = class("GoodWheelPiggySlide", BaseView)

local arr = {"Dark", "Shallow", "Gold"}

function GoodWheelPiggySlide:ctor()
    GoodWheelPiggySlide.super.ctor(self)
    self.m_data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    self.m_config = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getConfig()
end

function GoodWheelPiggySlide:getCsbName()
    return self.m_config.Slide
end

function GoodWheelPiggySlide:initUI(data)
    self.m_index = data
    self.m_reward = self.m_data:getRewardByIndex(self.m_index)
    GoodWheelPiggySlide.super.initUI(self, data)
    self:initView()
    local a = self:getRotation()
end

function GoodWheelPiggySlide:initCsbNodes()
    self.m_spGold = self:findChild("sp_gold")
    assert(self.m_spGold, "GoodWheelPiggySlide 必要的节点1")
    self.m_spDark = self:findChild("sp_dark")
    assert(self.m_spDark, "GoodWheelPiggySlide 必要的节点2")
    self.m_spShallow = self:findChild("sp_shallow")
    assert(self.m_spShallow, "GoodWheelPiggySlide 必要的节点3")
    self.m_spSelect = self:findChild("sp_xuanzhong")
    assert(self.m_spSelect, "GoodWheelPiggySlide 必要的节点4")
    self.m_nodeReward = self:findChild("Node_Reward")
    assert(self.m_nodeReward, "GoodWheelPiggySlide 必要的节点5")
    self.m_nodeSelect = self:findChild("ef_duigou")
    assert(self.m_nodeSelect, "GoodWheelPiggySlide 必要的节点5")
end

function GoodWheelPiggySlide:initView()
    self:initSlideVisible()
    local index = ((self.m_index - 1) % (#arr - 1)) + 1
    local bigIndex = self.m_data:getBigIndex()
    if self.m_index == bigIndex then
        self.m_spGold:setVisible(true)
    else
        self["m_sp" .. arr[index]]:setVisible(true)
    end

    self:createItem()
end

function GoodWheelPiggySlide:createItem()
    if self.m_reward then
        local reward = self.m_reward
        local itemDataList = self:getItemDataList()
        local shopItemUI = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
        if shopItemUI ~= nil then
            self.m_nodeReward:addChild(shopItemUI)
            if reward.collected then
                self:playCollected()
            else
                self:playNotCollected()
            end
        end
    end
end

function GoodWheelPiggySlide:initSlideVisible()
    for i = 1, #arr do
        self["m_sp" .. arr[i]]:setVisible(false)
    end
end

function GoodWheelPiggySlide:playIdle()
    self:runCsbAction(
        "idle",
        false,
        function()
            local reward = self.m_reward
            if reward ~= nil then
                local itemDataList = self:getItemDataList()
                local clickFunc = function()
                    if CardSysManager:needDropCards("Pig Dish") == true then
                        gLobalNoticManager:addObserver(
                            self,
                            function(self, func)
                                if not tolua.isnull(self) then
                                    self:playOver()
                                end
                            end,
                            ViewEventType.NOTIFY_CARD_SYS_OVER
                        )
                        CardSysManager:doDropCards("Pig Dish", nil)
                    else
                        if self and not tolua.isnull(self) then
                            self:playOver()
                        end
                    end
                end
                local rewardLayer = gLobalItemManager:createRewardLayer(itemDataList, clickFunc, tonumber(reward.coins), true)
                gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
            end
        end,
        60
    )
end

function GoodWheelPiggySlide:getItemDataList()
    local reward = self.m_reward
    local itemDataList = {}
    if reward ~= nil then
        local propList = reward.items
        -- 道具列表
        local coins = reward.coins
        -- 金币道具
        if coins and coins > 0 then
            local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
            itemData:setTempData({p_limit = 3})
            itemDataList[#itemDataList + 1] = itemData
        end
        -- 通用道具
        if propList and #propList > 0 then
            for i, v in ipairs(propList) do
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            end
        end
    end
    return itemDataList
end

function GoodWheelPiggySlide:playStart()
    self:runCsbAction(
        "start",
        false,
        function()
            self:playIdle()
        end,
        60
    )
end

function GoodWheelPiggySlide:playOver()
    self:runCsbAction(
        "over",
        false,
        function()
            performWithDelay(
                self,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GOODWHEELPIGGY_SPIN_END)
                end,
                0.5
            )
        end,
        60
    )
end

function GoodWheelPiggySlide:playNotCollected()
    self:runCsbAction("idle_notCollected", false)
end

function GoodWheelPiggySlide:playCollected()
    self:runCsbAction("idle_collected", false)
end

function GoodWheelPiggySlide:setSelectRotation(angle)
    self.m_nodeSelect:setRotation(angle)
end

return GoodWheelPiggySlide
