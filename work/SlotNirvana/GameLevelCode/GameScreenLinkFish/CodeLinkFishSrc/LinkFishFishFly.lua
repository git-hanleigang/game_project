---
--island
--2018年6月5日
--LinkFishFishFly.lua
-- 鱼飞行动画

local LinkFishFishFly = class("LinkFishFishFly", util_require("base.BaseView"))

LinkFishFishFly.m_ownerName = nil

---
-- index 是轮盘上面从左到右，从上到下， 1到n
--

function LinkFishFishFly:initFish( index)
    local flip = 1
    local ccbName = nil
    self.fishFlyType = 112 
    if index == 1 or index == 5 then
        ccbName = "Socre_LinkFish_Chip_Fly1"
        self.fishFlyType = 112
    elseif index == 2 or index == 4 then
        ccbName = "Socre_LinkFish_Chip_Fly2"
        self.fishFlyType = 113
    elseif index == 3 then
        ccbName = "Socre_LinkFish_Chip_Fly3"
        self.fishFlyType = 114
    elseif index == 6 or index == 10 then
        ccbName = "Socre_LinkFish_Chip_Fly4"
        self.fishFlyType = 115
    elseif index == 7 or index == 9 then
        ccbName = "Socre_LinkFish_Chip_Fly5"
        self.fishFlyType = 116
    elseif index == 8 then
        ccbName = "Socre_LinkFish_Chip_Fly6"
        self.fishFlyType = 117
    elseif index == 11 or index == 15 then
        ccbName = "Socre_LinkFish_Chip_Fly7"
        self.fishFlyType = 118
    elseif index == 12 or index == 14 then
        ccbName = "Socre_LinkFish_Chip_Fly8"
        self.fishFlyType = 119
    elseif index == 13 then
        ccbName = "Socre_LinkFish_Chip_Fly9"
        self.fishFlyType = 120
    end

    if index == 5 or index == 4 or index == 10 or index == 9 or index == 15 or index == 14 then
        flip = -1
    end

    self.m_ownerName = ccbName

    local resourceFilename= ccbName 
    self.m_Node =globalData.slotRunData.levelGetAnimNodeCallFun(self.fishFlyType,resourceFilename)
    self:addChild(self.m_Node)
    self.m_Node:setScaleX(flip)
end

function LinkFishFishFly:runAnimByName(animaName)
    self.m_Node:runAnim(animaName)
end

function LinkFishFishFly:getFishFlyType()
    return self.fishFlyType
end

function LinkFishFishFly:onEnter()

end

function LinkFishFishFly:onExit(  )
    self.m_Node:removeFromParent()
    globalData.slotRunData.levelPushAnimNodeCallFun(self.m_Node, self.fishFlyType)

end

function LinkFishFishFly:runAnim(animName)
    self:runCsbAction(animName)

end

return LinkFishFishFly