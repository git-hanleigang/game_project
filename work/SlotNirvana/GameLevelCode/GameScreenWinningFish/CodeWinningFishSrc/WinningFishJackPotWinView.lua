---
--xcyy
--2018年5月23日
--WinningFishJackPotWinView.lua

local WinningFishJackPotWinView = class("WinningFishJackPotWinView",util_require("base.BaseView"))

local POT_INDEX = {5,4,3,2,1}

local SP_TITLE = {
    Mini = "WinningFish_jackpot_mini_19",
    Minor = "WinningFish_jackpot_minor_20",
    Major = "WinningFish_jackpot_major_17",
    Grand = "WinningFish_jackpot_grand_16",
    Mega = "WinningFish_jackpot_mega_18"
}

WinningFishJackPotWinView.m_btnTouchSound = SOUND_ENUM.MUSIC_BTN_CLICK


function WinningFishJackPotWinView:initUI()
    self:createCsbNode("WinningFish/JackpotWinView.csb")

    self:addClick(self:findChild("Button"))
    self.m_isWaitting = false
    self.m_isJumping = false
end

function WinningFishJackPotWinView:onEnter()

end

function WinningFishJackPotWinView:onExit()
 
end


-- 更新jackpot 数值信息
--
function WinningFishJackPotWinView:updateJackpotInfo()
    -- local value=self.m_machine:BaseMania_updateJackpotScore(self.m_index)
end

--[[
    显示界面
]]
function WinningFishJackPotWinView:showView(machine,jackpotData,func)
    self:createGrandShare(machine)
    self.m_jackpotIndex = 5 - jackpotData.column
    
    self:setVisible(true)
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_jackpot_win.mp3")
    self.m_isWaitting = false
    self.m_data = jackpotData
    self.m_callBack = func
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 15,    --关键帧数  帧动画用
                    callBack = function (  )
                        self.m_sound_id = gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_jackpot_num_roll.mp3")
                    end,
                }
            },   
            callBack = function (  )
                self:runCsbAction("idle",true)
                
            end
        }
    })

    self.m_winCoins = jackpotData.winCoins
    self:findChild("m_lb_coins"):setString(0)
    local addValue = jackpotData.winCoins / (60 * 5)
    self.m_isJumping = true
    
    util_jumpNum(self:findChild("m_lb_coins"),0,jackpotData.winCoins,addValue,1/60,{12},nil,nil,function (  )
        if self.m_sound_id then
            gLobalSoundManager:stopAudio(self.m_sound_id)
            self.m_sound_id = nil
        end
        gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_jackpot_num_roll_end.mp3")
        local node = self:findChild("m_lb_coins")
        self.m_isJumping = false
        node:setString(util_formatCoins(self.m_winCoins, 12))
        self:jumpCoinsFinish()
        util_runAnimations({    --延时关闭
            {
                type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                delayTime = 1,
                callBack = function (  )
                    self:hideView()
                end
            }
        })
    end)
    self:findChild("Particle_3_0"):setVisible(true)
    self:findChild("Particle_3"):setVisible(true)
    self:findChild("Particle_8"):setVisible(true)
    self:findChild("Particle_4"):resetSystem()

    for key,value in pairs(SP_TITLE) do
        self:findChild(value):setVisible(key == jackpotData.jackName)
    end
end

--[[
    隐藏界面
]]
function WinningFishJackPotWinView:hideView()
    if self.m_isWaitting then   -- 防止连续点击
        return
    end

    local bShare = self:checkShareState()
    if not bShare then
        self:jackpotViewOver(function()
            self.m_isWaitting = true
            self:stopAllActions()
            util_runAnimations({
                {
                    type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                    node = self,   --执行动画节点  必传参数
                    actionName = "over", --动作名称  动画必传参数,单延时动作可不传
                    fps = 60,    --帧率  可选参数  
                    callBack = function (  )
                        self:setVisible(false)
                        if type(self.m_callBack) == "function" then
                            self.m_callBack()
                        end
                    end
                }
            })
        end)
    end
end

--[[
    点击回调
]]
function WinningFishJackPotWinView:clickFunc(sender)
    --数字刷新时点击
    if self.m_isJumping then
        if self.m_sound_id then
            gLobalSoundManager:stopAudio(self.m_sound_id)
            self.m_sound_id = nil
        end
        
        gLobalSoundManager:playSound(self.m_btnTouchSound)
        self.m_isJumping = false
        self:findChild("m_lb_coins"):unscheduleUpdate()
        self:findChild("m_lb_coins"):setString(util_formatCoins(self.m_winCoins, 12))
        self:jumpCoinsFinish()
        util_runAnimations({    --延时关闭
            {
                type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self,   --执行动画节点  必传参数
                delayTime = 1,
                callBack = function (  )
                    self:hideView()
                end
            }
        })
    else
        if self.m_isWaitting then   -- 防止连续点击
            return
        end
        gLobalSoundManager:playSound(self.m_btnTouchSound)
        self:hideView()
    end
end

--[[
    自动分享 | 手动分享
]]
function WinningFishJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WinningFishJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function WinningFishJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WinningFishJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WinningFishJackPotWinView