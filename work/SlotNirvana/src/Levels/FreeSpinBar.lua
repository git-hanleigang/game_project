local FreeSpinBar = class("FreeSpinBar", util_require("base.BaseView"))
-- 构造函数
function FreeSpinBar:initUI(data)
    local resourceFilename="FreespinBar/Freespinbar.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe")
    -- self.m_csbOwner["m_lb_num"]:setString(0)
    self.m_csbOwner["node_move"]:setPosition(0,0)
    -- self.m_csbOwner["m_lb_num"]:setPosition(0,20)

    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    local spBg = self:findChild("freespin_di_2")
    local concatStr = bOpenDeluxe and "_deluxe" or ""
    local bgImgPath = "FreespinBar/freespin_di" .. concatStr .. ".png"
    util_changeTexture(spBg, bgImgPath)
end

function FreeSpinBar:onEnter()

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)
    
end

---
-- 重连更新freespin 剩余次数
--
function FreeSpinBar:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self:updateFreespinCount(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function FreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function FreeSpinBar:updateFreespinCount(leftCount,totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["m_lb_num"]:setString(leftCount)
    if leftCount<=9 then
        self.m_csbOwner["node_move"]:setPosition(0,0)
    elseif leftCount<=99 then
        self.m_csbOwner["node_move"]:setPosition(-6,0)
    else
        self.m_csbOwner["node_move"]:setPosition(-12,0)
    end
    self:runCsbAction("actionframe")
end

function FreeSpinBar:onExit()

    gLobalNoticManager:removeAllObservers(self)
end
return FreeSpinBar