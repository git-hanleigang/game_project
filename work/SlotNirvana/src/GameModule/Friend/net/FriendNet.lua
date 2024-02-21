--浇花
local BaseNetModel = require("net.netModel.BaseNetModel")
local FriendNet = class("FriendNet", BaseNetModel)

function FriendNet:requestAllFriendList(extraData, sucFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if sucFunc then
            sucFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {
                facebookIds = extraData
            }
        }
    }
    self:sendActionMessage(ActionType.UserFriends, tbData, successFunc, failedFunc)
end

--获取推荐列表
function FriendNet:requestCommondList(successFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.FriendCommond, tbData, successFunc, failedFunc)
end

--搜索好友
function FriendNet:requestSerchList(content, successFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {
                content = content
            }
        }
    }
    self:sendActionMessage(ActionType.UserFriendSearch, tbData, successFunc, failedFunc)
end

--添加好友
function FriendNet:requestAddFriend(extraData, successFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {
                operateType = extraData.operateType,
                friendUdid = extraData.uid,
                source = extraData.source,
                facebookIds = extraData.fbids
            }
        }
    }
    self:sendActionMessage(ActionType.UserFriendOperate, tbData, successFunc, failedFunc)
end

-- 好友卡相关
function FriendNet:requestSendCard(extraData, successFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        dump(errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {
                position = extraData.position,
                dealId = extraData.dealId,
                mailType = extraData.mailType,
                friendUdid = extraData.friendUdid,
                cards = extraData.cards,
                dealIds = extraData.dealIds
            }
        }
    }
    self:sendActionMessage(ActionType.UserFriendSendCardMail, tbData, successFunc, failedFunc)
end

--获取添加列表
function FriendNet:requestAddFriendList(successFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc(errorCode, errorData)
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.UserFriendAddInfo, tbData, successFunc, failedFunc)
end

--要卡列表
function FriendNet:requestFriendCardList(successFunc, fileFunc)
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc(errorCode, errorData)
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    self:sendActionMessage(ActionType.UserFriendCardList, tbData, successFunc, failedFunc)
end

--向好友要卡
function FriendNet:requestApplyFriendCard(_cardId, successFunc, fileFunc)
    gLobalViewManager:addLoadingAnima()
    local failedFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc(errorCode, errorData)
        end
    end

    local successFunc = function(resJson)
        gLobalViewManager:removeLoadingAnima()
        if successFunc then
            successFunc(resJson)
        end
    end
    local tbData = {
        data = {
            params = {
                cardId = _cardId
            }
        }
    }
    self:sendActionMessage(ActionType.UserFriendApplyCard, tbData, successFunc, failedFunc)
end

return FriendNet
