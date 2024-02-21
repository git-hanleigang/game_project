---
--xcyy
--2018年5月23日
--LuckyRacingFreeGameView.lua

local LuckyRacingFreeGameView = class("LuckyRacingFreeGameView",util_require("base.BaseView"))

local RADIUS_HOURSE  =  {166,191,216,241}

local LENGTH        =       590 + 84

local LENGTH_HOURSE =   {1042,1200,1356,1513}

local DIRECTION_UP      =       1
local DIRECTION_RIGHT   =       2
local DIRECTION_DOWN    =       3
local DIRECTION_LEFT    =       4

local SECTION_COUNT     =       35

local SPINE_HOURSE_SKIN = {
    "huang",
    "zi",
    "lan",
    "lv",
    "hei",
}

local SPINE_WINNER_ANI = {
    "GuoChangKuang_yellow",
    "GuoChangKuang_purple",
    "GuoChangKuang_blue",
    "GuoChangKuang_green",
}

--第一次spin领先
local SOUND_FIRST_SPIN = {
    "LuckyRacingSounds/sound_LuckyRacing_fg_first_spin_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_first_spin_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_first_spin_blue.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_first_spin_green.mp3"
}

--过弯
local SOUND_INTO_THE_TURN = {
    "LuckyRacingSounds/sound_LuckyRacing_fg_into_the_turn_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_into_the_turn_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_into_the_turn_blue.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_into_the_turn_green.mp3"
}

--开始冲刺
local SOUND_START_SPRINT = {
    "LuckyRacingSounds/sound_LuckyRacing_fg_start_sprint_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_start_sprint_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_start_sprint_blue.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_start_sprint_green.mp3"
}

--成为第一名
local SOUND_BECOME_FIRST = {
    "LuckyRacingSounds/sound_LuckyRacing_fg_become_first_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_become_first_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_become_first_blue.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_become_first_green.mp3"
}

--最后一次spin
local SOUND_LAST_SPIN = {
    "LuckyRacingSounds/sound_LuckyRacing_fg_last_spin_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_last_spin_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_last_spin_blue.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_last_spin_green.mp3"
}

--最终赢家
local SOUND_WIN_HOURSE = {
    "LuckyRacingSounds/sound_LuckyRacing_fg_win_hourse_yellow.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_win_hourse_purple.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_win_hourse_blue.mp3",
    "LuckyRacingSounds/sound_LuckyRacing_fg_win_hourse_green.mp3"
}

LuckyRacingFreeGameView.m_sound_id = -1

function LuckyRacingFreeGameView:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("LuckyRacing/FreeGame.csb")

    self.m_sectionCount = SECTION_COUNT
    self.m_soundID_hourseMove = -1

    self.m_posView = util_createAnimation("LuckyRacingHoursePos.csb")
    self:findChild("root"):addChild(self.m_posView)
    self.m_posView:setVisible(false)

    self.m_downCount = 0
    self.m_isStart = false

    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 6)


    self.m_roomList = util_createAnimation("LuckyRacing_kuang.csb")
    self:findChild("kuang"):addChild(self.m_roomList)
    self.m_roomList.m_totalMutiples = 0

    self.m_mineScore = util_createAnimation("LuckyRacing_Mine.csb")
    if self.m_machine.m_isChangeScoreNode then
        self:findChild("mine_0"):addChild(self.m_mineScore)
    else
        self:findChild("mine"):addChild(self.m_mineScore)
    end
    
    self.m_mineScore.m_mutiples = 0

    --创建4个轮盘
    self.m_miniMachines = {}
    self.m_scoreItems = {}

    --落地音效
    self.m_soundScatterTips = {}

    self.m_heads = {}
    self.m_headNodes = {}
    self.m_chooseBg = {}
    self.m_jiantou = {}
    self.m_centerNodes = {}
    self.m_hourse = {}
    for index = 1,4 do
        local miniMachine = util_createView("CodeLuckyRacingSrc.CodeLuckyRacingSpecialReel.LuckyRacingMiniMachine",
        {parent = self.m_machine,index = index,parentView = self})
        self:findChild("qipan_"..(index - 1)):addChild(miniMachine)
        self.m_miniMachines[index] = miniMachine

        local jiantou = util_createAnimation("LuckyRacing_jiantou_0.csb")
        self:findChild("root"):addChild(jiantou,90)
        jiantou:setPosition(util_convertToNodeSpace(self:findChild("qipan_"..(index - 1)),self:findChild("root")))
        jiantou:setVisible(false)
        self.m_jiantou[index] = jiantou

        local scoreItem = util_createView("CodeLuckyRacingSrc.LuckyRacingScoreItem",{index = index})
        self:findChild("root"):addChild(scoreItem,100)
        -- scoreItem:setPosition(util_convertToNodeSpace(self:findChild("score_"..(index - 1)),self:findChild("root")))
        self.m_scoreItems[index] = scoreItem
        scoreItem:setVisible(false)

        --头像节点
        local headNode = cc.Node:create()
        self:findChild("root"):addChild(headNode,100)
        local headPos = util_convertToNodeSpace(self.m_roomList:findChild("touxiang_"..(index - 1)),self:findChild("root"))
        headNode:setPosition(headPos)
        self.m_headNodes[index] = headNode
        headNode.m_index = index
        headNode:setScale(self.m_roomList:findChild("touxiang_"..(index - 1)):getScale())

        local item = util_createView("CodeLuckyRacingSrc.LuckyRacingPlayerHead",{index = index})
        self.m_heads[index] = item
        headNode:addChild(item,10)

        local choose_bg = util_createAnimation("LuckyRacing_xuanzekuang.csb")
        choose_bg:runCsbAction("idleframe",true)
        headNode:addChild(choose_bg,5)
        choose_bg:setVisible(false)
        self.m_chooseBg[index] = choose_bg

        --中心点
        local centerPos = self:findChild("node_center_"..index)
        self.m_centerNodes[index] = centerPos

        --马
        local node_hourse = cc.Node:create()
        local hourse = util_spineCreate("Socre_LuckyRacing_fupao",true,true)
        util_spinePlay(hourse,"idleframe",false)
        hourse:setSkin(SPINE_HOURSE_SKIN[index])
        hourse.direction = DIRECTION_UP
        hourse.index = index
        node_hourse:addChild(hourse)
        self:findChild("root"):addChild(node_hourse)
        --需要经过的点
        hourse.m_points = {}

        --收集数量标签
        local lbl_count = util_createAnimation("LuckyRacing_XiaoQipan_1.csb")
        node_hourse:addChild(lbl_count)
        lbl_count:runCsbAction("idle")
        hourse.m_lbl_count = lbl_count
        hourse.m_lbl_count:setVisible(false)

        local startPos = util_convertToNodeSpace(self.m_posView:findChild("Node_"..index.."_1"),self:findChild("root"))
        hourse:getParent():setPosition(cc.p(self.m_centerNodes[1]:getPositionX() - RADIUS_HOURSE[index],startPos.y))
        hourse.stepCurr = 0
        self.m_hourse[index] = hourse
    end

