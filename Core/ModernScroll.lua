------------------现代滚动框模板------------------
do
    local c1 = { .4, .4, .4, .5 }
    local c2 = { .8, .8, .8, .5 }

    local function SetModernScrollThumbButtonColor(self, color)
        self.Top:SetColorTexture(unpack(color))
        self.Middle:SetColorTexture(unpack(color))
        self.Bottom:SetColorTexture(unpack(color))
    end

    function BiaoGe_ModernScrollThumbButton_UpdateShape(self)
        local textureWidth = self.textureWidth or 8
        local radius = math.min(textureWidth / 2, self:GetHeight() / 2)

        self.Top:ClearAllPoints()
        self.Top:SetSize(textureWidth, radius)
        self.Top:SetPoint("TOP")

        self.Middle:ClearAllPoints()
        self.Middle:SetWidth(textureWidth)
        self.Middle:SetPoint("TOP", 0, -radius)
        self.Middle:SetPoint("BOTTOM", 0, radius)

        self.Bottom:ClearAllPoints()
        self.Bottom:SetSize(textureWidth, radius)
        self.Bottom:SetPoint("BOTTOM")

        if self.TopMask then
            self.TopMask:ClearAllPoints()
            self.TopMask:SetSize(textureWidth, radius * 2)
            self.TopMask:SetPoint("CENTER", self.Top, "BOTTOM")

            self.BottomMask:ClearAllPoints()
            self.BottomMask:SetSize(textureWidth, radius * 2)
            self.BottomMask:SetPoint("CENTER", self.Bottom, "TOP")
        end
    end

    function BiaoGe_ModernScrollThumbButton_UpdatePosition(bar)
        local thumbButton = bar.ThumbButton
        if not thumbButton then return end

        local minValue, maxValue = bar:GetMinMaxValues()
        local valueRange = maxValue - minValue
        local ratio = 0
        if valueRange > 0 then
            ratio = (bar:GetValue() - minValue) / valueRange
        end

        local travel = math.max(0, bar:GetHeight() - 4 - thumbButton:GetHeight())
        thumbButton:ClearAllPoints()
        thumbButton:SetPoint("TOP", bar, "TOP", 0, -2 - travel * ratio)
    end

    function BiaoGe_ModernScrollFrameTemplate_Update(self)
        local bar = self.ScrollBar
        if not bar then return end

        local trackHeight = bar:GetHeight() - 4
        if trackHeight <= 0 then return end

        local visibleExtent
        local totalExtent
        if self.modernVisibleExtent ~= nil and self.modernTotalExtent ~= nil then
            visibleExtent = self.modernVisibleExtent
            totalExtent = self.modernTotalExtent
        else
            visibleExtent = self:GetHeight()
            totalExtent = visibleExtent + self:GetVerticalScrollRange()
        end

        local thumbHeight = trackHeight
        if totalExtent and totalExtent > 0 then
            thumbHeight = trackHeight * math.min(1, visibleExtent / totalExtent)
        end

        local minThumbHeight = self.minThumbHeight or 24
        thumbHeight = math.max(math.min(minThumbHeight, trackHeight), thumbHeight)
        thumbHeight = math.min(trackHeight, thumbHeight)
        bar:GetThumbTexture():SetHeight(thumbHeight)
        if bar.ThumbButton then
            bar.ThumbButton:SetWidth(bar:GetWidth())
            bar.ThumbButton:SetHeight(thumbHeight)
            BiaoGe_ModernScrollThumbButton_UpdateShape(bar.ThumbButton)
            BiaoGe_ModernScrollThumbButton_UpdatePosition(bar)
        end

        local _, maxValue = bar:GetMinMaxValues()
        local noOverflow
        if self.modernVisibleExtent ~= nil and self.modernTotalExtent ~= nil then
            noOverflow = self.modernTotalExtent <= self.modernVisibleExtent
        else
            noOverflow = maxValue <= 1
        end
        if self.alwaysHideScrollBar or noOverflow then
            bar:Hide()
        else
            bar:Show()
        end
    end

    function BiaoGe_ModernScrollFrameTemplate_SetScrollExtent(self, visibleExtent, totalExtent)
        self.modernVisibleExtent = visibleExtent
        self.modernTotalExtent = totalExtent
        BiaoGe_ModernScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernScrollFrameTemplate_ClearScrollExtent(self)
        self.modernVisibleExtent = nil
        self.modernTotalExtent = nil
        BiaoGe_ModernScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernScrollFrameTemplate_OnLoad(self)
        self:EnableMouse(true)
        self:EnableMouseWheel(true)
        self.SetScrollExtent = BiaoGe_ModernScrollFrameTemplate_SetScrollExtent
        self.ClearScrollExtent = BiaoGe_ModernScrollFrameTemplate_ClearScrollExtent
        self.ScrollBar.scrollStep = BG.scrollStep
        BiaoGe_ModernScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernScrollFrameTemplate_OnScrollRangeChanged(self, xRange, yRange)
        if self.modernVisibleExtent ~= nil then
            BiaoGe_ModernScrollFrameTemplate_Update(self)
            return
        end

        local bar = self.ScrollBar
        yRange = math.max(0, yRange or 0)

        self.modernScrollSyncing = true
        bar:SetMinMaxValues(0, yRange)
        local value = math.min(bar:GetValue(), yRange)
        bar:SetValue(value)
        self:SetVerticalScroll(value)
        self.modernScrollSyncing = nil

        BiaoGe_ModernScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernScrollFrameTemplate_OnVerticalScroll(self, offset)
        if self.modernVisibleExtent ~= nil then return end
        if self.modernScrollSyncing then return end
        self.modernScrollSyncing = true
        self.ScrollBar:SetValue(offset)
        self.modernScrollSyncing = nil
    end

    function BiaoGe_ModernScrollFrameTemplate_OnMouseWheel(self, delta)
        local bar = self.ScrollBar
        local minValue, maxValue = bar:GetMinMaxValues()
        local value = bar:GetValue() - delta * (bar.scrollStep or BG.scrollStep or 20)
        bar:SetValue(math.max(minValue, math.min(value, maxValue)))
    end

    function BiaoGe_ModernScrollBarTemplate_OnLoad(self)
        self:SetMinMaxValues(0, 0)
        self:SetValue(0)
        self:SetValueStep(1)
        self:EnableMouseWheel(true)
        self:Hide()
    end

    function BiaoGe_ModernScrollBarTemplate_OnValueChanged(self, value)
        local scroll = self:GetParent()
        BiaoGe_ModernScrollThumbButton_UpdatePosition(self)
        if scroll.modernVisibleExtent ~= nil then return end
        if scroll.modernScrollSyncing then return end
        scroll.modernScrollSyncing = true
        scroll:SetVerticalScroll(value)
        scroll.modernScrollSyncing = nil
    end

    function BiaoGe_ModernScrollBarTemplate_OnMouseWheel(self, delta)
        BiaoGe_ModernScrollFrameTemplate_OnMouseWheel(self:GetParent(), delta)
    end

    function BiaoGe_ModernScrollBarTemplate_OnEnter(self)
        -- self:GetThumbTexture():SetColorTexture(unpack(c2))
    end

    function BiaoGe_ModernScrollBarTemplate_OnLeave(self)
        -- self:GetThumbTexture():SetColorTexture(unpack(c1))
    end

    function BiaoGe_ModernScrollTrackButton_OnLoad(self)
        self:SetFrameLevel(self:GetParent():GetFrameLevel() + 1)
        self:EnableMouseWheel(true)
    end

    function BiaoGe_ModernScrollTrackButton_OnMouseDown(self, button)
        if button ~= "LeftButton" then return end

        local bar = self:GetParent()
        local thumbButton = bar.ThumbButton
        local minValue, maxValue = bar:GetMinMaxValues()
        local valueRange = maxValue - minValue
        local travel = bar:GetHeight() - 4 - thumbButton:GetHeight()
        local top = bar:GetTop()
        if travel <= 0 or valueRange <= 0 or not top then return end

        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / bar:GetEffectiveScale()
        local ratio = (top - 2 - thumbButton:GetHeight() / 2 - cursorY) / travel
        ratio = math.max(0, math.min(ratio, 1))
        bar:SetValue(minValue + ratio * valueRange)
    end

    function BiaoGe_ModernScrollTrackButton_OnMouseWheel(self, delta)
        BiaoGe_ModernScrollBarTemplate_OnMouseWheel(self:GetParent(), delta)
    end

    local function ModernScrollThumbButton_StopDragging(self)
        self.modernDragging = nil
        self.modernStartCursorY = nil
        self.modernStartValue = nil
        self:SetScript("OnUpdate", nil)
        SetModernScrollThumbButtonColor(self, self:IsMouseOver() and c2 or c1)
    end

    local function ModernScrollThumbButton_OnUpdate(self)
        if not IsMouseButtonDown("LeftButton") then
            ModernScrollThumbButton_StopDragging(self)
            return
        end

        local bar = self:GetParent()
        local minValue, maxValue = bar:GetMinMaxValues()
        local valueRange = maxValue - minValue
        local travel = (bar:GetHeight() - 4 - self:GetHeight()) * bar:GetEffectiveScale()
        if travel <= 0 or valueRange <= 0 then return end

        local _, cursorY = GetCursorPosition()
        local deltaY = cursorY - self.modernStartCursorY
        local value = self.modernStartValue - deltaY / travel * valueRange
        bar:SetValue(math.max(minValue, math.min(value, maxValue)))
    end

    function BiaoGe_ModernScrollThumbButton_OnLoad(self)
        local bar = self:GetParent()
        self:SetFrameLevel(bar:GetFrameLevel() + 2)
        self:SetWidth(bar:GetWidth())

        self.TopMask = self:CreateMaskTexture()
        self.TopMask:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMaskSmall")
        self.Top:AddMaskTexture(self.TopMask)

        self.BottomMask = self:CreateMaskTexture()
        self.BottomMask:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMaskSmall")
        self.Bottom:AddMaskTexture(self.BottomMask)

        BiaoGe_ModernScrollThumbButton_UpdateShape(self)
        BiaoGe_ModernScrollThumbButton_UpdatePosition(bar)
        SetModernScrollThumbButtonColor(self, c1)
    end

    function BiaoGe_ModernScrollThumbButton_OnEnter(self)
        if not self.modernDragging then
            SetModernScrollThumbButtonColor(self, c2)
        end
    end

    function BiaoGe_ModernScrollThumbButton_OnLeave(self)
        if not self.modernDragging then
            SetModernScrollThumbButtonColor(self, c1)
        end
    end

    function BiaoGe_ModernScrollThumbButton_OnMouseDown(self, button)
        if button ~= "LeftButton" then return end

        local _, cursorY = GetCursorPosition()
        self.modernDragging = true
        self.modernStartCursorY = cursorY
        self.modernStartValue = self:GetParent():GetValue()
        self:SetScript("OnUpdate", ModernScrollThumbButton_OnUpdate)
    end

    function BiaoGe_ModernScrollThumbButton_OnMouseUp(self, button)
        if button == "LeftButton" and self.modernDragging then
            ModernScrollThumbButton_StopDragging(self)
        end
    end

    local function SetModernHorizontalScrollThumbButtonColor(self, color)
        self.Left:SetColorTexture(unpack(color))
        self.Middle:SetColorTexture(unpack(color))
        self.Right:SetColorTexture(unpack(color))
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_UpdateShape(self)
        local textureHeight = self.textureHeight or 8
        local radius = math.min(textureHeight / 2, self:GetWidth() / 2)

        self.Left:ClearAllPoints()
        self.Left:SetSize(radius, textureHeight)
        self.Left:SetPoint("LEFT")

        self.Middle:ClearAllPoints()
        self.Middle:SetHeight(textureHeight)
        self.Middle:SetPoint("LEFT", radius, 0)
        self.Middle:SetPoint("RIGHT", -radius, 0)

        self.Right:ClearAllPoints()
        self.Right:SetSize(radius, textureHeight)
        self.Right:SetPoint("RIGHT")

        if self.LeftMask then
            self.LeftMask:ClearAllPoints()
            self.LeftMask:SetSize(radius * 2, textureHeight)
            self.LeftMask:SetPoint("CENTER", self.Left, "RIGHT")

            self.RightMask:ClearAllPoints()
            self.RightMask:SetSize(radius * 2, textureHeight)
            self.RightMask:SetPoint("CENTER", self.Right, "LEFT")
        end
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_UpdatePosition(bar)
        local thumbButton = bar.ThumbButton
        if not thumbButton then return end

        local minValue, maxValue = bar:GetMinMaxValues()
        local valueRange = maxValue - minValue
        local ratio = 0
        if valueRange > 0 then
            ratio = (bar:GetValue() - minValue) / valueRange
        end

        local travel = math.max(0, bar:GetWidth() - 4 - thumbButton:GetWidth())
        thumbButton:ClearAllPoints()
        thumbButton:SetPoint("LEFT", bar, "LEFT", 2 + travel * ratio, 0)
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self)
        local bar = self.ScrollBar
        if not bar then return end

        local trackWidth = bar:GetWidth() - 4
        if trackWidth <= 0 then return end

        local visibleExtent
        local totalExtent
        if self.modernVisibleExtent ~= nil and self.modernTotalExtent ~= nil then
            visibleExtent = self.modernVisibleExtent
            totalExtent = self.modernTotalExtent
        else
            visibleExtent = self:GetWidth()
            totalExtent = visibleExtent + self:GetHorizontalScrollRange()
        end

        local thumbWidth = trackWidth
        if totalExtent and totalExtent > 0 then
            thumbWidth = trackWidth * math.min(1, visibleExtent / totalExtent)
        end

        local minThumbWidth = self.minThumbWidth or 24
        thumbWidth = math.max(math.min(minThumbWidth, trackWidth), thumbWidth)
        thumbWidth = math.min(trackWidth, thumbWidth)
        bar:GetThumbTexture():SetWidth(thumbWidth)
        if bar.ThumbButton then
            bar.ThumbButton:SetWidth(thumbWidth)
            bar.ThumbButton:SetHeight(bar:GetHeight())
            BiaoGe_ModernHorizontalScrollThumbButton_UpdateShape(bar.ThumbButton)
            BiaoGe_ModernHorizontalScrollThumbButton_UpdatePosition(bar)
        end

        local _, maxValue = bar:GetMinMaxValues()
        local noOverflow
        if self.modernVisibleExtent ~= nil and self.modernTotalExtent ~= nil then
            noOverflow = self.modernTotalExtent <= self.modernVisibleExtent
        else
            noOverflow = maxValue <= 1
        end
        if self.alwaysHideScrollBar or noOverflow then
            bar:Hide()
        else
            bar:Show()
        end
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_SetScrollExtent(self, visibleExtent, totalExtent)
        self.modernVisibleExtent = visibleExtent
        self.modernTotalExtent = totalExtent
        BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_ClearScrollExtent(self)
        self.modernVisibleExtent = nil
        self.modernTotalExtent = nil
        BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_OnLoad(self)
        self:EnableMouse(true)
        self:EnableMouseWheel(true)
        self.SetScrollExtent = BiaoGe_ModernHorizontalScrollFrameTemplate_SetScrollExtent
        self.ClearScrollExtent = BiaoGe_ModernHorizontalScrollFrameTemplate_ClearScrollExtent
        self.ScrollBar.scrollStep = BG.scrollStep
        BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_OnScrollRangeChanged(self, xRange, yRange)
        if self.modernVisibleExtent ~= nil then
            BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self)
            return
        end

        local bar = self.ScrollBar
        xRange = math.max(0, xRange or 0)

        self.modernScrollSyncing = true
        bar:SetMinMaxValues(0, xRange)
        local value = math.min(bar:GetValue(), xRange)
        bar:SetValue(value)
        self:SetHorizontalScroll(value)
        self.modernScrollSyncing = nil

        BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self)
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_OnHorizontalScroll(self, offset)
        if self.modernVisibleExtent ~= nil then return end
        if self.modernScrollSyncing then return end
        self.modernScrollSyncing = true
        self.ScrollBar:SetValue(offset)
        self.modernScrollSyncing = nil
    end

    function BiaoGe_ModernHorizontalScrollFrameTemplate_OnMouseWheel(self, delta)
        local bar = self.ScrollBar
        local minValue, maxValue = bar:GetMinMaxValues()
        local value = bar:GetValue() - delta * (bar.scrollStep or BG.scrollStep or 20)
        bar:SetValue(math.max(minValue, math.min(value, maxValue)))
    end

    function BiaoGe_ModernHorizontalScrollBarTemplate_OnLoad(self)
        self:SetMinMaxValues(0, 0)
        self:SetValue(0)
        self:SetValueStep(1)
        self:EnableMouseWheel(true)
        self:Hide()
    end

    function BiaoGe_ModernHorizontalScrollBarTemplate_OnValueChanged(self, value)
        local scroll = self:GetParent()
        BiaoGe_ModernHorizontalScrollThumbButton_UpdatePosition(self)
        if scroll.modernVisibleExtent ~= nil then return end
        if scroll.modernScrollSyncing then return end
        scroll.modernScrollSyncing = true
        scroll:SetHorizontalScroll(value)
        scroll.modernScrollSyncing = nil
    end

    function BiaoGe_ModernHorizontalScrollBarTemplate_OnMouseWheel(self, delta)
        BiaoGe_ModernHorizontalScrollFrameTemplate_OnMouseWheel(self:GetParent(), delta)
    end

    function BiaoGe_ModernHorizontalScrollTrackButton_OnLoad(self)
        self:SetFrameLevel(self:GetParent():GetFrameLevel() + 1)
        self:EnableMouseWheel(true)
    end

    function BiaoGe_ModernHorizontalScrollTrackButton_OnMouseDown(self, button)
        if button ~= "LeftButton" then return end

        local bar = self:GetParent()
        local thumbButton = bar.ThumbButton
        local minValue, maxValue = bar:GetMinMaxValues()
        local valueRange = maxValue - minValue
        local travel = bar:GetWidth() - 4 - thumbButton:GetWidth()
        local left = bar:GetLeft()
        if travel <= 0 or valueRange <= 0 or not left then return end

        local cursorX = GetCursorPosition()
        cursorX = cursorX / bar:GetEffectiveScale()
        local ratio = (cursorX - left - 2 - thumbButton:GetWidth() / 2) / travel
        ratio = math.max(0, math.min(ratio, 1))
        bar:SetValue(minValue + ratio * valueRange)
    end

    function BiaoGe_ModernHorizontalScrollTrackButton_OnMouseWheel(self, delta)
        BiaoGe_ModernHorizontalScrollBarTemplate_OnMouseWheel(self:GetParent(), delta)
    end

    function BiaoGe_ModernHorizontalScrollBarTemplate_OnSizeChanged(self)
        BiaoGe_ModernHorizontalScrollFrameTemplate_Update(self:GetParent())
    end

    local function ModernHorizontalScrollThumbButton_StopDragging(self)
        self.modernDragging = nil
        self.modernStartCursorX = nil
        self.modernStartValue = nil
        self:SetScript("OnUpdate", nil)
        SetModernHorizontalScrollThumbButtonColor(self, self:IsMouseOver() and c2 or c1)
    end

    local function ModernHorizontalScrollThumbButton_OnUpdate(self)
        if not IsMouseButtonDown("LeftButton") then
            ModernHorizontalScrollThumbButton_StopDragging(self)
            return
        end

        local bar = self:GetParent()
        local minValue, maxValue = bar:GetMinMaxValues()
        local valueRange = maxValue - minValue
        local travel = (bar:GetWidth() - 4 - self:GetWidth()) * bar:GetEffectiveScale()
        if travel <= 0 or valueRange <= 0 then return end

        local cursorX = GetCursorPosition()
        local deltaX = cursorX - self.modernStartCursorX
        local value = self.modernStartValue + deltaX / travel * valueRange
        bar:SetValue(math.max(minValue, math.min(value, maxValue)))
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_OnLoad(self)
        local bar = self:GetParent()
        self:SetFrameLevel(bar:GetFrameLevel() + 2)
        self:SetHeight(bar:GetHeight())

        self.LeftMask = self:CreateMaskTexture()
        self.LeftMask:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMaskSmall")
        self.Left:AddMaskTexture(self.LeftMask)

        self.RightMask = self:CreateMaskTexture()
        self.RightMask:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMaskSmall")
        self.Right:AddMaskTexture(self.RightMask)

        BiaoGe_ModernHorizontalScrollThumbButton_UpdateShape(self)
        BiaoGe_ModernHorizontalScrollThumbButton_UpdatePosition(bar)
        SetModernHorizontalScrollThumbButtonColor(self, c1)
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_OnEnter(self)
        if not self.modernDragging then
            SetModernHorizontalScrollThumbButtonColor(self, c2)
        end
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_OnLeave(self)
        if not self.modernDragging then
            SetModernHorizontalScrollThumbButtonColor(self, c1)
        end
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_OnMouseDown(self, button)
        if button ~= "LeftButton" then return end

        local cursorX = GetCursorPosition()
        self.modernDragging = true
        self.modernStartCursorX = cursorX
        self.modernStartValue = self:GetParent():GetValue()
        self:SetScript("OnUpdate", ModernHorizontalScrollThumbButton_OnUpdate)
    end

    function BiaoGe_ModernHorizontalScrollThumbButton_OnMouseUp(self, button)
        if button == "LeftButton" and self.modernDragging then
            ModernHorizontalScrollThumbButton_StopDragging(self)
        end
    end
end
