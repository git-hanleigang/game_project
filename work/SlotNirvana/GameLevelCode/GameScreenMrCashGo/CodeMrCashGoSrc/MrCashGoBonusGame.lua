
local MrCashGoBonusGame = class("MrCashGoBonusGame", util_require("base.BaseGame"))
local SendDataManager = require "network.SendDataManager"

function MrCashGoBonusGame:initDatas(machine)
    self.m_machine  = machine

    self.m_bonusData = {}
end

function MrCashGoBonusGame:initUI()

    self.m_map = util_createView("CodeMrCashGoSrc.MrCashGoBonusMap", self.m_machine)
    self:addChild(self.m_map)

end


--[[
    _data = {    
        mapPos     = 4,           -- 当前地图所在位置/ 骰子的总点数
        dice       = {2, 2}       -- 两个骰子的点数
        bonusPos   = {1, 2, 3}    -- 触发玩法的bonus图标位置
        bonusType  = 1            -- 本次移动触发的bonus玩法类型 (1:jackpot类型奖励 2:大图标滚动玩法 3:bonus移动玩法 4:满级房子玩法)
        bonusOverFun    = function
        isReconnect =             -- 本次bonus是否是重连
        
        -- 1 == bonusType
        coinsType  = ""
        coinsValue = 1000

        -- 2 == bonusType
        reels = {}
        miniReels = {}
    }
]]
function MrCashGoBonusGame:setBonusData(_data)
    self.m_bonusData = _data
end
function MrCashGoBonusGame:clearBonusData()
    self.m_bonusData = {}
end

-- 玩法开始
function MrCashGoBonusGame:startBonusGame()
    -- 人物降落
    self.m_map:playRoleDownAnim(function()
        -- 播放按钮引导 设置按钮点击回调
        self.m_map:playPushBtnStart(self.m_bonusData.dice, self.m_bonusData.mapPos, function()
            -- 人物移动
            self.m_map:startRoleMove(self.m_bonusData.mapPos, function()
                if self.m_bonusData.bonusType == self.m_machine.BONUSTYPE_1 then
                    self:playJackpot()
                elseif self.m_bonusData.bonusType == self.m_machine.BONUSTYPE_2 then
                    self:playMoneyBag()
                elseif self.m_bonusData.bonusType == self.m_machine.BONUSTYPE_3 then
                    self:playBigVilla()
                elseif self.m_bonusData.bonusType == self.m_machine.BONUSTYPE_4 then
                    self:playCashRain()
                end
            end)                   
        end)
    end)
end
-- 玩法结束
function MrCashGoBonusGame:endBonusGame()
    if self.m_bonusData.bonusType == self.m_machine.BONUSTYPE_1 then
        self:playJackpotOver()
    end
    
    self.m_map:startRoleBack(function()
        if self.m_bonusData.bonusOverFun then
            self.m_bonusData.bonusOverFun()
        end
    end)
end


-- bonus1 Jackpot
function MrCashGoBonusGame:playJackpot()
    local coins = self.m_bonusData.coinsValue
    local jackpotIndex = 0
    local isMulti = false

    if self.m_bonusData.coinsType == "mini*5" then
        jackpotIndex = 4
        isMulti = true
    elseif self.m_bonusData.coinsType == "minor*5" then
        jackpotIndex = 3
        isMulti = true
    elseif self.m_bonusData.coinsType == "major" then
        jackpotIndex = 2
    elseif self.m_bonusData.coinsType == "grand" then
        jackpotIndex = 1
    end

    local bottomWinCoin = self.m_machine:getMrCashGoCurBottomWinCoins()
    local allWinCoins   = bottomWinCoin + self.m_bonusData.coinsValue
    self.m_machine:setLastWinCoin(allWinCoins)
    self.m_machine:updateBottomUICoins(0, self.m_bonusData.coinsValue)

    self.m_machine:showJackpotView(coins, jackpotIndex, isMulti, function()
        self:sendData()
    end)
end
function MrCashGoBonusGame:playJackpotOver()
    -- 刷新赢钱检测大赢 和顶部玩家金币
    local bottomWinCoin = self.m_machine:getMrCashGoCurBottomWinCoins()
    local allWinCoins   = bottomWinCoin
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{allWinCoins, GameEffect.EFFECT_BONUS})
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{allWinCoins, false,false,true})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
end

-- bonus2 超大图标
function MrCashGoBonusGame:playMoneyBag()
    if self.m_bonusData.isReconnect then
        self:endBonusGame()
    else
        self:sendData()
    end    
end
-- bonus3 满级房子玩法
function MrCashGoBonusGame:playBigVilla()
    if self.m_bonusData.isReconnect then
        self:endBonusGame()
    else
        self:sendData()
    end 
end
-- bonus4 bonus移动
function MrCashGoBonusGame:playCashRain()
    if self.m_bonusData.isReconnect then
        self:endBonusGame()
    else
        self:sendData()
    end 
end




--数据发送
function MrCashGoBonusGame:sendData()
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {
        msg = MessageDataType.MSG_BONUS_SELECT,
        data = {
        }
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end
--数据接收
function MrCashGoBonusGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]

        if spinData.action == "FEATURE" and nil ~= next(self.m_bonusData) then
            local result = spinData.result
            local userMoneyInfo = param[3]

            globalData.userRate:pushCoins(result.winAmount)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            self:endBonusGame()
        end
    end
end


--[[
    map的一些处理
]]
function MrCashGoBonusGame:hideFeatureLightAnim()
    self.m_map:hideFeatureLightAnim()
end
function MrCashGoBonusGame:hideJackpotLightAnim()
    self.m_map:hideJackpotLightAnim()
end
--[[
    工具接口
]]
function MrCashGoBonusGame:getCurBonusType()
    local bonusType = self.m_bonusData.bonusType or 0 

    return bonusType
end

return MrCashGoBonusGame