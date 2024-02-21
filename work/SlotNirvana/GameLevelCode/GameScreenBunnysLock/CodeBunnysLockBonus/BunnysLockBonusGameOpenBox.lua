---
--smy
--2018年4月26日
--BunnysLockBonusGameOpenBox.lua
--开箱子玩法(同赛马刮刮乐)

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local BunnysLockBonusGameOpenBox = class("BunnysLockBonusGameOpenBox",BaseGame )

local BTN_TAG_OPEN           =       5    --打开
local BTN_TAG_WALK_AWAY      =       6    --走人

function BunnysLockBonusGameOpenBox:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("BunnysLock/Kaixiangzi.csb")

    self:setVisible(false)
    self.m_isCanRecMsg = false

    self.m_btn_walk = self:findChild("Button_0")
    self.m_btn_open = self:findChild("Button_1")
    self.m_panel = self:findChild("Panel_1")
    self.m_btn_walk:setTag(BTN_TAG_WALK_AWAY)
    self.m_btn_open:setTag(BTN_TAG_OPEN)
    self.m_panel:setTag(BTN_TAG_OPEN)
    self:addClick(self.m_panel)

    --中间的兔子
    self.m_box = util_spineCreate("BunysLock_dajuese",true,true)
    self:findChild("tuzi"):addChild(self.m_box)
    util_spinePlay(self.m_box,"idleframe",true)


    self.m_box_egg = util_createAnimation("Kaixiangzi_box_dan.csb")
    util_spinePushBindNode(self.m_box,"dan_guadian",self.m_box_egg)

    self.m_prizeList = {}
    for index = 1,6 do
        local egg = util_createAnimation("Kaixiangzi_dan.csb")
        for iEgg = 1,6 do
            egg:findChild("dan_"..(iEgg - 1)):setVisible(index == iEgg)
        end
        self:findChild("dan_"..(index - 1)):addChild(egg)
        --刷新光效
        local light = util_createAnimation("BunysLock_kaixiang_tx.csb")
        self:findChild("Node_dan_tx_"..(index - 1)):addChild(light)

        local prizeItem = {
            item = egg,
            light = light,
            label = self:findChild("font_"..(index - 1))
        }

        self.m_prizeList[index] = prizeItem
    end

    --概率标签
    self.m_lbl_probability = self:findChild("lbl_probability")

    self.m_lbl_avg_bet = self:findChild("lbl_avg_bet")
    self.m_lbl_multiples = self:findChild("lbl_multiples")
    self.m_lbl_coins = self:findChild("lbl_coins")
end

function BunnysLockBonusGameOpenBox:showView(bonusData,func)
    self:setVisible(true)
    self:setEndCallFunc(func)
    self.m_isCanRecMsg = true
    self.m_isEnd = false
    self.m_bonusData = bonusData

    util_spinePlay(self.m_box,"idleframe",true)

    self:resetView()
end

function BunnysLockBonusGameOpenBox:hideView()
    self:setVisible(false)
    self.m_isCanRecMsg = false
end

--[[
    设置结束回调
]]
function BunnysLockBonusGameOpenBox:setEndCallFunc(func)
    self.m_endFunc = func
end

--[[
    按钮回调
]]
function BunnysLockBonusGameOpenBox:clickFunc(sender,isScrape)
    local btnTag = sender:getTag()

    if btnTag == BTN_TAG_OPEN then
        self:sendData(BTN_TAG_OPEN)
    elseif btnTag == BTN_TAG_WALK_AWAY then
        self:sendData(BTN_TAG_WALK_AWAY)
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

function BunnysLockBonusGameOpenBox:initViewData(callBackFun, gameSecen)
    self:initData()
end


