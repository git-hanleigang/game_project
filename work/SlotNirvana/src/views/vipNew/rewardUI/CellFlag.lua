--[[-- 
    页签上的标记
]]
local CellFlag = class("CellFlag", BaseView)

function CellFlag:getCsbName()
    return "VipNew/csd/rewardUI/CellFlag.csb"
end

function CellFlag:initCsbNodes()
    self.m_spNew = self:findChild("sp_new")
    self.m_spBoosted = self:findChild("sp_boosted")
    self.m_spUpgraded = self:findChild("sp_upgraded")
end

function CellFlag:updateFlag(_flagType)
    self.m_spNew:setVisible(_flagType == "new")
    self.m_spBoosted:setVisible(_flagType == "boosted")
    self.m_spUpgraded:setVisible(_flagType == "upgraded")
end

return CellFlag
