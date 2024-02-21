
local BaseNetModel = require("net.netModel.BaseNetModel")
local CollectLevelNet = class("CollectLevelNet", BaseNetModel)

-- 初始化奖励信息
function CollectLevelNet:sendGetListReq(_successFunc, _faildFunc)
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
            }
        }
    }
    self:sendActionMessage(ActionType.CollectionLevelGet, reqData, successFunc, faildFunc)
end

-- 添加收藏
function CollectLevelNet:sendAddListReq(_successFunc, _faildFunc,_gameId)
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
                gameId = _gameId
            }
        }
    }
    self:sendActionMessage(ActionType.CollectionLevelSave, reqData, successFunc, faildFunc)
end

-- 移除收藏
function CollectLevelNet:sendRemoveListReq(_successFunc, _faildFunc,_gameId)
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
                gameId = _gameId
            }
        }
    }
    self:sendActionMessage(ActionType.CollectionLevelDelete, reqData, successFunc, faildFunc)
end


return CollectLevelNet
