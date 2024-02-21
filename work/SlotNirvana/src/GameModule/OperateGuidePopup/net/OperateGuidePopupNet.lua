--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-07 11:27:20
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-07 11:27:40
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/net/OperateGuidePopupNet.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local NetWorkBase = require("network.NetWorkBase")
local OperateGuidePopupNet = class("OperateGuidePopupNet", NetWorkBase)

-- 向服务器保存 点位次数 信息
function OperateGuidePopupNet:sendSaveSiteCountInfoReq(_saveSiteCountList, _saveSiteCDList, _savePopupCDList)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function(target, resData)
    end

    local failedCallFun = function()
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local extraData = {}
    extraData[ExtraType.OperateGuidePopup] = _saveSiteCountList or {}
    extraData[ExtraType.OperateGuidePopupSiteCD] = _saveSiteCDList or {}
    extraData[ExtraType.OperateGuidePopupCD] = _savePopupCDList or {}
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

return OperateGuidePopupNet