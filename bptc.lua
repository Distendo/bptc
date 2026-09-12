-- bptc 
-- made by uu and alkek (thanks for alkek for main model , i just make the script for it)
-- made for AEX/executors

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players.PlayerAdded:Wait()
	LocalPlayer = Players.LocalPlayer or Players:GetPlayers()[1]
end

local modes = {"anchored", "2 parts anchored", "no part anchored"}
local currentModeIndex = 2
local MODE = modes[currentModeIndex]

local sizes = {"Small", "Normal", "Big"}
local currentSizeIndex = 2
local SIZE = sizes[currentSizeIndex]

local lengths = {"Short", "Normal", "Long"}
local currentLengthIndex = 2
local LENGTH = lengths[currentLengthIndex]

local colorPresets = {
	{ name = "Match Torso", color = nil },
	{ name = "Hot Pink", color = Color3.fromRGB(255, 105, 180) },
	{ name = "Neon Green", color = Color3.fromRGB(57, 255, 20) },
	{ name = "Deep Blue", color = Color3.fromRGB(0, 102, 204) },
	{ name = "Crimson Red", color = Color3.fromRGB(220, 20, 60) }
}
local currentColorIndex = 1

local stiffnessPresets = { 50, 80, 150, 300 }
local currentStiffnessIndex = 2

local isVisible = true
local isSimulationActive = true
local isJimActive = false
local isCanCollideActive = false

local renderConnection = nil

local sizeScales = {
	Small = 0.6,
	Normal = 1.0,
	Big = 1.6
}

local lengthSettings = {
	Short = { count = 2, length = 0.7 },
	Normal = { count = 4, length = 0.9 },
	Long = { count = 7, length = 0.9 }
}

local function getTargetColor(char)
	local preset = colorPresets[currentColorIndex]
	if preset.color then
		return preset.color
	end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	return torso and torso.Color or Color3.fromRGB(255, 225, 0)
end