end

--[[
    重置赛马信息
]]
function LuckyRacingFreeGameView:resetHourseInfo()
    for index = 1,4 do
        local hourse = self.m_hourse[index]
        hourse.direction = DIRECTION_UP
        hourse.stepCurr = 0
        hourse.runEnd = true
        hourse.m_isInTurn = false
        hourse.m_points = {}
        hourse.m_lbl_count:setVisible(false)
        local startPos = util_convertToNodeSpace(self.m_posView:findChild("Node_"..index.."_1"),self:findChild("root"))
        hourse:getParent():setPosition(cc.p(self.m_centerNodes[1]:getPositionX() - RADIUS_HOURSE[index],startPos.y))
        hourse.bonusCount = 0
        hourse:setRotation(0)
    end

    

end

--[[
    初始化界面信息
]]
function LuckyRacingFreeGameView:initViewInfo(result)
    self.m_curSpinIndex = 0
    self.m_resultData = result

    --将自己放在对应的战绩上
    local sets = self.m_resultData.data.sets
    local selfChair = 0
    for k,playerInfo in pairs(sets) do
        if playerInfo.udid == globalData.userRunData.userUdid then
            selfChair = playerInfo.chairId
        end
    end

    local userMultipleList = self.m_resultData.data.userMultipleList

    if self.m_machine.m_curSelect ~= selfChair then
        local temp = userMultipleList[tostring(selfChair)]
        userMultipleList[tostring(selfChair)] = userMultipleList[tostring(self.m_machine.m_curSelect)]
        userMultipleList[tostring(self.m_machine.m_curSelect)] = temp
    end

    self.m_roomList.m_totalMutiples = 0
    self.m_mineScore.m_mutiples = 0
    self.m_roomList:findChild("BitmapFontLabel_1"):setString("0")
    self.m_mineScore:findChild("BitmapFontLabel_1"):setString("0")
    self.m_rank = -1
    self:runCsbAction("idle")
    
    self:resetHourseInfo()
    self:refreshMutiples()
    self:refreshHead()
    for index = 1,4 do
        local miniMachine = self.m_miniMachines[index]
        miniMachine:hideLight()
        miniMachine:runIdleAni()

        self.m_jiantou[index]:setVisible(false)

        self.m_scoreItems[index]:resetBonusCount()
        self.m_headNodes[index].m_bonusCount = 0
        self.m_headNodes[index].m_isMe = false
        self.m_headNodes[index].m_rank = -1
        -- self.m_scoreItems[index]:setVisible(true)

        local scoreItem = self.m_scoreItems[index]
        if index == self.m_machine.m_curSelect + 1 then
            scoreItem:setLocalZOrder(110)
            self.m_headNodes[index]:setLocalZOrder(110)
        else
            scoreItem:setLocalZOrder(100 + index)
            self.m_headNodes[index]:setLocalZOrder(100 + index)
        end
    end
end

