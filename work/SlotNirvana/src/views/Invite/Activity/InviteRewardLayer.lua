-- 分享奖励
local InviteRewardLayer = class("InviteRewardLayer", BaseView)

function InviteRewardLayer:initUI()
    local path = "Activity/rewards.csb"
    self:createCsbNode(path)
    self:setExtendData("InviteRewardLayer")
    local root = self:findChild("root")
    root:setTouchEnabled(false)
    self:commonShow(self:findChild("root"))
    self:initView()
end

function InviteRewardLayer:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    self.coin_number = self:findChild("lb_number")
    local coin = G_GetMgr(G_REF.Invite):getData():getShareCoin()
    self.coin_number:setString(util_getFromatMoneyStr(coin))
    self.m_flyCoins = G_GetMgr(G_REF.Invite):getData():getShareCoin()
    self.clickHide = true
end

function InviteRewardLayer:onKeyBack()
    self:closeUI()
end

function InviteRewardLayer:onClickMask()
    self:closeUI()
end

function InviteRewardLayer:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_collect" then
        self:closeUI()
    end
end

function InviteRewardLayer:closeUI()
    if not self.clickHide then
        return
    end
    self.clickHide = false
    local root = self:findChild("root")
    self:checkFlyCoins(
        function()
            self:commonHide(
                root,
                function()
                    gLobalNoticManager:postNotification(G_GetMgr(G_REF.Invite):getConfig().EVENT_NAME.INVITER_GUIDE)
                    self:removeFromParent()
                end
            )
        end
    )
end
--飞金币
function InviteRewardLayer:checkFlyCoins(func)
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_flyCoins, func)
end
return InviteRewardLayer
