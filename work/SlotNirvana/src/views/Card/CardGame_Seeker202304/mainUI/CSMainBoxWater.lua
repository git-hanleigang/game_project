local CSMainBoxWater = class("CSMainBoxWater", BaseView)

function CSMainBoxWater:initDatas(_isShow)
    self.m_isShow = _isShow
end

function CSMainBoxWater:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_Box_shuibowen.csb"
end

function CSMainBoxWater:initUI()
    CSMainBoxWater.super.initUI(self)
    self:updateUI()
    self:runCsbAction("idle", true, nil, 60)
end

function CSMainBoxWater:updateUI()
    self:setVisible(self.m_isShow)
end

function CSMainBoxWater:setWaterShow(_isShow)
    self.m_isShow = _isShow
    self:updateUI()
end

return CSMainBoxWater
