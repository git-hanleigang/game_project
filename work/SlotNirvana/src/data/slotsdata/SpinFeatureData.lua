---
--island
--2018年4月11日
--SpinFeatureData.lua
--

local SpinFeatureData = class("SpinFeatureData")

SpinFeatureData.p_amount = nil  --通用数值， 例如freespin count  ， respin count等信息
SpinFeatureData.p_multiplier = nil -- 
SpinFeatureData.p_contents = nil  -- 例如两种选择
SpinFeatureData.p_chose = nil -- 选择的是第几个， 
SpinFeatureData.p_status = nil -- 状态
SpinFeatureData.p_bonusWinAmount = nil -- 小游戏赢钱
-- 构造函数
function SpinFeatureData:ctor()
    
end


---
-- 解析feature 数据
-- 
function SpinFeatureData:parseFeatureData(data)

    self.p_data = data
    self.p_bonus = data.bonus
    self.p_status=data.status
    self.p_amount = data.amount
    self.p_multiplier = data.multiplier
    self.p_contents = data.content
    self.p_chose = data.chose or data.choose
    self.p_allpoolindex = data.allpoolindex
    self.p_bnousGear = data.bnousGear
    self.p_bonusWinAmount = data.winAmount
    self.p_bet = data.bet
    self.p_lineCount = data.payLineCount
    self.p_extra = data.extra
end
function SpinFeatureData:copyData(targetData)
    self.p_data = targetData
    self.p_bonus = targetData.bonus
	self.p_status=targetData.stap_statustus
    self.p_amount = targetData.p_amount
    self.p_multiplier = targetData.p_multiplier
    self.p_contents = targetData.p_contents
    self.p_chose = targetData.p_chose
    self.p_allpoolindex = targetData.allpoolindex
    self.p_bnousGear = targetData.bnousGear
    self.p_bonusWinAmount = targetData.winAmount
end
return SpinFeatureData