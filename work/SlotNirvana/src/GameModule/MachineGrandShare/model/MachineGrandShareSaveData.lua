--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-02 16:43:21
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-02 19:44:30
FilePath: /SlotNirvana/src/GameModule/MachineGrandShare/model/MachineGrandShareSaveData.lua
Description: 关卡中大奖分享  存储的图片数据
--]]
local SaveData = class("SaveData")
function SaveData:ctor()
    self.m_imgPath = ""
    self.m_gameId = ""
end

function SaveData:parseData(_info)
    self.m_imgPath = _info.imgPath
    self.m_gameId = _info.gameId
end

function SaveData:getImagePath()
    return self.m_imgPath
end
function SaveData:getGameId()
    return self.m_gameId
end

function SaveData:getArchiveData()
    return {
        imgPath = self.m_imgPath,
        gameId = self.m_gameId 
    }
end

local MachineGrandShareSaveData = class("MachineGrandShareSaveData")
function MachineGrandShareSaveData:ctor()
    self.m_saveDataList = {}
    self:loadClientSaveData()
end

-- 从本地存储中读取未上传的信息
function MachineGrandShareSaveData:loadClientSaveData()
    local str = gLobalDataManager:getStringByField("MachineGrandShareCfg", "{}")
    local list = json.decode(str)
    for i=1, #list do
        local data = SaveData:create()
        data:parseData(list[i])
        table.insert(self.m_saveDataList, data)
    end
end

-- 存档 未上传的信息
function MachineGrandShareSaveData:saveArchiveData()
    local list = {}
    for i=1, #self.m_saveDataList do
        local data = self.m_saveDataList[i]
        table.insert(list, data:getArchiveData())
    end
    local str = json.encode(list)
    gLobalDataManager:setStringByField("MachineGrandShareCfg", str)
end

function MachineGrandShareSaveData:getTop()
    return self.m_saveDataList[1]
end
function MachineGrandShareSaveData:pop()
    return table.remove(self.m_saveDataList, 1)
end
function MachineGrandShareSaveData:push(_info)
    local data = SaveData:create()
    data:parseData(_info)
    table.insert(self.m_saveDataList, 1, data)
end

return MachineGrandShareSaveData