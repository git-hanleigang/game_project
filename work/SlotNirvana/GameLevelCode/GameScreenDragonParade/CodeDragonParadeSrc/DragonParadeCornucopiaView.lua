---
--xcyy
--2018年5月23日
--DragonParadeCornucopiaView.lua

local DragonParadeCornucopiaView = class("DragonParadeCornucopiaView",util_require("Levels.BaseLevelDialog"))


function DragonParadeCornucopiaView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("DragonParade_jvbaopen.csb")

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

    self.m_spine = util_spineCreate("DragonParade_jvbaopen", true, true)
    self:findChild("jvbaopen"):addChild(self.m_spine)


    self.m_isPlayingFeedBack = false --是否在播放 收集反馈
    self.m_playingTrans = false
end
--反馈
function DragonParadeCornucopiaView:playFeedback( index )
    if self.m_playingTrans then
        return
    end
    if not index then
        return
    end
    if self.m_isPlayingFeedBack == false then
        util_spinePlay(self.m_spine, "actionframe" .. index, false)
        self.m_isPlayingFeedBack = true
        local spineEndCallFunc = function()
            self:playIdle( index )
        end
        util_spineEndCallFunc(self.m_spine, "actionframe" .. index, spineEndCallFunc)

    end
    
end

function DragonParadeCornucopiaView:playIdle( index )
    if not index then
        return
    end
    self.m_isPlayingFeedBack = false
    util_spinePlay(self.m_spine, "idle" .. index, true)
end

function DragonParadeCornucopiaView:playSwitch( type )
    if self.m_playingTrans then
        return
    end
    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_base_dfdc_switch_levelup.mp3")

    self.m_isPlayingFeedBack = false
    local playName = "switch1to2"
    local idleIdx = 3
    if type == "1_2" then
        playName = "switch1to2"
        idleIdx = 2
    elseif type == "1_3" then
        playName = "switch1to3"
    elseif type == "2_3" then
        playName = "switch2to3"
    end
    util_spinePlay(self.m_spine, playName, false)
    local spineEndCallFunc = function()
        self:playIdle( idleIdx )
    end
    util_spineEndCallFunc(self.m_spine, playName, spineEndCallFunc)
end
--播过场
function DragonParadeCornucopiaView:playTrans(func2)
    -- local posNode = util_convertToNodeSpace(self.m_spine, self.m_machine.m_cornucopiaNode)
    -- util_changeNodeParent(self.m_machine.m_cornucopiaNode, self.m_spine)
    -- self.m_spine:setPosition(posNode)

    gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_trans_dfdc.mp3")

    self.m_playingTrans = true

    util_spinePlay(self.m_spine, "actionframe_guochang", false)
    local spineEndCallFunc = function()
        --重置数据
        self.m_machine.m_lastCornucopiaIndex = 1
        self.m_machine:resetBetData()

        self:playIdle( 1 )
        self.m_playingTrans = false
    end
    util_spineEndCallFunc(self.m_spine, "actionframe_guochang", spineEndCallFunc)

    -- performWithDelay(self, function()
    --     func1()
    -- end, 53/30)

    performWithDelay(self, function()
        -- util_changeNodeParent(self:findChild("jvbaopen"), self.m_spine)
        -- self.m_spine:setPosition(cc.p(0, 0))
        -- self:playIdle( 1 )

        func2()
    end, 1.2)
end

return DragonParadeCornucopiaView