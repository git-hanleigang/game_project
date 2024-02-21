---
--xcyy
--2018年5月23日
--MedusaFsTimesCount.lua

local MedusaFsTimesCount = class("MedusaFsTimesCount",util_require("base.BaseView"))


function MedusaFsTimesCount:initUI()

    self:createCsbNode("MedusaRise_bet.csb")

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
    self.m_vecItems = {}
    local index = 1
    while true do
        local parent = self:findChild("bet_"..index)
        if parent ~= nil then
            local item = util_createView("CodeMedusaRiseSrc.MedusaFsTimesItems")
            parent:addChild(item)
            self.m_vecItems[#self.m_vecItems + 1] = item
        else
            break
        end
        index = index + 1
    end
end


function MedusaFsTimesCount:onEnter()
    
end

function MedusaFsTimesCount:showItemIdle(count)
    for i = 1, count, 1 do
        local item = self.m_vecItems[i]
        item:showTriggerIdle()
    end
end

function MedusaFsTimesCount:showItemAnim(index, func)
    gLobalSoundManager:playSound("MedusaRiseSounds/sound_MedusaRise_collect_scatter.mp3")
    local item = self.m_vecItems[index]
    item:showTriggerAnim(func)
end

function MedusaFsTimesCount:resetUI()
    for i = 1, #self.m_vecItems, 1 do
        local item = self.m_vecItems[i]
        item:showIdle()
    end
end

function MedusaFsTimesCount:onExit()
 
end

--默认按钮监听回调
function MedusaFsTimesCount:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return MedusaFsTimesCount