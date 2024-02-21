--[[
    回归用户
]]
local ReturnSignInManager = class("ReturnSignInManager")

function ReturnSignInManager:ctor()
    self.m_netModel = gLobalNetManager:getNet("Activity") -- 网络模块
end

function ReturnSignInManager:getInstance()
    if not self._instance then
        self._instance = ReturnSignInManager:create()
    end
    return self._instance
end

function ReturnSignInManager:setFreeSpinData()
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    self.m_oldSpinData = clone(freeSpinData:getRewardsByAction("ReturnSign"))
end

function ReturnSignInManager:getFreeSpinData()
    return self.m_oldSpinData or {}
end

function ReturnSignInManager:getOldSginData()
    return self.m_oldSginData
end

function ReturnSignInManager:isOpenLetter()
    return gLobalDataManager:getBoolByField("ReturnSignOpenLetter", false)
end

function ReturnSignInManager:openMainLayer(_openType)
    if not globalDynamicDLControl:checkDownloaded("Activity_ReturnSignIn") then
        return nil
    end

    local view = nil
    if _openType == "Letter" then
        release_print("---ReturnSignInManager:open Letter---")
        view = util_createView("Activity.Activity_ReturnSignInLetter")
        if view then
            gLobalDataManager:setBoolByField("ReturnSignOpenLetter", true)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    elseif _openType == "MainUI" then
        release_print("---ReturnSignInManager:open MainUI---")
        view = util_createView("Activity.Activity_ReturnSignIn")
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

function ReturnSignInManager:openPayGemsLayer(_index)
    if not globalDynamicDLControl:checkDownloaded("Activity_ReturnSignIn") then
        return nil
    end

    local view = util_createView("Activity.Activity_ReturnSignInPayGems", _index)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function ReturnSignInManager:openBoxLayer(_index)
    if not globalDynamicDLControl:checkDownloaded("Activity_ReturnSignIn") then
        return nil
    end

    local view = util_createView("Activity.Activity_ReturnSignInOpenBox", _index)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function ReturnSignInManager:openRewardLayer(_openType, _index)
    if not globalDynamicDLControl:checkDownloaded("Activity_ReturnSignIn") then
        return nil
    end

    local view = nil
    if _openType == "Reward" then
        view = util_createView("Activity.Activity_ReturnSignInGiftReward", _index)
    elseif _openType == "SpinItem" then
        view = util_createView("Activity.Activity_ReturnSignInSpinReward", _index)
    end
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function ReturnSignInManager:sendGetReward(_index, _gems)
    local tbData = {
        data = {
            params = {
                collectDay = _index
            }
        }
    }

    if _gems then
        tbData.data.params.gems = _gems
    end

    gLobalViewManager:addLoadingAnima(false, 1)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RETURN_SIGN_COLLECT_TAP, true)

    local successCallback = function(_result)
        if _result and _result.ChurnReturn then
            local data = globalData.userRunData:getUserChurnReturnInfo()
            self.m_oldSginData = clone(data)
            local churnReturn = _result.ChurnReturn
            globalData.userRunData:setUserChurnReturnInfo(churnReturn)
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RETURN_SIGN_COLLECT, _index)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    self.m_netModel:sendActionMessage(ActionType.ReturnSignCollect, tbData, successCallback, failedCallback)
end

return ReturnSignInManager
