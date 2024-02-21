--[[
    author:JohnnyFred
    time:2019-11-27 16:05:54
]]
local CollectGemsUI = class("CollectGemsUI", util_require("base.BaseView"))

function CollectGemsUI:initUI(bRotation)
    local isPortrait = globalData.slotRunData.isPortrait
    local csbName = "GameNode/GameTopGem1.csb"
    -- if not bHorizontalScreen then
    --     csbName = "GameNode/GameTopCoinPortrait.csb"
    -- end

    self:createCsbNode(csbName)

    self:setCsbNodeScale(globalData.topUIScale)
    self.m_isPortrait = isPortrait
    self.m_bRotation = bRotation
    if self.m_bRotation then
        self:findChild("mainNode"):setRotation(90)
    end
    self.m_spIcon = self:findChild("gemIcon")
    self.m_lbValue = self:findChild("lbgem")
end

function CollectGemsUI:initView()

end

function CollectGemsUI:updateUI(nValue)
    assert(nValue, "gems value is nil!!!")
    self.m_curValue = nValue

    self:updateValue(self.m_curValue)
end

-- function CollectGemsUI:getCoinIconPos()
--     local pos = self.m_spIcon:getParent():convertToWorldSpace(cc.p(self.m_spIcon:getPosition()))
--     return pos
-- end

function CollectGemsUI:refreshValue(addValue, addTime, callBack)
    local lbValue = self.m_lbValue
    local preValue = self.m_curValue
    local curValue = (addValue ~= nil) and (preValue + addValue) or globalData.userRunData.gemNum
    self.m_curValue = curValue
    local perAddValue = (curValue - preValue) / (addTime * 30)

    local function animCallBack()
        self:updateValue(curValue)
        performWithDelay(
            self,
            function()
                if callBack then
                    callBack()
                end
            end,
            0.5
        )
    end
    util_jumpNumExtra(
        lbValue,
        preValue,
        curValue,
        perAddValue,
        1 / 30,
        util_getFromatMoneyStr,
        {16},
        nil,
        nil,
        animCallBack,
        function()
            self:updateLable()
            self:setFinalValue()
        end
    )
end

function CollectGemsUI:updateValue(nValue)
    self.m_lbValue:setString(util_getFromatMoneyStr(nValue))
    self:updateLable()
end

function CollectGemsUI:updateLable()
    if self.m_isPortrait then
        self:updateLabelSize({label = self.m_lbValue, sx = 0.44, sy = 0.44}, 150)
    else
        self:updateLabelSize({label = self.m_lbValue, sx = 0.58, sy = 0.58}, 150)
    end
end

function CollectGemsUI:showAction()
    self:runCsbAction("idle", false)
end

function CollectGemsUI:setFinalValue()
    local mgr = G_GetMgr(G_REF.Currency)
    if mgr then
        mgr:setGems(self.m_curValue)
    end
end

return CollectGemsUI
