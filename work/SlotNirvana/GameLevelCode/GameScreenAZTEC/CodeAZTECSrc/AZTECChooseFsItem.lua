---
--xcyy
--2018年5月23日
--AZTECChooseFsItem.lua

local AZTECChooseFsItem = class("AZTECChooseFsItem",util_require("base.BaseView"))
AZTECChooseFsItem.m_index = nil

local FS_TOTAL_TIMES = {15, 10, 5, 3, 1}
local FS_TOTAL_LINES = {243, 1024, 3125, 7776, 1}

function AZTECChooseFsItem:initUI(data)

    self:createCsbNode("AZTEC_jushu.csb")
    self.m_index = data.index
    self.m_parent = data.parent
    self:runCsbAction("idle"..self.m_index) -- 播放时间线
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self:findChild("lines"):setString(FS_TOTAL_LINES[self.m_index])
    self:findChild("freespins"):setString(FS_TOTAL_TIMES[self.m_index])
    self.m_clickFlag = true
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


function AZTECChooseFsItem:onEnter()
 

end

function AZTECChooseFsItem:initRandomUI(fsTimes, model, randomTimes, randomModel)
    self:findChild("freespins"):setString(fsTimes)
    self:findChild("lastRandom"):setString(randomTimes)
    self:findChild("endModel"):setString(model)
    self:findChild("lastModel"):setString(randomModel)
end

function AZTECChooseFsItem:selected()
    if self.m_index ~= 5 then
        gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_click.mp3")
        self:runCsbAction("animation"..self.m_index)
        self.m_parent:unselectOther(self.m_index)
        gLobalNoticManager:postNotification("CHOOSE_FS_MODEL", self.m_index)
    else
        gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_click_random.mp3")
        self.m_parent:unselectOther(self.m_index)
        self:runCsbAction("open", false, function()
            if self.m_netCallback == true then
                return
            end
            gLobalNoticManager:postNotification("CHOOSE_FS_MODEL", self.m_index)
            self:runCsbAction("animation5", false, function()
                if self.m_netCallback == true then
                    return
                end
                self:runCsbAction("animation5", true)
                self.m_bRunOnce = true
            end)
        end)
    end
    self.m_clickFlag = false
end

function AZTECChooseFsItem:randomAnimation()
    self.m_netCallback = true
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_click_run.mp3")
    self:runCsbAction("animation6", false, function()
        gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_click_over.mp3")
        self:runCsbAction("over")
        self.m_bRunOnce = true
    end)
end

function AZTECChooseFsItem:unselected()
    self:runCsbAction("hei"..self.m_index)
    self.m_clickFlag = false
end

function AZTECChooseFsItem:runIdle(func)
    if self.m_clickFlag == false then
        return
    end
    self:runCsbAction("glow_"..self.m_index, true)
end

function AZTECChooseFsItem:onExit()
 
end

--默认按钮监听回调
function AZTECChooseFsItem:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = false
    local name = sender:getName()
    local tag = sender:getTag()
    self:selected()
    
end


return AZTECChooseFsItem