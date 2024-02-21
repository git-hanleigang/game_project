---
--xcyy
--2018年5月23日
--FairyDragonMiniBgView.lua

local FairyDragonMiniBgView = class("FairyDragonMiniBgView", util_require("base.BaseView"))

FairyDragonMiniBgView.m_btnSpinStates = false

function FairyDragonMiniBgView:initUI(miniMachine)
    self:createCsbNode("FairyDragon_Jackpot_wanfa.csb")

    self.m_btnSpinStates = false


    self.m_miniMachine = miniMachine

    self.m_coinsTips = {}
    for i = 1, 8 do
        local tips = util_createView("FairyDragonSrc.FairyDragonJackpotCoinsTips")
        self:findChild("Node_" .. i):addChild(tips)
        self.m_coinsTips[i] = tips
    end
    for i = 1, 4 do
        local tips = util_createView("FairyDragonSrc.FairyDragonJackpotTips", i)
        self:findChild("jackpot" .. i):addChild(tips)
        
        self.m_coinsTips[8 + i] = tips
    end

    if self.m_miniMachine.m_parent.m_iBetLevel == 0 then
        self.m_coinsTips[12].m_jpGrandDarkImg:setVisible(true)
        self.m_coinsTips[12].m_jpGrandSuo:setVisible(true)
        self.m_coinsTips[12].m_jpGrandSuo:runCsbAction("actionframe",true)
    end
    

    self.m_lines = util_createView("FairyDragonSrc.FairyDragonWinCoinsLine")
    
    self:findChild("jinbi"):addChild(self.m_lines)
    for i = 25, 43 do
        self:findChild("line_" .. i):setVisible(false)
    end
    self.m_parMajor = self:findChild("Particle_major")
    self.m_parMinor = self:findChild("Particle_minor")
    self.m_parMini = self:findChild("Particle_mini")
    self.m_parMajor:setVisible(false)
    self.m_parMinor:setVisible(false)
    self.m_parMini:setVisible(false)

    self.m_startNum = 0
    self.m_allLines = 0
    self.m_showTag = 0  --当前阶段
    self.m_isUpdata = false
    self.m_nowWinTag = 0
    self.m_bMoving = false

    self.coinsEffect = util_createAnimation("FairyDragon_Jinbi2.csb")
    self:findChild("jinbiNode"):addChild(self.coinsEffect)
    self.coinsEffect:setVisible(false)
    -- self.coinsEffect:runCsbAction("actionframe",true)
    self.m_iUpdataTime = 0.5
end
function FairyDragonMiniBgView:initMachine(machine)
    self.m_machine = machine
end

function FairyDragonMiniBgView:onEnter()
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.1
    )
    schedule(
        self:findChild("rootNode"),
        function()
            self:updataAddLines()
        end,
        self.m_iUpdataTime
    )

    -- --点击了特殊spin按钮 监听
    gLobalNoticManager:addObserver(self,function(Target,params)
        self:quickStopBgCoinsCallFunc()
    end,ViewEventType.NOTIFY_LEVEL_CLICKED_SPECIAL_SPIN)

end

-- 更新jackpot 数值信息
--
function FairyDragonMiniBgView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self.m_coinsTips[12]:getLabNode(), 1)
    self:changeNode(self.m_coinsTips[11]:getLabNode(), 2)
    self:changeNode(self.m_coinsTips[10]:getLabNode(), 3)
    self:changeNode(self.m_coinsTips[9]:getLabNode(), 4)

    self:updateSize()
end

function FairyDragonMiniBgView:updateSize()
    local label1 = self.m_coinsTips[12]:getLabNode()
    local label2 = self.m_coinsTips[11]:getLabNode()
    local label3 = self.m_coinsTips[10]:getLabNode()
    local label4 = self.m_coinsTips[9]:getLabNode()
    self:updateLabelSize({label = label1, sx = 0.73, sy = 0.73}, 411)
    self:updateLabelSize({label = label2, sx = 0.73, sy = 0.73}, 411)
    self:updateLabelSize({label = label3, sx = 0.73, sy = 0.73}, 411)
    self:updateLabelSize({label = label4, sx = 0.73, sy = 0.73}, 411)
