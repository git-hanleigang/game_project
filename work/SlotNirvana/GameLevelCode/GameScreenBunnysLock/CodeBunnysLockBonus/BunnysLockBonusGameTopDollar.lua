---
--smy
--2018年4月26日
--BunnysLockBonusGameTopDollar.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local BunnysLockBonusGameTopDollar = class("BunnysLockBonusGameTopDollar",BaseGame )

local BTN_TAG_TRY_AGAIN     =       7    --再试一次
local BTN_TAG_TAKE_OFF      =       8    --拿钱走人

local ITEM_COUNT        =       10      

function BunnysLockBonusGameTopDollar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("BunnysLock/TopDollar.csb")

    self:setVisible(false)
    self.m_isCanRecMsg = false

    self.m_curMultiple = 0

    self:findChild("Button_1"):setTag(BTN_TAG_TAKE_OFF)
    self:findChild("Button_2"):setTag(BTN_TAG_TRY_AGAIN)

    self.m_btn_light_1 = util_createAnimation("BunnysLock/TopDollar_anniu_light.csb")
    self.m_btn_light_2 = util_createAnimation("BunnysLock/TopDollar_anniu_light.csb")

    self:findChild("Button_1_light"):addChild(self.m_btn_light_1)
    self:findChild("Button_2_light"):addChild(self.m_btn_light_2)

    self.m_btn_light_1:setVisible(false)
    self.m_btn_light_2:setVisible(false)

    -- self:findChild("star"):setVisible(false)
    -- self:findChild("over"):setVisible(true)
    self:runCsbAction("idleframe")

    self.m_lbl_cur_multi = self:findChild("topdollar_shuzi_2")
    self.m_lbl_leftTimes = self:findChild("topdollar_shuzi_1")
    self.m_lbl_winCoins = self:findChild("topdollar_shuzi_0")

    self.m_egg_items = {}
    for index = 1,ITEM_COUNT do
        local item = util_createView("CodeBunnysLockBonus.BunnysLockTopDollarItem",{parentView = self,index = index})
        self:findChild("dan_"..(index - 1)):addChild(item)
        self.m_egg_items[index] = item

        util_setCascadeOpacityEnabledRescursion(self:findChild("dan_"..(index - 1)),true)
    end
end

function BunnysLockBonusGameTopDollar:showView(bonusData,func)
    self:setVisible(true)
    self:setEndCallFunc(func)
    self.m_isCanRecMsg = true
    self.m_isEnd = false
    self.m_bonusData = bonusData
    self:runCsbAction("idleframe")
    self.m_curMultiple = 0
    self.m_lbl_winCoins.m_curCoins = 0

    self:resetView()

    self:showRewardStart()
end

--[[
    展示奖励开始动画
]]
function BunnysLockBonusGameTopDollar:showRewardStart()
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idleframe")

        --所有蛋循环亮起两次
        self:runTwinkleAni(function()
            self:runTwinkleAni(function()
                self:lightAllEgg(function()
                    local curTimes = self.m_bonusData.turn_hit - self.m_bonusData.topdollartime + 1
                    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_topdollar_click_"..curTimes..".mp3")
                    --切换文案
                    self:runCsbAction("change",false,function()
                        self:runTwinkleAni(function()
                            self:showResult()
                        end)
                    end)
                end)
            end)
        end)
    end)
end

