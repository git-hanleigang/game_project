--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:25:28
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/controller/TrillionChallengeMgr.lua
Description: 亿万赢钱挑战 mgr
--]]
local TrillionChallengeMgr = class("TrillionChallengeMgr", BaseGameControl)
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")
local TrillionChallengeLbAddCmptContainer = util_require("GameModule.TrillionChallenge.controller.TrillionChallengeLbAddCmptContainer")

function TrillionChallengeMgr:ctor()
    TrillionChallengeMgr.super.ctor(self)
    
    self.m_componentContainer = TrillionChallengeLbAddCmptContainer:create()

    self:setRefName(G_REF.TrillionChallenge)
    self:setDataModule("GameModule.TrillionChallenge.model.TrillionChallengeModel")
end

-- 获取网络 obj
function TrillionChallengeMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local TrillionChallengeNet = util_require("GameModule.TrillionChallenge.net.TrillionChallengeNet")
    self.m_net = TrillionChallengeNet:getInstance()
    return self.m_net
end

-- 亿万赢钱挑战 左边条节点
function TrillionChallengeMgr:createEntryNode()
    if not self:isCanShowLayer() then
        return
    end

    local node = util_createView("GameModule.TrillionChallenge.views.TrillionChallengeEntryNode")
    return node
end


-- 
--[[
    显示奖励弹板
    _params = {
        coins:
        items:
    }
]]
function TrillionChallengeMgr:showRewardLayer(_params)
    if not self:isCanShowLayer() or type(_params) ~= "table" then
        return
    end

    local rewardList = {}
    local coins = tonumber(_params.coins) or 0
    local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(coins, 6))
    table.insert(rewardList, itemData)
    for _, severData in ipairs(_params.items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(severData)
        table.insert(rewardList, shopItem)
    end

    if #rewardList == 0 or gLobalViewManager:getViewByName("TrillionChallengeRewardLayer") then
        return
    end

    local view = util_createView("GameModule.TrillionChallenge.views.TrillionChallengeRewardLayer", rewardList, coins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

-- 显示主界面
function TrillionChallengeMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByName("TrillionChallengeMainLayer") then
        return
    end

    local view = util_createView("GameModule.TrillionChallenge.views.TrillionChallengeMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end
function TrillionChallengeMgr:showPopLayer()
    return self:showMainLayer()
end

-- spin 更新数据
function TrillionChallengeMgr:spinUpdateRankInfo(_data)
    local data = self:getRunningData()
    if not data or not _data then
        return
    end

    data:setCurTotalWin(_data.totalWin)
    -- 排名变化
    if _data.rank then
        data:setRank(_data.rank)
    end
    -- if _data.rankUp then
    --     data:setRankUp(_data.rankUp)
    -- end
    -- 排名有变化 关卡入口显示上升 下降箭头
    if data:getRankUp() ~= 0 then
        gLobalNoticManager:postNotification(TrillionChallengeConfig.EVENT_NAME.NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP)
    end
end

function TrillionChallengeMgr:sendGetRankDataReq()
    local cb = function(_rankData)
        local data = self:getData()
        data:parseRankData(_rankData)
        gLobalNoticManager:postNotification(TrillionChallengeConfig.EVENT_NAME.ONRECIEVE_TRILLION_CHALLENGE_SUCCESS)
    end
    self:getNetObj():sendGetRankDataReq(cb)
end
function TrillionChallengeMgr:sendCollectReq()
    self:getNetObj():sendCollectReq()
end

-- 获取排名对应奖励
function TrillionChallengeMgr:getRankRewardByRank(_rank)
    return self:getData():getRankRewardByRank(_rank) 
end

function TrillionChallengeMgr:isCanShowHall()
    return self:isCanShowLayer()
end

-- 又可领取的 任务奖励 弹出主界面
function TrillionChallengeMgr:checkCanAutoPopMaiLayer()
    if not self:isCanShowLayer() then
        return false
    end
    local data = self:getRunningData()
    local taskDataList = data:getTaskList()
    local curWin = data:getCurTotalWin()
    for _, taskData in ipairs(taskDataList) do
        if taskData:checkCanCol(curWin) then
            return true
        end
    end
    
    return false
end

-- 注册金币滚动组件
function TrillionChallengeMgr:registerCoinAddComponent(_lb, _maxUIW, _limitStrCount)
    if not _lb then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    self.m_componentContainer:addComponent(_lb, _maxUIW, _limitStrCount)
end

return TrillionChallengeMgr