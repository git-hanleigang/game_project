-- local PublicConfig = require "CalacasParadePublicConfig"
local CalacasParadeFireworksCollectView = class("CalacasParadeFireworksCollectView", util_require("Levels.BaseLevelDialog"))


function CalacasParadeFireworksCollectView:initUI(_machine)
    self.m_machine = _machine

    self.m_curCoins    = 0
    self.m_targetCoins = 0

    self:createCsbNode("CalacasParade_yh_tanban.csb")
    self.m_lanCoins = self:findChild("m_lb_coins")
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CalacasParadeFireworksCollectView:initSpineUI()
    
end

function CalacasParadeFireworksCollectView:playStartAnim(_fun)
    self:setWinCoinsLab(0)
    self.m_targetCoins = 0

    self:setVisible(true)
    self:runCsbAction("start", false, _fun)
end

function CalacasParadeFireworksCollectView:getCollectEndNode()
    return self:findChild("Node_2")
end

function CalacasParadeFireworksCollectView:playCollectAnim(_addCoins, _fun)
    self:runCsbAction("shouji", false)
    self:jumpCoins(_addCoins, 18/60)
    self.m_machine:levelPerformWithDelay(self, 0.3, _fun)
end

function CalacasParadeFireworksCollectView:jumpCoins(_addCoins, _jumpTime)
    self.m_lanCoins:stopAllActions()

    local curCoins       = self.m_targetCoins
    local newTargetCoins = curCoins + _addCoins
    self.m_targetCoins   = newTargetCoins
    -- if self.m_targetCoins then
    --     self:setWinCoinsLab(self.m_targetCoins)
    --     return
    -- end
    -- 不要跳钱了
    local jumpTime       = _jumpTime
    local coinRiseNum =  _addCoins / (jumpTime * 60)
    local str         = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum       = tonumber(str)
    coinRiseNum       = math.ceil(coinRiseNum ) 

    self.m_updateAction = schedule(self.m_lanCoins, function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < newTargetCoins and curCoins or newTargetCoins
        self:setWinCoinsLab(curCoins)
        if curCoins >= newTargetCoins then
            self.m_lanCoins:stopAllActions()
        end
    end,0.008)
end

function CalacasParadeFireworksCollectView:setWinCoinsLab(_coins)
    self.m_curCoins = _coins
    local sCoins = _coins <= 0 and "" or util_formatCoins(_coins, 3)
    -- local sCoins = _coins <= 0 and "" or util_formatCoins(_coins, 50)
    self.m_lanCoins:setString(sCoins)
    self:updateLabelSize({label = self.m_lanCoins, sx=0.66, sy=0.66}, 262)
end

function CalacasParadeFireworksCollectView:playSwitchAnim()
    self:runCsbAction("switch", false)
end

return CalacasParadeFireworksCollectView