--[[
    开始游戏
]]
function LuckyRacingFreeGameView:startGame(func)
    self.m_endFunc = func

    --显示小轮盘的箭头
    local curChoose = self.m_machine.m_curSelect
    self.m_jiantou[curChoose + 1]:setVisible(true)
    self.m_jiantou[curChoose + 1]:runCsbAction("actionframe",false,function()
        self.m_jiantou[curChoose + 1]:runCsbAction("idleframe",true)
    end)
    for index = 1,4 do
        local miniMachine = self.m_miniMachines[index]
        miniMachine:setResultData(self.m_resultData)
        
        miniMachine:isSelfMachineAni(curChoose + 1 == index)
    end

    if self.m_isStart then
        return
    end
    self.m_isStart = true
    self.m_machine:delayCallBack(30 / 60,function()
        self:beginReel()
    end)
    -- self:endGame()
    
end

--[[
    开始转动
]]
function LuckyRacingFreeGameView:beginReel()
    self.m_downCount = 0
    self.m_curSpinIndex = self.m_curSpinIndex + 1
    for index = 1,4 do
        local miniMachine = self.m_miniMachines[index]
        miniMachine:beginMiniReel()
    end

    self.m_soundScatterTips = {}
end

--[[
    结束游戏
]]
function LuckyRacingFreeGameView:endGame()
    --判断是否马都停下了
    if self.m_soundID_hourseMove ~= -1 then
        gLobalSoundManager:stopAudio(self.m_soundID_hourseMove)
        self.m_soundID_hourseMove = -1
    end
    self.m_isStart = false
    self.m_machine:clearCurMusicBg()
    self:showWinnerAni(function()
        self.m_machine:delayCallBack(1,function()
            self:setVisible(false)
        end)
        
        self:showRankList(function()

            local winnerChairID = self.m_resultData.data.winnerChairId
            local playersInfo = self.m_resultData.data.sets
            local userMultiple = self.m_resultData.data.userMultiple
            local choose = self.m_machine.m_curSelect
            
            local selfInfo = nil
            for k,user in pairs(playersInfo) do
                if user.udid == globalData.userRunData.userUdid then
                    selfInfo = user
                    break
                end
            end

            local winMultiple = userMultiple[tostring(choose)]
            if winnerChairID == choose then
                winMultiple = self.m_resultData.data.winnerMultiple
            end

            local winScore = 0
            local winSpots = self.m_machine.m_roomData:getWinSpots()
            if winSpots and #winSpots > 0 then
                local winInfo = winSpots[#winSpots]
                winScore = winInfo.coins
            end
            local baseScore =  self.m_resultData.data.userScore[globalData.userRunData.userUdid]

            --检测是否获得大奖
            -- self.m_machine:checkFeatureOverTriggerBigWin(winScore, GameEffect.EFFECT_BONUS)
            -- self.m_machine:showWinCoinsView(baseScore,winMultiple,winScore,function()

                --领取奖励
                local gameName = self.m_machine:getNetWorkModuleName()
                local index = #winSpots - 1
                gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
                    function()
                        globalData.slotRunData.lastWinCoin = 0
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                            winScore, true, true
                        })
                    end,
                    function(errorCode, errorData)
                        
                    end
                )

                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                end
            -- end)
            
        end)
    end)
    
end

--[[
    转轮停止
]]
function LuckyRacingFreeGameView:slotReelDown()

    self.m_downCount = self.m_downCount + 1

    if self.m_downCount < 4 then
        return
    end


    --刷新当前收集的倍数
    -- self:refreshMutiples()

    --收集bonus图标
    self:collectBonusAni(function()
        self:refreshMutiples()
        self:collectBonusCount(function()
            --刷新马的位置
            self:refreshHoursePos()
            self:runSortAni()
            if self.m_curSpinIndex < self.m_resultData.data.freeSpinTimes then
                --开始下一次滚动
                self:beginReel()
            else
                --如果有马没跑到终点,等待所有马跑完再结束
                if self:isAllHourseMoveEnd() then
                    self:endGame()
                else
                    util_schedule(self,function()
                        if self:isAllHourseMoveEnd() then
                            self:stopAllActions()
                            self:endGame()
                        end
                    end,1)
                end
                
            end
        end)
        
    end)
end

--[[
    判断是否所有的马移动结束
]]
function LuckyRacingFreeGameView:isAllHourseMoveEnd()
    local isMoveEnd = true
    for index = 1,4 do
        local hourse = self.m_hourse[index]
        if not hourse.runEnd then
            isMoveEnd = false
            break
        end
    end

    return isMoveEnd
end

--[[
    排序动画
]]
function LuckyRacingFreeGameView:runSortAni()
    local temp = {}
    for index = 1,4 do
        temp[index] = self.m_headNodes[index]
    end
    table.sort(temp,function( a,b )
        return a.m_bonusCount > b.m_bonusCount
    end)

    --该颜色的马成为第一名
    if not temp[1].m_isMe and temp[1].m_rank ~= 1 and self.m_curSpinIndex ~= 1 then
        self:playSound(SOUND_BECOME_FIRST[temp[1].m_index],2)
    end

    for index = 1,4 do
        local endPos = util_convertToNodeSpace(self.m_roomList:findChild("touxiang_"..(index - 1)),self:findChild("root"))
        temp[index]:runAction(cc.EaseSineIn:create(cc.MoveTo:create(0.5,endPos)))
        if temp[index].m_isMe then
            --自己排名上升
            if self.m_rank ~= -1 and index < self.m_rank then
                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_smart_move.mp3")
            end
            self.m_rank = index
        end

        temp[index].m_rank = index
        
    end
    --第一次spin
    if self.m_curSpinIndex == 1 then
        self:playSound(SOUND_FIRST_SPIN[temp[1].m_index],2)
    end

    
