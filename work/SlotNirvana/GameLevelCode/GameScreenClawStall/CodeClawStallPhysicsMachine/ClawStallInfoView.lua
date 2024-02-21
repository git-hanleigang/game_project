---
--xcyy
--2018年5月23日
--ClawStallInfoView.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallGameManager = util_require("CodeClawStallPhysicsMachine.ClawStallGameManager"):getInstance()
local ClawStallInfoView = class("ClawStallInfoView",util_require("Levels.BaseLevelDialog"))

--抓取模式
local CLAW_MODE = {
    NORMAL = 1,     --普通模式
    SPECIAL = 2     --特殊模式
}

local BTN_TAG_NORMAL            =           1001
local BTN_TAG_AUTO              =           1002

function ClawStallInfoView:initUI(params)
    self.m_isCanClick = false
    --3d主界面
    self.m_mainView = params.mainView
    self:createCsbNode("ClawStall/GameScreenClawStall_Machine.csb")

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)

    local machieScale = ClawStallGameManager:getMachineView().m_machineRootScale
    -- local posY = (display.height - 768 * machieScale) / 2
    self:findChild("Node_LowerUI"):setScale(machieScale)
    local jackpotNode = self:findChild("Node_MachineJackpotView")
    jackpotNode:setScale(machieScale * jackpotNode:getScale())
    self:findChild("Node_Counter"):setScale(machieScale)
    self:findChild("Node_tanban"):setScale(machieScale)
    self:findChild("Node_ControlArea"):setScale(machieScale)

    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,1000)

    --赢钱统计弹板
    self.m_winCoinsView = util_createView("CodeClawStallPhysicsMachine.ClawStallWinCoinsView")
    self:findChild("Node_tanban"):addChild(self.m_winCoinsView)
    self.m_winCoinsView:setVisible(false)

    

    --抓中娃娃光效
    self.m_hitLight = util_createAnimation("ClawStall_ktx.csb")
    self:findChild("bktx"):addChild(self.m_hitLight)
    self.m_hitLight:setVisible(false)
    -- self.m_hitLight:runCsbAction("actionframe",true)
    --创建摇杆
    self:initJoyStick()

    --创建抓取按钮
    self:initGrabBtn()

    --倒计时标签
    self.m_countDown = util_createAnimation("ClawStall_Machine_Counter.csb")
    self:findChild("Node_Counter"):addChild(self.m_countDown)
    self.m_countDown:setVisible(false)

    --创建收集区
    self.m_collectItems = {}
    self:createCollectItem()

    --super grab提示弹板
    self.m_supeGrabTip = util_createAnimation("ClawStall_Machine_SuperGrabTips.csb")
    self:findChild("Node_tanban"):addChild(self.m_supeGrabTip)
    self.m_supeGrabTip:setVisible(false)

    local dollScore = util_createAnimation("ClawStall_Machine_DollScoreTips.csb")
    self:findChild("Node_DollScoreTips"):addChild(dollScore)

    --自动抓取提示
    self.m_autoTip = util_createAnimation("ClawStall_Respin_aotutips.csb")
    self:findChild("Node_aotu_tips"):addChild(self.m_autoTip)

end

--[[
    刷新自动抓取相关显示
]]
function ClawStallInfoView:updateAutoShow()
    local autoStatus = ClawStallGameManager:getAutoStatus()
    self.m_autoTip:findChild("Node_aotu"):setVisible(not autoStatus)
    self.m_autoTip:findChild("Node_aotu_now"):setVisible(autoStatus)

    self.m_grabBtn:findChild("node_normal"):setVisible(not autoStatus)
    self.m_grabBtn:findChild("node_auto"):setVisible(autoStatus)
end

-- 创建摇杆 --
function ClawStallInfoView:initJoyStick()
    if self.m_JoyStick ~= nil then
        return
    end

    self.m_JoyStick = util_createView("CodeClawStallPhysicsMachine.ClawStallJoyStick")
    self:findChild("Node_Joystick"):addChild(self.m_JoyStick)
    
