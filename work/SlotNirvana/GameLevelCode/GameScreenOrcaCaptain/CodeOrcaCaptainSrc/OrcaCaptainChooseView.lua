---
--xcyy
--2018年5月23日
--OrcaCaptainChooseView.lua
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainChooseView = class("OrcaCaptainChooseView",util_require("Levels.BaseLevelDialog"))

local page_num = {
    max = 15,
    mid = 10,
    min = 7
}

function OrcaCaptainChooseView:initUI(machine)

    self:createCsbNode("OrcaCaptain/ChooseGame.csb")

    self.m_machine = machine
    self.pageList = {}

    self:createAllPage()

    
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

function OrcaCaptainChooseView:showStartAct(isClick)
    self:findChild("Button_1"):setEnabled(true)
    if not isClick then
        self:findChild("Button_1"):setVisible(false)
    else
        self:findChild("Button_1"):setVisible(true)
        self.m_allowClick = true
    end
    for i,v in ipairs(self.pageList) do
        if self.m_machine.m_betLevel <= 0 and i == 1 then
            v:showIdleAct2()
        else
            v:showIdleAct()
        end
        
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_ThreeToOne_show)
    self:runCsbAction("start") -- 播放时间线
end

function OrcaCaptainChooseView:showOverAct()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_ThreeToOne_hide)
    self:runCsbAction("over",false,function ()
        self:setVisible(false)
        
        --刷新主界面显示
        -- for i,v in ipairs(self.pageList) do
        --     if v then
        --         v:setSpineVisible(false)
        --     end
        -- end
    end)
end

function OrcaCaptainChooseView:createAllPage()
    for i=1,4 do
        local page = util_createView("CodeOrcaCaptainSrc.OrcaCaptainChooseItem",{index = i,machine = self})
        self:findChild("Node_Choose_"..i):addChild(page)
        page.index = i
        self.pageList[#self.pageList + 1] = page
    end
end

function OrcaCaptainChooseView:clickEndEveryPageState(index)
    self:findChild("Button_1"):setEnabled(false)
    self.m_allowClick = false
    for i,v in ipairs(self.pageList) do
        v:setAllowClick(false)
        if index == v.index then
            v:showSelectAct()
        else
            v:showDarkAct()
        end
    end
    self.m_machine:delayCallBack(1,function ()
        if index == 1 then
            self.m_machine:updateCurSpinNum(20)
            
        elseif index == 2 then
            self.m_machine:updateCurSpinNum(15)
        elseif index == 3 then
            self.m_machine:updateCurSpinNum(10)
        elseif index == 4 then
            self.m_machine:updateCurSpinNum(7)
        end
        
        self.m_machine:updateProgressForBet()
        self.m_machine:updateCollectItemForBet(false)
        if self.m_machine:getProgressShowNum() == 0 then
            self.m_machine.isResetCollect = true
        else
            self.m_machine.isResetCollect = false
        end
        self:showOverAct()
    end)
end

function OrcaCaptainChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_allowClick then
        return
    end
    if name == "Button_1" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_click)
        self.m_allowClick = false
        self:findChild("Button_1"):setEnabled(false)
        self:showOverAct()
    end
end


return OrcaCaptainChooseView