--收藏关卡
local CollectLevelNet = require("GameModule.CollectLevel.net.CollectLevelNet")
local CollectLevelManager = class("CollectLevelManager", BaseGameControl)

function CollectLevelManager:ctor()
    CollectLevelManager.super.ctor(self)
    self:setRefName(G_REF.CollectLevel)

    self.m_netModel = CollectLevelNet:getInstance() -- 网络模块
end

function CollectLevelManager:getConfig()
    if not self.CollectLevelConfig then
        self.CollectLevelConfig = util_require("GameModule.CollectLevel.config.CollectLevelConfig")
    end
    return self.CollectLevelConfig
end

function CollectLevelManager:getData()
    return globalData.collectLevelData
end

function CollectLevelManager:getLevelById(_id)
    local list = self:getData():getLevelList()
    local status = false
    if #list > 0 then
        for i,v in ipairs(list) do
            if v == _id then
                status = true
            end
        end
    end
    return status
end

function CollectLevelManager:addLevelList(_id)
    local list = self:getData():getLevelList()
    table.insert(list,_id)
end

function CollectLevelManager:remLevelList(_id)
    local list = self:getData():getLevelList()
    for i,v in ipairs(list) do
        if v == _id then
            table.remove(list,i)
            break
        end
    end
end

function CollectLevelManager:getLevelList()
    local list1 = self:getData():getLevelList()
    local list = self:reverseTable(clone(list1))
    local level = {}
    for i=1,20 do
        local data = {}
        data.id = i
        if list[i] then
            data.levelname = list[i]
        end
        table.insert(level,data)
    end
    return level
end

function CollectLevelManager:reverseTable(_list)
    local tem = {}
    for i=1,#_list do
        local key = #_list
        tem[i] = table.remove(_list)
    end
    return tem
end
--其他页签的列表
function CollectLevelManager:getOtherGame()
    self.m_otherGame = {}
    local all = globalData.slotRunData:getNormalMachineEntryDatas()
    if all and #all > 0 then
        for i,v in ipairs(all) do
            if v.p_otherGame and v.p_otherGame == 1 then
                table.insert(self.m_otherGame,v)
            end
        end
    end
    return self.m_otherGame
end

--头像框页签
function CollectLevelManager:getFrameGame()
    self.m_frameGame = {}
    local all = globalData.slotRunData:getNormalMachineEntryDatas()
    if all and #all > 0 then
        for i,v in ipairs(all) do
            local bOpen = G_GetMgr(G_REF.AvatarFrame):checkCurSlotOpen(v.p_id)
            if bOpen then
                table.insert(self.m_frameGame,v)
            end
        end
    end
    return self.m_frameGame
end

function CollectLevelManager:getHallList(_type)
    local list = nil
    if _type == 1 then
        list = self:getFrameGame()
    else
        list = self:getOtherGame()
    end
    local endlist = {}
    if list and #list > 0 then
        for idx, itemInfo in ipairs(list) do
            local newIdx = math.floor((idx-1) / 6) + 1
            if not endlist[newIdx] then
                endlist[newIdx] = {}
            end
            table.insert(endlist[newIdx], itemInfo)
        end
    end
    return endlist
end

function CollectLevelManager:sendGetListReq()
    local successFunc = function(_data)
        if _data.collectionLevels and #_data.collectionLevels > 0 then
            for i,v in ipairs(_data.collectionLevels) do
                local data = globalData.slotRunData:getLevelInfoById(v)
                if not data then
                    self:sendRemoveListReq(v,nil,"remove")
                    table.remove(_data.collectionLevels,i)
                end
            end
        end
        self:getData():parseData(_data)
        gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.LEVEL_LIST)
    end
    local fileFunc = function()
    end
    self.m_netModel:sendGetListReq(successFunc,fileFunc)
end

function CollectLevelManager:sendAddListReq(_gameId,_callback)
    local successFunc = function(_data)
        --gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.INIT_REWARD_INFO)
        local list = self:getData():getLevelList()
        if #list >= 20 then
            self:sendRemoveListReq(list[1],_callback,_gameId)
        else
            self:addLevelList(_gameId)
            gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.LEVEL_LIST)
            if _callback then
                _callback(1)
            end
        end
       
    end
    local fileFunc = function()
    end
    self.m_netModel:sendAddListReq(successFunc,fileFunc,_gameId)
end

function CollectLevelManager:sendRemoveListReq(_gameId,_callback,_addId)
    local successFunc = function(_data)
        self:remLevelList(_gameId)
        if _addId ~= "remove" then
            self:addLevelList(_addId)
            gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.LEVEL_LIST)
            if _callback then
                _callback(1)
            end
        end
    end
    local fileFunc = function()
    end
    self.m_netModel:sendRemoveListReq(successFunc,fileFunc,_gameId)
end

function CollectLevelManager:showRuleLayer()
    local view = util_createView("views.CollectLevelCode.CollectRule")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CollectLevelManager:showTips()
    local view = util_createView("views.CollectLevelCode.CollectTip")
    return view
end

-- 创建 收藏关卡view tbview
function CollectLevelManager:createColLevelTbView()
    local view = util_createView("views.CollectLevelCode.CollectHall")
    return view
end

-- 创建 其他关卡view tbview
function CollectLevelManager:createColTbView()
    local view = util_createView("views.CollectLevelCode.CollectLevelHall")
    return view
end

-- 检查 收藏关卡功能是否开启
function CollectLevelManager:checkColLevelsOpen()
    return globalData.userRunData.levelNum >= globalData.constantData.CLUB_OPEN_LEVEL
end

return CollectLevelManager