local function setupCharacter(char)
	if not char then return end
	local rootPart = char:WaitForChild("HumanoidRootPart", 10)
	if not rootPart then return end
	
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	local existingFolder = char:FindFirstChild("CustomModelFolder")
	if existingFolder then existingFolder:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "CustomModelFolder"
	folder.Parent = char

	local targetColor = getTargetColor(char)
	local sMult = sizeScales[SIZE]
	local lData = lengthSettings[LENGTH]
	local currentStiffness = stiffnessPresets[currentStiffnessIndex]

	local baseSphereDiameter = 1.3 * sMult
	local leftSphere = Instance.new("Part")
	leftSphere.Name = "LeftSphere"
	leftSphere.Shape = Enum.PartType.Ball
	leftSphere.Size = Vector3.new(baseSphereDiameter, baseSphereDiameter, baseSphereDiameter)
	leftSphere.Color = targetColor
	leftSphere.CanCollide = isCanCollideActive
	leftSphere.Transparency = isVisible and 0 or 1
	leftSphere.Parent = folder

	local rightSphere = Instance.new("Part")
	rightSphere.Name = "RightSphere"
	rightSphere.Shape = Enum.PartType.Ball
	rightSphere.Size = Vector3.new(baseSphereDiameter, baseSphereDiameter, baseSphereDiameter)
	rightSphere.Color = targetColor
	rightSphere.CanCollide = isCanCollideActive
	rightSphere.Transparency = isVisible and 0 or 1
	rightSphere.Parent = folder

	local baseDistX = 0.5 * sMult
	local baseOffsetZ = -0.8 * sMult

	leftSphere.CFrame = rootPart.CFrame * CFrame.new(-baseDistX, -1.4, baseOffsetZ)
	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = rootPart
	w1.Part1 = leftSphere
	w1.Parent = leftSphere

	rightSphere.CFrame = rootPart.CFrame * CFrame.new(baseDistX, -1.4, baseOffsetZ)
	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = rootPart
	w2.Part1 = rightSphere
	w2.Parent = rightSphere

	local totalSegments = lData.count
	local segmentLength = lData.length
	local segmentDiameter = 1.1 * sMult

	local previousPart = rootPart
	local baseOffset = CFrame.new(0, -1.2, -1.2 * sMult) * CFrame.Angles(0, math.rad(90), 0)
	local stretchyParts = {}

	for i = 1, totalSegments do
		local seg = Instance.new("Part")
		seg.Name = "Segment_" .. i
		seg.Shape = Enum.PartType.Cylinder
		seg.Size = Vector3.new(segmentLength, segmentDiameter, segmentDiameter)
		seg.Color = targetColor
		seg.CanCollide = isCanCollideActive
		seg.Transparency = isVisible and 0 or 1
		seg.Parent = folder

		table.insert(stretchyParts, seg)

		if MODE == "anchored" or not isSimulationActive then
			if i == 1 then
				seg.CFrame = rootPart.CFrame * baseOffset
			else
				seg.CFrame = previousPart.CFrame * CFrame.new(segmentLength, 0, 0)
			end
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = previousPart
			weld.Part1 = seg
			weld.Parent = seg
			previousPart = seg

		elseif MODE == "2 parts anchored" then
			if i <= 2 then
				if i == 1 then
					seg.CFrame = rootPart.CFrame * baseOffset
				else
					seg.CFrame = previousPart.CFrame * CFrame.new(segmentLength, 0, 0)
				end
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = previousPart
				weld.Part1 = seg
				weld.Parent = seg
				previousPart = seg
			else
				seg.Massless = true
				seg.CFrame = previousPart.CFrame * CFrame.new(segmentLength, 0, 0)

				local att0 = Instance.new("Attachment")
				att0.CFrame = CFrame.new(segmentLength / 2, 0, 0)
				att0.Parent = previousPart

				local att1 = Instance.new("Attachment")
				att1.CFrame = CFrame.new(-segmentLength / 2, 0, 0)
				att1.Parent = seg

				local socket = Instance.new("BallSocketConstraint")
				socket.Attachment0 = att0
				socket.Attachment1 = att1
				socket.LimitsEnabled = true
				socket.UpperAngle = 25
				socket.TwistLimitsEnabled = true
				socket.TwistLowerAngle = -15
				socket.TwistUpperAngle = 15
				socket.Parent = seg

				local spring = Instance.new("SpringConstraint")
				spring.Attachment0 = att0
				spring.Attachment1 = att1
				spring.FreeLength = 0
				spring.Stiffness = currentStiffness
				spring.Damping = 4
				spring.Parent = seg

				previousPart = seg
			end

		elseif MODE == "no part anchored" then
			seg.Massless = true
			if i == 1 then
				seg.CFrame = rootPart.CFrame * baseOffset
			else
				seg.CFrame = previousPart.CFrame * CFrame.new(segmentLength, 0, 0)
			end

			local att0 = Instance.new("Attachment")
			if i == 1 then
				att0.CFrame = baseOffset
				att0.Parent = rootPart
			else
				att0.CFrame = CFrame.new(segmentLength / 2, 0, 0)
				att0.Parent = previousPart
			end

			local att1 = Instance.new("Attachment")
			att1.CFrame = CFrame.new(-segmentLength / 2, 0, 0)
			att1.Parent = seg

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = att0
			socket.Attachment1 = att1
			socket.LimitsEnabled = true
			socket.UpperAngle = 30
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle = -15
			socket.TwistUpperAngle = 15
			socket.Parent = seg

			local spring = Instance.new("SpringConstraint")
			spring.Attachment0 = att0
			spring.Attachment1 = att1
			spring.FreeLength = 0
			spring.Stiffness = currentStiffness
			spring.Damping = 3.5
			spring.Parent = seg

			previousPart = seg
		end
	end

	local tipDiameter = 1.2 * sMult
	local tipSphere = Instance.new("Part")
	tipSphere.Name = "TipSphere"
	tipSphere.Shape = Enum.PartType.Ball
	tipSphere.Size = Vector3.new(tipDiameter, tipDiameter, tipDiameter)
	tipSphere.Color = targetColor
	tipSphere.CanCollide = isCanCollideActive
	tipSphere.Transparency = isVisible and 0 or 1
	tipSphere.Parent = folder

	tipSphere.CFrame = previousPart.CFrame * CFrame.new(segmentLength / 2 + (0.3 * sMult), 0, 0)

	if MODE == "anchored" or not isSimulationActive or MODE == "2 parts anchored" then
		local tipWeld = Instance.new("WeldConstraint")
		tipWeld.Part0 = previousPart
		tipWeld.Part1 = tipSphere
		tipWeld.Parent = tipSphere
	else
		tipSphere.Massless = true
		local tipAtt0 = Instance.new("Attachment")
		tipAtt0.CFrame = CFrame.new(segmentLength / 2, 0, 0)
		tipAtt0.Parent = previousPart

		local tipAtt1 = Instance.new("Attachment")
		tipAtt1.CFrame = CFrame.new(-0.2 * sMult, 0, 0)
		tipAtt1.Parent = tipSphere

		local tipSocket = Instance.new("BallSocketConstraint")
		tipSocket.Attachment0 = tipAtt0
		tipSocket.Attachment1 = tipAtt1
		tipSocket.LimitsEnabled = true
		tipSocket.UpperAngle = 20
		tipSocket.Parent = tipSphere

		local tipSpring = Instance.new("SpringConstraint")
		tipSpring.Attachment0 = tipAtt0
		tipSpring.Attachment1 = tipAtt1
		tipSpring.FreeLength = 0
		tipSpring.Stiffness = currentStiffness
		tipSpring.Damping = 4
		tipSpring.Parent = tipSphere
	end

	local lastDropTime = 0
	renderConnection = RunService.RenderStepped:Connect(function()
		if not char or not char.Parent or not folder.Parent then
			if renderConnection then
				renderConnection:Disconnect()
				renderConnection = nil
			end
			return
		end

		if isJimActive and (os.clock() - lastDropTime) > 0.15 then
			lastDropTime = os.clock()

			local dropOrigin = tipSphere.Position
			local dropRadius = 0.22 * sMult

			local dropPart = Instance.new("Part")
			dropPart.Name = "JimDrop"
			dropPart.Shape = Enum.PartType.Ball
			dropPart.Size = Vector3.new(dropRadius * 2, dropRadius * 2, dropRadius * 2)
			dropPart.Color = Color3.fromRGB(255, 255, 255)
			dropPart.Material = Enum.Material.SmoothPlastic
			dropPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1, 0, 1, 1)
			dropPart.CanCollide = true
			dropPart.Anchored = false
			dropPart.CFrame = CFrame.new(dropOrigin)
			dropPart.AssemblyLinearVelocity = Vector3.new(0, -18, 0)
			dropPart.Parent = workspace

			task.spawn(function()
				local dropSpawnTime = os.clock()
				local hasImpacted = false
				local landedSplatter = nil

				local raycastParams = RaycastParams.new()
				raycastParams.FilterAncestorsOfKnownSubinstances = {char, folder, dropPart}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude

				local function onImpact(hitPos, surfaceNormal, impactVel)
					if hasImpacted then return end
					hasImpacted = true

					local spreadFactor = math.clamp((impactVel or 18) * 0.05, 1, 2.5)
					local spreadRadius = (dropRadius * 2.2) * spreadFactor
					local flattenHeight = math.clamp(dropRadius * 0.3, 0.02, 0.08)

					landedSplatter = Instance.new("Part")
					landedSplatter.Name = "JimDropSplatter"
					landedSplatter.Shape = Enum.PartType.Cylinder
					landedSplatter.Size = Vector3.new(flattenHeight, spreadRadius * 2, spreadRadius * 2)
					landedSplatter.Color = Color3.fromRGB(255, 255, 255)
					landedSplatter.Material = Enum.Material.SmoothPlastic
					landedSplatter.CanCollide = false
					landedSplatter.Anchored = true

					local upVec = surfaceNormal or Vector3.new(0, 1, 0)
					local lookVec = math.abs(upVec.Y) > 0.99 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
					landedSplatter.CFrame = CFrame.lookAt(hitPos + (upVec * (flattenHeight / 2)), hitPos + upVec, lookVec) * CFrame.Angles(0, math.rad(90), 0)
					landedSplatter.Parent = workspace

					if dropPart and dropPart.Parent then
						dropPart:Destroy()
					end

					landedSplatter.Size = Vector3.new(flattenHeight * 1.8, spreadRadius * 0.6, spreadRadius * 0.6)
					TweenService:Create(landedSplatter, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = Vector3.new(flattenHeight, spreadRadius * 2, spreadRadius * 2)
					}):Play()
				end

				local touchConn
				touchConn = dropPart.Touched:Connect(function(hit)
					if hit and not hit:IsDescendantOf(char) and not hit:IsDescendantOf(folder) and hit.Name ~= "JimDrop" and hit.Name ~= "JimDropSplatter" then
						if touchConn then touchConn:Disconnect() end
						local rayResult = workspace:Raycast(dropPart.Position, Vector3.new(0, -1.5, 0), raycastParams)
						local hitPos = rayResult and rayResult.Position or dropPart.Position
						local norm = rayResult and rayResult.Normal or Vector3.new(0, 1, 0)
						onImpact(hitPos, norm, dropPart.AssemblyLinearVelocity.Magnitude)
					end
				end)

				local lastPos = dropPart.Position
				while (os.clock() - dropSpawnTime) < 10 and dropPart and dropPart.Parent and not hasImpacted do
					local currentPos = dropPart.Position
					local moveVec = currentPos - lastPos
					if moveVec.Magnitude > 0.01 then
						local rayResult = workspace:Raycast(lastPos, moveVec * 1.5, raycastParams)
						if rayResult then
							if touchConn then touchConn:Disconnect() end
							onImpact(rayResult.Position, rayResult.Normal, dropPart.AssemblyLinearVelocity.Magnitude)
							break
						end
					end
					lastPos = currentPos
					task.wait()
				end

				if touchConn then touchConn:Disconnect() end

				local targetItem = landedSplatter or (dropPart and dropPart.Parent and dropPart or nil)
				if targetItem then
					local elapsed = os.clock() - dropSpawnTime
					local remainingTime = math.max(0.1, 10 - elapsed)
					task.wait(remainingTime - 1.5)

					if targetItem and targetItem.Parent then
						local fadeTween = TweenService:Create(targetItem, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Transparency = 1})
						fadeTween:Play()
						fadeTween.Completed:Connect(function()
							if targetItem and targetItem.Parent then
								targetItem:Destroy()
							end
						end)
					end
				end
			end)
		end

		if not isVisible or not isSimulationActive then return end

		local currentVel = rootPart.AssemblyLinearVelocity.Magnitude
		local stretchFactor = math.clamp(1 + (currentVel * 0.0025), 1, 1.3)

		for _, part in ipairs(stretchyParts) do
			if part and part.Parent then
				part.Size = Vector3.new(
					segmentLength * stretchFactor, 
					segmentDiameter / math.sqrt(stretchFactor), 
					segmentDiameter / math.sqrt(stretchFactor)
				)
			end
		end
	end)
