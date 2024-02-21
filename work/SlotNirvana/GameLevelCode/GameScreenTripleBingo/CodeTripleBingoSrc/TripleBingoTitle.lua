--[[

]]
local TripleBingoTitle = class("TripleBingoTitle", util_require("base.BaseView"))
local PublicConfig = require "TripleBingoPublicConfig"
function TripleBingoTitle:initUI(_initData)
    self.m_machine = _initData.machine

    self:createCsbNode(_initData.csbName)
    self:addClick(self:findChild("Panel_click"))

    self.m_dark = util_createAnimation("TripleBingo_tishititle_Dark.csb")
    self:findChild("Node_suoding_dark"):addChild(self.m_dark)

    self:runCsbAction("idle", true)
    self.m_animName = "idle"
    self.m_dark:runCsbAction("idle", true)
    local isATest = globalData.GameConfig:checkABtestGroupA("TripleBingoIcon")
    if not isATest then -- B组是直接解锁三个
        self.m_dark:setVisible(false)
        self:runCsbAction("idle1", true)
        self:updateShowTip()
    else 
        util_schedule(
            self:findChild("root"),
            function()
                self:updateShowTip()
                if not self.m_machine:isCanOpenChooseView() then
                    if self.m_animName ~= "darkstart" then
                        self.m_animName = "darkstart"
                        self.m_dark:runCsbAction("darkstart",false,function()
                            self.m_dark:runCsbAction("darkidle", true)
                        end)
                    end
                else
                    self.m_animName = "idle"
                    util_resetCsbAction(self.m_dark.m_csbAct)
                    self.m_dark:runCsbAction("idle", true)
                end
            end,
            0.08
        )
    end

    
end

function TripleBingoTitle:updateShowTip()
    if not self.m_machine.m_iBetLevel then
        return
    end

    local isATest =  globalData.GameConfig:checkABtestGroupA("TripleBingoIcon")
    if not isATest then -- B组是直接解锁三个
        self:findChild("Node_zi_all"):setVisible(true)
        for i=1,3 do
            self:findChild("Node_zi_"..i):setVisible(false)
        end
    else
        local index = self.m_machine.m_iBetLevel + 1
        for i=1,3 do
            self:findChild("Node_zi_"..i):setVisible(index == i)
        end
        self:findChild("Node_zi_all"):setVisible(false)
    end
end

--默认按钮监听回调
function TripleBingoTitle:clickFunc(sender)
    --选择bet档位界面
    if self.m_machine:isCanOpenChooseView() then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_6"])
        self.m_machine:showChooseView()
    end
end

return TripleBingoTitle
