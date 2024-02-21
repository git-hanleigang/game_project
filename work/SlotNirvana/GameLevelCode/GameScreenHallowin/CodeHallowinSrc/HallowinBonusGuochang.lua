---
--xcyy
--2018年5月23日
--HallowinBonusGuochang.lua

local HallowinBonusGuochang = class("HallowinBonusGuochang",util_require("base.BaseView"))


function HallowinBonusGuochang:initUI()

    self:createCsbNode("Hallowin_xiaoyouling_guochang.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
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
    local index = 1
    while true do
        local parent = self:findChild("Node_"..index)
        if parent ~= nil then
            local ghost = util_createAnimation("Hallowin_xiaoyouling.csb")
            parent:addChild(ghost)
            local delayTime = 0.1 * math.random(1, 10)
            performWithDelay(self, function()
                ghost:playAction("idle", true)
            end, delayTime)
        else
            break
        end
        index = index + 1
    end
    self.m_particle = self:findChild("Particle_1")
end

function HallowinBonusGuochang:showAnim(func)
    self:setVisible(true)
    self:findChild("Node_71"):setVisible(true)
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_ghost_guochang.mp3")
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
        self:findChild("Node_71"):setVisible(false)
        self.m_particle:stopSystem()
        performWithDelay(self, function()
            self:setVisible(false)
            self.m_particle:resetSystem()
        end, 2)
    end)
end

function HallowinBonusGuochang:onEnter()

end

function HallowinBonusGuochang:onExit()
 
end

return HallowinBonusGuochang