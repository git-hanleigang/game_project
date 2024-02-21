--[[

]]
local TripleBingoWinnerView = class("TripleBingoWinnerView", util_require("base.BaseView"))

function TripleBingoWinnerView:initUI()
    
    self:resetData()
    self:createCsbNode("TripleBingo_winner.csb")
    self:initFeedbackAnim()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function TripleBingoWinnerView:resetData()
    self.m_curCoins = 0
end

function TripleBingoWinnerView:setWinnerBg(_bingoReelIndex)
    self:upDateWinnerViewCoins(_bingoReelIndex, 0)
    for _reelIndex=1,3 do
        local bVisible = _reelIndex == _bingoReelIndex
        local node = self:findChild( string.format("Node_bingo%d", _reelIndex) )
        node:setVisible(bVisible)
    end
end

--弹板出现
function TripleBingoWinnerView:playWinnerBarStartAnim(_bingoReelIndex, _fun)
    self:changeWinnerBarParticle(true)
    self:setWinnerBg(_bingoReelIndex)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        _fun()
    end)
end
--弹板收集反馈
function TripleBingoWinnerView:playWinCoinsAnim(_bingoReelIndex, _addCoins, _fun)
    local labCoins = self:getCoinsLabel(_bingoReelIndex)
    local curCoins = self.m_curCoins
    local targetCoins = curCoins + _addCoins
    local time = 0.3
    local coinRiseNum =  _addCoins / (time * 60)
    local sRandomCoinRiseNum   = string.gsub(tostring(coinRiseNum),"0",math.random(1, 3))
    coinRiseNum = math.ceil(tonumber(sRandomCoinRiseNum))  
    schedule(labCoins, function()
        curCoins = curCoins + coinRiseNum
        curCoins = LongNumber.min(targetCoins, curCoins)
        self:upDateWinnerViewCoins(_bingoReelIndex, curCoins)
        if toLongNumber(curCoins) >= toLongNumber(targetCoins) then
            labCoins:stopAllActions()
            _fun()
        end
    end,0.008)

    self:playFeedbackAnim(_bingoReelIndex)
end
--弹板消失
function TripleBingoWinnerView:playWinnerBarOverAnim(_fun)
    self:changeWinnerBarParticle(false)
    self:runCsbAction("over", false, _fun)
end

--[[
    粒子出现消失
]]
function TripleBingoWinnerView:changeWinnerBarParticle(_bPlay)
    local particleNode = self:findChild("Particle_1")
    if _bPlay then
        particleNode:setPositionType(0)
        particleNode:setDuration(-1)
        particleNode:resetSystem()
    else
        particleNode:stopSystem()
        util_setCascadeOpacityEnabledRescursion(particleNode, true)
        particleNode:runAction(cc.FadeOut:create(63/60))
    end
end

--[[
    金币文本
]]
function TripleBingoWinnerView:getCoinsLabel(_bingoReelIndex)
    return self:findChild( string.format("m_lb_coins%d", _bingoReelIndex) )
end
function TripleBingoWinnerView:upDateWinnerViewCoins(_bingoReelIndex, _coins)
    self.m_curCoins = _coins
    local labCoins = self:getCoinsLabel(_bingoReelIndex)
    local sCoins = ""
    if toLongNumber(self.m_curCoins) > toLongNumber(0) then 
        sCoins = util_formatCoins(self.m_curCoins, 30)
    end
    labCoins:setString(sCoins)
    self:updateLabelSize({label = labCoins, sx = 0.6, sy = 0.6}, 673)
end

--[[
    反馈效果
]]
function TripleBingoWinnerView:initFeedbackAnim()    
    self.m_feedbackAnimList = {}
end
function TripleBingoWinnerView:playFeedbackAnim(_bingoReelIndex)
    local feedbackAnim = nil
    local parent = self:findChild( string.format("Node_add%d", _bingoReelIndex) )
    --创建
    if #self.m_feedbackAnimList > 0 then
        feedbackAnim = table.remove(self.m_feedbackAnimList, 1)
        util_changeNodeParent(parent, feedbackAnim)
        feedbackAnim:setVisible(true)
    end
    if not feedbackAnim then
        feedbackAnim = util_createAnimation("TripleBingo_winner_add.csb")
        parent:addChild(feedbackAnim)
    end
    --
    feedbackAnim:runCsbAction("add", false, function()
        feedbackAnim:setVisible(false)
        table.insert(self.m_feedbackAnimList, feedbackAnim)
    end)
end



return TripleBingoWinnerView
