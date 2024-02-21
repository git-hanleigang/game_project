--地图画线
local QuestDrawLine = class("QuestDrawLine", util_require("base.BaseView"))
local LuaList = require("common.LuaList")
QuestDrawLine.m_lines = nil
QuestDrawLine.m_isUnlockAnima = nil
-- QuestDrawLine.m_spanTime = 0
function QuestDrawLine:initUI()
    self.m_lines = LuaList.new()
    self.points_list = {}
end

--获得点
function QuestDrawLine:getLineDian()
    if QUEST_RES_PATH.QuestLinePointPath and string.len(QUEST_RES_PATH.QuestLinePointPath) > 0 then
        local spDian = util_createSprite(QUEST_RES_PATH.QuestLinePointPath)
        return spDian
    end
end

--创建点
function QuestDrawLine:checkCreateLineDian()
    if self.m_lines:empty() then
        return false
    end
    local info = self.m_lines:pop()
    if info then
        local dian = self:getLineDian()
        if dian then
            self:addChild(dian)
            dian:setPosition(info)
            table.insert(self.points_list, dian)
        end
        return true
    else
        return false
    end
end

--设置线坐标
function QuestDrawLine:pushLine(lines, unLockFunc)
    if unLockFunc then
        self.m_isUnlockAnima = true
    else
        self.m_isUnlockAnima = false
    end
    if lines and #lines > 0 then
        for i = 1, #lines do
            self:pushPos(lines[i])
            if not self.m_isUnlockAnima then
                self:checkCreateLineDian()
            end
        end
    end

    --解锁动画
    if self.m_isUnlockAnima then
        local spanTime = 0
        local triggerTime = 0.1

        local unLockCallbackFunc = unLockFunc
        local function update(dt)
            spanTime = spanTime + dt
            if spanTime < triggerTime then
                return
            end
            spanTime = spanTime - triggerTime
            local isCreate = self:checkCreateLineDian()
            if not isCreate then
                self.m_isUnlockAnima = false
                self:unscheduleUpdate()
                if unLockCallbackFunc then
                    unLockCallbackFunc()
                end
            end
        end
        self:onUpdate(update)
    end
end

--设置点坐标
function QuestDrawLine:pushPos(pos)
    self.m_lines:push(pos)
end

function QuestDrawLine:clearPoints()
    for _, sp_point in pairs(self.points_list) do
        if sp_point then
            sp_point:removeSelf()
        end
    end
    self.points_list = {}
end

return QuestDrawLine
