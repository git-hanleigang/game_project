---
--xcyy
--2018年5月23日
--JungleJauntRoadMainView.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntRoadMainView = class("JungleJauntRoadMainView",util_require("Levels.BaseLevelDialog"))

function JungleJauntRoadMainView:ctor()
    self.super.ctor(self)
    self.m_currStandIndex = 0
    self.m_maxIndex = 27
    self.m_trailingCellList = {}
    self.m_trailingList = {}
    self.m_trailingLabList = {}
    
    
end

function JungleJauntRoadMainView:initUI(params)
    self:createCsbNode("JungleJaunt_jumanji.csb")

    self.m_machine = params.machine
    self.m_currManType = self.m_machine.m_roadManType

    for i=1,self.m_maxIndex + 1 do
        self.m_trailingCellList[i] = util_createAnimation("JungleJaunt_jumanji_gezi.csb")
        self:findChild("gezi_"..i-1):addChild( self.m_trailingCellList[i])
        self.m_trailingCellList[i]:runCsbAction("idle")
    end
    
   
end

function JungleJauntRoadMainView:initManStandPos()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local chess_bet_list = selfData.chess_bet_list or {}
    local index = chess_bet_list[self.m_currManType] or 0
    self.m_currStandIndex = index

    local refPos = cc.p(self:findChild("tuowei_"..self.m_currStandIndex):getPosition())
    self.m_man:setPosition(refPos)
end

function JungleJauntRoadMainView:changeManIdleType()
    local idleAnimName = "qizi" ..PBC.RoadManTypeNum[self.m_currManType] .. "_idle"
    util_spinePlay(self.m_man.anim,idleAnimName,true)
end

function JungleJauntRoadMainView:playManRun()
    local animName = "qizi" ..PBC.RoadManTypeNum[self.m_currManType] .. "_run"
    util_spinePlay(self.m_man.anim,animName)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JungleJauntRoadMainView:initSpineUI()
    

    self.m_man = cc.Node:create()
    self:findChild("tuowei"):addChild(self.m_man,10)

    self.m_midTip = util_createAnimation("JungleJaunt_jumanji_lvseyuanpan.csb")
    self:findChild("Node_yuanpan"):addChild(self.m_midTip)
    self.m_midTip.anim = util_spineCreate("JungleJaunt_yuanpan",true,true)
    self.m_midTip:findChild("Node_yuanpan"):addChild(self.m_midTip.anim)
    util_spinePlay(self.m_midTip.anim,"idle",true)
    self.m_midTip:runCsbAction("idle2",true)
    self:setMidTipImg(0)


    self.m_midTipImg = util_createAnimation("JungleJaunt_jumanji_lvseyuanpan_shuoming.csb")
    self:findChild("Node_yuanpan"):addChild(self.m_midTipImg,1)
    self.m_midTipImg:runCsbAction("idle",true)

    self.m_man.anim = util_spineCreate("JungleJaunt_qizi",true,true) 
    self.m_man:addChild(self.m_man.anim)
    self:initManStandPos()
    self:changeManIdleType()

    self.m_doorPar = self.m_machine:findChild("Panel_Men")
    self.m_doorPar.doorAnim = util_createAnimation("JungleJaunt_jumanji_men.csb")
    self.m_machine:findChild("Node_men"):addChild(self.m_doorPar.doorAnim)
    self.m_doorPar.logoAnim = util_spineCreate("JungleJaunt_logo",true,true) 
    self.m_doorPar.doorAnim:findChild("Node_logo"):addChild(self.m_doorPar.logoAnim)
    self.m_doorPar.logoAnim:setVisible(false)
    self.m_doorPar:setVisible(false)

end

function JungleJauntRoadMainView:playDoorAnimClose(curFunc,_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_18)

    self.m_doorPar.doorAnim:setVisible(true)
    self.m_doorPar:setVisible(true)
    self.m_doorPar.doorAnim:runCsbAction("switch",false,function()
        if _func then
            _func()
        end
    end)
    performWithDelay(self.m_doorPar,function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_19)
        if curFunc then
            curFunc()
        end
    end,57/60)
