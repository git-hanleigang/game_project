local GoldenGhostBonusFreeSpinBar = class("GoldenGhostBonusFreeSpinBar", util_require("base.BaseView"))

local CodeGameScreenGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")

function GoldenGhostBonusFreeSpinBar:createCollectEffect( )
end

function GoldenGhostBonusFreeSpinBar:initUI(_csbName)
    self:createCsbNode(_csbName)
    
    self.lbCount = self:findChild("m_lb_num")
    self.lbCount:setString(0)
    self.lbTotalCount = self:findChild("m_lb_num_0")
    self.lbTotalCount:setString(0)

    self.labRespin_left = self:findChild("m_lb_num_1")
end

function GoldenGhostBonusFreeSpinBar:setCount(count,totalCount)
    local curTotalCount = tonumber(self.lbTotalCount:getString())
	if curTotalCount ~= 0 and curTotalCount ~= totalCount then
		self:runCsbAction("shouji",false)
	end
    if count then
        self.lbCount:setString(count)
        self.labRespin_left:setString(count)
    end
    if totalCount then
        self.lbTotalCount:setString(totalCount)
    end
end

function GoldenGhostBonusFreeSpinBar:playCollectEffect()
end

return GoldenGhostBonusFreeSpinBar