end

--[[
    收集bonus动画
]]
function LuckyRacingFreeGameView:collectBonusAni(func)
    local maxCount = 0
    for index =1,4 do
        if #self.m_miniMachines[index].m_bonus_pool > maxCount then
            maxCount = #self.m_miniMachines[index].m_bonus_pool
        end

        self.m_headNodes[index].m_bonusCount = self.m_headNodes[index].m_bonusCount + #self.m_miniMachines[index].m_bonus_pool
    end
    self:collectNextBonus(maxCount,func)
end

--[[
    收集下一个bonus
]]
function LuckyRacingFreeGameView:collectNextBonus(count,func)
    -- self:runSortAni()
    if count <= 0 then
        if type(func) == "function" then
            func()
        end
        return 
    end

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_collect_bonus.mp3")

    for index = 1,4 do
        if #self.m_miniMachines[index].m_bonus_pool > 0 then

            self.m_scoreItems[index]:collectAni()
            local score = self.m_miniMachines[index].m_bonus_pool[1].m_score
            if score then
                self.m_roomList.m_totalMutiples = self.m_roomList.m_totalMutiples + score
                self.m_scoreItems[index]:addMultiples(score)

                if index == self.m_machine.m_curSelect + 1 then
                    self.m_mineScore.m_mutiples = self.m_mineScore.m_mutiples + score
                    --自己获得的倍数
                    self.m_mineScore:findChild("BitmapFontLabel_1"):setString("X"..self.m_mineScore.m_mutiples)
                    self.m_mineScore:runCsbAction("actionframe")
                    self.m_mineScore:findChild("Particle_1"):resetSystem()
                end
            end
        end
        self.m_miniMachines[index]:runCollectAni()
    end

    --房间总倍数
    self.m_roomList:findChild("BitmapFontLabel_1"):setString("X"..self.m_roomList.m_totalMutiples)
    self.m_roomList:runCsbAction("actionframe")
    self.m_roomList:findChild("Particle_1"):resetSystem()

    

    self.m_machine:delayCallBack(15 / 30,function()
        self:collectNextBonus(count - 1,func)
    end)
end

--[[
    刷新每个玩家获得的倍数
]]
function LuckyRacingFreeGameView:refreshMutiples()
    --计算当前倍数
    local multipleList = self.m_resultData.data.userMultipleList
    for index = 1,4 do
        if self.m_curSpinIndex > 0 then
            local multipleData = multipleList[tostring(index - 1)]
            local totalMutiple = 0
            for spinIndex = 1,self.m_curSpinIndex do
                for k,mutiple in pairs(multipleData[spinIndex]) do
                    totalMutiple = totalMutiple + mutiple
                end
            end
            self.m_scoreItems[index]:refreshMutiples(totalMutiple)
        else
            self.m_scoreItems[index]:refreshMutiples(0)
        end
        
    end
end

--[[
    判断是否在点在范围内
]]
function LuckyRacingFreeGameView:isContainPoint(pos1,pos2,radius)
    if not radius then
        radius = 5
    end
    if pos1.x + radius >= pos2.x and pos1.x - radius <= pos2.x and pos1.y + radius >= pos2.y and pos1.y - radius <= pos2.y then
        return true
    end

    return false
end

