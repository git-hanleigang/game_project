---
--xcyy
--2018年5月23日
--KenoBonusGameView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseGame = util_require("base.BaseGame")
local KenoBonusGameView = class("KenoBonusGameView",BaseGame )

KenoBonusGameView.m_machine = nil
KenoBonusGameView.m_paytable = {} -- 存放paytable节点
KenoBonusGameView.m_paytable_tx = {}
KenoBonusGameView.m_numNode = {} -- 存放80个数字节点
KenoBonusGameView.m_numNodeName = {"baise", "hongse", "lvse", "huangse", "+1draw", "baoxiang"} -- 存放数字节点上面的节点名字
KenoBonusGameView.m_selectNumId = {} -- 存放选择的数字 最多十个 

function KenoBonusGameView:initUI(machine)
    self.m_selectNumId = {}
    self.m_isSetGuide = false--是否正在走引导
    self.m_isBeginstart = false --是否已经点击了start开始按钮，点击之后不能在选择号码
    self.m_kenoSpinNum = 10 --keno玩法默认10次(剩余次数)
    self.m_zhongJiangSpin = {} --每轮中奖号码
    self.m_kenoSelfData = nil --每次spin的数据
    self.m_kenoProtectLoc = {} -- super Keno时必中的4个
    self.m_superEgg = {}--super 提前创建的4个蛋
    self.m_winAmount = 0 --当前spin赢钱

    self.m_machine = machine

    self:createCsbNode("Keno/GameScreenKenoBoard.csb")

    -- 初始化paytable
    for paytableIndex = 4, 10 do
        self.m_paytable[paytableIndex] = util_createAnimation("Keno_Paytable.csb")
        self:findChild("Node_pay_"..paytableIndex):addChild(self.m_paytable[paytableIndex])
        
        self.m_paytable_tx[paytableIndex] = util_createAnimation("Keno_kenowin_tx.csb")
        self:findChild("Node_kenowin_"..paytableIndex):addChild(self.m_paytable_tx[paytableIndex])
        self.m_paytable_tx[paytableIndex]:setVisible(false)
    end

    -- 初始化数字80个
    for numIndex = 1, 80 do
        self.m_numNode[numIndex] = util_createAnimation("Keno_Num.csb")
        self:findChild("Node_"..numIndex):addChild(self.m_numNode[numIndex])
        self.m_numNode[numIndex]:runCsbAction("idleframe",true)
        
        self:setShowNumNode(numIndex, 1)
        local layoutClick = self.m_numNode[numIndex]:findChild("Panel_1")
        layoutClick:setTag(numIndex)
        self:addClick(layoutClick)
    end

    self.m_spinLeftNode = util_createAnimation("Keno_SpinLeft.csb")
    self:findChild("Node_SpinLeft"):addChild(self.m_spinLeftNode)

    self:findChild("m_lb_coins"):setString(util_formatCoins(0,30))
    self:findChild("m_lb_coins"):setVisible(false)

    -- 母鸡
    self.m_mujiSpine = util_spineCreate("Socre_Keno_Scatter", true, true)
    self:findChild("mujispine"):addChild(self.m_mujiSpine,10)

    --主要会挂载一些动效相关的节点
    self.m_effect_node = cc.Node:create()
    self.m_effect_node:setPosition(display.width * 0.5, display.height * 0.5)
    self:findChild("root"):addChild(self.m_effect_node, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
end

-- 处理paytable显示
-- 1红色2白色3黄色
function KenoBonusGameView:setShowPayTable(index, color, num, coins)
    for i=1,3 do
        if i ~= 2 then
            self.m_paytable[index]:findChild("m_lb_pay_"..i):setVisible(false)
            self.m_paytable[index]:findChild("m_lb_num_"..i):setVisible(false)
            if num and coins then
                self.m_paytable[index]:findChild("m_lb_pay_"..i):setString(coins)
                self.m_paytable[index]:findChild("m_lb_num_"..i):setString(num)

                local label1=self.m_paytable[index]:findChild("m_lb_pay_"..i)
                local info1={label=label1,sx=0.88,sy=0.88}
                self:updateLabelSize(info1,240)
            end
        end
    end
    self.m_paytable[index]:findChild("m_lb_pay_"..color):setVisible(true)
    self.m_paytable[index]:findChild("m_lb_num_"..color):setVisible(true)
end

-- 处理80个数字节点显示
-- index表示位置ID
function KenoBonusGameView:setShowNumNode(index, nodeNameID)
    for k,vName in pairs(self.m_numNodeName) do
        self.m_numNode[index]:findChild(vName):setVisible(false)
    end 
    self.m_numNode[index]:findChild(self.m_numNodeName[nodeNameID]):setVisible(true)
    if nodeNameID <= 3 then
        local bgImage = self.m_numNode[index]:findChild(self.m_numNodeName[nodeNameID])
        local path = "Common/KenoNum/Keno_xiyouxi_".. self.m_numNodeName[nodeNameID] .. index ..".png"
        util_changeTexture(bgImage,path)
    end
    if nodeNameID == 6 then
        self.m_numNode[index]:runCsbAction("start",false,function(  )
            self.m_numNode[index]:runCsbAction("idle",true)
        end)
    end
end

-- 点击函数
function KenoBonusGameView:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()
    -- 走引导的时候 不可点击
    if self.m_isSetGuide then
        return
    end
    -- 已经开始start 不可点击
    if self.m_isBeginstart then
        return 
    end

    if name == "Panel_1" then
        if self:getIsHavedSelect(tag) then
            local isSelect, selectIndex = self:getIsHavedSelect(tag)
            self:setShowNumNode(tag, 1)
            table.remove(self.m_selectNumId, selectIndex)
            globalData.slotRunData.kenoData_selectNumId = self.m_selectNumId
            -- 每次选择之后 刷新数字
            self:findChild("m_lb_marked"):setString(#self.m_selectNumId)
            if #self.m_selectNumId <= 0 then
                self:findChild("Button_erase"):setBright(false)
                self:findChild("Button_erase"):setTouchEnabled(false)
            end
        else
            if #self.m_selectNumId >= 10 then
                return -- 超过10个 不能在选择
            end

            gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_select.mp3")
            self:setShowNumNode(tag, 3)
            table.insert(self.m_selectNumId, tag)
            globalData.slotRunData.kenoData_selectNumId = self.m_selectNumId
            -- 每次选择之后 刷新数字
            self:findChild("m_lb_marked"):setString(#self.m_selectNumId)

            self:findChild("Button_erase"):setBright(true)
            self:findChild("Button_erase"):setTouchEnabled(true)
        end
        if #self.m_selectNumId >= 10 then
            self:findChild("Button_quick"):setBright(false)
            self:findChild("Button_quick"):setTouchEnabled(false)
            self:findChild("Button_start"):setBright(true)
            self:findChild("Button_start"):setTouchEnabled(true)
        else
            self:findChild("Button_quick"):setBright(true)
            self:findChild("Button_quick"):setTouchEnabled(true)
            self:findChild("Button_start"):setBright(false)
            self:findChild("Button_start"):setTouchEnabled(false)
        end
    elseif name == "Button_quick" then
        gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_click.mp3")
        self:clickBtnQuickPick()
        self:findChild("Button_start"):setBright(true)
        self:findChild("Button_start"):setTouchEnabled(true)
        self:findChild("Button_erase"):setBright(true)
        self:findChild("Button_erase"):setTouchEnabled(true)
    elseif name == "Button_erase" then
        gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_click.mp3")
        self:clickBtnErase()
        self:findChild("Button_start"):setBright(false)
        self:findChild("Button_start"):setTouchEnabled(false)
    elseif name == "Button_start" then
        gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_click.mp3")
        self:nextCliackStartSend()
    end
end

-- 判断点击的数字 是否已经选择了 已经选择的话 再次点击为取消选择
function KenoBonusGameView:getIsHavedSelect(tag)
    for i,v in ipairs(self.m_selectNumId) do
        if tag == v then
            return true, i
        end
    end
    return false, nil
end

function KenoBonusGameView:onEnter()
    BaseGame.onEnter(self)
    
end
function KenoBonusGameView:onExit()
    scheduler.unschedulesByTargetName("KenoBonusGameView")
    BaseGame.onExit(self)

end

-- 金币适配
function KenoBonusGameView:updateSizeJinBi()
    local label1=self:findChild("m_lb_coins")
    local info1={label=label1,sx=0.35,sy=0.35}
    self:updateLabelSize(info1,802)
end

--数据发送
function KenoBonusGameView:sendData()
    -- 玩法过程中触发大赢
    if self.m_machine.m_kenoIsPlayBigWin then
        return
    end

    if self.m_kenoSpinNum and self.m_kenoSpinNum <= 0 then
        if self.m_kenoSelfData and self.m_kenoSelfData.bonus.bsWinCoins then
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_over.mp3")

            local view = self:showKenoSpinOver(self.m_kenoSelfData.bonus.bsWinCoins, function()
                self.m_machine.m_isKeno = false

                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                globalData.slotRunData.kenoData_selectNumId = nil
                
                -- 重置进度条
                if self.m_kenoSelfData.collectData and self.m_kenoSelfData.collectData.point == 0 then
                    self.m_machine:resetShouJiMuJi()
                end

                self.m_machine:playChangeGuoChang(nil,function(  )
                    self.m_machine:checkFeatureOverTriggerBigWin( self.m_kenoSelfData.bonus.bsWinCoins, GameEffect.EFFECT_BONUS)
                end)

                self:waitWithDelay(25/30,function()
                    self.m_machine:setShouJiMujiPlayIdle()
                    -- 显示棋盘
                    self.m_machine:findChild("reel"):setVisible(true)
                    self.m_machine:findChild("Node_shouji"):setVisible(true)
                    self.m_machine:findChild("Node_Freebar"):setVisible(true)
                    -- 显示下条目
                    self.m_machine.m_bottomUI:setVisible(true)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

                    self.m_machine.m_runSpinResultData.p_features = {0}
                    self.m_machine:clearCurMusicBg()
                    self.m_machine:resetMusicBg()
                    self.m_machine:reelsDownDelaySetMusicBGVolume( ) 

                    self:runCsbAction("over",false,function(  )
                        self:setVisible(false)
                        -- 重置界面格子
                        for i=1,80 do
                            self.m_numNode[i]:runCsbAction("idleframe",false)
                            self:setShowNumNode(i, 1)
                        end

                        -- 重置paytable闪烁
                        for i=4,10 do
                            self.m_paytable_tx[i]:setVisible(false)
                            self.m_paytable_tx[i]:runCsbAction("idleframe",false)
                            if i == 10 then
                                self.m_paytable[i]:runCsbAction("idleframe1",false)
                            else
                                self.m_paytable[i]:runCsbAction("idleframe",false)
                            end
                        end

                        self.m_selectNumId = {}
                        self.m_kenoProtectLoc = {}
                        self.m_superEgg = {}
                        self:findChild("m_lb_hits"):setString(0)
                        self:findChild("m_lb_marked"):setString(0)
                        self:setBtnStatus(true)

                    end) 
                end)
                
            end)
            view:findChild("root"):setScale(self.m_machine.m_machineRootScale)
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=1,sy=1},780)
        end
        
        return
    end
    
    -- 重置界面格子
    for numIndex = 1, 80 do
        self.m_numNode[numIndex]:runCsbAction("idleframe",false)
        self:setShowNumNode(numIndex, 1)
    end

    -- 重置paytable闪烁
    for paytableIndex = 4, 10 do
        self.m_paytable_tx[paytableIndex]:setVisible(false)
        self.m_paytable_tx[paytableIndex]:runCsbAction("idleframe",false)
        if paytableIndex == 10 then
            self.m_paytable[paytableIndex]:runCsbAction("idleframe1",false)
        else
            self.m_paytable[paytableIndex]:runCsbAction("idleframe",false)
        end
    end

    for i,vId in ipairs(self.m_selectNumId) do
        if not self:getIsClearSuperKeno(vId) then
            self:setShowNumNode(vId, 3)
        else
            self:setShowNumNode(vId, 4)
        end
    end

    self:findChild("m_lb_hits"):setString(#self.m_kenoProtectLoc)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local newData = {}
    newData.pickLoc = self.m_selectNumId
    newData.inBonus = true
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = newData}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--数据接收
function KenoBonusGameView:recvBaseData(featureData)
    local extra = featureData.selfData.bonus.extra
    self.m_winAmount = featureData.winAmount
    if extra then
        self.m_kenoSelfData = featureData.selfData
        self.m_kenoProtectLoc = featureData.selfData.bonus.extra.protectLoc or {}
        self.m_kenoSpinNum = self.m_kenoSpinNum - 1
        local waitTime = 0
        if extra.protectLoc and extra.isFirstSuperKeno then
            if #extra.protectLoc > 0 then
                waitTime = 3

                self:showSuperKenoView(extra.protectLoc)
            end
            
        end

        self:waitWithDelay(waitTime,function()
            -- 剩余spin数
            self.m_spinLeftNode:findChild("m_lb_num"):setString(self.m_kenoSpinNum)
            self:findChild("m_lb_marked"):setString(10)

            -- 刷新选择的10个
            for i,vId in ipairs(extra.chooseLoc) do
                if not self:getIsClearSuperKeno(vId) then
                    self:setShowNumNode(vId, 3)
                else
                    if extra.isFirstSuperKeno then
                        self:setShowNumNode(vId, 4)
                    end
                end
            end
            -- 选择不足10个时 从服务器拿到最新的
            if #self.m_selectNumId < 10 then
                self.m_selectNumId = extra.chooseLoc
            end

            --刷新宝箱
            self:setKenoTips(1)
            for i,vId in ipairs(extra.giftLoc) do
                self:waitWithDelay(0.2*i,function()
                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_show_fangzi.mp3")
                    self:setShowNumNode(vId, 6)
                end)
            end

            -- 20个鸡蛋开始飞
            self:setKenoTips(2)
            self:findChild("m_lb_draw"):setString(0)

            self:waitWithDelay(0.6+0.1,function()
                gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_laomuji.mp3")
                util_spinePlay(self.m_mujiSpine, "actionframe3", false)
                util_spineEndCallFunc(self.m_mujiSpine, "actionframe3", function()
                    util_spinePlay(self.m_mujiSpine, "actionframe4", true)
                end)
            end)

            for i,vId in ipairs(extra.pickLoc) do
                local endWorldPos = self:findChild("Node_"..vId):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..vId):getPosition()))
                local endPos = self:findChild("mujiFlyEgg"):convertToNodeSpace(endWorldPos)

                local egg = util_createAnimation("Keno_shouji_dan_fly.csb")
                egg:setPosition(cc.p(0,0))
                self:findChild("mujiFlyEgg"):addChild(egg,1)
                egg:setVisible(false)

                self:waitWithDelay(0.6+0.1*i,function()
                    self:findChild("m_lb_draw"):setString(i)
                    egg:setVisible(true)
                    egg:runCsbAction("actionframe",true)
                    self:eggJump(endPos, vId, egg, featureData.selfData, i==#extra.pickLoc)
                    -- 最后一个蛋 飞出
                    if i==#extra.pickLoc then
                        util_spinePlay(self.m_mujiSpine, "actionframe5", false)
                        util_spineEndCallFunc(self.m_mujiSpine, "actionframe5", function()
                            self:playMuJiIdleRandom()
                        end)
                        
                    end
                end)
            end
        end)
        
    end
