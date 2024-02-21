---
--xcyy
--2018年5月23日
--WildGorillaFreeSpinStart.lua
-- FIX IOS 139
local WildGorillaFreeSpinStart = class("WildGorillaFreeSpinStart", util_require("base.BaseView"))

function WildGorillaFreeSpinStart:initUI(_data)
    local name = _data.csbName
    self:createCsbNode(name)
    local num = _data.fsCounts
    local numLab = self:findChild("m_lb_num")
    numLab:setString(num)
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
function WildGorillaFreeSpinStart:setFunCall(_func, _startFunc)
    self.m_func = _func
    self.m_startFunc = _startFunc
end

function WildGorillaFreeSpinStart:onEnter()
end

function WildGorillaFreeSpinStart:onExit()
end

--待机ccb中配置暂时屏蔽
function WildGorillaFreeSpinStart:showidle()
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

function WildGorillaFreeSpinStart:playOver()
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
function WildGorillaFreeSpinStart:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return
        end
        self:playOver()
    end
end

return WildGorillaFreeSpinStart
