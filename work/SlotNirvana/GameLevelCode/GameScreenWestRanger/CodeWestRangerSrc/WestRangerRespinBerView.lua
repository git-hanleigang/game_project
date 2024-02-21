---
--island
--2018年6月5日
--WestRangerRespinBerView.lua

local WestRangerRespinBerView = class("WestRangerRespinBerView", util_require("base.BaseView"))
WestRangerRespinBerView.m_liangNum = {}

function WestRangerRespinBerView:initUI(data)

    local resourceFilename="WestRanger_Respinbar.csb"
    self:createCsbNode(resourceFilename)

    for i=1,3 do
        self.m_liangNum[i] = util_createAnimation("WestRanger_Respinbar_liang_num.csb")
        self:findChild("m_lb_num_"..i.."_liang"):addChild(self.m_liangNum[i])
        for j=1,3 do
            self.m_liangNum[i]:findChild("m_lb_num_"..j.."_liang"):setVisible(false)
        end
        self.m_liangNum[i]:findChild("m_lb_num_"..i.."_liang"):setVisible(true)
        self.m_liangNum[i]:setVisible(false)
    end
    
end

-- 更新respin次数
function WestRangerRespinBerView:updateLeftCount(num,isLiang)
    for i=1,3 do
        self.m_liangNum[i]:setVisible(false)
    end
    if num >= 3 then
        self.m_liangNum[3]:setVisible(true)
        if isLiang then
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinTimesUpdate.mp3")
            self.m_liangNum[3]:runCsbAction("actionframe",false,function()
                self.m_liangNum[3]:runCsbAction("idle",true)
            end)
        else
            self.m_liangNum[3]:runCsbAction("idle",true)
        end
    else
        if num == 0 then
            return
        end
        self.m_liangNum[num]:setVisible(true)
        if isLiang then
            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRanger_respinTimesUpdate.mp3")
            self.m_liangNum[num]:runCsbAction("actionframe",false,function()
                self.m_liangNum[num]:runCsbAction("idle",true)
            end)
        else
            self.m_liangNum[num]:runCsbAction("idle",true)
        end
    end

    
end

function WestRangerRespinBerView:onEnter()
    WestRangerRespinBerView.super.onEnter(self)
end

function WestRangerRespinBerView:onExit()
    WestRangerRespinBerView.super.onExit(self)
end


return WestRangerRespinBerView