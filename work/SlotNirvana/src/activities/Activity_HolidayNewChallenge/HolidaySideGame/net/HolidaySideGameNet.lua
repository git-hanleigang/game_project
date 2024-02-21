--[[
   圣诞聚合 -- 小游戏
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local HolidaySideGameNet = class("HolidaySideGameNet", BaseNetModel)

function HolidaySideGameNet:requestStart(_success, _fail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success()
        end
    end
    local failedCallback = function (errorCode, errorData)
        if _fail then
            _fail()
        end        
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    local tbData = {data = {params = {}}}
    self:sendActionMessage(ActionType.HolidayNewChallengeSideGameEnterGame,tbData,successCallback,failedCallback)
end

function HolidaySideGameNet:requestPlay(_leafType, _success, _fail)
    -- 记录到本地
    local data = G_GetMgr(ACTIVITY_REF.HolidaySideGame):getRunningData()
    if not data then
        if _fail then
            _fail()
        end
        return
    end
    data:recodeLeafNum(_leafType, 1)
    if _success then
        _success()
    end

    -- gLobalViewManager:addLoadingAnima(false, 1)
    -- local successCallback = function (_result)
    --     gLobalViewManager:removeLoadingAnima()
    --     if _success then
    --         _success()
    --     end
    -- end
    -- local failedCallback = function (errorCode, errorData)
    --     gLobalViewManager:removeLoadingAnima()
    --     if _fail then
    --         _fail()
    --     end
    --     gLobalViewManager:showReConnect()
    -- end
    -- local tbData = {data = {params = {}}}
    -- tbData.data.params.type = _leafType
    -- self:sendActionMessage(ActionType.HolidayNewChallengeSideGamePlay,tbData,successCallback,failedCallback)
end

function HolidaySideGameNet:requestTime(_time)
    -- 记录到本地
    local data = G_GetMgr(ACTIVITY_REF.HolidaySideGame):getRunningData()
    if not data then
        if _fail then
            _fail()
        end
        return
    end
    data:recodeGameSec(_time)
    if _success then
        _success()
    end

    -- local successCallback = function (_result)
    -- end
    -- local failedCallback = function (errorCode, errorData)
    --     -- gLobalViewManager:showReConnect()
    -- end
    -- local tbData = {data = {params = {}}}
    -- tbData.data.params.seconds = _time
    -- self:sendActionMessage(ActionType.HolidayNewChallengeSideGameAddSeconds,tbData,successCallback,failedCallback)
end

function HolidaySideGameNet:requestCollect(_success, _fail)
    local data = G_GetMgr(ACTIVITY_REF.HolidaySideGame):getRunningData()
    if not data then
        if _fail then
            _fail()
        end
        return
    end
    local _curNormalNum = data:getRecordLeafNum(HolidaySideGameConfig.LeafType.Normal)
    local _curNormalNumOld = data:getCurNormalNumOld()
    local _curHighNum = data:getRecordLeafNum(HolidaySideGameConfig.LeafType.Golden)
    local _curHighNumOld = data:getCurHighNumOld()

    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        local data = G_GetMgr(ACTIVITY_REF.HolidaySideGame):getRunningData()
        if data then
            data:clearRecordData()
        end

        if _success then
            _success()
        end
    end
    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect(true)
    end
    local tbData = {data = {params = {}}}
    tbData.data.params.curNormalNum = _curNormalNum + _curNormalNumOld
    tbData.data.params.curHighNum = _curHighNum + _curHighNumOld
    self:sendActionMessage(ActionType.HolidayNewChallengeSideGameCollectReward,tbData,successCallback,failedCallback)
end

return HolidaySideGameNet