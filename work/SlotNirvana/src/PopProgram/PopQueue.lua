--[[
    弹板队列
    author:{author}
    time:2019-11-14 15:24:24
]]
local PopQueue = class("PopQueue")

function PopQueue:ctor(jsonData)
    self.m_popEndCallBack = nil --本次弹版结束后回调--
    self.m_curShowList = {} --本次弹版列表--
    self.m_curShowView = nil --当前弹版--
end

-- 设置弹框队列
function PopQueue:setPopQueue(data, callBackFunc)
    self.m_curShowList = data
    self.m_curShowView = nil
    -- 设置弹窗队列结束回调 --
    self.m_popEndCallBack = callBackFunc
end

-- 所有弹窗结束后续推送 --
function PopQueue:finishPopView()
    self.m_curShowList = {}
    self.m_curShowView = nil

    if self.m_popEndCallBack then
        self.m_popEndCallBack()
        self.m_popEndCallBack = nil
    end
end

-- 开始推送窗口逻辑 --
function PopQueue:nextPopView()
    printInfo("显示下一弹板！")
    -- 已经弹完 --
    if #self.m_curShowList == 0 then
        self:finishPopView()
        return
    end

    if self.m_curShowView then
        self.m_curShowView = nil
    end

    -- 查找可弹面版 --
    self.m_curShowView = self:popShowView()
    if self.m_curShowView ~= nil then
        self:showPopView(self.m_curShowView)
    end
end

-- 查找可查面板 并从列表中移除 --
function PopQueue:popShowView()
    if #self.m_curShowList == 0 then
        return nil
    end
    local pView = self.m_curShowList[1]
    table.remove(self.m_curShowList, 1)
    return pView
end

-- 从列表中移除 --
function PopQueue:removeShowView(programName)
    local index = nil
    for i = 1, #self.m_curShowList do
        local popInfo = self.m_curShowList[i]
        if popInfo:getRefName() == programName then
            index = i
        end
    end
    if index then
        table.remove(self.m_curShowList, index)
    end
end

-- 显示每一个推送窗口 --
function PopQueue:showPopView(popUpInfo)
    local isShow = false

    isShow = PopProgramMgr:showPopView(popUpInfo)
    if isShow then
        printInfo("显示弹板" .. popUpInfo:getRefName() .. "成功!")
    end

    if not isShow then
        self:nextPopView()
    end
end

-- 模块弹框是否已经触发
function PopQueue:isPopTrigger(popupName)
    for i = 1, #self.m_curShowList do
        local popInfo = self.m_curShowList[i]
        -- if popInfo:getRefName() == programName then
        if popInfo and popInfo:getPopupName() == popupName then
            return true
        end
    end
    return false
end

return PopQueue
