---
--xcyy
--2018年5月23日
--WarriorAliceRespinBarView.lua
local PublicConfig = require "WarriorAlicePublicConfig"
local WarriorAliceRespinBarView = class("WarriorAliceRespinBarView",util_require("Levels.BaseLevelDialog"))


function WarriorAliceRespinBarView:initUI()

    self:createCsbNode("WarriorAlice_respin_bar.csb")

    self.m_curNum = 3
end


function WarriorAliceRespinBarView:onEnter()

    WarriorAliceRespinBarView.super.onEnter(self)

end

function WarriorAliceRespinBarView:onExit()
    WarriorAliceRespinBarView.super.onExit(self)

end

function WarriorAliceRespinBarView:setCurNum(num)
    self.m_curNum = num
end

-- 更新并显示ReSpin剩余次数
function WarriorAliceRespinBarView:updateRespinCount( curtimes,isInit)
    if curtimes == 3 and self.m_curNum ~= 3 then
        if not isInit then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_add_respin_count)
        end
        self:runCsbAction("actionframe")
        self:delayCallBack(15/60,function ()
            self:findChild("m_lb_num"):setString(curtimes)
        end)
    else
        self:findChild("m_lb_num"):setString(curtimes)
    end
    self.m_curNum = curtimes
end

--[[
    延迟回调
]]
function WarriorAliceRespinBarView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WarriorAliceRespinBarView