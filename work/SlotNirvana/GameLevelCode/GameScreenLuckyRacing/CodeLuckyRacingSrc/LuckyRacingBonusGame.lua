---
--smy
--2018年4月26日
--LuckyRacingBonusGame.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local LuckyRacingBonusGame = class("LuckyRacingBonusGame",BaseGame )

local BTN_TAG_WALK_AWAY     =       1001    --结束刮奖
local BTN_TAG_SCRATCH       =       1002    --继续刮奖

local ICON_END = "common/LuckyRacing_END.png"

local BASE_ORDER  =  100

function LuckyRacingBonusGame:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("LuckyRacing/GuaJiang.csb")

    --是否直接显示结果
    self.m_isShowResult = false
    self.m_isWalkAway = false
    self.m_isCanRecMsg = false
    self.m_scrape_soundID = nil
    self.m_isAutoScrape = false

    self.m_node_scratch = self:findChild("node_scratch")

    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,BASE_ORDER)

    --用于创建刮奖层前临时显示
    self.m_tempCoating = self:findChild("meiGua")

    --用于翻页动画
    self.m_pageView = util_createAnimation("LuckyRacing_guakaifanye.csb")
    self:findChild("ef_fanye"):addChild(self.m_pageView)
    self.m_pageView:runCsbAction("idleframe")

    --添加扫光
    self.m_bg_light = util_createAnimation("LuckyRacing_guaka_shuaxinguang_2.csb")
    self.m_bg_light:setVisible(false)
    self:findChild("shg"):addChild(self.m_bg_light)


    self.m_rewardList = {}
    self.m_lightAnis = {}
    for index = 1,6 do
        local node  = self:findChild("jiangpai_"..(index - 1))
        node:removeAllChildren()
        local item = util_createAnimation("LuckyRacing_Jiangpai.csb")
        
        item:findChild("end"):setVisible(false)
        self.m_rewardList[index] = item
        node:addChild(item)

        local light = util_createAnimation("LuckyRacing_guaka_shuaxinguang.csb")
        self:findChild("shuaguang"..index):addChild(light)
        light:setVisible(false)
        self.m_lightAnis[index] = light
    end

    --结束刮奖按钮
    self.m_btn_walk_away = self:findChild("Button_0")
    --继续刮奖按钮
    self.m_btn_scratch = self:findChild("Button_1")

    self.m_lbl_probability = self:findChild("lbl_probability")
    --百分比上升粒子
    self.m_partical_csb = util_createAnimation("LuckyRacing_guaka_lizi.csb")
    self:findChild("ef_guaka_lizi"):addChild(self.m_partical_csb)
    self.m_partical_csb:setVisible(false)

    self.m_btn_walk_away.preParent = self.m_btn_walk_away:getParent()
    self.m_btn_scratch.preParent = self.m_btn_scratch:getParent()

    local coin = self:findChild("coin")
    coin:setVisible(false)
    

    self.m_btn_walk_away:setTag(BTN_TAG_WALK_AWAY)
    self.m_btn_scratch:setTag(BTN_TAG_SCRATCH)

    self.m_rewardItem = util_createAnimation("LuckyRacing_Jiangpai.csb")
    self.m_pageView:findChild("jiangpai"):addChild(self.m_rewardItem)
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function LuckyRacingBonusGame:showView()
    self:setVisible(true)
    self.m_pageView:findChild("meiGua"):setVisible(true)
    self.m_rewardItem:setVisible(true)
    self:findChild("Panel_1"):setVisible(true)
    self.m_effectNode:removeAllChildren(true)

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_bonus.mp3")
    self:runCsbAction("start",false,function()
        self:changeBtnParent(false)
        self:addCoatingLayer()
        self:runCsbAction("idle")
    end)

    self.m_selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    self.m_isEnd = false
    self.m_isCanRecMsg = true
    
    self:refreshCurRewardCoins()

    --刷新中奖列表
    self:refreshRewardList(true)

    local selfData = self.m_selfData
    local mutiples = selfData.treasureMultiple
    if not selfData.treasureMultiple then
        self.m_btn_walk_away:setBright(false)
        self.m_btn_walk_away:setTouchEnabled(false)
    end
    self.m_btn_scratch:setBright(true)
    self.m_btn_scratch:setTouchEnabled(true)
