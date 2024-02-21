---
--smy
--2018年5月24日
--PiggyLegendPirateFeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local PiggyLegendPirateFeatureChooseView = class("PiggyLegendPirateFeatureChooseView",util_require("base.BaseView"))
PiggyLegendPirateFeatureChooseView.m_choseFsCallFun = nil
PiggyLegendPirateFeatureChooseView.m_choseRespinCallFun = nil
PiggyLegendPirateFeatureChooseView.m_isTouch = nil
PiggyLegendPirateFeatureChooseView.m_chooseList = {}

function PiggyLegendPirateFeatureChooseView:initUI()
    self.m_featureChooseIdx = 1
    
    self:createCsbNode("PiggyLegendPirate/FreeSpinStart.csb")

    for i=1,5 do
        self.m_chooseList[i] = util_createAnimation("PiggyLegendPirate_choose"..i..".csb")
        self:findChild("Node_choose"..i):addChild(self.m_chooseList[i])
        self:findChild("Node_choose"..i):setZOrder(i)
        --添加点击
        local clickBtn = self.m_chooseList[i]:findChild("Panel_"..i)
        self:addClick(clickBtn)
        clickBtn:setTouchEnabled(false)

        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_choose"..i), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Node_choose"..i), true)
    end

end

function PiggyLegendPirateFeatureChooseView:onEnter()
    
    gLobalSoundManager:stopBgMusic()
    
end

function PiggyLegendPirateFeatureChooseView:onExit(  )

end

-- 设置回调函数
function PiggyLegendPirateFeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end

-- 点击函数
function PiggyLegendPirateFeatureChooseView:clickFunc(sender)

    if self.m_isTouch == true then
        return
    end
    self.m_isTouch = true
    
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end

-- 点击
function PiggyLegendPirateFeatureChooseView:clickButton_CallFun(name)
    local tag
    if name == "Panel_1" then
        tag = 1
    elseif name == "Panel_2" then
        tag = 2
    elseif name == "Panel_3" then
        tag = 3
    elseif name == "Panel_4" then
        tag = 4
    elseif name == "Panel_5" then
        tag = 5
    end
    self.m_featureChooseIdx = tag

    for i=1,5 do
        if i == tag then
            gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_freeView_select.mp3")
            self:findChild("Node_choose"..i):setZOrder(10)
            self.m_chooseList[i]:runCsbAction("choose", false, function()
                self.m_chooseList[i]:runCsbAction("idleframe3", true)
                self.machine:flyZhu(self, i, function()
                end)
                self:flyZhu(i, function()
                    self:choseOver( )
                end)
            end)
        else
            self.m_chooseList[i]:runCsbAction("dark", false, function()
                self.m_chooseList[i]:runCsbAction("idle2", true)
            end)
        end
    end

end

function PiggyLegendPirateFeatureChooseView:flyZhu(index, func)
    local startPos = self:findChild("Node_choose"..index):getParent():convertToWorldSpace(cc.p(self:findChild("Node_choose"..index):getPosition()))
    local startPosWorld = self:convertToNodeSpace(startPos)
    local moveEndPos = cc.p(display.width * 0.5, display.height * 0.5)

    local actionList = {}
    local collectNode = util_spineCreate("Socre_PiggyLegendPirate_Bonus1",true,true)
    self:addChild(collectNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    util_spinePlay(collectNode,"start",false)
    
    gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_freeView_select_zhuFly.mp3")

    collectNode:setPosition(startPosWorld)

    actionList[#actionList + 1] = cc.MoveTo:create(15/30,moveEndPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        util_spinePlay(collectNode,"actionframe2")
        util_spineEndCallFunc(collectNode,"actionframe2",function ()
            util_spinePlay(collectNode,"idle4",false)
            if func then
                func()
            end
        end)
    end)

    local spawnAct = cc.Spawn:create(cc.Sequence:create(actionList))

    collectNode:runAction(cc.Sequence:create(spawnAct))
end

-- 点击结束
function PiggyLegendPirateFeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function PiggyLegendPirateFeatureChooseView:initViewData(machine, func, changeBG)
    self.machine = machine
    local selfdata = machine.m_runSpinResultData.p_selfMakeData
    local lineBet = globalData.slotRunData:getCurTotalBet()
    for i=1,5 do
        self.m_chooseList[i]:findChild("m_lb_num_1"):setString(selfdata.selectNum[i])
        self.m_chooseList[i]:findChild("m_lb_coins_1"):setString(util_formatCoins(selfdata.selectStore[i]*lineBet,3))
    end
    self:findChild("m_lb_num_0"):setString(selfdata.selectMaxNum)
    self:findChild("m_lb_coins"):setString(util_formatCoins(selfdata.selectMaxStore*lineBet, 3))
    local node=self:findChild("m_lb_coins")
    self:updateLabelSize({label=node,sx=0.9,sy=0.9},90)

    self:findChild("m_lb_num_1"):setString(selfdata.freeTimes)
    
    performWithDelay(self, function ()

        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirates_freeView_start.mp3")
        gLobalSoundManager:playSound("PiggyLegendPirateSounds/sound_PiggyLegendPirate_over_jian.mp3")
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
            for i=1,5 do
                self.m_chooseList[i]:runCsbAction("idle1", true)
                local clickBtn = self.m_chooseList[i]:findChild("Panel_"..i)
                clickBtn:setTouchEnabled(true)
            end
        end)

    end, 0.5)

    self.m_callFunc = func
    self.m_changeBG = changeBG
end

--初始化游戏结束状态 子类调用
function PiggyLegendPirateFeatureChooseView:initGameOver()
    if self.m_callFunc then
        self.m_callFunc(self.m_featureChooseIdx)
    end
end

function PiggyLegendPirateFeatureChooseView:closeView(fun)
    local guoChangCallBack = function()
        if fun then
            fun()
        end
        performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
            self:removeFromParent()
        end,0.0)
    end

    for i=1,5 do
        self.m_chooseList[i]:findChild("Node_1"):setVisible(false)
    end

    self:runCsbAction("over", false, function()
        
        guoChangCallBack()
    end)
end

return PiggyLegendPirateFeatureChooseView