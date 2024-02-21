---
--xcyy
--2018年5月23日
--JollyFactoryHumanNode.lua
local PublicConfig = require "JollyFactoryPublicConfig"
local JollyFactoryHumanNode = class("JollyFactoryHumanNode",util_require("base.BaseView"))


function JollyFactoryHumanNode:initUI(params)
    self.m_machine = params.machine
    self.m_mainReelNode = self.m_machine:findChild("Node_2")
    self.m_curAniName = ""
    self.m_runAniEnd = true --动作是否执行完毕
    -- self.m_mainReelNode:setVisible(false)
    self.m_clickEnable = true

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(display.width * 0.8,display.height * 0.5))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    --显示区域
    -- layout:setBackGroundColor(cc.c3b(255, 0, 0))
    -- layout:setBackGroundColorOpacity(255)
    -- layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

function JollyFactoryHumanNode:changeTouchEnable(isEnabled)
    self.m_clickEnable = isEnabled
end

--默认按钮监听回调
function JollyFactoryHumanNode:clickFunc(sender)
    if not self.m_machine:collectBarClickEnabled() or not self.m_clickEnable then
        return
    end
    self:runClickAni()
    
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JollyFactoryHumanNode:initSpineUI()
    self.m_spine = util_spineCreate("JollyFactory_juese",true,true)
    self:addChild(self.m_spine)

    self.m_miLu = util_spineCreate("Socre_JollyFactory_lu",true,true)
    self:addChild(self.m_miLu)
    self.m_miLu:setPosition(cc.p(400,200))
    self.m_miLu:setVisible(false)

    self:bindMainReelNode(self.m_mainReelNode)

    self:runBaseIdle()

    self.m_spine_left = util_spineCreate("JollyFactory_juese",true,true)
    self:addChild(self.m_spine_left)
    self.m_spine_left:setVisible(false)

    self.m_spine_right = util_spineCreate("JollyFactory_juese",true,true)
    self:addChild(self.m_spine_right)
    self.m_spine_right:setVisible(false)
end

function JollyFactoryHumanNode:hideLight()
    self.m_spine_left:setVisible(false)
    self.m_spine_right:setVisible(false)
end

--[[
    点击反馈动画
]]
function JollyFactoryHumanNode:runClickAni()
    self:stopAllActions()
    self:runSpineAni("actionframe_dj",false,function()
        self:runBaseIdle()
    end)
end

--[[
    idle
]]
function JollyFactoryHumanNode:runBaseIdle(isChange)
    self:stopAllActions()
    if isChange then
        local aniTime = self:runSpineAni("idleframe_2",false,function()
            self:runBaseIdle()
        end)
    else
        local aniTime = self:runSpineAni("idleframe",true)
        performWithDelay(self,function()
            self:runBaseIdle(true)
        end,aniTime * 3)
    end
end

--[[
    转盘idle
]]
function JollyFactoryHumanNode:runWheelIdle()
    self:stopAllActions()

    local aniTime = self:runSpineAni("idleframe4",true)
end

--[[
    转盘开始旋转
]]
function JollyFactoryHumanNode:startWheelRun()
    self:stopAllActions()
    self:runSpineAni("idleframe5_start",false,function()
        self:runSpineAni("idleframe5_idle",true)
    end)
end

--[[
    转盘停止旋转
]]
function JollyFactoryHumanNode:wheelDown()
    self:runSpineAni("idleframe5_over",false,function()
        self:runWheelIdle()
    end)
end

--[[
    转盘中奖庆祝
]]
function JollyFactoryHumanNode:runWheelHitRewardAni(func)
    self:runSpineAni("actionframe_qingzhu",false,function()
        self:runWheelIdle()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    麋鹿出现
]]
function JollyFactoryHumanNode:showMiLu(func)
    self.m_miLu:setVisible(true)
    util_spinePlay(self.m_miLu,"start_2")
    util_spineEndCallFunc(self.m_miLu,"start_2",function()
        if type(func) == "function" then
            func()
        end
    end)
    
end

--[[
    隐藏麋鹿
]]
function JollyFactoryHumanNode:hideMiLu(func)
    self.m_miLu:setVisible(false)