end

function FairyDragonMiniBgView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

function FairyDragonMiniBgView:onExit()

    gLobalNoticManager:removeAllObservers(self)
    
end

function FairyDragonMiniBgView:updataAddLines()
    if self.m_isUpdata == false then
        return
    end
    if self.m_startNum > self.m_allLines then
        return
    end
    if self.m_startNum < self.m_allLines then
        self.m_startNum = self.m_startNum + 1
    end
    local bNeedMove, iDis = self:isNeedMove()

    self.m_lines:showLines(self.m_startNum)
    
    if self.m_startNum == self.m_allLines then
        self.m_isUpdata = false
        if bNeedMove == false and self.m_bMoving == false then
            self.m_func()
            if self.m_showTag >= 9 then

                local currRsCount = self.m_miniMachine.m_runSpinResultData.p_reSpinCurCount or 0
                
                if currRsCount == 0 then
                    local jackpotIndex = 1
                    local isJackpot = false
                    local selfdata = self.m_miniMachine.m_runSpinResultData.p_selfMakeData
                    if selfdata.winType == "multiple" then
                    else
                        if selfdata.winType == "mini" then
                            jackpotIndex = 1
                        elseif selfdata.winType == "minor" then
                            jackpotIndex = 2
                        elseif selfdata.winType == "major" then
                            jackpotIndex = 3
                        elseif selfdata.winType == "grand" then
                            jackpotIndex = 4
                        end
                        isJackpot = true
                    end
                
                    if isJackpot then
                        self:playJackpotWinEffect(selfdata.winType)
                    end
                    
                    self.m_miniMachine.m_parent:clearCurMusicBg()

                    self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe2", true)
                   

                else

                    if self.m_showTag == 9 then
                        gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Mini_Tip.mp3")
                    elseif self.m_showTag == 10 then
                        gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Minor_Tip.mp3")
                    elseif self.m_showTag == 11 then
                        gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Major_Tip.mp3")
                    elseif self.m_showTag == 12 then
                        gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Grand_Tip.mp3")
                    end
                    
                    self.m_coinsTips[self.m_showTag]:runCsbAction(
                        "start",
                        false,
                        function()
                            self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe", true)
                        end
                    )
                end
            end


            if self.m_JinbiXiaLuo then
                gLobalSoundManager:stopAudio(self.m_JinbiXiaLuo)
                self.m_JinbiXiaLuo = nil
            end

            self.coinsEffect:setVisible(false)

            self.m_lines:findChild("jinbishengzhangzong"):setVisible(false)

        end
    end

    if bNeedMove then
        self:playBgMoveEffect(iDis)
    end
    
    local index = math.ceil(self.m_startNum / 3)
    if self.m_startNum <= 24 then
        if index > self.m_showTag then

            gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_KuangLiang.mp3")

            self.m_coinsTips[index]:runCsbAction("actionframe1")
            if self.m_showTag > 0 then
                self.m_coinsTips[self.m_showTag]:runCsbAction("actionframe2")
            end
            self.m_showTag = index
        end
    else
        if self.m_showTag == 8 then
            gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_KuangLiang.mp3")
            self.m_coinsTips[self.m_showTag]:runCsbAction("actionframe2")
        end

        if self.m_startNum <= 29 then
            if self.m_showTag < 9 then

                gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_Game_Level_".. 1 ..".mp3")
                self.m_showTag = 9
                self.m_coinsTips[self.m_showTag]:runCsbAction(
                    "idleframe2",
                    false,
                    function()
                        -- self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe", true)
                    end
                )
            end
            self.m_parMajor:setVisible(false)
            self.m_parMinor:setVisible(false)
            self.m_parMini:setVisible(true)
        elseif self.m_startNum <= 35 then
            if self.m_showTag < 10 then
                self.m_coinsTips[self.m_showTag]:runCsbAction("over", false)

                gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_Game_Level_".. 2 ..".mp3")

                self.m_showTag = 10
                self.m_coinsTips[self.m_showTag]:runCsbAction(
                    "idleframe2",
                    false,
                    function()
                        -- self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe", true)
                    end
                )
            end
            self.m_parMajor:setVisible(false)
            self.m_parMinor:setVisible(true)
            self.m_parMini:setVisible(false)
        elseif self.m_startNum <= 43 then
            if self.m_showTag < 11 then
                self.m_coinsTips[self.m_showTag]:runCsbAction("over", false)

                gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_Game_Level_".. 3 ..".mp3")

                self.m_showTag = 11
                self.m_coinsTips[self.m_showTag]:runCsbAction(
                    "idleframe2",
                    false,
                    function()
                        -- self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe", true)
                    end
                )
            end
            self.m_parMajor:setVisible(true)
            self.m_parMinor:setVisible(false)
            self.m_parMini:setVisible(false)
        else
            if self.m_showTag < 12 then
                self.m_coinsTips[self.m_showTag]:runCsbAction("over", false)

                gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_Game_Level_".. 4 ..".mp3")

                self.m_showTag = 12
                self.m_coinsTips[self.m_showTag]:runCsbAction(
                    "idleframe2",
                    false,
                    function()
                        -- self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe", true)
                    end
                )
            end
            self.m_parMajor:setVisible(false)
            self.m_parMinor:setVisible(false)
            self.m_parMini:setVisible(false)
        end
    end
