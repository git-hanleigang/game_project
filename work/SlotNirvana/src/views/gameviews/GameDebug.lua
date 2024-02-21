local GameDebug=class("GameDebug",util_require("base.BaseView"))

--初始化读取服务器记录的数据
--如果没有初始化数据为0
--每次收到数据变化的消息 保存服务器数据
function GameDebug:initUI()
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end

    self:createCsbNode("Game/GameDebug.csb",isAutoScale)
    self.m_spin_times = self:findChild("spin_times")
    self.m_special_times = self:findChild("special_times")
    self.m_bet_all = self:findChild("bet_all")
    self.m_win_all = self:findChild("win_all")
    self.m_profit_and_loss = self:findChild("profit_and_loss")

    self.m_spin_exp = self:findChild("spin_exp")
    self.m_cust_spin = self:findChild("cust_spin")
    self.m_cust_special = self:findChild("cust_special")
    
    self.m_localGameData =  cc.Label:create()
    self:addChild(self.m_localGameData , 100000)
    self.m_localGameData:setSystemFontSize(24)
    self.m_localGameData:setString("")
    self.m_localGameData:setAnchorPoint(cc.p(0, 0))
    local pos = cc.p(self.m_cust_special:getPosition())
    self.m_localGameData:setPosition(cc.p(pos.x,pos.y - 30))

    self.m_localGameData2 =  cc.Label:create()
    self:addChild(self.m_localGameData2 , 100000)
    self.m_localGameData2:setSystemFontSize(24)
    self.m_localGameData2:setString("")
    self.m_localGameData2:setAnchorPoint(cc.p(0, 0))
    local pos = cc.p(self.m_cust_special:getPosition())
    self.m_localGameData2:setPosition(cc.p(pos.x,pos.y - 60))

    

    self:initData()
end

function GameDebug:updateLocalNewPeriodData2(str)
    self.m_localGameData2:setString(str)
end

function GameDebug:updateLocalNewPeriodData(str)
    self.m_localGameData:setString(str)
end

function GameDebug:updateSpinTime(num)
    if globalData.custDebugData then
        globalData.custDebugData.spin_times = globalData.custDebugData.spin_times + num
        globalData.custDebugData.cust_spin = globalData.custDebugData.cust_spin + num
    end
end

function GameDebug:updateSpecialTime( num )
    if globalData.custDebugData then
        globalData.custDebugData.special_times = globalData.custDebugData.special_times + num
        globalData.custDebugData.cust_special = globalData.custDebugData.cust_special + num
        self:updateData()
    end
end

function GameDebug:updateBetAll( num )
    if globalData.custDebugData then
        globalData.custDebugData.bet_all = globalData.custDebugData.bet_all + num
        self:updateLoss(globalData.custDebugData.win_all,globalData.custDebugData.bet_all)
    end
end

function GameDebug:updateWinAll(  num)
    if globalData.custDebugData then
        globalData.custDebugData.win_all = globalData.custDebugData.win_all + num
        self:updateLoss(globalData.custDebugData.win_all,globalData.custDebugData.bet_all)
    end
end

function GameDebug:updateLoss( win,bet )
    if globalData.custDebugData then
        globalData.custDebugData.profit_and_loss = win - bet
        self:updateData()
    end
end

function GameDebug:updateSpinExp( num )
    if globalData.custDebugData then
        globalData.custDebugData.spin_exp = num
    end
end

function GameDebug:saveData(  )
    gLobalSendDataManager:getNetWorkFeature():sendCustDebugUpdate(globalData.custDebugData)
end

function GameDebug:clearData(curDayTime)
    globalData.custDebugData = {}
    globalData.custDebugData.day = curDayTime
    globalData.custDebugData.spin_times = 0
    globalData.custDebugData.special_times = 0
    globalData.custDebugData.bet_all = 0
    globalData.custDebugData.win_all = 0
    globalData.custDebugData.profit_and_loss = 0
    globalData.custDebugData.spin_exp = 0
end

function GameDebug:updateData(  )
    if globalData.custDebugData then
        self.m_spin_times:setString(util_formatCoins(globalData.custDebugData.spin_times, 8))
        self.m_special_times:setString(util_formatCoins(globalData.custDebugData.special_times, 8))
        self.m_bet_all:setString(util_formatCoins(globalData.custDebugData.bet_all, 8))
        self.m_win_all:setString(util_formatCoins(globalData.custDebugData.win_all, 8))
        local loss = globalData.custDebugData.profit_and_loss 
        if loss < 0 then
            loss = -loss
            self.m_profit_and_loss:setString("-"..util_formatCoins(loss, 8))
        else
            self.m_profit_and_loss:setString(util_formatCoins(loss, 8))
        end
        self.m_spin_exp:setString(util_formatCoins(globalData.custDebugData.spin_exp, 8))
        self.m_cust_spin:setString(util_formatCoins(globalData.custDebugData.cust_spin, 8))
        self.m_cust_special:setString(util_formatCoins(globalData.custDebugData.cust_special, 8))
        self:saveData()
    end
end

function GameDebug:initData(  )
    local curDayTime = util_getymd_format()
    if globalData.custDebugData  then
        if globalData.custDebugData.day ~= curDayTime then
            --不是同一天初始化数据
            self:clearData(curDayTime)
        end
    else
        --没有数据初始化数据
        self:clearData(curDayTime)
    end
    globalData.custDebugData.cust_special = 0
    globalData.custDebugData.cust_spin = 0

    self:updateData()
end

function GameDebug:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateSpinTime(1)
        self:updateBetAll(params)
    end,ViewEventType.NOTIFY_DEBUG_SPIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateWinAll(params)
    end,ViewEventType.NOTIFY_DEBUG_WIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateSpecialTime(1,params)
    end,ViewEventType.NOTIFY_DEBUG_SPECIAL)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateSpinExp(params)
    end,ViewEventType.NOTIFY_DEBUG_SPIN_EXP)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateLocalNewPeriodData(params)
    end,ViewEventType.NOTIFY_DEBUG_NEW_PERIOD_DATA)
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateLocalNewPeriodData2(params)
    end,ViewEventType.NOTIFY_DEBUG_NEW_PERIOD_DATA2)
end

function GameDebug:onExit()
    gLobalNoticManager:removeAllObservers(self)
end


return GameDebug