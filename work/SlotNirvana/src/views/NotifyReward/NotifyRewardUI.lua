local NotifyRewardUI = class("NotifyRewardUI", util_require("base.BaseView"))

--vip 等级描述
local kNotifyRewardUI_VIPDesMapInfo = {
    "BRONZE",
    "SILVER",
    "GOLD",
    "PLATINUM",
    "DIAMOND",
    "ROYAL DIAMOND",
    "BLACK DIAMOND"
}

-- 打开弹板类型
local OPEN_TYPE = {
    FB = 1, -- fb 奖励
    RETURN = 2, -- 用户回归 奖励
    CHURN = 3 -- 用户流失 奖励
}

function NotifyRewardUI:initUI(_rewardData, _callBack, _openType)
    self.m_rewardData = _rewardData
    self.m_callBack = _callBack
    self.m_openType = _openType or OPEN_TYPE.FB
    self:setBtnEnabled(true)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("NotifyReward/claims.csb", isAutoScale)

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
                if self.btnEnabled then
                    self:runCsbAction("idle", true)
                end
            end
        )
    else
        self:runCsbAction(
            "show",
            false,
            function()
                if self.btnEnabled then
                    self:runCsbAction("idle", true)
                end
            end
        )
    end
    self.lbVIPDes = self:findChild("lbVIPDes")
    self.lbPerCoin = self:findChild("lbPerCoin")
    self.lbVIPCoin = self:findChild("lbVIPCoin")
    self.lbTotalCoin = self:findChild("lbTotalCoin")
    self.vipBg = self:findChild("vipBg")
    -- self.vipIcon = self:findChild("vipIcon")
    self.totalCoinIcon = self:findChild("claims_coins_2")
    util_changeTexture(self.vipBg, VipConfig.vip_bg)
    self:updateUI()
end

function NotifyRewardUI:setBtnEnabled(flag)
    self.btnEnabled = flag
end

function NotifyRewardUI:updateUI()
    local rewardData = self.m_rewardData
    local perCoins = tonumber(rewardData.coins)
    local totalCoins = tonumber(rewardData.totalCoins)
    local vipMultiple = rewardData.vipMultiple
    local vipLevel = tonumber(globalData.userRunData.vipLevel)
    self.lbVIPDes:setString(string.format("HONORABLE VIP %s YOU GET", kNotifyRewardUI_VIPDesMapInfo[vipLevel]))
    self.lbPerCoin:setString(util_formatCoins(perCoins, 14))
    util_scaleCoinLabGameLayerFromBgWidth(self.lbPerCoin, 296)
    self.lbVIPCoin:setString(vipMultiple)
    -- util_changeTexture(self.vipIcon, string.format(VipConfig.logo_middle .. "%d.png", vipLevel))
    self.lbTotalCoin:setString(string.format("%s COINS", util_formatCoins(totalCoins, 11)))

    local sp_coin = self:findChild("claims_coins_2")
    local uiList = {}
    table.insert(uiList, {node = sp_coin})
    table.insert(uiList, {node = self.lbTotalCoin, alignX = 10})
    util_alignCenter(uiList)

    -- title
    self:updateTitleUIVisible()
end

-- 标题 显隐
function NotifyRewardUI:updateTitleUIVisible()
    local spFb = self:findChild("sp_fb")
    local spReturn = self:findChild("sp_return")
    local spChurn = self:findChild("sp_churn")
    spFb:setVisible(self.m_openType == OPEN_TYPE.FB)
    spReturn:setVisible(self.m_openType == OPEN_TYPE.RETURN)
    spChurn:setVisible(self.m_openType == OPEN_TYPE.CHURN)
end

function NotifyRewardUI:clickFunc(sender)
    if self.btnEnabled then
        local senderName = sender:getName()
        if senderName == "btn_ok" then
            -- local endPos = globalData.flyCoinsEndPos
            -- local startPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPosition()))
            -- local baseCoins = globalData.topUICoinCount

            -- gLobalViewManager:pubPlayFlyCoin(
            --     startPos,
            --     endPos,
            --     baseCoins,
            --     self.m_rewardData.totalCoins,
            --     function()
            --         if self.close then
            --             self:close()
            --         end
            --     end
            -- )
            self:setBtnEnabled(false)
            self:flyCoins()
        end
    end
end


--飞金币
function NotifyRewardUI:flyCoins()
    local _flyCoinsEndCall = function ()
        local cardSource = "Link Code"
        if CardSysManager:needDropCards(cardSource) == true then
            -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    if not tolua.isnull(self) then 
                        self:close()
                    end
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards(cardSource, nil)
        else
            if not tolua.isnull(self) then 
                self:close()
            end
        end
    end

    local rewardCoins = tonumber(self.m_rewardData.totalCoins or 0) or 0
    if rewardCoins and rewardCoins > 0 then
        local coinNode = self:findChild("btn_ok")
        local senderSize = coinNode:getContentSize()
        local startPos = coinNode:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                if _flyCoinsEndCall ~= nil then
                    _flyCoinsEndCall()
                end
            end
        )
    else
        if _flyCoinsEndCall ~= nil then
            _flyCoinsEndCall()
        end
    end
end


function NotifyRewardUI:onKeyBack()
    self:close()
end

function NotifyRewardUI:close()
    local function closeCallBack()
        if self.m_callBack ~= nil then
            self.m_callBack()
        end
        self:removeFromParent()
    end

    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                if closeCallBack then
                    closeCallBack()
                end
            end
        )
    else
        self:runCsbAction("over", false, closeCallBack)
    end
end

return NotifyRewardUI
