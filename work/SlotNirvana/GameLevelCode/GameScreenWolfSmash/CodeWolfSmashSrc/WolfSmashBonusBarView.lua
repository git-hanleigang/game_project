---
--xcyy
--2018年5月23日
--WolfSmashBonusBarView.lua

local WolfSmashBonusBarView = class("WolfSmashBonusBarView",util_require("Levels.BaseLevelDialog"))

WolfSmashBonusBarView.m_freespinCurrtTimes = 0


function WolfSmashBonusBarView:initUI()

    self:createCsbNode("WolfSmash_base_pigui.csb")
    self.pigList = {}

    self:chooseShow(1)
    --创建小猪，并隐藏
    self:createAllPigForBar()
end


function WolfSmashBonusBarView:onEnter()

    WolfSmashBonusBarView.super.onEnter(self)

    

end

function WolfSmashBonusBarView:onExit()

    WolfSmashBonusBarView.super.onExit(self)


end

function WolfSmashBonusBarView:createAllPigForBar()
    for i=1,5 do
        local pigItem = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
        pigItem:setSkin("red")
        pigItem.showIndex = i
        pigItem.isShow = false
        self:findChild("Node_"..i):addChild(pigItem)
        self.pigList[#self.pigList + 1] = pigItem
        -- pigItem:setVisible(false)
        util_spinePlay(pigItem, "kb",false)
    end
end

function WolfSmashBonusBarView:chooseShow(index)
    if index == 1 then
        self:findChild("NodeShow_1"):setVisible(true)
        self:findChild("NodeShow_2"):setVisible(false)
    else
        self:findChild("NodeShow_1"):setVisible(false)
        self:findChild("NodeShow_2"):setVisible(true)
    end
end

--num为bonus的数量
function WolfSmashBonusBarView:changeBonusByCount(num,multiple)
    if num <= 5 then
        local pigItem = self.pigList[num]
        if pigItem and not pigItem.isShow then
            -- pigItem:setVisible(true)
            if multiple == 10 then
                pigItem:setSkin("gold")
            else
                pigItem:setSkin("red")
            end
            util_spinePlay(pigItem, "start2",false)
            util_spineEndCallFunc(pigItem, "start2", function ()
                util_spinePlay(pigItem, "idleframe_idt",false)
            end)
            pigItem.isShow = true
        end
    else
        self:changeNumForBonus(num)
    end
    
end

function WolfSmashBonusBarView:resetPigShow()
    -- self:chooseShow(1)
    for i,v in ipairs(self.pigList) do
        local pigItem = self.pigList[i]
        if pigItem and pigItem.isShow then
            -- pigItem:setVisible(false)
            util_spinePlay(pigItem, "kb",false)
            pigItem.isShow = false
        end
    end
end

function WolfSmashBonusBarView:changeNumForBonus(num)
    self:findChild("m_lb_num"):setString("X"..num)
end

function WolfSmashBonusBarView:triggerFreeGameByBonus()
    self:runCsbAction("actionframe")
end



return WolfSmashBonusBarView