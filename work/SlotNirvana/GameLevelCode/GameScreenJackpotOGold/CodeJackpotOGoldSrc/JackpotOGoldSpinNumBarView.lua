---
--xcyy
--2018年5月23日
--JackpotOGoldSpinNumBarView.lua

local JackpotOGoldSpinNumBarView = class("JackpotOGoldSpinNumBarView",util_require("Levels.BaseLevelDialog"))

function JackpotOGoldSpinNumBarView:initUI(machine)

    self.m_machine = machine
    self:createCsbNode("JackpotOGold_SpinNum.csb")

end

function JackpotOGoldSpinNumBarView:onEnter()

    JackpotOGoldSpinNumBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, "SHOW_SPIN_NUM")
    
end

function JackpotOGoldSpinNumBarView:onExit()

    JackpotOGoldSpinNumBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function JackpotOGoldSpinNumBarView:changeFreeSpinByCount()

    -- local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local leftFsCount = self.m_machine.m_curSpinNum
    if leftFsCount == 20 then
        leftFsCount = 1
    else
        leftFsCount = leftFsCount + 1
    end
    self:updateFreespinCount(leftFsCount)

end

-- 更新并显示FreeSpin剩余次数
function JackpotOGoldSpinNumBarView:updateFreespinCount( curtimes )
    if curtimes >= 18 and curtimes <= 19 then
        self:runCsbAction("idle2",true)
    else
        if curtimes ~= 20 then
            self:runCsbAction("idle",true)
        end
    end
    self:findChild("m_lb_num"):setString(curtimes)
    
end


return JackpotOGoldSpinNumBarView