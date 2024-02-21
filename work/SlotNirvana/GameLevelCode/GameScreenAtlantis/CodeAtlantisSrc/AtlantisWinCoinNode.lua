---
--xcyy
--2018年5月23日
--AtlantisWinCoinNode.lua

local AtlantisWinCoinNode = class("AtlantisWinCoinNode",util_require("base.BaseView"))


function AtlantisWinCoinNode:initUI()
    self:createCsbNode("FreeSpins_Atlantis.csb")

    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_callFuncs = {}
    self.m_lb_coins:setString(0)
end


function AtlantisWinCoinNode:onEnter()

end


function AtlantisWinCoinNode:onExit()
 
end

--[[
    显示界面
]]
function AtlantisWinCoinNode:showView()
    self.m_callFuncs = {}
    self:setVisible(true)
    self.m_lb_coins:setString(0)
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle")
    end)
end

--[[
    隐藏界面
]]
function AtlantisWinCoinNode:hideView()
    self:runCsbAction("over",false,function(  )
        self:setVisible(false)
    end)
end

--[[
    隐藏界面
]]
function AtlantisWinCoinNode:idleView()
    self:runCsbAction("idle")
    self.m_lb_coins:setString(0)
    self:setVisible(true)
end

--[[
    闪光特效
]]
function AtlantisWinCoinNode:lightAni()
    self:runCsbAction("actionframe",false,function(  )
        -- self:runCsbAction("idle")
    end)
end

--[[
    数字跳动
]]
function AtlantisWinCoinNode:jumpCoin(startNum,coinNum,soundType,func)
    local addValue = (coinNum - startNum) / (60 * 1)
    self.m_isJumping = true
    table.insert(self.m_callFuncs,1,func)

    if soundType == 1 then
        self.m_sound_id = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_jumpCoin1.mp3")
    else
        self.m_sound_id = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_jumpCoin2.mp3")
    end
    

    util_jumpNum(self.m_lb_coins,startNum,coinNum,addValue,1/60,{30},nil,nil,handler(nil, function (  )
        if self.m_sound_id then
            gLobalSoundManager:stopAudio(self.m_sound_id)
            self.m_sound_id = nil
        end
        self.m_isJumping = false
        self.m_lb_coins:setString(util_formatCoins(coinNum, 30))
        self:updateLabelSize({label=self.m_lb_coins,sx=0.45,sy=0.45},1037)
        local callFunc = self.m_callFuncs[1]
        if type(callFunc) == "function" then
            callFunc()
            self.m_callFuncs[1] = nil
        end
    end),function(  )
        self:updateLabelSize({label=self.m_lb_coins,sx=0.45,sy=0.45},1037)
    end)
end

--[[
    结束跳动
]]
function AtlantisWinCoinNode:endJump(coinNum)
    if self.m_isJumping then
        if self.m_sound_id then
            gLobalSoundManager:stopAudio(self.m_sound_id)
            self.m_sound_id = nil
        end
    end
    self.m_isJumping = false
    self.m_lb_coins:unscheduleUpdate()
    self.m_lb_coins:setString(util_formatCoins(coinNum, 30))
    self:updateLabelSize({label=self.m_lb_coins,sx=0.45,sy=0.45},1037)
    local callFunc = self.m_callFuncs[1]
    if type(callFunc) == "function" then
        callFunc()
        self.m_callFuncs[1] = nil
    end
end

--默认按钮监听回调
function AtlantisWinCoinNode:clickFunc()

end


return AtlantisWinCoinNode