end

function JungleJauntRoadMainView:playMidTipStartAinm(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_17)

    self.m_midTip:runCsbAction("start")
    util_spinePlay(self.m_midTip.anim,"start")
    util_spineEndCallFunc(self.m_midTip.anim,"start",function()
        util_spinePlay(self.m_midTip.anim,"actionframe",true)
        performWithDelay(self.m_midTip,function()
            util_spinePlay(self.m_midTip.anim,"over") 
            self.m_midTip:runCsbAction("over",false,function()
                if _func then
                    _func()
                end
                util_spinePlay(self.m_midTip.anim,"idle",true) 
            end)
        end,1.8)
    end)
    
end

function JungleJauntRoadMainView:playFreeMenIdle()
    self.m_doorPar.doorAnim:setVisible(true)
    self.m_doorPar.logoAnim:setVisible(true)
    self.m_doorPar:setVisible(true)
    self.m_doorPar.doorAnim:runCsbAction("idle")
end

function JungleJauntRoadMainView:playBaseMenIdle()
    self.m_doorPar.logoAnim:setVisible(false)
    self.m_doorPar.doorAnim:setVisible(false)
    self.m_doorPar:setVisible(false)
end


function JungleJauntRoadMainView:updateCurrCurrStandIndex(_num)
    self.m_currStandIndex = self.m_currStandIndex + _num
    if self.m_currStandIndex > self.m_maxIndex then
        self.m_currStandIndex = self.m_currStandIndex - self.m_maxIndex - 1
    end
end

function JungleJauntRoadMainView:addObservers()


    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_currManType = params.manType
            self:initManStandPos()
            self:changeManIdleType()
        end,
        PBC.ObserversConfig.UpdateRoadMan
    )
end
function JungleJauntRoadMainView:onEnter()
    self.super.onEnter(self)
    self:addObservers()

    util_setCascadeOpacityEnabledRescursion(self, true)
end


function JungleJauntRoadMainView:getTrailingNode(_index)
    local node = nil
    if not self.m_trailingList[tostring(_index)] then
        local animCsb = util_createAnimation("JungleJaunt_jumanji_tuowei.csb")
        self:findChild("tuowei_".._index):addChild(animCsb)
        self.m_trailingList[tostring(_index)] = animCsb
        node = animCsb
    else
        node = self.m_trailingList[tostring(_index)]
    end
    return node
end

function JungleJauntRoadMainView:getTrailingLab(_index)
    local node = nil
    if not self.m_trailingLabList[tostring(_index)] then
        local animCsb = util_createAnimation("JungleJaunt_jumanji_gezishuzi.csb")
        self:findChild("tuowei_".._index):addChild(animCsb,1)
        self.m_trailingLabList[tostring(_index)] = animCsb
        node = animCsb
    else
        node = self.m_trailingLabList[tostring(_index)]
    end
    return node
end

