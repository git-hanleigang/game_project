---
--xcyy
--2018年5月23日
--WildGorillaFreeSpinOver.lua
-- FIX IOS 139
local WildGorillaFreeSpinOver = class("WildGorillaFreeSpinOver", util_require("base.BaseView"))

function WildGorillaFreeSpinOver:initUI(_data)
    local name = "WildGorilla/FreeSpinOver.csb"
    self:createCsbNode(name)
    local num = _data.fsCounts
    local coinsNum = _data.coins
    local numLab = self:findChild("m_lb_num")
    local coinsLab = self:findChild("m_lb_coins")
    numLab:setString(num)
    coinsLab:setString(coinsNum)
    self.m_click = true
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false
            self:showidle()
        end
    )
end
--[[

    --@_func:播完over后的回调
	--@_startFunc: 点击start的回调    
]]
function WildGorillaFreeSpinOver:setFunCall(_func, _startFunc)
    self.m_func = _func
    self.m_startFunc = _startFunc
end

function WildGorillaFreeSpinOver:onEnter()
end

function WildGorillaFreeSpinOver:onExit()
end

--待机ccb中配置暂时屏蔽
function WildGorillaFreeSpinOver:showidle()
    --循环播放
    self:runCsbAction("idle", true)

    performWithDelay(
        self,
        function()
            self:playOver()
        end,
        110 / 30
    )
end
function WildGorillaFreeSpinOver:playOver()
    if self.m_click == true then
        return
    end
    self.m_click = true
    if self.m_startFunc then
        self.m_startFunc()
    end
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_func then
                self.m_func()
            end
            self:removeFromParent()
        end
    )
end
--默认按钮监听回调
function WildGorillaFreeSpinOver:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return
        end
        self:playOver()
    end
end

return WildGorillaFreeSpinOver
