---
--island
--2018年4月12日
--PiggyLegendPirateSuperFreeStartView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PiggyLegendPirateSuperFreeStartView = class("PiggyLegendPirateSuperFreeStartView", util_require("Levels.BaseLevelDialog"))


function PiggyLegendPirateSuperFreeStartView:initUI(data)
    

    local resourceFilename = "PiggyLegendPirate/SuperFreeGameStart.csb"
    self:createCsbNode(resourceFilename)

    local respinOverEffect = util_createAnimation("PiggyLegendPirate/ReSpinOver_g.csb")
    self:findChild("ef_g"):addChild(respinOverEffect)
    respinOverEffect:runCsbAction("actionframe",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("ef_g"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("ef_g"), true)

    self.m_click = true
    self:showBeiShu(data.index)
    self:findChild("m_lb_num"):setString(data.num)
    self.m_callFun = data.func
    self:initViewData()
end

function PiggyLegendPirateSuperFreeStartView:initViewData()
    
    self:runCsbAction("start",false,function()
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

end

function PiggyLegendPirateSuperFreeStartView:showBeiShu(index)
    if index == 2 then
        self:showBeiShu2(1)
    elseif index == 7 then
        self:showBeiShu2(2)
    elseif index == 13 then
        self:showBeiShu2(3)
    elseif index == 20 then
        self:showBeiShu2(4)
    end
end

function PiggyLegendPirateSuperFreeStartView:showBeiShu2(index)
    local imgName = {"Node_wanfa1","Node_wanfa2","Node_wanfa3","Node_wanfa4"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end
end

function PiggyLegendPirateSuperFreeStartView:onEnter()

    PiggyLegendPirateSuperFreeStartView.super.onEnter(self)
end

function PiggyLegendPirateSuperFreeStartView:onExit()

    PiggyLegendPirateSuperFreeStartView.super.onExit(self)

end

function PiggyLegendPirateSuperFreeStartView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        self.m_click = true
        self:runCsbAction("over",false,function (  )
            if self.m_callFun then
                self.m_callFun()
            end
            performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
                self:removeFromParent()
            end,0.0)
        end)
    end
end


return PiggyLegendPirateSuperFreeStartView