end

function LuckyRacingBonusGame:hideView()
    self.m_machine:setBaseVisible(true)

    

    self.m_machine:clearCurMusicBg()
    self:removeTemp()
    local winAmount = self.m_winAmount
    --检测是否获得大奖
    self.m_machine:checkFeatureOverTriggerBigWin(winAmount, GameEffect.EFFECT_BONUS)
    if self.m_selfData.bonusType == "SIMPLE" then
        self.m_machine:showWinCoinsViewWithOutMultiples(winAmount,function()
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                winAmount, true, true
            })
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
            end
            self.m_endFunc = nil
        end)
    else
        self:changeBtnParent(true)
        local mutilple = self.m_selfData.treasureMultiple
        if not mutilple then
            mutilple = math.floor(winAmount / self.m_selfData.avgBet)
        end
        self.m_rewardItem:setVisible(false)
        self:runCsbAction("over",false,function()
            self:setVisible(false)
        end)
        self.m_machine:delayCallBack(65 / 60,function()
            self:findChild("Panel_1"):setVisible(false)
            self.m_machine:showWinCoinsViewForBonus(self.m_selfData.avgBet,mutilple,winAmount,function()
            
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
                    winAmount, true, true
                })
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                end
                self.m_endFunc = nil
    
            end)
        end)
        
        
    end
    
    
    self.m_isCanRecMsg = false
end

--[[
    设置结束回调
]]
function LuckyRacingBonusGame:setEndCallFunc(func)
    self.m_endFunc = func
end

--[[
    按钮回调
]]
function LuckyRacingBonusGame:clickFunc(sender,isScrape)
    local btnTag = sender:getTag()
    if btnTag == BTN_TAG_WALK_AWAY then --结束刮奖
        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_wise_choice.mp3")
        self:sendData(-1)
        self.m_isWalkAway = true
        self.m_pageView:findChild("meiGua"):setVisible(true)
        self:removeTemp()
    elseif btnTag == BTN_TAG_SCRATCH then   --继续刮奖
        local func = function()
            if self.m_isEnd then
                self:removeTemp()
                --刷新已获得的奖励
                self:refreshCurRewardCoins()
                self.m_machine:delayCallBack(1,function()
                    self:hideView()
                end)
            else
                self:sendData(0)
                self.m_isShowResult = true
            end
        end
        --移除触摸监听
        if self.m_coatingLayer then
            self.m_coatingLayer:unregisterScriptTouchHandler()
        end
        
        if isScrape then
            func()
        else
            --自动刮奖
            self:autoScrape()
        end
    end

    --按钮置灰
    self.m_btn_walk_away:setBright(false)
    self.m_btn_walk_away:setTouchEnabled(false)
    self.m_btn_scratch:setBright(false)
    self.m_btn_scratch:setTouchEnabled(false)

end

--[[
    自动刮奖
]]
function LuckyRacingBonusGame:autoScrape()
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scrape.mp3")
    --安全判定
    if not self.m_coatingLayer then
        self:clickFunc(self.m_btn_scratch,true)
        return
    end

    self.m_isAutoScrape = true

    local touchFunc = self.m_coatingLayer.touchFunc
    local bgSize = self.m_coatingLayer.m_bgSize
    local size = CCSizeMake(180,bgSize.height)
    local centerPos = self.m_coatingLayer.m_pos
    local startPosX = centerPos.x - size.width / 2
    local endPosX = centerPos.x + size.width / 2
    local startPosY = centerPos.y + size.height / 2
    local endPosY = centerPos.y - size.height / 2

    local startPos = cc.p(startPosX,startPosY)
    local endPos = cc.p(endPosX,endPosY)

    local actionNode = cc.Node:create()
    self:addChild(actionNode)
    touchFunc(nil,{
        name = "began",
        x = startPosX,
        y = startPosY
    })
    local offset = 20
    local curPosX = startPosX
    local curPosY = startPosY
    local curDirection = 1  --1往上刮 2往下刮
    util_schedule(actionNode,function()
        local offsetPos = cc.p(0,0)
        if curDirection == 1 then
            curPosX = curPosX + offset
            curPosY = curPosY + offset
            touchFunc(nil,{
                name = "moved",
                x = curPosX,
                y = curPosY
            })
            if curPosX >= endPosX then
                curDirection = 2
                curPosY = curPosY - offset
            elseif curPosY >= startPosY then
                curDirection = 2
                curPosX = curPosX + offset
            end
        else
            curPosX = curPosX - offset
            curPosY = curPosY - offset
            touchFunc(nil,{
                name = "moved",
                x = curPosX,
                y = curPosY
            })
            if curPosX <= startPosX then
                curDirection = 1
                curPosY = curPosY - offset
            elseif curPosY <= endPosY then
                curDirection = 1
                curPosX = curPosX + offset
            end
        end

        if curPosX - 15 <= endPosX and curPosX + 15 >= endPosX and curPosY - 15 <= endPosY and curPosY + 15 >= endPosY then
            touchFunc(nil,{
                name = "ended",
                x = curPosX,
                y = curPosY
            }) 
            actionNode:stopAllActions()
            actionNode:removeFromParent()
            self.m_isAutoScrape = false
        end
        
    end,1 / 120)
