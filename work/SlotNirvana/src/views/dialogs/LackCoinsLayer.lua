--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-02 17:58:52
]]
local LackCoinsLayer = class("LackCoinsLaer", BaseLayer)

function LackCoinsLayer:initDatas()
    self:setLandscapeCsbName("Dialog/NewUserRewardLayer.csb")
    self:setKeyBackEnabled(false)
end

function LackCoinsLayer:initCsbNodes()
    self.m_icon = self:findChild("coin_dollar")
    self.m_lbReward = self:findChild("m_lb_reward")
    self.m_lbNotice = self:findChild("BitmapFontLabel_1_0_0")
    self.m_btnCollect = self:findChild("btn_collect")
end

function LackCoinsLayer:initView()
    self.m_lbNotice:setText("Enjoy some free coins to keep spinning!")
    local rewardCoins = tostring(globalData.constantData.CoinReparationNum)
    self.m_lbReward:setText(util_getFromatMoneyStr(rewardCoins))
    local uiList1 = {
        {node = self.m_icon},
        {node = self.m_lbReward, alignX = 5}
    }
    util_alignCenter(uiList1)
end

function LackCoinsLayer:onShowedCallFunc()
    self:setAutoCloseUI(
        3,
        nil,
        function()
            if not tolua.isnull(self) then
                self:onCollectCoins()
            end
        end
    )
end

function LackCoinsLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_collect" then
        self:onCollectCoins()
    end
end

function LackCoinsLayer:onCollectCoins()
    gLobalViewManager:addLoadingAnima(true)
    -- 飞金币起始位置
    local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
    local succCallFunc = function(jsonResult)
        local coins = jsonResult.coins or 0
        if coins > 0 then
            -- 飞金币
            G_GetMgr(G_REF.Currency):playFlyCurrency(
                {cuyType = FlyType.Coin, addValue = coins, startPos = startPos},
                function()
                    gLobalViewManager:removeLoadingAnima()
                    if not tolua.isnull(self) then
                        self:closeUI()
                    end
                end
            )
        else
            gLobalViewManager:removeLoadingAnima()
            util_sendToSplunkMsg("LackCoins", "collect coins <= 0!!!")
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end
    end

    local failedCallback = function()
        gLobalViewManager:removeLoadingAnima()
    end

    local requestInfo = {
        data = {
            params = {}
        }
    }
    G_GetNetModel(NetType.Common):sendActionMessage(ActionType.MinBetNoCoinsAward, requestInfo, succCallFunc, failedCallFunc)
end

return LackCoinsLayer
