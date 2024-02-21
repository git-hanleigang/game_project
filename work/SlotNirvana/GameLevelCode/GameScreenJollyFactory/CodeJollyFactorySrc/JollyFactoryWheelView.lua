---
--xcyy
--2018年5月23日
local PublicConfig = require "JollyFactoryPublicConfig"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local JollyFactoryWheelView = class("JollyFactoryWheelView",util_require("base.BaseView"))

JollyFactoryWheelView.m_isWaiting = false --是否等待网络消息回来
JollyFactoryWheelView.m_featureData = nil --网络消息返回的数据
JollyFactoryWheelView.m_endFunc = nil     --结束回调

local MAX_WHEEL_COUNT   =   12  -- 转盘区域数

--转盘转动方向
local DIRECTION = {
    CLOCK_WISE = 1,             --顺时针
    ANTI_CLOCK_WISH = -1,       --逆时针
}

-- 构造函数
function JollyFactoryWheelView:ctor(params)
    JollyFactoryWheelView.super.ctor(self,params)
    self.m_featureData = SpinFeatureData.new()

    self.m_extraCoins = toLongNumber(0)
    self.m_wheel_run_sound = nil
end

function JollyFactoryWheelView:initUI(params)
    self.m_machine = params.machine
    self.m_endIndex = 0
    self:createCsbNode("JollyFactory/GameScreenWheel.csb")

    local btnLight = util_createAnimation("JollyFactory_Wheel_anniu.csb")
    self:findChild("Node_anniu"):addChild(btnLight)
    btnLight:runCsbAction("idle",true)
    self.m_btnLight = btnLight

    for index = 1,2 do
        local particle = self:findChild("Particle_lz"..index)
        if not tolua.isnull(particle) then
            particle:setVisible(false)
            particle:stopSystem()
        end
    end

    self.m_addCoinsView = util_createAnimation("JollyFactory_Wheel_jiesuan.csb")
    self:findChild("Node_wheel_jiesuan"):addChild(self.m_addCoinsView)
    self.m_addCoinsView:setVisible(false)


    --创建转盘
    self:createWheelNode()

    self.m_isStartMove = false
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JollyFactoryWheelView:initSpineUI()
    self.m_down_light = util_spineCreate("JollyFactory_Wheel_run",true,true)
    self:findChild("Node_down"):addChild(self.m_down_light)
    self.m_down_light:setVisible(false)

    self.m_up_light = util_spineCreate("JollyFactory_Wheel_run",true,true)
    self:findChild("Node_up"):addChild(self.m_up_light)
    self.m_up_light:setVisible(false)

    self.m_clickTip = util_spineCreate("JollyFactory_shou",true,true)
    self:findChild("Node_shou"):addChild(self.m_clickTip)
    util_spinePlay(self.m_clickTip,"idle",true)
    self.m_clickTip:setVisible(false)
end

function JollyFactoryWheelView:onEnter()
    JollyFactoryWheelView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(self, params)
        self:featureResultCallFun(params)
    end,
    ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    创建转盘
]]
function JollyFactoryWheelView:createWheelNode()
    local params = {
        doneFunc = handler(self,self.wheelDown),        --停止回调
        rotateNode = self:findChild("Node_wheel"),      --需要转动的节点
        sectorCount = MAX_WHEEL_COUNT,     --总的扇面数量
        direction = DIRECTION.CLOCK_WISE,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 30,      --最小速度(每秒转动的角度)
        maxSpeed = 600,     --最大速度(每秒转动的角度)
        accSpeed = 400,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 120,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 0,         --开始减速前转动的圈数
        minDistance = 30,   --以最小速度行进的距离
        backDistance = 1,    --回弹距离
        backTime = 0.5      --回弹时间
    }
    self.m_wheel_node = util_require("CodeJollyFactorySrc.JollyFactoryWheelNode"):create(params)
    self:addChild(self.m_wheel_node)

    self.m_wheel_items = {}
    for index = 1,MAX_WHEEL_COUNT do
        local node = self:findChild("Node_"..(index - 1))
        local item = util_createAnimation("JollyFactory_Wheel_item.csb")
        node:addChild(item)
        self.m_wheel_items[index] = item
    end
end


--[[
    获取转盘上的格子
]]
function JollyFactoryWheelView:getWheelItem(index)
    return self.m_wheel_items[index + 1]
end


