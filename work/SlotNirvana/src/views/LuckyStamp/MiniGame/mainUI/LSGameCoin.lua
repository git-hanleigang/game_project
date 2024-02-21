--[[--
    金币
]]
local LSGameCoin = class("LSGameCoin", BaseView)

function LSGameCoin:initDatas(_index)
    self.m_index = _index
    self.m_showCoinNum = self:getCoinNum(true)
end

function LSGameCoin:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_coin.csb"
end

function LSGameCoin:initCsbNodes()
    self.m_lbCoin = self:findChild("lb_coin")
end

function LSGameCoin:initUI()
    LSGameCoin.super.initUI(self)
    self:initCoin()
end

function LSGameCoin:resetUI()
    self.m_showCoinNum = self:getCoinNum(true)
    self:initCoin()
end

function LSGameCoin:initCoin()
    self.m_lbCoin:setString(util_formatCoins(self.m_showCoinNum, 3))
end

function LSGameCoin:playIdle()
    self:runCsbAction("idle_1", true, nil, 60)
end

function LSGameCoin:playScaleStart(_over)
    self:runCsbAction("start", false, _over, 60)
    return util_csbGetAnimTimes(self.m_csbAct, "start", 60)
end

function LSGameCoin:playScaleIdle()
    self:runCsbAction("idle_2", true, nil, 60)
end

function LSGameCoin:playScaleOver(_over)
    self:runCsbAction("over", false, _over, 60)
    return util_csbGetAnimTimes(self.m_csbAct, "start", 60)
end

function LSGameCoin:stopSche()
    if self.m_upSche then
        self:stopAction(self.m_upSche)
        self.m_upSche = nil
    end
end

function LSGameCoin:increaseCoin(_over)
    self:stopSche()
    local costTime = 1 -- 秒
    local finalCoins = self:getUpCoin()
    local changeNum = math.floor((finalCoins - self.m_showCoinNum) / 30)
    self.m_upSche =
        util_schedule(
        self,
        function()
            self.m_showCoinNum = self.m_showCoinNum + changeNum
            if self.m_showCoinNum >= finalCoins then
                self.m_showCoinNum = finalCoins
                self:initCoin()
                self:stopSche()
                if _over then
                    _over()
                end
                return
            else
                self:initCoin()
            end
        end,
        1 / 30
    )
end

function LSGameCoin:upCoin()
    self:playScaleStart(
        function()
            if not tolua.isnull(self) then
                self:increaseCoin(
                    function()
                        if not tolua.isnull(self) then
                            self:playScaleOver()
                        end
                    end
                )
            end
        end
    )
    return (70 - 50) / 60 + 1 + (90 - 70) / 60 + 0.3 -- start时间 + 涨金币时间 + over时间 + 额外停顿时间
end

function LSGameCoin:onEnter()
    LSGameCoin.super.onEnter(self)
end

function LSGameCoin:onExit()
    LSGameCoin.super.onExit(self)
    self:stopSche()
end

-- 获取戳的数据
function LSGameCoin:getStampData(_isInit)
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        return data:getCurProcessData(_isInit)
    end
    return nil
end

-- 获取当前戳的宝箱数据
function LSGameCoin:getCurBoxData(_isInit)
    local stampData = self:getStampData(_isInit)
    if stampData then
        return stampData:getLatticeDataByIndex(self.m_index)
    end
    return nil
end

-- 获取金币
function LSGameCoin:getCoinNum(_isInit)
    if LuckyStampCfg.TEST_MODE == true then
        return 100000000 * self.m_index
    end
    local boxData = self:getCurBoxData(_isInit)
    if boxData then
        return boxData:getCoins()
    end
    return 0
end

-- 获取增长后的金币
function LSGameCoin:getUpCoin()
    if LuckyStampCfg.TEST_MODE == true then
        return 200000000 * self.m_index
    end
    local boxData = self:getCurBoxData()
    if boxData then
        return boxData:getCoins()
    end
    return 0
end

return LSGameCoin
