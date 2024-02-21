---
--xcyy
--2018年5月23日
--TripletroveFreeSpinLabelView.lua

local TripletroveFreeSpinLabelView = class("TripletroveFreeSpinLabelView",util_require("Levels.BaseLevelDialog"))


function TripletroveFreeSpinLabelView:initUI(index)

    local file = self:changeLabelFile(index)
    self:createCsbNode(file)
    self.m_redWordList = {}

end

function TripletroveFreeSpinLabelView:changeLabelFile(index)
    if index == 1 then
        return "Tripletrove_lanzi.csb"
    elseif index == 2 then
        return "Tripletrove_jinzi.csb"
    elseif index == 3 then
        return "Tripletrove_hongzi.csb"
    end
end

function TripletroveFreeSpinLabelView:clearResWordList( )
    for i,v in ipairs(self.m_redWordList) do
        v:removeFromParent()
    end
    self.m_redWordList = {}
end

function TripletroveFreeSpinLabelView:initRedWordShow(index)
    self:clearResWordList()
    for i = 0,index do
        local fork = util_createAnimation("Tripletrove_hongzi_cha.csb")
        local pos = util_convertToNodeSpace(self:findChild("Socre_tripletrove_" .. i),self)
        self:addChild(fork)
        fork:setPosition(pos)
        fork:runCsbAction("idle")
        table.insert(self.m_redWordList,fork)
    end
end

function TripletroveFreeSpinLabelView:initBuleWordShow(num)
    self:findChild("m_lb_num"):setString(num)
    self:updateLabelSize({label=self:findChild("m_lb_num"),sx=0.35,sy=0.35},163)
end

function TripletroveFreeSpinLabelView:initGoldWordShow( )
    
end

return TripletroveFreeSpinLabelView