end

--[[
    添加涂层
]]
function LuckyRacingBonusGame:addCoatingLayer()
    self.m_node_scratch:removeAllChildren()
    self.m_tempCoating:setVisible(false)
    self.m_pageView:findChild("meiGua"):setVisible(false)
    self:removeTemp()

    local soundID = nil

    local onTouchEvent = function(obj,event)
        if not self.m_coin then
            return
        end
        if event.name == "began" then
            local coin = self:findChild("coin")
            self.m_coin = cc.Sprite:createWithSpriteFrame(coin:getSpriteFrame())
            self.m_coatingLayer:addChild(self.m_coin)

            
            self.m_scrape_soundID = gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_scrape.mp3",true)

        elseif event.name == "moved" then

        elseif event.name == "ended" then
            self.m_coin:runAction(cc.Sequence:create({
                cc.FadeOut:create(0.2),
                cc.RemoveSelf:create(),
                cc.CallFunc:create(function()
                    self.m_coin = nil
                end)
            }))
            self:stopScrapeSound()
            
        end

        -- local worldPos = self.m_coatingLayer:convertToWorldSpace(cc.p(event.x,event.y))
        -- local pos = self:convertToNodeSpace(worldPos)
        self.m_coin:setPosition(cc.p(event.x,event.y))
    end

    local coatingLayer = util_createGuaGuaLeLayer({
        sp_reward = cc.Sprite:create(),      --需要刮出来的奖励精灵
        sp_bg = cc.Sprite:createWithSpriteFrameName("common/LuckyRacing_pai1.png"),          --需要刮开的图层
        size = CCSizeMake(125,130),           --需要刮开的区域大小
        pos = util_convertToNodeSpace(self.m_node_scratch,self),
        onTouch = onTouchEvent,
        startFunc = function ()
            --按钮置灰 奖励刮出来之前不允许点击
            self.m_btn_walk_away:setBright(false)
            self.m_btn_walk_away:setTouchEnabled(false)
            self.m_btn_scratch:setBright(false)
            self.m_btn_scratch:setTouchEnabled(false)
            self:changeBtnParent(true)
        end,
        callBack = function()
            self:changeBtnParent(false)
            self:clickFunc(self.m_btn_scratch,true)
        end        --刮开结束回调
    })
    self:addChild(coatingLayer,BASE_ORDER - 20)
    self.m_coatingLayer = coatingLayer

    -- local coin = self:findChild("coin")
    -- coin:setVisible(false)
    -- local pos = util_convertToNodeSpace(coin,self)
    -- self.m_coin = cc.Sprite:createWithSpriteFrame(coin:getSpriteFrame())
    -- self:addChild(self.m_coin)
    -- self.m_coin:setPosition(pos)

    

    if not self.m_isEnd then
        --刷新奖励
        self:refreshReward()

        --刷新中奖列表
        -- self:refreshRewardList()
        --刷新已获得的奖励
        self:refreshCurRewardCoins()
    end
    
