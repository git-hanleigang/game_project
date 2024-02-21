--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-14 17:10:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-15 14:14:38
FilePath: /SlotNirvana/src/GameModule/Sidekicks/net/SidekicksNet.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]

local ActionNetModel = util_require("net.netModel.ActionNetModel")
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksNet = class("SidekicksNet", ActionNetModel)

-- 每日轮盘
function SidekicksNet:sendWheelSpin()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_WHEEL_SPIN, {success = true, data = _result})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_WHEEL_SPIN, {success = false})
    end

    self:sendActionMessage(ActionType.SidekicksDailyRewardCollect,tbData,successCallback,failedCallback)
end

-- 宠物重命名
function SidekicksNet:sendSyncPetName(_petId, _newName)
    local tbData = {
        data = {
            params = {
                petId = _petId,
                name = _newName
            }
        }
    }
    self:sendActionMessage(ActionType.SidekicksPetRename, tbData)
end

-- 喂宠物 升级
function SidekicksNet:sendFeedPetReq(_petId, _count)
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        _result.petId = _petId
        gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTICE_FEED_PET_NET_CALL_BACK, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end

    local tbData = {
        data = {
            params = {
                petId = _petId,
                num = _count
            }
        }
    }
    self:sendActionMessage(ActionType.SidekicksLevelUp, tbData, successCallback, failedCallback)
end

-- 喂宠物 星级突破
function SidekicksNet:sendStarUpPetReq(_petId, _count)
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        _result.petId = _petId
        gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTICE_STAR_UP_PET_NET_CALL_BACK, _result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end

    local tbData = {
        data = {
            params = {
                petId = _petId,
                num = _count
            }
        }
    }
    self:sendActionMessage(ActionType.SidekicksStarUp, tbData, successCallback, failedCallback)
end

-- 荣誉促销购买
function SidekicksNet:buyHonorSale(_data)
    if not _data then
        gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HONOR_SALE)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = 0
    goodsInfo.goodsId = _data:getKeyId()
    goodsInfo.goodsPrice = _data:getPrice()
    goodsInfo.totalCoins = _data:getCoins()
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo,_data:getLevel())
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, _data:getItemList())
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseActivityGoods(
        "",
        _data:getLevel(),
        BUY_TYPE.SIDEKICKS_LEVEL_SALE,
        _data:getKeyId(),
        _data:getPrice(),
        0,
        0,
        function()
            gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HONOR_SALE, {success = true, data = _data})
        end,
        function()
            gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_HONOR_SALE)
        end
    )
end

function SidekicksNet:sendIapLog(_goodsInfo,_level)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "SidekicksHonorSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = _goodsInfo.discount
    goodsInfo.totalCoins = _goodsInfo.totalCoins
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "PetHonorSale"
    purchaseInfo.purchaseStatus = "PetHonorSale".._level
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

function SidekicksNet:syncGuideDataReq(_guideData)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.SidekicksGuideData] = _guideData:getSaveGuideData()
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

return SidekicksNet