--[[
    刷新转盘
]]
function JollyFactoryWheelView:updateWheelView(wheelData)
    self.m_wheelData = wheelData
    
    for index = 1,MAX_WHEEL_COUNT do
        local wheelItem = self.m_wheel_items[index]
        local itemData = wheelData[index]
        
        self:updateWheelItemShow(wheelItem,itemData)

    end
end

--[[
    刷新单格区域显示
]]
function JollyFactoryWheelView:updateWheelItemShow(item,itemData)
    if itemData[1] == "lu" then
        item:findChild("Node_jackpot"):setVisible(false)
        item:findChild("Node_coin"):setVisible(false)
        item:findChild("Node_freegames"):setVisible(false)
        local spine = item:findChild("Node_milu"):getChildByName("lu")
        if tolua.isnull(spine) then
            spine = util_spineCreate("Socre_JollyFactory_lu",true,true)
            item:findChild("Node_milu"):addChild(spine)
            spine:setName("lu")
        end

        util_spinePlay(spine,"idle2")

        spine:setVisible(true)

    elseif itemData[1] == "coins" then
        item:findChild("Node_jackpot"):setVisible(false)
        item:findChild("Node_coin"):setVisible(true)
        item:findChild("Node_freegames"):setVisible(false)
        local coins = toLongNumber(itemData[2]) 
        coins = self:formatVerticalCoins(coins)
        local m_lb_coins = item:findChild("m_lb_coins")
        if not tolua.isnull(m_lb_coins) then
            m_lb_coins:setString(coins)
        end
    elseif itemData[1] == "free" then
        item:findChild("Node_jackpot"):setVisible(false)
        item:findChild("Node_coin"):setVisible(false)
        item:findChild("Node_freegames"):setVisible(true)
    else
        item:findChild("Node_jackpot"):setVisible(true)
        item:findChild("Node_coin"):setVisible(false)
        item:findChild("Node_freegames"):setVisible(false)
        item:findChild("Node_grand"):setVisible(itemData[1] == "grand")
        item:findChild("Node_major"):setVisible(itemData[1] == "major")
        item:findChild("Node_minor"):setVisible(itemData[1] == "minor")
        item:findChild("Node_mini"):setVisible(itemData[1] == "mini")
    end
end

--[[
    是否为jackpot
]]
function JollyFactoryWheelView:isJackpotType(rewardType)
    rewardType = string.lower(rewardType)
    if rewardType == "grand" or rewardType == "major" or rewardType == "minor" or rewardType == "mini" then
        return true
    end
    return false
    
end

--[[
    将文字转化为竖向显示
]]
function JollyFactoryWheelView:formatVerticalCoins(coins)
    local coins = util_formatCoinsLN(coins,3)
    local len = string.len(coins)
    local str = ""
    --将文字转换为纵向显示
    for index = 1,len do
        local char = string.sub(coins,index,index)
        if char ~= "," then
            str = str..char.."\n"
        end
    end

    return str
end

--[[
    转盘开始转动
]]
function JollyFactoryWheelView:startWheel()
    self.m_wheel_run_sound = gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wheel_run"],true)
    self.m_wheel_node:startMove()

    self.m_wheel_node:setSlowFunc(function()
        self:hideWheelRotateAni()
    end)

    self:runWheelRotateAni()
end

--[[
    转盘转动动画
]]
function JollyFactoryWheelView:runWheelRotateAni()
    self.m_down_light:setVisible(true)
    self.m_up_light:setVisible(true)
    util_spinePlay(self.m_down_light,"actionframe_down",true)
    util_spinePlay(self.m_up_light,"actionframe_up",true)

    self:runCsbAction("actionframe_down")
    for index = 1,2 do
        local particle = self:findChild("Particle_lz"..index)
        if not tolua.isnull(particle) then
            particle:setVisible(true)
            particle:resetSystem()
        end
    end
end

--[[
    隐藏转盘转动动画
]]
function JollyFactoryWheelView:hideWheelRotateAni()
    self.m_down_light:setVisible(false)
    self.m_up_light:setVisible(false)

    for index = 1,2 do
        local particle = self:findChild("Particle_lz"..index)
        if not tolua.isnull(particle) then
            particle:stopSystem()
        end
    end
end

