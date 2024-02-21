---
--xcyy
--2018年5月23日
--LoveShotTimeBarView.lua
--fixios0223
local LoveShotTimeBarView = class("LoveShotTimeBarView",util_require("base.BaseView"))

LoveShotTimeBarView.RESPIN = 1
LoveShotTimeBarView.FREESPIN = 2
LoveShotTimeBarView.PICKGAME = 3

function LoveShotTimeBarView:initUI(_states)

    self:createCsbNode("LoveShot_tishitiao.csb")

end

function LoveShotTimeBarView:setViewStates(_states )
    if _states == self.RESPIN then
        self:runCsbAction("respingame")
    elseif _states == self.FREESPIN then
        self:runCsbAction("freegame")
    elseif _states == self.PICKGAME then
        self:runCsbAction("pickgame")
    end
end

function LoveShotTimeBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function LoveShotTimeBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function LoveShotTimeBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function LoveShotTimeBarView:updateFreespinCount( _curtimes,_totaltimes )
    
    self:findChild("fs_left_num"):setString(_curtimes)
    self:findChild("fs_total_num"):setString(_totaltimes)
end

-- 更新并显示ReSpin剩余次数
function LoveShotTimeBarView:updateRespinCount( _curtimes,_totaltimes )
    
    
    self:findChild("rs_left_num"):setString(_totaltimes - _curtimes)
    self:findChild("rs_total_num"):setString(_totaltimes)
end

-- 更新并显示获得的 cashrush 个数
function LoveShotTimeBarView:updateCashRushNum( _num )

    
    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_zuanShi_num_Update.mp3")
    self:runCsbAction("pickgameollect")
    self:findChild("cashrush_num"):setString(_num)

end



return LoveShotTimeBarView