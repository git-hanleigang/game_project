--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-10 15:07:45
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local PokerRecallNet = class("PokerRecallNet", BaseNetModel)

function PokerRecallNet:printRequestFailedErrorMsg(_actionType, _errorMsg)
    local printStr = "------------ REQUEST SUCCESS ERROR : " .. _actionType .. " :" .. _errorMsg
    release_print(printStr)
    -- if _errorMsg == "activity not open" then
    --     local ui = gLobalViewManager:getViewByExtendData("RedecorMainUI")
    --     if ui ~= nil and ui.closeUI then
    --         ui:closeUI()
    --     end
    -- elseif _errorMsg == "node already build or not open" then
    --     local ui = gLobalViewManager:getViewByExtendData("RedecorMainUI")
    --     if ui ~= nil and ui.closeUI then
    --         ui:closeUI()
    --     end
    -- elseif _errorMsg == "material not enough" then
    --     local ui = gLobalViewManager:getViewByExtendData("RedecorMainUI")
    --     if ui ~= nil and ui.closeUI then
    --         ui:closeUI()
    --     end
    -- else
    --     assert(false, printStr)
    -- end
    assert(false, printStr)
end

function PokerRecallNet:requestPokerRecallPlay(_id, _idx, _isChange, _successCallFunc, _failedCallFunc)
    local successFunc = function(resData)
        local result = util_cjsonDecode(resData.result)
        release_print("-----------GetPlayRequestSuccess lose post---------")
        --assert(false, "丢包下报错")

        -- if result ~= nil and result ~= "" then
        --     if result["error"] ~= nil then
        --         self:printRequestFailedErrorMsg("PokerRecallPlay", result["error"])
        --         return
        --     end

        --     if _successCallFunc then
        --         _successCallFunc(result)
        --     end
        -- else
        --     if _failedCallFunc then
        --         _failedCallFunc()
        --     end
        -- end
        if _successCallFunc then
            _successCallFunc(result)
        end
    end

    local failedFunc = function(errorCode, errorData)
        release_print(errorCode, errorData)
        local logMsg = "errorCode:"..errorCode..",errorData:"..errorData
        util_sendToSplunkMsg("PokerRecallRequestPlayCardFailed", errorData)

        --self:printRequestFailedErrorMsg("PokerRecallPlay", errorData)
        if _failedCallFunc then
            _failedCallFunc()
        end
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    --翻牌的索引
    tbData.data.params.index = _id
    if _idx ~= nil then
        tbData.data.params.pos = _idx
    end

    local status = "PLAYING"

    if _isChange then
        status = "FIRST"
    end

    tbData.data.params.type = status
    self:sendActionMessage(ActionType.PokerRecallPlay, tbData, successFunc, failedFunc)
end

function PokerRecallNet:requestPokerRecallReward(_idx, _successCallFunc, _failedCallFunc)
    local successFunc = function(_data)
        if _successCallFunc then
            _successCallFunc(_data)
        end
    end

    local failedFunc = function()
        if _failedCallFunc then
            _failedCallFunc()
        end
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.index = _idx

    self:sendActionMessage(ActionType.PokerRecallReward, tbData, successFunc, failedFunc)
end

return PokerRecallNet
