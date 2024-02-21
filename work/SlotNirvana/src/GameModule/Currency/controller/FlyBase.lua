--[[
    飞货币基类
    author:{author}
    time:2022-05-16 15:25:59
]]
local posOrder = {
    MenuTop = 1,
    CoinPusherTop = 2,
    BingoRushTop = 3,
    BuckStoreTop = 4,
    ShopTop = 10
}
local FlyPosInfo = require("GameModule.Currency.model.FlyPosInfo")
local FlyBase = class("FlyBase")

function FlyBase:ctor(cuyMgr)
    self.m_flyCuyInfo = nil
    self.m_mgr = cuyMgr
    --开始时延迟播放飞金币动画
    self.m_delayFlyTime = 0

    -- 默认终点坐标
    self.m_defEndPos = {}

    -- 节点终点坐标
    self.m_endPos = {}
    -- 横版坐标
    self.m_endPos.Landscape = {}
    -- 竖版坐标
    self.m_endPos.Portrait = {}
    -- 是否创建收集节点
    self.m_isNeedCreateCollect = false

    -- 最终坐标
    self.m_flyStartPos = nil
    self.m_flyEndPos = nil
end

function FlyBase:clearData()
    self.m_flyCuyInfo = nil
    self.m_isRunning = false
    self.m_isNeedCreateCollect = false
    self.m_flyStartPos = nil
    self.m_flyEndPos = nil
end

-- 创建位置信息
function FlyBase:createEndPos(pos, name, order)
    return FlyPosInfo:create(pos, name, order)
end

-- 添加结束位置
function FlyBase:addEndPos(pos, name, isPortrait)
    local order = posOrder[name or ""]
    if not order then
        return
    end

    local tbPos = nil
    if isPortrait then
        tbPos = self.m_endPos.Portrait
    else
        tbPos = self.m_endPos.Landscape
    end
    local posInfo = nil
    -- 查找是否已经存了坐标
    for i = #tbPos, 1, -1 do
        local info = tbPos[i]
        if info:getName() == name then
            posInfo = info
            break
        end
    end
    if posInfo then
        -- 替换坐标
        posInfo:setPos(pos)
    else
        posInfo = self:createEndPos(pos, name, order)
        table.insert(tbPos, posInfo)
        -- 添加后重排序
        table.sort(
            tbPos,
            function(a, b)
                return a:getOrder() < b:getOrder()
            end
        )
    end
end

-- 移除结束位置
function FlyBase:removeEndPos(name)
    if not name or name == "" then
        return
    end

    for k, _value in pairs(self.m_endPos) do
        for i = #_value, 1, -1 do
            local info = _value[i]
            if info:getName() == name then
                table.remove(_value, i)
            end
        end
    end
end

-- 初始化结束位置
function FlyBase:initEndPos()
    local _endPos = self.m_flyCuyInfo:getEndPos()
    if not _endPos then
        -- 没有输入的自定义坐标
        local _posList = nil
        local _defPosInfo = nil
        if globalData.slotRunData.isPortrait then
            _posList = self.m_endPos.Portrait
            _defPosInfo = self.m_defEndPos.Portrait
        else
            _posList = self.m_endPos.Landscape
            _defPosInfo = self.m_defEndPos.Landscape
        end
        if #_posList > 0 then
            -- 优先级最高的节点坐标
            local posInfo = _posList[#_posList]
            _endPos = posInfo:getPos()
        else
            -- 使用默认坐标
            _endPos = _defPosInfo:getPos()
            self.m_isNeedCreateCollect = true
        end
    end
    self.m_flyEndPos = _endPos
end

-- 获得结束位置
function FlyBase:getEndPos()
    return self.m_flyEndPos
end

-- 初始化开始位置
function FlyBase:initStartPos()
    self.m_flyStartPos = self.m_flyCuyInfo:getStartPos()
end

-- 开始位置
function FlyBase:getStartPos()
    return self.m_flyStartPos
end

-- 是否创建收集节点
function FlyBase:isNeedCreateCollectUI()
    -- 是否发生旋转
    -- if globalData.slotRunData:isFramePortrait() ~= globalData.slotRunData.isPortrait then
    --     return true
    -- end
    if self.m_isNeedCreateCollect then
        return true
    end
    return false
end

function FlyBase:initFlyInfo(flyCuyInfo)
    self.m_flyCuyInfo = flyCuyInfo

    self.m_delayFlyTime = 0
    self.m_isRunning = true

    self:initStartPos()
    self:initEndPos()
end

-- 是否正在执行
function FlyBase:isRunning()
    return self.m_isRunning
end

function FlyBase:createCuyNode()
end

-- 显示收集UI
function FlyBase:showCollectUI()
end

-- 飞行准备
function FlyBase:flyReady()
    self:showCollectUI()

    self.m_mgr:addLayerRefCount()
end

-- 开始飞行
function FlyBase:flyStart(flyNode)
    if flyNode then
        flyNode:flyStart()
    end
end

--创建金币出现时漩涡动画
function FlyBase:createStartEffect(posEffect)
end

function FlyBase:flyCurrencys(flyFunc)
    self:flyReady()
end

-- 飞货币抵达效果
function FlyBase:flyArrive(flyNode)
end

-- 收集货币
function FlyBase:flyCollect(flyNode, flyLayer)
    if not flyNode then
        return
    end
    local index = flyNode:getIdx()
    local count = self:getFlyCount()

    if index == 1 then
        self:playCollectSound()
    end

    local collectOverFunc = function()
        if index == count then
            self:flyOver()
        end
    end
    self:playCollectAction(flyLayer, collectOverFunc)
end

function FlyBase:getFlyCount()
    return self.m_flyCuyInfo:flyCount()
end

function FlyBase:playCollectSound()
end

-- 领取动画
function FlyBase:playCollectAction(flyLayer, callback)
    if callback then
        callback()
    end
end

-- 飞行结束
function FlyBase:flyOver()
    -- self:clearData()
    self.m_mgr:desLayerRefCount()
end

-- 飞行退出
function FlyBase:flyExit()
end

-- 飞行结束清理
function FlyBase:flyCleanUp()
    self:clearData()
end

return FlyBase