--[[
    所有蛋同时亮起
]]
function BunnysLockBonusGameTopDollar:lightAllEgg(func)
    for index,eggItem in ipairs(self.m_egg_items) do
        eggItem:runLightToDarkAni()
    end

    self.m_machine:delayCallBack(60 / 60,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    所有蛋闪烁
]]
function BunnysLockBonusGameTopDollar:runTwinkleAni(func)
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_topdollar_show_all_egg.mp3")
    local light_index = {
        {8,9},
        {4,5},
        {7,10},
        {3,6},
        {1,2}
    }
    for iLight = 1,#light_index do
        local temp = light_index[iLight]
        for index = 1,#temp do
            local eggItem = self.m_egg_items[temp[index]]
            self.m_machine:delayCallBack(0.1 * (iLight - 1),function()
                eggItem:runTwinkleAni()
            end)
        end
    end
    local delayTime = 0.2 * (#light_index - 1) + 50 / 60
    self.m_machine:delayCallBack(delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function BunnysLockBonusGameTopDollar:hideView()
    self:setVisible(false)
    self.m_isCanRecMsg = false
end

--[[
    显示结果
]]
function BunnysLockBonusGameTopDollar:showResult(func)
    local result = self.m_bonusData.topdollarwin.result
    table.sort(result,function(a,b)
        return a[2] < b[2]
    end)

    self:showNextEgg(result,1,function()
        --刷新按钮状态
        self:findChild("Button_1"):setBright(true)
        self:findChild("Button_1"):setTouchEnabled(true)
        self.m_btn_light_1:setVisible(true)
        self.m_btn_light_1:runCsbAction("actionframe",false,function()
            self.m_btn_light_1:runCsbAction("actionframe1",true)
        end)

        if self.m_bonusData.topdollartime == 0 then
            self:findChild("Button_2"):setBright(false)
            self:findChild("Button_2"):setTouchEnabled(false)
        else
            self:findChild("Button_2"):setBright(true)
            self:findChild("Button_2"):setTouchEnabled(true)
            self.m_btn_light_2:setVisible(true)
            self.m_btn_light_2:runCsbAction("actionframe",false,function()
                self.m_machine:delayCallBack(0.5,function()
                    self.m_btn_light_2:runCsbAction("actionframe1",true)
                end)
            end)
        end
        --刷新赢钱
        local topdollarwin = self.m_bonusData.topdollarwin
        self.m_lbl_cur_multi:setString("x"..topdollarwin.win)
        
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示下个中的蛋
]]
function BunnysLockBonusGameTopDollar:showNextEgg(result,index,func)
    if index > #result then
        if type(func) == "function" then
            func()
        end
        return
    end
    local data = result[index]

    local callFunc = function()
        self.m_machine:delayCallBack(0.3,function()
            self:showNextEgg(result,index + 1,func)
        end)
        
    end
    
    local eggItem = self.m_egg_items[data[1] + 1]
    --高分图标特殊亮起
    if data[1] <= 1 then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_topdollar_show_egg_big.mp3")
        eggItem:runSpecialLightAni(callFunc)
    else
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_topdollar_show_egg_small.mp3")
        eggItem:runLightAni(callFunc)
    end

    self:updateScore(data)
end

function BunnysLockBonusGameTopDollar:updateScore(data)
    self.m_curMultiple = self.m_curMultiple + data[2]
    local avgbet = self.m_machine.m_collectData.avgbet
    local totalWin = self.m_curMultiple * avgbet

    self.m_lbl_cur_multi:setString("x"..self.m_curMultiple)
    -- 
    self:jumpNum(self.m_lbl_winCoins.m_curCoins,totalWin,function()
        
    end)
    self.m_lbl_winCoins.m_curCoins = totalWin
    
end

--[[
    设置结束回调
]]
function BunnysLockBonusGameTopDollar:setEndCallFunc(func)
    self.m_endFunc = func
end

--[[
    按钮回调
]]
function BunnysLockBonusGameTopDollar:clickFunc(sender)
    local btnTag = sender:getTag()
    self.m_btn_light_1:setVisible(false)
    self.m_btn_light_2:setVisible(false)
    self:findChild("Button_1"):setBright(false)
    self:findChild("Button_1"):setTouchEnabled(false)

    self:findChild("Button_2"):setBright(false)
    self:findChild("Button_2"):setTouchEnabled(false)
    if btnTag == BTN_TAG_TRY_AGAIN then --再试一次
        if self.m_bonusData.topdollartime > 0 then
            self:sendData(BTN_TAG_TRY_AGAIN)
        end
    elseif btnTag == BTN_TAG_TAKE_OFF then  --拿钱走人
        self:sendData(BTN_TAG_TAKE_OFF)
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

function BunnysLockBonusGameTopDollar:initViewData(callBackFun, gameSecen)
    self:initData()
end


function BunnysLockBonusGameTopDollar:resetView()
    local topdollarwin = self.m_bonusData.topdollarwin
    local collectData = self.m_machine.m_collectData
    local avgBet = self.m_machine.m_collectData.avgbet

    --刷新中的蛋
    if topdollarwin.multi then
        for index = 1,#topdollarwin.multi do
            local item = self.m_egg_items[index]
            local mutilple = topdollarwin.multi[index]

            item:updateMutilple(util_formatCoins(mutilple * avgBet,3) ,false)
        end
    end
    
    self.m_lbl_cur_multi:setString("x0")
    self.m_lbl_leftTimes:setString(self.m_bonusData.topdollartime)
    self.m_lbl_winCoins:setString(util_formatCoins(0,50))
    self:updateLabelSize({label=self.m_lbl_winCoins,sx=0.55,sy=0.55},670)   

    self.m_btn_light_1:setVisible(false)
    self.m_btn_light_2:setVisible(false)

    self:findChild("Button_1"):setBright(false)
    self:findChild("Button_1"):setTouchEnabled(false)

    self:findChild("Button_2"):setBright(false)
    self:findChild("Button_2"):setTouchEnabled(false)
end

function BunnysLockBonusGameTopDollar:initData()
    self:initItem()
end

function BunnysLockBonusGameTopDollar:initItem()
    
end

--数据发送
function BunnysLockBonusGameTopDollar:sendData(select)
    if self.m_isWaiting then
        return
    end
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")
    self.m_curSelect = select

    if select == BTN_TAG_TAKE_OFF then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_walk_away.mp3")
    else
        local curTimes = self.m_bonusData.turn_hit - self.m_bonusData.topdollartime + 2
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_topdollar_click_"..curTimes..".mp3")
        
    end

    self.m_action=self.ACTION_SEND
    --防止连续点击
    self.m_isWaiting = true

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,data = select}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--数据接收
function BunnysLockBonusGameTopDollar:recvBaseData(featureData)
    self.m_isWaiting = false

    local collectData = featureData.p_data.selfData.collectData
    local mapData = featureData.p_data.selfData.map_result

    self.m_curMultiple = 0

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

    if self.m_curSelect == BTN_TAG_TRY_AGAIN then
        self.m_lbl_winCoins.m_curCoins = 0
        --刷新界面
        self:resetView()
        self:runTwinkleAni(function()
            self:showResult(function()
                if self.m_isEnd then
                    self.m_machine:delayCallBack(0.5,function()
                        self:showWinCoinsView()
                    end)
                end
            end)
        end)
    else
        if self.m_isEnd then
            self.m_machine:delayCallBack(0.5,function()
                self:showWinCoinsView()
            end)
        end
    end
    
