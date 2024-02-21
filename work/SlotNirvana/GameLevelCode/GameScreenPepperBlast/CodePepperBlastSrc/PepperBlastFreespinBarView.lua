---
--xcyy
--2018年5月23日
--PepperBlastFreespinBarView.lua

local PepperBlastFreespinBarView = class("PepperBlastFreespinBarView",util_require("base.BaseView"))

PepperBlastFreespinBarView.m_freespinCurrtTimes = 0


function PepperBlastFreespinBarView:initUI()
    self:createCsbNode("FreeSpinsPepperBlast.csb")
    self:runCsbAction("idle1",true)
    --[[
        [1] = {                                --fsType 0:超级 1:普通
            rootNode = _node,                  --rootNode
            [1] = {label = _node, sx=0, sy=0}  --leftNode
            [2] = {label = _node, sx=0, sy=0}  --totalNode
        }
    ]]
    self.m_labelInfo = {}
    local fsTypeNode = self:findChild("PepperBlast_FREEGAMES")
    local leftNode = fsTypeNode:getChildByName("m_lb_num_1")
    local totalNode = fsTypeNode:getChildByName("m_lb_num_2")
    self.m_labelInfo[1] = {
        rootNode = fsTypeNode,
        [1] = {label = leftNode, sx=leftNode:getScaleX(), sy=leftNode:getScaleY(), length = leftNode:getContentSize().width},
        [2] = {label = totalNode, sx=totalNode:getScaleX(), sy=totalNode:getScaleY(), length = totalNode:getContentSize().width},
    }
    fsTypeNode = self:findChild("PepperBlast_SUPERFREEGAMES_WENZI_1")
    leftNode = fsTypeNode:getChildByName("m_lb_num_3")
    totalNode = fsTypeNode:getChildByName("m_lb_num_4")
    self.m_labelInfo[0] = {
        rootNode = fsTypeNode,
        [1] = {label = leftNode, sx=leftNode:getScaleX(), sy=leftNode:getScaleY(), length = leftNode:getContentSize().width},
        [2] = {label = totalNode, sx=totalNode:getScaleX(), sy=totalNode:getScaleY(), length = totalNode:getContentSize().width},
    }
end

function PepperBlastFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function PepperBlastFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function PepperBlastFreespinBarView:changeFreeSpinByCount(params)
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local collectLeftCount = globalData.slotRunData.freeSpinCount
    local leftCount = collectTotalCount - collectLeftCount
    
    self.m_freespinCurrtTimes = leftCount
    self:updateFreespinCount(leftCount, collectTotalCount)
end

function PepperBlastFreespinBarView:updateFreespinVisible()
    for _fsType,v in pairs(self.m_labelInfo) do
        v.rootNode:setVisible(_fsType == self.m_fsType)
    end
end
-- 更新并显示FreeSpin剩余次数
function PepperBlastFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local isCurType = false
    for _fsType,v in pairs(self.m_labelInfo) do
        isCurType = _fsType == self.m_fsType
        if(isCurType)then
            --不需要控制文本尺寸 0426
            --当前次数
            v[1].label:setString(curtimes)
            -- self:updateLabelSize(v[1], v[1].length)
            --总次数
            v[2].label:setString(totaltimes)
            -- self:updateLabelSize(v[2], v[1].length)

            break
        end
    end
end

function PepperBlastFreespinBarView:setFreeSpinType(fsType)
    self.m_fsType = fsType
end
function PepperBlastFreespinBarView:getFreeSpinType()
    return self.m_fsType
end
return PepperBlastFreespinBarView