end

--[[
    创建抓取按钮
]]
function ClawStallInfoView:initGrabBtn()
    self.m_grabBtn = util_createAnimation("ClawStall_Machine_BtnGrab.csb")
    self:findChild("Node_BtnGrab"):addChild(self.m_grabBtn)
    local normalBtn = self.m_grabBtn:findChild("btn_normal")
    local autoBtn = self.m_grabBtn:findChild("btn_auto")
    normalBtn:setTag(BTN_TAG_NORMAL)
    autoBtn:setTag(BTN_TAG_AUTO)
    self:addClick(normalBtn)
    self:addClick(autoBtn)
    self.m_grabBtn:runCsbAction("idle",true)
end

--[[
    创建收集区道具
]]
function ClawStallInfoView:createCollectItem()
    for index = 1,15 do
        local item = util_createAnimation("ClawStall_Machine_Grabs.csb")
        item:runCsbAction("idle")
        self:findChild("Node_Grab"..index):addChild(item)
        item.m_clawType = CLAW_MODE.NORMAL

        local item_gold = util_createAnimation("ClawStall_Machine_GrabsSuper.csb")
        item_gold:runCsbAction("idle")
        self:findChild("Node_Grab"..index):addChild(item_gold)
        item_gold:setVisible(false)
        item_gold.m_clawType = CLAW_MODE.SPECIAL

        self.m_collectItems[#self.m_collectItems + 1] = {
            normal = item,
            gold = item_gold
        }
    end
end

--[[
    开始倒计时
]]
function ClawStallInfoView:startCountDown()
    local countDownTime = ClawStallGameManager:getCountDownTime()
    local func = function()

        if self.m_isChangeStatus or ClawStallGameManager:getAutoStatus() then
            return
        end
        countDownTime = countDownTime - 1

        if countDownTime <= 0 then
            self.m_countDown:findChild("m_lb_time"):setString("00:00")
            self:hideCounter()

            --开始抓取
            self:clickFunc(self.m_grabBtn:findChild("btn_normal"))
        else
            local str = util_hour_min_str(countDownTime)
            self.m_countDown:findChild("m_lb_time"):setString(str)

            if countDownTime <= 10 and not self.m_countDown.isAlert then
                self.m_countDown.isAlert = true
                self.m_countDown:runCsbAction("idle",true)
            end
        end

        
    end


    local str = util_hour_min_str(countDownTime)
    self.m_countDown:findChild("m_lb_time"):setString(str)
    self.m_countDown:setVisible(true)
    self.m_countDown.isAlert = false
    util_schedule(self.m_countDown, func, 1)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_count_down)
    self.m_countDown:runCsbAction("start")
end

--[[
    隐藏倒计时
]]
function ClawStallInfoView:hideCounter( )
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_hide_count_down)
    self.m_countDown:stopAllActions()
    self.m_countDown:runCsbAction("over",false,function(  )
        self.m_countDown:setVisible(false)
    end)
    
    
end

