

local GoldieGrizzliesExtraTimesView = class("GoldieGrizzliesExtraTimesView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "GoldieGrizzliesPublicConfig"

function GoldieGrizzliesExtraTimesView:initUI(params)
    self.m_machine = params.machine
    self.m_callFunc = params.callBack
    self:createCsbNode("GoldieGrizzlies/ReSpinMore.csb")
    self.m_isClicked = true

    self.m_clickBtns = {}
    for index = 1,3 do
        local item = util_createAnimation("GoldieGrizzlies_respinmore.csb")
        
        item:findChild("m_lb_num"):setVisible(false)

        --添加点击区域
        local layout = ccui.Layout:create() 
        item:addChild(layout)    
        layout:setAnchorPoint(0.5,0.5)
        layout:setContentSize(CCSizeMake(200,350))
        layout:setTouchEnabled(true)
        layout:setTag(index)
        self:addClick(layout)

        self.m_clickBtns[index] = item

        self:findChild("respin"..index):addChild(item)
        util_setCascadeOpacityEnabledRescursion(self:findChild("respin"..index),true)

        item:runCsbAction("idle1",true)
    end

    --动作执行完毕才能点击
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        self.m_isClicked = false
    end)
end

function GoldieGrizzliesExtraTimesView:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    self.m_isClicked = true

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_extra_time_view_clicked)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if not selfData then
        if type(self.m_callFunc) == "function" then
            self.m_callFunc()
        end
        return
    end

    local extraTimes = self.m_machine.m_runSpinResultData.p_selfMakeData.extraTimes
    local showTimes = clone(self.m_machine.m_runSpinResultData.p_selfMakeData.showTimes)
    --移除抽中的次数
    for index = 1,#showTimes do
        if showTimes[index] == extraTimes then
            table.remove(showTimes,index)
            break
        end
    end

    
    local target = sender:getTag()
    for index = 1,3 do
        local item = self.m_clickBtns[index]
        item:findChild("m_lb_num"):setVisible(true)
        if index == target then
            item:findChild("m_lb_num"):setString(extraTimes)
            item:runCsbAction("choose",false,function()
                item:runCsbAction("idle2")
            end)
        else
            item:findChild("m_lb_num"):setString(showTimes[1])
            table.remove(showTimes,1)
            item:runCsbAction("dark",false,function()
            end)
        end
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_extra_time_view_feed_back)
    self.m_machine:delayCallBack(1.8,function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_fly_extra_times)
        --飞粒子效果
        self:flyParticleToRespinBar(sender,self.m_machine.m_respinBar:findChild("m_lb_num_2"),function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GoldieGrizzlies_fly_extra_times_feed_back)
            self.m_machine.m_respinBar:changeRespinByCount(self.m_machine.m_runSpinResultData.p_reSpinCurCount)
            self.m_machine.m_respinBar:addTimeAni()
            if type(self.m_callFunc) == "function" then
                self.m_callFunc()
            end
            self:removeFromParent()
        end)
        self:runCsbAction("over",false,function()
            
        end)
    end)
end

function GoldieGrizzliesExtraTimesView:flyParticleToRespinBar(startNode,endNode,func)
    --粒子拖尾
    local tail = util_createAnimation("GoldieGrizzlies_respinmore_lizi.csb")
    
    local Particle = tail:findChild("Particle_1")
    Particle:setPositionType(0)

    local startPos = util_convertToNodeSpace(startNode,self.m_machine.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_machine.m_effectNode)

    self.m_machine.m_effectNode:addChild(tail)
    tail:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(20 / 60,endPos),
        cc.CallFunc:create(function()
            Particle:stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    tail:runAction(seq)
end

return GoldieGrizzliesExtraTimesView