--[[
    中奖动画
]]
function JollyFactoryWheelView:runHitRewardAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wheel_select"])
    self:runCsbAction("actionframe",true)

    local selfData = self.m_featureData.p_data.selfData
    local wheelResult = selfData.wheelResult
    local rewardType = wheelResult[1]
    local isJackpot = self:isJackpotType(rewardType)
    local winCoins = self.m_featureData.p_data.winAmountValue

    local endFunc = function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc({
                rewardType = rewardType,
                winCoins = winCoins,
                isJackpot = isJackpot
            })

            self:setEndFunc(nil)
        end
    end

    if isJackpot then
        self.m_machine.m_jackPotBarView:showHitLight(rewardType)
    end

    if rewardType == "lu" then
        self:addCoinsByMiLu(function()
            self.m_machine:delayCallBack(0.5,function()
                endFunc()
            end)
        end)
    end

    self.m_machine.m_humanNode:runWheelHitRewardAni(function()
        if isJackpot then
            self.m_machine:delayCallBack(0.5,function()
                endFunc()
            end)
        elseif rewardType == "coins" then
            self.m_machine:delayCallBack(0.5,function()
                endFunc()
            end)
        elseif rewardType == "free" then
            self.m_machine.m_runSpinResultData:parseResultData(self.m_featureData.p_data, self.m_machine.m_lineDataPool)
            endFunc()
        else

        end
    end)
end

--[[
    麋鹿给钱
]]
function JollyFactoryWheelView:addCoinsByMiLu(func)
    local selfData = self.m_featureData.p_data.selfData
    local winCoins = self.m_featureData.p_data.winAmountValue
    local wheelIndex = selfData.wheelIndex
    local extraCash = selfData.extraCash

    local item = self.m_wheel_items[wheelIndex + 1]
    local spine = item:findChild("Node_milu"):getChildByName("lu")

    if not tolua.isnull(spine) then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_milu"])
        util_spinePlay(spine,"move")
        util_spineEndCallFunc(spine,"move",function()

            self.m_btnLight:setVisible(false)
            self:runCsbAction("start")
            self.m_machine:delayCallBack(25 / 60,function()
                
                --显示弹板
                self.m_addCoinsView:setVisible(true)
                self.m_addCoinsView:runCsbAction("start")
                self:updateAddCoins("")

                self.m_machine:delayCallBack(20 / 60,function()
                    --显示麋鹿
                    self.m_machine.m_humanNode:showMiLu(function()
                        self:addNextCoins(extraCash,1,function()
                            if type(func) == "function" then
                                func()
                            end
                        end)
                    end)
                end)
                
            end)
            
            if not tolua.isnull(spine) then
                util_spinePlay(spine,"idle2")
                spine:setVisible(false)
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
end

function JollyFactoryWheelView:addNextCoins(list,index,func)
    if index > #list then
        return
    end
    local multi = list[index]
    local totalBet = self.m_machine:getTotalBet()
    local addCoins = totalBet * multi

    local duration = 0.5
    if index > 2 then
        duration = 1
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_milu_get_coins"])
    --麋鹿舔圣诞老人动作
    self.m_machine.m_humanNode:runMiLuAni(function()
        self:addNextCoins(list,index + 1,func)
    end)

    self.m_machine:delayCallBack(15 / 30,function()
        self.m_addCoinsView:runCsbAction("zengzhang",true)
        self:jumpCoins({
            startCoins = self.m_extraCoins,
            endCoins =  self.m_extraCoins + addCoins,
            duration = duration,
            endFunc = function()
                self.m_addCoinsView:runCsbAction("idle",true)
                if index == #list then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_milu_jump_coins_end"])
                    self.m_addCoinsView:runCsbAction("jiesuan",false,function()
                        if type(func) == "function" then
                            func()
                        end
                    end)
                    for index = 1,6 do
                        local particle = self.m_addCoinsView:findChild("Particle_"..index)
                        if not tolua.isnull(particle) then
                            particle:resetSystem()
                        end
                    end
                end
            end
        })

        self.m_extraCoins  = self.m_extraCoins + addCoins
    end)
    

    
end

--[[
    刷新额外赢钱
]]
function JollyFactoryWheelView:updateAddCoins(coins)
    local m_lb_num = self.m_addCoinsView:findChild("m_lb_num")
    m_lb_num:setString(util_formatCoinsLN(coins,30))
    local info={label = m_lb_num,sx = 0.85,sy = 0.85}
    self:updateLabelSize(info,832)
end

--[[
    金币跳动
]]
function JollyFactoryWheelView:jumpCoins(params)
    local label = self.m_addCoinsView:findChild("m_lb_num")
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or toLongNumber(0)  -- 起始金币
    local endCoins = params.endCoins or  toLongNumber(0)   --结束金币数
    local duration = params.duration or 0.5   --持续时间
    local maxWidth = params.maxWidth or 832 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_JollyFactory_milu_jump_coins --跳动音效
    local jumpSoundEnd --= PublicConfig.SoundConfig.sound_JollyFactory_jump_coins_end --跳动结束音效

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / toLongNumber(120  * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))

    local curCoins = startCoins
    label:stopAllActions()

    if self.m_jump_soundId then
        gLobalSoundManager:stopAudio(self.m_jump_soundId)
        self.m_jump_soundId = nil
    end

    if jumpSound then
        self.m_jump_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            label:stopAllActions()
            if self.m_jump_soundId then
                gLobalSoundManager:stopAudio(self.m_jump_soundId)
                self.m_jump_soundId = nil
            end
            label:setString(util_formatCoinsLN(endCoins,30))
            local info={label = label,sx = 0.85,sy = 0.85}
            self:updateLabelSize(info,maxWidth)
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoinsLN(curCoins,30))

            local info={label = label,sx = 0.85,sy = 0.85}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    转盘停止
]]
function JollyFactoryWheelView:wheelDown()
    if self.m_wheel_run_sound then
        gLobalSoundManager:stopAudio(self.m_wheel_run_sound)
        self.m_wheel_run_sound = nil
    end
    self:runHitRewardAni()
