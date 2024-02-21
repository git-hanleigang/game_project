--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-12 15:44:35
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-12 19:55:20
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/net/PiggyClickerGameNet.lua
Description: 快速点击小游戏 net
--]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local PiggyClickerGameNet = class("PiggyClickerGameNet", BaseNetModel)
local PiggyClickerGameConfig = util_require("GameModule.PiggyClicker.config.PiggyClickerGameConfig")

-- 开始游戏
function PiggyClickerGameNet:sendStartGameReq(_gameIdx)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            gLobalNoticManager:postNotification(PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_START_GAME_FAILD)
            return
        end
        gLobalNoticManager:postNotification(PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_START_GAME_SUCCESS, _gameIdx)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_START_GAME_FAILD)
    end
    local reqData = {
        data = {
            params = {
                index = _gameIdx
            }
        }
    }
    self:sendActionMessage(ActionType.PiggyClickerGenerate, reqData, successCallback, failedCallback)
end

-- 同步游戏数据 存档
function PiggyClickerGameNet:sendArchiveGameReq(_gameIdx, _saveDataStr)
    local reqData = {
        data = {
            params = {
                index = _gameIdx,
                saveData = _saveDataStr
            }
        }
    }
    self:sendActionMessage(ActionType.PiggyClickerSave, reqData)
end

-- 游戏结束 领奖
function PiggyClickerGameNet:sendGameCollectReq(_gameIdx, _verifyData)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            -- 失败
            return
        end
        gLobalNoticManager:postNotification(PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_COLLECT_GAME_SUCCESS, _result)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    local reqData = {
        data = {
            params = {
                index = _gameIdx,
                verifyData = _verifyData
            }
        }
    }
    self:sendActionMessage(ActionType.PiggyClickerCollect, reqData, successCallback, failedCallback)
end

--通知服务器游戏结束了
function PiggyClickerGameNet:sendGameClearReq(_gameIdx)
    local reqData = {
        data = {
            params = {
                index = _gameIdx,
            }
        }
    }
    self:sendActionMessage(ActionType.PiggyClickerClear, reqData)
end

-- 充值
function PiggyClickerGameNet:goPurchase(_gameData)
    if not _gameData then
        return 
    end
    
    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _gameData:getKeyId()
    goodsInfo.goodsPrice = tostring(_gameData:getPrice())
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)

    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_gameData)
    
    local idx = _gameData:getGameIdx() 
    self.m_curPayGameData = _gameData
    local localId = string.format("%s_%s", BUY_TYPE.PIGGY_CLICKER_PAY, idx)
    gLobalSaleManager:purchaseActivityGoods(localId, idx, BUY_TYPE.PIGGY_CLICKER_PAY, goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
end
function PiggyClickerGameNet:buySuccess()
    if self.m_curPayGameData then
        self.m_curPayGameData:clearArchiveData()
        self.m_curPayGameData = nil
    end
    gLobalViewManager:checkBuyTipList(function() 
        gLobalNoticManager:postNotification(PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_BUY_SUCCESS)
    end)
end
function PiggyClickerGameNet:buyFailed()
    print("PiggyClickerGameNet--buy--failed")
    self.m_curPayGameData = nil
end

function PiggyClickerGameNet:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "PiggyClicker"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "PiggyClicker"
    purchaseInfo.purchaseStatus = "PiggyClicker"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return PiggyClickerGameNet