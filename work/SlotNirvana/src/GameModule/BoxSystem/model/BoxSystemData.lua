--[[
    神秘宝箱系统
]]
local BaseGameModel = require("GameBase.BaseGameModel")
local BoxSystemGroupData = import(".BoxSystemGroupData")
local BoxSystemData = class("BoxSystemData", BaseGameModel)

function BoxSystemData:ctor()
    self.p_boxGroupList = {}
end

--[[
    message PassMysteryBox {
        repeated PassMysteryBoxGroup boxGroupList = 1;
    }
]]
function BoxSystemData:parseData(data)
    self.p_boxGroupList = {}
    for i = 1, #(data.boxGroupList or {}) do
        local boxInfo = BoxSystemGroupData:create()
        boxInfo:parseData(data.boxGroupList[i])
        local group = boxInfo:getGroupName()
        self.p_boxGroupList[group] = boxInfo
    end
end

function BoxSystemData:getBoxGroupList()
    return self.p_boxGroupList or {}
end

function BoxSystemData:getBoxListByGroup(_group)
    if not _group then
        return
    end
    return self.p_boxGroupList["" .. _group]
end

return BoxSystemData
