---
--smy
--2018年4月18日
--JackpotElvesWheelView.lua
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "JackpotElvesPublicConfig"
local JackpotElvesWheelView = class("JackpotElvesWheelView", util_require("Levels.BaseLevelDialog"))
JackpotElvesWheelView.m_randWheelIndex = nil
JackpotElvesWheelView.m_wheelSumIndex =  18 -- 轮盘有多少块
JackpotElvesWheelView.m_wheelData = {} -- 大轮盘信息
JackpotElvesWheelView.m_wheelNode = {} -- 大轮盘Node 
JackpotElvesWheelView.m_isClicked = nil

local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}

local JACKPOT_INDEX = {
    epic = 1,
    grand = 2,
    ultra = 3,
    mega = 4,
    major = 5,
    minor = 6,
    mini = 7
}

function JackpotElvesWheelView:initUI(data)
    
    self:createCsbNode("JackpotElves/JackpotElvesWheel.csb") 

    self:changeBtnEnabled(false)
    
    self.m_machine = data.machine
    self.m_isNearMiss = false

    self.m_isClicked = true
    self.turnSound = nil
    self.m_wheel = require("CodeJackpotElvesWheelGame.JackpotElvesWheelAction"):create(self:findChild("Node_wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.wheel ) -- 设置轮盘信息

    self:getWheelSymbol()
    -- 点击layer
    self:setTouchLayer()
    -- self:findChild("Button"):setEnabled(false)
end

function JackpotElvesWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:clickFunc()
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()    
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

--[[
    小精灵
]]
function JackpotElvesWheelView:setElves(redElves, greenElves)
    self.m_redElve = redElves
    self.m_greenElve = greenElves
end
--[[
    显示界面动画
]]

function JackpotElvesWheelView:showWheelAni(data, func)
    self:setVisible(true)
    self:showViewAni(data)
    self.m_elvesID = 1
    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
        if func ~= nil then
            func()
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_redPeopleShow)
        self.m_redElve:setVisible(true)
        self:playSpineAnim(self.m_redElve, "chuxian", false, function()
            self:playElveIdle(self.m_redElve)
            self:darkNormalSymbolNode()
            self:delayCallBack(0.4, function()
                self:showJackpotNode(function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_peopleRawUp)
                    self:playSpineAnim(self.m_redElve, "shifa", false, function()
                        self:playElveIdle(self.m_redElve)
                    end)
                    self:delayCallBack(1.1, function()
                        local startPos = util_getConvertNodePos(self:findChild("Node_red"), self:findChild("root"))
                        startPos = cc.p(startPos.x + 80, startPos.y + 80)
                        self:flyParticles(startPos, 1)
                    end)
                end)
            end)

        end)
    end)

end

function JackpotElvesWheelView:flyParticles(startPos, processID)
    local parentNode = self:findChild("root")
    local endPos = cc.p(self:findChild("Node_wheel"):getPosition())
    local flyNode = util_createAnimation("JackpotElves_tw_lizi.csb")
    for id = 1, 3, 1 do
        local particle = flyNode:findChild("ef_lizi"..id)
        particle:setPositionType(0)
        particle:resetSystem()
    end
    parentNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local moveTo = cc.MoveTo:create(0.5, endPos)
    local callFunc = cc.CallFunc:create(function()
        
        for id = 1, 3, 1 do
            local particle = flyNode:findChild("ef_lizi"..id)
            particle:stopSystem()
        end
        --加buff动画
        -- if processID == 1 then
        --     self:addMultiBuffAni(self.m_elvesID, function()
        --         self:addBuffOver(processID)
        --     end)
        if processID == 2 then
            processID = processID + 1
            self:showJackpotNode()
            self:delayCallBack(2, function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElve_rawUpdateForLv)
                self:playSpineAnim(self.m_greenElve, "actionframe3_1", false, function()
                    local startPos = util_getConvertNodePos(self:findChild("Node_green"), self:findChild("root"))
                    startPos = cc.p(startPos.x - 160, startPos.y + 80)
                    self:flyParticles(startPos, processID)
                    self:playSpineAnim(self.m_greenElve, "actionframe3_2", false, function()
                        self:playElveIdle(self.m_greenElve, "idle")
                    end)
                end)
            end)
        else
            self:addMultiBuffAni(self.m_elvesID, function()
                self:addBuffOver(processID)
            end)
        end
        self:runCsbAction("fankui", false, function()
            self:runCsbAction("idle", true)
        end)
        self:delayCallBack(0.5, function ()
            flyNode:removeFromParent()
        end)
    end)
    flyNode:runAction(cc.Sequence:create(moveTo, callFunc))
