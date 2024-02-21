---
--xcyy
--2018年5月23日
--PepperBlastReSpinTimesBar.lua

local PepperBlastReSpinTimesBar = class("PepperBlastReSpinTimesBar",util_require("base.BaseView"))

PepperBlastReSpinTimesBar.m_CurrtTimes = 0


function PepperBlastReSpinTimesBar:initUI()
    self:createCsbNode("RespinPepperBlast.csb")
    -- self:runCsbAction("idle1",true)

    self:initTimesNode()
end
function PepperBlastReSpinTimesBar:initTimesNode()
    self.m_timesNodes = {}

    local parent = {}
    local csbNode,csbAct = {},{}
    --之后扩展的话最多也就10之内吧
    for _index=1,10 do
        parent = self:findChild("Node_" .. _index)
        if(parent)then
            --目前是挂几个父节点就有几个小csb 后续可能把小csb融合到 一个csb内
            local csbName = string.format("RespinPepperBlast_%d.csb", _index)
            csbNode = util_createAnimation(csbName)
            parent:addChild(csbNode)
            table.insert(self.m_timesNodes, csbNode)
        else
            break
        end
    end
end

function PepperBlastReSpinTimesBar:onEnter()
end

function PepperBlastReSpinTimesBar:onExit()
end

---
-- 更新freespin 剩余次数
--
function PepperBlastReSpinTimesBar:showTimes(times)
    self:updateTimes(times)
    self.m_CurrtTimes = times 

    --respin次数重置为3音效
    if(3 == times)then
        gLobalSoundManager:playSound("PepperBlastSounds/PepperBlastSounds_RS_ReSet.mp3")
    end
    
end

-- 更新并显示FreeSpin剩余次数
function PepperBlastReSpinTimesBar:updateTimes(curtimes)
    local img = {}

    for _index,_node in ipairs(self.m_timesNodes)do
        local lightNodeName = string.format("PepperBlast_RESPIN_CISHU_%d_2_2", _index)
        img = _node:findChild(lightNodeName)

        img:setVisible(_index == curtimes)
        if(_index == curtimes)then
            local times_node = _node
            local img_node = img
            self:playChangeAction(times_node, img_node)   
        end
    end
end

function PepperBlastReSpinTimesBar:playChangeAction(times_node, img_node)
    times_node:runCsbAction("actionframe")
end
function PepperBlastReSpinTimesBar:setBotTouch(isEnable)
    self:findChild("Button"):setBright(isEnable)
    self:findChild("Button"):setTouchEnabled(isEnable)
end

function PepperBlastReSpinTimesBar:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        print("[PepperBlastReSpinTimesBar:clickFunc]")
        -- gLobalNoticManager:postNotification("SHOW_TIP1")
    end
end


--重置reSpin次数播放特效

function PepperBlastReSpinTimesBar:playResetTimesEffect()
    print("[PepperBlastReSpinTimesBar:playResetTimesEffect]")
    
end
--获取下一个收集进度的位置
function PepperBlastReSpinTimesBar:getNextProgressNodePos()
    local curProgress = self.m_freespinCurrtTimes

    local progressNode = self.m_progressNodes[curProgress+1]
    if(not progressNode)then
        progressNode = self.m_progressNodes[#self.m_progressNodes]
    end

    local pos = cc.p(progressNode:getPosition())
    return pos
end
return PepperBlastReSpinTimesBar