function JungleJauntRoadMainView:playManRunAnim(_runNum,_func)

    local actionList = {}
    local roadIndex1 = self.m_currStandIndex
    actionList[#actionList+1] = cc.CallFunc:create(function()
        local currRoadIndex = roadIndex1
        for i=1,_runNum do
            currRoadIndex = currRoadIndex + 1
            if currRoadIndex > self.m_maxIndex then
                currRoadIndex = 0
            end
            local traNode = self:getTrailingNode(currRoadIndex)
            traNode:setVisible(true)

            local traLab = self:getTrailingLab(currRoadIndex)
            traLab:setVisible(false)
            local index = i
            performWithDelay(traNode,function()
                traLab:setVisible(true)
                traLab:runCsbAction("start")
                traLab:findChild("m_lb_num"):setString(index)
                if i == _runNum then
                    traNode:runCsbAction("start")
                else
                    traNode:runCsbAction("start2")
                end
            end,1/60 * (i - 1) )
            
        end

    end)

    actionList[#actionList+1] = cc.DelayTime:create(10/60 + 1/60 * _runNum)

    for i=1,_runNum - 1 do
        self:updateCurrCurrStandIndex(1)
        local roadIndex = self.m_currStandIndex
        local endNode = self:findChild("tuowei_"..roadIndex)
        local pos = cc.p(endNode:getPositionX(),endNode:getPositionY())
        local animWait = 0
        local jumpH = 50
        local jumptime = 0.25
        local waitTime = 0.025
        actionList[#actionList+1] = cc.CallFunc:create(function()
            -- self:playManRun()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_15)
        end)
        actionList[#actionList+1] = cc.DelayTime:create(animWait)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            
        end)
        actionList[#actionList+1] = cc.EaseIn:create(cc.JumpTo:create(jumptime,pos ,jumpH ,1),1) 
        actionList[#actionList+1] = cc.CallFunc:create(function()
            
            local traNode = self:getTrailingNode(roadIndex)
            traNode:setVisible(true)
            traNode:runCsbAction("over2",false,function()
                traNode:setVisible(false)
            end)

            local traLab = self:getTrailingLab(roadIndex)
            traLab:runCsbAction("over",false,function()
                traLab:setVisible(false)
            end)
            
            self.m_trailingCellList[roadIndex + 1]:runCsbAction("actionframe")

        end)
        actionList[#actionList+1] = cc.DelayTime:create(waitTime)  
    end

    
    -- 最后一次 蹦的帅一点
    self:updateCurrCurrStandIndex(1)
    local traNode = self:getTrailingNode(self.m_currStandIndex)
    local traLab = self:getTrailingLab(self.m_currStandIndex)
    local endNode = self:findChild("tuowei_"..self.m_currStandIndex)
    local pos = cc.p(endNode:getPositionX(),endNode:getPositionY())
    local jumpH = 80
    local jumptime = 0.4
    local animWait = 0
    actionList[#actionList+1] = cc.CallFunc:create(function()
        -- self:playManRun()
    end)
    actionList[#actionList+1] = cc.DelayTime:create(animWait)
    actionList[#actionList+1] = cc.EaseIn:create(cc.JumpTo:create(jumptime,pos ,jumpH ,1),2) 
    actionList[#actionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_16)
        traNode:setVisible(true)
        traNode:runCsbAction("auto2",false,function()
            traNode:setVisible(false)
        end)
        traLab:runCsbAction("over",false,function()
            traLab:setVisible(false)
        end)
        self.m_trailingCellList[self.m_currStandIndex + 1]:runCsbAction("actionframe")

        if _func then
            _func()
        end 
    end)
    local hideTime = util_csbGetAnimTimes(traNode.m_csbAct, "auto2")
    actionList[#actionList+1] = cc.DelayTime:create(hideTime)
    actionList[#actionList+1] = cc.CallFunc:create(function()
        
    end)
    self.m_man:runAction(cc.Sequence:create(actionList))
end


function JungleJauntRoadMainView:setMidTipImg(_trId)
    self.m_midTip:findChild("tip_1"):setVisible(_trId == 1)
    self.m_midTip:findChild("tip_2"):setVisible(_trId == 2)
    self.m_midTip:findChild("tip_3"):setVisible(_trId == 3)
    self.m_midTip:findChild("tip_4"):setVisible(_trId == 4)
end

function JungleJauntRoadMainView:getAddNum()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local chess_bet_list = selfData.chess_bet_list or {}
    local index = chess_bet_list[self.m_currManType] or 0
    if index <  self.m_currStandIndex then
        return self.m_maxIndex + 1 - self.m_currStandIndex + index 
        
    else
        return index - self.m_currStandIndex  
    end
    
end

return JungleJauntRoadMainView