end

--[[
    停止挂卡音效
]]
function LuckyRacingBonusGame:stopScrapeSound( )
    if self.m_scrape_soundID then
        gLobalSoundManager:stopAudio(self.m_scrape_soundID)
        self.m_scrape_soundID = nil
    end

    
end

--[[
    修改按钮父节点
]]
function LuckyRacingBonusGame:changeBtnParent(isPutBack)
    if isPutBack then
        local pos1 = util_convertToNodeSpace(self.m_btn_scratch,self.m_btn_scratch.preParent)
        util_changeNodeParent(self.m_btn_scratch.preParent,self.m_btn_scratch) 
        self.m_btn_scratch:setPosition(pos1)

        local pos2 = util_convertToNodeSpace(self.m_btn_walk_away,self.m_btn_walk_away.preParent)
        util_changeNodeParent(self.m_btn_walk_away.preParent,self.m_btn_walk_away) 
        self.m_btn_walk_away:setPosition(pos2)
    else
        local pos1 = util_convertToNodeSpace(self.m_btn_scratch,self)
        util_changeNodeParent(self,self.m_btn_scratch,BASE_ORDER - 10) 
        self.m_btn_scratch:setPosition(pos1)

        local pos2 = util_convertToNodeSpace(self.m_btn_walk_away,self)
        util_changeNodeParent(self,self.m_btn_walk_away,BASE_ORDER - 10) 
        self.m_btn_walk_away:setPosition(pos2)
    end
end

--[[
    移除临时控件
]]
function LuckyRacingBonusGame:removeTemp()
    if self.m_coatingLayer then
        self.m_coatingLayer:removeFromParent()
        self.m_coatingLayer = nil
    end
    -- self:findChild("coin"):setVisible(true)
end

--[[
    刷新奖励
]]
function LuckyRacingBonusGame:refreshReward()
    for index = 1,7 do
        self.m_rewardItem:findChild("jiangpai_"..(index - 1)):setVisible(false)
    end

    self.m_rewardItem:findChild("end"):setVisible(self.m_selfData.hitNext == 0)
    if self.m_selfData.hitNext ~= 0 then
        --需要刮出来的奖励
        local selfData = self.m_selfData
        self.m_curHitIndex,self.m_curMutilples = self:getCurHitIndex()
        self.m_rewardItem:findChild("jiangpai_"..(self.m_curHitIndex - 1)):setVisible(true)
    end
    
end

--[[
    获取当前中奖索引
]]
function LuckyRacingBonusGame:getCurHitIndex()
    local selfData = self.m_selfData
    local curHitIndex = -1
    for index,mutilples in pairs(selfData.multiples) do
        if mutilples == selfData.hitNext then
            curHitIndex = index
            break
        end
    end

    return curHitIndex,selfData.hitNext
end

--[[
    刷新中奖列表
]]
function LuckyRacingBonusGame:refreshRewardList(isInit)
    local selfData = self.m_selfData
    local curHitIndex = -1
    local mutilples = selfData.multiples
    if mutilples then
        for index = 1,6 do
            local item = self.m_rewardList[index]
            if mutilples[index] then
                for iColor = 1, 7 do
                    item:findChild("jiangpai_"..(iColor - 1)):setVisible(index == iColor)
                end
                self:findChild("font_"..(index - 1)):setString("X"..mutilples[index])
            else
                for iColor = 1, 7 do
                    item:findChild("jiangpai_"..(iColor - 1)):setVisible(7 == iColor)
                end
                self:findChild("font_"..(index - 1)):setString("")
            end
        end
    end
    

    --刷新结束概率
    self.m_lbl_probability:setString(selfData.endRange.."%")

    if not isInit and selfData.endRange > 0 then
        self.m_partical_csb:setVisible(true)
        self.m_partical_csb:findChild("Particle_1"):resetSystem()
        self.m_partical_csb:findChild("Particle_2"):resetSystem()
    end
    
end

