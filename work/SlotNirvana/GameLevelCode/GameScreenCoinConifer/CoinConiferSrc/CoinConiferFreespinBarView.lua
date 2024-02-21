---
--xcyy
--2018年5月23日
--CoinConiferFreespinBarView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConiferFreespinBarView = class("CoinConiferFreespinBarView", util_require("base.BaseView"))

CoinConiferFreespinBarView.m_freespinCurrtTimes = 0
CoinConiferFreespinBarView.m_freespinTotalTimes = 0

function CoinConiferFreespinBarView:initUI()
    self:createCsbNode("CoinConifer_freebar.csb")
    self.m_freespinTotalTimes = 0
    self.addNode = cc.Node:create()
    self:addChild(self.addNode)
end

function CoinConiferFreespinBarView:onEnter()
    CoinConiferFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function CoinConiferFreespinBarView:onExit()
    CoinConiferFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function CoinConiferFreespinBarView:initTotalCount(num)
    self.m_freespinTotalTimes = globalData.slotRunData.totalFreeSpinCount
    self:findChild("m_lb_num_1"):setString(globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount)
end

---
-- 更新freespin 剩余次数
--
function CoinConiferFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CoinConiferFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
end

function CoinConiferFreespinBarView:changeFreeSpinTotalCount()
    local totaltimes = globalData.slotRunData.totalFreeSpinCount
    self.addNode:stopAllActions()
    
    if totaltimes > self.m_freespinTotalTimes then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeNum_addFanKui)
        self:runCsbAction("actionframe")
        performWithDelay(self.addNode,function ()
            self:findChild("m_lb_num_2"):setString(totaltimes)
        end,10/60)
    else
        self:findChild("m_lb_num_2"):setString(totaltimes)
    end
end

return CoinConiferFreespinBarView
