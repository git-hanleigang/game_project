---
--xcyy
--2018年5月23日
--BeatlesFreespinBarView.lua

local BeatlesFreespinBarView = class("BeatlesFreespinBarView",util_require("base.BaseView"))

BeatlesFreespinBarView.m_freespinCurrtTimes = 0


function BeatlesFreespinBarView:initUI(machine)
    self.m_machine = machine
    self.dianshi = util_spineCreate("Beatles_dianshi", true, true)
    self.m_num_right = util_createAnimation("Beatles_Base_SpinBar_num.csb")
    self.m_num_lift = util_createAnimation("Beatles_Base_SpinBar_num.csb")
    -- self.m_line_right:setRotation(-90)
    util_spinePushBindNode(self.dianshi,"shuzi1",self.m_num_lift)
    util_spinePushBindNode(self.dianshi,"shuzi2",self.m_num_right)
    self.m_machine:findChild("dianshi_spine"):addChild(self.dianshi)

    util_spinePlay(self.dianshi, "idleframe", true)

end


function BeatlesFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function(self,params)  --设置灯光
        self:showSpinBarFankui(params)
    end,"SPINEBAR_NUM_BEATLES")
end

function BeatlesFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function BeatlesFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BeatlesFreespinBarView:updateFreespinCount( curtimes,totaltimes )

    util_spinePlay(self.dianshi, "switch_free", false)
    util_spineEndCallFunc(self.dianshi, "switch_free", function()
        util_spinePlay(self.dianshi, "idleframe2_free", true)
        self.m_num_lift:findChild("m_lb_num"):setString(totaltimes - curtimes)
        self.m_num_right:findChild("m_lb_num"):setString(totaltimes)
    end)
    
end

function BeatlesFreespinBarView:isChangeBase(isBase)
    if isBase then
        util_spinePlay(self.dianshi, "idleframe", true)
    else
        util_spinePlay(self.dianshi, "idleframe2_free", true)
        self.m_num_lift:findChild("m_lb_num"):setString(globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount)
        self.m_num_right:findChild("m_lb_num"):setString(globalData.slotRunData.totalFreeSpinCount)
    end
end

function BeatlesFreespinBarView:updateSpinNum(curtimes)
    self.m_num_lift:findChild("m_lb_num"):setString(curtimes)
    self.m_num_right:findChild("m_lb_num"):setString("10")
end

function BeatlesFreespinBarView:showSpinBarFankui(spin_num)
    if spin_num == 8 or spin_num == 9 then
        util_spinePlay(self.dianshi, "switch", false)
        util_spineEndCallFunc(self.dianshi, "switch", function()
            util_spinePlay(self.dianshi, "idleframe", true)
        end)
        return
    end
    local ani_str = spin_num == 10 and "idleframe2" or "idleframe"
    util_spinePlay(self.dianshi, ani_str, true)
end

return BeatlesFreespinBarView