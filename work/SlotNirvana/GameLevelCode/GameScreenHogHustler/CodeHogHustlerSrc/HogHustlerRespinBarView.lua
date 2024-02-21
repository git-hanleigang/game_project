---
--xcyy
--2018年5月23日
--HogHustlerRespinBarView.lua

local HogHustlerRespinBarView = class("HogHustlerRespinBarView",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

function HogHustlerRespinBarView:initUI()

    self:createCsbNode("HogHustler_respinbar.csb")

    -- self:runCsbAction("idleframe")

    self.m_cur_time = -1        --当前剩余次数
    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    self.m_respinNums = {}
    for i = 1, 3 do
        local respinNumNode = util_createAnimation("HogHustler_respinbar_shuzi.csb")
        self:findChild(tostring(i)):addChild(respinNumNode)
        for j = 1, 3 do
            respinNumNode:findChild("Button_" .. j):setVisible(j == i)
        end
        
        table.insert(self.m_respinNums, respinNumNode)
        respinNumNode:setVisible(false)
    end
    

    self:findChild("Particle_2"):stopSystem()
    self:findChild("Particle_2_0"):stopSystem()

end


function HogHustlerRespinBarView:onEnter()
    HogHustlerRespinBarView.super.onEnter(self)
end

function HogHustlerRespinBarView:changeRespinTimes(time,notplay)

    if time == self.m_cur_time then     --相同次数不播放
        return
    end

    self.m_cur_time = time
    


    if time == 0 then
        for i=1,3 do
            local numNode = self.m_respinNums[i]
            numNode:setVisible(false)
        end
        self.m_cur_time = -1
    else
        for i=1,3 do
            local numNode = self.m_respinNums[i]
            numNode:setVisible(i == time)

            if i == time then
                if notplay or i ~= 3 then
                    numNode:runCsbAction("idle")
                else
                    numNode:runCsbAction("switch")

                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_respin_timesreset)

                    -- self:findChild("Particle_2"):resetSystem()
                    -- self:findChild("Particle_2_0"):resetSystem()

                    -- self:runCsbAction("switch", false)
                end
                
            end
        end
    end

    -- if time == 3 then
        
    --     if notplay then
    --     else
            
    --         gLobalSoundManager:playSound("CharmsSounds/Charms_respinTime_rest.mp3")
    --     end
        
    --     self:stopAllActions()
    --     self:runCsbAction("03")
    -- elseif time == 2 then
    --     self:stopAllActions()
    --     self:runCsbAction("02") 
    -- elseif time == 1 then  
    --     self:stopAllActions() 
    --     self:runCsbAction("01")  
    -- elseif time == 0 then
    --     --重置剩余次数
    --     self.m_cur_time = -1
    --     self:stopAllActions()
    --     self:runCsbAction("idleframe")
    -- end
    

end


function HogHustlerRespinBarView:onExit()
    HogHustlerRespinBarView.super.onExit(self)
end



return HogHustlerRespinBarView