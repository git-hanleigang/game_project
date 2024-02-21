--[[
    收集条进度圆点
]]

local WinningFishCollectionBarItem = class("WinningFishCollectionBarItem",util_require("base.BaseView"))

function WinningFishCollectionBarItem:initUI()
    self:createCsbNode("Socre_WinningFish_shoujitiaojindu.csb")
    --完成标志
    self.m_sign = self:findChild("Mermaid_jindutiao_qipao_1")
    self:showSign(false)
    self.m_isShow = false
end


function WinningFishCollectionBarItem:onEnter()

end

function WinningFishCollectionBarItem:onExit()

end

--[[
    是否显示完成标志
]]
function WinningFishCollectionBarItem:showSign(isShow,showAni)
    local params = {}
    if self.m_isShow == isShow then
        return
    end
    self.m_isShow = isShow
    if isShow then
        if showAni then
            params[1] = {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
                delayTime = 0,  --延时事件  可选参数
            }
            params[2] ={
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "idleframe2", --动作名称  动画必传参数,单延时动作可不传
                delayTime = 0,  --延时事件  可选参数
            }
        else
            params[1] ={
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "idleframe2", --动作名称  动画必传参数,单延时动作可不传
                delayTime = 0,  --延时事件  可选参数
            }
        end
        
    else
        params[1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "idleframe1", --动作名称  动画必传参数,单延时动作可不传
            delayTime = 0,  --延时事件  可选参数
        }
    end
    util_runAnimations(params)
end

return WinningFishCollectionBarItem