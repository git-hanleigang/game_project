local ActionManager = class("ActionManager")


function ActionManager:ctor()
    self:init()
end

--[[
    构造函数
]] 
function ActionManager:init()

end

function ActionManager:onEnter()
    -- body
end

function ActionManager:onExit()

end

--[[
    执行动作列表
    {
        {
            type,   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node,   --执行动画节点  必传参数
            actionName, --动作名称  动画必传参数,单延时动作可不传
            actionList = {}, --动作列表 序列动作必传参数
            fps,    --帧率  可选参数
            delayTime,  --延时事件  可选参数
            soundFile,  --播放音效 执行动作同时播放 可选参数
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex,    --关键帧数  帧动画用
                    keyFrameName,   --关键帧名  spine动画用
                    callBack,
                }       --关键帧回调
            },   
            callBack,   --回调函数 可选参数
        }
    }
]]
function ActionManager:runAnimations(aniList)
    self.m_aniList = aniList
    self:playNextAnimation()
end

--[[
    播放下个动画
]]
function ActionManager:playNextAnimation()
    if not self.m_aniList then
        return
    end
    local aniData = nil
    for index=1,#self.m_aniList do
        if not self.m_aniList[index].isPlayed then
            aniData = self.m_aniList[index]
            break
        end
    end
    if not aniData then
        return
    end

    startAni = function()
        if aniData.soundFile then
            gLobalSoundManager:playSound(aniData.soundFile)
        end
        aniData.isPlayed = true
        if aniData.type == "animation" then     --帧动画执行动作
            aniData.node:runCsbAction(aniData.actionName,false,function()
                if type(aniData.callBack) == "function" then    --检测回调
                    aniData.callBack(aniData)
                end
                self:playNextAnimation()
            end,aniData.fps) 
            if aniData.keyFrameList then    --关键帧
                for index,keyFrameData in pairs(aniData.keyFrameList) do      --关键帧监测
                    if keyFrameData.keyFrameIndex then
                        --计算该帧需延迟时间
                        local time = util_csbGetAnimKeyFrameTimes(aniData.node.m_csbAct,aniData.actionName,keyFrameData.keyFrameIndex,aniData.fps)
                        local waittingNode = cc.Node:create()
                        aniData.node:addChild(waittingNode)
                        --执行延迟动作
                        waittingNode:runAction(cc.Sequence:create({
                            cc.DelayTime:create(time),
                            cc.CallFunc:create(function(  )
                                if type(keyFrameData.callBack) == "function" then    --检测回调
                                    keyFrameData.callBack(aniData)
                                end
                            end),
                            cc.RemoveSelf:create(true)
                        }))
                    end
                end
            end
        elseif aniData.type == "spine" then      --骨骼动画
            util_spinePlay(aniData.node,aniData.actionName,false)
            util_spineEndCallFunc(aniData.node,aniData.actionName,function()        --结束回调
                if type(aniData.callBack) == "function" then    --检测回调
                    aniData.callBack(aniData)
                end
                self:playNextAnimation()
            end)
            if aniData.keyFrameList then
                for index,keyFrameData in pairs(aniData.keyFrameList) do      --关键帧监测
                    util_spineFrameEvent(aniData.node,aniData.actionName,keyFrameData.keyFrameName,function(  )
                        if type(keyFrameData.callBack) == "function" then    --检测回调
                            keyFrameData.callBack(aniData)
                        end
                    end)
                end
            end
        elseif aniData.type == "delay" then  --延时动作
            if type(aniData.callBack) == "function" then    --检测回调
                aniData.callBack(aniData)
            end
            self:playNextAnimation()
        elseif aniData.type == "seq" then   --序列动作
            local callFunc = cc.CallFunc:create(function(  )
                if type(aniData.callBack) == "function" then    --检测回调
                    aniData.callBack(aniData)
                end
                self:playNextAnimation()
            end)
            table.insert(aniData.actionList,#aniData.actionList + 1,callFunc)
            local seq = cc.Sequence:create(aniData.actionList)
            aniData.node:runAction(seq)
        else    --传入错误的type,播放下个动画
            cclog("动画类型错误")
            self:playNextAnimation()
        end
    end

    --延时执行动作
    if aniData.delayTime and aniData.delayTime > 0 then
        performWithDelay(aniData.node,handler(self,startAni),aniData.delayTime)
    else
        startAni()
    end
end

return ActionManager
