--[[
    time:2022-04-26 16:34:05
]]
local NetWorkBase = util_require("network.NetWorkBase")
local ShopItem = util_require("data.baseDatas.ShopItem")
local AdChallengeManager = class("AdChallengeManager", BaseActivityControl)

function AdChallengeManager:ctor()
    AdChallengeManager.super.ctor(self)
    self:setRefName("AdsChallenge")
    self:setResInApp(true)
end

function AdChallengeManager:showMainLayer(_overCallback)
    if not globalData.AdChallengeData or not globalData.AdChallengeData:isHasAdChallengeActivity() then
        if _overCallback then
            _overCallback()
        end
        return nil
    end
    local uiView = gLobalViewManager:getViewByExtendData("AdsChallengeMainLayer")
    if uiView then
        uiView:updetaView()
    else
        uiView = util_createView("views.Ad_Challenge.AdsChallengeMainLayer",_overCallback)
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

function AdChallengeManager:willDoComplete(cellCount)
    if cellCount then
        return   globalData.AdChallengeData.m_currentCompleteMap[cellCount] and  globalData.AdChallengeData.m_currentCompleteMap[cellCount] == 0
    end
    return globalData.AdChallengeData.m_doComplete
end

function AdChallengeManager:isDoAction() --是否要播动画
    local maxPoint = globalData.AdChallengeData.m_maxWatchCount
    local lastPoint =  globalData.AdChallengeData:getLastWatchCount()
    local curPoint = globalData.AdChallengeData:getCurrentWatchCount()
    if curPoint > maxPoint then
        return false
    end
    if curPoint ~= lastPoint then
        return true
    end
    return false
end

function AdChallengeManager:isShowMainLayer() --是否要弹出界面
    if self:willDoComplete() then
        return true
    end
    if self:isDoAction() then
        return true
    end
    return false
end

function AdChallengeManager:sendCollectReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }
    self.m_CompleteVec_beforeCollect = clone(globalData.AdChallengeData.m_currentCompleteVec)

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result and _result.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADSTASK_COLLECT_REWARDS, {success = false})
            return
        end
        
        if _result and _result.items then
            self:checkExtraActivtyData(_result)
        end
        self:sendFireBaseLog()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADSTASK_COLLECT_REWARDS, {success = true,result = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADSTASK_COLLECT_REWARDS, {success = false})
    end
    local netModel = gLobalNetManager:getNet("Activity")
    netModel:sendActionMessage(ActionType.AdIncentiveCollect,tbData,successCallback,failedCallback)
end

-- 档位详情
function AdChallengeManager:sendFireBaseLog()
    for i,v in ipairs(globalData.AdChallengeData.m_currentCompleteVec) do
        local before_v = self.m_CompleteVec_beforeCollect[i]
        if v > before_v then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.AD_Challenge_Finish ..i,false)
        end
    end
end

function AdChallengeManager:checkExtraActivtyData(_params)
    ------------- 检索合成福袋 zkk-------------
    local items = _params.items or {}
    local rewardItems =  {}
    for i, itemData in ipairs(items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(itemData, true)
        if globalData:isCardNovice() and shopItem.p_type == "Package" then
            -- 新手集卡期不显示 集卡 道具
        else
            table.insert(rewardItems, shopItem)
        end
    end
    _params.items = rewardItems
    local propsBagList = {}
    for _, data in ipairs(rewardItems) do
        if string.find(data.p_icon, "Pouch") then
            table.insert(propsBagList, data)
        end
    end
    if next(propsBagList) then
        _params.propsBagList = propsBagList
    end
    ------------- 检索合成福袋 zkk-------------
end
function AdChallengeManager:setAdsFreeSpin(isAds)
    self.m_isAdsFreeSpin = isAds 
end

function AdChallengeManager:isAdsFreeSpin()
    return not not self.m_isAdsFreeSpin
end

function AdChallengeManager:checkOpenLevel()
    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    --常量表开启等级
    local needLevel = globalData.constantData.ADCHALLABGE_OPENLEVEL or 20
    if needLevel > curLevel then
        return false
    end
    return true
end

return AdChallengeManager