--[[
    马移动动作
]]
function LuckyRacingFreeGameView:hourseMove(hourse,bonusCount,curCount)

    --判断是否有新增bonus
    if hourse.bonusCount >= bonusCount  then
        return
    end
    
    hourse.bonusCount = bonusCount

    

    -- hourse:stopAllActions()
    local step = 3

    local radius = RADIUS_HOURSE[hourse.index]
    local stepInCircle = radius / (2 * math.pi * radius / 4 / step) 

    hourse.runEnd = false
    util_spinePlay(hourse,"actionframe",true)
    util_schedule(hourse,function()

        local startPos = cc.p(hourse:getParent():getPosition())
        local centerNode = self.m_centerNodes[hourse.direction]
        local centerPos = cc.p(centerNode:getPosition())
        
        local direction = hourse.direction
        --设置马的位置
        if direction == DIRECTION_UP then
            
            --处于弧线时更新X坐标
            if hourse.stepCurr > 0 or self:isInCircle(startPos,centerNode,direction) then
                if not hourse.m_isInTurn then
                    self:playSound(SOUND_INTO_THE_TURN[hourse.index],2)
                end
                --开始过弯
                hourse.m_isInTurn = true
                local startCirclePos = cc.p(centerPos.x - radius,centerPos.y)
                hourse.stepCurr = hourse.stepCurr + step
                -- 弧长公式 L=n× π× r/180
                local angleCircle = hourse.stepCurr / (math.pi *radius/180 )
                local addX =  radius - math.cos(angleCircle * math.pi / 180) * radius
                local addY =  math.sin(angleCircle * math.pi / 180) * radius 

                --刷新Y坐标
                local posY = startCirclePos.y + addY
                hourse:getParent():setPositionY(posY)
                local posX = self:getCirclePosX(hourse:getParent(),centerNode,radius)
                hourse:getParent():setPositionX(posX)

                local angle = self:getAngle(cc.p(posX,posY),centerPos)
                hourse:setRotation(angle)

                --更新坐标后判断是否还在圆弧内
                if hourse.stepCurr >= radius * math.pi * 2 / 4 then
                    hourse.m_isInTurn = false
                    --修改方向
                    hourse.direction = DIRECTION_RIGHT
                    hourse:getParent():setPosition(cc.p(centerPos.x,centerPos.y + radius) )

                    hourse:setRotation(90)
                    hourse.stepCurr = 0
                end
            else
                --刷新Y坐标
                local posY = startPos.y + step
                hourse:getParent():setPositionY(posY)
            end

            
        elseif direction == DIRECTION_RIGHT then
            
            --处于弧线时更新X坐标
            if hourse.stepCurr > 0 or self:isInCircle(startPos,centerNode,direction) then
                if not hourse.m_isInTurn then
                    self:playSound(SOUND_INTO_THE_TURN[hourse.index],2)
                end
                --开始过弯
                hourse.m_isInTurn = true
                local startCirclePos = cc.p(centerPos.x,centerPos.y + radius)
                hourse.stepCurr = hourse.stepCurr + step

                -- 弧长公式 L=n× π× r/180
                local angleCircle = hourse.stepCurr / (math.pi * radius / 180 )
                local addX =  math.sin(angleCircle * math.pi / 180) * radius 
                local addY =  radius - math.cos(angleCircle * math.pi / 180) * radius

                --刷新X坐标
                local posX = startCirclePos.x + addX
                hourse:getParent():setPositionX(posX)
                local posY = self:getCirclePosY(hourse:getParent(),centerNode,radius)
                hourse:getParent():setPositionY(posY)

                local angle = self:getAngle(cc.p(posX,posY),centerPos)
                hourse:setRotation(angle)

                --更新坐标后判断是否还在圆弧内
                if hourse.stepCurr >= radius * math.pi * 2 / 4 then
                    hourse.m_isInTurn = false
                    --修改方向
                    hourse.direction = DIRECTION_DOWN
                    hourse:getParent():setPosition(cc.p(centerPos.x + radius,centerPos.y) )
                    hourse:setRotation(180)
                    hourse.stepCurr = 0
                end
            else
                --刷新X坐标
                local posX = startPos.x + step
                hourse:getParent():setPositionX(posX)
            end
        elseif direction == DIRECTION_DOWN then
            
            --处于弧线时更新X坐标
            if hourse.stepCurr > 0 or self:isInCircle(startPos,centerNode,direction) then
                if not hourse.m_isInTurn then
                    self:playSound(SOUND_INTO_THE_TURN[hourse.index],2)
                end
                --开始过弯
                hourse.m_isInTurn = true
                local startCirclePos = cc.p(centerPos.x + radius,centerPos.y)
                hourse.stepCurr = hourse.stepCurr + step
                -- 弧长公式 L=n× π× r/180
                local angleCircle = hourse.stepCurr / (math.pi *radius/180 )
                local addX =  radius - math.cos(angleCircle * math.pi / 180) * radius

                local addY =  math.sin(angleCircle * math.pi / 180) * radius 

                --刷新Y坐标
                local posY = startCirclePos.y - addY
                hourse:getParent():setPositionY(posY)
                local posX = self:getCirclePosX(hourse:getParent(),centerNode,radius)
                hourse:getParent():setPositionX(posX)

                local angle = self:getAngle(cc.p(posX,posY),centerPos)
                hourse:setRotation(angle)

                --更新坐标后判断是否还在圆弧内
                if hourse.stepCurr >= radius * math.pi * 2 / 4 then
                    hourse.m_isInTurn = false
                    --修改方向
                    hourse.direction = DIRECTION_LEFT
                    hourse:getParent():setPosition(cc.p(centerPos.x,centerPos.y - radius) )
                    hourse:setRotation(270)

                    hourse.stepCurr = 0
                end
            else
                --刷新Y坐标
                local posY = startPos.y - step
                hourse:getParent():setPositionY(posY)
            end
        elseif direction == DIRECTION_LEFT then
            
            --处于弧线时更新X坐标
            if hourse.stepCurr > 0 or self:isInCircle(startPos,centerNode,direction) then
                if not hourse.m_isInTurn then
                    self:playSound(SOUND_INTO_THE_TURN[hourse.index],2)
                end
                --开始过弯
                hourse.m_isInTurn = true
                local startCirclePos = cc.p(centerPos.x,centerPos.y - radius)
                hourse.stepCurr = hourse.stepCurr + step

                -- 弧长公式 L=n× π× r/180
                local angleCircle = hourse.stepCurr / (math.pi * radius / 180 )
                local addX =  math.sin(angleCircle * math.pi / 180) * radius 
                local addY =  radius - math.cos(angleCircle * math.pi / 180) * radius

                --刷新X坐标
                local posX = startCirclePos.x - addX
                hourse:getParent():setPositionX(posX)
                local posY = self:getCirclePosY(hourse:getParent(),centerNode,radius)
                hourse:getParent():setPositionY(posY)

                local angle = self:getAngle(cc.p(posX,posY),centerPos)
                hourse:setRotation(angle)

                --更新坐标后判断是否还在圆弧内
                if hourse.stepCurr >= radius * math.pi * 2 / 4 then
                    hourse.m_isInTurn = false
                    --修改方向
                    hourse.direction = DIRECTION_UP
                    hourse:getParent():setPosition(cc.p(centerPos.x - radius,centerPos.y))
                    hourse:setRotation(0)

                    hourse.stepCurr = 0
                end
            else
                --刷新X坐标
                local posX = startPos.x - step
                hourse:getParent():setPositionX(posX)
            end
        end

        --移除已经经过的点
        self:removeCurPos(hourse)
        --判断是否到达终点
        local endPos = self:getEndPos(hourse.bonusCount,hourse.index)
        local curPos = cc.p(hourse:getParent():getPosition()) 
        if self:isContainPoint(curPos,endPos) then
            hourse.runEnd = true
            hourse:stopAllActions()
            util_spinePlay(hourse,"idleframe",false)

            if hourse.bonusCount >= SECTION_COUNT then
                hourse.m_lbl_count:setVisible(false)
                
                self:runCsbAction("actionframe",false,function()
                    self:runCsbAction("idle")
                end)
            end

            --判断是否马都停下了
            if hourse.index == self.m_machine.m_curSelect + 1 and self.m_soundID_hourseMove ~= -1 then
                gLobalSoundManager:stopAudio(self.m_soundID_hourseMove)
                self.m_soundID_hourseMove = -1
            end
        end
    end,1 / 120)
