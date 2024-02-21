--浇花
local BaseNetModel = require("net.netModel.BaseNetModel")
local FlowerNet = class("FlowerNet", BaseNetModel)

-- 初始化奖励信息
function FlowerNet:sendInitRewardReq(_successFunc, _faildFunc,_type)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_data)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_data)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {
        data = {
            params = {
                type = _type
            }
        }
    }
    self:sendActionMessage(ActionType.FLowerInitReward, reqData, successFunc, faildFunc)
end

-- 初始化购买信息
function FlowerNet:sendInitPayReq(_successFunc, _faildFunc,_type)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_data)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_data)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        dump(_errorCode)
        gLobalViewManager:removeLoadingAnima()

        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {
        data = {
            params = {
                type = _type
            }
        }
    }
    self:sendActionMessage(ActionType.FlowerInitPayInfo, reqData, successFunc, faildFunc)
end

-- 浇花
function FlowerNet:sendWaterReq(_successFunc, _faildFunc,_type,_index)
    gLobalViewManager:addLoadingAnima(false,1)
    local successFunc = function(_data)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_data)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        dump(_errorCode)
        gLobalViewManager:removeLoadingAnima()
        G_GetMgr(G_REF.Flower):setWaterHide(true)
        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {
        data = {
            params = {
                type = _type,
                index = _index
            }
        }
    }
    self:sendActionMessage(ActionType.FlowerWaterFlower, reqData, successFunc, faildFunc)
end

-- 浇花引导
function FlowerNet:sendFlowerGuideReq(_successFunc, _faildFunc,_type)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_data)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_data)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        dump(_errorCode)
        gLobalViewManager:removeLoadingAnima()

        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {
        data = {
            params = {
                type = _type
            }
        }
    }
    self:sendActionMessage(ActionType.FlowerUpdateGuide, reqData, successFunc, faildFunc)
end
-- 浇花日
function FlowerNet:sendWaterTimeReq(_successFunc, _faildFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_data)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_data)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {}
    self:sendActionMessage(ActionType.FlowerStartWaterDay, reqData, successFunc, faildFunc)
end

function FlowerNet:sendFlowerCoinsReq(_successFunc, _faildFunc)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(_data)
        gLobalViewManager:removeLoadingAnima()

        if _successFunc then
            _successFunc(_data)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _faildFunc then
            _faildFunc()
        end
    end
    local reqData = {}
    self:sendActionMessage(ActionType.FlowerCollectCoins, reqData, successFunc, faildFunc)
end
return FlowerNet
