local BaseGame = util_require("base.BaseGame")
local BaseView = require "base.BaseView"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CashOrConkDFBase = class("CashOrConkDFBase",BaseView)
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

function CashOrConkDFBase:addObservers()
    gLobalNoticManager:addObserver(self,function(self,params)
        self._blockClick = false
        if params and params[1] == false then

            local view = gLobalViewManager:findReconnectView()

            if tolua.isnull(view)  then
                gLobalViewManager:showReConnect(true)
            else
                local oldFunc = view.m_okFunc
                local newFunc = function()
                    view.m_okFunc = oldFunc
                    if gLobalGameHeartBeatManager then
                        gLobalGameHeartBeatManager:stopHeartBeat()
                    end
                    util_restartGame()
                end
                view.m_okFunc = newFunc
            end
            
            return
        end
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
end

function CashOrConkDFBase:onEnter()
    self._config_music = CashOrConkPublicConfig
    self:addObservers()
end

function CashOrConkDFBase:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function CashOrConkDFBase:showSurePop(data,callBack)
    local view = GD.util_createView("CashOrConkDFSureView",{
        machine = self._machine,
        callback = function(...)
            callBack(...)
            -- self._machine:checkFeatureOverTriggerBigWin(data.coins or 0, GameEffect.EFFECT_BONUS)
        end,
        data = data,
    })
    view:popView()
    self._machine:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    gLobalNoticManager:removeAllObservers(self)
end

function CashOrConkDFBase:showDFEndView(...)
    self._machine:showDFEndView(...)
end

function CashOrConkDFBase:sendData(data)
    self._lastSendData = data
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= data}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    self._blockClick = true
end

function CashOrConkDFBase:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        self._machine.m_runSpinResultData.p_selfMakeData.bonus = spinData.result.selfData.bonus

        release_print("CashOrConkDFBase:featureResultCallFun")
        release_print(cjson.encode(spinData.result.selfData.bonus))

        local userMoneyInfo = param[3]
        globalData.userRate:pushCoins(userMoneyInfo.resultCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
 
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

function CashOrConkDFBase:setDelegate(machine)
    self._machine = machine
end

function CashOrConkDFBase:setLockClick(isLock)
    self._blockClick = isLock
end

function CashOrConkDFBase:resetMusicBg(...)
    self._machine:resetMusicBg(...)
end

function CashOrConkDFBase:refreshStatus()

end

function CashOrConkDFBase:createDirectView()
    gLobalNoticManager:removeAllObservers(self)
    local view = util_require("Pick.CashOrConkDFDirect",true):create()
    if view.initData_ then
        view:initData_({machine = self._machine})
    end
    self:addChild(view)
    return view
end

function CashOrConkDFBase:getMainStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local mode = extra.mode

    return tonumber(string.sub(mode,2,2))
end

function CashOrConkDFBase:getSubStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local mode = extra.mode

    return tonumber(string.sub(mode,3,3)),tonumber(string.sub(mode,4,4))
end

function CashOrConkDFBase:levelPerformWithDelay(_parent, _time, _fun)
	if _time <= 0 then
		_fun()
		return
	end
	local waitNode = cc.Node:create()
    waitNode:setName("waitNode")
	_parent:addChild(waitNode)
	performWithDelay(waitNode,function()
		_fun()
		waitNode:removeFromParent()
	end, _time)
	return waitNode
end

function CashOrConkDFBase:maskShow(time,opacity)

end

return CashOrConkDFBase