end

--[[
    移除经过的点
]]
function LuckyRacingFreeGameView:removeCurPos(hourse)
    local pos = hourse.m_points[1]
    if not pos then
        return
    end
    local curPos = cc.p(hourse:getParent():getPosition()) 
    if self:isContainPoint(curPos,pos) then
        table.remove(hourse.m_points,1)
        if #hourse.m_points <= 0 then
            hourse.m_lbl_count:setVisible(false)
        end
        hourse.m_lbl_count:findChild("BitmapFontLabel_1"):setString("+"..(#hourse.m_points))
    end
end

--[[
    刷新马的位置
]]
function LuckyRacingFreeGameView:refreshHoursePos()
    --当前spin次数
    local curSpinIndex = self.m_curSpinIndex

    for index = 1,4 do
        --获取当前倍数列表
        local mutipleList = self.m_resultData.data.userMultipleList[tostring(index - 1)]
        local hourse = self.m_hourse[index]
        
        --本次获得的bonus数量
        local bonusCount = 0
        for spinIndex = 1, curSpinIndex do
            local multiples = mutipleList[spinIndex]
            bonusCount = bonusCount + #multiples
        end
        local addCount = #mutipleList[curSpinIndex]

        --最终冲刺
        if bonusCount >= self.m_sectionCount then
            self:playSound(SOUND_LAST_SPIN[index],2.3)
        end

        --开始冲刺
        if addCount >= 8 then
            self:playSound(SOUND_START_SPRINT[index],3)
        end

        --计算当前需增加的点
        self:addPoints(hourse,index,bonusCount,addCount)

        if index == self.m_machine.m_curSelect + 1 then
            if self.m_soundID_hourseMove ~= -1 then
                gLobalSoundManager:stopAudio(self.m_soundID_hourseMove)
                self.m_soundID_hourseMove = -1
            end
            self.m_soundID_hourseMove = gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_hourse_run.mp3",true)
        end

        if hourse.runEnd then
            self:hourseMove(hourse,bonusCount)
        else
            hourse.bonusCount = bonusCount
        end
    end
end

--[[
    计算当前需增加的经过点
]]
function LuckyRacingFreeGameView:addPoints(hourse,index,bonusCount,addCount)
    for startIndex = bonusCount - addCount + 1,bonusCount do
        local node =  self.m_posView:findChild("Node_"..index.."_"..(startIndex + 1))
        local pos = util_convertToNodeSpace(node,self:findChild("root"))
        table.insert(hourse.m_points,#hourse.m_points + 1,pos)
    end
    
end

--[[
    获取终点坐标
]]
function LuckyRacingFreeGameView:getEndPos(bonusCount,index)
    if bonusCount >= SECTION_COUNT then
        bonusCount = SECTION_COUNT
    end
    local endNode = self.m_posView:findChild("Node_"..index.."_"..(bonusCount + 1))

    local endPos = util_convertToNodeSpace(endNode,self:findChild("root"))
    return endPos
end

--[[
    刷新头像
]]
function LuckyRacingFreeGameView:refreshHead()
    local playersInfo = clone(self.m_resultData.data.sets)

    --当前选的马
    local curChoose = self.m_machine.m_curSelect
    if not curChoose or curChoose == -1 then
        curChoose = 0
    end

    --将自己放在对应颜色的座位上
    for index = 1,4 do
        local info = playersInfo[index]
        if info and info.udid == globalData.userRunData.userUdid and index ~= curChoose + 1 then
            local temp = playersInfo[index]
            playersInfo[index] = playersInfo[curChoose + 1]
            playersInfo[curChoose + 1] = temp
            break
        end
    end

    for index = 1,4 do
        local info = playersInfo[index]
        local item = self.m_heads[index]

        --刷新头像
        item:refreshData(info)
        item:refreshHead(true)

        local scale = self.m_roomList:findChild("touxiang_"..(index - 1)):getScale()
        local bg = self.m_chooseBg[index]
        if item:isMyself() then
            bg:setVisible(true)
            item.m_isMe = true


            self.m_headNodes[index]:setScale(scale * 1.1)
        else
            bg:setVisible(false)
            self.m_headNodes[index]:setScale(scale)
        end
    end
end

--[[
    判断当前马在某一弧度范围内
]]
function LuckyRacingFreeGameView:isInCircle(pos,centerPoint,direction)
    local centerPos = cc.p(centerPoint:getPosition())
    if direction == DIRECTION_UP and pos.x < centerPos.x and pos.y >= centerPos.y then
        return true
    elseif direction == DIRECTION_RIGHT and pos.x >= centerPos.x and pos.y > centerPos.y  then
        return true
    elseif direction == DIRECTION_DOWN and pos.x > centerPos.x and pos.y <= centerPos.y  then
        return true
    elseif direction == DIRECTION_LEFT and pos.x <= centerPos.x and pos.y < centerPos.y  then
        return true
    end
    return false
end

--[[
    获取Y坐标
]]
function LuckyRacingFreeGameView:getCirclePosY(target,centerPoint,radius)
    local pos = cc.p(target:getPosition())
    local centerPos = cc.p(centerPoint:getPosition())
    if pos.y < centerPos.y then
        return -math.sqrt(math.abs(radius * radius - (pos.x - centerPos.x) * (pos.x - centerPos.x))) + centerPos.y
    else
        return math.sqrt(math.abs(radius * radius - (pos.x - centerPos.x) * (pos.x - centerPos.x))) + centerPos.y
    end
end

--[[
    获取X坐标
]]
function LuckyRacingFreeGameView:getCirclePosX(target,centerPoint,radius)
    local pos = cc.p(target:getPosition())
    local centerPos = cc.p(centerPoint:getPosition())
    if pos.x < centerPos.x then
        return -math.sqrt(math.abs(radius * radius - (pos.y - centerPos.y) * (pos.y - centerPos.y)) ) + centerPos.x
    else
        return math.sqrt(math.abs(radius * radius - (pos.y - centerPos.y) * (pos.y - centerPos.y))) + centerPos.x
    end
end

--[[
    获取偏转角度
]]
function LuckyRacingFreeGameView:getAngle(startPos,endPos)
    local angle = -util_getAngleByPos(startPos,endPos)
    return angle
end

--[[
    显示赢家动画
]]
function LuckyRacingFreeGameView:showWinnerAni(func)
    local winner = 1

    --获取赢家
    for index = 1,4 do
        if self.m_scoreItems[index].m_bonusCount >= self.m_resultData.data.collectMax then
            winner = index
            break
        end
    end

    self:playSound(SOUND_WIN_HOURSE[winner],3)
    self.m_machine:showWinnerView(winner,func)
end

--[[
    显示排行榜
]]
function LuckyRacingFreeGameView:showRankList(func)
    local choose = self.m_machine.m_curSelect
    local winnerChairID = self.m_resultData.data.winnerChairId
    local isSelfWin = false
    local playersInfo = self.m_resultData.data.sets
    local userMultiple = {}
    local winnerMultiple = self.m_resultData.data.winnerMultiple

    local winScore = 0
    local winSpots = self.m_machine.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local winInfo = winSpots[#winSpots]
        winScore = winInfo.coins
    end

    for k,multiples in pairs(self.m_resultData.data.userMultiple) do
        table.insert(userMultiple,1,multiples)
    end
    table.sort(userMultiple,function(a,b)
        return a > b
    end)

    local bonusCountInfo = {}
    for index = 1,4 do
        --倍数列表
        local mutipleList = self.m_resultData.data.userMultipleList[tostring(index - 1)]
        
        --本次获得的bonus数量
        local bonusCount = 0
        for k,multiples in pairs(mutipleList) do
            bonusCount = bonusCount + #multiples
        end
        bonusCountInfo[index] = {
            index = index,
            bonusCount = bonusCount
        }
    end

    table.sort(bonusCountInfo,function(a,b)
        return a.bonusCount > b.bonusCount
    end)

    local view = util_createView("CodeLuckyRacingSrc.LuckyRacingRankListView",{
        playersInfo = playersInfo,
        winnerChairID = winnerChairID,
        choose = choose,
        userMultiple = userMultiple,
        winnerMultiple = winnerMultiple,
        bonusCountInfo = bonusCountInfo,
        winScore = winScore,
        mineScore = self.m_machine.m_collectScore,
        lbl_total = self.m_roomList:findChild("BitmapFontLabel_1"),
        scoreItem = self.m_heads[bonusCountInfo[1].index],
        callBack = function()
            if type(func) == "function" then
                func()
            end
        end
    })

    view:findChild("root"):setScale(self.m_machine.m_machineRootScale)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    gLobalViewManager:showUI(view)
end

--[[
    收集bonus数量
]]
function LuckyRacingFreeGameView:collectBonusCount(func)
    if self.m_curSpinIndex == 0 then
        return
    end
    if self.m_curSpinIndex > self.m_resultData.data.freeSpinTimes then
        self.m_curSpinIndex = self.m_resultData.data.freeSpinTimes
    end
    local ani1 = util_createAnimation("LuckyRacing_XiaoQipan_0.csb")
    self.m_effectNode:addChild(ani1)
    local curSelect = self.m_machine.m_curSelect

    local data = self.m_resultData.data

    
    --获取当前倍数列表
    local mutipleList = self.m_resultData.data.userMultipleList[tostring(curSelect)]

    if not mutipleList then
        release_print("---------------LuckyRacing curSelect:"..curSelect..",curSpinIndex:"..self.m_curSpinIndex)
        release_print("---------------LuckyRacing udid:"..globalData.userRunData.userUdid)
        release_print("---------------LuckyRacing mutipleList is nil")
    end

    --本次获得的bonus数量
    local curCount = #mutipleList[self.m_curSpinIndex]
    ani1:findChild("BitmapFontLabel_1"):setString("+"..curCount)

    local hourse = self.m_hourse[curSelect + 1]
    local endPos = util_convertToNodeSpace(hourse,self.m_effectNode)

    local tuowei = util_createAnimation("LuckyRacing_shouji_tuowei.csb")
    for index = 1,6 do
        tuowei:findChild("Particle_"..index):setPositionType(0)
        tuowei:findChild("Particle_"..index):setDuration(-1)
    end

    ani1:findChild("node_tuowei"):addChild(tuowei)

    ani1:setPosition(util_convertToNodeSpace(self.m_miniMachines[curSelect + 1],self.m_effectNode))

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_show_number.mp3")
    ani1:runCsbAction("start",false,function()
        ani1:runCsbAction("over")
        local seq = cc.Sequence:create({
            cc.MoveTo:create(0.5,endPos),
            cc.CallFunc:create(function()
                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_fly_feed_back.mp3")
                self:showColloctCount(func)

                for index = 1,6 do
                    local particle = tuowei:findChild("Particle_"..index)
                    if particle then
                        particle:stopSystem()
                    end
                end
                ani1:findChild("Node_2"):setVisible(false)
            end),
            cc.DelayTime:create(1),
            cc.RemoveSelf:create()
        })
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_fly_number.mp3")
        ani1:runAction(seq)
    end)
end

--[[
    显示所有马收集的数量
]]
function LuckyRacingFreeGameView:showColloctCount(func)
    for index = 1,4 do
        --获取当前倍数列表
        local mutipleList = self.m_resultData.data.userMultipleList[tostring(index - 1)]
        --本次获得的bonus数量
        local curCount = #mutipleList[self.m_curSpinIndex]

        local hourse = self.m_hourse[index]
        local endPos = util_convertToNodeSpace(hourse.m_lbl_count,self.m_effectNode)

        local ani2 = util_createAnimation("LuckyRacing_XiaoQipan_1.csb")
        ani2:findChild("BitmapFontLabel_1"):setString("+"..curCount)
        hourse.m_lbl_count:findChild("BitmapFontLabel_1"):setString("+"..(curCount + #hourse.m_points))
        hourse.m_lbl_count:setVisible(false)
        self.m_effectNode:addChild(ani2)
        ani2:setPosition(endPos)

        local aniName = self.m_machine.m_curSelect == (index - 1) and "actionframe" or "actionframe2"

        ani2:runCsbAction(aniName,false,function()
            hourse.m_lbl_count:setVisible(true)
            ani2:removeFromParent()
            
        end)
    end
    
    self.m_machine:delayCallBack(30 / 60,func)
end

--[[
    播放音效
]]
function LuckyRacingFreeGameView:playSound(soundName,time)
    if self.m_sound_id and self.m_sound_id ~= -1 then
        return
    end

    if not time then
        time = 1
    end

    self.m_sound_id = gLobalSoundManager:playSound(soundName)
    self.m_machine:delayCallBack(time,function()
        self.m_sound_id = -1
    end)
end

--[[
    飞粒子动画
]]
function LuckyRacingFreeGameView:flyParticleAni(startNode,endNode,func)
    local ani = util_createAnimation("LuckyRacing_shouji_tuowei.csb")
    for index = 1,6 do
        ani:findChild("Particle_"..index):setPositionType(0)
        ani:findChild("Particle_"..index):setDuration(-1)
    end
    self.m_effectNode:addChild(ani)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    ani:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(20 / 60,endPos),
        cc.CallFunc:create(function(  )
            for index = 1,6 do
                ani:findChild("Particle_"..index):stopSystem()
            end
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_fg_fly_number.mp3")
    ani:runAction(seq)
    return ani
end

---
-- 每个reel条滚动到底
function LuckyRacingFreeGameView:slotOneReelDown(machineIndex,reelCol)
    local reelIndex = reelCol
    if machineIndex == 2 or machineIndex == 4 then
        reelIndex = reelCol + 3
    end
    
    if self.m_soundScatterTips[reelIndex] then
        return
    end
    self.m_soundScatterTips[reelIndex] = true
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scatter_tip.mp3")
end


return LuckyRacingFreeGameView