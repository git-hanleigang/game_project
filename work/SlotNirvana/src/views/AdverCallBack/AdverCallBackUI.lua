--[[
    author:JohnnyFred
    time:2019-10-30 15:54:41
]]
local AdverCallBackUI = class("AdverCallBackUI", util_require("base.BaseView"))

function AdverCallBackUI:initUI(callBack)
    self.callBack = callBack
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    local coins = tonumber(globalData.userRunData.loginUserData.userBack.coins)
    local coinsUsd = globalData.userRunData.loginUserData.userBack.coinsUsd
    self.btnLockFlag = false

    self:createCsbNode("Dialog/AdverCallBack.csb", isAutoScale)
    local lbCoins = self:findChild("lbCoins")
    lbCoins:setString(util_formatCoins(coins, 30))
    self:updateLabelSize({label = lbCoins}, 726)

    local lb_worth = self:findChild("lb_worth")
    lb_worth:setString("$" .. coinsUsd)

    gLobalSendDataManager:getLogFeature():sendADCallBackLog("Push", coins)
    self:commonShow(
        self:findChild("root"),
        function()
            if not self.btnLockFlag then
                self:runCsbAction("idle", true, nil, 60)
            end
        end
    )
end

function AdverCallBackUI:setBtnLockFlag(flag)
    self.btnLockFlag = flag
end

function AdverCallBackUI:onClickMask()
    local sender = self:findChild("btnEnjoy")
    self:onClickEnjoy(sender)
end

function AdverCallBackUI:onClickEnjoy(sender)
    if not sender then
        return false
    end

    if self.btnLockFlag then
        return
    end

    self:setBtnLockFlag(true)
    gLobalSendDataManager:getNetWorkFeature():sendActionUserBack(
        function(target, resData)
            local endPos = globalData.flyCoinsEndPos
            local startPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPosition()))
            local baseCoins = globalData.topUICoinCount
            local rewardCoins = globalData.userRunData.coinNum - baseCoins
            gLobalViewManager:pubPlayFlyCoin(
                startPos,
                endPos,
                baseCoins,
                rewardCoins,
                function()
                    -- local coins = tonumber(globalData.userRunData.loginUserData.userBack.coins)
                    -- gLobalSendDataManager:getLogFeature():sendADCallBackLog("Coins",coins)
                    self:close()
                end
            )
        end,
        function()
            gLobalViewManager:showReConnect()
            self:setBtnLockFlag(false)
        end
    )
end

function AdverCallBackUI:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btnEnjoy" then
        self:onClickEnjoy(sender)
    end
end

-- function AdverCallBackUI:onKeyBack()
--     self:close()
-- end

function AdverCallBackUI:close()
    self:setBtnLockFlag(true)
    self:commonHide(
        self:findChild("root"),
        function()
            if self.callBack ~= nil then
                self.callBack()
            end
            self:removeFromParent()
        end
    )
end

return AdverCallBackUI
