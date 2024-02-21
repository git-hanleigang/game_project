--[[
    LevelRoadGame 小游戏控制层 950041
]]

local LevelRoadGameMgr = class("LevelRoadGameMgr", BaseGameControl)
local LevelRoadGameNet = require("activities.Activity_LevelRoadGame.net.LevelRoadGameNet")

function LevelRoadGameMgr:ctor()
    LevelRoadGameMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LevelRoadGame)

    self.m_netModel = LevelRoadGameNet:getInstance()

    self.themeName = self:getThemeName()

    self.m_isActive = false  -- 是否可以点击标志（true 表示 动画状态不可点击）   
    self.m_isShowChest = false -- chest宝箱是否显示，显示时（true），不可点击格子。

end

----------------------------------------- 解析数据 -----------------------------------------
function LevelRoadGameMgr:parseData(data)
    if not data then
        return
    end

    local _dataMoudle = self:getData()  
    if not _dataMoudle then
        _dataMoudle = require("activities.Activity_LevelRoadGame.model.LevelRoadGameData"):create()
        _dataMoudle:parseData(data)
        _dataMoudle:setRefName(ACTIVITY_REF.LevelRoadGame)
        self:registerData(_dataMoudle)
    else
        _dataMoudle:parseData(data)
    end
end

----------------------------------------- 网络处理 -----------------------------------------
function LevelRoadGameMgr:sendValidationFreeGame(gameIdx)  -- 校验是否完成免费游戏次数
    self.m_netModel:sendValidationFreeGame(gameIdx)
end

function LevelRoadGameMgr:sendBuy(gameData) -- 发送支付消息
    self.m_netModel:goPurchase(gameData)
end

function LevelRoadGameMgr:sendGetReward(gameIdx) -- 发送领奖消息
    self.m_netModel:sendGetReward(gameIdx)
end

----------------------------------------- 邮箱处理 -----------------------------------------
function LevelRoadGameMgr:onClickMail()
    local oneGameData = self:getData():getOneGame()
    if oneGameData then
        self:showGameLayer("Welcome", oneGameData)
    end
end

----------------------------------------- 状态控制 -----------------------------------------
-- 是否可以点击标志（true 表示 动画状态不可点击）
function LevelRoadGameMgr:setActive(status) -- 动画开始调用（true） 动画结束调用（false） 
    self.m_isActive = status     
end

function LevelRoadGameMgr:isActive()
    return self.m_isActive       
end

-- chest宝箱是否显示，显示时（true），不可点击格子。
function LevelRoadGameMgr:setChestStatus(status) -- 宝箱动画开始调用（true） 宝箱动画结束调用（false） 
    self.m_isShowChest = status    
end

function LevelRoadGameMgr:isShowChest()
    return self.m_isShowChest       
end

----------------------------------------- 关闭界面 -----------------------------------------
function LevelRoadGameMgr:closeMainLayer()
    local _mainLayer = self:getLayerByName("LRGameMainLayer")
    if _mainLayer then
        _mainLayer:closeUI()
    end
end

function LevelRoadGameMgr:playChestOver() -- 关闭 宝箱三选一 node
    local _mainLayer = self:getLayerByName("LRGameMainLayer")
    if _mainLayer.m_Chest then
        _mainLayer.m_Chest:playOver()
        self:setActive(false)
    end
end

----------------------------------------- 打开界面 -----------------------------------------
-- 小游戏 二次确认支付界面
function LevelRoadGameMgr:showPayConfirmLayer(gameData)
    if not self:isCanShowLayer() then
        return nil
    end

    local oneGameData

    if gameData then
        oneGameData = gameData
    else
        oneGameData = self:getData():getOneGame()
    end

    if self:getLayerByName(self.themeName) == nil then
        local view = util_createView(self.themeName .. ".LRGameCode.PayLayer.LRGamePayConfirmLayer", oneGameData)
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end

-- 小游戏 展示界面方法
function LevelRoadGameMgr:showGameLayer(layer, gameData, index, callback)
    if not self:isCanShowLayer() then
        return nil
    end
 
    local gameLayerName = "LRGame" .. layer .. "Layer"

    if self:getLayerByName(gameLayerName) then
        return nil
    end

    local oneGameData

    if gameData then
        oneGameData = gameData
    else
        oneGameData = self:getData():getOneGame()
    end

    -- 换皮名/LRGameCode/X**Layer/LRGameX**Layer"
    local view = util_createView(self.themeName .. ".LRGameCode." .. layer .. "Layer." .. gameLayerName, oneGameData)  
        view:setName(gameLayerName)

    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end


------------------------------------------------- 数据持久化 -------------------------------------------------
---------------------------------------- self 直接调用方法
-- 将 24格子索引 和 paytable索引 存储到缓存中
function LevelRoadGameMgr:saveStepToCache(key, value)
    self:setStepKey(key)
    self:setStepValue(value)
end

-- 取 24格子索引 和 paytable索引 从缓存中
function LevelRoadGameMgr:getStepFromCache()
    local clickMapIndex = string.split(self:getCacheKey(), "-")
    local paytableIndex = string.split(self:getCacheValue(), "-")

    return clickMapIndex, paytableIndex
end

---------------------------------------- 设置缓存文件名
-- 获取 UserDefaultKey
function LevelRoadGameMgr:getUserDefaultKey()
    return "LevelRoadGameKey" .. globalData.userRunData.uid
end

-- 获取 UserDefaultValue
function LevelRoadGameMgr:getUserDefaultValue()
    return "LevelRoadGameValue" .. globalData.userRunData.uid
end

---------------------------------------- 存数据
-- 通过 UserDefaultKey 将数据 存到本地缓存
function LevelRoadGameMgr:setStepKey(string)
    gLobalDataManager:setStringByField(self:getUserDefaultKey(), string, true)
end

-- 通过 UserDefaultValue 将数据 存到本地缓存
function LevelRoadGameMgr:setStepValue(string)
    gLobalDataManager:setStringByField(self:getUserDefaultValue(), string, true)
end

---------------------------------------- 取数据
-- 通过 UserDefaultKey 从本地缓存取数据
function LevelRoadGameMgr:getCacheKey()
    return gLobalDataManager:getStringByField(self:getUserDefaultKey(), "")
end

-- 通过 UserDefaultValue 从本地缓存取数据
function LevelRoadGameMgr:getCacheValue()
    return gLobalDataManager:getStringByField(self:getUserDefaultValue(), "")
end
------------------------------------------------- 数据持久化 end -------------------------------------------------

return LevelRoadGameMgr