end

--[[
    麋鹿舔圣诞老人
]]
function JollyFactoryHumanNode:runMiLuAni(func)
    util_spinePlay(self.m_miLu,"idle")
    self:runSpineAni("idleframe6",false,function()
        self:runWheelIdle()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    添加wild相关动作
]]
function JollyFactoryHumanNode:runAddWildAni(func)
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe",false,function()
        
        self:runSpineAni("idleframe2",true)
    end)

    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,34 / 30)
end

--[[
    添加wild结束相关动作
]]
function JollyFactoryHumanNode:runAddWildOverAni(func)
    self:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_add_wild_over"])
    local aniTime = self:runSpineAni("over",false,function()
        if type(func) == "function" then
            func()
        end
        self:runBaseIdle()
    end)
end

--[[
    添加wild结束相关动作
]]
function JollyFactoryHumanNode:runBigWinAni(func)
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe_bigwin",false,function()
        if type(func) == "function" then
            func()
        end
        self:runBaseIdle()
    end)

    return aniTime
end

--[[
    复制列动效
]]
function JollyFactoryHumanNode:copyReelAni(copyCol,func)
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe2",false,function()
        if type(func) == "function" then
            func()
        end
        self:runBaseIdle()
    end)

    if copyCol ~= 2 then
        self.m_spine_left:setVisible(true)
        util_spinePlay(self.m_spine_left,"actionframe2_zuo")
        util_spineEndCallFunc(self.m_spine_left,"actionframe2_zuo",function()
            self.m_spine_left:setVisible(false)
        end)
    end

    if copyCol ~= 5 then
        self.m_spine_right:setVisible(true)
        util_spinePlay(self.m_spine_right,"actionframe2_you")
        util_spineEndCallFunc(self.m_spine_right,"actionframe2_you",function()
            self.m_spine_right:setVisible(false)
        end)
    end


    return aniTime
end

--[[
    低级图标变高级图标
]]
function JollyFactoryHumanNode:runSymbolToHighAni(func)
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe_tbsj",false,function()
        if type(func) == "function" then
            func()
        end
        self:runBaseIdle()
    end) 
    return aniTime
end

function JollyFactoryHumanNode:runHideHumanAni()
    self:stopAllActions()
    self:runSpineAni("actionframe_qipan")
end

--[[
    向上看
]]
function JollyFactoryHumanNode:runLookUpAni(func)
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe3",false,function()
        if type(func) == "function" then
            func()
        end
    end) 
    return aniTime
end

--[[
    被砸反馈
]]
function JollyFactoryHumanNode:runHitBackAni(count,func)
    if count > 5 then
        count = 5
    end
    self:stopAllActions()
    local aniTime = self:runSpineAni("actionframe_fankui"..count,false,function()
        if type(func) == "function" then
            func()
        end
    end) 
    return aniTime
end

--[[
    从眩晕恢复
]]
function JollyFactoryHumanNode:resumeDizzyAni(func)
    self:stopAllActions()
    local aniTime = self:runSpineAni("over2",false,function()
        self:runBaseIdle()
        if type(func) == "function" then
            func()
        end
    end) 
    return aniTime
end

--[[
    绑定主棋盘
]]
function JollyFactoryHumanNode:bindMainReelNode(node)
    node:retain()
    node:removeFromParent(false)
    util_spinePushBindNode(self.m_spine, "qipan", node)
    node:release()
end

function JollyFactoryHumanNode:runSpineAni(aniName,isLoop,func)
    if not isLoop then
        isLoop = false
    end

    --动作已经执行完不需要融合
    if not self.m_runAniEnd then
        -- util_spineMix(self.m_spine,self.m_curAniName,aniName,0.2)
    end

    self.m_runAniEnd = false
    self.m_curAniName = aniName
    util_spinePlay(self.m_spine,aniName,isLoop)
    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    performWithDelay(self,function()
        if not isLoop then
            self.m_runAniEnd = true
        end
        
        if type(func) == "function" then
            func()
        end
    end,aniTime)

    return aniTime
end



return JollyFactoryHumanNode