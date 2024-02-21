local CashOrConkReward = class("CashOrConkReward",util_require("base.BaseView"))

local CashOrConkUserAction = require("CashOrConkUserAction")
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

function CashOrConkReward:initUI()
    self:createCsbNode("CashOrConk_jianglilan_classic.csb")

    self._spine_eff1 = util_spineCreate("CashOrConk_jianglilan",true,true)
    self._spine_eff1:hide()
    util_spinePlayAction(self._spine_eff1, "actionframe",true)
    self:findChild("Node_tx"):addChild(self._spine_eff1)

    local spine_eff = util_spineCreate("CashOrConk_jianglilan",true,true)
    util_spinePlayAction(spine_eff, "idleframe2",true,function()
    end)
    self:findChild("Node_tx"):addChild(spine_eff)
    self._curCoinCount = 0
    self:setCoinLabel(self._curCoinCount)
end

function CashOrConkReward:playStart(func)
    self:runCsbAction("start",false,function()
        self:plalIdle()
        if func then
            func()
        end
    end)
end

function CashOrConkReward:plalIdle()
    self:runCsbAction("actionframe_idle",true)
end

function CashOrConkReward:plalHideIdle()
    self:runCsbAction("idle_hide",true)
end

local hash_index_2_music = {
    CashOrConkPublicConfig.sound_CashOrConk_57,
    CashOrConkPublicConfig.sound_CashOrConk_34,
    CashOrConkPublicConfig.sound_CashOrConk_29,
}
local __index = 1
function CashOrConkReward:playAddCoins(addCoins)
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_50)
    if addCoins > 0 and math.random(1,10) >= 7 then
        gLobalSoundManager:playSound(hash_index_2_music[__index])
        __index = __index + 1
        if __index == 4 then
            __index = 1
        end
    end
    if self._userAction then
        if self._userAction.schedulerID then
            self._userAction:stop()
        end
        self._userAction = nil
    end
    
    self._curCoinCount = self._curCoinCount + addCoins
    local cv = self._curCoinCount - addCoins
    local av = addCoins
    local time = (38/30)*1000
    local userAction
    userAction = CashOrConkUserAction.new(self,time,function(per)
        if self and self.setCoinLabel then
            self:setCoinLabel(cv + per * av)
        end
    end)
    time = time + 20/60

    util_spinePlayAction(self._spine_eff1, addCoins >0 and "actionframe" or "actionframe_js",true)
    if addCoins > 0 then
        self._spine_eff1:hide()
        local spine_eff = util_spineCreate("CashOrConk_jianglilan",true,true)
        util_spinePlayAction(spine_eff, "actionframe_start",false,function()
            spine_eff:hide()
        end)
        self:findChild("Node_tx_1"):addChild(spine_eff)
        self:levelPerformWithDelay(self,38/30,function()
            self:runCsbAction("actionframe_over",false,function()
                self._spine_eff1:hide()
                self:plalIdle()
            end)
        end)
        self:levelPerformWithDelay(self,5/30,function()
            self._spine_eff1:show()
            userAction:run()
        end)
    else
        self._spine_eff1:show()
        self:runCsbAction("actionframe_start",false,function()
            self:runCsbAction("actionframe_js",false)
        end)
        self:levelPerformWithDelay(self,38/30,function()
            self:runCsbAction("actionframe_js_over",false,function()
                self:runCsbAction("actionframe_over",false,function()
                    self._spine_eff1:hide()
                    self:plalIdle()
                end)
            end)
        end)
        userAction:run()
    end

    self._userAction = userAction
    return time
end

function CashOrConkReward:setCoinCnt(coins)
    self._curCoinCount = coins
end

function CashOrConkReward:setCoinLabel(coins)
    self:findChild("m_lb_coins"):setVisible(coins ~= 0)
    local str=util_formatCoinsLN(coins,3,nil,nil,nil,true)
    self:findChild("m_lb_coins"):setString(str)
end

function CashOrConkReward:setCoinLabelAndCount(...)
    self:setCoinLabel(...)
    self:setCoinCnt(...)
end

function CashOrConkReward:levelPerformWithDelay(_parent, _time, _fun)
	if _time <= 0 then
		_fun()
		return
	end
	local waitNode = cc.Node:create()
	_parent:addChild(waitNode)
	performWithDelay(waitNode,function()
		_fun()
		waitNode:removeFromParent()
	end, _time)
	return waitNode
end

return CashOrConkReward