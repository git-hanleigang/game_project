--[[
    装修网络层
    author: 徐袁
    time: 2021-09-09 11:28:23
]]
local BaseActivityManager = util_require("baseActivity.BaseActivityManager")
local RedecorNet = class(" RedecorNet", BaseActivityManager)

function RedecorNet:getInstance()
    if self.instance == nil then
        self.instance = RedecorNet.new()
    end
    return self.instance
end

function RedecorNet:printRequestSuccessErrorMsg(_actionType, _errorMsg)
    local printStr = "------------ REQUEST SUCCESS ERROR [MAQUN]: " .. _actionType .. " :" .. _errorMsg
    release_print(printStr)
    if _errorMsg == "activity not open" then
        local ui = gLobalViewManager:getViewByExtendData("RedecorMainUI")
        if ui ~= nil and ui.closeUI then
            ui:closeUI()
        end
    elseif _errorMsg == "node already build or not open" then
        local ui = gLobalViewManager:getViewByExtendData("RedecorMainUI")
        if ui ~= nil and ui.closeUI then
            ui:closeUI()
        end
    elseif _errorMsg == "material not enough" then
        local ui = gLobalViewManager:getViewByExtendData("RedecorMainUI")
        if ui ~= nil and ui.closeUI then
            ui:closeUI()
        end
    else
        assert(false, printStr)
    end
end

-- 更换风格请求
function RedecorNet:requestBuildNode(_nodeId, _success, _failed)
    local function successCallFun(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                self:printRequestSuccessErrorMsg("RedecorateBuild", result["error"])
                return
            end

            if _success then
                _success(result)
            end
        else
            if _failed then
                _failed()
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        release_print(errorCode)
        if _failed then
            _failed()
        end
    end
    local params = {}
    params.nodeId = _nodeId
    self:sendMsgBaseFunc(ActionType.RedecorateBuild, "redecor", params, successCallFun, failedCallFun)
end

function RedecorNet:requestSelectStyle(_nodeId, _style, _success, _fail)
    local function successCallFun(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                self:printRequestSuccessErrorMsg("RedecorateNodeStyle", result["error"])
                return
            end
            if _success then
                _success(result)
            end
        else
            if _fail then
                _fail()
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        release_print(errorCode)
        if _fail then
            _fail()
        end
    end
    local params = {}
    params.nodeId = _nodeId
    params.style = _style
    self:sendMsgBaseFunc(ActionType.RedecorateNodeStyle, "redecor", params, successCallFun, failedCallFun)
end

-- 请求:打开宝箱
function RedecorNet:requestOpenTreasure(_openType, _order, _success, _fail)
    local function successCallFun(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                self:printRequestSuccessErrorMsg("RedecorateOpenTreasure", result["error"])
                return
            end
            if _success then
                _success(result)
            end
        else
            if _fail then
                _fail()
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        release_print(errorCode)
        if _fail then
            _fail()
        end
    end
    local params = {}
    params.openType = _openType
    params.order = _order
    self:sendMsgBaseFunc(ActionType.RedecorateOpenTreasure, "redecor", params, successCallFun, failedCallFun)
end

-- 请求:丢弃宝箱
function RedecorNet:requestPassTreasure(_order, _success, _fail)
    local function successCallFun(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                self:printRequestSuccessErrorMsg("RedecoratePass", result["error"])
                return
            end
            if _success then
                _success(result)
            end
        else
            if _fail then
                _fail()
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        release_print(errorCode)
        if _fail then
            _fail()
        end
    end
    local params = {}
    params.order = _order
    self:sendMsgBaseFunc(ActionType.RedecoratePass, "redecor", params, successCallFun, failedCallFun)
end

-- 请求:打开fullview
function RedecorNet:requestOpenFullView(_success, _fail)
    local function successCallFun(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                self:printRequestSuccessErrorMsg("RedecorateFullView", result["error"])
                return
            end
            -- 数据缓存

            if _success then
                _success(result)
            end
        else
            if _fail then
                _fail()
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        release_print(errorCode)
        if _fail then
            _fail()
        end
    end
    local params = {}
    self:sendMsgBaseFunc(ActionType.RedecorateFullView, "redecor", params, successCallFun, failedCallFun)
end

-- 请求:fullview切换风格
function RedecorNet:requestFullViewSelectStyle(_activityName, _nodeId, _style, _success, _fail)
    local function successCallFun(resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil and result ~= "" then
            if result["error"] ~= nil then
                self:printRequestSuccessErrorMsg("RedecorateChangeStyle", result["error"])
                return
            end

            if _success then
                _success(result)
            end
        else
            if _fail then
                _fail()
            end
        end
    end

    local function failedCallFun(target, errorCode, errorData)
        release_print(errorCode)
        if _fail then
            _fail()
        end
    end
    local params = {}
    params.activityName = _activityName
    params.nodeId = _nodeId
    params.style = _style
    self:sendMsgBaseFunc(ActionType.RedecorateChangeStyle, "redecor", params, successCallFun, failedCallFun)
end

-- 发送获取排行榜消息
function RedecorNet:requestGetRank(loadingLayerFlag, successCallback, failedCallback)
    local function successCallFunc(target, resultData)
        if resultData.result ~= nil and resultData.result ~= "" then
            local rankData = cjson.decode(resultData.result)
            if rankData ~= nil then
                if successCallback then
                    successCallback(rankData)
                end
            else
                local str = "------------------ ERROR[MAQUN]: ActionType.RedecorateRank, resultData.result = " .. resultData.result
                -- assert(false, str)
                release_print(str)
            end
        end
        if loadingLayerFlag then
            gLobalViewManager:removeLoadingAnima()
        end
    end

    local function failedCallFun(target, code, errorMsg)
        if loadingLayerFlag then
            gLobalViewManager:removeLoadingAnima()
        end
        if failedCallback then
            failedCallback()
        end
    end
    if loadingLayerFlag then
        gLobalViewManager:addLoadingAnimaDelay()
    end
    local actionData = self:getSendActionData(ActionType.RedecorateRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFunc, failedCallFun)
end

return RedecorNet
