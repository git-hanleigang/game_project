
local BaseNetModel = require("net.netModel.BaseNetModel")
local UserInfoNet = class("UserInfoNet", BaseNetModel)

--旧请求
function UserInfoNet:sendNameHeadReq(_nickName,_mail,_extra,_sendOption,_isEmail,successCallFun,failedCallFunFail)
    local successCallFun = function(responseTable)
        if successCallFun then
            successCallFun()
        end
    end

    local failedCallFunFail = function(errorCode, errorData)
        release_print("saveNickNameFailed")
    end
    gLobalSendDataManager:getNetWorkFeature():sendNameEmailHead(_nickName,_mail,_extra,_sendOption,successCallFun,failedCallFunFail)
end

function UserInfoNet:sendActionEmailRewardReq()
    local _callFun = function(responseTable)
        release_print("sendActionEmailReward")
        local uiView = gLobalSysRewardManager:showView("EmailReward")
        gLobalViewManager:showUI(uiView,ViewZorder.ZORDER_UI)
    end

    local _callFunFail = function(errorCode, errorData)
        release_print("sendActionEmailReward fail")
    end
    gLobalSendDataManager:getNetWorkFeature():sendActionEmailReward(_callFun,_callFunFail)
end

function UserInfoNet:sendUserBagInfoReq()
    local successCallFun = function(items)
        items = items or {}
        G_GetMgr(G_REF.UserInfo):getData():paseBagItem(items)
    end

    local failedCallFunFail = function(errorCode, errorData)
        release_print("sendUserBagInfoReq fail")
    end
    gLobalSendDataManager:getNetWorkFeature():sendUserBagInfoReq(successCallFun,failedCallFunFail)
end

function UserInfoNet:sendInfomationReq(_uuid,_robot,_nickName,_frame,_callFun,_callFunFail,_type)
    if _type and _type == 1 then
    else
        gLobalViewManager:addLoadingAnima(false, 1)
    end
    local successFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()
        if _callFun then
            _callFun(protoResult)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _callFunFail then
            _callFunFail()
        end
    end

    local reqData = {
        data = {
            params = {
                udid = _uuid,
                robot = _robot,
                nickName = _nickName,
                frame = _frame
            }
        }
    }
    self:sendActionMessage(ActionType.AvatarFrameDetail, reqData, successFunc, faildFunc)
end

function UserInfoNet:sendFrameLikeReq(_like_list,_callFun,_callFunFail)
    gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(protoResult)
        gLobalViewManager:removeLoadingAnima()
        if _callFun then
            _callFun(protoResult)
        end
    end

    local faildFunc = function(_errorCode, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _callFunFail then
            _callFunFail()
        end
    end

    local reqData = {
        data = {
            params = {
                frames = _like_list
            }
        }
    }
    self:sendActionMessage(ActionType.AvatarFrameFavorite, reqData, successFunc, faildFunc)
end

return UserInfoNet