end

function JackpotElvesWheelView:addBuffOver(processID)
    processID = processID + 1
    if #self.m_bonusData.buff < processID then
        self:runCsbAction("fankui2",true)
        -- self:findChild("Button"):setEnabled(true)
        --恢复点击状态
        self:setClickFlagTrue()
    else
        self.m_elvesID = self.m_elvesID + 1
        if self.m_elvesID > 2 then
            self.m_elvesID = 2
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_lvPeopleShow)
        self.m_greenElve:setVisible(true)
        self:playSpineAnim(self.m_greenElve, "chuxian", false, function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElve_rawUpdateForLv)
            self:playSpineAnim(self.m_greenElve, "actionframe3_1", false, function()
                local startPos = util_getConvertNodePos(self:findChild("Node_green"), self:findChild("root"))
                startPos = cc.p(startPos.x - 160, startPos.y + 80)
                self:flyParticles(startPos, processID)
                self:playSpineAnim(self.m_greenElve, "actionframe3_2", false, function()
                    self:playElveIdle(self.m_greenElve, "idle")
                end)
            end)
            
        end)
    end
    
end

function JackpotElvesWheelView:showViewAni(data)
    

    --设置回调
    self:initCallBack(data.callFunc)
    --重置轮盘角度
    self:findChild("Node_wheel"):setRotation(0)

    self.m_bonusData = clone(data.bonusData)

    self.m_isWaiting = false

    self.m_isNearMiss = false

    self.m_isClicked = true

    self:setWheelData(data.wheel ) -- 设置轮盘信息
    --初始化全部小块
    self:initAllSymbolNode()

end

--[[
    恢复点击事件
]]
function JackpotElvesWheelView:setClickFlagTrue()
    -- 取消压暗
    for index,symbolNode in ipairs(self.m_bigWheelNode) do
        if symbolNode.m_symbolType == "normal" and symbolNode.m_isAddBuff == false then
            symbolNode:playAction("idle")
        end
    end
    self.m_isClicked = false
end

--[[
    隐藏界面动画
]]
function JackpotElvesWheelView:hideViewAni(func)
    self:setVisible(false)
    for index,symbolNode in ipairs(self.m_bigWheelNode) do
        symbolNode:playAction("idle")
    end
    
end

function JackpotElvesWheelView:clickFunc()
    if self.m_isClicked then
        return
    end
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_click)
    self.m_isClicked = true
    self:runCsbAction("idle", true)

    self:playSpineAnim(self.m_redElve, "idle2_1", false, function()
        self:playElveIdle(self.m_redElve, "idle2")
    end)

    self:playSpineAnim(self.m_greenElve, "idle2_1", false, function()
        self:playElveIdle(self.m_greenElve, "idle2_2")
    end)
    self:pauseForIndex(50)
    self.turnSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelZhuan,true)
    self:beginWheelAction()

    self:sendData()
    -- self:findChild("Button"):setEnabled(false)
end

-- 转盘转动结束调用
function JackpotElvesWheelView:initCallBack(callBackFun)
    self.m_endFunc = callBackFun
end

function JackpotElvesWheelView:onEnter()
    JackpotElvesWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function JackpotElvesWheelView:onExit()
   JackpotElvesWheelView.super.onExit(self) 
end

function JackpotElvesWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("JackpotElves_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function JackpotElvesWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 250 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 20 --动态减速度
    wheelData.m_slowQ = 5 --减速圈数
    wheelData.m_stopV = 30 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = function(  ) -- 转盘停止回调
        self:wheelRotateEnd()
    end

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel.m_currentDistance = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    -- self.m_wheel:recvData(self.m_randWheelIndex)
end

-- 返回上轮轮盘的停止位置
function JackpotElvesWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function JackpotElvesWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function JackpotElvesWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        -- gLobalSoundManager:playSound("JackpotElvesSounds/sound_JackpotElves_wheel_rptate.mp3")       
    end
end

-- 设置轮盘网络消息
function JackpotElvesWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

--[[
    创建小块
]]
function JackpotElvesWheelView:getWheelSymbol()
    self.m_bigWheelNode = {}


    for index = 1, self.m_wheelSumIndex, 1 do
        local symbolData = self.m_bigWheelData[index]
        local symbolNode
        if type(symbolData) == "table" then --jackpot类型
            symbolNode = util_createAnimation("JackpotElves_wheel_jackpot_di.csb")
            symbolNode.m_symbolType = "jackpot"

            symbolNode.m_jackpotItems = {}
            for itemIndex = 1,2 do
                local jackpotItem = util_createAnimation("JackpotElves_wheel_jackpot.csb")
                symbolNode.m_jackpotItems[itemIndex] = jackpotItem
                symbolNode:findChild("jackpot1_"..itemIndex):addChild(jackpotItem)
            end
        else    --普通金币类型
            symbolNode = util_createAnimation("JackpotElves_wheel_coin.csb")
            symbolNode.m_symbolType = "normal"
        end

        symbolNode.m_isAddBuff = false
        local parentNode = self:findChild("Node_"..index)
        parentNode:addChild(symbolNode)
        --存储小块数据
        symbolNode.m_symbolData = symbolData
        --小块索引
        symbolNode.m_index = index
        symbolNode:playAction("idle")
        
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = symbolNode
    end
    
end

--[[
    初始化所有小块
]]
function JackpotElvesWheelView:initAllSymbolNode()
    for index,symbolNode in ipairs(self.m_bigWheelNode) do
        local symbolData = self.m_bigWheelData[index]
        if symbolNode.m_symbolType == "jackpot" then --jackpot类型
            for itemIndex = 1,2 do
                local jackpotItem = symbolNode.m_jackpotItems[itemIndex] 
                jackpotItem:setVisible(false)
            end
        end

        symbolNode.m_isAddBuff = false
        --存储小块数据
        symbolNode.m_symbolData = symbolData
        self:updateSymbolNode(symbolNode)
    end
end
--[[
    压暗所有非jackpot 和 没有buff的 小块
]]
function JackpotElvesWheelView:darkNormalSymbolNode()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelJackpotBarAim)
    for index,symbolNode in ipairs(self.m_bigWheelNode) do
        if symbolNode.m_symbolType == "normal" and symbolNode.m_isAddBuff == false then
            symbolNode:playAction("yaan")
        end
    end
