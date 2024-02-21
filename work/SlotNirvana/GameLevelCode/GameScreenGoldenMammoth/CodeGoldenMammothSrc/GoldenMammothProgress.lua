---
--xcyy
--2018年5月23日
--GoldenMammothProgress.lua

local GoldenMammothProgress = class("GoldenMammothProgress",util_require("base.BaseView"))

function GoldenMammothProgress:initUI()

    self:createCsbNode("GoldenMammoth_progress.csb")
    
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
    self:runCsbAction("idle", true)

    local index = 1
    self.m_vecFsIcon = {}
    while true do
        local node = self:findChild("Node"..index)
        if node ~= nil then
            local icon = util_createView("CodeGoldenMammothSrc.GoldenMammothIcon")
            node:addChild(icon)
            self.m_vecFsIcon[#self.m_vecFsIcon + 1] = icon
        else
            break
        end
        index = index + 1
    end
    self.m_currIndex = 0
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function GoldenMammothProgress:initFsIconStatus(data)
    self.m_currIndex = data
    for i = 1, #self.m_vecFsIcon, 1 do
        local icon = self.m_vecFsIcon[i]
        if i <= self.m_currIndex then
            icon:showIdle()
        end
    end
end

function GoldenMammothProgress:resetFsIconStatus()
    for i = 1, #self.m_vecFsIcon, 1 do
        local icon = self.m_vecFsIcon[i]
        icon:showUnselected()
    end
end

function GoldenMammothProgress:itemSuperAnim()
    for i = 1, #self.m_vecFsIcon, 1 do
        local icon = self.m_vecFsIcon[i]
        icon:triggerSuperFs()
    end
end

function GoldenMammothProgress:onEnter()
 

end

function GoldenMammothProgress:onExit()
 
end

function GoldenMammothProgress:idleProgress()
    self:runCsbAction("idle", true)
end

function GoldenMammothProgress:showProgress()
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true)
    end)
end

function GoldenMammothProgress:hideProgress()
    self:runCsbAction("over")
end

function GoldenMammothProgress:triggerSuperGame(func)
    self:itemSuperAnim()
    self:runCsbAction("animation", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function GoldenMammothProgress:triggerIconAnim(count, func)
    self.m_currIndex = count
    local icon = self.m_vecFsIcon[self.m_currIndex]
    gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_collect_coin.mp3")
    if count == 10 then
        icon:triggerFs(function()
            gLobalSoundManager:playSound("GoldenMammothSounds/sound_goldenmammoth_collect_over.mp3")
            self:triggerSuperGame(function()
                if func ~= nil then
                    func()
                end
            end)
        end)
    else
        icon:triggerFs(function()
            if func ~= nil then
                func()
            end
        end)
    end
end

function GoldenMammothProgress:showTip()
    local tip =  util_createView("CodeGoldenMammothSrc.GoldenMammothTip")
    self:findChild("node_tip"):addChild(tip)
    tip:setName("tip")
    tip:showTip()
end

function GoldenMammothProgress:hideTip()
    local tip = self:findChild("node_tip"):getChildByName("tip")
    if tip ~= nil then
        tip:hideTip()
    end
end


function GoldenMammothProgress:clickFunc(sender)
    local tip = self:findChild("node_tip"):getChildByName("tip")
    if tip == nil then
        self:showTip()
    else
        self:hideTip()
    end
    
end

return GoldenMammothProgress