end

--[[
    设置停止索引
]]
function JollyFactoryWheelView:setWheelEndIndex(endIndex)
    self.m_wheel_node:setEndIndex(endIndex)
    self.m_endIndex = endIndex
    
end

function JollyFactoryWheelView:showView()
    self:setVisible(true)
    self.m_clickTip:setVisible(true)
end

--[[
    重置转盘角度
]]
function JollyFactoryWheelView:resetWheel(wheelData)
    self:updateWheelView(wheelData)
    self:runCsbAction("idleframe")
    self.m_wheel_node:resetViewStatus()
    self.m_isEnd = false
    self.m_isStartMove = false
    self.m_isWaiting = false
    self.m_endIndex = 0
    self.m_btnLight:setVisible(true)
    self.m_extraCoins = toLongNumber(0)
    self:updateAddCoins(self.m_extraCoins)
    self.m_addCoinsView:setVisible(false)

    for index = 1,2 do
        local particle = self:findChild("Particle_lz"..index)
        if not tolua.isnull(particle) then
            particle:setVisible(false)
            particle:stopSystem()
        end
    end
end

--[[
    设置结束回调
]]
function JollyFactoryWheelView:setEndFunc(func)
    self.m_endFunc = func
end

--[[
    设置bonus数据
]]
function JollyFactoryWheelView:setBonusData(featureData,endFunc)
    --解析数据(触发时传进来的数据为空)
    if featureData then
        self.m_featureData:parseFeatureData(featureData.result)
    end
end



--默认按钮监听回调
function JollyFactoryWheelView:clickFunc(sender)
    if self.m_isStartMove then
        return
    end
    self.m_isStartMove = true
    self:startWheel()
    self.m_clickTip:setVisible(false)

    self:sendData()
end

------------------------------------网络数据相关------------------------------------------------------------
--[[
    数据发送
]]
function JollyFactoryWheelView:sendData(data)
    
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接数据，data对应发给服务器的select字段
    local messageData = {
        msg=MessageDataType.MSG_BONUS_SELECT,
        jackpot = self.m_jackpotList
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


--[[
    解析返回的数据
]]
function JollyFactoryWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        --防止其他类型消息传到这里
        if spinData.action == "FEATURE" and not self.m_isEnd then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            --bonus中需要带回status字段才会有最新钱数回来
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end

--[[
    网络消息返回
]]
function JollyFactoryWheelView:recvBaseData(featureData)
    self.m_isWaiting = false
    --游戏结束
    if featureData.p_status=="CLOSED" then
        self.m_isEnd = true
    end

    --显示点击的结果
    self:showClickResult()
end

--[[
    显示点击结果
]]
function JollyFactoryWheelView:showClickResult()

    local wheelIndex = self.m_featureData.p_data.selfData.wheelIndex
    self:setWheelEndIndex(wheelIndex)
end

return JollyFactoryWheelView