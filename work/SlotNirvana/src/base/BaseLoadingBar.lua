--[[--
]]
local BaseLoadingBar = class("BaseLoadingBar", BaseView)

function BaseLoadingBar:ctor()
    BaseLoadingBar.super.ctor(self)
    -- 进度条上的刻度 在工程中的名字
    self.lb_num = "lb_num" 
    -- 进度条 在工程中的名字
    self.LoadingBar = "LoadingBar_1"
    -- 进度条增长的时间间隔
    self.m_frameInterval = 0.01
end

function BaseLoadingBar:initCsbNodes()
    self._lbNum = self:findChild(self.lb_num)
    self._loadingbar = self:findChild(self.LoadingBar)
end

function BaseLoadingBar:updateUI(_cur, _max)
    _cur = math.min(_cur, _max)
    self.m_cur = _cur
    self.m_max = _max
    local percent = (_cur/_max)*100
    self:updateNum(_cur, _max)
    self:updatePercent(percent)
end
 
function BaseLoadingBar:updateNum(_cur, _max)
    _cur = math.min(_cur, _max)
    if self._lbNum then
        self._lbNum:setString(_cur .. "/" .. _max)
    end
end

function BaseLoadingBar:updatePercent(_percent)
    self._loadingbar:setPercent(_percent)    
end

-- 每涨一个百分比回调
function BaseLoadingBar:increaseFrameCall(_percent)
    self:updatePercent(_percent)
end

-- 每涨一个刻度回调
function BaseLoadingBar:increaseUpdateNumCall(_cur, _max)
    _cur = math.min(_cur, _max)
    self.m_cur = _cur
    self.m_max = _max
    self:updateNum(_cur, _max)
end

-- 每次涨满回调
function BaseLoadingBar:increasePerMaxCall()
end

-- 增长结束回调
function BaseLoadingBar:increaseOver()
end

-- 开始增长回调
function BaseLoadingBar:startIncrease()
end

--[[--
    增长
    涨满后还有富余，刷新上层的任务进度，继续涨
    _increaseList={
        {cur = 8, tar = 10, max = 10},
        {cur = 0, tar = 20, max = 20},
        {cur = 0, tar = 15, max = 30}
    }
    _increaseOver: 增长结束回调
    _perMaxCall: 每次涨满回调
]]
function BaseLoadingBar:playIncrease(_increaseList, _increaseOver, _perMaxCall, _perUpdateNumCall, _perFrameCall)
    _increaseList = _increaseList or {}
    if not (_increaseList and #_increaseList > 0) then
        if _increaseOver then
            _increaseOver()
        end
        return
    end

    self:stopIncreaseSche()

    local perMaxNum = 0
    local index = 1
    local info = _increaseList[1]
    
    local cur = info.cur
    local tar = info.tar
    local max = info.max
    
    local nowPercent = (cur/max)*100
    local tarPercent = (tar/max)*100

    local nextUpdateNumPercent = ((cur+1)/max)*100

    self:startIncrease()
    
    local framePercent = math.min(1, 100/max)
    self.m_increaseSche = util_schedule(self, function()
        nowPercent = nowPercent + framePercent

        self:increaseFrameCall(nowPercent)
        if _perFrameCall then
            _perFrameCall(nowPercent)
        end

        if nowPercent >= nextUpdateNumPercent then
            cur = cur + 1
            nextUpdateNumPercent = math.min(100, ((cur+1)/max)*100)

            self:increaseUpdateNumCall(cur, max)
            if _perUpdateNumCall then
                _perUpdateNumCall(cur, max)
            end

            if cur == max then
                
                self:increasePerMaxCall()
                perMaxNum = perMaxNum + 1
                if _perMaxCall then
                    _perMaxCall(perMaxNum, cur, max)
                end
            end

            if nowPercent >= tarPercent then
                nowPercent = tarPercent
                index = index + 1
                if index > #_increaseList then
                    self:stopIncreaseSche()
                    self:increaseOver()
                    if _increaseOver then
                        _increaseOver()
                    end
                else
                    -- 从下一个开始涨
                    info = _increaseList[index]
                    cur = info.cur
                    tar = info.tar
                    max = info.max
                    
                    nowPercent = (cur/max)*100
                    tarPercent = (tar/max)*100
                    nextUpdateNumPercent = ((cur+1)/max)*100
                end
            end 
        end

    end, self.m_frameInterval)
end

function BaseLoadingBar:stopIncreaseSche()
    if self.m_increaseSche then
        self:stopAction(self.m_increaseSche)
        self.m_increaseSche = nil
    end
end


return BaseLoadingBar
