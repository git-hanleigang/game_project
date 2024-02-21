---
--xcyy
--2018年5月23日
--SpacePupBonusStarItemCoins.lua

local SpacePupBonusStarItemCoins = class("SpacePupBonusStarItemCoins",util_require("Levels.BaseLevelDialog"))

SpacePupBonusStarItemCoins.m_curIndex = 0
SpacePupBonusStarItemCoins.m_isClick = false

function SpacePupBonusStarItemCoins:initUI(bonusView, _index)

    self:createCsbNode("SpacePup_pickstar_coin.csb")

    self.m_curIndex = _index
    self.m_parent = bonusView

    self:runCsbAction("idleframe", true) -- 播放时间线

    self.m_coinsNode = self:findChild("Node_coins")
    self.m_pickNode = self:findChild("Node_pick")
    self.pickCoins_1 = self:findChild("m_lb_num")
    self.pickCoins_2 = self:findChild("m_lb_num_0")

    util_setCascadeOpacityEnabledRescursion(self, true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:addClick(self:findChild("click_Panel"))
end

function SpacePupBonusStarItemCoins:initViewAni()
    self:runCsbAction("idleframe", true)
end

function SpacePupBonusStarItemCoins:onEnter()
    SpacePupBonusStarItemCoins.super.onEnter(self)
end

function SpacePupBonusStarItemCoins:onExit()
    SpacePupBonusStarItemCoins.super.onExit(self)
end

function SpacePupBonusStarItemCoins:refreshView(_onEnter, _starType, _pickCoins, _curPickCount)
    local onEnter = _onEnter
    local starType = _starType
    local pickCoins = _pickCoins
    local curPickCount = _curPickCount
    
    self.pickCoins_1:setString(util_formatCoins(pickCoins,3))
    self.pickCoins_2:setString(util_formatCoins(pickCoins,3))

    if onEnter then
        if starType == "coins" then
            self:runCsbAction("idle", true)
            self.m_coinsNode:setVisible(true)
            self.m_pickNode:setVisible(false)
        elseif starType == "pick" then
            self:runCsbAction("idle", true)
            self.m_pickNode:setVisible(true)
            self.m_coinsNode:setVisible(false)
        end
    else
        if starType == "coins" then
            self:runCsbAction("idle", true)
            self.m_coinsNode:setVisible(true)
            self.m_pickNode:setVisible(false)
            performWithDelay(self.m_scWaitNode, function()
                self.m_parent:flyParticleToCoins(self.m_curIndex, pickCoins, curPickCount)
            end, 40/60)
        elseif starType == "pick" then
            self:runCsbAction("idle", true)
            self.m_pickNode:setVisible(true)
            self.m_coinsNode:setVisible(false)
        end
        
        self:runCsbAction("switch", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

function SpacePupBonusStarItemCoins:playDarkAni( _starType, _pickCoins)
    local starType = _starType
    local pickCoins = _pickCoins
    if starType == "coins" then
        self.m_coinsNode:setVisible(true)
        self.m_pickNode:setVisible(false)
        self.pickCoins_1:setString(util_formatCoins(pickCoins,3))
        self.pickCoins_2:setString(util_formatCoins(pickCoins,3))
    elseif starType == "pick" then
        self.m_pickNode:setVisible(true)
        self.m_coinsNode:setVisible(false)
    end
    self:runCsbAction("yaan", false)
end

--默认按钮监听回调
function SpacePupBonusStarItemCoins:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_Panel" and self:isCanTouch() and self.m_parent:isCanTouch() then
        self:setClickData(self.m_curIndex)
    end
end

function SpacePupBonusStarItemCoins:setClickData(_index)
    self:setClickState(false)
    self.m_parent:sendData(_index)
end

function SpacePupBonusStarItemCoins:setClickState(_state)
    self.m_isClick = _state
end

function SpacePupBonusStarItemCoins:isCanTouch()
    return self.m_isClick
end

return SpacePupBonusStarItemCoins
