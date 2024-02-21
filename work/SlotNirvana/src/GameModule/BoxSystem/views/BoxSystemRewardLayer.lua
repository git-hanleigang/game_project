--[[
    神秘宝箱系统 奖励界面
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BoxSystemRewardLayer = class("BoxSystemRewardLayer", BaseLayer)
local MAX_ITEMS = 8 -- 一行最多显示个数
local MAX_ROW = 2 -- 最大行数 【这里只能放下两行，多了就得做滑动列表了】
local OFFSET_Y = 32
local CARD_SOURCE = {
    "Pass Chest"
}

function BoxSystemRewardLayer:ctor()
    BoxSystemRewardLayer.super.ctor(self)
    self:setLandscapeCsbName("BoxSystem/csd/BoxSystemRewardLayer.csb")
end

function BoxSystemRewardLayer:initDatas(_groupName, _rewardData)
    self.m_groupName = _groupName or ""
    self.m_rewardData = _rewardData or {}
    self.m_activityName = ""
    self.m_icon = ""
    local splitArr = string.split(self.m_groupName, "|")
    if splitArr and #splitArr > 1 then
        self.m_activityName = splitArr[1]
        self.m_icon = splitArr[2]
    end
    self.m_coinItem = nil
    self.m_coins = toLongNumber(self.m_rewardData.coins) or toLongNumber(0)
    self.m_items = self.m_rewardData.items or {}
end

function BoxSystemRewardLayer:initCsbNodes()
    self.m_node_reward = self:findChild("node_reward")
end

function BoxSystemRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function BoxSystemRewardLayer:playShowAction()
    gLobalSoundManager:playSound("BoxSystem/sound/openBox.mp3")
    BoxSystemRewardLayer.super.playShowAction(self, "start")
end

function BoxSystemRewardLayer:initView()
    self:initIcon()
    self:initRewards()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BoxSystemRewardLayer:initIcon()
    for i = 1, 2, 1 do
        local sp_box = self:findChild("sp_box_" .. i)
        if sp_box and self.m_icon and self.m_icon ~= "" then
            util_changeTexture(sp_box, "BoxSystem/ui/ui_" .. self.m_icon .. "_" .. i .. ".png")
        end
    end
end

function BoxSystemRewardLayer:initRewards()
    local itemCount = 0
    local propNodeList = {}

    local coins = self.m_coins
    local items = self.m_items
    local isHasCoins = false
    if coins > toLongNumber(0) then
        isHasCoins = true
        local coinItemData = gLobalItemManager:createLocalItemData("Coins", coins)
        table.insert(propNodeList, coinItemData)
        itemCount = itemCount + 1
    end
    if #items > 0 then
        for i = 1, #items do
            local itemData = ShopItem:create()
            itemData:parseData(items[i])
            if string.find(itemData.p_icon, "Coupon") then --促销优惠券
                itemData:setTempData({p_mark = {{ITEM_MARK_TYPE.NONE}}})
            end
            if string.find(itemData.p_icon, "club_pass_") then -- 高倍场体验卡
                itemData:setTempData({p_num = 1})
            end

            table.insert(propNodeList, itemData)
        end
        itemCount = itemCount + #items
    end

    local rowCount = 1
    if itemCount > MAX_ITEMS then
        rowCount = MAX_ROW
    end

    if rowCount == 1 then
        local propNode = gLobalItemManager:addPropNodeList(propNodeList, ITEM_SIZE_TYPE.REWARD)
        if propNode then
            self.m_node_reward:addChild(propNode)
            if not self.m_coinItem and isHasCoins then
                self.m_coinItem = propNode:getChildByTag(1)
            end
        end
    elseif rowCount == 2 then
        local fisrtRowCount = math.ceil(itemCount / 2)

        local firstRowNodeList = {}
        local sencondRowNodeList = {}
        if propNodeList and #propNodeList > 0 then
            for i = 1, #propNodeList do
                if i <= fisrtRowCount then
                    table.insert(firstRowNodeList, propNodeList[i])
                else
                    table.insert(sencondRowNodeList, propNodeList[i])
                end
            end
        end

        local itemWidth = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.REWARD)
        local firstPropNode = gLobalItemManager:addPropNodeList(firstRowNodeList, ITEM_SIZE_TYPE.REWARD)
        if firstPropNode then
            self.m_node_reward:addChild(firstPropNode)
            firstPropNode:setPosition(cc.p(0, itemWidth / 2 + OFFSET_Y))
            if not self.m_coinItem and isHasCoins then
                self.m_coinItem = firstPropNode:getChildByTag(1)
            end
        end

        local sencondPropNode = gLobalItemManager:addPropNodeList(sencondRowNodeList, ITEM_SIZE_TYPE.REWARD)
        if sencondPropNode then
            self.m_node_reward:addChild(sencondPropNode)
            sencondPropNode:setPosition(cc.p(0, -(itemWidth / 2 + OFFSET_Y)))
        end
    end
end

function BoxSystemRewardLayer:onClickMask()
    self.m_isTouch = true
    self:flyCoins()
end

function BoxSystemRewardLayer:clickFunc(sender)
    if self.m_isTouch then
        return
    end
    self.m_isTouch = true
    local name = sender:getName()
    if name == "btn_collect" then
        self:flyCoins()
    end
end

function BoxSystemRewardLayer:flyCoins()
    local flyList = {}
    local btnCollect = self.m_coinItem
    if btnCollect and self.m_coins > toLongNumber(0) then
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        G_GetMgr(G_REF.Currency):playFlyCurrency(
            flyList,
            function()
                self:dropCard()
            end
        )
    else
        self:dropCard()
    end
end

function BoxSystemRewardLayer:dropCard()
    local dropSource = nil
    if CARD_SOURCE and #CARD_SOURCE > 0 then
        for i, v in ipairs(CARD_SOURCE) do
            if CardSysManager:needDropCards(v) == true then
                dropSource = v
                break
            end
        end
    end
    if dropSource ~= nil then
        CardSysManager:doDropCards(
            dropSource,
            function()
                self:dropCard()
            end
        )
    else
        self:dropClubMerge()
    end
end

function BoxSystemRewardLayer:dropClubMerge()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    local cb = function()
        mergeManager:resetPropsBagTempList()
        globalDeluxeManager:dropExperienceCardItemEvt()
        if not tolua.isnull(self) then
            self:closeUI()
        end
    end
    mergeManager:autoPopPropsBagLayer(cb)
end

return BoxSystemRewardLayer
