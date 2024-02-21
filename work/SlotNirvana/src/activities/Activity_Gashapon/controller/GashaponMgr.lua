--[[
Author: ZKK
Date: 2022-04-19 12:28:18
--]]
local NetWorkBase = util_require("network.NetWorkBase")
local GashaponMgr = class("GashaponMgr", BaseActivityControl)
local ShopItem = util_require("data.baseDatas.ShopItem")

function GashaponMgr:ctor()
    GashaponMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Gashapon)
end

function GashaponMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    local uiView = util_createView("Activity.Activity_GashaponMainLayer", data)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

--打开获得积分
function GashaponMgr:showGainPointsLayer(callback)
    local data = self:getRunningData()
    if data then
        if data.m_gashaponPoint_add and data.m_gashaponPoint_add > 0 then
            local taskView = util_createView("Activity.Activity_GashaponTipLayer",callback)
            gLobalViewManager:showUI(taskView, ViewZorder.ZORDER_POPUI)
        else
            if callback then
                callback()
            end
        end
    else
        if callback then
            callback()
        end
    end   
end

function GashaponMgr:updateGashaponBigRewardCount()
    local data = self:getRunningData()    
    if data and data.m_gashaponBigReward  then
        local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
        local serverTM = util_UTC2TZ(nowTime, -8)
        local hour = serverTM.hour
        if hour == 24 then
            hour = 0
        end
        local allSeconds_Distance = serverTM.min * 60 + serverTM.sec
        for i,v in ipairs(data.m_gashaponBigReward) do
            local began_count = tonumber(v.phaseNumVec[hour + 1]) 
            local end_count  = tonumber(v.phaseNumVec[hour + 2])
            local distance = (began_count - end_count )/60/60
            local current =  math.ceil(began_count - distance * allSeconds_Distance)
            local lastLeftNum = tonumber(v.lastLeftNum)
            if lastLeftNum < current then
                v.currentNum = lastLeftNum
            else
                v.currentNum = current
            end
        end
    end
end
function GashaponMgr:getGashaponBigRewardCount()
    -- body
end

-- 扭蛋机抽奖
function GashaponMgr:sendActionPlayCapsuleToysRequest(type)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnimaDelay()

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if resData:HasField("result") then
            local result = cjson.decode(resData.result)
            if result then
                if result.items ~= nil then
                    local itemData = {}
                    for index, value in ipairs(result.items) do
                        local shopItem = ShopItem:create()
                        shopItem:parseData(value, true)
                        itemData[index] = shopItem
                    end
                    result.items = itemData
                end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GASHAPON_PLAY_END, {success = true, result = result})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GASHAPON_PLAY_END, {success = false})
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GASHAPON_PLAY_END, {success = false})
    end

     -- 组装数据发送
     local actionData = NetWorkBase:getSendActionData(ActionType.CapsuleToysPlay)
     local params = {}
     params.type = type - 1
     actionData.data.params = json.encode(params)
     NetWorkBase:sendMessageData(actionData, successCallFun, failedCallFun)
end




function GashaponMgr:setSuccessDoLuckySpin(success)
    self.successDoLuckySpin = success
end
function GashaponMgr:getSuccessDoLuckySpin()
    return self.successDoLuckySpin
end

function GashaponMgr:setTouchMachineBtn(isTouch)
    self.isTouch = isTouch
end
function GashaponMgr:getTouchMachineBtn()
    return self.isTouch
end

return GashaponMgr
