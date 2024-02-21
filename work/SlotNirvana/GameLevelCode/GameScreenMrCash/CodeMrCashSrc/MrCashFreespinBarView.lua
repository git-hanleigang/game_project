---
--xcyy
--2018年5月23日
--MrCashFreespinBarView.lua

local MrCashFreespinBarView = class("MrCashFreespinBarView",util_require("base.BaseView"))

MrCashFreespinBarView.m_freespinCurrtTimes = 0


function MrCashFreespinBarView:initUI()

    self:createCsbNode("MrCash_FS_cishu.csb")

    self.m_flashNode = util_createAnimation("MrCash_FS_cishu_shangbai.csb") 
    self:findChild("Node_shangbai"):addChild(self.m_flashNode)
    self.m_flashNode:setVisible(false)

end


function MrCashFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MrCashFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MrCashFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount 
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function MrCashFreespinBarView:playFsNumAnim(startValue,endValue,callBack)

    self.m_flashNode:setVisible(true)
    self.m_flashNode:runCsbAction("actionframe",true)

    local spendTime = 6/60
    local addValue = 1
    local label = self:findChild("m_lb_num")
    local currCall = function(  )
        self.m_flashNode:runCsbAction("hide",false,function(  )
            self.m_flashNode:setVisible(false)
        end)
        label:setScale(1)
        if callBack then
            callBack()
        end
    end
    local num = 0
    util_jumpNum(label,startValue,endValue,addValue,spendTime,nil,nil,nil,currCall,function(  )

        if num % 6 == 0 then
            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_Fsbar_LabJump.mp3")
            util_playScaleToAction(label,spendTime * 1/ 6 ,0.5,function(  )
                util_playScaleToAction(label,spendTime * 5/ 6 ,1,function(  )
                
                end)
            end)
        end
        num = num + 1
        
    end)

end

-- 更新并显示FreeSpin剩余次数
function MrCashFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    
end


return MrCashFreespinBarView