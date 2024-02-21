--[[
    弹板数据管理（代理）类
    author:徐袁
    time:2020-12-19 15:17:55 zzz
]]
local PopupItemConfig = nil
local PopupControlData = nil
local PopUpManager = class("PopUpManager", BaseSingleton)

function PopUpManager:ctor()
    PopUpManager.super.ctor(self)
    -- 弹板信息配置数据
    self.popupConfigs = {}
    -- 弹板控制配置数据
    self.popupControlDatas = {}
end

--[[
    @desc: 解析弹板信息配置数据
    author:徐袁
    time:2020-12-19 15:24:30
    @return:
]]
function PopUpManager:parsePopUpItemConfigs(datas)
    
    if datas ~= nil and #datas > 0 then
        if not PopupItemConfig then
            PopupItemConfig = require("data.popUp.PopupItemConfig")
        end

        for i = 1, #datas do
            local item = PopupItemConfig:create()
            item:parseData(datas[i])
            self:addPopUpItem(self.popupConfigs, item)
        end
    end

end

function PopUpManager:addPopUpItem(tbPopUps, item)
    if not item then
        return
    end
    -- 判断点位类型
    local pos = item:getPosType()
    local popUpId = item:getPopUpId()
    if not tbPopUps["" .. pos] then
        tbPopUps["" .. pos] = {}
    end
    -- 判断id是否已经存在
    local popUpInfo = tbPopUps["" .. pos]["" .. popUpId]
    if not popUpInfo then
        tbPopUps["" .. pos]["" .. popUpId] = item
    end
end

--根据活动id，获取弹窗数据 只取一条
function PopUpManager:getPushViewDataByActivityId(activityId)
    for k, datas in pairs(self.popupConfigs) do
        for id, activityData in pairs(datas) do
            if tostring(activityData.id) == activityId then
                return activityData
            end
        end
    end
    return nil
end

-- 通过id获得弹板信息
function PopUpManager:getPopUpInfoById(id)
    for key, value in pairs(self.popupConfigs) do
        local _info = value["" .. id]
        if _info then
            return _info
        end
    end
    return nil
end

-- 获得点位弹框数据
function PopUpManager:getPopUpInfosByPos(posType)
    return self.popupConfigs["" .. posType] or {}
end

-- 通过pos和type获得弹板
function PopUpManager:getPopUpInfoByPosAndType(posType, nType)
    local data = {}
    local posDatas = self:getPopUpInfosByPos(posType)
    for key, value in pairs(posDatas) do
        if value:getPopType() == nType then
            table.insert(data, value)
        end
    end
    return data
end

--去重，同zOrder，根据zOrder1只取最小的一个
function PopUpManager:screenByZorder(data)
    local tempRet = {}
    for i = 1, #data do
        local popUpItem = data[i]
        local key = popUpItem:getPriority()
        local temp = tempRet["" .. key]
        if temp == nil or temp:getSecondPriority() > popUpItem:getSecondPriority() then
            tempRet["" .. key] = popUpItem
        end
    end

    local ret = {}
    for k, v in pairs(tempRet) do
        ret[#ret + 1] = v
    end

    return ret
end

-- 弹板排序
function PopUpManager:sortPopUpData(data, posType)
    if not next(data) then
        return {}
    end

    local popUpItems = self:screenByZorder(data)
    if posType == PushViewPosType.LoginToLobby then
        --登录的特殊处理
        for i = 1, #popUpItems do
            local info = popUpItems[i]
            local controlData = self:getPopupControlData(info)
            if controlData and controlData.p_loginPriority then
                info:setPriority(controlData.p_loginPriority)
            end
        end
    end
    --按照窗口优先级排序
    table.sort(
        popUpItems,
        function(a, b)
            return tonumber(a:getPriority()) < tonumber(b:getPriority())
        end
    )
    return popUpItems
end

-- =====================================================================
--[[
    @desc: 解析弹板控制配置数据
    author:徐袁
    time:2020-12-19 15:25:45
    --@datas: 
    @return:
]]
function PopUpManager:parsePopUpControlDatas(datas)
    if datas ~= nil and #datas > 0 then
        if not PopupControlData then
            PopupControlData = require("data.popUp.PopupControlData")
        end

        for i = 1, #datas do
            local item = PopupControlData:create()
            item:parseData(datas[i])
            self.popupControlDatas[item:getRefName()] = item
        end
    end
end

--[[
    @desc: 根据程序引用名获取弹窗控制逻辑
    author:徐袁
    time:2020-12-19 16:11:26
    --@luaName: 
    @return:
]]
function PopUpManager:getPopupControlData(data)
    if not data then
        return nil
    end

    local isNovice = data:isNovice()
    local refName = data:getRefName()
    local activityData = G_GetActivityDataByRef(refName)
    if (activityData and activityData:isNovice() == isNovice) then
        -- 有活动且弹窗配置和活动类型一致
        if isNovice then
            return G_GetMgr(G_REF.UserNovice):getPopupControlDataByRef(refName)
        else
            return self:getPopupControlDataByRef(refName)
        end
    else
        return nil
    end
end

function PopUpManager:getPopupControlDataByRef(refName)
    if not refName then
        return nil
    end

    local controlData = self.popupControlDatas["" .. refName]
    if controlData and controlData:isOpen() then
        return controlData
    end

    return nil
end

return PopUpManager
