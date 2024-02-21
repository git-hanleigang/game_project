---
--xcyy
--2018年5月23日
--BlazingMotorsRisingIdelView.lua

local BlazingMotorsRisingIdelView = class("BlazingMotorsRisingIdelView",util_require("base.BaseView"))


function BlazingMotorsRisingIdelView:initUI()

    self:createCsbNode("Socre_BlazingMotors_Rising.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    

end


function BlazingMotorsRisingIdelView:onEnter()
 

end

function BlazingMotorsRisingIdelView:getActTime()

    local time1 = util_csbGetAnimTimes(self.m_csbAct,"show")
    local time2 = 0 -- util_csbGetAnimTimes(self.m_csbAct,"over")

    return time1 + time2
end

function BlazingMotorsRisingIdelView:getOverActTime()

    local time1 = 0 -- util_csbGetAnimTimes(self.m_csbAct,"show")
    local time2 = util_csbGetAnimTimes(self.m_csbAct,"over")

    return time1 + time2
end

function BlazingMotorsRisingIdelView:showOverAnction()
    self:runCsbAction("over",false,function(  )
        -- self:runCsbAction("over",false,function(  )
            
        -- end)
    end)
    
end


function BlazingMotorsRisingIdelView:showAnction()
    self:runCsbAction("show",false,function(  )
        -- self:runCsbAction("over",false,function(  )
            
        -- end)
    end)
    
end
function BlazingMotorsRisingIdelView:onExit()
 
end

--默认按钮监听回调
function BlazingMotorsRisingIdelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return BlazingMotorsRisingIdelView