function BunnysLockBonusGameOpenBox:resetView()
    local collectData = self.m_machine.m_collectData
    self:refreshScore()

    local probability = (1 - self.m_bonusData.pos) * 100
    self.m_lbl_probability:setString(probability)

    local turnbonus = self.m_bonusData.turnbonus
    for index = 1,6 do
        local multi = turnbonus[index] or 0
        self.m_prizeList[index].label:setString("x"..multi)
        if multi == 0 then
            self.m_prizeList[index].item:runCsbAction("dark")
            self.m_prizeList[index].label:setVisible(false)
        else
            self.m_prizeList[index].item:runCsbAction("idleframe")
            self.m_prizeList[index].label:setVisible(true)
        end
    end

    --变更按钮状态
    if self.m_isEnd then
        self.m_btn_walk:setBright(false)
        self.m_btn_walk:setTouchEnabled(false)

        self.m_btn_open:setBright(false)
        self.m_btn_open:setTouchEnabled(false)
        self.m_panel:setVisible(false)
        
    else
        self.m_btn_open:setBright(true)
        self.m_btn_open:setTouchEnabled(true)
        self.m_panel:setVisible(true)

        if self.m_bonusData.turnkind then
            self.m_btn_walk:setBright(true)
            self.m_btn_walk:setTouchEnabled(true)
        else
            self.m_btn_walk:setBright(false)
            self.m_btn_walk:setTouchEnabled(false)
        end
    end
end

--[[
    刷新倍数列表
]]
function BunnysLockBonusGameOpenBox:refreshMultipleList(func)
    local turnbonus = self.m_bonusData.turnbonus
    local delayTime = 0
    for index = 1,6 do
        local prize = self.m_prizeList[index]

        prize.light:runCsbAction("actionframe")
        self.m_machine:delayCallBack(20 / 60,function()
            local multi = turnbonus[index] or 0
            prize.label:setString("x"..multi)

            if multi == 0 then
                prize.item:runCsbAction("dark")
                prize.label:setVisible(false)
            else
                prize.item:runCsbAction("idleframe")
                prize.label:setVisible(true)
            end
        end)
    end
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_refresh_reward_list.mp3")
    self.m_machine:delayCallBack(delayTime + 1,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function BunnysLockBonusGameOpenBox:initData()
    self:initItem()
end

function BunnysLockBonusGameOpenBox:initItem()
    
end

--数据发送
function BunnysLockBonusGameOpenBox:sendData(select)
    if self.m_isWaiting then
        return
    end
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")

    self.m_btn_walk:setBright(false)
    self.m_btn_walk:setTouchEnabled(false)

    self.m_btn_open:setBright(false)
    self.m_btn_open:setTouchEnabled(false)
    self.m_panel:setVisible(false)

    if select == BTN_TAG_WALK_AWAY then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_walk_away.mp3")
    end


    self.m_curSelect = select
    self.m_action=self.ACTION_SEND
    --防止连续点击
    self.m_isWaiting = true

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = select}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--数据接收
function BunnysLockBonusGameOpenBox:recvBaseData(featureData)
    self.m_isWaiting = false

    local collectData = featureData.p_data.selfData.collectData
    local mapData = featureData.p_data.selfData.map_result

    --更新缓存数据
    self.m_machine:updateBonusData(mapData,collectData)
    self.m_selfData = featureData.p_data.selfData
    self.m_bonusData = self.m_selfData.bonus
    self.m_winAmount = featureData.p_data.winAmount
    self.m_machine.m_runSpinResultData.p_winAmount = self.m_winAmount
    self.m_machine.m_runSpinResultData.p_selfMakeData = self.m_selfData
    self.m_machine.m_runSpinResultData.p_features = featureData.p_data.features
    
    --bonus是否结束
    local isBonusEnd = false
    if self.m_selfData.bonus and self.m_selfData.bonus.status == "CLOSED" then
        isBonusEnd = true
    end
    self.m_isEnd = isBonusEnd

    if self.m_curSelect == BTN_TAG_OPEN then
        self:openBoxAni(self.m_isEnd,function()
            self:hitRewardAni(function()
                --收集倍数
                if self.m_isEnd then
                    self.m_machine:delayCallBack(0.5,function()
                        self:showWinCoinsView()
                    end)  
                else
                    self:refreshMultipleList(function()
                        --刷新开出end的概率
                        local probability = (1 - self.m_bonusData.pos) * 100
                        self.m_lbl_probability:setString(probability)
                        self:findChild("Particle_1"):resetSystem()
                        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_refresh_probability.mp3")
                        self:runCsbAction("actionframe1",false,function()
                            self:resetView()
                        end)
                    end)
                end
            end)
        end)
        
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_walk_away.mp3")
        util_spinePlay(self.m_box,"actionframe3",false)
        util_spineEndCallFunc(self.m_box,"actionframe3",function()
            self:showWinCoinsView()
        end)
    end