end
--[[
    展示第一层 jackpot
]]
function JackpotElvesWheelView:showJackpotNode(func)
    local jackpotNum = 0
    local delayTime = 0.5
    local vecDelayTime = {}
    local iElvesID = self.m_elvesID
    if iElvesID == 2 then
        delayTime = 0
    end
    local wheelData = self.m_bonusData.wheel[iElvesID]
    util_printLog("展示jackpot当前的精灵Id = "..self.m_elvesID,true)
    local json = cjson.encode(self.m_bonusData)
    util_printLog("展示jackpot当前bonusData = "..json,true)
    for index,symbolNode in ipairs(self.m_bigWheelNode) do
        local symbolData = wheelData[1][index]
        if symbolNode.m_symbolType == "jackpot" then --jackpot类型
            jackpotNum = jackpotNum + 1
            local eachTime = (jackpotNum - 1) * delayTime
            vecDelayTime[#vecDelayTime + 1] = eachTime
            local jackpotItems = symbolNode.m_jackpotItems
            local item = jackpotItems[iElvesID]
            self:delayCallBack(vecDelayTime[1], function()
                symbolNode:playAction("start"..iElvesID, false, function()

                end)
                item:setVisible(true)
                item:playAction("start")
                for k,jackpotType in pairs(JACKPOT_TYPE) do
                    item:findChild("Node_"..jackpotType):setVisible(jackpotType == symbolData[iElvesID])
                end
            end)
            table.remove(vecDelayTime, 1)
        end
    end
    self:delayCallBack((jackpotNum + 1) * delayTime, function ()
        if func ~= nil then
            func()
        end
    end)
end

--[[
    刷新信号块
]]
function JackpotElvesWheelView:updateSymbolNode(symbolNode)
    local symbolData = symbolNode.m_symbolData
    if not symbolData then
        return
    end

    if symbolNode.m_symbolType == "normal" then --普通类型
        self:updateCoinLab(symbolNode, symbolData, 1)
    else    --jackpot类型
        if type(symbolData) == "table" and symbolNode.m_jackpotItems then
            local jackpotItems = symbolNode.m_jackpotItems
            if symbolData[1] == "jackpot" then --初始值,不做操作
                for index = 1,#jackpotItems do
                    jackpotItems[index]:setVisible(false)
                end
            else
                --刷新jackpot显示
                for index = 1,#symbolData do
                    local item = jackpotItems[index]
                    item:setVisible(true)
                    item:playAction("idle")
                    for k,jackpotType in pairs(JACKPOT_TYPE) do
                        item:findChild("Node_"..jackpotType):setVisible(jackpotType == symbolData[index])
                    end
                end
            end
        end
        
    end
end
--[[
    update金币奖励
]]
function JackpotElvesWheelView:updateCoinLab(symbolNode, symbolData, multip)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    -- local coins = self:formatStrToPortrait(util_formatCoins(lineBet * symbolData,3)) 
    local coins = util_formatCoinsLN(lineBet * symbolData, 3) 

    local newCoinsArray,splitNum = self:splitCoinsLab(coins)
    if multip == 1 then
        symbolNode:findChild("Node_coin"):setVisible(not symbolNode.m_isAddBuff)
    end
    
    symbolNode:findChild("Node_multi"):setVisible(symbolNode.m_isAddBuff)

    self:showSplitCoins(newCoinsArray,splitNum,symbolNode)
    -- symbolNode:findChild("m_lb_coins"):setString(coins)
    -- symbolNode:findChild("m_lb_coins_2"):setString(coins)
    symbolNode:findChild("m_lb_conis_3"):setString(multip.."X")

    -- self:updateLabelSizeByHeight({label=symbolNode:findChild("m_lb_coins"),sx=1,sy=1},200)
    -- self:updateLabelSizeByHeight({label=symbolNode:findChild("m_lb_coins_2"),sx=1,sy=1},200)
    self:updateLabelSize({label=symbolNode:findChild("m_lb_conis_3"),sx=0.76,sy=0.76},115)
end

--拆分显示钱数的字符串
function JackpotElvesWheelView:splitCoinsLab(str)
    if str == nil or type(str) ~= "string" then
        return {}
     end
 
     local strArray = {}
 
     local strLen = string.len( str )
     local index = 0
     for i=1,strLen do
         local charStr =  string.sub(str,i,i)
                 table.insert( strArray, charStr )
             index = index + 1
     end
 
     return strArray,index
end

function JackpotElvesWheelView:showSplitCoins(Array,splitNum,symbolNode)
    for i=2,6 do
        if i == splitNum then
            symbolNode:findChild("Node_"..i):setVisible(true)
            symbolNode:findChild("Node_"..i.."_1"):setVisible(true)
        else
            symbolNode:findChild("Node_"..i):setVisible(false)
            symbolNode:findChild("Node_"..i.."_1"):setVisible(false)
        end
    end
    for i,v in ipairs(Array) do
        if symbolNode:findChild("m_lb_coins_"..splitNum.."_"..i.."_1") then
            symbolNode:findChild("m_lb_coins_"..splitNum.."_"..i.."_1"):setString(tostring(v))
        end
        if symbolNode:findChild("m_lb_coins_"..splitNum.."_"..i.."_2") then
            symbolNode:findChild("m_lb_coins_"..splitNum.."_"..i.."_2"):setString(tostring(v))
        end
    end
end

--[[
    将金币转化为纵向格式
]]
function JackpotElvesWheelView:formatStrToPortrait(coins)
    
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

--根据高度调整label大小 info={label=cc.label,sx=1,sy=1} length=高度限制 otherInfo={info1,info2,info3,...}
function JackpotElvesWheelView:updateLabelSizeByHeight(info, length, otherInfo)
    local _label = info.label
    if _label.mulNode then
        _label = _label.mulNode
    end
    local height = _label:getContentSize().height
    local scale = length / height
    if height <= length then
        scale = 1
    end

    _label:setScaleX(scale * (info.sx or 1))
    _label:setScaleY(scale * (info.sy or 1))
    if otherInfo and #otherInfo > 0 then
        for k, orInfo in ipairs(otherInfo) do
            orInfo.label:setScaleX(scale * (orInfo.sx or 1))
            orInfo.label:setScaleY(scale * (orInfo.sy or 1))
        end
    end
end

--[[
    数据发送
]]
function JackpotElvesWheelView:sendData()
    if self.m_isWaiting then
        return
    end
    --防止连续点击
    self.m_isWaiting = true
    
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,betLevel = self.m_machine.m_iBetLevel}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function JackpotElvesWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "FEATURE" then
            
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            self:recvBaseData(spinData.result)
        end
    end
end