--[[
    刷新已获得的奖励
]]
function LuckyRacingBonusGame:refreshCurRewardCoins()
    --需要刮出来的奖励
    local selfData = self.m_selfData
    self:findChild("lbl_avg_bet"):setString(util_formatCoins(selfData.avgBet,3))
    local mutiples = selfData.treasureMultiple or 0
    self:findChild("lbl_multiples"):setString(util_formatCoins(mutiples,3))
    self:findChild("lbl_coins"):setString(util_formatCoins(selfData.avgBet * mutiples,3))
end

--[[
    创建下一个涂层
]]
function LuckyRacingBonusGame:createNextCoatingLayer()
    self:hitRewardAni(function()
        --刷新已获得的奖励
        self:refreshCurRewardCoins()
        if not self.m_isEnd then
            self.m_btn_walk_away:setBright(true)
            self.m_btn_walk_away:setTouchEnabled(true)
            self.m_btn_scratch:setBright(true)
            self.m_btn_scratch:setTouchEnabled(true)
            self:addCoatingLayer()
        end
    end)
end

--[[
    飞粒子动画
]]
function LuckyRacingBonusGame:flyParticleAni(startNode,endNode,multiple,func)
    local ani = util_createAnimation("LuckyRacing_Jiangpai_shizi.csb")
    ani:findChild("ef_lizi"):setPositionType(0)
    ani:findChild("ef_lizi"):setDuration(-1)
    ani:findChild("font"):setString("x"..multiple)
    self.m_effectNode:addChild(ani)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    ani:setPosition(startPos)

    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local seq = cc.Sequence:create({
        -- cc.MoveTo:create(0.5,endPos),
        cc.BezierTo:create(0.5,{startPos, cc.p(startPos.x + 300, startPos.y - 10), endPos}),
        cc.CallFunc:create(function(  )
            ani:findChild("ef_lizi"):stopSystem()
            ani:findChild("font"):setVisible(false)
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_bonus_reward_collect.mp3")
    ani:runAction(seq)
end

function LuckyRacingBonusGame:jumpNum(coins )

    local node = self:findChild("lbl_multiples")
    node:setString("")

    local coinRiseNum =  -coins / 60 / (55 / 60)

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = coins * 2
    node:stopAllActions()


    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum

        if curCoins <= coins then

            curCoins = coins

            local node = self:findChild("lbl_multiples")
            node:setString(util_formatCoins(curCoins,3))
            local info={label = node,sx = 0.4,sy = 0.4}
            self:updateLabelSize(info,370)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            node:stopAllActions()

        else
            local node=self:findChild("lbl_multiples")
            node:setString(util_formatCoins(curCoins,3))

            local info={label = node,sx = 0.4,sy = 0.4}
            self:updateLabelSize(info,370)
        end
        

    end,(55 / 60) / 60)
end

--[[
    中奖动画
]]
function LuckyRacingBonusGame:hitRewardAni(func)
    if self.m_isEnd then
        local ani = util_createAnimation("LuckyRacing_guakashoujifankui.csb")
        self:findChild("ef_shoujifankui"):addChild(ani)

        gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_multiples_cut_down.mp3")

        ani:runCsbAction("weizhong",false,function ()
            ani:removeFromParent()

            if type(func) == "function" then
                func()
            end
        end)
        --需要刮出来的奖励
        local mutiples = self.m_selfData.treasureMultiple or 0
        self:jumpNum(mutiples)
        return
    end
    
    local randSoundIndex = math.random(1,5)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_show_reward_"..randSoundIndex..".mp3")
    self.m_rewardItem:runCsbAction("actionframe",false,function()
        self.m_rewardItem:runCsbAction("idleframe")
    end)

    self.m_machine:delayCallBack(40 / 60,function()
        local endNode = self:findChild("lbl_multiples")
        local startNode = self:findChild("font_"..(self.m_curHitIndex - 1))
        
        self:flyParticleAni(startNode,endNode,self.m_curMutilples,function()
            local ani = util_createAnimation("LuckyRacing_guakashoujifankui.csb")
            self:findChild("ef_shoujifankui"):addChild(ani)
            if not self.m_isEnd then
                --刷新已获得的奖励
                self:refreshCurRewardCoins()
            end
            gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_bonus_reward_collect_over.mp3")
            
            ani:runCsbAction("zhongjiang",false,function ()
                ani:removeFromParent()

                --显示临时的涂层
                self.m_tempCoating:setVisible(true)
                gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_bonus_change_reward.mp3")
                --翻页动画
                self.m_pageView:runCsbAction("actionframe",false,function()
                    self.m_pageView:runCsbAction("idleframe")
                    if type(func) == "function" then
                        func()
                    end
                end)

                --扫光动画
                self:runLightAni()

                self.m_machine:delayCallBack(0.3,function()
                    self:refreshRewardList()
                end)
                
            end)
        end)
    end)

    if self.m_curHitIndex <= 6 then
        local item = self.m_rewardList[self.m_curHitIndex]
        if item then
            item:runCsbAction("actionframe",false,function()
                item:runCsbAction("idleframe")
            end)
        end
    end

    
end

--[[
    扫光动画
]]
function LuckyRacingBonusGame:runLightAni()
    self.m_bg_light:setVisible(true)
    -- self.m_bg_light:findChild("ef_lizi"):setVisible(true)
    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_bonus_change_rewardList.mp3")

    self.m_bg_light:runCsbAction("actionframe",false,function()
        self.m_machine:delayCallBack(1,function()
            self.m_bg_light:setVisible(false)
        end)
        
    end)
    
    --刷新光粒子
    local lizi = util_createAnimation("LuckyRacing_guaka_shuaxinlizi.csb")
    local node = self.m_bg_light:findChild("ef_lizi")
    node:removeAllChildren()
    node:addChild(lizi)
    lizi:findChild("Particle_1"):setPositionType(0)
    lizi:findChild("Particle_1"):setDuration(-1)
    util_setCascadeOpacityEnabledRescursion(node,true)

    self.m_machine:delayCallBack(35 / 60,function()
        lizi:findChild("Particle_1"):stopSystem()
        self.m_machine:delayCallBack(1,function()
            node:removeAllChildren()
        end)
        
    end)
    for index = 1,6 do
        self.m_lightAnis[index]:setVisible(true)
        self.m_lightAnis[index]:runCsbAction("actionframe",false,function()
            self.m_lightAnis[index]:setVisible(false)
        end)
    end
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function LuckyRacingBonusGame:initViewData(callBackFun, gameSecen)
    self:initData()
end


function LuckyRacingBonusGame:resetView(featureData, callBackFun, gameSecen)
    self:initData()
end

function LuckyRacingBonusGame:initData()
    self:initItem()
end

function LuckyRacingBonusGame:initItem()
    
end

--数据发送
function LuckyRacingBonusGame:sendData(bonusAct)
    if self.m_isWaiting then
        return
    end


    self.m_action=self.ACTION_SEND
    --防止连续点击
    self.m_isWaiting = true

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,bonusSelect = bonusAct}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--数据接收
function LuckyRacingBonusGame:recvBaseData(featureData)
    self.m_isWaiting = false

    self.m_selfData = featureData.p_data.selfData
    self.m_bonusData = featureData.p_bonus
    self.m_winAmount = featureData.p_data.winAmount

    self.m_machine.m_runSpinResultData.p_selfMakeData = featureData.p_data.selfData
    
    --bonus是否结束
    local isBonusEnd = false
    if featureData.p_bonus and featureData.p_bonus.status == "CLOSED" then
        isBonusEnd = true
    end
    self.m_isEnd = isBonusEnd

    if self.m_isShowResult then
        self.m_isShowResult = false
        self:removeTemp()

        self:createNextCoatingLayer()
    end

    if isBonusEnd then
        if self.m_isWalkAway then
            self.m_isWalkAway = false
            self:hideView()
        else
            self.m_machine:delayCallBack(1,function()
                self:hideView()
            end)
        end

    end
end

function LuckyRacingBonusGame:sortNetData(data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status

        end
    end 

    localdata = data

    return localdata
end

--[[
    接受网络回调
]]
function LuckyRacingBonusGame:featureResultCallFun(param)
    if not self.m_isCanRecMsg  then
        return
    end
    if type(param[2]) ~= "table" then
        return
    end
    local result = param[2].result
    if result and result.action == "BONUS" then
        self.super.featureResultCallFun(self,param)
    end
    
end

return LuckyRacingBonusGame