--[[
    刷新收集区
]]
function ClawStallInfoView:refreshCollectItems(bonusData)

    local storedIcons = bonusData.storedIcons
    if not storedIcons then
        util_printLog("抓娃娃storedIcons数据错误!!!!",true)
        return
    end

    local iconData = storedIcons[bonusData.bonustime + 1]
    if iconData then
        ClawStallGameManager:setCurClawMode(iconData[3])

        if iconData[3] and iconData[3] == CLAW_MODE.SPECIAL then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_super_grab)
            self.m_mainView:changeClawForSpecial()
            self.m_supeGrabTip:setVisible(true)
            self.m_supeGrabTip:runCsbAction("auto",false,function(  )
                self.m_supeGrabTip:setVisible(false)

                --检测自动状态
                local autoStatus = ClawStallGameManager:getAutoStatus()
                if autoStatus then
                    self.m_mainView:startAutoClaw()
                end
            end)
        else
            --检测自动状态
            local autoStatus = ClawStallGameManager:getAutoStatus()
            if autoStatus then
                self.m_mainView:startAutoClaw()
            end
        end
    end
    

    local collectData = bonusData.collect
    if not collectData then
        return
    end
    local machine = ClawStallGameManager:getMachineView()
    local curTime = bonusData.bonustime
    for index = 1,15 do
        local items = self.m_collectItems[index]
        local data = collectData[index]
        
        if not data then
            items.normal:setVisible(false)
            items.gold:setVisible(false)
        else
            local iconData = storedIcons[index]
            local iconType = iconData[3] or CLAW_MODE.NORMAL
            items.normal:setVisible(iconType == CLAW_MODE.NORMAL)
            items.gold:setVisible(iconType == CLAW_MODE.SPECIAL)
            local curItem = iconType == CLAW_MODE.NORMAL and items.normal or items.gold
            curItem:findChild("m_lb_mul"):setString("X"..data[2])
            curItem:findChild("m_lb_mul_0"):setString("X"..data[2])
            if data[1] == "-1" then --未抓取
                if curTime + 1 == index then -- 当前次数
                    curItem:runCsbAction("tishi",true)
                else
                    curItem:runCsbAction("idle")
                end
                self:changeItemShow(curItem,"multi",iconType)
            elseif data[1] == "0" then --未抓到
                curItem:runCsbAction("idle3")
                self:changeItemShow(curItem,"multi",iconType)
            else
                curItem:runCsbAction("idle2")
                if data[1] == "coins" then
                    self:changeItemShow(curItem,"coins",iconType)
                    local winCoins = data[4] or 0
                    local str = util_formatCoins(winCoins,3)
                    curItem:findChild("m_lb_coins"):setString(str)
                else
                    self:changeItemShow(curItem,"jackpot",iconType)
                    if iconType == CLAW_MODE.NORMAL or data[3] == 0 then
                        
                        if iconType == CLAW_MODE.SPECIAL then
                            curItem:findChild("Node_MultiJackpot"):setVisible(false)
                            curItem:findChild("Node_MultiAll"):setVisible(true)
                        end
                        
                        curItem:findChild("ClawStall_wawaji_wenzi_1_3"):setVisible(data[1] == "grand")
                        curItem:findChild("ClawStall_wawaji_wenzi_2_4"):setVisible(data[1] == "major")
                        curItem:findChild("ClawStall_wawaji_wenzi_3_5"):setVisible(data[1] == "minor")
                        curItem:findChild("ClawStall_wawaji_wenzi_4_6"):setVisible(data[1] == "mini")
                    else
                        curItem:findChild("ClawStall_wawaji_grand"):setVisible(data[1] == "grand")
                        curItem:findChild("ClawStall_wawaji_major"):setVisible(data[1] == "major")
                        curItem:findChild("ClawStall_wawaji_minor"):setVisible(data[1] == "minor")
                        curItem:findChild("ClawStall_wawaji_mini"):setVisible(data[1] == "mini")
                        curItem:findChild("m_lb_coins_0"):setString(util_formatCoins(data[3] * data[2],3))
                        curItem:findChild("m_lb_mul_3"):setString("X"..data[2])
                    end
                    

                    machine.m_jackpotBar:showJackpotLight(data[1])
                end
            end
        end
    end
end

