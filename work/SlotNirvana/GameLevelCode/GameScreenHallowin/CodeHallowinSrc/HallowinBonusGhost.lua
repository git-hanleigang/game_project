---
--xcyy
--2018年5月23日
--HallowinBonusGhost.lua

local HallowinBonusGhost = class("HallowinBonusGhost",util_require("base.BaseView"))


function HallowinBonusGhost:initUI(data)

    self:createCsbNode("Hallowin_xiaoyouling.csb")

    self:runCsbAction("idle", true) -- 播放时间线
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
    self:addClick(self:findChild("click"))
    self.m_clickFlag = true
    self.m_index = data
    self.m_particle = self:findChild("Particle_1")
    self.m_particle:stopSystem()
end

function HallowinBonusGhost:initCallFunc(func)
    self.m_clickCallFunc = func
end

function HallowinBonusGhost:onEnter()

end

function HallowinBonusGhost:onExit()

end

function HallowinBonusGhost:showParticle()
    self.m_particle:resetSystem()
end

function HallowinBonusGhost:getGhostID()
    self:setVisible(false)
    self:stopAllActions()
    return self.m_index
end

function HallowinBonusGhost:setCoins(num)
    self:findChild("m_lb_coins"):setString(util_formatCoins(num, 3, false ,false, true))
end

--默认按钮监听回调
function HallowinBonusGhost:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFlag ~= true then
        return
    end

    self.m_clickFlag = self.m_clickCallFunc(self.m_index)
end

return HallowinBonusGhost