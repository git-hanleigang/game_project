---
--xcyy
--2018年5月23日
--ToroLocoFreespinBarView.lua
local ToroLocoPublicConfig = require "ToroLocoPublicConfig"
local ToroLocoFreespinBarView = class("ToroLocoFreespinBarView", util_require("base.BaseView"))

ToroLocoFreespinBarView.m_freespinCurrtTimes = 0

function ToroLocoFreespinBarView:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("ToroLoco_FreeSpinBar.csb")

    self.m_addEffect = util_createAnimation("ToroLoco_FreeSpinBar_add.csb")
    self:findChild("Node_add"):addChild(self.m_addEffect)
    self.m_addEffect:setVisible(false)
end

function ToroLocoFreespinBarView:onEnter()
    ToroLocoFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function ToroLocoFreespinBarView:onExit()
    ToroLocoFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function ToroLocoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ToroLocoFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num1"):setString(totaltimes)
    if curtimes > 99 then
        self:findChild("m_lb_num"):setScale(0.25)
    else
        self:findChild("m_lb_num"):setScale(0.4)
    end

    if totaltimes > 99 then
        self:findChild("m_lb_num1"):setScale(0.25)
    else
        self:findChild("m_lb_num1"):setScale(0.4)
    end
end

--[[
    播放增加free次数的效果
]]
function ToroLocoFreespinBarView:playAddNumsEffect(_func)
    if _func then
        gLobalSoundManager:playSound(ToroLocoPublicConfig.SoundConfig.sound_ToroLoco_freeNums_add)
    end

    self.m_addEffect:setVisible(true)
    local nodePos = util_convertToNodeSpace(self.m_addEffect, self.m_machine)
    util_changeNodeParent(self.m_machine, self.m_addEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_addEffect:setPosition(nodePos)
    self.m_addEffect:runCsbAction("actionframe", false, function()
        self.m_addEffect:setVisible(false)
        util_changeNodeParent(self:findChild("Node_add"), self.m_addEffect, 0)
        self.m_addEffect:setPosition(cc.p(0, 0))
    end)
    
    performWithDelay(self,function()
        if _func then
            _func()
        end
    end, 5/60)
end

return ToroLocoFreespinBarView
