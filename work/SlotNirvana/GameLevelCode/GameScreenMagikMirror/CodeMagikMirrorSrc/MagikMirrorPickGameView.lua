---
--xcyy
--2018年5月23日
--MagikMirrorPickGameView.lua
-- "PickData": {
--     "pickTimes": 3, //触发pick最初次数
--     "process": [[1,4,4,6],[],.. ], //pick玩法的获取列表，第一位：1-5:获取free次数，6:获取+2次pick，7:获取+3次pick。第二位：free个数。第三位：pick剩余次数。第四位：pick总次数
-- },
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorPickGameView = class("MagikMirrorPickGameView",util_require("Levels.BaseLevelDialog") )

local ACTION_STATE = {
    IDLE = 1,
    PAUSE = 2,
    OVER = 3
}
function MagikMirrorPickGameView:initUI(machine)
    self.m_ClickResultDataAry = {}

    self.m_machine = machine

    self:createCsbNode("MagikMirror/PickScreen.csb")

    self:setPickViewNodePosY()
    -- 剩余pick次数
    self.m_pickNumNode = util_createAnimation("MagikMirror_pick_bar_pick.csb")
    self:findChild("Node_pickcishu"):addChild(self.m_pickNumNode)

    -- 获得free次数
    self.m_freeNumNode = util_createAnimation("MagikMirror_pick_bar_fgcishu.csb")
    self:findChild("Node_fgcishu"):addChild(self.m_freeNumNode)

    

    self.curIndex = 0
    self.freeNum = 0
    self.pickNum = 0
    --主要会挂载一些动效相关的节点
    self.m_effect_node = cc.Node:create()
    self.m_effect_node:setPosition(display.width * 0.5, display.height * 0.5)
    self:addChild(self.m_effect_node, GAME_LAYER_ORDER.LAYER_ORDER_TOP)

    self.m_effectNode1 = cc.Node:create()
    self:addChild(self.m_effectNode1, GAME_LAYER_ORDER.LAYER_ORDER_TOP + 1)

    local bg = util_createAnimation("MagikMirror/GameScreenMagikMirrorBg.csb")
    bg:findChild("free_bg"):setVisible(true)
    bg:findChild("base_bg"):setVisible(false)
    bg:findChild("super_bg"):setVisible(false)
    if bg:findChild("Particle_1") and bg:findChild("Particle_2") then
        bg:findChild("Particle_1"):setVisible(false)
        bg:findChild("Particle_2"):setVisible(false)
    end
    self:findChild("bg"):addChild(bg)

    self:runCsbAction("idle")
end

function MagikMirrorPickGameView:setPickViewNodePosY()
    if self.m_machine.isBigSize then
        local homePos = util_convertToNodeSpace(self.m_machine.m_topUI,self)
        local nodePos = util_convertToNodeSpace(self:findChild("Node_ui"),self)
        local changeY = (homePos.y - DESIGN_SIZE.height)/2
        self:findChild("Node_ui"):setPosition(cc.p(nodePos.x,nodePos.y + changeY))
    end
end


function MagikMirrorPickGameView:setResultDataAry(data)
    self.m_ClickResultDataAry = data
end

--[[
    开始bonus玩法
]]
function MagikMirrorPickGameView:beginBonusEffect(func,func2)
    self.m_action = ACTION_STATE.IDLE
    self.curIndex = 0
    -- bonus玩法结束之后的回调
    if func then
        self.m_overCallFunc = func
    end
    self:runCsbAction("idle")
    self.m_freeNumNode:runCsbAction("idle")
    local pickTimes = self.m_ClickResultDataAry.pickTimes
    self:updateUiForPickNum(pickTimes, pickTimes,false)
    self:updataUIData(0, pickTimes, pickTimes)

    -- self.m_clickedPaoAry = {}
    self:startPaoPaoAction()
    if func2 then
        func2()
    end
    
    -- self:delayCallBack(0.5,function ()
        
    -- end)

end



