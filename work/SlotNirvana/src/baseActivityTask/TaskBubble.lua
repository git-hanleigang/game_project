--[[
    任务气泡
]]
-- ios fix
local TaskBubble = class("TaskBubble", util_require("base.BaseView"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager"):getInstance()
local ShopItem = require "data.baseDatas.ShopItem"

function TaskBubble:initUI(_csbName, _activityName, _itemScale)
    self:createCsbNode(_csbName)
    self:initData(_activityName, _itemScale)
    self:initNode()
    self:addItems()
end
--初始化数据
function TaskBubble:initData(_activityName, _itemScale)
    self.m_taskDataObj = ActivityTaskManager:getCurrentTaskByActivityName(_activityName)
    self.m_coins = self.m_taskDataObj:getCoins()
    self.m_isHideBubble = true --气泡是否隐藏
    self.m_isActionTime = false --是否正在动画中
    self.m_isFirstOpen = true --是否是第一次打开气泡

    self.m_itemScale = _itemScale
end
--初始化节点
function TaskBubble:initNode()
    self.m_addItemNode = self:findChild("Node_jiedian")
    assert(self.m_addItemNode, "用于添加道具的节点为空")
end
--气泡显示动画
function TaskBubble:runShowAmin()
    if not self.m_isActionTime and self.m_isHideBubble then
        local time = 0.1
        if self.m_isFirstOpen then
            time = 0.5
            self.m_isFirstOpen = false
        end
        local showBubble = function()
            if not self.m_isActionTime then
                local showEndCallBack = function()
                    local hideBubble = function()
                        self:runHideAmin()
                    end
                    self:setBubbleState(false)
                    self:setActionTimeState(false)
                    performWithDelay(self.m_addItemNode, hideBubble, 5)
                end
                self:setActionTimeState(true)
                self:runCsbAction("show", false, showEndCallBack, 60)
            end
        end
        performWithDelay(self.m_addItemNode, showBubble, time)
    end
end
--气泡隐藏动画
function TaskBubble:runHideAmin()
    if not self.m_isActionTime and not self.m_isHideBubble then
        self:setActionTimeState(true)
        self:runCsbAction(
            "hide",
            false,
            function()
                self:setActionTimeState(false)
                self:setBubbleState(true)
            end,
            60
        )
    end
end
--强制气泡隐藏
function TaskBubble:forceHide()
    if self.m_isActionTime then
        if self.m_isHideBubble then
            self:runCsbAction("hide", false, nil, 60)
        end
    else
        self:runHideAmin()
    end
end
--添加道具
function TaskBubble:addItems()
    if self.m_taskDataObj then
        local itemDataList = {}
        --金币道具
        if self.m_coins and self.m_coins > 0 then
            local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_coins)
            itemData:setTempData({p_limit = 3})
            itemDataList[#itemDataList + 1] = itemData
        end
        --通用道具
        local rewardItems = self.m_taskDataObj:getItemData()
        local count = #rewardItems
        if rewardItems and count > 0 then
            for i, v in ipairs(rewardItems) do
                local tempData = ShopItem:create()
                tempData:parseData(v)
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(tempData.p_icon, tempData.p_num, tempData)
            end
        end
        local index = 1
        local max = table.nums(self.m_itemScale)
        if count > 0 and count <= max then
            index = count
        elseif count > max then
            index = max
        end
        local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD, self.m_itemScale[index])
        self.m_addItemNode:addChild(itemNode)
        util_setCascadeOpacityEnabledRescursion(self.m_addItemNode, true)
    end
end
--删除道具
function TaskBubble:removeItems()
    self.m_addItemNode:removeAllChildren()
end
--设置气泡状态
function TaskBubble:setBubbleState(_flag)
    self.m_isHideBubble = _flag
end
function TaskBubble:getBubbleState()
    return self.m_isHideBubble
end
--设置是否正在执行动画状态
function TaskBubble:setActionTimeState(_flag)
    self.m_isActionTime = _flag
end
function TaskBubble:getActionTimeState()
    return self.m_isActionTime
end

function TaskBubble:onEnter()
end
function TaskBubble:onExit()
end
return TaskBubble
