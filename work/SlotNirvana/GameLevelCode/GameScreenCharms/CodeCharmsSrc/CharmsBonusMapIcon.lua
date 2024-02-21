---
--xcyy
--2018年5月23日
--CharmsBonusMapIcon.lua

local CharmsBonusMapIcon = class("CharmsBonusMapIcon",util_require("base.BaseView"))


function CharmsBonusMapIcon:initUI(data)

    self:createCsbNode(data)

    self:runCsbAction("actionframe", true) -- 播放时间线
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




function CharmsBonusMapIcon:onEnter()
 
end

function CharmsBonusMapIcon:runAnimation(animation, isLoop, func)
    if animation == "animation0" then
        local effect, act = util_csbCreate("smallmap_jiesuo_1.csb")
        self:addChild(effect, 10)
        util_csbPlayForKey(act, "actionframe", false, function()
            effect:removeFromParent(true)
        end, 30)
    end
    self:runCsbAction(animation, isLoop, func)
end

function CharmsBonusMapIcon:onExit()
 
end

--默认按钮监听回调
function CharmsBonusMapIcon:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return CharmsBonusMapIcon