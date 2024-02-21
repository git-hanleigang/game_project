---
--xcyy
--2018年5月23日
--SaharaTreasureChooseDiamond.lua

local SaharaTreasureChooseDiamond = class("SaharaTreasureChooseDiamond",util_require("base.BaseView"))


function SaharaTreasureChooseDiamond:initUI(data)

    self:createCsbNode("SaharaTreasure_zuan.csb")

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
    self.m_index = data
end

function SaharaTreasureChooseDiamond:initBtn()
    self:addClick(self:findChild("click"))
    self.m_clickFlag = true
end

function SaharaTreasureChooseDiamond:setClickCall(func)
    self.m_clickCall = func
end

function SaharaTreasureChooseDiamond:runAnimation(anim, isLoop, func)
    self:runCsbAction(anim, isLoop, function()
        if func ~= nil then
            func()
        end
    end)
end

function SaharaTreasureChooseDiamond:updateUI(id)
    local index = 1
    while true do
        local line = self:findChild("kx"..index)
        local diamond = self:findChild("zuan"..index)
        if line ~= nil then
            if id ~= index then
                line:setVisible(false)
                diamond:setVisible(false)
            end
        else
            break
        end
        index = index + 1
    end
    if id == 7 then
        gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_wild.mp3")
    end
end

function SaharaTreasureChooseDiamond:onEnter()

end

function SaharaTreasureChooseDiamond:onExit()
 
end

--默认按钮监听回调
function SaharaTreasureChooseDiamond:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = self.m_clickCall(self.m_index)
end

function SaharaTreasureChooseDiamond:getClickFlag()
    return self.m_clickFlag
end

return SaharaTreasureChooseDiamond