--[[
    刷新界面 free数 次数
]]
function MagikMirrorPickGameView:updataUIData(fgTimes, bonusTimes,bonusTotalTimes, isPlay)
    local waitTime = 0
    if isPlay then
        if self.freeNum ~= fgTimes then
            waitTime = 5/60
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_free_addNum)
            self.m_freeNumNode:runCsbAction("actionframe")
        end
        -- if self.pickNum ~= bonusTotalTimes then
        --     waitTime = 5/60
        --     self.m_pickNumNode:runCsbAction("actionframe")
        -- end
    end
    self.freeNum = fgTimes
    -- self.pickNum = bonusTotalTimes
    self:delayCallBack(waitTime,function ()
        self.m_freeNumNode:findChild("m_lb_num"):setString(tonumber(fgTimes))
        -- self.m_pickNumNode:findChild("m_lb_num_1"):setString((tonumber(bonusTotalTimes) - tonumber(bonusTimes)))
        -- self.m_pickNumNode:findChild("m_lb_num_2"):setString(tonumber(bonusTotalTimes))
    end)
    
    
end

function MagikMirrorPickGameView:updateUiForPickNum(bonusTimes,bonusTotalTimes, isPlay)
    local waitTime = 0
    if isPlay then

        if self.pickNum ~= bonusTotalTimes then
            waitTime = 5/60
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_pick_addNum)
            self.m_pickNumNode:runCsbAction("actionframe")
        end
    end
    self.pickNum = bonusTotalTimes
    self:delayCallBack(waitTime,function ()
        self.m_pickNumNode:findChild("m_lb_num_1"):setString((tonumber(bonusTotalTimes) - tonumber(bonusTimes)))
        self.m_pickNumNode:findChild("m_lb_num_2"):setString(tonumber(bonusTotalTimes))
    end)
end

--[[
    花开始移动
]]
function MagikMirrorPickGameView:startPaoPaoAction( )

    self:beginPaoAct( true )

    self:beginPaoAct(nil, true)
    
    self:beginPaoAct()
    if self.m_updatePosHandler ~= nil then
        self:stopAction(self.m_updatePosHandler)
        self.m_updatePosHandler = nil
    end
    self.m_updatePosHandler = schedule(self,function( )

        self:beginPaoAct()

    end,2)
end

