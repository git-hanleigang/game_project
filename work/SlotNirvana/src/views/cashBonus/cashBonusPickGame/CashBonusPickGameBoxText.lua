local CashBonusPickGameBoxText = class("CashBonusPickGameBoxText", util_require("base.BaseView"))

function CashBonusPickGameBoxText:initUI(data)
    self.m_data = data
    -- setDefaultTextureType("RGBA8888", nil)

    self:createCsbNode("NewCashBonus/CashBonusNew/CashPickGameBoxText.csb")
    -- setDefaultTextureType("RGBA4444", nil)
end

function CashBonusPickGameBoxText:initData(data, list)
    for i = 1, 2 do
        local uiList = {}
        local icon = self:findChild("icon" .. i)
        table.insert(uiList, {node = icon})
        local lbsCoins = self:findChild("lbs_coins" .. i)
        lbsCoins:setString(string.lower(util_formatCoins(tonumber(data.coins), 30)))
        table.insert(uiList, {node = lbsCoins, alignX = 5, alignY = 7})
        util_alignCenter(uiList)
        -- local cont = lbsCoins:getContentSize()
        -- icon:setPositionX(lbsCoins:getPositionX()-cont.width/2-40)
    end
    self.m_type = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultBoxType(self.m_data.index)
    if self.m_type == CASHBACK_BOX_TYPE.ALL_WIN_SELECTED or self.m_type == CASHBACK_BOX_TYPE.COIN_SELECTED then
        local temp = {}
        temp.startPos = self:getflyStartPos()
        temp.data = data
        list[#list + 1] = temp
    end
end

function CashBonusPickGameBoxText:playShowAnim()
    local animName
    if self.m_type == CASHBACK_BOX_TYPE.COIN_SELECTED then
        animName = "coinShow"
    elseif self.m_type == CASHBACK_BOX_TYPE.COIN_NOT_SELECTED then
        animName = "darkCoinShow"
    end
    self:runCsbAction(animName)
end

function CashBonusPickGameBoxText:getflyStartPos(type)
    local nodeEff1 = self:findChild("node_flypos")
    local endPos = nodeEff1:getParent():convertToWorldSpace(cc.p(nodeEff1:getPosition()))
    return endPos
end

return CashBonusPickGameBoxText
