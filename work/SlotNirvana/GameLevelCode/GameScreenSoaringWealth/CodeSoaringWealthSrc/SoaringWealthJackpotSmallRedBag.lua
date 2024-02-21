---
--SoaringWealthJackpotSmallRedBag.lua

local SoaringWealthJackpotSmallRedBag = class("SoaringWealthJackpotSmallRedBag",util_require("Levels.BaseLevelDialog"))

SoaringWealthJackpotSmallRedBag.m_machine = nil
SoaringWealthJackpotSmallRedBag.m_jackpot_machine = nil
SoaringWealthJackpotSmallRedBag.m_curIndex = nil
SoaringWealthJackpotSmallRedBag.m_isClick = true
SoaringWealthJackpotSmallRedBag.m_callFuncClick = true

function SoaringWealthJackpotSmallRedBag:initUI(_m_machine, _jackpot_machine, _index)

    self:createCsbNode("SoaringWealth_JackpotBonus_hongbao.csb")
    
    self.m_machine = _m_machine
    self.m_jackpot_machine = _jackpot_machine
    self.m_curIndex = _index

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听
end

function SoaringWealthJackpotSmallRedBag:setSmallBagClick(_clickState)
    local clickState = _clickState
    self.m_isClick = clickState
end

function SoaringWealthJackpotSmallRedBag:onExit()
    SoaringWealthJackpotSmallRedBag.super.onExit(self)
end

--默认按钮监听回调
function SoaringWealthJackpotSmallRedBag:clickFunc(sender)
    local name = sender:getName()

    if name == "click" and self:isCanTouch() then
        print("当前点击第"..self.m_curIndex.."个奖励")
        self:playEndAni()
    end
end

function SoaringWealthJackpotSmallRedBag:playEndAni()
    self.m_isClick = false
    self:runCsbAction("fankui", false, function()
        self:setVisible(false)
    end)
    self.m_jackpot_machine:playEndAni(self.m_curIndex)
end

function SoaringWealthJackpotSmallRedBag:setClickState(_clickState)
    self.m_callFuncClick = _clickState
end

function SoaringWealthJackpotSmallRedBag:isCanTouch()
    return self.m_isClick and self.m_callFuncClick
end

return SoaringWealthJackpotSmallRedBag