--[[
    刷新本次抓取奖励
]]
function ClawStallInfoView:showRewardAni(curIndex,curRewardData,func)
    local items = self.m_collectItems[curIndex]
    local storedIcons = self.m_mainView.m_bonusData.storedIcons
    local iconData = storedIcons[curIndex]
    local iconType = iconData[3] or CLAW_MODE.NORMAL
        
    if not curRewardData then
        items.normal:setVisible(false)
        items.gold:setVisible(false)
        util_printLog("娃娃奖励数据错误!!!!",true)
        if type(func) == "function" then
            func()
        end
    else
        items.normal:setVisible(iconType == CLAW_MODE.NORMAL)
        items.gold:setVisible(iconType == CLAW_MODE.SPECIAL)
        local curItem = iconType == CLAW_MODE.NORMAL and items.normal or items.gold
        curItem:findChild("m_lb_mul"):setString("X"..curRewardData[2])
        curItem:findChild("m_lb_mul_0"):setString("X"..curRewardData[2])
        if curRewardData[1] == "-1" then --未抓取
            curItem:runCsbAction("idle")
            if type(func) == "function" then
                func()
            end
            util_printLog("当前抓取娃娃状态错误!!!!",true)
            self:changeItemShow(curItem,"multi",iconType)
        elseif curRewardData[1] == "0" then --未抓到
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_heart_change_to_fail_status)
            curItem:runCsbAction("bianan",false,func)
            self:changeItemShow(curItem,"multi",iconType)

        else
            if curRewardData[1] == "coins" then --抓到金币
                --奖励飞到收集区
                self:flyRewardToCollectBar(curRewardData,curItem,function(  )
                    curItem:runCsbAction("fankui",false,func)
                    self:changeItemShow(curItem,"coins",iconType)
                    local winCoins = curRewardData[4] or 0
                    local str = util_formatCoins(winCoins,3)
                    curItem:findChild("m_lb_coins"):setString(str)
                end)
            else    --获得jackpot
                self:showJackpotView(curRewardData,curItem,function( )

                    curItem:runCsbAction("fankui",false,function()
                        if iconType == CLAW_MODE.NORMAL or curRewardData[3] == 0 then
                            if type(func) == "function" then
                                func()
                            end
                        end
                    end)
                    
                    self:changeItemShow(curItem,"jackpot",CLAW_MODE.NORMAL)
                    
                    curItem:findChild("ClawStall_wawaji_wenzi_1_3"):setVisible(curRewardData[1] == "grand")
                    curItem:findChild("ClawStall_wawaji_wenzi_2_4"):setVisible(curRewardData[1] == "major")
                    curItem:findChild("ClawStall_wawaji_wenzi_3_5"):setVisible(curRewardData[1] == "minor")
                    curItem:findChild("ClawStall_wawaji_wenzi_4_6"):setVisible(curRewardData[1] == "mini")
                    --显示飞金币
                    if iconType == CLAW_MODE.SPECIAL and curRewardData[3] > 0 then
                        --奖励飞到收集区
                        self:flyRewardToCollectBar(curRewardData,curItem,function(  )
                            curItem:runCsbAction("fankui",false,func)
                            self:changeItemShow(curItem,"jackpot",iconType)

                            curItem:findChild("ClawStall_wawaji_grand"):setVisible(curRewardData[1] == "grand")
                            curItem:findChild("ClawStall_wawaji_major"):setVisible(curRewardData[1] == "major")
                            curItem:findChild("ClawStall_wawaji_minor"):setVisible(curRewardData[1] == "minor")
                            curItem:findChild("ClawStall_wawaji_mini"):setVisible(curRewardData[1] == "mini")
                            curItem:findChild("m_lb_coins_0"):setString(util_formatCoins(curRewardData[3] * curRewardData[2],3))
                            curItem:findChild("m_lb_mul_3"):setString("X"..curRewardData[2])
                        end)
                    end

                    
                end)
            end
        end
    end
end

--检测是否为jackpot类型
function ClawStallInfoView:checkIsJackpotType(rewardType)
    rewardType = tostring(rewardType)
    if rewardType == "grand" or rewardType == "major" or rewardType == "minor" or rewardType == "mini" then
        return true
    end

    return false
end

--[[
    抓中娃娃光效
]]
function ClawStallInfoView:showRewardLight(itemID)
    local aniName = "actionframe2"
    if itemID < 6 then
        aniName = "actionframe"
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_item_drop_feed_back)
    self.m_hitLight:setVisible(true)
    self.m_hitLight:runCsbAction(aniName,false,function(  )
        self.m_hitLight:setVisible(false)
    end)
end