end

function FairyDragonMiniBgView:showLines(_num)
    self.m_lines:showLines(_num)
    if _num > 24 then
        self:findChild("line_" .. _num):setVisible(true)
    end
end

function FairyDragonMiniBgView:initLowUI(data)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local j = 1
    for i = 12, 5, -1 do
        local bet = data[i]
        local curCoins = tonumber(bet) * totalBet
        self.m_coinsTips[j]:setTipsCoins(curCoins)
        j = j + 1
    end
end
--断线重连 重新设置当前进度
function FairyDragonMiniBgView:showNewLines(_num)
    self.m_lines:showNewLines(_num)

    if _num <= 24 then
        local index = math.ceil(_num / 3)
        for i = 1, 8 do
            if i == index then
                self.m_coinsTips[i]:runCsbAction("idle2")
            else
                self.m_coinsTips[i]:runCsbAction("idle1")
            end
        end
        self.m_showTag = index
    else
        if _num > 24 then
            for i = 25, _num do
                self:findChild("line_" .. i):setVisible(true)
            end
        end
        for i = 1, 8 do
            self.m_coinsTips[i]:runCsbAction("idle1")
        end
        if _num <= 29 then
            self.m_showTag = 9
            self.m_coinsTips[9]:runCsbAction("idleframe", true)
        elseif _num <= 35 then
            self.m_showTag = 10
            self.m_coinsTips[10]:runCsbAction("idleframe", true)
        elseif _num <= 43 then
            self.m_showTag = 11
            self.m_coinsTips[11]:runCsbAction("idleframe", true)
        else
            self.m_showTag = 11
            self.m_coinsTips[12]:runCsbAction("idleframe", true)
        end
    end
    self.m_startNum = _num
    self.m_allLines = _num
    local bNeedMove, iDis = self:isNeedMove()
    if bNeedMove then
        local startPos = cc.p(self:findChild("rootNode"):getPosition())
        local endPos = cc.p(startPos.x, startPos.y - iDis)
        self:findChild("rootNode"):setPosition(endPos)
    end
end

