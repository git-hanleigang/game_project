---
--xcyy
--2018年5月23日
--PandaDeluxeFreespinBarView.lua

local PandaDeluxeFreespinBarView = class("PandaDeluxeFreespinBarView",util_require("base.BaseView"))

PandaDeluxeFreespinBarView.m_freespinCurrtTimes = 0


function PandaDeluxeFreespinBarView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("PandaDeluxe_collect_0.csb")

    self:findChild("ShowTip"):setVisible(true)
    self:findChild("FsBar"):setVisible(false)

     
    if globalData.slotRunData.isDeluexeClub == true then
        self:updateBetEnable(false)
    end
    

    self:addClick(self:findChild("click"))
end


function PandaDeluxeFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    if globalData.slotRunData.isDeluexeClub ~= true then
        gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
            self:updateBetEnable(params)
        end,"BET_ENABLE")
    end

end

function PandaDeluxeFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PandaDeluxeFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PandaDeluxeFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
    
end

--默认按钮监听回调
function PandaDeluxeFreespinBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        return
    end

    if name == "click" then
        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalSoundManager:playSound("PandaDeluxeSounds/sound_PandaDeluxe_ChooseBet_Open.mp3")
        self.m_machine:showChooseBetLayer()

    end

end


function PandaDeluxeFreespinBarView:updateBetEnable(flag)
    if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
        flag=false
    end

    if globalData.slotRunData.isDeluexeClub == true then
        flag=false
    end

    local btn = self:findChild("Button_1")
    btn:setBright(flag)
    btn:setTouchEnabled(flag)

    self:findChild("click"):setVisible(flag)
end

return PandaDeluxeFreespinBarView