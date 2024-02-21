--[[
Author: cxc
Date: 2021-01-11 19:49:27
LastEditTime: 2021-06-24 23:09:19
LastEditors: Please set LastEditors
Description: 常规促销 小游戏 选择哪个已奖励 金币袋
FilePath: /SlotNirvana/src/views/sale/LuckyChooseLayer.lua
--]]
local LuckyChooseLayer = class("LuckyChooseLayer", BaseLayer)
local LuckyChooseManager = util_require("manager/System/LuckyChooseManager"):getInstance()
local LuckyChooseConfig = util_require("views.sale.LuckyChooseConfig")

function LuckyChooseLayer:ctor()
    LuckyChooseLayer.super.ctor(self)

    self:setPauseSlotsEnabled(true) 

    self.m_itemNodes = {}


    self:setExtendData("LuckyChooseLayer")
    self:setLandscapeCsbName("Sale/LuckyChooseLayer.csb") 
end

function LuckyChooseLayer:initUI(_callFunc)
    LuckyChooseLayer.super.initUI(self) 
    
    self.m_callFunc = _callFunc -- 关闭界面的回调

    for i=1, LuckyChooseConfig.BAG_COUNT do
        local parentItem = self:findChild("node_bag" .. i)
        local nodeItem = util_createView("views.sale.LuckyChooseItem", i)
        nodeItem:addTo(parentItem)

        table.insert(self.m_itemNodes, nodeItem)
    end
end

--[[
description: 更新 所有金钱袋
param _openIdx number 开启的哪一个
param _rewards array 3个金钱袋对应的奖励
--]]
function LuckyChooseLayer:updateItems(_openIdx, _rewards)
    if not _openIdx or #self.m_itemNodes ~= LuckyChooseConfig.BAG_COUNT then
        return
    end
    -- "rewards":[{"coins":495000000,"hit":false},{"coins":1485000000,"hit":false},{"coins":4950000000,"hit":false}]
    local gainRewardInfo = nil
    for i=1, LuckyChooseConfig.BAG_COUNT do
        local rewardInfo = _rewards[i]
        if not rewardInfo then
            local jsonStr = json.encode(_rewards)
            release_print("cxc----常规促销小游戏数据有问题--", jsonStr)
            gLobalBuglyControl:luaException("cxc----常规促销小游戏数据有问题--",jsonStr)
            return
        end
        local bTouch = rewardInfo.hit or false
        if bTouch then
            gainRewardInfo = table.remove(_rewards, i)
            break
        end
    end
    for i=1, LuckyChooseConfig.BAG_COUNT do
        local nodeItem = self.m_itemNodes[i]
        local rewardInfo = nil
        if _openIdx == i then
            rewardInfo = gainRewardInfo
        else
            rewardInfo = _rewards[#_rewards]
            table.remove(_rewards, #_rewards)
        end
        nodeItem:refreshUI(rewardInfo)
    end
end

function LuckyChooseLayer:onShowedCallFunc()
    LuckyChooseLayer.super.onShowedCallFunc(self)
    
    self:runCsbAction("idle", true)
end
function LuckyChooseLayer:onExit()
    LuckyChooseLayer.super.onExit(self)

    -- 也许中间有 什么弹板设么操作中断了 小游戏
    local noCoinSaleData = G_GetActivityDataByRef(ACTIVITY_REF.NoCoinSale)
    if noCoinSaleData then
        noCoinSaleData:resetMiniGameTrigger()
    end
    local commSaleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
    if commSaleData then
        commSaleData:resetMiniGameTrigger()
    end

    -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT) 
end 

-- 注册消息事件
function LuckyChooseLayer:registerListener()
    LuckyChooseLayer.super.registerListener(self)

     -- 更新 items
     gLobalNoticManager:addObserver(self,function(self, _rewards)
        local openIdx = LuckyChooseManager:getOpenBagIdx() 
        -- 刷新items
        self:updateItems(openIdx, _rewards)
    end,LuckyChooseConfig.EVENT_NAME.NOTIFY_UPDATE_ITEM_STATE)

    -- 关闭界面
    gLobalNoticManager:addObserver(self,function(self, params)
        self:closeUI(self.m_callFunc)
    end,LuckyChooseConfig.EVENT_NAME.NOTIFY_COLLECT_CLOSE_UI)
end

return LuckyChooseLayer