--[[
    奖励飞到收集区
]]
function ClawStallInfoView:flyRewardToCollectBar(rewardData,endNode,func)
    local flyNode = util_createAnimation("ClawStall_Machine_PrizeCoins.csb")
    local particle = flyNode:findChild("Particle_1")
    particle:setPositionType(0)

    local coins = rewardData[3] or 0
    local str = util_formatCoins(coins,3)
    flyNode:findChild("m_lb_coins"):setString(str)
    

    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    

    local iconType = endNode.m_clawType
    local actionList = {}
    if iconType == CLAW_MODE.NORMAL then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_item_coins_collect)
        self:findChild("Node_reward"):addChild(flyNode)
        actionList = {
            cc.JumpTo:create(20 / 60,cc.p(120,200),50,1),
            cc.CallFunc:create(function()
                local pos = util_convertToNodeSpace(flyNode,self.m_effectNode)
                util_changeNodeParent(self.m_effectNode,flyNode)
                flyNode:setPosition(pos)

                flyNode:runCsbAction("shouji",false,function(  )
                    flyNode:findChild("m_lb_coins"):setVisible(false)
                end)
            end),
            cc.EaseExponentialIn:create(cc.MoveTo:create(35 / 60,endPos))
        }
    else
        self.m_effectNode:addChild(flyNode)
        --转化二维坐标
        local clawPos = self.m_mainView:getClawPos()
        local worldPos = self.m_mainView:Convert3DToGL2D(clawPos)
        worldPos.y = worldPos.y - 150
        local pos = self.m_effectNode:convertToNodeSpace(worldPos)
        flyNode:setPosition(pos)

        actionList = {
            cc.DelayTime:create(20 / 60),
            cc.CallFunc:create(function(  )
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_item_coins_indrawing)
            end),
            cc.CallFunc:create(function()
                flyNode:runCsbAction("shouji",false,function(  )
                    flyNode:findChild("m_lb_coins"):setVisible(false)
                end)
            end),
            cc.EaseExponentialIn:create(cc.MoveTo:create(35 / 60,endPos))
        }
    end

    --结束回调
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        particle:stopSystem()
        if iconType == CLAW_MODE.NORMAL then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_item_coins_collect_feed_back)
        end
        
        if type(func) == "function" then
            func()
        end
    end)

    actionList[#actionList + 1] = cc.DelayTime:create(1)
    actionList[#actionList + 1] = cc.RemoveSelf:create(true)

    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("chuxian")

    -- self.m_effectNode:addChild(flyNode)
    
end

--[[
    jackpot飞到收集区
]]
function ClawStallInfoView:flyJackpotToCollectBar(flyNode,endNode,func)
    local particle = flyNode:findChild("Particle_1")
    particle:setPositionType(0)

    local endPos = util_convertToNodeSpace(endNode,self:findChild("Node_tanban"))
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_jp)
    local seq = cc.Sequence:create({
        cc.MoveTo:create(25 / 60,endPos),
        cc.CallFunc:create(function()
            particle:stopSystem()
            flyNode:findChild("Jackpots"):setVisible(false)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_jp_feed_back)
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji")
end

--[[
    变更道具显示
]]
function ClawStallInfoView:changeItemShow(item,itemType,clawType)
    item:findChild("Node_multiplier"):setVisible(itemType == "multi")
    item:findChild("Node_WInningCoins"):setVisible(itemType == "coins")
    
    if clawType == CLAW_MODE.SPECIAL and itemType == "jackpot" then
        item:findChild("Node_MultiJackpot"):setVisible(false)
        item:findChild("Node_MultiAll"):setVisible(true)
    elseif clawType == CLAW_MODE.SPECIAL then
        item:findChild("Node_MultiJackpot"):setVisible(false)
        item:findChild("Node_MultiAll"):setVisible(false)
    else
        item:findChild("Node_MultiJackpot"):setVisible(itemType == "jackpot")
    end
end

function ClawStallInfoView:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc or self.m_isChangeStatus then
            return
        end
        self:setButtonStatusByBegan(sender)
        self:clickStartFunc(sender)

        local autoStatus = ClawStallGameManager:getAutoStatus()

        

        performWithDelay(self.m_grabBtn,function()
            self.m_isChangeStatus = true
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_long_press_btn)
            self.m_grabBtn:runCsbAction("actionframe2",false,function()
                
            end)

            ClawStallGameManager:setAutoStatus(not autoStatus)


            performWithDelay(self.m_waitNode,function()
                self.m_isChangeStatus = false
                self:updateAutoShow()

                if ClawStallGameManager:getAutoStatus() then
                    self.m_mainView:startAutoClaw()
                    self.m_countDown:stopAllActions()
                    self.m_countDown:setVisible(false)
                else
                    self.m_mainView:stopAutoAction()
                end

            end,1)
        end,1)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc or self.m_isChangeStatus then
            return
        end
        self:setButtonStatusByMoved(sender)
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc or self.m_isChangeStatus then
            return
        end

        self.m_grabBtn:stopAllActions()
        self:setButtonStatusByEnd(sender)
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        local offy = math.abs(endPos.y - beginPos.y)
        if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil and not ClawStallGameManager:getAutoStatus() then
            self:clickSound(sender)
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickEndFunc or self.m_isChangeStatus then
            return
        end
        self:clickEndFunc(sender, eventType)
    end
end

--点击监听
function ClawStallInfoView:clickStartFunc(sender)
    
end
--结束监听
function ClawStallInfoView:clickEndFunc(sender,eventType)
    
end

--默认按钮监听回调
function ClawStallInfoView:clickFunc(sender)
    local tag = sender:getTag()
    if tag == BTN_TAG_AUTO then
        return
    end

    if self.m_mainView.m_isClawing or self.m_mainView.m_isWaiting or self.m_isClicked or self.m_isChangeStatus then
        return
    end
    self.m_isClicked = true

    if not ClawStallGameManager:getAutoStatus() then
        self:setGrabBtnEnabled(false,false)
        self.m_grabBtn:runCsbAction("actionframe",false,function(  )
            
            self.m_isClicked = false
            self.m_grabBtn:pauseForIndex(0)
        end)
    else
        self:setGrabBtnEnabled(false,false)
        self.m_isClicked = false
        self.m_grabBtn:pauseForIndex(0)
    end
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_click_btn)

    self.m_JoyStick:refreshDirection(cc.p(0,0))

    --发送预抓取消息
    ClawStallGameManager:sendPreClawData()
    
end

--[[
    开始抓取
]]
function ClawStallInfoView:startClaw( )
    --获取当前抓取模式
    local clawMode = ClawStallGameManager:getCurClawMode()
    if clawMode == CLAW_MODE.NORMAL then
        self.m_mainView:clawAction("begin")
    else
        self.m_mainView:startIndrawing()
    end
end

--[[
    奖励结算
]]
function ClawStallInfoView:playScoreCollectAnim(collectData,func)
    self.m_winCoins = 0

    local machine = ClawStallGameManager:getMachineView()
    --本次玩法是否有赢钱
    local isWinCoins = false

    --计算jackpot数量
    self.m_jackpotCounts = {}
    for index = 1,#collectData do
        local rewardData = collectData[index] or {}
        local rewardType = rewardData[1] or "coins"
        if rewardType ~= "0" then
            isWinCoins = true
        end
        if self:checkIsJackpotType(rewardType) then
            if not self.m_jackpotCounts[rewardType] then
                self.m_jackpotCounts[rewardType] = 0
            end
            self.m_jackpotCounts[rewardType] = self.m_jackpotCounts[rewardType] + 1
        end
    end

    if not isWinCoins then
        --清掉所有光效
        machine.m_jackpotBar:hideJackpotLight()
        self.m_winCoinsView:hideView(func)
    else
        self.m_winCoinsView:showView(function(  )
            self:collectNextReward(1,collectData,function(  )
                --清掉所有光效
                machine.m_jackpotBar:hideJackpotLight()
                self.m_winCoinsView:hideView(func)
            end)
        end)
    end

    
    
end

--[[
    结算下一个奖励
]]
function ClawStallInfoView:collectNextReward(index,collectData,func)
    if index > #collectData then
        if type(func) == "function" then
            func()
        end
        return
    end
    local rewardData = collectData[index]

    local items = self.m_collectItems[index]
    
    if rewardData[1] == "-1" then --未抓取
        util_printLog("娃娃状态错误!!!!",true)
        self:collectNextReward(index + 1,collectData,func)
    elseif rewardData[1] == "0" then --未抓到
        self:collectNextReward(index + 1,collectData,func)
    else
        self.m_winCoins = self.m_winCoins + (rewardData[4] or 0)
        -- item:runCsbAction("shouji")
        local curItem = items.normal:isVisible() and items.normal or items.gold
        items.normal:setVisible(false)
        items.gold:setVisible(false)
        if rewardData[1] == "coins" then --抓到金币
            
            self:flyCoinAni(rewardData,curItem,self.m_winCoinsView,function()
                self.m_winCoinsView:updateCoins(self.m_winCoins)
                self:collectNextReward(index + 1,collectData,func)
            end)
        else    --获得jackpot
            self:flyCoinAni(rewardData,curItem,self.m_winCoinsView,function()
                self.m_winCoinsView:updateCoins(self.m_winCoins)
                self:showJackpotWinView(rewardData,function()
                    self:collectNextReward(index + 1,collectData,func)
                end)
                
            end)
            
        end
    end
end

--[[
    显示获得jackpot弹板
]]
function ClawStallInfoView:showJackpotView(rewardData,item,func)
    local machine = ClawStallGameManager:getMachineView()
    local view = util_createView("CodeClawStallPhysicsMachine.ClawStallJackPotView",{
        jackpotType = rewardData[1],
        birdType = rewardData[5] or 1,
        winCoin = rewardData[4] or 0,
        item = item,
        parentView = self,
        func = function()
            if type(func) == "function" then
               func() 
            end
        end
    })
    self:findChild("Node_tanban"):addChild(view)

    machine.m_jackpotBar:showJackpotLight(rewardData[1])
end

--[[
    显示获得jackpot赢钱弹板
]]
function ClawStallInfoView:showJackpotWinView(rewardData,func)
    local machine = ClawStallGameManager:getMachineView()
    local view = util_createView("CodeClawStallPhysicsMachine.ClawStallJackPotWinView",{
        rewardData = rewardData,
        func = function()
            --清理掉结算完的jackpot光效
            self.m_jackpotCounts[rewardData[1]] = self.m_jackpotCounts[rewardData[1]] - 1
            if self.m_jackpotCounts[rewardData[1]] <= 0 then
                machine.m_jackpotBar:hideJackpotLight(rewardData[1])
            end
            
            if type(func) == "function" then
               func() 
            end
        end
    })
    self:findChild("Node_tanban"):addChild(view)
    view:setPosition(cc.p(-display.center.x,-display.center.y))
end

--[[
    金币收集动效
]]
function ClawStallInfoView:flyCoinAni(rewardData,startNode,endNode,func)
    local flyNode
    if startNode.m_clawType == CLAW_MODE.NORMAL then
        flyNode = util_createAnimation("ClawStall_Machine_Grabs.csb")
    else
        flyNode = util_createAnimation("ClawStall_Machine_GrabsSuper.csb")
    end
    local particle = flyNode:findChild("Particle_1")
    particle:setPositionType(0)

    flyNode:findChild("m_lb_mul"):setString("X"..rewardData[2])
    flyNode:findChild("m_lb_mul_0"):setString("X"..rewardData[2])
    if rewardData[1] == "coins" then
        self:changeItemShow(flyNode,"coins",startNode.m_clawType)
        local winCoins = rewardData[4] or 0
        local str = util_formatCoins(winCoins,3)
        flyNode:findChild("m_lb_coins"):setString(str)
    else
        self:changeItemShow(flyNode,"jackpot",startNode.m_clawType)
        if startNode.m_clawType == CLAW_MODE.NORMAL then
            flyNode:findChild("ClawStall_wawaji_wenzi_1_3"):setVisible(rewardData[1] == "grand")
            flyNode:findChild("ClawStall_wawaji_wenzi_2_4"):setVisible(rewardData[1] == "major")
            flyNode:findChild("ClawStall_wawaji_wenzi_3_5"):setVisible(rewardData[1] == "minor")
            flyNode:findChild("ClawStall_wawaji_wenzi_4_6"):setVisible(rewardData[1] == "mini")
        else
            flyNode:findChild("ClawStall_wawaji_grand"):setVisible(rewardData[1] == "grand")
            flyNode:findChild("ClawStall_wawaji_major"):setVisible(rewardData[1] == "major")
            flyNode:findChild("ClawStall_wawaji_minor"):setVisible(rewardData[1] == "minor")
            flyNode:findChild("ClawStall_wawaji_mini"):setVisible(rewardData[1] == "mini")
            flyNode:findChild("m_lb_coins_0"):setString(util_formatCoins(rewardData[3],3))
            flyNode:findChild("m_lb_mul_3"):setString("X"..rewardData[2])
        end
        
    end

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_fly_heart_to_winner)
    local seq = cc.Sequence:create({
        cc.MoveTo:create(25 / 60,endPos),
        cc.CallFunc:create(function()
            particle:stopSystem()
            flyNode:findChild("root"):setVisible(false)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_fly_heart_to_winner_feed_back)
            local feedBackAni = util_createAnimation("ClawStall_shoujichu.csb")
            self.m_effectNode:addChild(feedBackAni)
            feedBackAni:setPosition(endPos)
            feedBackAni:runCsbAction("actionframe3",false,function(  )
                feedBackAni:removeFromParent()
            end)
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji",false,function(  )
        flyNode:findChild("m_lb_coins"):setVisible(false)
    end)
end

--[[
    重置自动抓取按钮状态
]]
function ClawStallInfoView:resetAutoBtnStatus()
    local autoBtn = self.m_grabBtn:findChild("btn_auto")
    autoBtn:setBright(true)
    autoBtn:setTouchEnabled(true)
end

--[[
    设置抓取按钮是否可点击
]]
function ClawStallInfoView:setGrabBtnEnabled(isEnabled,isJoyStickEnabled)
    
    local btn = self.m_grabBtn:findChild("btn_normal")
    btn:setBright(isEnabled)
    btn:setTouchEnabled(isEnabled)

    local autoBtn = self.m_grabBtn:findChild("btn_auto")
    autoBtn:setBright(isEnabled)
    autoBtn:setTouchEnabled(isEnabled)


    if isEnabled then
        self.m_grabBtn:pauseForIndex(0)
    else
        self.m_grabBtn:runCsbAction("idle",true)
        self.m_grabBtn:stopAllActions()
    end
    

    self.m_JoyStick:setTouchEnabled(isJoyStickEnabled)
    self.m_isCanClick = isEnabled
end

--[[
    显示操作提示
]]
function ClawStallInfoView:showControlTip( )
    self.m_JoyStick:showControlTip()
end

--[[
    吸取娃娃反馈光效
]]
function ClawStallInfoView:inDrawingFeedBackAni()
    local ani = util_createAnimation("ClawStall_bao.csb")
    self.m_effectNode:addChild(ani)
    --转化二维坐标
    local clawPos = self.m_mainView:getClawPos()
    local worldPos = self.m_mainView:Convert3DToGL2D(clawPos)
    worldPos.y = worldPos.y - 150
    local pos = self.m_effectNode:convertToNodeSpace(worldPos)
    ani:setPosition(pos)
    ani:runCsbAction("actionframe",false,function(  )
        ani:removeFromParent()
    end)
end

--[[
    go文字提示
]]
function ClawStallInfoView:showGoAni(func)
    local ani = util_createAnimation("ClawStall_Respin_go.csb")
    self:findChild("Node_go"):addChild(ani)
    ani:runCsbAction("start",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

return ClawStallInfoView