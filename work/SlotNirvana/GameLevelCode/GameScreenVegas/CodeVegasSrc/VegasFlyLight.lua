---
--island
--2018年6月5日
--VegasFlyLight.lua

local VegasFlyLight = class("VegasFlyLight", util_require("base.BaseView"))

VegasFlyLight.m_ownerName = nil

---
-- index 是轮盘上面从左到右，从上到下， 1到n
--

function VegasFlyLight:initLight( index)
    local flip = 1
    local ccbName = nil
    self.vegasFlyType = 112 
    if index == 1 or index == 5 then
        ccbName = "Socre_Vegas_Feature_tw_1"
        self.vegasFlyType = 112
    elseif index == 2 or index == 4 then
        ccbName = "Socre_Vegas_Feature_tw_2"
        self.vegasFlyType = 113
    elseif index == 3 then
        ccbName = "Socre_Vegas_Feature_tw_3"
        self.vegasFlyType = 114
    elseif index == 6 or index == 10 then
        ccbName = "Socre_Vegas_Feature_tw_4"
        self.vegasFlyType = 115
    elseif index == 7 or index == 9 then
        ccbName = "Socre_Vegas_Feature_tw_5"
        self.vegasFlyType = 116
    elseif index == 8 then
        ccbName = "Socre_Vegas_Feature_tw_6"
        self.vegasFlyType = 117
    elseif index == 11 or index == 15 then
        ccbName = "Socre_Vegas_Feature_tw_7"
        self.vegasFlyType = 118
    elseif index == 12 or index == 14 then
        ccbName = "Socre_Vegas_Feature_tw_8"
        self.vegasFlyType = 119
    elseif index == 13 then
        ccbName = "Socre_Vegas_Feature_tw_9"
        self.vegasFlyType = 120
    end

    if index == 5 or index == 4 or index == 10 or index == 9 or index == 15 or index == 14 then
        flip = -1
    end

    self.m_ownerName = ccbName

    local resourceFilename= ccbName .. ".csb"
    self.m_Node =globalData.slotRunData.levelGetAnimNodeCallFun(self.vegasFlyType,resourceFilename)
    self:addChild(self.m_Node)
    self.m_Node:setScaleX(flip)
end

function VegasFlyLight:runAnimByName(animaName)
    self.m_Node:runAnim(animaName)
end

function VegasFlyLight:getVegasFlyType()
    return self.vegasFlyType
end

function VegasFlyLight:onEnter()
    
end

function VegasFlyLight:onExit(  )
    self.m_Node:removeFromParent()
    globalData.slotRunData.levelPushAnimNodeCallFun(self.m_Node, self.vegasFlyType)

end

function VegasFlyLight:runAnim(animName)
    self:runCsbAction(animName)

end

return VegasFlyLight