end

function BunnysLockBonusGameTopDollar:showWinCoinsView()
    local avgBet = self.m_selfData.collectData.avgbet
    local params = {
        baseCoins = self.m_winAmount - self.m_bonusData.topdollar_money, --地图上的钱
        bonusCoins = self.m_bonusData.topdollar_money, --topdollar的钱
        winCoins = self.m_winAmount
    }
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_topdollar_show_win_coins.mp3")
    self.m_machine:showBonusWinView("topdollar",params,function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_topdollar_exit.mp3")
        self.m_machine:showBonusStart("topdollar",false,function()
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
                self.m_endFunc = nil
            end
            self:hideView()
        end)
        
    end)
    
    
end

function BunnysLockBonusGameTopDollar:sortNetData(data)
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
function BunnysLockBonusGameTopDollar:featureResultCallFun(param)
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

function BunnysLockBonusGameTopDollar:jumpNum(startCoins,coins,func)
    local node = self.m_lbl_winCoins
    self.m_lbl_winCoins:setString(util_formatCoins(startCoins,50))
    self:updateLabelSize({label=self.m_lbl_winCoins,sx=0.55,sy=0.55},670)

    local coinRiseNum =  (coins - startCoins) / 5

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)
    -- coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    node:stopAllActions()
    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            self.m_lbl_winCoins:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.m_lbl_winCoins,sx=0.55,sy=0.55},670)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end

        else

            self.m_lbl_winCoins:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.m_lbl_winCoins,sx=0.55,sy=0.55},670)
        end
        

    end,(55 / 60) / 60)
end

return BunnysLockBonusGameTopDollar