--[[
    新版餐厅管理部分
]]

local ActivityDiningroomManager = class("ActivityDiningroomManager") 

ActivityDiningroomManager.BAGTYPE = {
    "WILD",
    "NORMAL"
}
ActivityDiningroomManager.GIFTTYPE = {
    "NORMAL",
    "GEM"
}

function ActivityDiningroomManager:ctor()
    self.m_netModel        = gLobalNetManager:getNet("Activity")   -- 网络模块
    self.m_curGiftPos      = 0       -- 当前操作的礼盒位置
    self.m_curCustomerPos  = 0       -- 当前操作的客人位置
    self.m_getRankDataTime = 0       -- 获得排行榜数据的时间
    self.m_rankExpireTime  = 5       -- 过期时间
    self.m_isGudie         = false   -- 是否在引导中
    self.m_curStage        = 1       -- 当前阶段
end

function ActivityDiningroomManager:getInstance()
	if not self._instance then
        self._instance = ActivityDiningroomManager:create()
    end
    return self._instance
end

-- 开食材包
function ActivityDiningroomManager:openBagRequest(_type,_status,_stage)
    -- local params = {}
    -- params.
    -- params.
    local tbData = {
        data = {
            params = {
                bagType = self.BAGTYPE[_type],
                bagNum  = 1
            }
        }
    }
    if _stage then 
        tbData.data.params.guide = _stage
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_OPEN_BAG, false)
            return
        end
        
        local params = {}
        if _result and _result.stuffs then 
            params = {
                resultData = _result.stuffs,
                type       = _type + 1,
                status     = _status
            }
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_OPEN_BAG, params)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_OPEN_BAG, false)
    end

    self.m_netModel:sendActionMessage(ActionType.DiningRoomOpenBag,tbData,successCallback,failedCallback)
end

-- 制作食物
function ActivityDiningroomManager:makeFood(params)
    local tbData = {
        data = {
            params = {
                customerIndex = params.customerIndex
            }
        }
    }
    if params.curStage then 
        tbData.data.params.guide = params.curStage
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()

        if not _result or _result.error then 
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_MAKE_FOOD, false)
            return
        end

        params.foodCoins    = tonumber(_result.foodCoins)
        params.giftData     = _result.giftData
        params.chapterItems = _result.chapterItems
        params.chapterCoins = tonumber(_result.chapterCoins)
        params.stuffCoins   = tonumber(_result.stuffCoins)
        params.roundItems   = _result.roundItems
        params.roundCoins   = tonumber(_result.roundCoins)
        params.lastGiftData = _result.lastGiftData
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_MAKE_FOOD,params)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_MAKE_FOOD, false)
    end

    self.m_netModel:sendActionMessage(ActionType.DiningRoomMakeFood,tbData,successCallback,failedCallback)
end

-- 开礼盒
function ActivityDiningroomManager:openGift(_openType, _position, _isNOPlace)
    local tbData = {
        data = {
            params = {
                openType = self.GIFTTYPE[_openType],
                position = _position - 1
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        if not _result or _result.error then 
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_OPEN_GIFT, false)
            return
        end

        local params = {
            result = _result,
            pos = _position,
            isNOPlace = _isNOPlace
        }

        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_OPEN_GIFT, params)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_OPEN_GIFT, false)
    end

    self.m_netModel:sendActionMessage(ActionType.DiningRoomOpenGift,tbData,successCallback,failedCallback)
end

-- 引导
function ActivityDiningroomManager:setGuideStage(_stage)
    local tbData = {
        data = {
            params = {
                guide =  _stage
            }
        }
    }

    local successCallback = function (_result)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:showReConnect()
    end

    self.m_netModel:sendActionMessage(ActionType.DiningRoomGuide,tbData,successCallback,failedCallback)
end

-- 获取排行榜信息 
function ActivityDiningroomManager:sendActionRank()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    -- 数据没有过期
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime - self.m_getRankDataTime <= self.m_rankExpireTime then
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_GET_RANK_DATA, true)
        return
    end

    local successCallback = function (_result)
        if not _result or _result.error then 
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_GET_RANK_DATA, false)
            return
        end
        
        if _result then 
            local curTime = os.time()
            if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                curTime = globalData.userRunData.p_serverTime / 1000
            end            
            self.m_getRankDataTime = curTime

            local gameData = G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
            if gameData and gameData:isRunning() then
                gameData:setRankJackpotCoins(0)
                release_print("_result.myRank 1 is " .. tostring(_result.myRank))
                gameData:parseRankData(_result)
            end

        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.DiningRoom})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_GET_RANK_DATA, true)
    end

    local failedCallback = function (errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_GET_RANK_DATA, false)
    end

    self.m_netModel:sendActionMessage(ActionType.DiningRoomRank,tbData,successCallback,failedCallback)
end

function ActivityDiningroomManager:getData()
    local gameData = G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
    if gameData and gameData:isRunning() then
        return gameData
    end
end

function ActivityDiningroomManager:addMaskLayer()
    if not self.m_maskLayer then 
        self.m_maskLayer = util_newMaskLayer()
        self.m_maskLayer:setOpacity(0)
        gLobalViewManager:showUI(self.m_maskLayer, ViewZorder.ZORDER_UI)
    end
end

function ActivityDiningroomManager:removeMaskLayer()
    if self.m_maskLayer then 
        self.m_maskLayer:removeFromParent()
        self.m_maskLayer = nil
    end
end

function ActivityDiningroomManager:setCurGiftPos(_pos)
    self.m_curGiftPos = _pos
end

function ActivityDiningroomManager:getCurGiftPos( )
    return  self.m_curGiftPos
end

function ActivityDiningroomManager:setCurCustomerPos(_pos)
    self.m_curCustomerPos = _pos
end

function ActivityDiningroomManager:getCurCustomerPos( )
    return self.m_curCustomerPos
end

function ActivityDiningroomManager:setGuide(_flag, _stage)
    self.m_isGudie = _flag
    self.m_curStage = _stage
end
function ActivityDiningroomManager:getGuide()
    return self.m_isGudie, self.m_curStage
end

return ActivityDiningroomManager