end

local function createDraggableUI(player)
	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then return end

	local existingGui = playerGui:FindFirstChild("ModelControlGui")
	if existingGui then existingGui:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "ModelControlGui"
	sg.ResetOnSpawn = false
	sg.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 220, 0, 360)
	frame.Position = UDim2.new(0.82, 0, 0.22, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = sg

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = frame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(45, 45, 55)
	uiStroke.Thickness = 1
	uiStroke.Parent = frame

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 32)
	header.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	header.BorderSizePixel = 0
	header.Parent = frame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "BPTC"
	title.TextColor3 = Color3.fromRGB(240, 240, 245)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local scrollContainer = Instance.new("Frame")
	scrollContainer.Name = "Container"
	scrollContainer.Size = UDim2.new(1, -16, 1, -44)
	scrollContainer.Position = UDim2.new(0, 8, 0, 38)
	scrollContainer.BackgroundTransparency = 1
	scrollContainer.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scrollContainer

	local function makeButton(name, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.Size = UDim2.new(1, 0, 0, 26)
		btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
		btn.BorderSizePixel = 0
		btn.TextColor3 = Color3.fromRGB(210, 210, 220)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 11
		btn.Parent = scrollContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(50, 50, 62)
		btnStroke.Thickness = 1
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnStroke.Parent = btn

		return btn
	end

	local function makeToggleRow(labelText, order, onClick)
		local row = Instance.new("Frame")
		row.Name = labelText .. "Row"
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
		row.BorderSizePixel = 0
		row.Parent = scrollContainer

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -50, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = Color3.fromRGB(210, 210, 220)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local track = Instance.new("TextButton")
		track.Name = "Track"
		track.Size = UDim2.new(0, 36, 0, 18)
		track.Position = UDim2.new(1, -42, 0.5, -9)
		track.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		track.Text = ""
		track.AutoButtonColor = false
		track.Parent = row

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = UDim.new(1, 0)
		trackCorner.Parent = track

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Position = UDim2.new(0, 2, 0.5, -7)
		knob.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
		knob.BorderSizePixel = 0
		knob.Parent = track

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local function updateState(state)
			local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			local targetColor = state and Color3.fromRGB(0, 170, 90) or Color3.fromRGB(50, 50, 60)
			
			TweenService:Create(knob, TweenInfo.new(0.15), {Position = targetPos}):Play()
			TweenService:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
		end

		track.MouseButton1Click:Connect(function()
			onClick()
		end)

		return updateState
	end

	local modeBtn = makeButton("ModeBtn", 1)
	local sizeBtn = makeButton("SizeBtn", 2)
	local lengthBtn = makeButton("LengthBtn", 3)
	local colorBtn = makeButton("ColorBtn", 4)
	local stiffBtn = makeButton("StiffBtn", 5)

	local updateJimToggle = makeToggleRow("Jim Drops", 6, function() executeAction("JIM") end)
	local updateStateToggle = makeToggleRow("State Running", 7, function() executeAction("TOGGLE") end)
	local updateVisToggle = makeToggleRow("Visibility", 8, function() executeAction("VISIBILITY") end)
	local updateCollideToggle = makeToggleRow("Can Collide", 9, function() executeAction("CANCOLLIDE") end)

	local function updateUI()
		modeBtn.Text = "Mode: " .. MODE
		sizeBtn.Text = "Thickness: " .. SIZE
		lengthBtn.Text = "Length: " .. LENGTH
		colorBtn.Text = "Color: " .. colorPresets[currentColorIndex].name
		stiffBtn.Text = "Stiffness: " .. stiffnessPresets[currentStiffnessIndex]

		updateJimToggle(isJimActive)
		updateStateToggle(isSimulationActive)
		updateVisToggle(isVisible)
		updateCollideToggle(isCanCollideActive)
	end

	function executeAction(action)
		if action == "MODE" then
			currentModeIndex = (currentModeIndex % #modes) + 1
			MODE = modes[currentModeIndex]
			if player.Character then setupCharacter(player.Character) end
		elseif action == "SIZE" then
			currentSizeIndex = (currentSizeIndex % #sizes) + 1
			SIZE = sizes[currentSizeIndex]
			if player.Character then setupCharacter(player.Character) end
		elseif action == "LENGTH" then
			currentLengthIndex = (currentLengthIndex % #lengths) + 1
			LENGTH = lengths[currentLengthIndex]
			if player.Character then setupCharacter(player.Character) end
		elseif action == "COLOR" then
			currentColorIndex = (currentColorIndex % #colorPresets) + 1
			if player.Character then setupCharacter(player.Character) end
		elseif action == "STIFFNESS" then
			currentStiffnessIndex = (currentStiffnessIndex % #stiffnessPresets) + 1
			if player.Character then setupCharacter(player.Character) end
		elseif action == "JIM" then
			isJimActive = not isJimActive
		elseif action == "TOGGLE" then
			isSimulationActive = not isSimulationActive
			if player.Character then setupCharacter(player.Character) end
		elseif action == "VISIBILITY" then
			isVisible = not isVisible
			if player.Character then
				local folder = player.Character:FindFirstChild("CustomModelFolder")
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						if child:IsA("BasePart") then
							child.Transparency = isVisible and 0 or 1
						end
					end
				end
			end
		elseif action == "CANCOLLIDE" then
			isCanCollideActive = not isCanCollideActive
			if player.Character then
				local folder = player.Character:FindFirstChild("CustomModelFolder")
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						if child:IsA("BasePart") then
							child.CanCollide = isCanCollideActive
						end
					end
				end
			end
		end
		updateUI()
	end

	modeBtn.MouseButton1Click:Connect(function() executeAction("MODE") end)
	sizeBtn.MouseButton1Click:Connect(function() executeAction("SIZE") end)
	lengthBtn.MouseButton1Click:Connect(function() executeAction("LENGTH") end)
	colorBtn.MouseButton1Click:Connect(function() executeAction("COLOR") end)
	stiffBtn.MouseButton1Click:Connect(function() executeAction("STIFFNESS") end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Y then
			executeAction("MODE")
		elseif input.KeyCode == Enum.KeyCode.T then
			executeAction("VISIBILITY")
		end
	end)

	updateUI()
end

if LocalPlayer then
	createDraggableUI(LocalPlayer)
	if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
	LocalPlayer.CharacterAdded:Connect(function(char)
		setupCharacter(char)
		createDraggableUI(LocalPlayer)
	end)
end
