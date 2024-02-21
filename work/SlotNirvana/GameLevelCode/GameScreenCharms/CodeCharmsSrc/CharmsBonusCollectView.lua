---
--xcyy
--2018年5月23日
--CharmsBonusCollectView.lua

local CharmsBonusCollectView = class("CharmsBonusCollectView",util_require("base.BaseView"))


function CharmsBonusCollectView:initUI()

    self:createCsbNode("Socre_Charms_Bonus_jiesuanTrail.csb")

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

    self:findChild("Particle_1"):setPositionType(0)
    self:findChild("Particle_xiao"):setPositionType(0)
    self:findChild("Particle_jinkuai"):setPositionType(0)
    
    

end


function CharmsBonusCollectView:onEnter()
 

end

function CharmsBonusCollectView:showAdd()
    
end
function CharmsBonusCollectView:onExit()
 
end

--默认按钮监听回调
function CharmsBonusCollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return CharmsBonusCollectView