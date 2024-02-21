---
--xcyy
--2018年5月23日
--PepperBlastSuperCollectBar.lua

local PepperBlastSuperCollectBar = class("PepperBlastSuperCollectBar",util_require("base.BaseView"))

PepperBlastSuperCollectBar.m_freespinCurrtTimes = 0
PepperBlastSuperCollectBar.m_freespinTotalCountTimes = 0

function PepperBlastSuperCollectBar:onEnter()
end

function PepperBlastSuperCollectBar:onExit()
end

function PepperBlastSuperCollectBar:initUI()
    self:createCsbNode("LoadingBarPepperBlast.csb")
    --event
    local clickNode = self:findChild("Button")
    self:addClick(clickNode)
    --init
    self:initProgressNode()
    self:initSuperCollectTip()
end
function PepperBlastSuperCollectBar:initProgressNode()
    self.m_progressNodes = {}
    self.m_progressActs = {}
    self.m_spineNodes = {}


    local progressParent = {}
    local csbNode,csbAct = {},{}

    local spine = {}

    --之后扩展的话最多也就10之内吧
    for _index=1,10 do
        progressParent = self:findChild("Node_" .. _index)
        if(progressParent)then
            --背景
            csbNode,csbAct = util_csbCreate("LoadingBarPepperBlast_node.csb")
            table.insert(self.m_progressNodes, csbNode)
            table.insert(self.m_progressActs, csbAct)
            progressParent:addChild(csbNode)
            --使用spine代替
            -- csbNode:getChildByName("PepperBlast_TUBIAO_SCATTER_2"):setVisible(false)
            --图标
            spine = util_spineCreate("LoadingBarPepperBlast_node", true, true)
            progressParent:addChild(spine)
            util_spinePlay(spine, "idle", true)
            table.insert(self.m_spineNodes, spine)
        else
            break
        end
    end
end

---
-- 更新freespin 剩余次数
--
function PepperBlastSuperCollectBar:changeSuperCollectByCount(collectNetData, endFun)

    local collectTotalCount = 0
    local collectLeftCount = 0
    if(nil ~= collectNetData)then
        collectTotalCount = collectNetData.collectTotalCount or collectNetData.p_collectTotalCount
        collectLeftCount = collectNetData.collectLeftCount or collectNetData.p_collectLeftCount
    end
    
    local leftCount = collectTotalCount - collectLeftCount
    self.m_freespinCurrtTimes = leftCount
    self.m_freespinTotalCountTimes = collectTotalCount

    self:updateFreespinCount(leftCount, collectTotalCount, endFun)
end

-- 更新并显示次数
function PepperBlastSuperCollectBar:updateFreespinCount(curtimes, totaltimes, endFun)
    local bg = {}
    local spine = {}
    local maxIndex = #self.m_progressNodes
    --解决当前索引为0时回调函数不执行问题
    local isImplementEndFun = false

    for _index=1,maxIndex do
        bg = self.m_progressNodes[_index]
        spine = self.m_spineNodes[_index]
        --可见
        spine:setVisible(_index <= curtimes)
        --展示效果
        if(_index == curtimes)then
            isImplementEndFun = true
            --最后一个收集动画名称
            local animName = (_index == maxIndex) and "start2" or "start"
            util_spinePlay(spine, animName, false)
            util_spineEndCallFunc(spine, animName, function()
                self:upDateLastOneAction()
                if(endFun)then
                    endFun()
                end
            end)
        end
    end

    if(not isImplementEndFun)then
        if(endFun)then
            endFun()
        end
    end
end
 --只剩最后一个就收集完成时的动画
function PepperBlastSuperCollectBar:upDateLastOneAction()
    self:pauseForIndex(0)
    --接近完成模式
    if(self.m_freespinTotalCountTimes>0 and self.m_freespinCurrtTimes+1 == self.m_freespinTotalCountTimes)then
        local animName = "actionframe"
        self:runCsbAction(animName, false)

        for _index,_csbAct in ipairs(self.m_progressActs) do
            if(_index > self.m_freespinCurrtTimes)then
                util_csbPlayForKey(_csbAct, animName, false)
            else
                util_csbPauseForIndex(_csbAct, 0)
            end
        end
    --普通模式
    else
        for _index,_csbAct in ipairs(self.m_progressActs) do
            util_csbPauseForIndex(_csbAct, 0)
        end
    end

    --spine
    for _index,_spine in ipairs(self.m_spineNodes) do
        if(_index <= self.m_freespinCurrtTimes)then
            util_spinePlay(_spine, "idle", true)
        else
            break
        end
    end
end
function PepperBlastSuperCollectBar:setBotTouch(isEnable)
    self:findChild("Button"):setBright(isEnable)
    self:findChild("Button"):setTouchEnabled(isEnable)
end

function PepperBlastSuperCollectBar:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        self.m_collectTip:ShowTip()
    end
end


--获取下一个收集进度的位置
function PepperBlastSuperCollectBar:getNextProgressNodePos()
    local curProgress = self.m_freespinCurrtTimes

    local progressNode = self.m_progressNodes[curProgress+1] or self.m_progressNodes[#self.m_progressNodes]

    local pos = cc.p(progressNode:getPosition())
    return pos
end

--==spine操作

--=================提示界面
function PepperBlastSuperCollectBar:initSuperCollectTip()
    local parent = self:findChild("Button")
    self.m_collectTip = util_createView("CodePepperBlastSrc.PepperBlastSuperCollectTip")
    parent:addChild(self.m_collectTip)
    util_setCsbVisible(self.m_collectTip, false)

    local parent_size = parent:getContentSize()
    local cur_pos = cc.p(self.m_collectTip:getPosition())
    -- local cur_size = self.m_collectTip:getTipSize()
    local offset_pos = cc.p(-parent_size.width, 0)
    self.m_collectTip:setPosition(cur_pos.x + offset_pos.x, cur_pos.y + offset_pos.y)
end
function PepperBlastSuperCollectBar:ShowTip()
    self.m_collectTip:ShowTip()
end
function PepperBlastSuperCollectBar:HideTip()
    self.m_collectTip:HideTip()
end

return PepperBlastSuperCollectBar