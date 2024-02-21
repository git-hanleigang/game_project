---
--xcyy
--2018年5月23日
--CharmsViewRespinBar.lua

local CharmsViewRespinBar = class("CharmsViewRespinBar",util_require("base.BaseView"))


function CharmsViewRespinBar:initUI()

    self:createCsbNode("LinkReels/CharmsLink/4in1_Socre_Charms_Chip_respin.csb")

    self:runCsbAction("idleframe")
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


function CharmsViewRespinBar:onEnter()
    

end

function CharmsViewRespinBar:changeRespinTimes(time,notplay)
    
    if time == 3 then
        
        if notplay then
        else
            
            gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/Charms_respinTime_rest.mp3")
        end
        

        self:runCsbAction("03")
    elseif time == 2 then
        self:runCsbAction("02") 
    elseif time == 1 then   
        self:runCsbAction("01")  
    elseif time == 0 then
        self:runCsbAction("idleframe")
    end
    
end
function CharmsViewRespinBar:onExit()
 
end



return CharmsViewRespinBar