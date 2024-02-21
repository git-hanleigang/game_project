--[[
    
]]

local BaseWheel = require("Levels.ActivityBaseWheel")
local RoutineSaleWheel = class("RoutineSaleWheel", BaseView)

function RoutineSaleWheel:getCsbName()
    return "Sale_New/csb/turntable/SaleTurntable_spin.csb"
end

function RoutineSaleWheel:initDatas(_params, _mainLayer)
    self.m_params = _params
    self.m_maxUsd = _params.maxUsd
    self.m_baseCoins = _params.baseCoins
    self.m_wheelChunk = _params.wheelChunk
    self.m_wheelReward = _params.wheelReward
    self.m_count = _params.count
    self.m_mainLayer = _mainLayer
end

function RoutineSaleWheel:initCsbNodes()
    self.m_node_wheel = self:findChild("node_wheel")
    self.m_btn_spin = self:findChild("btn_spin") 
    self.m_btn_spin:setEnabled(self.m_params.isReward)
end

function RoutineSaleWheel:initUI()
    RoutineSaleWheel.super.initUI(self)

    self:setMultiSpan()
    self:addWheel()
    self:runCsbAction("idle", true)
end

function RoutineSaleWheel:setMultiSpan()
    for i = 1, self.m_count do
        local node = self:findChild("lb_number_" .. i)
        local sp_sector = self:findChild("sp_sector" .. i)
        local chunkInfo = self.m_wheelChunk[i] or {}
        if node and sp_sector then
            local multiple = chunkInfo.p_multiple or 0
            local index = chunkInfo.p_index or 1
            node:setString("x" .. multiple)
            node:setVisible(multiple > 0)
            sp_sector:setVisible(multiple > 0)
            util_changeTexture(sp_sector, "Sale_New/ui/turntable/ui_turntable_spin_sector" ..  index .. ".png")
        end
    end
end

function RoutineSaleWheel:addWheel()
    local params = {
        doneFunc = handler(self, self.rollEnd), --停止回调
        rotateNode = self.m_node_wheel, --需要转动的节点
        sectorCount = 3, --总的扇面数量
        parentView = self, --父界面
        startSpeed = 0, --开始速度
        minSpeed = 50, --最小速度(每秒转动的角度)
        maxSpeed = 500, --最大速度(每秒转动的角度)
        accSpeed = 300, --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 300, --减速结算的加速度(每秒减少的角速度)
        turnNum = 1, --开始减速前转动的圈数
        minDistance = 100, --以最小速度行进的距离
        backDistance = 0, --回弹距离
        backTime = 0 --回弹时间
    }
    self.m_wheel = BaseWheel:create(params)
    self:addChild(self.m_wheel)
end

function RoutineSaleWheel:wheelRolling()
    local index = self.m_wheelReward.p_index
    self.m_wheel:startMove()
    self.m_wheel:setEndIndex(index)
end

function RoutineSaleWheel:rollEnd()
    self.m_mainLayer:hideEf()

    local reward = self.m_wheelReward
    G_GetMgr(G_REF.RoutineSale):showRewardLayer(reward, self.m_baseCoins)
end

function RoutineSaleWheel:clickFunc(_sender)
    if self.m_mainLayer:getTouch() then
        return
    end

    if self.m_wheelReward then
        self.m_mainLayer:setTouch(true)
        self.m_mainLayer:addSpinEf()
        self:wheelRolling()
    end
end

return RoutineSaleWheel
