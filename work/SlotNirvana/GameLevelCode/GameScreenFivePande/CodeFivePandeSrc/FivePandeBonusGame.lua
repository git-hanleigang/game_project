---
--smy
--2018年4月26日
--FivePandeBonusGame.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local FivePandeBonusGame = class("FivePandeBonusGame",BaseGame )
FivePandeBonusGame.m_mainClass = nil
FivePandeBonusGame.isClickNow = nil

function FivePandeBonusGame:initUI()

    self.isClickNow = false
    self.m_isShowTournament = true

    self:createCsbNode("FivePande/BonusGame.csb",false)
    self.m_isBonusCollect=true
    
    -- TODO 输入自己初始化逻辑


    self.m_labNode = util_createAnimation("BonusGamechengbei.csb")
    self:findChild("Node_BetLab"):addChild(self.m_labNode)
    self.m_labNode:runCsbAction("actionframe")
    self.m_labNode:setVisible(false)
    
end

--创建csb节点
function FivePandeBonusGame:createCsbNode(filePath,isAutoScale)
    self.m_baseFilePath=filePath
    self.m_csbNode,self.m_csbAct=util_csbCreate(self.m_baseFilePath,self.m_isCsbPathLog)
    self:addChild(self.m_csbNode)
    self:bindingEvent(self.m_csbNode)
    self:pauseForIndex(0)
    if isAutoScale then
        -- if tolua.type(self.m_csbNode)=="cc.Layer" then
            util_csbScale(self.m_csbNode,self:getUIScalePro() + 0.1)
        -- end
    end

end

function FivePandeBonusGame:changeMul()
    -- self.m_labNode.m_csbOwner["m_lb_mul"]:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,0.7),cc.ScaleTo:create(0.2,1)))
    -- scheduler.performWithDelayGlobal(function()
        self.m_labNode:runCsbAction("collect1")
        self.m_labNode.m_csbOwner["m_lb_mul"]:setString("*"..self.m_mul)
    -- end,0.2,"FivePande_BonusGame")
end

function FivePandeBonusGame:showStartView(func)
    local view = util_createView("CodeFivePandeSrc.FivePandeBonusStart")
    view:initViewData(func)
    self:findChild("Node_7"):addChild(view,1)
end
function FivePandeBonusGame:showRewardView(pool,mul,total)


    self.m_mainClass:BaseMania_completeCollectBonus()
    self.m_mainClass:updateCollect()

    -- self:findChild("root"):setVisible(false)
    local view = util_createView("CodeFivePandeSrc.FivePandeBonusOver")

    gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_bonus_win.mp3")

    view:initViewData(pool,mul,total,
    function()

        if self.m_serverWinCoins == self.m_totleWimnCoins then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,true})
        else

            globalData.lastWinCoin = tonumber(self.m_totleWimnCoins)
          
        end
        
        self.m_mainClass.m_ShowBonus = false

        if self.m_callFunc then
            self.m_callFunc()
        end

        util_playFadeOutAction(self,0.2,function(  )
            
            self:removeFromParent()
        end)
        
    end)
    view:setPosition(- display.width / 2 ,- display.height / 2)
    self:addChild(view,1)
end

function FivePandeBonusGame:onEnter()
    BaseGame.onEnter(self)
end
function FivePandeBonusGame:onExit()
    scheduler.unschedulesByTargetName("FivePande_BonusGame")
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end


--------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function FivePandeBonusGame:initViewData(data,callBackFun,mainClass)
    self.m_mainClass = mainClass
    self:initData()
    self.m_collectDataList=data
    self.m_pool=self.m_collectDataList[1].p_collectCoinsPool
    self.m_labNode.m_csbOwner["m_lb_pool"]:setString(util_formatCoins(self.m_pool, 3))
    self:changeMul()
    self.m_callFunc=callBackFun

    self:findChild("root"):setVisible(false)

    -- self:sendStartGame()
    gLobalSoundManager:playSound("FivePandeSounds/sound_despicablewolf_enter_fs.mp3")
    self:showStartView(
    function()
        self.m_currentMusicId = gLobalSoundManager:playBgMusic( "FivePandeSounds/music_despicablewolf_bonus_bg.mp3")
        -- self.m_leftBG:runAction(cc.FadeIn:create(1))
        -- self.m_rightBG:runAction(cc.FadeIn:create(1))
        self:findChild("root"):setVisible(true)
        self.m_labNode:runCsbAction("actionframe")
        self.m_labNode:setVisible(true)

        self:runCsbAction("actionframe",false,function()
            self:runCsbAction("actionframe1",true)
        end)
        local cb = cc.CallFunc:create(function()
                self:startGameCallFunc()

               self:openItems()
        end)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cb))
    end)
end


function FivePandeBonusGame:openItems()
    for k = 1, 10 do
        self.m_itemList[k]:setVisible(true)
        self.m_itemList[k]:showItemStart()
    end 

    local cb = cc.CallFunc:create(function()
        for k = 1, 10 do
            self.m_itemList[k]:showIdle()
        end   
        
        -- self:sendStartGame()
    end)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cb))          
end

