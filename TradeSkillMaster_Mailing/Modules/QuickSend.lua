-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Mailing                            --
--            http://www.curse.com/addons/wow/tradeskillmaster_mailing            --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local QuickSend = TSM:NewModule("QuickSend", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Mailing") -- loads the localization table

local private = {itemLink=nil, quantity=0, target="", cod=0, money=0}

function QuickSend:CreateTab(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:Hide()
	frame:SetPoint("TOPLEFT", 5, -5)
	frame:SetPoint("BOTTOMRIGHT", -5, 5)
	frame:SetAllPoints()
	TSMAPI.Design:SetFrameColor(frame)

	local label = TSMAPI.GUI:CreateLabel(frame, "normal")
	label:SetPoint("TOPLEFT", 5, -5)
	label:SetPoint("TOPRIGHT", -5, -5)
	label:SetHeight(50)
	label:SetJustifyV("TOP")
	label:SetJustifyH("LEFT")
	label:SetText(L["This tab allows you to quickly send any quantity of an item to another character. You can also specify a COD to set on the mail (per item)."])

	TSMAPI.GUI:CreateHorizontalLine(frame, -55)
	
	
	local itemBoxLabel = TSMAPI.GUI:CreateLabel(frame, "small")
	itemBoxLabel:SetPoint("TOPLEFT", 5, -65)
	itemBoxLabel:SetHeight(20)
	itemBoxLabel:SetJustifyV("CENTER")
	itemBoxLabel:SetJustifyH("LEFT")
	itemBoxLabel:SetText(L["Item (Drag Into Box):"])
	
	local function OnItemDrag(self)
		local cType, _, link = GetCursorInfo()
		if cType == "item" then
			self:SetText(link)
			private.itemLink = link
			ClearCursor()
			private.btn:Update()
		end
	end
	
	local itemBox = TSMAPI.GUI:CreateInputBox(frame)
	itemBox:SetPoint("TOPLEFT", itemBoxLabel, "TOPRIGHT", 5, 0)
	itemBox:SetPoint("TOPRIGHT", -95, -65)
	itemBox:SetHeight(20)
	itemBox:SetText(private.itemLink or "")
	itemBox:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
	itemBox:SetScript("OnReceiveDrag", OnItemDrag)
	itemBox:SetScript("OnMouseDown", OnItemDrag)
	itemBox.tooltip = L["Drag (or place) the item that you want to send into this editbox."]
	
	local itemClearBtn = TSMAPI.GUI:CreateButton(frame, 15)
	itemClearBtn:SetPoint("TOPLEFT", itemBox, "TOPRIGHT", 5, 0)
	itemClearBtn:SetPoint("TOPRIGHT", -5, -65)
	itemClearBtn:SetHeight(20)
	itemClearBtn:SetText(L["Clear"])
	itemClearBtn:SetScript("OnClick", function()
			private.itemLink = nil
			itemBox:SetText("")
			private.btn:Update()
		end)
	itemClearBtn.tooltip = L["Clears the item box."]
	
	
	local targetBoxLabel = TSMAPI.GUI:CreateLabel(frame, "small")
	targetBoxLabel:SetPoint("TOPLEFT", 5, -95)
	targetBoxLabel:SetHeight(20)
	targetBoxLabel:SetJustifyV("CENTER")
	targetBoxLabel:SetJustifyH("LEFT")
	targetBoxLabel:SetText(L["Target:"])
	
	local targetBox = TSMAPI.GUI:CreateInputBox(frame)
	targetBox:SetPoint("TOPLEFT", targetBoxLabel, "TOPRIGHT", 5, 0)
	targetBox:SetWidth(100)
	targetBox:SetHeight(20)
	targetBox:SetText(private.target)
	targetBox:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
		end)
	targetBox:SetScript("OnEditFocusLost", function(self)
			self:HighlightText(0, 0)
			private.target = self:GetText():trim()
			private.btn:Update()
		end)
	targetBox:SetScript("OnTabPressed", function(self)
			self:ClearFocus()
			frame.qtyBox:SetFocus()
			frame.qtyBox:HighlightText()
		end)
	TSMAPI.GUI:SetAutoComplete(targetBox, AUTOCOMPLETE_LIST.MAIL)
	targetBox.tooltip = L["Enter the name of the player you want to send this item to."].."\n\n"..TSM.SPELLING_WARNING

	local characterList = {}
	local player = UnitName("player")
	for character in pairs(TSMAPI:GetCharacters()) do
		if not TSMAPI:IsPlayer(character) then
			tinsert(characterList, character)
		end
	end
	local numFriends = GetNumFriends()
	for i = 1, numFriends do
		local name, _, _, _, _ = GetFriendInfo(i)
		tinsert(characterList, name)
	end

	local targetDropdown = TSMAPI.GUI:CreateDropdown(frame, characterList)
	targetDropdown:SetPoint("TOPLEFT", targetBoxLabel, "TOPRIGHT", 5, 0)
	targetDropdown:SetWidth(110)
	targetDropdown:SetHeight(20)
	targetDropdown:SetCallback("OnValueChanged", function(self, _, value)
		     self:SetText("")
			 private.target = characterList[value]
			 targetBox:SetText(private.target)
			 private.btn:Update()
         end)
	targetDropdown.text:Hide()
	targetDropdown.dropdown:SetBackdropColor(0,0,0,0)
	targetDropdown.dropdown:SetBackdropBorderColor(0,0,0,0)

	local qtyBoxLabel = TSMAPI.GUI:CreateLabel(frame, "small")
	qtyBoxLabel:SetPoint("TOPLEFT", targetBox, "TOPRIGHT", 20, 0)
	qtyBoxLabel:SetHeight(20)
	qtyBoxLabel:SetJustifyV("CENTER")
	qtyBoxLabel:SetJustifyH("LEFT")
	qtyBoxLabel:SetText(L["Max Quantity:"])
	
	local qtyBox = TSMAPI.GUI:CreateInputBox(frame)
	qtyBox:SetPoint("TOPLEFT", qtyBoxLabel, "TOPRIGHT", 5, 0)
	qtyBox:SetPoint("TOPRIGHT", -5, -95)
	qtyBox:SetHeight(20)
	qtyBox:SetNumeric(true)
	qtyBox:SetNumber(private.quantity)
	qtyBox:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
		end)
	qtyBox:SetScript("OnEditFocusLost", function(self)
			self:HighlightText(0, 0)
			private.quantity = self:GetNumber()
			private.btn:Update()
		end)
	qtyBox:SetScript("OnTabPressed", function(self)
			self:ClearFocus()
			frame.codBox:SetFocus()
			frame.codBox:HighlightText()
		end)
	qtyBox.tooltip = L["This is the maximum number of the specified item to send when you click the button below. Setting this to 0 will send ALL items."]
	frame.qtyBox = qtyBox

	local moneyBoxLabel = TSMAPI.GUI:CreateLabel(frame, "small")
	moneyBoxLabel:SetPoint("TOPLEFT", 5, -125)
	moneyBoxLabel:SetHeight(20)
	moneyBoxLabel:SetJustifyV("CENTER")
	moneyBoxLabel:SetJustifyH("LEFT")
	moneyBoxLabel:SetText(L["Send Money:"])

	local moneyBox = TSMAPI.GUI:CreateInputBox(frame)
	moneyBox:SetPoint("TOPLEFT", moneyBoxLabel, "TOPRIGHT", 5, 0)
	moneyBox:SetPoint("TOPRIGHT", -5, -125)
	moneyBox:SetHeight(20)
	moneyBox:SetText(TSMAPI:FormatTextMoney(private.money))
	moneyBox:SetScript("OnEnterPressed", function(self)
		local copper = TSMAPI:UnformatTextMoney(self:GetText():trim())
		if copper then
			private.money = copper
			self:SetText(TSMAPI:FormatTextMoney(copper))
			if copper > 0 then
				private.cod = 0
				frame.codBox:SetText(TSMAPI:FormatTextMoney(private.cod))
			end
			self:ClearFocus()
			private.btn:Update()
		else
			self:SetFocus()
		end
	end)
	frame.moneyBox = moneyBox

	local codBoxLabel = TSMAPI.GUI:CreateLabel(frame, "small")
	codBoxLabel:SetPoint("TOPLEFT", 5, -155)
	codBoxLabel:SetHeight(20)
	codBoxLabel:SetJustifyV("CENTER")
	codBoxLabel:SetJustifyH("LEFT")
	codBoxLabel:SetText(L["COD Amount (per Item):"])

	local codBox = TSMAPI.GUI:CreateInputBox(frame)
	codBox:SetPoint("TOPLEFT", codBoxLabel, "TOPRIGHT", 5, 0)
	codBox:SetPoint("TOPRIGHT", -5, -155)
	codBox:SetHeight(20)
	codBox:SetText(TSMAPI:FormatTextMoney(private.cod))
	codBox:SetScript("OnEnterPressed", function(self)
		local copper = TSMAPI:UnformatTextMoney(self:GetText():trim())
		if copper then
			private.cod = copper
			self:SetText(TSMAPI:FormatTextMoney(copper))
			if copper > 0 then
				private.money = 0
				frame.moneyBox:SetText(TSMAPI:FormatTextMoney(private.money))
			end
			self:ClearFocus()
			private.btn:Update()
		else
			self:SetFocus()
		end
	end)
	codBox.tooltip = L["Enter the desired COD amount (per item) to send this item with. Setting this to '0c' will result in no COD being set."]
	frame.codBox = codBox
	
	local function OnClick()
		local itemString = TSMAPI:GetItemString(private.itemLink)
		local items = {}
		if itemString then
			local numHave = 0
			for _, _, iString, quantity in TSMAPI:GetBagIterator() do
				if iString == itemString then
					numHave = numHave + quantity
				end
			end
			local quantity
			if private.quantity == 0 then
				quantity = numHave
			else
				quantity = min(private.quantity, numHave)
			end
			items = {[itemString]=quantity}
		end
		
		TSM.AutoMail:SendItems(items, private.target, private.SendCallback, private.cod > 0 and private.cod, private.money)
		private.btn:SetText(L["Sending..."])
		private.btn:Disable()
	end
	
	local btn = TSMAPI.GUI:CreateButton(frame, 15)
	btn:SetPoint("TOPLEFT", 5, -185)
	btn:SetPoint("TOPRIGHT", -5, -185)
	btn:SetHeight(40)
	btn:GetFontString():SetWidth(btn:GetWidth())
	btn:GetFontString():SetHeight(btn:GetHeight())
	btn:SetScript("OnClick", OnClick)
	btn.tooltip = L["Click this button to send off the item to the specified character."]
	btn.Update = function(self)
		if private.target == "" then
			self:Disable()
			self:SetText(L["No Target Specified"])
		elseif not private.itemLink and private.money and private.money > 0 then
			self:Enable()
			self:SetText(format(L["Send money %s to %s"], TSMAPI:FormatTextMoney(private.money), private.target))
		elseif not private.itemLink then
			self:Disable()
			self:SetText(L["No Item Specified"])
		elseif private.money and private.money> 0 then
			self:Enable()
			if private.quantity == 0 then
				self:SetText(format(L["Send all %s money %s to %s"], private.itemLink, TSMAPI:FormatTextMoney(private.money), private.target))
			else
				self:SetText(format(L["Send %sx%d money %s to %s"], private.itemLink, private.quantity, TSMAPI:FormatTextMoney(private.money), private.target))
			end
		else
			self:Enable()
			if private.cod > 0 then
				if private.quantity == 0 then
					self:SetText(format(L["Send all %s to %s - %s per Item COD"], private.itemLink, private.target, TSMAPI:FormatTextMoney(private.cod)))
				else
					self:SetText(format(L["Send %sx%d to %s - %s per Item COD"], private.itemLink, private.quantity, private.target, TSMAPI:FormatTextMoney(private.cod)))
				end
			else
				if private.quantity == 0 then
					self:SetText(format(L["Send all %s to %s - No COD"], private.itemLink, private.target))
				else
					self:SetText(format(L["Send %sx%d to %s - No COD"], private.itemLink, private.quantity, private.target))
				end
			end
		end
	end
	btn:Update()
	private.btn = btn
	
	return frame
end

function private:SendCallback()
	private.btn:Update()
end