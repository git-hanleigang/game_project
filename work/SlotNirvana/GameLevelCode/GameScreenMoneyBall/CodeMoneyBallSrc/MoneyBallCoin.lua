---
--xcyy
--2018年5月23日
--MoneyBallCoin.lua

local MoneyBallCoin = class("MoneyBallCoin",util_require("base.BaseView"))

local MULTIP_ARRAY = {2, 3, 5, 8, 10, 15, 20, 50}
function MoneyBallCoin:initUI()

    self:createCsbNode("MoneyBall_Coin.csb")

    -- self:runCsbAction("idleframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self.m_labScore = self:findChild("m_lb_coins")
    self.m_labMultip = self:findChild("m_lb_multip")
    self.m_score = 0
end

function MoneyBallCoin:moveAnim()
    self:runCsbAction("actionframe")
end

function MoneyBallCoin:lastMoveAnim()
    self:runCsbAction("actionframe1")
    if self.m_iMultip ~= nil then
        self:updateMultip()
    end
end

function MoneyBallCoin:addAnim()
    self:runCsbAction("add", false, function()
    end)
end

function MoneyBallCoin:hideAnim(func)
    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end)
end

function MoneyBallCoin:idleAnim()
    self:runCsbAction("idleframe", true)
end

function MoneyBallCoin:setScore(score)
    self.m_score = self.m_score + score
    self.m_labMultip:setVisible(false)
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    lTatolBetNum = lTatolBetNum * 0.01
    local strScore = self.m_score * lTatolBetNum 
    self.m_labScore:setString(util_formatCoins(strScore, 3, false, false, true))

    local info = {label = self.m_labScore,sx = 1,sy = 1}
    self:updateLabelSize(info, 110)

    -- self.m_labScore:setString(self.m_score)
end

function MoneyBallCoin:setMultip(multip)
    self.m_iMultip = multip
    self.m_labScore:setVisible(false)
    self.m_changeTimes = 0
end

function MoneyBallCoin:showLastIdle(multip)
    self:runCsbAction("idle1")
    self.m_labScore:setVisible(false)
    self.m_labMultip:setString(multip.."X")
end

function MoneyBallCoin:showIdle()
    self:runCsbAction("idle")
end

function MoneyBallCoin:updateMultip()
    self.m_updateAction = schedule(self, function()
        local index = math.random(1, 8)
        local multip = MULTIP_ARRAY[index]
        if self.m_changeTimes == 13 then
            multip = self.m_iMultip
            self:stopAction(self.m_updateAction)
            self.m_updateAction = nil
            self.m_changeTimes = 0
            self.m_iMultip = nil
        end
        gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_multip_change.mp3")
        self.m_changeTimes = self.m_changeTimes + 1
        self.m_labMultip:setString(multip.."X")
    end, 0.2)
    
end

function MoneyBallCoin:onEnter()

end

function MoneyBallCoin:onExit()
 
end

return MoneyBallCoin