--[[
    接收数据
]]
function JackpotElvesWheelView:recvBaseData(featureData)
    self.m_featureData = featureData
    self.m_isWaiting = false

    local selfData = featureData.selfData
    self.m_randWheelIndex = selfData.index + 1
    --near miss
    if #self.m_bonusData.buff == 1 then --只有红色精灵的情况下会出现near miss
        --是否出现near miss
        local missList = self:checkNeedNearMiss()
        if #missList ~= 0 then
            self.m_isNearMiss = true
            local randIndex = math.random(1,#missList)
            self.m_randWheelIndex = missList[randIndex]
        end
        
    end

    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)
end

--[[
    检测停止位置两侧的奖励是否比最终奖励差
]]
function JackpotElvesWheelView:checkNeedNearMiss( )
    local wheelData = self.m_bonusData.wheel[1]
    local wheelMultiple = wheelData[2]
    local missList = {}

    
    local endIndex = self.m_randWheelIndex
    local lastWinCoins = self.m_serverWinCoins

    --前一个奖励
    local preIndex = endIndex - 1
    if preIndex <= 0 then
        preIndex = self.m_wheelSumIndex
    end
    local preRewardData = self.m_bigWheelData[preIndex]
    if type(preRewardData) == "table" then

    else
        preRewardData = preRewardData * wheelMultiple[preIndex]
    end


    --后一个奖励
    local nextIndex = endIndex + 1
    if nextIndex > self.m_wheelSumIndex then
        nextIndex = 1
    end
    local nextRewardData = self.m_bigWheelData[nextIndex]
    if type(nextRewardData) == "table" then

    else
        nextRewardData = nextRewardData * wheelMultiple[nextIndex]
    end
    local preWinCoins = self:getWinCoinsByRewardData(preRewardData)
    local nextWinCoins = self:getWinCoinsByRewardData(nextRewardData)

    if preWinCoins < lastWinCoins then
        missList[#missList + 1] = preIndex
    end

    if nextWinCoins < lastWinCoins then
        missList[#missList + 1] = nextIndex
    end

    return missList
end

--[[
    根据奖励数据获取具体赢钱数
]]
function JackpotElvesWheelView:getWinCoinsByRewardData(data)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local winCoins = 0
    if type(data) == "table" then
        local jackpotIndex = JACKPOT_INDEX[data[1]]
        winCoins = self.m_machine:BaseMania_updateJackpotScore(jackpotIndex)
    else
        winCoins = lineBet * data
    end

    return winCoins
end

--[[
    添加乘倍buff动画
]]
function JackpotElvesWheelView:addMultiBuffAni(index, func)
    local buffData = self.m_bonusData.buff[index]
    local wheelData = self.m_bonusData.wheel[index]
    util_printLog("添加buff传进来的精灵Id = "..index,true)
    util_printLog("添加buff当前的精灵Id = "..self.m_elvesID,true)
    local json = cjson.encode(self.m_bonusData)
    util_printLog("添加buff当前bonusData = "..json,true)
    local baseWheelData = wheelData[1]
    local wheelMultiple = wheelData[2]
    for index , symbolData in ipairs(baseWheelData) do
        if type(symbolData) == "number" then
            -- baseWheelData[index] = baseWheelData[index] * wheelMultiple[index]
            if wheelMultiple[index] > 1 then
                local symbolNode = self.m_bigWheelNode[index]
                --加buff状态
                if symbolNode.m_isAddBuff ~= true then
                    symbolNode.m_isAddBuff = true
                    self:updateCoinLab(symbolNode, symbolData, wheelMultiple[index])
                    symbolNode:playAction("start")
                end
            end
        end
    end
    self:setWheelData(baseWheelData)
    self:delayCallBack(1.1, function ()
        if func ~= nil then
            func()
        end
    end)
end

function JackpotElvesWheelView:playSoundNearMiss()
    local randomNum = math.random(1, 3)
    if randomNum == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_nearMissRandom1)
    elseif randomNum == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_nearMissRandom2)
    else
        return
    end
end

