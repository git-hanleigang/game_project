
local LuckySpinRewardLayer = class("LuckySpinRewardLayer", BaseLayer)

function LuckySpinRewardLayer:ctor(_data,_callback)
    LuckySpinRewardLayer.super.ctor(self)
    
    self.m_data = _data
    self.m_callBackFun = _callback
    self:setLandscapeCsbName("LuckySpinNew/LuckySpin_Reward.csb")
end

function LuckySpinRewardLayer:initCsbNodes()
    self.m_spcoin = self:findChild("sp_coin")
    self.m_lbcoin = self:findChild("lb_coin")
    self.m_btnCollect = self:findChild("btn_collect")
end

function LuckySpinRewardLayer:initView()
    local coins = tonumber(self.m_data.cc)
    self.m_coins = coins
    self.m_lbcoin:setString(util_formatCoins(coins, 13))
    local uiList = {
        {node = self.m_spcoin},
        {node = self.m_lbcoin, alignX = 5}
    }
    util_alignCenter(uiList)
end

function LuckySpinRewardLayer:onShowedCallFunc()
    LuckySpinRewardLayer.super.onShowedCallFunc(self)

    self:runCsbAction("idle", true)
end

function LuckySpinRewardLayer:flyCurrency()
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local startPos = self.m_btnCollect:getParent():convertToWorldSpace(cc.p(self.m_btnCollect:getPosition()))
        local flyList = {}
        if self.m_coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        end
        curMgr:playFlyCurrency(
            flyList,
            function()
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
        )
    end
end

function LuckySpinRewardLayer:closeUI()
    local callback = function()
        if self.m_callBackFun then
            self.m_callBackFun()
        end
    end
    LuckySpinRewardLayer.super.closeUI(self,callback)
end

function LuckySpinRewardLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_collect" then
        self:closeUI()
    end
end

return LuckySpinRewardLayer