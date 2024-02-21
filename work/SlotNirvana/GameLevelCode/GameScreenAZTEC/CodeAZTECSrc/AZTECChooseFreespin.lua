---
--xcyy
--2018年5月23日
--AZTECChooseFreespin.lua
local BaseLevelDialog = require "Levels.BaseLevelDialog"
local AZTECChooseFreespin = class("AZTECChooseFreespin",BaseLevelDialog)


function AZTECChooseFreespin:initUI()

    self:createCsbNode("AZTEC/ChooseFsLayer.csb")

    self:runCsbAction("ildeframe", true) -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_fs_choose_window.mp3")
    self.m_vecItems = {}
    local index = 1
    while true do
        local node = self:findChild("Node_" .. index )
        if node ~= nil then
            local data = {}
            data.index = index
            data.parent = self
            local item = util_createView("CodeAZTECSrc.AZTECChooseFsItem", data)
            node:addChild(item)
            self.m_vecItems[#self.m_vecItems + 1] = item
            performWithDelay(self, function()
                item:runIdle()
            end, 2 * (index - 1))
        else
            break
        end
        index = index + 1
    end
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function AZTECChooseFreespin:unselectOther(index)
    for i = 1, #self.m_vecItems, 1 do 
        if self.m_vecItems[i].m_index ~= index then 
            self.m_vecItems[i]:unselected()
        end
    end
end

function AZTECChooseFreespin:initRandomUI(fsTimes, model, randomTimes, randomModel)
    self.m_vecItems[#self.m_vecItems]:initRandomUI(fsTimes, model, randomTimes, randomModel)
end

function AZTECChooseFreespin:randomAnimation()
    self.m_vecItems[#self.m_vecItems]:randomAnimation()
end

--默认按钮监听回调
function AZTECChooseFreespin:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function AZTECChooseFreespin:overAnimation(func)
    self:runCsbAction("over", false, function()
        if func then
            func()
        end
    end)
end

return AZTECChooseFreespin