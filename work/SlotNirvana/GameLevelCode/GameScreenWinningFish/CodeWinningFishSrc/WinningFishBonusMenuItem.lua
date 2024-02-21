--[[
    收集玩法菜单
]]

local WinningFishBonusMenuItem = class("WinningFishBonusMenuItem",util_require("base.BaseView"))

local bonus_icon = {
    {bg = "WinningFish_shouji_yushi_01_27",icon = "WinningFish_shouji_yushi_02_28"},
    {bg = "WinningFish_shouji_yushi_01_27_0",icon = "WinningFish_shouji_yushi_02_28_0"},
    {bg = "WinningFish_shouji_yushi_01_27_1",icon = "WinningFish_shouji_yushi_02_28_1"},
}

local BOX_ID    =    9          --宝箱ID

local FISH_NAME = {
    "WinningFish_shoujiyu_01_1",
    "WinningFish_shoujiyu_03_3",
    "WinningFish_shoujiyu_05_5",
    "WinningFish_shoujiyu_07_7",
    "WinningFish_shoujiyu_09_9",
    "WinningFish_shoujiyu_11_11",
    "WinningFish_shoujiyu_13_13",
    "WinningFish_shoujiyu_15_15"    
}

local INDEX = {8,7,6,5,4,3,2,1}

function WinningFishBonusMenuItem:initUI(params)
    

    self.m_index = params.menuIndex
    self.m_baseGame = params.baseGame

    --金鱼图标
    self.m_fish = {}

    if self.m_index == BOX_ID then
        self:createCsbNode("Socre_WinningFish_Bonus_menu_box.csb")
    else
        self.m_index = INDEX[self.m_index]
        self:createCsbNode("Socre_WinningFish_Bonus_menu.csb")
        for key,name in pairs(FISH_NAME) do
            self.m_fish[key] = self:findChild(name)
            self.m_fish[key]:setVisible(false)
        end
    end

    --分数标签
    self.m_lb_coins = self:findChild("m_lb_coins")

    self.m_picks2 = self:findChild("picks2_1")
    self.m_picks3 = self:findChild("picks3_1")
    
end


function WinningFishBonusMenuItem:onEnter()

end

function WinningFishBonusMenuItem:onExit()

end

--[[
    刷新次数
]]
function WinningFishBonusMenuItem:refreshPicks(totalTimes,curTimes)
    local params = {}
    if totalTimes == 2 then
        if self.m_index ~= BOX_ID then
            self.m_picks2:setVisible(true)
            self.m_picks3:setVisible(false)
        end
        
        if not curTimes or curTimes == 0 then
            params[1] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "idle_h2", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    
                end,   --回调函数 可选参数
            }
        elseif curTimes + 1 == totalTimes then
            params[1] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "start_2", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    self:runCsbAction("idle_2",true)
                end,   --回调函数 可选参数
            }
            local particle = self:findChild("Node_shouji_2"):getChildByName("Particle_1")
            particle:resetSystem()
        else
            local particle = self:findChild("Node_shouji_3"):getChildByName("Particle_1")
            particle:resetSystem()
            params[1] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "start_s2", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    
                end,   --回调函数 可选参数
            }
            params[2] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "over_2", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    
                end,   --回调函数 可选参数
            }
        end
    else
        if self.m_index ~= BOX_ID then
            self.m_picks2:setVisible(false)
            self.m_picks3:setVisible(true)
        end
        
        if not curTimes or curTimes == 0 then
            params[1] =    {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "idle_h3", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    
                end,   --回调函数 可选参数
            }
        elseif curTimes == 1 then
            params[1] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "start_3", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    self:runCsbAction("idle_s3",true)
                end,   --回调函数 可选参数
            }
            local particle = self:findChild("Node_shouji_1"):getChildByName("Particle_1")
            particle:resetSystem()
        elseif curTimes + 1 == totalTimes then
            params[1] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "start_s3", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    self:runCsbAction("idle_3",true)
                end,   --回调函数 可选参数
            }
            local particle = self:findChild("Node_shouji_2"):getChildByName("Particle_1")
            particle:resetSystem()
        else
            local particle = self:findChild("Node_shouji_3"):getChildByName("Particle_1")
            particle:resetSystem()
            params[1] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "start_ss3", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    
                end,   --回调函数 可选参数
            }
            params[2] =  {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                actionName = "over_3", --动作名称  动画必传参数,单延时动作可不传
                actionList = {}, --动作列表 序列动作必传参数
                fps = 60,    --帧率  可选参数
                callBack = function(  )
                    
                end,   --回调函数 可选参数
            }
        end
    end

    util_runAnimations(params)
end


--[[
    更新信息
]]
function WinningFishBonusMenuItem:updateInfo(data)
    local selfData = data.p_selfMakeData

    -- self.m_index = curIndex     --更新索引

    local iconCount = selfData.picks[self.m_index] --需要bonus数量
    if self.m_index ~= BOX_ID then
        local score = selfData.pickScore[self.m_index] --分数

        -- if data.p_bonus then
        --     local fishCount = data.p_bonus.extra.pickData[self.m_index][2]
        --     if fishCount > 0 then
        --         --变更分数
        --         score = selfData.pickScore[self.m_index] * fishCount
        --     end
        -- end

        self.m_lb_coins:setString(score)

        --金鱼类型显示
        for index=1,#self.m_fish do
            self.m_fish[index]:setVisible(self.m_index == index)
        end
    end
    
    
    if not data.p_bonus then
        self:refreshPicks(iconCount)
        return
    end
    local pickData = data.p_bonus.extra.pickData
    local addPicks = self.m_baseGame.m_machine.m_runSpinResultData.addPicks
    if pickData then
        if self.m_index ~= BOX_ID or not addPicks then
            for key,typeInfo in pairs(pickData) do
                if self.m_index  == typeInfo[1] then
                    self:refreshPicks(iconCount,typeInfo[2])
                end
            end
        else
            local pickIndex = self.m_baseGame.pickIndex
            
            local curCount = 0
            local totalCount = 0
            for index=1,#addPicks do
                if addPicks[index] and addPicks[index][2] == BOX_ID then
                    if index <= pickIndex then
                        curCount = curCount + 1
                    end
                    totalCount = totalCount + 1
                end
            end

            self:refreshPicks(iconCount,pickData[BOX_ID][2] - totalCount + curCount)
        end
        
    end
end

--[[
    播放光效
]]
function WinningFishBonusMenuItem:playLightEffect()
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数 
            callBack = function(  )
                
            end
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数 
        }
    })
end

function WinningFishBonusMenuItem:hidePickTimes( )
    self.m_picks2:setVisible(false)
    self.m_picks3:setVisible(false)
end

return WinningFishBonusMenuItem