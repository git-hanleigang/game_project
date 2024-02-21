---
--xcyy
--2018年5月23日
--TreasureToadRespinBarView.lua

local TreasureToadRespinBarView = class("TreasureToadRespinBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

TreasureToadRespinBarView.m_freespinCurrtTimes = 0


function TreasureToadRespinBarView:initUI()

    self:createCsbNode("TreasureToad_RespinSpinBar.csb")
    self:findChild("Zi_0"):setVisible(false)
    self.totaltimes = 0
end

function TreasureToadRespinBarView:updateTotalTimes(totaltimes)
    self.totaltimes = totaltimes
    self:findChild("m_lb_num1"):setString(totaltimes)
    self:updateLabelSize({label=self:findChild("m_lb_num1"),sx=1,sy=1}, 47)
end

-- 更新并显示reSpin剩余次数
function TreasureToadRespinBarView:updateRespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:updateLabelSize({label=self:findChild("m_lb_num"),sx=1,sy=1}, 47)
end

function TreasureToadRespinBarView:updateRespinTotalCount(totaltimes,isInit)
    if self.totaltimes ~= totaltimes then
        if not isInit then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_respin_addNum)
            self:runCsbAction("actionframe")
        end
        self:delayCallBack(10/60,function ()
            self:updateTotalTimes(totaltimes)
        end)
    end
end

--[[
    延迟回调
]]
function TreasureToadRespinBarView:delayCallBack(time, func)
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

return TreasureToadRespinBarView