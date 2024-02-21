

---
-- 处理Fb相关所有消息
--

local NetWorkFb = class("NetWorkFb",require "network.NetWorkBase")


function NetWorkFb:ctor( )
      
end


---
---
--faceBook登录
function NetWorkFb:sendActionFbConnect(totleCoin, rewardCoins)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.FacebookConnect)
    actionData.data.balanceCoinsNew = get_integer_string(totleCoin)
    actionData.data.balanceGems = 0


    actionData.data.exp = globalData.userRunData.currLevelExper
    actionData.data.version = self:getVersionNum()
    actionData.data.rewardCoins = rewardCoins
    actionData.data.rewardGems = 0

    local extraData = {}
    extraData[ExtraType.fbConnect] = {}
    extraData[ExtraType.fbConnect].facebookId = globalData.userRunData.fbUdid
    extraData[ExtraType.fbConnect].token =  globalData.userRunData.fbToken
    local bBindingFb = globalData.userRunData.isGetFbReward
    if bBindingFb == false then
        bBindingFb = 1
    end
    extraData[ExtraType.fbConnect].bindingFb = bBindingFb
    actionData.data.extra = cjson.encode(extraData)

    self:sendMessageData( actionData, self.sendFbConnectSuccess, self.sendFbConnectFailed)
end

  
---更新任务成功 
function NetWorkFb:sendFbConnectSuccess(redultData)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FB_BINING_REWARD,
    {true})
end

--更细任务失败、
function NetWorkFb:sendFbConnectFailed(errorCode , errorData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FB_BINING_REWARD,
    {false})
end

return NetWorkFb