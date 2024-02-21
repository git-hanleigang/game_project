local ExpMulReward = class("ExpMulReward", util_require("base.BaseView"))

function ExpMulReward:initUI()
    self:createCsbNode("MulReward/XP_MulReward.csb")

    --将buff类型index化
    self.m_buffTypeIndex = globalData.buffConfigData:getBuffTypeIndex()
    self.m_time = self:findChild("daojishi")
    self.m_wenziList = {}
    for i=1,#self.m_buffTypeIndex do
        local node = self:findChild("wenzi"..i)
        if node ~= nil then
            self.m_wenziList[#self.m_wenziList+1] = node
        end
        
    end

    self.m_leftTime = 0
    self.m_id = 1
    self.m_curBuffType = 1

    self:showNextDouble()
    schedule(self,function()
        self:updateTime()

    end,1)

end

function ExpMulReward:getCurBuff( )
    if self.m_curBuffType <= 1 or self.m_curBuffType > #self.m_buffTypeIndex then
        return BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN
    end

    local key = self.m_buffTypeIndex[self.m_curBuffType]
    return key
end

--test

-- buffs = {}
-- buffs[1] = {}
-- buffs[1].id = 10001
-- buffs[1].type = BUFFTYPY.BUFFTYPY_DOUBLE_EXP
-- buffs[1].description = ""
-- buffs[1].duration = 300
-- buffs[1].expire = 200 
-- buffs[1].multiple = 2

-- -- buffs[1].id = 10002
-- -- buffs[1].type = BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN

-- buffs[2] = {}
-- buffs[2].id = 10002
-- buffs[2].type = BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN
-- buffs[2].description = ""
-- buffs[2].duration = 200
-- buffs[2].expire = 100 
-- buffs[2].multiple = 2

-- globalData.syncBuffs(buffs)
-- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MULEXP_END)


function ExpMulReward:updateTime()
    if self.m_id < 1 or self.m_id > #self.m_buffTypeIndex then
        return
    end

    local key = self.m_buffTypeIndex[self.m_id]
    local tempTime = globalData.buffConfigData:getBuffLeftTimeByType(key)
    if tempTime > 0 then
        self.m_leftTime = tempTime
    else
        if self.m_leftTime > 0 then
            self.m_leftTime = self.m_leftTime - 1
        end
    end
    local strTimes = util_count_down_str(self.m_leftTime)
    if self.m_leftTime > 86400 then
        strTimes =  math.ceil((self.m_leftTime)/86400).." DAYS"
    end
    self.m_time:setString(strTimes)
end

function ExpMulReward:updateWenzi(index)
    for i=1,#self.m_wenziList do
        local node = self.m_wenziList[i]
        if node ~= nil then
            if i == index then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end
    end
end

--显示时间
function ExpMulReward:showTime()
    self.m_time:setVisible(true)

    for i=1,#self.m_wenziList do
        local node = self.m_wenziList[i]
        if node ~= nil then
            node:setVisible(false)
        end
    end

    self:updateTime()
end

--切换文字显示
function ExpMulReward:changeWenzi()
    self.m_time:setVisible(false)

    self.m_curBuffType = self.m_id
    self:updateWenzi(self.m_curBuffType)

    self:runCsbAction("show",false,function()
        self:showTime()

        self:runCsbAction("show",false,function(  )
            self.m_id = self.m_id + 1
            self:showNextDouble()

        end)
        
    end)
end

--切换特殊文字显示
function ExpMulReward:changeDoubleWenzi()
    self.m_time:setVisible(false)

    self.m_curBuffType = 1
    self.m_id = 1
    self:findChild("wenzi1"):setScale(1)
    self:findChild("wenzi1"):setString("MORE XP")
    self:updateWenzi(self.m_id)

    self:runCsbAction("show",false,function()
        self:findChild("wenzi1"):setScale(0.65)
        self:findChild("wenzi1"):setString("LEVEL UP FASTER")

        self:runCsbAction("show",false,function()
            self:showTime()
    
            self:runCsbAction("show",false,function(  )
                self.m_id = self.m_id + 1
                self:showNextDouble()
    
            end)
        end)

    end)
end

function ExpMulReward:showNextDouble()
    --buff全结束了
    local checkDoube = globalData.buffConfigData:checkBuff()
    if not checkDoube then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MULEXP_END)
        if not tolua.isnull(self) then
            self:removeFromParent()
        end
        return
    end

    if self.m_id < 1 or self.m_id > #self.m_buffTypeIndex then
        self.m_id = 1
    end

    local isHaveNext = false
    for i=self.m_id,#self.m_buffTypeIndex do
        local key = self.m_buffTypeIndex[self.m_id]
        local multipleExp = globalData.buffConfigData:getBuffMultipleByType(key)
        local exp_leftTime = globalData.buffConfigData:getBuffLeftTimeByType(key)

        if multipleExp == nil or multipleExp <= 1 or exp_leftTime <= 0 then
            self.m_id = self.m_id + 1
            if self.m_id > #self.m_buffTypeIndex then
                self.m_id = 1
            end
        else
            isHaveNext = true

            local isDouble = false
            if BUFFTYPY.BUFFTYPY_DOUBLE_EXP == key then
                isDouble = true
            end

            if not isDouble then
                self:changeWenzi()
            else
                self:changeDoubleWenzi()
            end

            return
        end
    end

    --找下一个
    if not isHaveNext then
        self:showNextDouble()
    end

end


return ExpMulReward