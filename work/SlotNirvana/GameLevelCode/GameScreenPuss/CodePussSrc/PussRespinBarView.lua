---
--xcyy
--2018年5月23日
--PussRespinBarView.lua

local PussRespinBarView = class("PussRespinBarView",util_require("base.BaseView"))


function PussRespinBarView:initUI()

    self:createCsbNode("Puss_tishibar.csb")

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

end


function PussRespinBarView:onEnter()
 

end

function PussRespinBarView:changeRespinTimes(times,isinit)

    local lab1 =  self:findChild("Puss_tishi_1_3_0")
    local lab2 =  self:findChild("Puss_tishi_2_5_0")
    local lab3 =  self:findChild("Puss_tishi_3_7_0")

    lab1:setVisible(true)
    lab2:setVisible(true)
    lab3:setVisible(true)

    if times == 0 then

    elseif times == 1 then
        lab1:setVisible(false)

    elseif times == 2 then

        lab2:setVisible(false)

    elseif times == 3 then
        if not isinit then
            gLobalSoundManager:playSound("PussSounds/music_Puss_Respin_rest.mp3")
            self:runCsbAction("animation0")
        end
        
        lab3:setVisible(false)
    end
    
end

function PussRespinBarView:onExit()
 
end

--默认按钮监听回调
function PussRespinBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return PussRespinBarView