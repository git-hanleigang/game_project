--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{dhs}
    time:2021-11-19 19:44:52
    filepath: /SlotNirvana/Dynamic/LotteryOpenLayer/Activity/LotteryOpenLayer.lua
]]

local LotteryOpenLayer = class("LotteryOpenLayer", BaseLayer)

function LotteryOpenLayer:ctor(_call)
    LotteryOpenLayer.super.ctor(self)
    self.m_callFunc = _call
end

function LotteryOpenLayer:initDatas(_data)
    self.m_lotteryData = G_GetMgr(G_REF.Lottery):getData()
    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Lottery/csd/Lottery_Open_Layer.csb")
end

function LotteryOpenLayer:initCsbNodes()
    --初始化节点
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_lbTime = self:findChild("lb_time")
    self.m_btnClose = self:findChild("btn_close")
    self.m_npcSpine = self:findChild("spine")
end

function LotteryOpenLayer:initView()
    --初始化当前期数据
    local intLimit = self.m_lbCoin:getContentSize().width
    self:setRandomNum()
    self:jackPotValue(self.m_lbCoin,intLimit)
    self:runCsbAction("idle", true)
    -- self:initSpine()
    self:checkTimer()
    util_alignCenter(
        {
            {node = self.m_spCoin},
            {node = self.m_lbCoin}
        }
    )

end

--初始化npc
-- function LotteryOpenLayer:initSpine()
function LotteryOpenLayer:initSpineUI()
    LotteryOpenLayer.super.initSpineUI(self)
      
    local spine = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren",true, true, 1)
    self.m_npcSpine:addChild(spine)
    util_spinePlay(spine, "idle2", true)
    -- 机器spine
    local parent = self:findChild("ball_spine")
    local spineNode = util_spineCreate("Lottery/spine/quxian/quxian", true, true, 1)
    parent:addChild(spineNode)
    util_spinePlay(spineNode, "idle", false)
    -- 旋转碰撞的球
    for i = 1, 8 do
        local spineBall = self:createBallSpine()
        spineBall:setRotation(util_random(0, 360))
        util_spinePushBindNode(spineNode, string.format("%02d", i) .. "qiu", spineBall)
        --local random = self:getRandomNum()
        util_spinePlay(spineBall, "h" .. i, false)
    end
    util_spinePlay(spineNode, "start", true)
end

function LotteryOpenLayer:createBallSpine()
    local spineQiuNode = util_spineCreate("Lottery/spine/qiu/skeleton", true, true, 1)
    return spineQiuNode
end
-- 保留随机数方法，由于红球只有9个，展示了8个暂时不用随机方法产生小球数字
function LotteryOpenLayer:setRandomNum()
    -- 处理该页面小球动画，进行两层for循环产生随机数问题，先存一个table
    self.m_numTable = {}
    for i = 1, 9 do
        table.insert(self.m_numTable, i)
    end
end

function LotteryOpenLayer:getRandomNum()
    local index = util_random(1,#self.m_numTable)
    local random = self.m_numTable[index]
    for i=#self.m_numTable,1,-1 do
        if random == self.m_numTable[i] then
            table.remove(self.m_numTable,i)
            break
        end
    end
    return random
end

-- 处理倒计时相关逻辑
function LotteryOpenLayer:checkTimer()
    if not self.m_lotteryData then
        return
    end
    local days = util_leftDays(self.m_lotteryData:getEndChooseTimeAt())
    if days < 1 then
        self:updateLeftTime()
        self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTime), 1)
        return
    end
    local timeStr = " DAYS TO LOTTERY"
    if days == 1 then
        timeStr = " DAY TO LOTTERY"
    end
    self.m_lbTime:setString(days .. timeStr)

end

function LotteryOpenLayer:updateLeftTime()
    local leftTimeStr, bOver = util_daysdemaining(self.m_lotteryData:getEndChooseTimeAt())
    
    if bOver then
        self.m_lbTime:setString("Waiting for the Lottery...")
        self:clearScheduler()
        return
    end
    self.m_lbTime:setString(leftTimeStr)
end
--停掉定时器
function LotteryOpenLayer:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

--本期头奖
function LotteryOpenLayer:jackPotValue(_lb,_limit)
    G_GetMgr(G_REF.Lottery):registerCoinAddComponent(_lb, _limit)
end

function LotteryOpenLayer:clickFunc(_sender)
    local btnName = _sender:getName()

    if btnName == "btn_close" then
        local callFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            self.m_callFunc()
        end
        self:closeUI(callFunc)
    elseif btnName == "btn_enjoy" then
        local callFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
            G_GetMgr(G_REF.Lottery):showMainLayer(self.m_callFunc)
        end
        self:closeUI(callFunc)
    end
    
end

return LotteryOpenLayer