end

--[[
    开箱子动画
]]
function BunnysLockBonusGameOpenBox:openBoxAni(isEnd,func,endFunc)
    local params = {}
    --开出炸弹
    if isEnd then
        self.m_box_egg:setVisible(false)
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_box,   --执行动画节点  必传参数
            soundFile = "BunnysLockSounds/sound_BunnysLock_box_show_bomb.mp3",  --播放音效 执行动作同时播放 可选参数
            actionName = "actionframe2", --动作名称  动画必传参数,单延时动作可不传
            callBack = function()
                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_after_bomb.mp3")
                util_spinePlay(self.m_box,"idleframe2",true)
                if type(func) == "function" then
                    func()
                end
            end,   --回调函数 可选参数
        }

    else
        self.m_box_egg:setVisible(true)
        for index = 1,6 do
            self.m_box_egg:findChild("dan_"..(index - 1)):setVisible((index - 1) == self.m_bonusData.turnkind)
        end
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_box,   --执行动画节点  必传参数
            actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
            soundFile = "BunnysLockSounds/sound_BunnysLock_box_open.mp3",  --播放音效 执行动作同时播放 可选参数
            callBack = function()
                local randIndex = math.random(1,5)
                gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_show_reward_"..randIndex..".mp3")
                if type(func) == "function" then
                    func()
                end
            end,   --回调函数 可选参数
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_box,   --执行动画节点  必传参数
            actionName = "actionframe1", --动作名称  动画必传参数,单延时动作可不传
            callBack = function()
                
            end,   --回调函数 可选参数
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_box,   --执行动画节点  必传参数
            actionName = "change", --动作名称  动画必传参数,单延时动作可不传
            soundFile = "BunnysLockSounds/sound_BunnysLock_box_change.mp3",  --播放音效 执行动作同时播放 可选参数
            callBack = function()
                util_spinePlay(self.m_box,"idleframe",true)
                if type(endFunc) == "function" then
                    endFunc()
                end
            end
        }
    end
    util_runAnimations(params)
end

function BunnysLockBonusGameOpenBox:showWinCoinsView()
    local avgBet = self.m_selfData.collectData.avgbet
    local params = {
        baseCoins = (self.m_winAmount - self.m_bonusData.box_money), --地图上的钱
        bonusCoins = self.m_bonusData.box_money, --topdollar的钱
        winCoins = self.m_winAmount
    }
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_show_win_coins.mp3")
    self.m_machine:showBonusWinView("box",params,function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_box_exit.mp3")
        self.m_machine:showBonusStart("box",false,function()
            self:hideView()
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
                self.m_endFunc = nil
            end
        end)
        
    end)
    
    
end


--[[
    中奖动画
]]
function BunnysLockBonusGameOpenBox:hitRewardAni(func)
    if self.m_isEnd then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_score_down.mp3")
        
        self:runCsbAction("actionframe",false,function()
            self:jumpNum(self.m_bonusData.multi,function()
                self:refreshScore()
                if type(func) == "function" then
                    func()
                end
            end)
        end)
        
        
        return
    end

    local endNode = self:findChild("lbl_multiples")
    local startNode = self:findChild("font_"..(self.m_bonusData.turnkind))

    local eggItem = self.m_prizeList[self.m_bonusData.turnkind + 1].item
    if eggItem then
        eggItem:runCsbAction("actionframe")
    end
    
    self:flyParticleAni(startNode,endNode,function()
        
        self:runCsbAction("actionframe2",false,function()
            if type(func) == "function" then
                func()
            end
        end)
        
        

        local collectData = self.m_machine.m_collectData
        
        --倍数
        local multi = self.m_bonusData.multi or 0
        self.m_lbl_multiples:setString(multi)

        --平均bet
        local avgBet = collectData.avgbet

        local endCoins = avgBet * multi
        local startCoins = self.m_lbl_coins.m_curCoins
        self:jumpCoins(startCoins,endCoins,function()
            --刷新倍数和赢钱
            self:refreshScore()
        end)
    end)
