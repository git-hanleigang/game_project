
local SendDataManager = require "network.SendDataManager"
local TrainYourDragonChooseGameView = class("TrainYourDragonChooseGameView",util_require("base.BaseGame"))
function TrainYourDragonChooseGameView:ctor()
    TrainYourDragonChooseGameView.super.ctor(self)
    self.m_isNetLoading = false--是否正在等待网络消息
end
function TrainYourDragonChooseGameView:initUI()
    local resourceFilename = "TrainYourDragon/XuanZeJieMian.csb"
    self:createCsbNode(resourceFilename)
    --添加点击图标
    self.m_itemNodeTab = {}
    for i = 1,6 do
        local itemNode = util_createAnimation("Socre_TrainYourDragon_gem.csb")
        self:findChild("gem_"..i):addChild(itemNode)
        itemNode.isOpen = false
        table.insert(self.m_itemNodeTab,itemNode)
        self:addClick(self:findChild("Panel_"..i))
    end
end
--重连时传入数据初始化
function TrainYourDragonChooseGameView:initViewData(data)
    self:enableBtn(false)
    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_chooseView.mp3")
    -- self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
        if data ~= nil then
            local totalbet = data.selfData.avgBet
            for i,pos in ipairs(data.choose) do
                local multiple = tonumber(data.content[i])
                self.m_itemNodeTab[pos + 1]:findChild("BitmapFontLabel_1"):setString(util_formatCoins(totalbet*multiple, 3,nil,nil,true))
                self.m_itemNodeTab[pos + 1]:findChild("BitmapFontLabel_2"):setString(util_formatCoins(totalbet*multiple, 3,nil,nil,true))
                self.m_itemNodeTab[pos + 1]:playAction("actionframe")
                self.m_itemNodeTab[pos + 1].isOpen = true
                self.m_itemNodeTab[pos + 1]:findChild("numNode"):setVisible(false)
            end
            self:enableBtn(true)
        end
        for i,itemNode in ipairs(self.m_itemNodeTab) do
            if itemNode.isOpen == false then
                itemNode:playAction("idle1",true)
            end
        end
    -- end)
end
--设置是否可点击
function TrainYourDragonChooseGameView:enableBtn(isEnable)
    for i = 1,6 do
        self:findChild("Panel_"..i):setTouchEnabled(isEnable)
    end
end
function TrainYourDragonChooseGameView:clickFunc(sender)
    if self.m_isNetLoading  then--正在等待网络消息
        return
    end
    local name = sender:getName()
    local index = tonumber(string.match(name,"%d+"))
    if self.m_itemNodeTab[index].isOpen == false then
        self.m_clickId = index
        self:sendData()
        self.m_itemNodeTab[index]:playAction("dianji")
        self.m_itemNodeTab[index]:findChild("Particle_dianji"):setPositionType(0)
        self.m_itemNodeTab[index]:findChild("Particle_dianji"):resetSystem()
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_chooseClicked.mp3")
    end
end
--翻开点击图标
function TrainYourDragonChooseGameView:startOpenItem()
    if self.m_itemNodeTab[self.m_clickId].isOpen == false then
        local totalbet = self.m_spinDataResult.selfData.avgBet
        self.m_itemNodeTab[self.m_clickId]:findChild("BitmapFontLabel_1"):setString(util_formatCoins(totalbet * tonumber(self.m_data.content[#self.m_data.content]), 3,nil,nil,true))
        self.m_itemNodeTab[self.m_clickId]:findChild("BitmapFontLabel_2"):setString(util_formatCoins(totalbet * tonumber(self.m_data.content[#self.m_data.content]), 3,nil,nil,true))
        self.m_itemNodeTab[self.m_clickId]:playAction("actionframe")
        self.m_itemNodeTab[self.m_clickId].isOpen = true

        if self.m_data.status == "CLOSED" then
            self.m_itemNodeTab[self.m_clickId]:findChild("closedNode"):setVisible(false)
            self:enableBtn(false)
            performWithDelay(self,function ()
                self:bonusGameOver()
            end,0.5)
        else
            -- self.m_itemNodeTab[self.m_clickId]:findChild("Keeping"):setVisible(false)
            self.m_itemNodeTab[self.m_clickId]:findChild("numNode"):setVisible(false)
        end
    end
end
function TrainYourDragonChooseGameView:onEnter()
    TrainYourDragonChooseGameView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:colseSelfView()
    end,"TrainYourDragonChooseGameView_colseSelfView")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:enableBtn(params[1])
    end,"TrainYourDragonChooseGameView_enableBtn")
    
end
--数据发送
function TrainYourDragonChooseGameView:sendData()
    self.m_isNetLoading = true
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT,clickPos = self.m_clickId - 1}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end
--接收返回消息
function TrainYourDragonChooseGameView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_WheelWinCoins = spinData.result.bonus.bsWinCoins
        
        self.m_totleWimnCoins = spinData.result.winAmount

        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        self.m_spinDataResult = spinData.result
        -- self.m_machine:SpinResultParseResultData(spinData)
        gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_SpinResultParseResultData",{spinData})
        self.m_data = spinData.result.bonus
        self:startOpenItem()
        self.m_isNetLoading = false
    else
        -- 处理消息请求错误情况
    end
end
function TrainYourDragonChooseGameView:onExit()
    TrainYourDragonChooseGameView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function TrainYourDragonChooseGameView:bonusGameOver()
    --没翻开的翻开变暗
    if self.m_data.extra and self.m_data.extra.displayData and #self.m_data.extra.displayData > 0 then
        local displayData = clone(self.m_data.extra.displayData)
        for i,itemNode in ipairs(self.m_itemNodeTab) do
            if itemNode.isOpen == false then
                local totalbet = self.m_spinDataResult.selfData.avgBet
                itemNode:findChild("BitmapFontLabel_1"):setString(util_formatCoins(totalbet * tonumber(displayData[1][1]), 3,nil,nil,true))
                itemNode:findChild("BitmapFontLabel_2"):setString(util_formatCoins(totalbet * tonumber(displayData[1][1]), 3,nil,nil,true))
                itemNode:playAction("dark")
                
                if displayData[1][1] == "keep" then
                    itemNode:findChild("numNode"):setVisible(false)
                else
                    itemNode:findChild("closedNode"):setVisible(false)
                end
                table.remove(displayData,1)
            end
        end
    end
    performWithDelay(self,function ()
        gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_showTrainYourDragonDragonGrowWinCoinView",{2})
    end,1)
end

function TrainYourDragonChooseGameView:colseSelfView()
    self:runCsbAction("over",false,function ()
        self:removeFromParent()
    end)
end
return TrainYourDragonChooseGameView