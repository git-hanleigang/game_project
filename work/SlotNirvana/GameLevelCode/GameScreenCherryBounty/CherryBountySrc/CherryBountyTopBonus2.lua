--[[
    顶部金色樱桃
]]
local CherryBountyTopBonus2 = class("CherryBountyTopBonus2", cc.Node)

function CherryBountyTopBonus2:initData_(_machine)
    self.m_machine = _machine
    self.m_targetCoins = 0

    self:initUI()
end
function CherryBountyTopBonus2:initUI(_data)
    self.m_spine = util_spineCreate("Socre_CherryBounty_Bonus2_big", true, true)
    self:addChild(self.m_spine)
    util_spinePlay(self.m_spine, "idleframe", false)

    self.m_labCsb = self.m_machine:createSpineSymbolBindCsb(self.m_machine.SYMBOL_Bonus1)
    self.m_labCsb:findChild("bonus1"):setVisible(true)
    self.m_labCoins = self.m_labCsb:findChild("m_lb_coins_1")
    util_spinePushBindNode(self.m_spine, "shuzi", self.m_labCsb)
end
--时间线-出现
function CherryBountyTopBonus2:playTopBonusStart(_fun)
    self:setVisible(true)
    self.m_targetCoins = 0
    self.m_labCoins:setString("")
    local animName = "start"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine,  animName, function()
        -- util_spinePlay(self.m_spine, "idleframe", false)
        _fun()
    end)
end
--时间线-收集
function CherryBountyTopBonus2:playTopBonusCollectAnim(_addCoins)
    local labCoins   = self.m_labCoins
    local startCoins = self.m_targetCoins
    local endCoins   = startCoins + _addCoins
    self.m_targetCoins = endCoins
    local jumpTime   = 15/30
    local coinRise   =  _addCoins / (jumpTime * 60)  
    local fnOver     = function() end
    local fnUpDate   = function()
        local symbolType = self.m_machine.SYMBOL_Bonus1
        self.m_machine:upDateBonusCoinsLabelSize(self.m_labCoins, nil, symbolType, nil)
    end
    util_jumpNumExtra(
        labCoins,
        startCoins,
        endCoins,
        coinRise,
        1/60,
        util_formatCoinsLN,
        {4},
        nil, 
        nil,
        fnOver,
        fnUpDate
    )
    util_spinePlay(self.m_spine, "shouji2", false)
end
--时间线-收集结束
function CherryBountyTopBonus2:playCollectOverAnim(_fun)
    local animName = "actionframe3"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine,  animName, function()
        util_spinePlay(self.m_spine, "idleframe2", true)
        self.m_machine:levelPerformWithDelay(self, 0.3, _fun)
    end)
end

return CherryBountyTopBonus2