function FairyDragonMiniBgView:setLines(_num, _allLines, _func)
    self.m_iUpdataTime = 0.5
    self.m_startNum = _allLines - _num
    self.m_allLines = _allLines
    self.m_isUpdata = true
    self.m_func = function()

        self.m_btnSpinStates = false

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN)

        if _func then
            _func()
        end
    end
     
    if self.m_JinbiXiaLuo == nil then
        self.m_JinbiXiaLuo = gLobalSoundManager:playSound("FairyDragonSounds/FairyDragon_JPgame_Jinbi_Xialuo.mp3",true)
    end
    
    

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_SHOW_SPECIAL_SPIN) -- 显示特殊spin按钮

    self.m_btnSpinStates = true

    self.coinsEffect:setVisible(true)
    self.coinsEffect:runCsbAction("actionframe", true)

end

function FairyDragonMiniBgView:quickStopBgCoinsAct( _num )
    
    self.m_lines:showNewLines(_num)

    if _num <= 24 then
        local index = math.ceil(_num / 3)
        for i = 1, 8 do
            if i == index then
                self.m_coinsTips[i]:runCsbAction("idle2")
            else
                self.m_coinsTips[i]:runCsbAction("idle1")
            end
        end
        self.m_showTag = index
    else
        if _num > 24 then
            for i = 25, _num do
                self:findChild("line_" .. i):setVisible(true)
            end
        end
        for i = 1, 8 do
            self.m_coinsTips[i]:runCsbAction("idle1")
        end
        if _num <= 29 then
            self.m_showTag = 9
            self.m_coinsTips[9]:runCsbAction("idleframe", true)
        elseif _num <= 35 then
            self.m_showTag = 10
            self.m_coinsTips[10]:runCsbAction("idleframe", true)
        elseif _num <= 43 then
            self.m_showTag = 11
            self.m_coinsTips[11]:runCsbAction("idleframe", true)
        else
            self.m_showTag = 11
            self.m_coinsTips[12]:runCsbAction("idleframe", true)
        end
    end
    self.m_startNum = _num

    local bNeedMove, iDis = self:isNeedMove()
    if bNeedMove then
        local startPos = cc.p(self:findChild("rootNode"):getPosition())
        local endPos = cc.p(startPos.x, startPos.y - iDis)
        self:findChild("rootNode"):setPosition(endPos)
    end

end

function FairyDragonMiniBgView:isNeedMove()
    local allLines = self.m_startNum
    local tag = 0
    local dis = 0
    if allLines <= 24 then
        tag = math.ceil(allLines / 3)
    elseif allLines <= 29 then
        tag = 9
    elseif allLines <= 35 then
        tag = 10
    elseif allLines <= 43 then
        tag = 11
    else
        tag = 12
    end
    if tag > self.m_nowWinTag then
        if tag <= 6 then
            self.m_nowWinTag = tag
            return false, 0
        elseif tag <= 8 then
            dis = 25 * 3 * (tag - self.m_nowWinTag)
            if self.m_nowWinTag == 0 then
                dis = 25 * 3 * (tag - self.m_nowWinTag)
            elseif self.m_nowWinTag <= 6 then
                dis = dis + 25 * 3 * 2
            end
            self.m_nowWinTag = tag
            return true, dis
        else
            if self.m_nowWinTag == 0 then
                dis =  25*3*8 + 25*4*(tag - 8)
             else
                dis = 25 * 4 * (tag - self.m_nowWinTag)
            end
            self.m_nowWinTag = tag
            return true, dis
        end
    end

    return false, 0
end

