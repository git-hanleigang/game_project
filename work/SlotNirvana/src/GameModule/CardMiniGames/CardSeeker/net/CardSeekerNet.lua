--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CardSeekerNet = class("CardSeekerNet", BaseNetModel)

function CardSeekerNet:requestOpenBox(_chapter, _pos, _success, _failed)
    release_print("CardSeekerNet:requestOpenBox _chapter="..(_chapter or "nil")..",_pos="..(_pos or "nil"))
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.pos = _pos
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.CardAdventurePlay, tbData, successFunc, failedFunc)
end

function CardSeekerNet:requestCollectReward(_chapter, _success, _failed)
    release_print("CardSeekerNet:requestCollectReward _chapter="..(_chapter or "nil"))
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.CardAdventureRewardData, tbData, successFunc, failedFunc)
end

function CardSeekerNet:requestCostGem(_type, _chapter, _success, _failed)
    release_print("CardSeekerNet:requestCostGem _chapter="..(_chapter or "nil")..",_type="..(_type or "nil"))
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.chapter = _chapter
    tbData.data.params.type = _type
    self:sendActionMessage(ActionType.CardAdventureGemConsume, tbData, successFunc, failedFunc)
end

function CardSeekerNet:requestGiveUp(_chapter, _success, _failed)
    release_print("CardSeekerNet:requestGiveUp _chapter="..(_chapter or "nil"))
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.chapter = _chapter
    self:sendActionMessage(ActionType.CardAdventureClearData, tbData, successFunc, failedFunc)
end


function CardSeekerNet:requestGiveUpAgain(_success, _failed)
    release_print("CardSeekerNet:requestGiveUpAgain")
    gLobalViewManager:addLoadingAnimaDelay()
    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        if _success then
            _success(resData)
        end
    end
    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.CardAdventureGiveUpAgain, tbData, successFunc, failedFunc)
end



return CardSeekerNet
