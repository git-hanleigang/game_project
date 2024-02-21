--[[
Author: your name
Date: 2021-11-26 10:35:04
LastEditTime: 2021-11-26 10:35:05
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/choose/LotteryChooseOKBtn.lua
--]]
local LotteryChooseOKBtn = class("LotteryChooseOKBtn", BaseView)

function LotteryChooseOKBtn:initDatas()
    LotteryChooseOKBtn.super.initDatas(self)
    self.m_bMachine = false -- 是否是机选号码
end

function LotteryChooseOKBtn:initCsbNodes()
    self.m_btnOK = self:findChild("btn_OK")
end

function LotteryChooseOKBtn:initUI()
    LotteryChooseOKBtn.super.initUI(self)

    self:updateBtnState()
end

-- 更新按钮显示状态
function LotteryChooseOKBtn:updateBtnState(_bMachine)
    local bCanSyncNumber = G_GetMgr(G_REF.Lottery):checkCanSyncNumberList()
    self:setButtonLabelDisEnabled("btn_OK",bCanSyncNumber)
    self.m_bMachine = _bMachine -- 是否是机选号码
end

function LotteryChooseOKBtn:clickFunc(sender)
    local name = sender:getName()
    
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_OK" then
        G_GetMgr(G_REF.Lottery):showChooseNumberTipLayer(self.m_bMachine)
    end
end

function LotteryChooseOKBtn:getCsbName()
    return "Lottery/csd/Choose/node_OK.csb"
end

function LotteryChooseOKBtn:playIdleAct()
    self:runCsbAction("idle") 
end
function LotteryChooseOKBtn:playShowAct()
    self:runCsbAction("start") 
end

return LotteryChooseOKBtn