--[[
    收集条
]]

local WinningFishCollectionBar = class("WinningFishCollectionBar",util_require("base.BaseView"))

local TAG_EXPLAIN       =       1001    --收集条说明

function WinningFishCollectionBar:initUI()
    self:createCsbNode("Socre_WinningFish_shoujitiao.csb")
    self.m_node_progress = {}   --收集条进度节点
    self.m_csbNode_pool = {}    --收集条进度圆点池
    self:showAni()
    for index=1,20 do
        local node = self:findChild("Node_"..index - 1)
        self.m_node_progress[index] = node

        local item = util_createView("CodeWinningFishSrc.WinningFishCollectionBarItem")
        node:addChild(item)
        self.m_csbNode_pool[index] = item
    end
    self.m_curBubbleCount = 0       --当前收集进度

    --收集条说明节点
    self.m_node_explain = self:findChild("node_explain")

    
    self:addClick(self:findChild("Button_1"))
end

function WinningFishCollectionBar:onEnter()
    
end

function WinningFishCollectionBar:onExit()
 
end

function WinningFishCollectionBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    点击回调
]]
function WinningFishCollectionBar:clickFunc(sender)
    self:refreshTip()
end

--[[
    刷新说明提示
]]
function WinningFishCollectionBar:refreshTip(isRemove)
    if self.m_isWaitting then
        return
    end

    self.m_isWaitting = true
    local item_explain = self.m_node_explain:getChildByTag(TAG_EXPLAIN)
    local params = {}
    if item_explain then
        
        params[1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = item_explain,   --执行动画节点  必传参数
            actionName = "over", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            callBack = function(  )
                self.m_node_explain:removeAllChildren(true)
                self.m_isWaitting = false
            end,   --回调函数 可选参数
        }
    else
        local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
        if self.m_machine:getGameSpinStage( ) > IDLE or isRemove or (selfData and selfData.bonusType) then
            self.m_isWaitting = false
            return
        end
        
        item_explain = util_createAnimation("Socre_WinningFish_shoujitiaoshuoming.csb")
        self.m_node_explain:addChild(item_explain)
        item_explain:setTag(TAG_EXPLAIN)
        params[1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = item_explain,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            callBack = function(  )
                item_explain:runCsbAction("idleframe")
                self.m_isWaitting = false
            end,   --回调函数 可选参数
        }
    end
    util_runAnimations(params)
end

--[[
    刷新进度
]]
function WinningFishCollectionBar:updateProgress(bubbleCount)
    for index=1,20 do
        local item = self.m_csbNode_pool[index]
        item:showSign(index <= bubbleCount,false)
    end
    --刷新当前进度值
    self.m_curBubbleCount = bubbleCount
end

--[[
    获取下一个未激活的节点
]]
function WinningFishCollectionBar:getNextNode(index)
    local node = self.m_csbNode_pool[self.m_curBubbleCount + index]
    if not node then
        node = self.m_csbNode_pool[#self.m_csbNode_pool]
    end
    return node
end

--[[
    播放收集动画
]]
function WinningFishCollectionBar:playCollectionAni(bubblePos,func)
    local params = {}
    if #bubblePos >= 20 then
        --清理背景音乐
        self.m_machine:clearCurMusicBg()
        gLobalSoundManager:playSound("WinningFishSounds/music_winningFish_colloction_full.mp3")
        params[1] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "jiman", --动作名称  动画必传参数,单延时动作可不传
            -- soundFile = "WinningFishSounds/music_winningFish_colloction_full.mp3",  --播放音效 执行动作同时播放 可选参数
            fps = 60,    --帧率  可选参数
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 319,    --关键帧数  帧动画用
                    callBack = function (  )
                        self:findChild("Particle_2"):resetSystem()
                    end,
                }       --关键帧回调
            }
        }
        params[2] = {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "shouji", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 200,    --关键帧数  帧动画用
                    callBack = function (  )
                        self:findChild("Particle_2_0"):resetSystem()
                        self:findChild("Particle_2"):resetSystem()
                    end,
                }
            },   
            callBack = function(  )
                if not self.isHide then
                    self:runCsbAction("idleframe",true)
                end     
                
                if type(func) == "function" then
                    func()
                end
            end,   --回调函数 可选参数
        }
    else
        -- params[1] = {
        --     type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        --     node = self,   --执行动画节点  必传参数
        --     actionName = "shouji", --动作名称  动画必传参数,单延时动作可不传
        --     fps = 60,    --帧率  可选参数
        --     keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
        --         {
        --             keyFrameIndex = 200,    --关键帧数  帧动画用
        --             callBack = function (  )
        --                 self:findChild("Particle_2_0"):resetSystem()
        --                 self:findChild("Particle_2"):resetSystem()
        --             end,
        --         }
        --     },   
        --     callBack = function(  )
        --         if not self.isHide then
        --             self:runCsbAction("idleframe",true)
        --         end

        --         if type(func) == "function" then
        --             func()
        --         end
        --     end,   --回调函数 可选参数
        -- }
        if type(func) == "function" then
            func()
        end
    end
    util_runAnimations(params)
end

--[[
    隐藏动画
]]
function WinningFishCollectionBar:hideAni()
    if self.isHide then
        return
    end
    self.isHide = true
    self.m_node_explain:removeAllChildren(true)
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "over", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数
            callBack = function(  )
                self:setVisible(false)
            end
        }
    })
end

--[[
    显示动画
]]
function WinningFishCollectionBar:showAni()
    self.isHide = false
    self:setVisible(true)
    self:runCsbAction("idleframe",true)
end

return WinningFishCollectionBar