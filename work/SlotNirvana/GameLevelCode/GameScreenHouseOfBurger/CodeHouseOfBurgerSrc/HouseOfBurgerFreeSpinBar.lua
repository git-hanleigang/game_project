
local HouseOfBurgerFreeGameBar = class("HouseOfBurgerFreeGameBar", util_require("base.BaseView"))
function HouseOfBurgerFreeGameBar:initUI(data)

    local resourceFilename = "HouseOfBurger_freespin_bar.csb"
    self:createCsbNode(resourceFilename)

    -- self:runCsbAction("start",false,function()
    --     self:runCsbAction("idle",true)
    -- end)
end
function HouseOfBurgerFreeGameBar:updateView(curNum,sumNum)
    local showNum = sumNum - curNum
    self:findChild("lbs_curNum"):setString(showNum)
    self:findChild("lbs_sumNum"):setString(sumNum)
end


function HouseOfBurgerFreeGameBar:onEnter()
end

function HouseOfBurgerFreeGameBar:onExit()

end



return HouseOfBurgerFreeGameBar
