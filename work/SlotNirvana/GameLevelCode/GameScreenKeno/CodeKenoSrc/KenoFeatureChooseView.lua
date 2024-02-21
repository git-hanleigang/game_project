---
--smy
--2018年5月24日
--KenoFeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local KenoFeatureChooseView = class("KenoFeatureChooseView",util_require("base.BaseView"))
KenoFeatureChooseView.m_choseFsCallFun = nil
KenoFeatureChooseView.m_choseRespinCallFun = nil
KenoFeatureChooseView.m_dropPig = nil
KenoFeatureChooseView.m_isTouch = nil

function KenoFeatureChooseView:initUI()
    self.m_featureChooseIdx = 1
    self.m_schDelay1 = false
    self.m_isSuper = false -- 是否是super
    
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self:createCsbNode("Keno/FeatureChoose.csb", isAutoScale)

    --添加点击
    local keno = self:findChild("kenoBtn")
    self:addClick(keno)
    local freespin = self:findChild("freeBtn")
    self:addClick(freespin)

    -- 小鸡飞出来
    self.m_xiaojiNode = util_spineCreate("Keno_freegame_fankui", true, true)
    self.m_xiaojiNode:setVisible(false)
    self:findChild("xiaojispine"):addChild(self.m_xiaojiNode)

    -- 母鸡
    self.m_mujiNode = util_spineCreate("Socre_Keno_Scatter", true, true)
    self.m_mujiNode:setVisible(false)
    self:findChild("mujispine"):addChild(self.m_mujiNode)

    -- 小鸡
    self.m_wildNode = util_spineCreate("Socre_Keno_Wild2", true, true)
    self:findChild("xiaojispine2"):addChild(self.m_wildNode)
    util_spinePlay(self.m_wildNode, "idleframe5", true)

    self.m_GuoChangDark = util_createAnimation("Keno_dark.csb")
    self:findChild("root"):addChild(self.m_GuoChangDark,-1)
    
    --  z展示动画定义
    self.runCsbActionLock = "actionframe2"
    self.runCsbActionfreespin = "actionframe"

end

function KenoFeatureChooseView:onEnter()
    
    gLobalSoundManager:stopBgMusic()
    
end

function KenoFeatureChooseView:onExit(  )

end

-- 设置回调函数
function KenoFeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end

-- 点击函数
function KenoFeatureChooseView:clickFunc(sender)

    if self.m_isTouch == true or self.m_schDelay1 == false then
        return
    end
    self.m_isTouch = true
    
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end

-- 点击
function KenoFeatureChooseView:clickButton_CallFun(name)
    local tag = 1 --点击free
    local random = math.random(1,2)
    if name == "kenoBtn" then
        tag = 0 -- 点击keno
        if self.m_isSuper then--super
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_choose_Keno_super_"..random..".mp3")
        else
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_choose_Keno_"..random..".mp3")
        end
    else
        if self.m_isSuper then--super
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_choose_Free_super_"..random..".mp3")
        else
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_choose_Free_"..random..".mp3")
        end
    end
    self.m_featureChooseIdx = tag

    self:choseOver( )

end

-- spine时间线
function KenoFeatureChooseView:runSpineAnim(spine,animName,loop,func)
    util_spinePlay(spine, animName, loop)
    if func ~= nil then
          util_spineEndCallFunc(spine, animName, func)
    end
end

-- 点击结束
function KenoFeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function KenoFeatureChooseView:initViewData(machine, func, changeBG)
    self.machine = machine
    local startName = "start"
    local startSound = "KenoSounds/sound_Keno_show_choose_layer.mp3"
    self:findChild("tag_super_free"):setVisible(false)
    self:findChild("tag_super_keno"):setVisible(false)
    self:findChild("title"):setVisible(true)
    self:findChild("title_super"):setVisible(false)
    
    if self.machine.m_runSpinResultData.p_selfMakeData.collectData and self.machine.m_runSpinResultData.p_selfMakeData.collectData.point >= 10 then
        startName = "start2"
        startSound = "KenoSounds/sound_Keno_show_choose_layer_super.mp3"
        self.m_isSuper = true
        self:findChild("tag_super_free"):setVisible(true)
        self:findChild("tag_super_keno"):setVisible(true)

        self:findChild("title"):setVisible(false)
        self:findChild("title_super"):setVisible(true)
    end
    performWithDelay(self, function ()
        self.m_GuoChangDark:runCsbAction("start", false, function()
            self.m_GuoChangDark:runCsbAction("idle",true)
        end)

        self.m_mujiNode:setVisible(true)
        util_spinePlay(self.m_mujiNode, "idleframe2", true)

        self:runCsbAction(startName, false, function()
            self:runCsbAction("idle", true)
            self.m_schDelay1 = true
        end)
        gLobalSoundManager:playSound(startSound)
    end, 0.5)

    self.m_callFunc = func
    self.m_changeBG = changeBG
end

-- 过场
function KenoFeatureChooseView:playChangeGuoChang(func1)
    
    self.m_GuoChang = util_spineCreate("Keno_guochang", true, true)
    self:findChild("root"):addChild(self.m_GuoChang, 1001)

    self.machine:waitWithDelay(40/30,function(  )
        if self.m_GuoChangDark then
            self.m_GuoChangDark:runCsbAction("over",false)
        end
    end)

    gLobalSoundManager:playSound("KenoSounds/sound_Keno_guochang.mp3")
    util_spinePlay(self.m_GuoChang, "guochang", false)
    util_spineEndCallFunc(self.m_GuoChang, "guochang", function()
        performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
            self:removeFromParent()
        end,0.1)
    end)
    self.machine:waitWithDelay(25/30,function(  )
        if func1 then
            func1()
        end
    end)
end

--初始化游戏结束状态 子类调用
function KenoFeatureChooseView:initGameOver()
    local guoChangCallBack = function()
        self:playChangeGuoChang(function()
            if self.m_callFunc then
                self.m_callFunc(self.m_featureChooseIdx)
            end
        end)
    end

    if self.m_featureChooseIdx == 1 then
        if self.m_isSuper then
            self:findChild("dark4"):setVisible(false)
        else
            self:findChild("dark3"):setVisible(false)
        end
        self:findChild("Particle_2"):stopSystem()
        self:findChild("Particle_2_0"):stopSystem()

        self.m_xiaojiNode:setVisible(true)
        util_spinePlay(self.m_xiaojiNode, "actionframe", false)
        self:runCsbAction(self.runCsbActionfreespin,false,function(  )
            self:findChild("Particle_1_0"):stopSystem()
        end) 
        self.machine:waitWithDelay(90/60,function(  )
            guoChangCallBack()
        end)
    else
        if self.m_isSuper then
            self:findChild("dark2"):setVisible(false)
        else
            self:findChild("dark1"):setVisible(false)
        end
        self:findChild("Particle_2"):stopSystem()
        self:findChild("Particle_2_0"):stopSystem()

        self.m_mujiNode:setVisible(true)
        util_spinePlay(self.m_mujiNode, "buling2", false)
        self:runCsbAction(self.runCsbActionLock,false,function()
            self:findChild("Particle_1"):stopSystem()
        end)
        self.machine:waitWithDelay(90/60,function(  )
            guoChangCallBack()
        end)
    end
end

return KenoFeatureChooseView