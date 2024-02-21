---
--smy
--2018年5月24日
--Christmas2021FeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local Christmas2021FeatureChooseView = class("Christmas2021FeatureChooseView",util_require("base.BaseView"))
Christmas2021FeatureChooseView.m_choseFsCallFun = nil
Christmas2021FeatureChooseView.m_choseRespinCallFun = nil
Christmas2021FeatureChooseView.m_dropPig = nil
Christmas2021FeatureChooseView.m_isTouch = nil

function Christmas2021FeatureChooseView:initUI()
    self.m_featureChooseIdx = 1
    self.m_schDelay1 = false
    
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self:createCsbNode("Christmas2021/GameChoose.csb", isAutoScale)

    --添加点击
    local respin = self:findChild("btnRespin")
    self:addClick(respin)
    local freespin = self:findChild("btnFreespin")
    self:addClick(freespin)

    -- 挂载光圈
    self.m_guang1 = util_createAnimation("Christmas2021/GameChoose_guang.csb")
    self:findChild("guang1"):addChild(self.m_guang1)
    self.m_guang1:runCsbAction("idle1",true)

    self.m_guang2 = util_createAnimation("Christmas2021/GameChoose_guang.csb")
    self:findChild("guang2"):addChild(self.m_guang2)
    self.m_guang2:runCsbAction("idle2",true)

    performWithDelay(self, function ()
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
            self.m_schDelay1 = true
        end)
        gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_show_choose_layer.mp3")
    end, 0.5)
    
    --  z展示动画定义
    self.runCsbActionLock = "actionframe1"
    self.runCsbActionfreespin = "actionframe2"

end

function Christmas2021FeatureChooseView:onEnter()
    
    gLobalSoundManager:stopBgMusic()
    
end

function Christmas2021FeatureChooseView:onExit(  )

end

-- 设置回调函数
function Christmas2021FeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end

-- 点击函数
function Christmas2021FeatureChooseView:clickFunc(sender)

    if self.m_isTouch == true or self.m_schDelay1 == false then
        return
    end
    self.m_isTouch = true
    
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end

-- 点击
function Christmas2021FeatureChooseView:clickButton_CallFun(name)
    local tag = 1 --点击free
    if name == "btnRespin" then
        tag = 0 -- 点击respin
        gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_choose.mp3") 
    else
        gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_choose2.mp3") 
    end
    self.m_featureChooseIdx = tag

    self:choseOver( )

end

-- spine时间线
function Christmas2021FeatureChooseView:runSpineAnim(spine,animName,loop,func)
    util_spinePlay(spine, animName, loop)
    if func ~= nil then
          util_spineEndCallFunc(spine, animName, func)
    end
end

-- 点击结束
function Christmas2021FeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function Christmas2021FeatureChooseView:initViewData(machine, freeSpinNum, respinNum, func, changeBG)
    self.machine = machine
    self.m_nFreeSpinNum = freeSpinNum
    self:findChild("free_spin_times"):setString(freeSpinNum)
    self:findChild("respin_times"):setString(respinNum)

    self:findChild("free_spin_times1"):setString(freeSpinNum)
    self:findChild("respin_times1"):setString(respinNum)

    self.m_callFunc = func
    self.m_changeBG = changeBG
end

--初始化游戏结束状态 子类调用
function Christmas2021FeatureChooseView:initGameOver()
    local guoChangCallBack = function()
        self.machine:playChangeGuoChang(function()
            if self.m_featureChooseIdx == 1 then
                if self.m_changeBG ~= nil then
                    self.m_changeBG()
                end
            end
            -- 过场中间 线隐藏点选择界面
            -- self:findChild("Panel_1"):setVisible(false)
            -- self:findChild("root"):setVisible(false)
        end,function()
            if self.m_callFunc then
                self.m_callFunc(self.m_featureChooseIdx)
            end
    
            performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
                self:removeFromParent()
            end,0.0)
        end)
    end

    if self.m_featureChooseIdx == 1 then
        self:findChild("Particle_2"):resetSystem()
        self:runCsbAction(self.runCsbActionfreespin,false,function (  )
            self:runCsbAction("over2",false,function (  )
                self:setVisible(false)
                guoChangCallBack()
            end)
        end) 
    else
        self:findChild("Particle_1"):resetSystem()
        self:runCsbAction(self.runCsbActionLock,false,function (  )
            self:runCsbAction("over1",false,function (  )
                self:setVisible(false)
                guoChangCallBack()
            end)
        end)
    end
end

return Christmas2021FeatureChooseView