function FivePandeBonusGame:resetView(collectData,featureData,callBackFun, mainClass)
    self.m_mainClass = mainClass 
    self:initData()
    self.m_callFunc=callBackFun
    self.m_pool=collectData.p_collectCoinsPool
    self.m_labNode.m_csbOwner["m_lb_pool"]:setString(util_formatCoins(self.m_pool, 3))
    self:changeMul()
    self:findChild("root"):setVisible(true)
    -- self.m_leftBG:setOpacity(255)
    -- self.m_rightBG:setOpacity(255)
    for k = 1, 10 do
        self.m_itemList[k]:setVisible(true)
        self.m_itemList[k]:showIdle()
    end 

    self.m_labNode:runCsbAction("actionframe")
    self.m_labNode:setVisible(true)

    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("actionframe1",true)
    end)

    scheduler.performWithDelayGlobal(function()
        self:continueGame(featureData)
    end,2,"FivePande_BonusGame")
end

function FivePandeBonusGame:initData()
    self.m_itemList={}
    self.m_mul=1
    self.m_pool=0
    self:initItem()
end
function FivePandeBonusGame:initItem()
    local function itemFunc(pos)
        
        self:sendStep(pos)
    end
    for i = 1, 10 do 
        print("init item %d" , i)
        local item = util_createView("CodeFivePandeSrc.FivePandeBonusItem")
        item:initItem(self,i,itemFunc)
        self.m_csbOwner["node_"..i]:addChild(item)
        self.m_itemList[i] = item
        item:setVisible(false)
    end
end

--处理服务器数据
function FivePandeBonusGame:recvData(selectData,isReward)
    --奖励计算
    print("--------------recvData")
    if selectData then
        self.m_mul=self.m_mul+math.abs(selectData)
    end
end

--数据发送
function FivePandeBonusGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else
        
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData=nil
        if self.m_isBonusCollect then
            
            messageData={msg= "nil" , clickPos= pos - 1 } -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
        end
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    end
end


--服务器数据展示(宝箱奖励展示)
function FivePandeBonusGame:showStep(pos,selectData)
    self.isClickNow = false
    
    if not selectData then
        return
    end

    

    self:changeMul()
    self.m_itemList[pos]:showClick(math.abs(selectData),selectData>0)
end

--弹出结算界面前展示其他宝箱数据
function FivePandeBonusGame:showOther()
    print("--------------showOther")
    for k,v in ipairs(self.p_chose) do
        self.p_contents[v+1]=-100
    end
    local other_list={}
    for i=1,10 do
        if not self.m_itemList[i].isShowItem then
            other_list[#other_list+1]=i
        end
    end

    local notChooseArray = {}
    local notChoose_index=1
    for k,v in ipairs(self.p_contents) do
        if v~=-100 then
            if notChoose_index<=#other_list and other_list[notChoose_index]<=#self.m_itemList then
                if v < 5 then
                    table.insert( notChooseArray, notChoose_index )
                end
                notChoose_index=notChoose_index+1
            end
        end
    end


    local rodNum = nil
    local notKeepIndex_1 = nil
    local notKeepIndex_2 = nil

    if notChooseArray and #notChooseArray >= 2 then
        rodNum = math.random( 1, #notChooseArray)
        notKeepIndex_1 = notChooseArray[rodNum]
        table.remove( notChooseArray, rodNum )
        rodNum = math.random( 1, #notChooseArray)
        notKeepIndex_2 = notChooseArray[rodNum]
    end
    
    

    local other_index=1
    for k,v in ipairs(self.p_contents) do
        if v~=-100 then
            if other_index<=#other_list and other_list[other_index]<=#self.m_itemList then
                local isShowKeep = true
                if notKeepIndex_1 == other_index or notKeepIndex_2 == other_index then
                    isShowKeep = false
                end

                self.m_itemList[other_list[other_index]]:showOver(math.abs(v),isShowKeep)
                other_index=other_index+1
            end
        end
    end
end

--开始结束流程
function FivePandeBonusGame:gameOver(isContinue)
    --默认1秒后弹出其他箱子内容，子类实现
    scheduler.performWithDelayGlobal(function()
        self:showOther(isContinue)
    end,1, "FivePande_BonusGame")
    --默认3秒后弹出结算面板，子类实现
    scheduler.performWithDelayGlobal(function()
        self:showReward(isContinue)
    end,3, "FivePande_BonusGame")
end

--弹出结算奖励
function FivePandeBonusGame:showReward()
    print("--------------showReward")
    gLobalSoundManager:stopAudio(self.m_currentMusicId)
    self:showRewardView(self.m_pool,self.m_mul,self.m_serverWinCoins)
end


function FivePandeBonusGame:uploadCoins(featureData)
    local coins=self.m_pool*self.m_mul
    print("----------------------uploadCoins="..coins)
end

function FivePandeBonusGame:sortNetData( data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            if data.bonus.status == "CLOSED" then
                local bet = data.bonus.content[data.bonus.choose[#data.bonus.choose] + 1]
                data.bonus.content[data.bonus.choose[#data.bonus.choose] + 1] = - bet
            end
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status

        end
    end 


    localdata = data

    return localdata
end

function FivePandeBonusGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            local data = self:sortNetData(spinData.result)
            self.m_featureData:parseFeatureData(data)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end
return FivePandeBonusGame