--[[
    轮盘停止
]]
function JackpotElvesWheelView:wheelRotateEnd( )
    if self.turnSound then
        gLobalSoundManager:stopAudio(self.turnSound)
        self.turnSound = nil
    end
    if self.m_isNearMiss then
        self:playSoundNearMiss()
        local selfData = self.m_featureData.selfData
        local rightIndex = selfData.index + 1
        local animName = "idle4"
        if (rightIndex > self.m_randWheelIndex) or (math.abs(rightIndex - self.m_randWheelIndex) > 1) then
            animName = "idle7"
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelNearMiss)
        self:playSpineAnim(self.m_redElve, animName, false, function()
            self:playSpineAnim(self.m_redElve, "idle4_1", true)
        end)

        self:delayCallBack(66 / 30, function()
            local nearMissNode = self.m_bigWheelNode[self.m_randWheelIndex]
            
            self.m_randWheelIndex = selfData.index + 1

            local moveDistance = 360 - (self.m_randWheelIndex - 1) * self.m_wheel.m_targetStep  --需要移动的距离
            local node = self:findChild("Node_wheel")
            local seq = cc.Sequence:create({
                cc.RotateTo:create(4 / 30, moveDistance),
                cc.CallFunc:create(function( )
                    nearMissNode:playAction("yaan")
                    self:runCsbAction("fankui3",false,function ()
                        self:showWheelWinCoins()
                    end)
                end)
            })
            node:runAction(seq)
        end)
        
    else
        self:showWheelWinCoins()
    end
end

--[[
    显示转盘玩法赢钱
]]
function JackpotElvesWheelView:showWheelWinCoins()
    local selfData = self.m_featureData.selfData
    local callFunc = function(  )
        
        local winCoins = self.m_serverWinCoins
        self.m_machine:showWheelOverView(winCoins,function(  )
            if type(self.m_endFunc) == "function" then
                self.m_endFunc(self.m_serverWinCoins)
            end
        end)
        
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_wheelNearMissRew)
    self:runCsbAction("actionframe", true)
    if self.m_isNearMiss ~= true then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_peopleJump)
        self:playElveIdle(self.m_redElve, "idle5")
        self:playElveIdle(self.m_greenElve, "idle4")
    end
    --jackpotbar动画
            
    local jackpotList = selfData.jackpotWins
    self.m_machine:showJackpotBarAction(jackpotList)
    self:delayCallBack(3, function()
         -- 计算赢钱类型
         if self.m_isNearMiss ~= true then
            self:playElveIdle(self.m_redElve)
            self:playElveIdle(self.m_greenElve)
        end
        
        local symbolNode = self.m_bigWheelNode[self.m_randWheelIndex]
        if symbolNode.m_symbolType == "normal" then --金币奖励
            
            callFunc()
        else    --获得jackpot
            
            
            if selfData and selfData.jackpotWins then
                --新增中多个jackpot
                if type(jackpotList) == "table" and #jackpotList == 2 then
                    self.m_machine:showTwoJackpotWinView(selfData.jackpotWins,function ()
                        self.m_machine:showJackpotBarIdle()
                        if type(self.m_endFunc) == "function" then
                            self.m_endFunc(self.m_serverWinCoins)
                        end
                    end)
                else
                    self:showJackpotWinView(1,selfData.jackpotWins,function(  )
                        if type(self.m_endFunc) == "function" then
                            self.m_endFunc(self.m_serverWinCoins)
                        end
                    end)
                end
                
            end
            
        end
    end)
   
end

--[[
    显示jackpot赢钱
]]
function JackpotElvesWheelView:showJackpotWinView(index,data,func)
    if index > #data then
        if type(func) == "function" then
            func()
        end
        self.m_machine:showJackpotBarIdle()
        return
    end

    local jackpotType = data[index][1]
    local winCoins = data[index][2]
    self.m_machine:showJackpotWinView(jackpotType,winCoins,function(  )
        self:showJackpotWinView(index + 1,data,func)
    end)
end

--[[
    小精灵 idle
]]
function JackpotElvesWheelView:playElveIdle(spNode, animName)
    if animName then
        self:playSpineAnim(spNode, animName, true)
    else
        local randomNum = math.random(0, 3)
        local animName = "idle"
        if randomNum == 0 then
            animName = "idle3"
        end
        self:playSpineAnim(spNode, animName, false, function()
            self:playElveIdle(spNode)
        end)
    end
    
end

--[[
    首字母大写
]]
function JackpotElvesWheelView:firstToUpper(str)
    local firstChar = string.sub( str,1,1)
    local upperChar = string.upper(firstChar)
    local firstUpper = string.gsub(str,firstChar,upperChar,1)
    return firstUpper
end

--[[
    spine 动画
]]
function JackpotElvesWheelView:playSpineAnim(spNode, animName, isLoop, func)
    util_spinePlay(spNode, animName, isLoop == true)
    if func ~= nil then
        util_spineEndCallFunc(spNode, animName, function()
            func()
        end)
    end
end

--[[
    延迟回调
]]
function JackpotElvesWheelView:delayCallBack(time, func)
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

return JackpotElvesWheelView