---
--smy
--2018年5月24日
--WestRangerFeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local WestRangerFeatureChooseView = class("WestRangerFeatureChooseView",util_require("base.BaseView"))
WestRangerFeatureChooseView.m_dropPig = nil
WestRangerFeatureChooseView.m_isTouch = nil

function WestRangerFeatureChooseView:initUI()
    self.m_featureChooseIdx = 1
    self.m_schDelay1 = false
    
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self:createCsbNode("WestRanger/Choose.csb", isAutoScale)

    --添加点击
    local fenClick = self:findChild("Panel_1")
    self:addClick(fenClick)
    local lvClick = self:findChild("Panel_2")
    self:addClick(lvClick)
    local lanClick = self:findChild("Panel_3")
    self:addClick(lanClick)

    self.m_kaiQiangSpine = util_spineCreate("Socre_WestRanger_Choose", true, true)
    self:findChild("kaiqiang"):addChild(self.m_kaiQiangSpine,1)

    performWithDelay(self, function ()
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
            self.m_schDelay1 = true
        end)
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_featureChooseStart.mp3")
    end, 0.5)

end

function WestRangerFeatureChooseView:onEnter()
    
    gLobalSoundManager:stopBgMusic()
    
end

function WestRangerFeatureChooseView:onExit(  )

end

-- 点击函数
function WestRangerFeatureChooseView:clickFunc(sender)

    if self.m_isTouch == true or self.m_schDelay1 == false then
        return
    end
    self.m_isTouch = true
    
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end

-- 点击
function WestRangerFeatureChooseView:clickButton_CallFun(name)
    gLobalSoundManager:playSound("WestRangerSounds/sound_WestRangers_Click_Collect.mp3")
    local tag = 0 --点击free
    if name == "Panel_1" then
        tag = 0 
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_featureChooseFire9.mp3")
    elseif name == "Panel_2" then
        tag = 1
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_featureChooseFire6.mp3")
    elseif name == "Panel_3" then
        tag = 2
        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_featureChooseFire3.mp3")
    end
    self.m_featureChooseIdx = tag
    self:runCsbAction("actionframe"..(tag+1), false)
    util_spinePlay(self.m_kaiQiangSpine,"actionframe"..(tag+1))
    
    util_spineEndCallFunc(self.m_kaiQiangSpine,"actionframe"..(tag+1),function ()

        performWithDelay(self, function ()
            self:runCsbAction("over"..(tag+1), false,function()
                self:setVisible(false)
                performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
                    self:removeFromParent()
                end,0.0)
    
            end)
    
            self:choseOver( )
        end, 0.5)
    end)

end

-- 点击结束
function WestRangerFeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function WestRangerFeatureChooseView:initViewData(machine, func)
    self.machine = machine

    self.m_callFunc = func
end

--初始化游戏结束状态 子类调用
function WestRangerFeatureChooseView:initGameOver()
    local guoChangCallBack = function()
    --     self.machine:playChangeGuoChang(function()
    --         if self.m_featureChooseIdx == 1 then
    --         end
    --     end,function()
            if self.m_callFunc then
                self.m_callFunc(self.m_featureChooseIdx)
            end
    --     end)
    end

    
    guoChangCallBack()
end

return WestRangerFeatureChooseView