---
--xcyy
--2018年5月23日
--SpacePupBonusStarItemBall.lua

local SpacePupBonusStarItemBall = class("SpacePupBonusStarItemBall",util_require("Levels.BaseLevelDialog"))

SpacePupBonusStarItemBall.m_curIndex = 0
SpacePupBonusStarItemBall.m_isClick = false

function SpacePupBonusStarItemBall:initUI(bonusView, _index)

    self:createCsbNode("SpacePup_pickstar.csb")

    self.m_curIndex = _index
    self.m_parent = bonusView

    self:runCsbAction("idleframe", true) -- 播放时间线

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:addClick(self:findChild("click_Panel"))
end

function SpacePupBonusStarItemBall:initViewAni()
    self:runCsbAction("idleframe", true)
end

function SpacePupBonusStarItemBall:onEnter()
    SpacePupBonusStarItemBall.super.onEnter(self)
end

function SpacePupBonusStarItemBall:onExit()
    SpacePupBonusStarItemBall.super.onExit(self)
end

function SpacePupBonusStarItemBall:refreshView(_onEnter, _starType)
    local onEnter = _onEnter
    local starType = _starType
    local endCallFunc = _endCallFunc

    if onEnter then
        if starType == "coins" then
            self:runCsbAction("idle", true)
        elseif starType == "pick" then
            self:runCsbAction("idle", true)
        end
    else
        self:runCsbAction("switch", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

function SpacePupBonusStarItemBall:playDarkAni()
    self:runCsbAction("yaan", false)
end

--默认按钮监听回调
function SpacePupBonusStarItemBall:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_Panel" and self:isCanTouch() and self.m_parent:isCanTouch() then
        self:setClickData(self.m_curIndex)
    end
end

function SpacePupBonusStarItemBall:setClickData(_index)
    self:setClickState(false)
    self.m_parent:sendData(_index)
end

function SpacePupBonusStarItemBall:setClickState(_state)
    self.m_isClick = _state
end

function SpacePupBonusStarItemBall:isCanTouch()
    return self.m_isClick
end

return SpacePupBonusStarItemBall
