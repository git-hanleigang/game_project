---
--xcyy
--2018年5月23日
--HogHustlerReelsJiaoBiao.lua

local HogHustlerReelsJiaoBiao = class("HogHustlerReelsJiaoBiao",util_require("Levels.BaseLevelDialog"))


function HogHustlerReelsJiaoBiao:initUI(coins)
    self:createCsbNode("HogHustler_jiaobiao.csb")
    if coins then
        self:findChild("h"):setVisible(coins == 901)
        self:findChild("o"):setVisible(coins == 902)
        self:findChild("g"):setVisible(coins == 903)
        self:findChild("h2"):setVisible(coins == 904)
        self:findChild("u"):setVisible(coins == 905)
        self:findChild("s"):setVisible(coins == 906)
        self:findChild("t"):setVisible(coins == 907)
        self:findChild("l"):setVisible(coins == 908)
        self:findChild("e"):setVisible(coins == 909)
        self:findChild("r"):setVisible(coins == 910)
    end
end

function HogHustlerReelsJiaoBiao:onEnter()
    HogHustlerReelsJiaoBiao.super.onEnter(self)
end

function HogHustlerReelsJiaoBiao:showAdd()
    
end

function HogHustlerReelsJiaoBiao:onExit()
    HogHustlerReelsJiaoBiao.super.onExit(self)
end

return HogHustlerReelsJiaoBiao