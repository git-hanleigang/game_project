local BaseNetModel = require("net.netModel.BaseNetModel")
local InviteNet = class("InviteNet", BaseNetModel)

function InviteNet:getInstance()
    if self.instance == nil then
        self.instance = InviteNet.new()
    end
    return self.instance
end

function InviteNet:sendInviteDataReq(_successFunc,_failedCallback)
    gLobalViewManager:addLoadingAnima()
	local successCallback = function (_rewardList)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc(_rewardList)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failedCallback then
        	_failedCallback()
        end
    end

    local tbData = {
        data = {
            params = {
            }
        }
    }
    self:sendActionMessage(ActionType.InviteData, tbData, successCallback, failedCallback)
end
--分享领取奖励
function InviteNet:sendReciveReq(_successFunc,_failedCallback)
    gLobalViewManager:addLoadingAnima()
    local successCallback = function (_rewardList)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc(_rewardList)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failedCallback then
            _failedCallback()
        end
    end

    local tbData = {
        data = {
            params = {
            }
        }
    }
    self:sendActionMessage(ActionType.InviteShareCollect, tbData, successCallback, failedCallback)
end

--邀请关系同意
function InviteNet:sendInviteLinkReq(_successFunc,_failedCallback,_code)
    local successCallback = function (_data)
        if _successFunc then
            _successFunc(_data)
        end
    end

    local failedCallback = function (errorCode, errorData)
        if _failedCallback then
            _failedCallback()
        end
    end

    local tbData = {
        data = {
            params = {
                code = _code
            }
        }
    }
    self:sendActionMessage(ActionType.InviteLink, tbData, successCallback, failedCallback)
end

--被邀请领奖
function InviteNet:sendInviteeRew(_successFunc,_failedCallback,_level,_type)
    gLobalViewManager:addLoadingAnima()
    local successCallback = function (_data)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc(_data)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failedCallback then
            _failedCallback()
        end
    end

    local tbData = {
        data = {
            params = {
                level = _level,
                type = _type
            }
        }
    }
    self:sendActionMessage(ActionType.InviteePassCollect, tbData, successCallback, failedCallback)
end

--邀请领奖
function InviteNet:sendInviterRew(_successFunc,_failedCallback,_type,_value)
    gLobalViewManager:addLoadingAnima()
    local successCallback = function (_data)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc(_data)
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failedCallback then
            _failedCallback()
        end
    end

    local tbData = {
        data = {
            params = {
                type = _type,
                value = _value
            }
        }
    }
    self:sendActionMessage(ActionType.InviterCollect, tbData, successCallback, failedCallback)
end

return InviteNet
