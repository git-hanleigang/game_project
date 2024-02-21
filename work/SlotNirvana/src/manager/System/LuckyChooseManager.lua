--[[
Author: cxc
Date: 2021-01-13 15:17:36
LastEditTime: 2021-01-19 10:10:40
LastEditors: Please set LastEditors
Description: 常规促销 小游戏 选择哪个已奖励 金币袋
FilePath: /SlotNirvana/src/manager/System/LuckyChooseManager.lua
--]]
local LuckyChooseManager = class("LuckyChooseManager")
local LuckyChooseConfig = util_require("views.sale.LuckyChooseConfig")

LuckyChooseManager.m_instance = nil
function LuckyChooseManager:getInstance()
    if LuckyChooseManager.m_instance == nil then
        LuckyChooseManager.m_instance = LuckyChooseManager.new()
    end
    return LuckyChooseManager.m_instance
end

-- 构造函数
function LuckyChooseManager:ctor()
    self.m_maxRewardCoinsPrice = 0 -- 常规促销小游戏 奖励的金币价值
    self.m_openBagIdx = 0 -- 打开的那个 袋子
end

-- 常规促销小游戏 奖励的金币价值 set get
function LuckyChooseManager:setMaxRewardCoinsPrice(_price)
    _price = _price or 0
    self.m_maxRewardCoinsPrice = _price
end
function LuckyChooseManager:getMaxRewardCoinsPrice()
    return tonumber(self.m_maxRewardCoinsPrice)
end

-- 打开的那个 袋子 set get
function LuckyChooseManager:setOpenBagIdx(_openIdx)
    _openIdx = _openIdx or 0
    self.m_openBagIdx = _openIdx
end
function LuckyChooseManager:getOpenBagIdx()
    return self.m_openBagIdx
end

-- 请求领取奖励 自动领取未领取奖励
function LuckyChooseManager:sendGainRewardReq(_openIdx)
    gLobalViewManager:addLoadingAnima(false, 3)

    local successCallFunc = function(_, resultData)
        print("cxc--sendGainRewardReq--success")
        gLobalViewManager:removeLoadingAnima()

        if not resultData:HasField("result") then
            gLobalNoticManager:postNotification(LuckyChooseConfig.EVENT_NAME.NOTIFY_COLLECT_CLOSE_UI)
            return            
        end

        local resultStr = resultData.result
        local resultObj = cjson.decode(resultStr)
        local rewards = resultObj.rewards or {}
        if #rewards ~= LuckyChooseConfig.BAG_COUNT then
            gLobalNoticManager:postNotification(LuckyChooseConfig.EVENT_NAME.NOTIFY_COLLECT_CLOSE_UI)
            return
        end
        
        gLobalNoticManager:postNotification(LuckyChooseConfig.EVENT_NAME.NOTIFY_UPDATE_ITEM_STATE, rewards)
    end

    local failedCallFunc = function(target, errorCode, errorData)
        print("cxc--sendGainRewardReq--fail")
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect() -- 该界面都没有 返回操作，网络不行或者服务器报错都让重新登录
    end

    self:setOpenBagIdx(_openIdx)
    gLobalSendDataManager:getNetWorkFeature():sendSaleMiniGamesCollectReq(successCallFunc, failedCallFunc)
end

-- 常规促销 小游戏 面板
function LuckyChooseManager:popLuckyChooseLayer(_callFunc)
    local maxRewardCoinsPrice = self:getMaxRewardCoinsPrice()
    if maxRewardCoinsPrice <= 0 then
        if _callFunc then
            _callFunc()
        end
        return
    end
    
    local view = util_createView("views.sale.LuckyChooseLayer", _callFunc)
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_UI)
end

-- 常规促销 小游戏收集的金币 面板
function LuckyChooseManager:popCollectCoinLayer(_rewardInfo)
    local view = util_createView("views.sale.LuckyCollectCoinLayer", _rewardInfo)
    gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_UI)
end

-- 检查是否 处于常规促销 小游戏 面板中
function LuckyChooseManager:checkShowLuckyChooseLayer()
    local view = gLobalViewManager:getViewByExtendData("LuckyChooseLayer")
    if view then
        return true
    end

    return false
end

return LuckyChooseManager
