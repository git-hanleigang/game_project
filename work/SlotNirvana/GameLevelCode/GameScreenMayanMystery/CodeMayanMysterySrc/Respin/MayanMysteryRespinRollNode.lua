---
--xcyy
--2018年5月23日
--MayanMysteryRespinRollNode.lua
local MayanMysteryRespinRollNode = class("MayanMysteryRespinRollNode",util_require("base.BaseView"))


function MayanMysteryRespinRollNode:initUI()
    self.m_RollNode = nil
    self.m_btrigger = false
    self.m_bStop = false
    self.m_bHead = false
    self:createCsbNode("MayanMystery_chengbeibaoshi.csb")
end

function MayanMysteryRespinRollNode:updateData(index)

    self:findChild("Node_X2"):setVisible(index == 2)
    self:findChild("Node_X3"):setVisible(index == 3)
    self:findChild("Node_X4"):setVisible(index == 4)
    self:findChild("Node_X5"):setVisible(index == 5)
end
  
function MayanMysteryRespinRollNode:startus()
    return self.m_bStop
end
  
function MayanMysteryRespinRollNode:stopRun( _b )
    self.m_bStop = true
end
  
function MayanMysteryRespinRollNode:playAction(key,loop,func,fps)
    self:runCsbAction(key,loop,func,fps)
end

return MayanMysteryRespinRollNode