end

-- 飞鸡蛋
function KenoBonusGameView:eggJump(pos, id, node, selfData, isLast)
    local time = 1
    local actionList = {}
    -- 因为层级原因 这四个特殊处理下
    if id == 41 or id == 51 or id == 61 or id == 71 then
        local startPos = cc.p(node:getPosition())
        actionList[#actionList + 1] = cc.BezierTo:create(time,{cc.p(startPos.x, startPos.y+250), cc.p(pos.x, startPos.y+250), pos})
    else
        actionList[#actionList + 1] = cc.JumpTo:create(time, pos, 250, 1)
    end
    
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            local isFangzi = false --判断是否砸中房子
            for i,v in ipairs(selfData.bonus.extra.giftHit) do
                if id == v.loc then
                    isFangzi = true
                end
            end
            node:removeFromParent()
            local baozha = util_createAnimation("Keno_Num_baodian_dan.csb")
            if isFangzi then
                baozha = util_createAnimation("Keno_Num_baodian.csb")
            end
            
            -- self:findChild("Node_"..id):addChild(baozha, 100000)
            local startWorldPos = self:findChild("Node_"..id):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..id):getPosition()))
            local startPos = self:findChild("Node_AllHit"):convertToNodeSpace(startWorldPos)
            self:findChild("Node_AllHit"):addChild(baozha)
            baozha:setPosition(startPos)
            
            -- gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_egg_luodi.mp3")
            baozha:runCsbAction("actionframe",false,function()
                baozha:removeFromParent()
            end)
            self:waitWithDelay(15/60,function()
                self:setShowNumNode(id, 2)
                -- 中奖显示红色
                for i,vId in ipairs(self.m_selectNumId) do
                    if id == vId then
                        
                        gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_egg_zhongjiang.mp3")
                        self:setShowNumNode(vId, 4)
                        self.m_numNode[vId]:runCsbAction("start",false)

                        table.insert(self.m_zhongJiangSpin, vId)
                        self:findChild("m_lb_hits"):setString(#self.m_zhongJiangSpin)
                        break
                    end
                end
                
                -- 中奖宝箱+1次数 要等所以的鸡蛋飞完
                for i,v in ipairs(selfData.bonus.extra.giftHit) do
                    if id == v.loc then
                        self:setShowNumNode(v.loc, 5)
                    end
                end

                -- 所有鸡蛋飞完 显示结算
                if isLast then
                    
                    if #self.m_zhongJiangSpin >= 4 then
                        local waitTime = 2
                        self:waitWithDelay(0.0,function()
                            local random = math.random(1,3)
                            gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_qipan_shanshuo_"..random..".mp3")
                            -- paytable闪烁
                            self.m_paytable_tx[#self.m_zhongJiangSpin]:setVisible(true)
                            self.m_paytable_tx[#self.m_zhongJiangSpin]:runCsbAction("actionframe",true)

                            if #self.m_zhongJiangSpin == 10 then
                                self.m_paytable[#self.m_zhongJiangSpin]:runCsbAction("actionframe",false)
                            else
                                self.m_paytable[#self.m_zhongJiangSpin]:runCsbAction("actionframe1",true)
                            end
                            
                            
                            self:setKenoTips(3)
                            self:findChild("m_lb_3"):setString(#self.m_zhongJiangSpin)
                            -- 不中奖的压黑
                            for i=1,80 do
                                local isHave = false
                                local isHaveGiftHit = false
                                for j,vId in ipairs(self.m_zhongJiangSpin) do
                                    if i == vId then
                                        isHave = true
                                    end
                                end
                                for m,v in ipairs(selfData.bonus.extra.giftHit) do
                                    if i == v.loc then
                                        isHaveGiftHit = true
                                    end
                                end
                                if isHave then
                                    self.m_numNode[i]:runCsbAction("actionframe1",true)
                                else
                                    if not isHaveGiftHit then
                                        self.m_numNode[i]:runCsbAction("darkstart",false,function(  )
                                            self.m_numNode[i]:runCsbAction("dark",true)
                                        end)
                                    end
                                end
                            end

                            -- 中奖宝箱+1次数 要等所以的鸡蛋飞完
                            for i,v in ipairs(selfData.bonus.extra.giftHit) do
                                waitTime = 5
                                if i == 1 then
                                    gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_draw_show.mp3")
                                end
                                self.m_kenoSpinNum = self.m_kenoSpinNum + v.spin
                                self.m_numNode[v.loc]:runCsbAction("actionframe",false,function(  )
                                    self.m_numNode[v.loc]:runCsbAction("actionframe",false,function(  )
                                        self:baoxiangFly(v.loc, i, selfData)
                                    end)
                                end)
                            end
                        end, self.m_effect_node)
                        
                        -- 中奖动画 播放0.5秒之后 播放大赢
                        local bigWinWaitTime = 0.5
                        if #selfData.bonus.extra.giftHit > 0 then
                            bigWinWaitTime = 4.8
                        end

                        -- 如果中奖10个 会弹一个特殊的弹窗
                        if #self.m_zhongJiangSpin == 10 then
                            self:waitWithDelay(waitTime,function()
                                gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_muji_winmax.mp3")
                                util_spinePlay(self.m_mujiSpine, "tanban1", false)
                                --tanban1 时间线25帧开始出现弹板
                                self:waitWithDelay(25/30,function()
                                    self:showWinMaxView(self.m_winAmount, function()
                                        util_spinePlay(self.m_mujiSpine, "start", false)
                                        if self.m_winAmount > 0 then
                                            if self.m_kenoSpinNum > 0 then
                                                self.m_machine:checkFeatureOverTriggerBigWin( self.m_winAmount, GameEffect.EFFECT_BONUS, true)
                                            else
                                                self:nextCliackStartSend()
                                            end
            
                                            self:findChild("m_lb_coins"):setString(util_formatCoins(selfData.bonus.bsWinCoins,30))
                                            if selfData.bonus.bsWinCoins > 0 then
                                                self:findChild("m_lb_coins"):setVisible(true)
                                            else
                                                self:findChild("m_lb_coins"):setVisible(false)
                                            end
                                            self:updateSizeJinBi()
                                        end
                                  
                                    end)
                                end)
                            end)
                        else
                            self:waitWithDelay(bigWinWaitTime,function()
                                if self.m_winAmount > 0 then
                                    if self.m_kenoSpinNum > 0 then
                                        self.m_machine:checkFeatureOverTriggerBigWin( self.m_winAmount, GameEffect.EFFECT_BONUS, true)
                                    end
    
                                    self:findChild("m_lb_coins"):setString(util_formatCoins(selfData.bonus.bsWinCoins,30))
                                    if selfData.bonus.bsWinCoins > 0 then
                                        self:findChild("m_lb_coins"):setVisible(true)
                                    else
                                        self:findChild("m_lb_coins"):setVisible(false)
                                    end
                                    self:updateSizeJinBi()
                                end
                            end)
                            -- 继续往下执行
                            self:waitWithDelay(waitTime,function()
                                local isHaveBigWin = false
                                for i = 1, #self.m_machine.m_gameEffects do
                                    local effectData = self.m_machine.m_gameEffects[i]
                                    if effectData.p_selfEffectType == self.m_machine.EFFECT_SEND then
                                        isHaveBigWin = true
                                    end
                                end 
                                -- 如果触发大赢 不走这块逻辑
                                if not isHaveBigWin then
                                    self:nextCliackStartSend()
                                end
                            end,self.m_effect_node)
                        end
                    else
                        local waitTime = 1
                        -- 中奖宝箱+1次数 要等所以的鸡蛋飞完
                        for i,v in ipairs(selfData.bonus.extra.giftHit) do
                            waitTime = 4.8
                            if i == 1 then
                                gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_draw_show.mp3")
                            end
                            self.m_kenoSpinNum = self.m_kenoSpinNum + v.spin
                            self.m_numNode[v.loc]:runCsbAction("actionframe",false,function(  )
                                self.m_numNode[v.loc]:runCsbAction("actionframe",false,function(  )
                                    self:baoxiangFly(v.loc, i, selfData)
                                end)
                            end)
                        end
                        if #selfData.bonus.extra.giftHit > 0 then
                            -- 不中奖的压黑
                            for i=1,80 do
                                local isHaveGiftHit = false
                                for m,v in ipairs(selfData.bonus.extra.giftHit) do
                                    if i == v.loc then
                                        isHaveGiftHit = true
                                    end
                                end
              
                                if not isHaveGiftHit then
                                    self.m_numNode[i]:runCsbAction("darkstart",false,function(  )
                                        self.m_numNode[i]:runCsbAction("dark",true)
                                    end)
                                end
                            end
                        end

                        -- 继续往下执行
                        self:setKenoTips(1)
                        self:waitWithDelay(waitTime,function()
                            self:nextCliackStartSend()
                        end)
                    end

                end
            end)
        end
    )
    local sq = cc.Sequence:create(actionList)
    node:runAction(sq)
end

-- paytable 格子 重置闪烁
function KenoBonusGameView:resetNodeLight(selfData)
    if #self.m_zhongJiangSpin >= 4 then
        self.m_paytable_tx[#self.m_zhongJiangSpin]:runCsbAction("idleframe",false)
        if #self.m_zhongJiangSpin == 10 then
            self.m_paytable[#self.m_zhongJiangSpin]:runCsbAction("idleframe1",false)
        else
            self.m_paytable[#self.m_zhongJiangSpin]:runCsbAction("idleframe",false)
        end

        for i=1,80 do
            local isHave = false
            local isHaveGiftHit = false
            for j,vId in ipairs(self.m_zhongJiangSpin) do
                if i == vId then
                    isHave = true
                end
            end
            for m,v in ipairs(selfData.bonus.extra.giftHit) do
                if i == v.loc then
                    isHaveGiftHit = true
                end
            end
            if isHave then
                self.m_numNode[i]:runCsbAction("idleframe",false)
            else
                if not isHaveGiftHit then
                    self.m_numNode[i]:runCsbAction("darkover",false)
                end
            end
        end
    end
end

-- 中奖宝箱飞动画
function KenoBonusGameView:baoxiangFly(vId, _indexId, selfData)
    local flyBaoXiang = util_createAnimation("Keno_draw_fly.csb")
    self:addChild(flyBaoXiang, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    local startWorldPos = self:findChild("Node_"..vId):getParent():convertToWorldSpace(cc.p(self:findChild("Node_"..vId):getPosition()))
    local startPos = self:convertToNodeSpace(startWorldPos)
    flyBaoXiang:setPosition(startPos)

    flyBaoXiang:runCsbAction("actionframe",false,function(  )
        if flyBaoXiang:findChild("Particle_1") then
            flyBaoXiang:findChild("Particle_1"):setDuration(500)
            flyBaoXiang:findChild("Particle_1"):setPositionType(0)
            flyBaoXiang:findChild("Particle_1"):resetSystem()
        end
        
        if _indexId == 1 then
            gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_draw_fly.mp3")
        end
        local endWorldPos = self.m_spinLeftNode:findChild("m_lb_num"):getParent():convertToWorldSpace(cc.p(self.m_spinLeftNode:findChild("m_lb_num"):getPosition()))
        local endPos = self:convertToNodeSpace(endWorldPos)
        local move = cc.MoveTo:create(30/60,endPos)
        local call = cc.CallFunc:create(function ()
            if flyBaoXiang:findChild("Particle_1") then
                flyBaoXiang:findChild("Particle_1"):stopSystem()
            end

            if _indexId == #selfData.bonus.extra.giftHit then
                gLobalSoundManager:playSound("KenoSounds/sound_Keno_keno_draw_baozha.mp3")
                self.m_spinLeftNode:runCsbAction("actionframe",false)
                -- 6帧之后 数字变化
                self:waitWithDelay(6/60,function()
                    -- 剩余spin数
                    self.m_spinLeftNode:findChild("m_lb_num"):setString(self.m_kenoSpinNum)
                end)

                -- 中奖十个 又不重置了
                if #self.m_zhongJiangSpin ~= 10 then 
                    self:resetNodeLight(selfData)
                end
            end

            flyBaoXiang:removeFromParent()
            
        end)
    
        local seq = cc.Sequence:create(move,call)
        flyBaoXiang:runAction(seq)
    end)
end

--开始结束流程
function KenoBonusGameView:gameOver(isContinue)

end

--弹出结算奖励
function KenoBonusGameView:showReward()

end

function KenoBonusGameView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            if param[2] and param[2].result then
                local spinData = param[2]
                dump(spinData.result, "featureResultCallFun data", 3)
                if spinData.action == "FEATURE" then
                    self:recvBaseData(spinData.result)
                end
            end
        else
            -- 处理消息请求错误情况
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
    end 
end

-- 开始引导
function KenoBonusGameView:beginShowGuide( )
    self.m_KenoGuideView = util_createView("CodeKenoSrc.KenoGuideView",self)
    self.m_KenoGuideView:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_KenoGuideView:initViewData(self)

    gLobalViewManager:showUI(self.m_KenoGuideView)
    self.m_isSetGuide = true
end

-- 保存数据
function KenoBonusGameView:setDataByKey(value)
    globalData.slotRunData.kenoData_introFinished = value
end

-- 设置80个各自中间的提示
function KenoBonusGameView:setKenoTips(_index)
    for i=0,3 do
        self:findChild("txt_"..i):setVisible(false)
    end
    self:findChild("txt_".._index):setVisible(true)
end

-- 随机播放三种母鸡idle
-- 三条idle时间线随机播放，idleframe5的概率要比6和7大
function KenoBonusGameView:playMuJiIdleRandom( )
    local random = math.random(1, 10)
    local idleName = "idleframe5"
    if random >= 1 and random <= 3 then
        idleName = "idleframe6"
    elseif random >= 4 and random <= 6 then
        idleName = "idleframe7"
    end

    util_spinePlay(self.m_mujiSpine, idleName, false)
    util_spineEndCallFunc(self.m_mujiSpine, idleName, function()
        self:playMuJiIdleRandom()
    end)
end

-- 进入keno界面时 刷新一下
function KenoBonusGameView:updataKenoView(machine)
    self.m_machine = machine

    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local kenoData_selectNumId = globalData.slotRunData.kenoData_selectNumId
    if kenoData_selectNumId then
        self.m_selectNumId = kenoData_selectNumId
    end
    self.m_kenoSpinNum = selfMakeData.bonus.extra.leftTimes or 10
    if selfMakeData.bonus and selfMakeData.bonus.extra and selfMakeData.bonus.extra.chooseLoc then
        self.m_selectNumId = selfMakeData.bonus.extra.chooseLoc
        if #selfMakeData.bonus.extra.chooseLoc >= 10 then
            self:waitWithDelay(0.5,function()
                self:nextCliackStartSend()
            end)
        end
    end

    --刷新一下赢钱的金币
    if selfMakeData.bonus and selfMakeData.bonus.bsWinCoins then
        self:findChild("m_lb_coins"):setString(util_formatCoins(selfMakeData.bonus.bsWinCoins,30))
        if selfMakeData.bonus.bsWinCoins > 0 then
            self:findChild("m_lb_coins"):setVisible(true)
        else
            self:findChild("m_lb_coins"):setVisible(false)
        end
        self:updateSizeJinBi()
    end  

    for i,_selectNumId in ipairs(self.m_selectNumId) do
        self:setShowNumNode(_selectNumId, 3)
    end

    if #self.m_selectNumId >= 10 then
        self:findChild("Button_quick"):setBright(false)
        self:findChild("Button_quick"):setTouchEnabled(false)
        self:findChild("Button_start"):setBright(true)
        self:findChild("Button_start"):setTouchEnabled(true)
    else
        self:findChild("Button_quick"):setBright(true)
        self:findChild("Button_quick"):setTouchEnabled(true)
        self:findChild("Button_start"):setBright(false)
        self:findChild("Button_start"):setTouchEnabled(false)
    end
    if #self.m_selectNumId > 0 then
        self:findChild("Button_erase"):setBright(true)
        self:findChild("Button_erase"):setTouchEnabled(true)
    else
        self:findChild("Button_erase"):setBright(false)
        self:findChild("Button_erase"):setTouchEnabled(false)
    end 
    
    if selfMakeData.bonus and selfMakeData.bonus.extra then
        self.m_kenoSpinNum = selfMakeData.bonus.extra.leftTimes
        -- self.m_kenoSpinNum = 2
    end
    if selfMakeData.bonus and selfMakeData.bonus.extra and selfMakeData.bonus.extra.paytable then 
        self.m_kenoPaytable = selfMakeData.bonus.extra.paytable
        self.m_kenoBet = self.m_machine.m_runSpinResultData.p_bet*self.m_machine.m_runSpinResultData.p_payLineCount
        if selfMakeData.bonus and selfMakeData.bonus.extra and selfMakeData.bonus.extra.avgBet then 
            self.m_kenoBet = selfMakeData.bonus.extra.avgBet
        end 
        -- 初始化paytable
        for i=4,10 do
            if i == 10 then
                self:setShowPayTable(i,3,i,util_formatCoins(self.m_kenoPaytable[tostring(i)]*self.m_kenoBet,30))
            else
                self:setShowPayTable(i,1,i,util_formatCoins(self.m_kenoPaytable[tostring(i)]*self.m_kenoBet,30))
            end
        end
    end

    -- 刷新super Keno时必中的4个
    if selfMakeData.bonus and selfMakeData.bonus.extra and selfMakeData.bonus.extra.protectLoc then
        self.m_kenoProtectLoc = selfMakeData.bonus.extra.protectLoc or {}
        for i,vId in ipairs(self.m_kenoProtectLoc) do
            self:setShowNumNode(vId, 4)
        end
    end
    -- 剩余spin数
    self.m_spinLeftNode:findChild("m_lb_num"):setString(self.m_kenoSpinNum)

    self:findChild("m_lb_marked"):setString(#self.m_selectNumId)

    self:setKenoTips(0)

    -- 老母鸡掉下来
    self.m_mujiSpine:setVisible(false)
    self:waitWithDelay(0.3,function()
        
        if self.m_machine.m_isDuanXian then
            self.m_mujiSpine:setVisible(true)
            self:playMuJiIdleRandom()
        else
            self.m_mujiSpine:setVisible(true)
            util_spinePlay(self.m_mujiSpine, "start", false)
            util_spineEndCallFunc(self.m_mujiSpine, "start", function()
                self:playMuJiIdleRandom()
            end)
        end
        
        -- super 四个蛋
        -- if selfMakeData.collectData and selfMakeData.collectData.point >= 10 and self.m_kenoSpinNum == 10 then
        --     for i=1,4 do
        --         local start_worldPos = self:findChild("dan"..i):getParent():convertToWorldSpace(cc.p(self:findChild("dan"..i):getPosition()))
        --         local start_pos = self:findChild("mujiFlyEgg"):convertToNodeSpace(start_worldPos)

        --         local egg = util_createAnimation("Keno_shouji_dan_fly.csb")
        --         egg:setPosition(start_pos)
        --         self:findChild("mujiFlyEgg"):addChild(egg,1)
        --         egg:runCsbAction("show", false)
        --         table.insert(self.m_superEgg,egg)
        --     end
        -- end
    end)
end

-- 延时函数
function KenoBonusGameView:waitWithDelay(time, endFunc, parent)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

-- 设置按钮状态
function KenoBonusGameView:setBtnStatus(status)
    local btnName = {"Button_quick", "Button_erase", "Button_start"}
    for i,vBtnName in ipairs(btnName) do
        self:findChild(vBtnName):setBright(status)
        self:findChild(vBtnName):setTouchEnabled(status)
    end
    -- 已经点击了 start按钮
    self.m_isBeginstart = not status

    self.m_zhongJiangSpin = self.m_kenoProtectLoc
end

-- 点击quickpick
function KenoBonusGameView:clickBtnQuickPick( )

    local cheakRandomFun = function(randomNum)
        while #self.m_selectNumId < 10 do 
            local istrue = false
            local num = math.random( 1,80 )
            if #self.m_selectNumId ~= nil then
                for i = 1 ,#self.m_selectNumId do
                    if self.m_selectNumId[i] == num then
                        istrue = true
                    end
                end
            end
            if istrue == false then
                table.insert( self.m_selectNumId, num )
            end
        end
    end

    cheakRandomFun()

    for i,_selectNumId in ipairs(self.m_selectNumId) do
        self:setShowNumNode(_selectNumId, 3)
    end
    self:findChild("m_lb_marked"):setString(#self.m_selectNumId)
    globalData.slotRunData.kenoData_selectNumId = self.m_selectNumId

    -- 按钮压暗
    self:findChild("Button_quick"):setBright(false)
    self:findChild("Button_quick"):setTouchEnabled(false)

    self:findChild("Button_erase"):setBright(true)
    self:findChild("Button_erase"):setTouchEnabled(true)
end

-- 点击Erase
function KenoBonusGameView:clickBtnErase( )
    for i,_selectNumId in ipairs(self.m_selectNumId) do
        self:setShowNumNode(_selectNumId, 1)
    end
    self:findChild("m_lb_marked"):setString(0)
    self.m_selectNumId = {}
    globalData.slotRunData.kenoData_selectNumId = self.m_selectNumId

    self:findChild("Button_quick"):setBright(true)
    self:findChild("Button_quick"):setTouchEnabled(true)

    self:findChild("Button_erase"):setBright(false)
    self:findChild("Button_erase"):setTouchEnabled(false)
end

-- 结束弹板
function KenoBonusGameView:showKenoSpinOver(coins, func)
    self.m_machine:clearCurMusicBg()

    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    return self.m_machine:showDialog("KenoOver",ownerlist,func)

end

-- super Keno必中的几个 每次开始start时 不清理
function KenoBonusGameView:getIsClearSuperKeno(vId)
    for m,nId in ipairs(self.m_kenoProtectLoc) do
        if vId == nId then
            return true
        end
    end
    return false
end

-- 播放大赢之后 如果其他动画还没有播放 停掉
function KenoBonusGameView:checkBigWinEffect( )
    if self.m_effect_node then
        self.m_effect_node:stopAllActions()
        self.m_effect_node:removeAllChildren()
    end
end

-- 显示super keno第一次界面
function KenoBonusGameView:showSuperKenoView(protectLoc )
    self.m_KenoGuideView = util_createView("CodeKenoSrc.KenoGuideView",self)
    self.m_KenoGuideView:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_KenoGuideView:setSuperKenoView(self, protectLoc)

    gLobalViewManager:showUI(self.m_KenoGuideView)
end

-- 中最大10个格子的时候 的弹板
function KenoBonusGameView:showWinMaxView(coins,func)

    local view = util_createView("CodeKenoSrc.KenoWinMaxView")

    local courFunc = function(  )

        if func then
            func()
        end
    end

    view:initViewData(coins,courFunc)
    self:findChild("Node_AllHit"):addChild(view)

end

-- 下一次的send
function KenoBonusGameView:nextCliackStartSend( )
    self.m_machine:nextKenoSendEffect()
end

return KenoBonusGameView