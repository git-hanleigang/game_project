---
--xcyy
--2018年5月23日
--ClassicRapid2JackPotBarView.lua

local ClassicRapid2JackPotBarView = class("ClassicRapid2JackPotBarView",util_require("base.BaseView"))

function ClassicRapid2JackPotBarView:initUI()

    self:createCsbNode("ClassicRapid2_jackpot.csb")

    -- self.m_JPbarSaoGuangView = util_createView("ClassicRapidSrc.ClassicRapidJPbarSaoGuangView")
    -- self:findChild("Node_saoguang"):addChild(self.m_JPbarSaoGuangView)
    -- self.m_JPbarSaoGuangView:runCsbAction("animation0",true)

end

function ClassicRapid2JackPotBarView:onExit()

end



function ClassicRapid2JackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ClassicRapid2JackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end



-- 更新jackpot 数值信息
--
function ClassicRapid2JackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner
    local widthList = {198,180,162,135,135}
    local scaleList = {1.07,1.11,1.21,1.31,1.35}

    for i=1,#widthList do
        local lbCoins = self:findChild("jackpot_coins"..i)
        local lbLockCoins = self:findChild("jackpot_coins"..i.."_0")
        self:updateSize(lbCoins,lbLockCoins,i,widthList[i],scaleList[i])
    end


end

function ClassicRapid2JackPotBarView:updateSize(lbs,lockLbs,index,width,scale)
    local value=self.m_machine:BaseMania_updateJackpotScore(index+5)

    lbs:setString(util_formatCoins(value,20))
    local info1={label=lbs,sx = scale,sy = scale}
    self:updateLabelSize(info1,width)

    if lockLbs then
        lockLbs:setString(util_formatCoins(value,20))
        local info2={label=lockLbs,sx = scale,sy = scale}
        self:updateLabelSize(info2,width)
    end

end


function ClassicRapid2JackPotBarView:updateLock( level )
    -- performWithDelay(self,function()
        if level == 4 then -- 最高档
            self:findChild("jackpot_coins1_0"):setVisible(false)
            self:findChild("jackpot_coins2_0"):setVisible(false)
            self:findChild("jackpot_coins3_0"):setVisible(false)
            self:findChild("jackpot_coins4_0"):setVisible(false)
            -- self:runCsbAction("jiesuo"..level,false,function()
            --     self:runCsbAction("animation0")
            -- end)
        elseif level == 3 then
            self:findChild("jackpot_coins1_0"):setVisible(true)
            self:findChild("jackpot_coins2_0"):setVisible(false)
            self:findChild("jackpot_coins3_0"):setVisible(false)
            self:findChild("jackpot_coins4_0"):setVisible(false)
            -- self:runCsbAction("jiesuo"..level,false,function()
            --     self:runCsbAction("animation0")
            -- end)
        elseif level == 2 then
            self:findChild("jackpot_coins1_0"):setVisible(true)
            self:findChild("jackpot_coins2_0"):setVisible(true)
            self:findChild("jackpot_coins3_0"):setVisible(false)
            self:findChild("jackpot_coins4_0"):setVisible(false)
            -- self:runCsbAction("jiesuo"..level,false,function()
            --     self:runCsbAction("animation0")
            -- end)
        elseif level == 1 then
            self:findChild("jackpot_coins1_0"):setVisible(true)
            self:findChild("jackpot_coins2_0"):setVisible(true)
            self:findChild("jackpot_coins3_0"):setVisible(true)
            self:findChild("jackpot_coins4_0"):setVisible(false)
            -- self:runCsbAction("jiesuo"..level,false,function()
            --     self:runCsbAction("animation0")
            -- end)
        elseif level == 0 then

            self:findChild("jackpot_coins1_0"):setVisible(true)
            self:findChild("jackpot_coins2_0"):setVisible(true)
            self:findChild("jackpot_coins3_0"):setVisible(true)
            self:findChild("jackpot_coins4_0"):setVisible(true)
        else
            self:findChild("jackpot_coins1_0"):setVisible(false)
            self:findChild("jackpot_coins2_0"):setVisible(false)
            self:findChild("jackpot_coins3_0"):setVisible(false)
            self:findChild("jackpot_coins4_0"):setVisible(false)

        end



    -- end,5/3)



end


function ClassicRapid2JackPotBarView:showjackPotAction(id)
    self:runCsbAction("animation"..id)
    gLobalSoundManager:playSound("ClassicRapid2Sounds/classRapid_jackpotWin2.mp3")

end

function ClassicRapid2JackPotBarView:clearAnim()
    self:runCsbAction("animation0")
end


return ClassicRapid2JackPotBarView