end

--[[
    刷新分数
]]
function BunnysLockBonusGameOpenBox:refreshScore()
    local collectData = self.m_machine.m_collectData
    --平均bet
    local avgBet = collectData.avgbet
    self.m_lbl_avg_bet:setString(util_formatCoins(avgBet,4))
    --倍数
    local multi = self.m_bonusData.multi or 0
    self.m_lbl_multiples:setString(multi)
    --赢钱数
    local totalCoins = avgBet * multi
    self.m_lbl_coins:setString(util_formatCoins(totalCoins,4))
    self.m_lbl_coins.m_curCoins = totalCoins
end

--[[
    飞粒子动画
]]
function BunnysLockBonusGameOpenBox:flyParticleAni(startNode,endNode,func)
    local ani = util_createAnimation("BonusGameEgg_lizi.csb")
    ani:findChild("Particle_1"):setPositionType(0)
    ani:findChild("Particle_1"):setDuration(-1)
    self:addChild(ani)

    local startPos = util_convertToNodeSpace(startNode,self)
    ani:setPosition(startPos)

    local endPos = util_convertToNodeSpace(endNode,self)

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_fly_prize.mp3")
    local seq = cc.Sequence:create({
        cc.BezierTo:create(0.5,{startPos, cc.p(startPos.x + 300, startPos.y - 10), endPos}),
        cc.CallFunc:create(function(  )
            gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_box_fly_prize_feedback.mp3")
            ani:findChild("Particle_1"):stopSystem()
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    ani:runAction(seq)
end

function BunnysLockBonusGameOpenBox:sortNetData(data)
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
function BunnysLockBonusGameOpenBox:featureResultCallFun(param)
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

function BunnysLockBonusGameOpenBox:jumpNum(multiple,func)

    local node = self.m_lbl_multiples
    node:setString("")

    local coinRiseMul =  -multiple / 60

    local str = string.gsub(tostring(coinRiseMul),"0",math.random( 1, 3 ))
    coinRiseMul = tonumber(str)
    -- coinRiseNum = math.ceil(coinRiseNum ) 

    local curMultiple = multiple * 2
    node:stopAllActions()

    local collectData = self.m_machine.m_collectData
    --平均bet
    local avgBet = collectData.avgbet

    
    util_schedule(node,function()

        curMultiple = curMultiple + coinRiseMul
        --保留小数点后一位
        curMultiple = math.ceil(curMultiple * 10) / 10

        if curMultiple <= multiple then

            curMultiple = multiple

            local node = self.m_lbl_multiples
            node:setString(curMultiple)

            --赢钱数
            local totalCoins = avgBet * curMultiple
            self.m_lbl_coins:setString(util_formatCoins(totalCoins,4))

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end

        else
            local node=self.m_lbl_multiples
            node:setString(curMultiple)

            --赢钱数
            local totalCoins = avgBet * curMultiple
            self.m_lbl_coins:setString(util_formatCoins(totalCoins,4))
        end
        
    end,1 / 60)
end

function BunnysLockBonusGameOpenBox:jumpCoins(startCoins,coins,func)

    local node = self.m_lbl_coins
    self.m_lbl_coins:setString(util_formatCoins(startCoins,4))

    local coinRiseNum =  (coins - startCoins) / 20

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)

    local curCoins = startCoins
    node:stopAllActions()
    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum
        curCoins = math.ceil(curCoins)

        if curCoins >= coins then

            curCoins = coins

            self.m_lbl_coins:setString(util_formatCoins(curCoins,4))

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end
        else
            self.m_lbl_coins:setString(util_formatCoins(curCoins,4))
        end
    end,1 / 60)
end

return BunnysLockBonusGameOpenBox