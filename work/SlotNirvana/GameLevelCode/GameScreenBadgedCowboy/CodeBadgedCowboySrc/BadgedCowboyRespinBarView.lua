---
--xcyy
--BadgedCowboyRespinBarView.lua

local PublicConfig = require "BadgedCowboyPublicConfig"
local BadgedCowboyRespinBarView = class("BadgedCowboyRespinBarView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BadgedCowboyPublicConfig"

BadgedCowboyRespinBarView.m_respinCurrtTimes = 0

function BadgedCowboyRespinBarView:initUI()
    self:createCsbNode("BadgedCowboy_respinBar.csb")

    self:runCsbAction("idle", true)
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function BadgedCowboyRespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function()
            -- 显示 freespin count
            self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
        end,
        ViewEventType.SHOW_RESPIN_SPIN_NUM
    )
end

function BadgedCowboyRespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function BadgedCowboyRespinBarView:showRespinBar(curRespin, totalRespin)
    self:updateLeftCount(curRespin, totalRespin)
end

-- 更新 respin 次数
function BadgedCowboyRespinBarView:updateLeftCount(respinCount, totalRespinCount)
    self:findChild("Node_oneTime"):setVisible(false)
    self:findChild("Node_last"):setVisible(false)
    self:findChild("Node_otherTime"):setVisible(false)
    self:findChild("Node_text"):setVisible(true)
    self:findChild("left_num"):setString(respinCount)
    self:findChild("right_num"):setString(respinCount)
    if respinCount > 0 then
        if respinCount == 1 then
            self:findChild("Node_oneTime"):setVisible(true)
        else
            self:findChild("Node_otherTime"):setVisible(true)
        end
    else
        self:findChild("Node_text"):setVisible(false)
        self:findChild("Node_last"):setVisible(true)
    end
    if respinCount > 0 and respinCount == totalRespinCount then
        gLobalSoundManager:playSound(PublicConfig.Music_Repin_ResetTimes)
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    else
        self:runCsbAction("idle", true)
    end
end

return BadgedCowboyRespinBarView
