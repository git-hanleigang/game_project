---
--xcyy
--2018年5月23日
--AZTECFreeSpinBar.lua

local AZTECFreeSpinBar = class("AZTECFreeSpinBar",util_require("Levels.FreeSpinBar"))


function AZTECFreeSpinBar:initUI(data)
    local resourceFilename="AZTEC_FREESPIN.csb"
    self:createCsbNode(resourceFilename)
    -- self:runCsbAction("idleframe")
    -- self.m_csbOwner["m_lb_num"]:setString(0)
    -- self.m_csbOwner["m_lb_num"]:setPosition(0,20)
end

function AZTECFreeSpinBar:updateFreespinCount(leftCount,totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["m_lb_num"]:setString(leftCount)
    -- if leftCount<=9 then
    --     self.m_csbOwner["node_move"]:setPosition(0,0)
    -- elseif leftCount<=99 then
    --     self.m_csbOwner["node_move"]:setPosition(-6,0)
    -- else
    --     self.m_csbOwner["node_move"]:setPosition(-12,0)
    -- end
    self:runCsbAction("actionframe")
end


return AZTECFreeSpinBar