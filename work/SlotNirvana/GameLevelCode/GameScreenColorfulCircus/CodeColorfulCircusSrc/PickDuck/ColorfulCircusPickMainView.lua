
local ColorfulCircusPickMainView = class("ColorfulCircusPickMainView",util_require("Levels.BaseLevelDialog"))
local ColorfulCircusObjectPool = util_require("CodeColorfulCircusSrc.PickDuck.ColorfulCircusObjectPool")

local DUCK_WIDTH        = 145
local DUCK_PANEL_WIDTH  = 733           --duck所在Panel宽
local DUCK_INTERVAL     = 220
local LEFT_ORIGIN_X     = -200          --左起点
local RIGHT_ORIGIN_X    = 933           --右起点
local TOUCH_EDGE_DIS    = 80            --边界到可点击区域距离
local GAME_STATUS ={
    NORMAL = 1,
    BEATTACK = 2,
    OVER = 3,
}

local PRIZE_TYPE = {
    TIMES = 1,
    MULTI = 2,
}



function ColorfulCircusPickMainView:initUI(_machine, _multi, _specialWin, _spinNum, _avgBet, _callBackFun, pos)
    self.m_machine = _machine
    self.m_multi = _multi
    self.m_specialWin = _specialWin
    self.m_spinNum = _spinNum       --初始次数
    self.m_avgBet = _avgBet
    self.m_callBackFun = _callBackFun
    self.m_duckModeHandlerID = nil
    self.m_duckItemList = {{},{},{},{}}
    self.m_duckLast = {}
    self.m_status = GAME_STATUS.NORMAL
    self.m_curPickTimes = 0         --第几次pick
    self.m_lastPickTimes = _spinNum --pick剩余次数
    self.m_curWinCoins = _avgBet
    self.m_curMulti = 1
    self.m_isStartViewOvering = false
    self.m_isCanClickStartPopup = false
    self:createCsbNode("ColorfulCircus/PickColorfulCircus.csb")

    self.m_rootNode = self:findChild("root")
    self.m_movePanel = self:findChild("Panel_4")
    self.m_posY = {}
    for i = 1, 4 do
        self.m_posY[i] = self:findChild("Node_" .. i):getPositionY()
    end

    --start板
    self.m_startView = util_createAnimation("ColorfulCircus_pick_start.csb")
    self:findChild("Node_start"):addChild(self.m_startView)
    self.m_startView:setVisible(false)
    if pos then
        self.m_startView:findChild("dadian1"):setVisible(pos == 5)
        self.m_startView:findChild("dadian2"):setVisible(pos == 10)
        self.m_startView:findChild("dadian3"):setVisible(pos == 15)
        self.m_startView:findChild("dadian4"):setVisible(pos == 20)
    end
    
    --次数板
    self.m_timesView = util_createAnimation("ColorfulCircus_pick_cishu.csb")
    self:findChild("Node_pickshu"):addChild(self.m_timesView)
    --赢钱板
    self.m_winView = util_createAnimation("ColorfulCircus_pick_win.csb")
    self:findChild("Node_pickwin"):addChild(self.m_winView)
    --乘倍板
    self.m_multiView = util_createAnimation("ColorfulCircus_pick_cheng.csb")
    self:findChild("Node_pickcheng"):addChild(self.m_multiView, 1)

    self.m_shootCntLabel = self.m_timesView:findChild("m_lb_num")
    self.m_winCoinsLabel = self.m_winView:findChild("m_lb_coins")
    self.m_multiLabel = self.m_multiView:findChild("m_lb_num")

    self.m_winEffect = util_createAnimation("ColorfulCircus_pick_win_zjk.csb")
    self.m_winView:findChild("zjk"):addChild(self.m_winEffect)
    self.m_winEffect:setVisible(false)
    
    --水
    self.m_waters = {}
    for i=1,4 do
        self.m_waters[i] = util_createAnimation("ColorfulCircus_pick_shui.csb")
        self:findChild("Node_shui" .. i):addChild(self.m_waters[i])
        self.m_waters[i]:runCsbAction("idle", true)
    end
    --炮
    self.m_gun = util_createAnimation("ColorfulCircus_pick_pao.csb")
    self:findChild("Node_pao"):addChild(self.m_gun)
    self.m_gun:runCsbAction("idle", true)
    
    
    self:addClick(self:findChild("Panel_1"))

    self:initRefresh()

    self:addClick(self.m_startView:findChild("Panel_StartClick"))

    gLobalNoticManager:addObserver(self,function(self,param)
        local duck = param
        self:duckClick(duck)
    end,"COLORFULCIRCUS_DUCK_CLICK")


    self.m_duckPool = ColorfulCircusObjectPool.New(function (_row, _posX, _isToLeft)
        return self:createOneDuck(_row, _posX, _isToLeft)
    end)

    self:initOriginDucks()


    self.m_multiUp10Light = {}
    if self.m_specialWin then
        for i=1,#self.m_specialWin do
            if self.m_specialWin[i] and self.m_specialWin[i][2] == 2 and self.m_specialWin[i][3] >= 10 then
                local lightBg = util_createAnimation("ColorfulCircus_shuzhi_beiguang.csb")
                self:addChild(lightBg)
                lightBg:runCsbAction("idle", true)
                lightBg:findChild("Particle_1"):resetSystem()
                self.m_multiUp10Light[#self.m_multiUp10Light + 1] = lightBg
                lightBg:setVisible(false)
            end
        end
    end
    
end

function ColorfulCircusPickMainView:initRefresh()
    self:updateTotalWin()
    self:refreshMulti(false, self.m_curMulti)
    self:refreshShootTimes()
end

--初始创建鸭子
function ColorfulCircusPickMainView:initOriginDucks()
    for row=1,4 do
        for i=1,5 do
            local duck = nil
            if row % 2 == 1 then --left
                duck = self.m_duckPool:Get(row, RIGHT_ORIGIN_X - (i - 1)*DUCK_INTERVAL, true)
            else
                duck = self.m_duckPool:Get(row, LEFT_ORIGIN_X + (i - 1)*DUCK_INTERVAL, false)
            end
            table.insert(self.m_duckItemList[row], duck)
            if i == 1 then
                self.m_duckLast[row] = duck
            end
        end
    end
    
end

--更新赢钱
function ColorfulCircusPickMainView:updateTotalWin()
    if self.m_winCoinsLabel then
        self.m_winCoinsLabel:setString(util_formatCoins(self.m_curWinCoins, 30))
        self:updateLabelSize({label=self.m_winCoinsLabel,sx=0.85,sy=0.9},725)
    end
end

function ColorfulCircusPickMainView:duckOver(duck, _type, _param, pos)
    


    --判定结束
    if self:checkTimesOver() then
        if _type == PRIZE_TYPE.MULTI then
            self:flyPrize(duck, _type, _param, pos)
        end
        self.m_status = GAME_STATUS.OVER
        performWithDelay(self, function()
            self:gameOverBefore(function (  )
                performWithDelay(self, function()
                    self:gameOver()
                end, 2)
            end)
        end, 1.5)
    else
        
        self:flyPrize(duck, _type, _param, pos)
    end
        
end

function ColorfulCircusPickMainView:duckClick(duck)
    if self.m_curPickTimes >= #self.m_specialWin then
        return
    end
    self.m_status = GAME_STATUS.BEATTACK
    self.m_curPickTimes = self.m_curPickTimes + 1
    self.m_lastPickTimes = self.m_lastPickTimes - 1
    self:refreshShootTimes()
    -- self:setMultiData()
    self:setShootData()   --此时增加的次数已经加上 未更新 收集时更新


    local specialData = self:getSpecialWinByTimes(self.m_curPickTimes)
    local type = 1
    local param = 1
    if specialData then
        type = specialData[2]
        param = specialData[3]
    end

    self:gunFire(duck, type, param)
end

function ColorfulCircusPickMainView:gunFire(duck, _type, _param)
    self.m_gun:runCsbAction("actionframe2", false, function ()
        self.m_gun:runCsbAction("idle", true)
    end)
    performWithDelay(self, function ()
        if duck and not tolua.isnull(duck) then
            duck:beDamage(function (  )
                
            end)

            --damage特效
            local damageEffect = util_createAnimation("ColorfulCircus_pick_yazizg.csb")
            self.m_rootNode:addChild(damageEffect, 150)
            local pos = util_convertToNodeSpace(duck:findChild("zg"), self.m_rootNode)
            damageEffect:setPosition(cc.p(pos))
            damageEffect:runCsbAction("actionframe2", false, function (  )
                damageEffect:removeFromParent()
            end)

            performWithDelay(self, function ()
                self:duckOver(duck, _type, _param, pos)
            end, 10/60)
        end
    end, 16/60)
end

function ColorfulCircusPickMainView:checkTimesOver()
    if self.m_curPickTimes >= #self.m_specialWin then
        return true
    end
    
    return false
end

function ColorfulCircusPickMainView:getSpecialWinByTimes(times)
    for i,v in ipairs(self.m_specialWin) do
        if v and v[1] == times then
            return v
        end
    end
    return nil
end

function ColorfulCircusPickMainView:gameStart()
    self:initSchedule()
end

function ColorfulCircusPickMainView:gameOver()
    self:unscheduleDuckMove()

    -- self:winEffectShow(false)
    self.m_machine:showPickOverStart(function()
        self.m_machine:duckShowOver(function (  )
            self.m_machine:changeMainUi(self.m_machine.m_base )
            self:hideDuckView()
            
            self.m_machine:resetMusicBg(true)
        end, function (  )
            self.m_machine:duckOverCheckBigwin()

            if self.m_callBackFun then
                self.m_callBackFun()
            end

            self:delDuckView(  )
        end)
    end)
    
end

function ColorfulCircusPickMainView:gameOverBefore(_func)
    if self.m_curMulti and self.m_curMulti > 0 then
        self.m_multiView:setVisible(false)
        local multiNode = util_createAnimation("ColorfulCircus_pick_cheng.csb")
        self:addChild(multiNode, 100)
        local backLight1 = util_createAnimation("ColorfulCircus_shuzhi_beiguang.csb")
        multiNode:findChild("shuzhi_beiguang"):addChild(backLight1)
        backLight1:findChild("Particle_1"):setDuration(-1)     --设置拖尾时间(生命周期)
        backLight1:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        backLight1:findChild("Particle_1"):resetSystem()
        backLight1:playAction("idle", true)

        local startPos = util_convertToNodeSpace(self:findChild("Node_pickcheng"), self)
        multiNode:setPosition(cc.p(startPos))
        multiNode:findChild("m_lb_num"):setString("x" .. self.m_curMulti)
        self:updateLabelSize({label=multiNode:findChild("m_lb_num"),sx=0.95,sy=0.95},177)

        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_duck_multiFinalFly.mp3")

        local winLabel = self.m_winView:findChild("m_lb_coins")
        local endPos = util_convertToNodeSpace(winLabel, self)
        -- endPos = cc.pAdd(endPos, cc.p(winLabel:getContentSize().width/2, winLabel:getContentSize().height/2))

        local actionList = {}
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            multiNode:runCsbAction("start", false)
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(10/60)
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            multiNode:runCsbAction("idle", false)
        end)
        actionList[#actionList + 1] = cc.DelayTime:create(30/60)
        actionList[#actionList + 1] = cc.CallFunc:create(function(  )
            multiNode:runCsbAction("fly", false)
        end)
        -- actionList[#actionList + 1] = cc.DelayTime:create(26/60)
        -- actionList[#actionList + 1] = cc.MoveTo:create(30/60, endPos)
        actionList[#actionList + 1] = cc.EaseIn:create(cc.BezierTo:create(30/60,{startPos, cc.p(startPos.x, endPos.y), endPos}), 2)
        -- actionList[#actionList + 1] = cc.DelayTime:create(0.2)
        -- actionList[#actionList + 1] = cc.RemoveSelf:create()
        actionList[#actionList + 1] =
            cc.CallFunc:create(
            function()
                self.m_winView:runCsbAction("actionframe2", false)
                performWithDelay(self, function()
                    self:winEffectShow(true)
                end, 7/60)
                self.m_curWinCoins = self.m_curWinCoins * self.m_curMulti
                self:updateTotalWin()

                if _func then
                    _func()
                end
                multiNode:removeFromParent()
            end
        )
        local sq = cc.Sequence:create(actionList)
        multiNode:runAction(sq)
    else
        if _func then
            _func()
        end
    end
end

function ColorfulCircusPickMainView:winEffectShow(_appear)
    if _appear then
        self.m_winEffect:setVisible(true)
        self.m_winEffect:runCsbAction("actionframe", true)
    else
        self.m_winEffect:setVisible(false)
    end
end

function ColorfulCircusPickMainView:flyPrize(duck, _type, _param, pos)
    if duck then
        -- local worldPos = duck:getParent():convertToWorldSpace(cc.p(duck:getPositionX(), duck:getPositionY()))
        -- local specialData = self:getSpecialWinByTimes(self.m_curPickTimes)
        -- if specialData and specialData[2] then
            

            local isHaveLight = false
            if _type == PRIZE_TYPE.MULTI and _param and _param >= 10 then
                isHaveLight = true
            end
            local sign = util_createView("CodeColorfulCircusSrc.PickDuck.ColorfulCircusSignView", self, _type, _param, isHaveLight)
            self.m_rootNode:addChild(sign, 100)

            --此处 粒子一开始就是扩散到最大情况
            if isHaveLight then
                if self.m_multiUp10Light and #self.m_multiUp10Light > 0 then
                    self.m_multiUp10Light[1]:setVisible(true)
                    util_changeNodeParent(sign:findChild("shuzhi_beiguang"), self.m_multiUp10Light[1])
                    util_setCascadeOpacityEnabledRescursion(sign:findChild("shuzhi_beiguang"), true)
                    table.remove(self.m_multiUp10Light, 1)
                end
            end

            -- local nodePos = self.m_rootNode:convertToNodeSpace(worldPos)
            -- sign:setPosition(cc.p(nodePos))
            sign:setPosition(cc.p(pos))

            if _type == PRIZE_TYPE.MULTI then
                if self.m_status ~= GAME_STATUS.OVER then
                    self.m_status = GAME_STATUS.NORMAL
                end
                
                
                local multiNode = self:findChild("Node_pickcheng")
                local endPos = util_convertToNodeSpace(multiNode, self.m_rootNode)
                self:signFly(sign, endPos, function()
                    self.m_curMulti = self.m_curMulti +_param
                    self:refreshMulti(true, self.m_curMulti)
                    
                    sign:removeFromParent()
                end, PRIZE_TYPE.MULTI, _param)
            elseif _type == PRIZE_TYPE.TIMES then

                

                local timesNode = self.m_timesView:findChild("m_lb_num")
                local endPos = util_convertToNodeSpace(timesNode, self.m_rootNode)
                self:signFly(sign, endPos, function()
                    if self.m_status ~= GAME_STATUS.OVER then
                        self.m_status = GAME_STATUS.NORMAL
                    end
                    self:refreshShootTimes(true)

                    
                    sign:removeFromParent()
                end, PRIZE_TYPE.TIMES, _param)
            end

            
        -- end
    else
        local a = 1
    end
    
end

function ColorfulCircusPickMainView:signFly(node, endPos, func, _type, _param)
    local actionList = {}
    -- actionList[#actionList + 1] = cc.DelayTime:create(actionframeTimes)
    -- actionList[#actionList + 1] = cc.BezierTo:create(flyTime,{startPos, cc.p(endPos.x, startPos.y), endPos})
    -- actionList[#actionList + 1] =
    --     cc.CallFunc:create(
    --     function()
    --     end
    -- )
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        node:playFly()
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(26/60)
    -- actionList[#actionList + 1] = cc.MoveTo:create(22/60, endPos)

    local startP = cc.p(node:getPosition())
    local bez = nil
    local randNum = math.random(1,100)
    local centerPos = cc.p((startP.x+endPos.x) / 2, (startP.y+endPos.y) / 2)
    local randDis = math.random(100, 200)
    local flyTime = 16
    if _type == PRIZE_TYPE.MULTI then
        if centerPos.x > endPos.x then
            bez = cc.BezierTo:create(flyTime/60, {startP, cc.pAdd(centerPos, cc.p(-randDis,-randDis)), endPos})
        else
            bez = cc.BezierTo:create(flyTime/60, {startP, cc.pAdd(centerPos, cc.p(-randDis,randDis)), endPos})
        end
    else
        if centerPos.x > endPos.x then
            bez = cc.BezierTo:create(flyTime/60, {startP, cc.pAdd(centerPos, cc.p(randDis,randDis)), endPos})
        else
            bez = cc.BezierTo:create(flyTime/60, {startP, cc.pAdd(centerPos, cc.p(randDis,-randDis)), endPos})
        end
    end
    
    
    -- actionList[#actionList + 1] = cc.MoveTo:create(11/60, endPos)
    actionList[#actionList + 1] = bez
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        if _type == PRIZE_TYPE.MULTI then
            gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_duck_multiFly.mp3")
        else
            gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_duck_shootFly.mp3")
        end
    end)
    -- actionList[#actionList + 1] = cc.DelayTime:create(0.2)
    -- actionList[#actionList + 1] = cc.RemoveSelf:create()
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
        end
    )
    local sq = cc.Sequence:create(actionList)
    node:runAction(sq)
end

--设置乘倍数据
-- function ColorfulCircusPickMainView:setMultiData()
--     local specialData = self:getSpecialWinByTimes(self.m_curPickTimes)
--     if specialData and specialData[2] == PRIZE_TYPE.MULTI and specialData[3] then
--         self.m_curMulti = self.m_curMulti + specialData[3]
--     end
-- end

--设置次数数据
function ColorfulCircusPickMainView:setShootData()
    local specialData = self:getSpecialWinByTimes(self.m_curPickTimes)
    if specialData and specialData[2] == PRIZE_TYPE.TIMES and specialData[3] then
        self.m_lastPickTimes = self.m_lastPickTimes + specialData[3]
    end
end

function ColorfulCircusPickMainView:refreshMulti(_isPlayAnim, num)
    if self.m_multiLabel then
        if num == 0 then
            self.m_multiLabel:setString("")
        else
            if _isPlayAnim then
                self.m_multiView:runCsbAction("switch", false)
                performWithDelay(self, function (  )
                    self.m_multiLabel:setString("x" .. num)
                    self:updateLabelSize({label=self.m_multiLabel,sx=0.95,sy=0.95},177)
                end, 10/60)
            else
                self.m_multiLabel:setString("x" .. num)
                self:updateLabelSize({label=self.m_multiLabel,sx=0.95,sy=0.95},177)
            end
        end
    end
end

function ColorfulCircusPickMainView:refreshShootTimes(_isPlayAnim)
    if self.m_shootCntLabel then
        if _isPlayAnim then
            self.m_timesView:runCsbAction("switch2", false, function()
                if self.m_lastPickTimes == 2 or self.m_lastPickTimes == 1 then
                    self.m_timesView:runCsbAction("actionframe", true)
                end
                
            end)
            performWithDelay(self, function (  )
                self.m_shootCntLabel:setString(self.m_lastPickTimes)
                self:updateLabelSize({label=self.m_shootCntLabel,sx=1.1,sy=1.1},85)
            end, 10/60)
        else
            self.m_shootCntLabel:setString(self.m_lastPickTimes)
            self:updateLabelSize({label=self.m_shootCntLabel,sx=1.1,sy=1.1},85)

            if self.m_lastPickTimes ~= 2 and self.m_lastPickTimes ~= 1 then
                self.m_timesView:runCsbAction("idle", true)
            else
                self.m_timesView:runCsbAction("actionframe", true)
            end
        end
    end
end

function ColorfulCircusPickMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Panel_1" then
        -- self:initSchedule()
    elseif name == "Panel_StartClick" then
        if self.m_isStartViewOvering == false and self.m_isCanClickStartPopup then
            self.m_isStartViewOvering = true


            gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_duck_startPopupOver.mp3")
            self.m_startView:runCsbAction("over", false, function()
                self.m_startView:setVisible(false)
                self.m_status = GAME_STATUS.NORMAL
            end)
        end
    end
end

function ColorfulCircusPickMainView:initSchedule()
    if self.m_duckModeHandlerID ~= nil then
        return
    end
    self.m_duckModeHandlerID = scheduler.scheduleUpdateGlobal(function(dt)

        for i,rowDuckList in ipairs(self.m_duckItemList) do
            for j = #rowDuckList, 1, -1 do
                local duck = rowDuckList[j]
                duck:updateMove(dt)

                local posNewX = duck:getPositionX()
                if duck:getIsToLeft() then
                    if posNewX <= (0 - DUCK_WIDTH) then
                        table.remove(rowDuckList, j)
                        if self.m_duckLast[i] and self.m_duckLast[i] == duck then
                            self.m_duckLast[i] = nil
                        end
                        self.m_duckPool:Put(duck)
                    end
                else
                    if posNewX >= (DUCK_PANEL_WIDTH + DUCK_WIDTH) then
                        table.remove(rowDuckList, j)
                        if self.m_duckLast[i] and self.m_duckLast[i] == duck then
                            self.m_duckLast[i] = nil
                        end
                        self.m_duckPool:Put(duck)
                    end
                end
            end
        end

        for i=1,4 do
            if self.m_duckLast[i] == nil then
                local duck = nil
                if i % 2 == 1 then  --向左走
                    duck = self.m_duckPool:Get(i, RIGHT_ORIGIN_X, true)
                    self:resetOneDuck(duck, i, RIGHT_ORIGIN_X, true)
                else
                    duck = self.m_duckPool:Get(i, LEFT_ORIGIN_X, false)
                    self:resetOneDuck(duck, i, LEFT_ORIGIN_X, false)
                end
                self.m_duckLast[i] = duck
                table.insert(self.m_duckItemList[i], duck)
                
            else
                local lastPosX = self.m_duckLast[i]:getPositionX()
                if i % 2 == 1 then  --向左走
                    if lastPosX <= (RIGHT_ORIGIN_X - DUCK_INTERVAL) then
                        local duck = self.m_duckPool:Get(i, lastPosX + DUCK_INTERVAL, true)
                        self:resetOneDuck(duck, i, lastPosX + DUCK_INTERVAL, true)
                        self.m_duckLast[i] = duck
                        table.insert(self.m_duckItemList[i], duck)
                    end
                else
                    if lastPosX >= (LEFT_ORIGIN_X + DUCK_INTERVAL) then
                        local duck = self.m_duckPool:Get(i, lastPosX - DUCK_INTERVAL, false)
                        self:resetOneDuck(duck, i, lastPosX - DUCK_INTERVAL, false)
                        self.m_duckLast[i] = duck
                        table.insert(self.m_duckItemList[i], duck)
                    end
                end
            end
        end
    end)
end

function ColorfulCircusPickMainView:showDuckView()
    self.m_machine:setTopUIZOrder(true)
    self:setVisible(true)

    gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_duck_startPopupStart.mp3")
    self.m_startView:setVisible(true)
    self.m_startView:runCsbAction("idle")
    performWithDelay(self, function (  )
        self.m_isCanClickStartPopup = true
    end, 0.3)
    self:gameStart()
    self.m_status = GAME_STATUS.OVER
end

function ColorfulCircusPickMainView:hideDuckView()
    self.m_machine:setTopUIZOrder(false)
    self:setVisible(false)
    
end

function ColorfulCircusPickMainView:delDuckView(  )
    self:removeFromParent()
end

function ColorfulCircusPickMainView:beginDuckGame()
    
    
    -- performWithDelay(self, function()
        performWithDelay(self, function()
            if self.m_isStartViewOvering == false then
                self.m_isStartViewOvering = true

                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_duck_startPopupOver.mp3")
                self.m_startView:runCsbAction("over", false, function()
                    self.m_startView:setVisible(false)
                    self.m_status = GAME_STATUS.NORMAL
                end)
            end
            
        end, 1.5)
    -- end, 0.5)
end

function ColorfulCircusPickMainView:createOneDuck(_row, _posX, _isToLeft)
    local duck = util_createView("CodeColorfulCircusSrc.PickDuck.ColorfulCircusDuckView", self, _isToLeft)
    self.m_movePanel:addChild(duck)
    duck:setPositionY(self.m_posY[_row])
    duck:setPositionX(_posX)
    return duck
end

function ColorfulCircusPickMainView:resetOneDuck(_duck, _row, _posX, _isToLeft)
    _duck:resetDuck(_posX, self.m_posY[_row], _isToLeft)
end

--是否在可点击区域
function ColorfulCircusPickMainView:checkDuckCanTouch(_duck)
    if _duck and not tolua.isnull(_duck) then
        local posX = _duck:getPositionX()
        if posX < (0 + TOUCH_EDGE_DIS) or posX > (DUCK_PANEL_WIDTH - TOUCH_EDGE_DIS) then
            return false
        end
    end
    return true
end

function ColorfulCircusPickMainView:unscheduleDuckMove()
    if self.m_duckModeHandlerID then
        scheduler.unscheduleGlobal(self.m_duckModeHandlerID)
        self.m_duckModeHandlerID = nil
    end
end

function ColorfulCircusPickMainView:onEnter()
    ColorfulCircusPickMainView.super.onEnter(self)
end

function ColorfulCircusPickMainView:onExit()
    self:unscheduleDuckMove()
    gLobalNoticManager:removeAllObservers(self)
    ColorfulCircusPickMainView.super.onExit(self)
end


return ColorfulCircusPickMainView