--[[
    免费弹板
]]
local PiggyFreeLayer = class("PiggyFreeLayer", BaseLayer)

function PiggyFreeLayer:initDatas(_closeFunc)
    self.m_closeFunc = _closeFunc
    self:setLandscapeCsbName("PigBank2022/csb/pop/PBFreeTanban.csb")
    self:setPauseSlotsEnabled(true)
    self:setHideActionEnabled(false)
end

function PiggyFreeLayer:initCsbNodes()
    self.m_spCoin = self:findChild("sp_coins")
    self.m_lbCoin = self:findChild("lb_coins")
end

function PiggyFreeLayer:initView()
    self:initCoins()
end

function PiggyFreeLayer:initCoins()
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    local coins = piggyBankData and piggyBankData.p_coins or 0
    local saleRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate()
    if saleRate and saleRate > 0 then
        self.m_lbCoin:setString(util_getFromatMoneyStr(coins + coins * saleRate / 100))
    else
        self.m_lbCoin:setString(util_getFromatMoneyStr(coins))
    end
    local UIList = {}
    local limitWidth = 700
    table.insert(UIList, {node = self.m_spCoin, anchor = cc.p(0.5, 0.5)})
    table.insert(UIList, {node = self.m_lbCoin, scale = 0.65, anchor = cc.p(0.5, 0.5), alignX = 3})
    util_alignCenter(UIList, nil, limitWidth)
end

function PiggyFreeLayer:playStart(_over)
    self:runCsbAction("start", false, _over, 60)
end

function PiggyFreeLayer:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function PiggyFreeLayer:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

function PiggyFreeLayer:playShowAction()
    PiggyFreeLayer.super.playShowAction(self, "start")
end

function PiggyFreeLayer:onShowedCallFunc()
    self:playIdle()
end

function PiggyFreeLayer:closeUI(_over)
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:playOver(
        function()
            PiggyFreeLayer.super.closeUI(self, _over)
        end
    )
end

function PiggyFreeLayer:onEnter()
    PiggyFreeLayer.super.onEnter(self)
end

function PiggyFreeLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI(
            function()
                if self.m_closeFunc then
                    self.m_closeFunc()
                end
            end
        )
    elseif name == "btn_break" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, nil, self.m_closeFunc)
            end
        )
    end
end

return PiggyFreeLayer
