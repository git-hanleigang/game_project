-- 个人累充 网络消息处理

local AddPayNet = class("AddPayNet", util_require("baseActivity.BaseActivityManager"))

function AddPayNet:getInstance()
    if self.instance == nil then
        self.instance = AddPayNet.new()
    end
    return self.instance
end

-- 请求领奖
function AddPayNet:requestCollect()
    self:sendMsgBaseFunc(
        ActionType.SuperBowlRechargeCollect,
        "AddPay",
        nil,
        function(resData)
            if resData:HasField("result") then
                -- resData.result = "result: {"coins":315000000,"items":[{"activityId":"-1","buff":0,"description":"金色4星卡卡包","expireAt":0,"icon":"Rank_11","id":800005,"item":0,"itemInfo":{"createTime":1675042761000,"description":"","duration":-1,"icon":"/XX/XX.png","id":800005,"lastUpdateTime":1675042761000,"linkId":"100001:203500-100","name":"Golden Chips","subtitle":"+%s","type1":3,"type2":0},"mark":"1","num":1,"type":"Package"},{"activityId":"400001","buff":0,"description":"合成游戏经验包3","expireAt":1677571199000,"icon":"Major_Pouch","id":880405,"item":0,"itemInfo":{"createTime":1675042761000,"description":"","duration":-1,"icon":"/XX/XX.png","id":145,"lastUpdateTime":1675042761000,"linkId":"-1","name":"Major Pouch","subtitle":"+%s","type1":1,"type2":1},"mark":"2","num":5,"type":"Item"},{"activityId":"-1","buff":0,"description":"1天高倍场体验卡","expireAt":0,"icon":"club_pass_1","id":780001,"item":0,"itemInfo":{"createTime":1675042761000,"description":"","duration":-1,"icon":"/XX/XX.png","id":140,"lastUpdateTime":1675042761000,"linkId":"-1","name":"CLUB PASS CARD","subtitle":"-1","type1":1,"type2":1},"mark":"0","num":1440,"type":"Item"}],"success":true}"
                local buyResult = cjson.decode(resData.result)
                if buyResult and buyResult.success == true then
                    if resData and resData.activity and resData.activity.superBowlRecharge then
                        local act_data = G_GetMgr(ACTIVITY_REF.AddPay):getRunningData()
                        if act_data then
                            act_data:parseData(resData.activity.superBowlRecharge)
                        end
                    end

                    G_GetMgr(ACTIVITY_REF.AddPay):recordRewardsList(buyResult)
                end
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_ADDPAY_COLLECTED, {msg = true})
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_ADDPAY_COLLECTED, {msg = false})
        end
    )
end

return AddPayNet
