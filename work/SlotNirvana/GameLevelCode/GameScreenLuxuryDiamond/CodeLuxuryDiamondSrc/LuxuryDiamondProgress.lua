local LuxuryDiamondProgress = class("LuxuryDiamondProgress", util_require("Levels.BaseLevelDialog"))
-- 构造函数
local PROGRESS_WIDTH = 765

function LuxuryDiamondProgress:initUI(data)
    local resourceFilename = "LuxuryDiamond_jindutiao.csb"
    self:createCsbNode(resourceFilename)

    self.m_machine = data

    self.m_progress =  self:findChild("LuxuryDiamond_bace_jindutiao_16")
    -- self.m_loadHead = self:findChild("progressHead")
    -- local loadHead = util_createAnimation("LuxuryDiamond_jindutiao_shangzhang.csb")
    -- self.m_loadHead:addChild(loadHead)
    -- loadHead:playAction("idle", true)
    -- self.m_loadHead:setVisible(false)



    self.m_box = util_spineCreate("LuxuryDiamond_SuperFreeSpin", true, true)
    self:findChild("you_baoxiang"):addChild(self.m_box)


    -- self.m_bonus = util_spineCreate("LuxuryDiamond_Jindutiaoz", true, true)
    -- self:findChild("zuo"):addChild(self.m_bonus)
    -- util_spinePlay(self.m_bonus,"idleframe",true)

    -- self.m_bonus_effect = util_createAnimation("LuxuryDiamond_shoujifankui.csb")
    -- self:findChild("zuo"):addChild(self.m_bonus_effect)
    -- self.m_bonus_effect:setVisible(false)

    self.m_full_effect = util_createAnimation("LuxuryDiamond_jindutiao_man.csb")
    self:findChild("progressHead"):addChild(self.m_full_effect, 2)
    self.m_full_effect:setPosition(cc.p(0, 0))
    -- self.m_full_effect:setPosition(cc.p(self.m_progress:getContentSize().width, 23))
    self.m_full_effect:setVisible(false)
    self.m_Percent = 0
    self:restProgressEffect(0)
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    self.m_AniId = nil
    self.m_iBetLevel = 4
    self.m_isLock = false
    self:idle()
    self:addClick(self:findChild("btn_click"))

    self:addClick(self:findChild("btn_box"))
end

function LuxuryDiamondProgress:boxOpen()
    util_spinePlay(self.m_box,"actionframe2",false)

    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_boxOpen.mp3")
end

function LuxuryDiamondProgress:boxIdle()
    util_spinePlay(self.m_box,"idle2",true)
end

function LuxuryDiamondProgress:lock(betLevel)
    self.m_iBetLevel = betLevel
    local isLock = betLevel ~= 4
    if isLock ~= self.m_isLock then
        local ani_str = isLock and "suoding" or "jiesuo"
        self:runCsbAction(ani_str, false, function()
            self:idle()
        end)
    end
end

function LuxuryDiamondProgress:idle()
    if self.m_iBetLevel < 4 then
        self:runCsbAction("idle3", true)
        self.m_isLock = true
    else
        self:runCsbAction("idle", true)
        self.m_isLock = false
        self:boxIdle()
    end
end

--默认按钮监听回调
function LuxuryDiamondProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_machine:isNormalStates() then
        if name == "btn_show_Tip" or name == "btn_box" then 
            gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
            gLobalNoticManager:postNotification("SHOW_COLLECT_TIP_LUXDIA")
        elseif  name == "btn_click" and self.m_isLock then
            gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
            gLobalNoticManager:postNotification("CHOOSE_LUXDIA", {5})
            self.m_machine.m_choose_view:setUI(5, true)
        elseif  name == "btn_click" and not self.m_isLock then
            gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
            gLobalNoticManager:postNotification("SHOW_COLLECT_TIP_LUXDIA")
        end
    end
end

function LuxuryDiamondProgress:setPercent(percent)
    self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
    -- local posX = percent * 0.01 * PROGRESS_WIDTH - 373
    -- self.m_loadHead:setPositionX(posX)
    self.m_Percent = percent
    --self.m_loadHead:setVisible(percent ~= 0)
end

function LuxuryDiamondProgress:restProgressEffect(percent)

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    self:setPercent(percent)
    self:boxIdle()
    -- util_spinePlay(self.m_bonus,"idleframe",true)
    -- self.m_bonus_effect:setVisible(false)
end

function LuxuryDiamondProgress:getCollectPos()
    local panda = self:findChild("zuo")
    local pos = panda:getParent():convertToWorldSpace(cc.p(panda:getPosition()))
    return pos
end

function LuxuryDiamondProgress:getCurPercent()
    return self.m_Percent
end

function LuxuryDiamondProgress:updatePercent(percent,callback)
    local oldPercent = self.m_Percent
    local dis_num = math.abs(math.ceil(percent - oldPercent))
    local total_time = 1 - 2/6
    local step_time = total_time / 10
    local step_num = dis_num / 10
    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end

    if self.m_AniId ~= nil and self.m_csbAct:getTarget() then
        self.m_csbAct:getTarget():stopAction(self.m_AniId)
        self.m_AniId = nil
    end
    -- self.m_loadHead:setOpacity(255)
    -- self.m_loadHead:setVisible(true)   

    self.m_full_effect:setVisible(true)
    self.m_full_effect:runCsbAction("actionframe", false, function()
        self.m_full_effect:setVisible(false)
    end)
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_progressUp.mp3")
    performWithDelay(self, function(  )
        -- self.m_full_effect:setVisible(true)
        self.m_percentAction = schedule(self.m_scheduleNode, function()
            oldPercent = oldPercent + step_num
            if oldPercent >= percent then
                self.m_scheduleNode:stopAction(self.m_percentAction)
                self.m_percentAction = nil
                if callback then
                    callback()
                end
                oldPercent = percent
                -- util_playFadeOutAction(self.m_loadHead, 0.5, function()
                --     self.m_loadHead:setVisible(false)
                -- end)
                -- if oldPercent >= 100 then
                --     util_spinePlay(self.m_box,"actionframe",false)
                --     self.m_full_effect:setVisible(true)
                --     util_spineEndCallFunc(self.m_box,"actionframe",function()
                --         self.m_full_effect:setVisible(false)
                --     end)
                -- end

                -- self.m_full_effect:setVisible(false)
            end

            self:setPercent(oldPercent)
        end, step_time)
    end,1/6)
end

function LuxuryDiamondProgress:fankui()
    -- util_spinePlay(self.m_bonus,"actionframe",false)
    -- util_spineEndCallFunc(self.m_bonus, "actionframe", function()
    --     util_spinePlay(self.m_bonus,"idleframe",true)
    -- end)
    -- gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_bouns_fankui.mp3")
    -- self.m_bonus_effect:setVisible(true)
    -- self.m_bonus_effect:playAction("fankui", false,function()
    --     self.m_bonus_effect:setVisible(false)
    -- end)
end

function LuxuryDiamondProgress:showSuperFankui()
    local oldPercent = self.m_Percent
    if oldPercent >= 100 then
        self:boxOpen()
        -- self.m_full_effect:setVisible(true)
        -- util_spineEndCallFunc(self.m_box,"actionframe2",function()
            -- util_spinePlay(self.m_box,"idle2",true)
            -- self.m_full_effect:setVisible(false)
        -- end)
    end
end


function LuxuryDiamondProgress:onEnter()
    LuxuryDiamondProgress.super.onEnter(self)
end

function LuxuryDiamondProgress:onExit()
    LuxuryDiamondProgress.super.onExit(self)
end

return LuxuryDiamondProgress