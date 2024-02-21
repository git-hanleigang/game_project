--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-21 10:39:25
]]
--轮盘转动界面
--GoodWheelPiggyAction.lua

local GoodWheelPiggyAction = class("GoodWheelPiggyAction", util_require("base.BaseWheel"))

function GoodWheelPiggyAction:ctor(node, num, func, setRotFunc, Array, bindKey)
    self.m_target = node
    self.m_status = self.ACTION_READY
    self.m_func = func
    self.m_setRotFunc = setRotFunc
    self.m_isWheelData = false
    self.m_targetStep = 360 / num

    self.m_targetDistance = 0
    self.m_moveDistance = 0
    self.m_currentDistance = node:getRotation()
    self.m_stopDistance = 0

    self.m_curTime = 0
    self.m_curV = 0
    self.m_curA = 0
    self.m_targetV = 0
    self.m_frameStep = 0

    self.m_startA = 300 --加速度
    self.m_runV = 500 --匀速
    self.m_runTime = 2 --匀速时间
    self.m_slowA = 150 --动态减速度
    self.m_slowQ = 2 --减速圈数
    self.m_stopV = 110 --停止时速度
    self.m_backTime = 0 --回弹前停顿时间
    self.m_stopNum = 0 --停止圈数
    self.m_randomDistance = 0

    self.m_backV = self.m_targetStep * 0.5 --回弹时速度
    if bindKey then
        self.m_bindKey = true
        self:bindData(bindKey)
    end
    self:setIgnorePause(true)
end

function GoodWheelPiggyAction:setWheelRotFunc(setRotFunc)
    self.m_setRotFunc = setRotFunc
end

--保存时间
function GoodWheelPiggyAction:saveTime()
    self.m_curTime = socket.gettime()
end

--读取时间间隔
function GoodWheelPiggyAction:getSpanTime()
    local spanTime = (socket.gettime() - self.m_curTime)
    return spanTime
end

function GoodWheelPiggyAction:recvData(index, dirType)
    self.m_isWheelData = true
    self.overIndex = index --最后停止的下标
    self.m_moveDistance = 360 - self.overIndex * self.m_targetStep --需要移动的距离

    self.m_dirType = math.random(-1, 1)
    --不需要停在正中央位置的
    if self.m_dirType == 0 then
        self.m_dirType = 1
    end
    self.m_dirType = -1
    self.m_randomDistance = 0 --最后停留的位置偏移
    if self.m_dirType == -1 then
        self.m_randomDistance = math.random(-0.5 * self.m_targetStep, -self.m_targetStep * 0.5)
    elseif self.m_dirType == 1 then
        self.m_randomDistance = math.random(self.m_targetStep * 0.6, self.m_targetStep * 0.7) --0.5 0.7
    end
    self.m_targetDistance = 360 * self.m_stopNum + self.m_moveDistance + self.m_randomDistance
    self.m_targetDistance1 = self.m_targetDistance - self.m_targetStep
    if self.m_targetDistance1 < 0 then
        self.m_targetDistance1 = self.m_targetDistance1 + 360
    end

    self.m_randomDistance = math.abs(self.m_randomDistance)
end

return GoodWheelPiggyAction
