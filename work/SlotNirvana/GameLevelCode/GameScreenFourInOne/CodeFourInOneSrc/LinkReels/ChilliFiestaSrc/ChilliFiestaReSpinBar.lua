---
--island
--2018年4月12日
--ChilliFiestaReSpinBar.lua
local ChilliFiestaReSpinBar = class("ChilliFiestaReSpinBar", util_require("base.BaseView"))
function ChilliFiestaReSpinBar:initUI(data)

    local resourceFilename = "LinkReels/ChilliFiestaLink/4in1_ChilliFiesta_Respin_bar.csb"
    self:createCsbNode(resourceFilename)
    -- self:runCsbAction("start",false,function()
    --     self:runCsbAction("idle",true)
    -- end)
end
function ChilliFiestaReSpinBar:updateView(curNum,sumNum)
    local showNum = sumNum - curNum
    self:findChild("lbs_curNum"):setString(showNum)
    self:findChild("lbs_sumNum"):setString(sumNum)
end



function ChilliFiestaReSpinBar:showView()
    self:setVisible(true)
end

function ChilliFiestaReSpinBar:hideView()
    self:setVisible(false)
end

function ChilliFiestaReSpinBar:onEnter()
end

function ChilliFiestaReSpinBar:onExit()

end



return ChilliFiestaReSpinBar
