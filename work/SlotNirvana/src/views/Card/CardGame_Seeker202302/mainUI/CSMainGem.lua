--[[
    钻石节点
    挂在主界面和一些弹框中
]]
local CSMainGem = class("CSMainGem", BaseView)

function CSMainGem:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_Gem.csb"
end

function CSMainGem:initDatas()
end

function CSMainGem:initCsbNodes()
    self.m_lbGem = self:findChild("lb_gem")
end

function CSMainGem:initUI()
    CSMainGem.super.initUI(self)
    self:initView()
end

function CSMainGem:initView()
    self:initGem()
end

function CSMainGem:initGem()
    local gemNum = self:getUserGem() or 0
    self.m_lbGem:setString(gemNum)
    self:updateLabelSize({label = self.m_lbGem}, 125)
end

function CSMainGem:onEnter()
    CSMainGem.super.onEnter(self)
    -- 刷新钻石 或者在逻辑中直接调用刷新函数
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initGem()
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_GEM
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initGem()
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )
end

function CSMainGem:getUserGem()
    return globalData.userRunData.gemNum
end

return CSMainGem