function MagikMirrorPickGameView:beginPaoAct( isFirst ,isSecond)
    local createNum = math.random(2,5)
    local beginWith = {-display.width/3, -display.width/6, 0, display.width/6, display.width/3}
    if isFirst then
        createNum = 4
    elseif isSecond then
        createNum = 4
    end
    for i=1,createNum do
        
        local roIndex = math.random( 1 , #beginWith)
        local roundPos = beginWith[roIndex] 
        table.remove(beginWith,roIndex)

        local random = math.random(-100,100) * self.m_machine.m_machineRootScale
        
        local startPos = cc.p(roundPos+random,display.height/2 + 160 + random)

        if isFirst then
            startPos = cc.p(roundPos,display.height/3 - 100)
        elseif isSecond then
            startPos = cc.p(roundPos+random,display.height/3 + 100)
        end

        local random = math.random(-100,100) * self.m_machine.m_machineRootScale
        local endPos = cc.p(roundPos+random,-display.height / 2 - 160 +random)
        local scale =  math.random(8,10) / 10
        local speed = math.random(100,150)  
        local time = display.height / speed
        local waitTime = 0.1 --math.random(4,6) * 25 / speed  
        if isFirst then
            time = time/2
        elseif isSecond then
            time = time*(display.height + 320 - (display.height/2 + 160 - 250))/(display.height + 320)
        end

        self:createOneFlower(startPos,endPos,scale,time,waitTime )
    end
    
end

--[[
   创建一个花
]]
function MagikMirrorPickGameView:createOneFlower(startPos,endPos,scale,time,waitTime )

    local node = util_createView("CodeMagikMirrorSrc.MagikMirrorPickGameFlowerBtn",self) 
    self:findChild("Node_hua"):addChild(node)
    node:setPosition(startPos)
    node:setScale(scale)
    node:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(true)

        local widthNum = math.round(2,5) 
        local actList2 = {}
        local widthTimes = time / widthNum
        for i=1,widthNum do
            local roundWitdh = math.round(1,3) * 50 * scale
            actList2[#actList2 + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(widthTimes,cc.p(-roundWitdh  ,0)))
            actList2[#actList2 + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(widthTimes,cc.p(roundWitdh  ,0)))
        end
        local sq_1 = cc.Sequence:create(actList2)
    end)
    actList[#actList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(time,endPos))
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(false)
        node:stopAllActions()
        node:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

--[[
    点击函数
]]
function MagikMirrorPickGameView:clickFunc(pao)

    if self:isTouch() then
        self.curIndex = self.curIndex + 1
        pao:findChild("click_pao"):setTouchEnabled(false)

        pao:findChild("click_pao"):setVisible(false)
        pao:stopAllActions()
        -- self.m_clickedPaoAry[#self.m_clickedPaoAry + 1] = pao
        self:showReward(self.curIndex,pao)
    end
end

--[[
    判断是否可以点击
]]
function MagikMirrorPickGameView:isTouch()

    if self.m_action == ACTION_STATE.PAUSE then
        return false
    end

    if self.m_action == ACTION_STATE.OVER then
        return false
    end

    return true
end

function MagikMirrorPickGameView:onEnter()
    MagikMirrorPickGameView.super.onEnter(self)
    
end
function MagikMirrorPickGameView:onExit()
    MagikMirrorPickGameView.super.onExit(self)
    if self.m_updatePosHandler ~= nil then
        self:stopAction(self.m_updatePosHandler)
        self.m_updatePosHandler = nil
    end
end


function MagikMirrorPickGameView:showReward(index,clickedPao)
    if self:checkPickGameOver(index) then
        self.m_action = ACTION_STATE.PAUSE
        if self.m_updatePosHandler ~= nil then
            self:stopAction(self.m_updatePosHandler)
            self.m_updatePosHandler = nil
        end
        self:delayCallBack(0.5,function ()
            self:stopAllActionForFlower(function ()
                -- self:gameOver()
            end)
            
        end)
    end

    local process = self.m_ClickResultDataAry.process or {}
    local processIndex = process[index]or {}
    local rewardNum = processIndex[1] or 0      --奖励的次数
    local freeNum = processIndex[2] or 0        --点击后free次数
    local pickCurNum = processIndex[3] or 0     --点击后pick次数
    local pickTotalNum = processIndex[4] or 0   --点击后总的pick次数

    -- local clickedPao = self.m_clickedPaoAry[1]
    -- table.remove(self.m_clickedPaoAry, 1)

    if not tolua.isnull(clickedPao) then
        --刷新花点击之后的显示
        clickedPao:setShowNum(rewardNum)
        
        clickedPao:showClickAction()
        clickedPao:stopAllActions()
        --增加pick直接刷新
        -- if tonumber(rewardNum) > 5 then
        self:delayCallBack(0.3,function ()
            self:updateUiForPickNum(pickCurNum,pickTotalNum, true)
        end)
        -- end
        util_changeNodeParent(self.m_effectNode1,clickedPao)
        clickedPao:runCsbAction("actionframe",false,function(  )
            
            --刷新ui显示
            self:flyFlowerToEndNode(clickedPao,rewardNum,function ()
                self:updataUIData(freeNum, pickCurNum,pickTotalNum, true)
                if self:checkPickGameOver(index) then   --结束
                    self.m_action = ACTION_STATE.OVER
                    self:delayCallBack(1,function ()
                        
                        -- if self.m_updatePosHandler ~= nil then
                        --     self:stopAction(self.m_updatePosHandler)
                        --     self.m_updatePosHandler = nil
                        -- end
                        -- self:delayCallBack(0.5,function ()
                        --     self:stopAllActionForFlower(function ()
                                self:gameOver()
                            -- end)
                            
                        -- end)
                    end)
                else
                    -- self.m_action = ACTION_STATE.IDLE
                end
            end)
            
        end)
    end
end

function MagikMirrorPickGameView:flyFlowerToEndNode(node,rewardNum,func)
    local particle1 = node:findChild("Particle_1")
    if particle1 then
        particle1:setVisible(false)
    end
    local startPos = util_convertToNodeSpace(node,self.m_effectNode1)
    node:setPosition(startPos)
    local endNode = self:findChild("Node_fgcishu")
    if tonumber(rewardNum) > 5 then
        endNode = self:findChild("Node_pickcishu")
    end
    if tonumber(rewardNum) > 5 then
        if func then
            func()
        end
        node:runCsbAction("over",false,function ()
            node:removeFromParent()
        end)
        
    else
        local endPos = util_convertToNodeSpace(endNode,self.m_effectNode1)
        if particle1 then
            particle1:setVisible(false)
        end
        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            node:runCsbAction("fly")
            if particle1 then
                particle1:setDuration(-1)     --设置拖尾时间(生命周期)
                particle1:setPositionType(0)   --设置可以拖尾
                particle1:resetSystem()
            end
        end)
        actList[#actList + 1] = cc.MoveTo:create(0.5, endPos)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            if not tolua.isnull(node) then
                if particle1 then
                    particle1:stopSystem()--移动结束后将拖尾停掉
                end
                if node:findChild("Node_1") then
                    node:findChild("Node_1"):setVisible(false)
                end
            end
            if func then
                func()
            end
        end)
        actList[#actList + 1] = cc.DelayTime:create(0.5)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            node:removeFromParent()
        end)
        node:runAction(cc.Sequence:create( actList))
    end
    
end

function MagikMirrorPickGameView:stopAllActionForFlower(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_hide_allFlower)
    local children = self:findChild("Node_hua"):getChildren()
    for k,_node in pairs(children) do
        if not tolua.isnull(_node) then
            _node:stopAllActions()
            _node:hideCurFlower()
        end
    end
    self:delayCallBack(21/30,function ()
        if func then
            func()
        end
    end)
    
end

--结束流程
function MagikMirrorPickGameView:gameOver()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_freeView_move)
    self:runCsbAction("actionframe",false,function ()
        self.m_freeNumNode:runCsbAction("actionframe2")
        local particle1 = self.m_freeNumNode:findChild("Particle_1")
        local particle2 = self.m_freeNumNode:findChild("Particle_2")
        if particle1 and particle2 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_freeView_buling)
            particle1:resetSystem()
            particle2:resetSystem()
        end
        self:delayCallBack(1.5,function ()
            util_nodeFadeIn(self, 0.5, 255, 0, nil, function()
                self:setVisible(false)
            end)
            -- self.m_machine.mirror:runCsbAction("idle1",true)
            util_setCascadeOpacityEnabledRescursion(self.m_machine:findChild("Node_qipan"), true)
            util_setCascadeColorEnabledRescursion(self.m_machine:findChild("Node_qipan"), true)
            self.m_machine:setReelUiFadeIn(true)
            -- self.m_machine:findChild("Node_qipan"):setVisible(true)
            -- util_nodeFadeIn(self.m_machine:findChild("Node_qipan"), 0.5, 0, 255, nil, function()
            -- end)
            self:delayCallBack(0.5,function ()
                self:findChild("Node_hua"):removeAllChildren()
                self.m_effectNode1:removeAllChildren()
                if self.m_overCallFunc then
                    self.m_overCallFunc()
                end
            end)
        end)
        
    end)
end

--判断是否结束
function MagikMirrorPickGameView:checkPickGameOver(index)
    local process = self.m_ClickResultDataAry.process or {}
    local processIndex = process[index] or {}
    if table_length(processIndex) == 0 then
        return true
    end
    local pickCurNum = processIndex[3] or 0
    local pickTotalNum = processIndex[4] or 0
    if tonumber(pickCurNum) == 0 then
        return true
    end
    return false
end

--[[
    延迟回调
]]
function MagikMirrorPickGameView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return MagikMirrorPickGameView