function FairyDragonMiniBgView:playBgMoveEffect(_moveDis)
    self.m_bMoving = true
    local startPos = cc.p(self:findChild("rootNode"):getPosition())
    local endPos = cc.p(startPos.x, startPos.y - _moveDis)
    local dealy = cc.DelayTime:create(0.2)
    local moveTo = cc.MoveTo:create(1, endPos)
    local fun =
        cc.CallFunc:create(
        function()
            self.m_bMoving = false
            if self.m_isUpdata == false then
                if self.m_func then
                    if self.m_showTag >= 9 then
                        local currRsCount = self.m_miniMachine.m_runSpinResultData.p_reSpinCurCount or 0
                
                        if currRsCount == 0 then
                            local jackpotIndex = 1
                            local isJackpot = false
                            local selfdata = self.m_miniMachine.m_runSpinResultData.p_selfMakeData
                            if selfdata.winType == "multiple" then
                            else
                                if selfdata.winType == "mini" then
                                    jackpotIndex = 1
                                elseif selfdata.winType == "minor" then
                                    jackpotIndex = 2
                                elseif selfdata.winType == "major" then
                                    jackpotIndex = 3
                                elseif selfdata.winType == "grand" then
                                    jackpotIndex = 4
                                end
                                isJackpot = true
                            end
                        
                            if isJackpot then
                                self:playJackpotWinEffect(selfdata.winType)
                            end
                            

                            self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe2", true)
                         
                            self.m_miniMachine.m_parent:clearCurMusicBg()
                            
                        else

                            if self.m_showTag == 9 then
                                gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Mini_Tip.mp3")
                            elseif self.m_showTag == 10 then
                                gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Minor_Tip.mp3")
                            elseif self.m_showTag == 11 then
                                gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Major_Tip.mp3")
                            elseif self.m_showTag == 12 then
                                gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_Grand_Tip.mp3")
                            end
                            
                            self.m_coinsTips[self.m_showTag]:runCsbAction(
                                "start",
                                false,
                                function()
                                    self.m_coinsTips[self.m_showTag]:runCsbAction("idleframe", true)
                                end
                            )
                        end
   
                    end
                    self.m_func()


                    if self.m_JinbiXiaLuo then
                        gLobalSoundManager:stopAudio(self.m_JinbiXiaLuo)
                        self.m_JinbiXiaLuo = nil
                    end

                    self.coinsEffect:setVisible(false)

                    self.m_lines:findChild("jinbishengzhangzong"):setVisible(false)
                      
                end
            end
        end
    )
    self:findChild("rootNode"):runAction(cc.Sequence:create(dealy, moveTo, fun))
end

function FairyDragonMiniBgView:playJackpotWinEffect(winType)
    if self.m_showTag >= 9 then
        
        if winType == "major" then
            self:runCsbAction("idle_zi",true)
        elseif winType == "minor" then
            self:runCsbAction("idle_lan",true)
        elseif winType == "mini"  then
            self:runCsbAction("idle_lv",true)
        end

        gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_Jp_Game_WinTip.mp3")

    end
end

function FairyDragonMiniBgView:playGrandJackpotWinEffect(_func)

    if _func then
        _func()
    end

    -- if self.m_JinbiXiaLuo == nil then
    --     self.m_JinbiXiaLuo = gLobalSoundManager:playSound("FairyDragonSounds/FairyDragon_JPgame_Jinbi_Xialuo.mp3",true)
    -- end
    
    -- self.m_iUpdataTime = 0.01
    -- self.m_allLines = 44
    -- self.m_isUpdata = true
    -- self.coinsEffect:setVisible(true)
    -- self.coinsEffect:runCsbAction("actionframe", true)
    -- self.m_func = function()
    --     if _func then
    --         _func()
    --     end
    -- end
end

function FairyDragonMiniBgView:quickStopBgCoinsCallFunc( )
    
    if self.m_btnSpinStates then
        self.m_btnSpinStates = false

        if self.m_isUpdata then

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_CLOSE_SPECIAL_SPIN)

            if self.m_startNum < self.m_allLines - 1   then

                self:quickStopBgCoinsAct( self.m_allLines - 1 ) 

            end
            
        end
        
    end
    
end

--默认按钮监听回调
function FairyDragonMiniBgView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()


end
return FairyDragonMiniBgView
