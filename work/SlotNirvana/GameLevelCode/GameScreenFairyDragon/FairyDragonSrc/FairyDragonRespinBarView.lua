
local FairyDragonRespinBarView = class("FairyDragonRespinBarView",util_require("base.BaseView"))
function FairyDragonRespinBarView:initUI()
    self:createCsbNode("FairyDragon_spin_cishu.csb")
end


function FairyDragonRespinBarView:onEnter()

end

function FairyDragonRespinBarView:onExit()
end


function FairyDragonRespinBarView:changeRespinCount()
    local leftFsCount = 5 - globalData.slotRunData.iReSpinCount+1
    local totalFsCount = 5
    self:updateRespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FairyDragonRespinBarView:updateRespinCount( curtimes,totaltimes )

    self:findChild("Num"):setString(curtimes.."/" ..totaltimes )
    
end


return FairyDragonRespinBarView