--[[
	Dex REContinued v1.2.2
	Developed by Tesker103
	
	A recontinuation of the old DEX Explorer with many features from the original roadmap
]]

local nodes = {}
local selection

local function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

local waxcloneref = cloneref
local cloneref = if not waxcloneref then function(...) return ... end else setmetatable({}, {__mode = 'v', __call = function(self, obj)
    if not obj then
        return
    end
    local id = obj:GetDebugId()
    local a = self[id]
    if a then
        return a
    end
    a = waxcloneref(obj)
    self[id] = a
    return a
end})

local service = setmetatable({}, {
	__index = function(self, name)
		self[name] = cloneref(game:GetService(name))
		return self[name]
	end
})

local oldgame = game
local game = cloneref(workspace.Parent)

local EmbeddedModules = {
	Explorer = function()
--[[
	Explorer App Module
	
	The main explorer interface
]]
		-- Common Locals
		local Main,Lib,Apps,Settings -- Main Containers
		local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
		local API,RMD,env,service,plr,create,createSimple -- Main Locals

		local function initDeps(data)
			Main = data.Main
			Lib = data.Lib
			Apps = data.Apps
			Settings = data.Settings

			API = data.API
			RMD = data.RMD
			env = data.env
			service = data.service
			plr = data.plr
			create = data.create
			createSimple = data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			ModelViewer = Apps.ModelViewer
			SettingsWindow = Apps.SettingsWindow
			Notebook = Apps.Notebook
		end

		local function main()
			local Explorer = {}
			local tree,listEntries,explorerOrders = {},{},{}
			local searchResults = setmetatable({}, {__mode = "k"})
			local specResults = {}
			local expanded
			local entryTemplate,treeFrame,toolBar,descendantAddedCon,descendantRemovingCon,itemChangedCon
			local ffa = function(obj, class)
				local s, res = pcall(function() return obj:FindFirstAncestorWhichIsA(class) end)
				if s and res then
					if res.ClassName == "DataModel" then return game end
					return cloneref(res)
				end
				return nil
			end
			local badsvcs = {
	["AchievementService"] = false, ["AdService"] = false, ["AnimationClipProvider"] = false,
	["AnalyticsService"] = false, ["AppLifecycleObserverService"] = false, ["AppStorageService"] = false,
	["AssetService"] = false, ["AudioFocusService"] = false, ["AuroraService"] = false,
	["AvatarChatService"] = false, ["AvatarCreationService"] = false, ["AvatarEditorService"] = false,
	["AvatarSettings"] = false, ["BadgeService"] = false, ["BrowserService"] = false,
	["CSGDictionaryService"] = true, ["CaptureService"] = false, ["ChangeHistoryService"] = false,
	["Chat"] = false, ["CollectionService"] = false, ["CommerceService"] = false,
	["ContentProvider"] = false, ["ContextActionService"] = false, ["ControllerService"] = false,
	["CookiesService"] = false, ["CorePackages"] = false, ["CreatorStoreService"] = false,
	["Debris"] = false, ["EditableService"] = false, ["EncodingService"] = true,
	["EventIngestService"] = false, ["ExperienceAuthService"] = false, ["ExperienceNotificationService"] = false,
	["ExperienceService"] = false, ["ExperienceStateCaptureService"] = false, ["ExperienceStateRecordingService"] = false,
	["FaceAnimatorService"] = false, ["FacialAgeEstimationService"] = false, ["FeatureRestrictionManager"] = false,
	["FilteredSelection"] = false, ["FriendService"] = false, ["GamePassService"] = false,
	["GamepadService"] = false, ["GenericChallengeService"] = false, ["GenerationService"] = true,
	["GroupService"] = false, ["GuiService"] = false, ["GuidRegistryService"] = false,
	["HSRDataContentProvider"] = false, ["HapticService"] = false, ["HeapProfilerService"] = false,
	["HeatmapService"] = false, ["HttpRbxApiService"] = false, ["HttpService"] = false,
	["IXPService"] = false, ["InsertService"] = false, ["Instance"] = false,
	["JointsService"] = false, ["KeyboardService"] = true, ["KeyframeSequenceProvider"] = false,
	["LinkingService"] = true, ["LocalizationService"] = false, ["LocalizationTable"] = false,
	["LodDataService"] = false, ["LogService"] = false, ["MarketplaceService"] = false,
	["MaterialService"] = false, ["MemStorageService"] = false, ["MeshContentProvider"] = false,
	["MessageBusService"] = false, ["MicroProfilerService"] = false, ["ModerationService"] = false,
	["MouseService"] = false, ["NetworkClient"] = true, ["NetworkServer"] = true,
	["NonReplicatedCSGDictionaryService"] = true, ["NotificationService"] = true, ["Packages"] = false,
	["PermissionsService"] = false, ["PhysicsService"] = false, ["PlatformCloudStorageService"] = true,
	["PlatformFriendsService"] = false, ["PlatformLibraries"] = false, ["PlayerEmulatorService"] = true,
	["PlayerHydrationService"] = false, ["PointsService"] = true, ["PolicyService"] = true,
	["ProximityPromptService"] = false, ["RbxAnalyticsService"] = true, ["RecommendationService"] = false,
	["RobloxPluginGuiService"] = true, ["RobloxReplicatedStorage"] = false, ["RobloxServerStorage"] = false,
	["RtMessagingService"] = false, ["Run Service"] = false, ["RuntimeContentService"] = false,
	["RuntimeScriptService"] = false, ["SafetyService"] = false, ["Script Context"] = false,
	["ScriptProfilerService"] = false, ["ScriptRegistrationService"] = false, ["ScriptService"] = true,
	["Selection"] = false, ["ServerScriptService"] = true, ["ServerStorage"] = true,
	["SessionService"] = false, ["SharedTableRegistry"] = false, ["SlimAnimationReplicationService"] = false,
	["SlimContentProvider"] = false, ["SlimReplicationService"] = false, ["SocialService"] = false,
	["SolidModelContentProvider"] = false, ["SoundService"] = false, ["SpawnerService"] = false,
	["Stats"] = false, ["StudioData"] = false, ["StylingService"] = false,
	["TelemetryService"] = false, ["Teleport Service"] = false, ["TemporaryCageMeshProvider"] = false,
	["TestService"] = true, ["TextBoxService"] = false, ["TextChatService"] = false,
	["TextService"] = false, ["ThirdPartyUserService"] = false, ["TimerService"] = false,
	["TouchInputService"] = false, ["TweenService"] = false, ["UIDragDetectorService"] = false,
	["UserInputService"] = false, ["UserService"] = false, ["VRService"] = false,
	["VideoCaptureService"] = false, ["VideoService"] = false, ["VirtualInputManager"] = true,
	["VirtualUser"] = true, ["Visit"] = false, ["VoiceChatService"] = false,
	["WebViewService"] = false, ["WebsocketService"] = true
}

local legitservices = {"Workspace", "Players", "Lighting", "ReplicatedFirst","ReplicatedStorage", "StarterGui", "StarterPlayer", "StarterPack", "CoreGui", "SoundService"}

			local always = {}
			for i, Name in next, legitservices do
				always[Name] = i
			end

			local function sortsss(Children)
				local always_1 = {}
				local etc = {}
				for _, Child in next, Children do
					if always[Child.Name] then
						table.insert(always_1, Child)
					else
						table.insert(etc, Child)
					end
				end

				table.sort(always_1, function(Left, Right) return always[Left.Name] < always[Right.Name] end)
				table.sort(etc, function(Left, Right) return Left.Name:lower() < Right.Name:lower() end)

				local Sorted = {}
				for _, Child in next, always_1 do table.insert(Sorted, Child) end
				for _, Child in next, etc do table.insert(Sorted, Child) end
				return Sorted
			end

			local ggc = game.GetChildren
			local ggd = game.GetDescendants

			local getDescendants = function(obj)
				local ok, raw = pcall(ggd, obj)
				if not ok or type(raw) ~= "table" then return {} end
				
				setmetatable(raw, {__mode = "v"})
				
				local Out = {}
				for Index = 1, #raw do
					local child = raw[Index]
					if child then
						local s, name = pcall(function() return child.Name end)
						local s2, parent = pcall(function() return child.Parent end)
						local s3, class = pcall(function() return child.ClassName end)
						
						if s and s2 and s3 and (badsvcs[name] or badsvcs[class]) and parent and parent.ClassName == "DataModel" then continue end
						
						Out[#Out + 1] = cloneref(child)
					end
					raw[Index] = nil
				end
				return Out
			end

			local getTextSize = service.TextService.GetTextSize
			local updateDebounce,refreshDebounce = false,false
			local nilNode = {Obj = Instance.new("Folder")}
			local idCounter = 0
			local scrollV,scrollH,clipboard
			local renameBox,renamingNode,searchFunc
			local sortingEnabled,autoUpdateSearch
			local table,math = table,math
			local nilMap, nilCons = {}, {}
			local connectSignal = game.DescendantAdded.Connect
			local addObject,removeObject,moveObject = nil,nil,nil
			local iconData
			local remote_blocklist = setmetatable({}, {__mode = "k"})

			local function chk(i)
 			if typeof(i) == "Instance" then
     			local s, c = pcall(function() return i.ClassName end)
     			if s and rawget(badsvcs, c) ~= nil then rawset(badsvcs, c, true) end
    			end
			end

pcall(function()
			for _, v in next, getgc(true) do
   			chk(v)
    			if typeof(v) == "table" then
      			for tk, tv in next, v do
        		chk(tk)
        	        chk(tv)
	      	 	end
		        end
			end
end)

			addObject = function(root)
				root = cloneref(root)
				if nodes[root] then return end

				local s, name = pcall(function() return root.Name end)
				local s2, parent = pcall(function() return root.Parent end)
				local s3, class = pcall(function() return root.ClassName end)
				if s and s2 and s3 and (badsvcs[name] or badsvcs[class]) and (parent and parent.ClassName == "DataModel") then return end

				local isNil = false
				local rootParObj = ffa(root,"Instance")
				local par = nodes[rootParObj]

				-- Nil Handling
				if not par then
					if nilMap[root] then
						nilCons[root] = nilCons[root] or {
							connectSignal(root.ChildAdded, function(c) addObject(cloneref(c)) end),
							connectSignal(root.AncestryChanged, function(c) moveObject(cloneref(c)) end),
						}
						par = nilNode
						isNil = true
					else
						return
					end
				elseif nilMap[rootParObj] or par == nilNode then
					nilMap[root] = true
					nilCons[root] = nilCons[root] or {
						connectSignal(root.ChildAdded, function(c) addObject(cloneref(c)) end),
						connectSignal(root.AncestryChanged, function(c) moveObject(cloneref(c)) end),
					}
					isNil = true
				end

				local newNode = {Obj = root, Parent = par}
				nodes[root] = newNode

				pcall(function()
					root.AncestryChanged:Connect(function()
						moveObject(root)
					end)
					if Settings.Explorer.UseNameWidth then
						root:GetPropertyChangedSignal("Name"):Connect(function()
							if nodes[root] then nodes[root].NameWidth = nil end
						end)
					end
				end)

				-- Automatic sorting if expanded
				if sortingEnabled and expanded[par] and par.Sorted then
					local left,right = 1,#par
					local floor = math.floor
					local sorter = Explorer.NodeSorter
					local pos = (right == 0 and 1)

					if not pos then
						while true do
							if left >= right then
								if sorter(newNode,par[left]) then
									pos = left
								else
									pos = left+1
								end
								break
							end

							local mid = floor((left+right)/2)
							if sorter(newNode,par[mid]) then
								right = mid-1
							else
								left = mid+1
							end
						end
					end

					table.insert(par,pos,newNode)
				else
					par[#par+1] = newNode
					par.Sorted = nil
				end

				local insts = getDescendants(root)
				for i = 1,#insts do
					local obj = insts[i]
					if nodes[obj] then continue end -- Deferred

					local par = nodes[ffa(obj,"Instance")]
					if not par then continue end
					local newNode = {Obj = obj, Parent = par}
					nodes[obj] = newNode
					par[#par+1] = newNode

					-- Nil Handling
					if isNil then
						nilMap[obj] = true
						nilCons[obj] = nilCons[obj] or {
							connectSignal(obj.ChildAdded, function(c) addObject(cloneref(c)) end),
							connectSignal(obj.AncestryChanged, function(c) moveObject(cloneref(c)) end),
						}
					end
				end

				if searchFunc and autoUpdateSearch then
					searchFunc({newNode})
				end

				if not updateDebounce and Explorer.IsNodeVisible(par) then
					if expanded[par] then
						Explorer.PerformUpdate()
					elseif not refreshDebounce then
						Explorer.PerformRefresh()
					end
				end
			end

			removeObject = function(root)
				root = cloneref(root)
				local node = nodes[root]
				if not node then return end

				-- Nil Handling
				if nilMap[node.Obj] then
					moveObject(node.Obj)
					return
				end

				local par = node.Parent
    if par then
        local pos = table.find(par, node)
        if pos then
            table.remove(par, pos)
        end
    end

				local function recur(root)
					for i = 1,#root do
						local node = root[i]
						if not node.Del then
							nodes[node.Obj] = nil
							if #node > 0 then recur(node) end
						end
					end
				end
				recur(node)
				node.Del = true
				nodes[root] = nil

				if par and not updateDebounce and Explorer.IsNodeVisible(par) then
					if expanded[par] then
						Explorer.PerformUpdate()
					elseif not refreshDebounce then
						Explorer.PerformRefresh()
					end
				end
			end

			moveObject = function(obj)
				obj = cloneref(obj)
				local node = nodes[obj]
				if not node then return end

				local oldPar = node.Parent
				local newPar = nodes[ffa(obj,"Instance")]
				if oldPar == newPar then return end

				-- Nil Handling
				if not newPar then
					if nilMap[obj] then
						newPar = nilNode
					else
						removeObject(obj)
						return
					end
				elseif nilMap[newPar.Obj] or newPar == nilNode then
					nilMap[obj] = true
					nilCons[obj] = nilCons[obj] or {
						connectSignal(obj.ChildAdded, function(c) addObject(cloneref(c)) end),
						connectSignal(obj.AncestryChanged, function(c) moveObject(cloneref(c)) end),
					}
				end

				if oldPar then
					local parPos = table.find(oldPar,node)
					if parPos then table.remove(oldPar,parPos) end
				end

				node.Id = nil
				node.Parent = newPar

				if sortingEnabled and expanded[newPar] and newPar.Sorted then
					local left,right = 1,#newPar
					local floor = math.floor
					local sorter = Explorer.NodeSorter
					local pos = (right == 0 and 1)

					if not pos then
						while true do
							if left >= right then
								if sorter(node,newPar[left]) then
									pos = left
								else
									pos = left+1
								end
								break
							end

							local mid = floor((left+right)/2)
							if sorter(node,newPar[mid]) then
								right = mid-1
							else
								left = mid+1
							end
						end
					end

					table.insert(newPar,pos,node)
				else
					newPar[#newPar+1] = node
					newPar.Sorted = nil
				end

				if searchFunc and searchResults[node] then
					local currentNode = node.Parent
					while currentNode and (not searchResults[currentNode] or expanded[currentNode] == 0) do
						expanded[currentNode] = true
						searchResults[currentNode] = true
						currentNode = currentNode.Parent
					end
				end

				if not updateDebounce and (Explorer.IsNodeVisible(newPar) or Explorer.IsNodeVisible(oldPar)) then
					if expanded[newPar] or expanded[oldPar] then
						Explorer.PerformUpdate()
					elseif not refreshDebounce then
						Explorer.PerformRefresh()
					end
				end
			end

			Explorer.ViewWidth = 0
			Explorer.Index = 0
			Explorer.EntryIndent = 20
			Explorer.FreeWidth = 32
			Explorer.GuiElems = {}

			Explorer.InitRenameBox = function()
				renameBox = create({{1,"TextBox",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.062745101749897,0.51764708757401,1),BorderMode=2,ClearTextOnFocus=false,Font=3,Name="RenameBox",PlaceholderColor3=Color3.new(0.69803923368454,0.69803923368454,0.69803923368454),Position=UDim2.new(0,26,0,2),Size=UDim2.new(0,200,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,Visible=false,ZIndex=2}}})

				renameBox.Parent = Explorer.Window.GuiElems.Content.List

				renameBox.FocusLost:Connect(function()
					if not renamingNode then return end

					pcall(function() renamingNode.Obj.Name = renameBox.Text end)
					renamingNode = nil
					Explorer.Refresh()
				end)

				renameBox.Focused:Connect(function()
					renameBox.SelectionStart = 1
					renameBox.CursorPosition = #renameBox.Text + 1
				end)
			end

			Explorer.SetRenamingNode = function(node)
				renamingNode = node
				renameBox.Text = tostring(node.Obj)
				renameBox:CaptureFocus()
				Explorer.Refresh()
			end

			Explorer.SetSortingEnabled = function(val)
				sortingEnabled = val
				Settings.Explorer.Sorting = val
			end

			Explorer.UpdateView = function()
				local maxNodes = math.ceil(treeFrame.AbsoluteSize.Y / 20)
				local maxX = treeFrame.AbsoluteSize.X
				local totalWidth = Explorer.ViewWidth + Explorer.FreeWidth

				scrollV.VisibleSpace = maxNodes
				scrollV.TotalSpace = #tree + 1
				scrollH.VisibleSpace = maxX
				scrollH.TotalSpace = totalWidth

				scrollV.Gui.Visible = #tree + 1 > maxNodes
				scrollH.Gui.Visible = totalWidth > maxX

				local oldSize = treeFrame.Size
				treeFrame.Size = UDim2.new(1,(scrollV.Gui.Visible and -16 or 0),1,(scrollH.Gui.Visible and -39 or -23))
				if oldSize ~= treeFrame.Size then
					Explorer.UpdateView()
				else
					scrollV:Update()
					scrollH:Update()

					renameBox.Size = UDim2.new(0,maxX-100,0,16)

					if scrollV.Gui.Visible and scrollH.Gui.Visible then
						scrollV.Gui.Size = UDim2.new(0,16,1,-39)
						scrollH.Gui.Size = UDim2.new(1,-16,0,16)
						Explorer.Window.GuiElems.Content.ScrollCorner.Visible = true
					else
						scrollV.Gui.Size = UDim2.new(0,16,1,-23)
						scrollH.Gui.Size = UDim2.new(1,0,0,16)
						Explorer.Window.GuiElems.Content.ScrollCorner.Visible = false
					end

					Explorer.Index = scrollV.Index
				end
			end

			Explorer.NodeSorter = function(a,b)
				if a.Del or b.Del then return false end -- Ghost node

				local aClass = a.Class
				local bClass = b.Class
				if not aClass then aClass = a.Obj.ClassName a.Class = aClass end
				if not bClass then bClass = b.Obj.ClassName b.Class = bClass end

				local aOrder = explorerOrders[aClass]
				local bOrder = explorerOrders[bClass]
				if not aOrder then aOrder = RMD.Classes[aClass] and tonumber(RMD.Classes[aClass].ExplorerOrder) or 9999 explorerOrders[aClass] = aOrder end
				if not bOrder then bOrder = RMD.Classes[bClass] and tonumber(RMD.Classes[bClass].ExplorerOrder) or 9999 explorerOrders[bClass] = bOrder end

				if aOrder ~= bOrder then
					return aOrder < bOrder
				else
					local aName,bName = tostring(a.Obj),tostring(b.Obj)
					if aName ~= bName then
						return aName < bName
					elseif aClass ~= bClass then
						return aClass < bClass
					else
						local aId = a.Id if not aId then aId = idCounter idCounter = (idCounter+0.001)%999999999 a.Id = aId end
						local bId = b.Id if not bId then bId = idCounter idCounter = (idCounter+0.001)%999999999 b.Id = bId end
						return aId < bId
					end
				end
			end

			Explorer.Update = function()
				local topNode = tree[scrollV.Index + 1]
				table.clear(tree)
				local maxNameWidth,maxDepth,count = 0,1,1
				local nameCache = {}
				local font = Enum.Font.SourceSans
				local size = Vector2.new(math.huge,20)
				local useNameWidth = Settings.Explorer.UseNameWidth
				local tSort = table.sort
				local sortFunc = Explorer.NodeSorter
				local isSearching = (expanded == Explorer.SearchExpanded)
				local textServ = service.TextService

				local function recur(root,depth)
					if depth > maxDepth then maxDepth = depth end
					depth = depth + 1
					if sortingEnabled and not root.Sorted then
						tSort(root,sortFunc)
						root.Sorted = true
					end
					for i = 1,#root do
						local n = root[i]

						if (isSearching and not searchResults[n]) or n.Del then continue end

						if useNameWidth then
							local nameWidth = n.NameWidth
							if not nameWidth then
								local objName = tostring(n.Obj)
								nameWidth = nameCache[objName]
								if not nameWidth then
									nameWidth = getTextSize(textServ,objName,14,font,size).X
									nameCache[objName] = nameWidth
								end
								n.NameWidth = nameWidth
							end
							if nameWidth > maxNameWidth then
								maxNameWidth = nameWidth
							end
						end

						tree[count] = n
						count = count + 1
						if expanded[n] and #n > 0 then
							recur(n,depth)
						end
					end
				end

				recur(nodes[game],1)

				-- Nil Instances
				if env.getnilinstances then
					if not (isSearching and not searchResults[nilNode]) then
						tree[count] = nilNode
						count = count + 1
						if expanded[nilNode] then
							recur(nilNode,2)
						end
					end
				end

		if Settings.Explorer.StopAutoScroll and topNode then
			local newIdx = table.find(tree, topNode)
			if newIdx then
				scrollV.Index = newIdx - 1
			end
		end

				Explorer.MaxNameWidth = maxNameWidth
				Explorer.MaxDepth = maxDepth
				Explorer.ViewWidth = useNameWidth and Explorer.EntryIndent*maxDepth + maxNameWidth + 26 or Explorer.EntryIndent*maxDepth + 226
				Explorer.UpdateView()
			end

			Explorer.StartDrag = function(offX,offY)
				if Explorer.Dragging then return end
				for i,v in next, selection.List do
					local Obj = v.Obj
					if Obj.Parent == game or Obj:IsA("Player") then
						return
					end
				end
				Explorer.Dragging = true

				local dragTree = treeFrame:Clone()
				dragTree:ClearAllChildren()

				for i,v in pairs(listEntries) do
					local node = tree[i + Explorer.Index]
					if node and selection.Map[node] then
						local clone = v:Clone()
						clone.Active = false
						clone.Indent.Expand.Visible = false
						clone.Parent = dragTree
					end
				end

				local newGui = Instance.new("ScreenGui")
				newGui.DisplayOrder = Main.DisplayOrders.Menu
				dragTree.Parent = newGui
				Lib.ShowGui(newGui)

				local dragOutline = create({
					{1,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="DragSelect",Size=UDim2.new(1,0,1,0),}},
					{2,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Size=UDim2.new(1,0,0,1),ZIndex=2,}},
					{3,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),ZIndex=2,}},
					{4,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Size=UDim2.new(0,1,1,0),ZIndex=2,}},
					{5,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Line",Parent={1},Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=2,}},
				})
				dragOutline.Parent = treeFrame

				local mouse = Main.Mouse or service.Players.LocalPlayer:GetMouse()
				local function move()
					local posX = mouse.X - offX
					local posY = mouse.Y - offY
					dragTree.Position = UDim2.new(0,posX,0,posY)

					for i = 1,#listEntries do
						local entry = listEntries[i]
						if Lib.CheckMouseInGui(entry) then
							dragOutline.Position = UDim2.new(0,entry.Indent.Position.X.Offset-scrollH.Index,0,entry.Position.Y.Offset)
							dragOutline.Size = UDim2.new(0,entry.Size.X.Offset-entry.Indent.Position.X.Offset,0,20)
							dragOutline.Visible = true
							return
						end
					end
					dragOutline.Visible = false
				end
				move()

				local input = service.UserInputService
				local mouseEvent,releaseEvent

				mouseEvent = input.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						move()
					end
				end)

				releaseEvent = input.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						releaseEvent:Disconnect()
						mouseEvent:Disconnect()
						newGui:Destroy()
						dragOutline:Destroy()
						Explorer.Dragging = false

						for i = 1,#listEntries do
							if Lib.CheckMouseInGui(listEntries[i]) then
								local node = tree[i + Explorer.Index]
								if node then
									if selection.Map[node] then return end
									local newPar = node.Obj
									local sList = selection.List
									for i = 1,#sList do
										local n = sList[i]
										pcall(function() n.Obj.Parent = newPar end)
									end
									Explorer.ViewNode(sList[1])
								end
								break
							end
						end
					end
				end)
			end

			Explorer.NewListEntry = function(index)
				local newEntry = entryTemplate:Clone()
				newEntry.Position = UDim2.new(0,0,0,20*(index-1))

				local isRenaming = false

				newEntry.InputBegan:Connect(function(input)
					local node = tree[index + Explorer.Index]
					if not node or selection.Map[node] or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

					newEntry.Indent.BackgroundColor3 = Settings.Theme.Button
					newEntry.Indent.BorderSizePixel = 0
					newEntry.Indent.BackgroundTransparency = 0
				end)

				newEntry.InputEnded:Connect(function(input)
					local node = tree[index + Explorer.Index]
					if not node or selection.Map[node] or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

					newEntry.Indent.BackgroundTransparency = 1
				end)

				newEntry.MouseButton1Down:Connect(function()

				end)

				newEntry.MouseButton1Up:Connect(function()

				end)

				newEntry.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent, mouseEvent

						local mouse = Main.Mouse or plr:GetMouse()
						local startX, startY

						if input.UserInputType == Enum.UserInputType.Touch then
							startX = input.Position.X
							startY = input.Position.Y
						else
							startX = mouse.X
							startY = mouse.Y
						end

						local listOffsetX = startX - treeFrame.AbsolutePosition.X
						local listOffsetY = startY - treeFrame.AbsolutePosition.Y

						releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								mouseEvent:Disconnect()
							end
						end)

						mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								local currentX, currentY

								if input.UserInputType == Enum.UserInputType.Touch then
									currentX = input.Position.X
									currentY = input.Position.Y
								else
									currentX = mouse.X
									currentY = mouse.Y
								end

								local deltaX = currentX - startX
								local deltaY = currentY - startY
								local dist = math.sqrt(deltaX^2 + deltaY^2)

								if dist > 5 then
									releaseEvent:Disconnect()
									mouseEvent:Disconnect()
									isRenaming = false
									Explorer.StartDrag(listOffsetX, listOffsetY)
								end
							end
						end)
					end
				end)

				newEntry.MouseButton2Down:Connect(function()

				end)

				newEntry.Indent.Expand.InputBegan:Connect(function(input)
					local node = tree[index + Explorer.Index]
					if not node or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

					if input.UserInputType == Enum.UserInputType.Touch then
						Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse_Over" or "Expand_Over")
					elseif input.UserInputType == Enum.UserInputType.MouseMovement then
						Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse_Over" or "Expand_Over")
					end
				end)

				newEntry.Indent.Expand.InputEnded:Connect(function(input)
					local node = tree[index + Explorer.Index]
					if not node or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

					if input.UserInputType == Enum.UserInputType.Touch then
						Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
					elseif input.UserInputType == Enum.UserInputType.MouseMovement then
						Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
					end
				end)

				newEntry.Indent.Expand.MouseButton1Down:Connect(function()
					local node = tree[index + Explorer.Index]
					if not node or #node == 0 then return end

					expanded[node] = not expanded[node]
					Explorer.Update()
					Explorer.Refresh()
				end)

				newEntry.Parent = treeFrame
				return newEntry
			end

			Explorer.Refresh = function()
				local maxNodes = math.max(math.ceil((treeFrame.AbsoluteSize.Y) / 20), 0)	
				local renameNodeVisible = false
				local isa = game.IsA

				for i = 1,maxNodes do
					local entry = listEntries[i]
					if not listEntries[i] then entry = Explorer.NewListEntry(i) listEntries[i] = entry Explorer.ClickSystem:Add(entry) end

					local node = tree[i + Explorer.Index]
					if node then
						local obj = node.Obj
						local depth = Explorer.EntryIndent*Explorer.NodeDepth(node)

						entry.Visible = true
						entry.Position = UDim2.new(0,-scrollH.Index,0,entry.Position.Y.Offset)
						entry.Size = UDim2.new(0,Explorer.ViewWidth,0,20)
						entry.Indent.EntryName.Text = tostring(node.Obj)
						entry.Indent.Position = UDim2.new(0,depth,0,0)
						entry.Indent.Size = UDim2.new(1,-depth,1,0)

						entry.Indent.EntryName.TextTruncate = (Settings.Explorer.UseNameWidth and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd)

						Explorer.MiscIcons:DisplayExplorerIcons(entry.Indent.Icon, obj.ClassName)

						if selection.Map[node] then
							entry.Indent.BackgroundColor3 = Settings.Theme.ListSelection
							entry.Indent.BorderSizePixel = 0
							entry.Indent.BackgroundTransparency = 0
						else
							if Lib.CheckMouseInGui(entry) then
								entry.Indent.BackgroundColor3 = Settings.Theme.Button
							else
								entry.Indent.BackgroundTransparency = 1
							end
						end

						if node == renamingNode then
							renameNodeVisible = true
							renameBox.Position = UDim2.new(0,depth+25-scrollH.Index,0,entry.Position.Y.Offset+2)
							renameBox.Visible = true
						end

						if #node > 0 and expanded[node] ~= 0 then
							if Lib.CheckMouseInGui(entry.Indent.Expand) then
								Explorer.MiscIcons:DisplayByKey(entry.Indent.Expand.Icon, expanded[node] and "Collapse_Over" or "Expand_Over")
							else
								Explorer.MiscIcons:DisplayByKey(entry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
							end
							entry.Indent.Expand.Visible = true
						else
							entry.Indent.Expand.Visible = false
						end
					else
						entry.Visible = false
					end
				end

				if not renameNodeVisible then
					renameBox.Visible = false
				end

				for i = maxNodes+1, #listEntries do
					Explorer.ClickSystem:Remove(listEntries[i])
					listEntries[i]:Destroy()
					listEntries[i] = nil
				end
			end

			Explorer.PerformUpdate = function(instant)
				updateDebounce = true
				Lib.FastWait(not instant and 0.1)
				if not updateDebounce then return end
				updateDebounce = false
				if not Explorer.Window:IsVisible() then return end
				Explorer.Update()
				Explorer.Refresh()
			end

			Explorer.ForceUpdate = function(norefresh)
				updateDebounce = false
				Explorer.Update()
				if not norefresh then Explorer.Refresh() end
			end

			Explorer.PerformRefresh = function()
				refreshDebounce = true
				Lib.FastWait(0.1)
				refreshDebounce = false
				if updateDebounce or not Explorer.Window:IsVisible() then return end
				Explorer.Refresh()
			end

			Explorer.IsNodeVisible = function(node)
				if not node then return end

				local curNode = node.Parent
				while curNode do
					if not expanded[curNode] then return false end
					curNode = curNode.Parent
				end
				return true
			end

			Explorer.NodeDepth = function(node)
				local depth = 0

				if node == nilNode then
					return 1
				end

				local curNode = node.Parent
				while curNode do
					if curNode == nilNode then depth = depth + 1 end
					curNode = curNode.Parent
					depth = depth + 1
				end
				return depth
			end

			local sconns = {}
			Explorer.SetupConnections = function()
				for _, con in next, sconns do con:Disconnect() end
				table.clear(sconns)
				local function hs(svc)
					if Main.Elevated then
						table.insert(sconns, svc.DescendantAdded:Connect(function(obj) addObject(cloneref(obj)) end))
						table.insert(sconns, svc.DescendantRemoving:Connect(function(obj) removeObject(cloneref(obj)) end))
					else
						table.insert(sconns, svc.DescendantAdded:Connect(function(obj) pcall(addObject, cloneref(obj)) end))
						table.insert(sconns, svc.DescendantRemoving:Connect(function(obj) pcall(removeObject, cloneref(obj)) end))
					end
				end

				local ggc = game.GetChildren
				local ok, children = pcall(ggc, game)
				if ok and type(children) == "table" then
					setmetatable(children, {__mode = "v"})
					for _, svc in next, children do
						local s, name = pcall(function() return svc.Name end)
						local s3, class = pcall(function() return svc.ClassName end)
						if s and s3 and not (badsvcs[name] or badsvcs[class]) then
							hs(svc)
						end
					end
				end
				table.insert(sconns, game.ChildAdded:Connect(function(child)
					local s, name = pcall(function() return child.Name end)
					local s3, class = pcall(function() return child.ClassName end)
					if s and s3 and not (badsvcs[name] or badsvcs[class]) then
						hs(child)
						if Main.Elevated then addObject(cloneref(child)) else pcall(addObject, cloneref(child)) end
					end
				end))

				table.insert(sconns, game.ChildRemoved:Connect(function(child)
					if Main.Elevated then removeObject(cloneref(child)) else pcall(removeObject, cloneref(child)) end
				end))
			end

			Explorer.ViewNode = function(node)
				if not node then return end

				Explorer.MakeNodeVisible(node)
				Explorer.ForceUpdate(true)
				local visibleSpace = scrollV.VisibleSpace

				for i,v in next,tree do
					if v == node then
						local relative = i - 1
						if Explorer.Index > relative then
							scrollV.Index = relative
						elseif Explorer.Index + visibleSpace - 1 <= relative then
							scrollV.Index = relative - visibleSpace + 2
						end
					end
				end

				scrollV:Update() Explorer.Index = scrollV.Index
				Explorer.Refresh()
			end

			Explorer.ViewObj = function(obj)
				Explorer.ViewNode(nodes[obj])
			end

			Explorer.MakeNodeVisible = function(node,expandRoot)
				if not node then return end

				local hasExpanded = false

				if expandRoot and not expanded[node] then
					expanded[node] = true
					hasExpanded = true
				end

				local currentNode = node.Parent
				while currentNode do
					hasExpanded = true
					expanded[currentNode] = true
					currentNode = currentNode.Parent
				end

				if hasExpanded and not updateDebounce then
					coroutine.wrap(Explorer.PerformUpdate)(true)
				end
			end

			Explorer.ShowRightClick = function(MousePos)
				local Mouse = MousePos or Main.Mouse
				local context = Explorer.RightClickContext
				local absoluteSize = context.Gui.AbsoluteSize
				context.MaxHeight = (absoluteSize.Y <= 600 and (absoluteSize.Y - 40)) or nil
				context:Clear()

				local sList = selection.List
				local sMap = selection.Map
				local emptyClipboard = #clipboard == 0
				local presentClasses = {}
				local apiClasses = API.Classes

				for i = 1, #sList do
					local node = sList[i]
					local class = node.Class
					local obj = node.Obj

					if not presentClasses.isViableDecompileScript then
						presentClasses.isViableDecompileScript = env.isViableDecompileScript(obj)
					end
					if not class then
						class = obj.ClassName
						node.Class = class
					end

					local curClass = apiClasses[class]
					while curClass and not presentClasses[curClass.Name] do
						presentClasses[curClass.Name] = true
						curClass = curClass.Superclass
					end
				end

				context:AddRegistered("CUT")
				context:AddRegistered("COPY")
				context:AddRegistered("PASTE", emptyClipboard)
				context:AddRegistered("DUPLICATE")
				context:AddRegistered("DELETE")
				context:AddRegistered("DELETE_CHILDREN", #sList ~= 1)
				context:AddRegistered("RENAME", #sList ~= 1)

				context:AddDivider()
				context:AddRegistered("GROUP")
				context:AddRegistered("UNGROUP")
				context:AddRegistered("SELECT_CHILDREN")
				context:AddRegistered("JUMP_TO_PARENT")
				context:AddRegistered("EXPAND_ALL")
				context:AddRegistered("COLLAPSE_ALL")

				context:AddDivider()

				if expanded == Explorer.SearchExpanded then context:AddRegistered("CLEAR_SEARCH_AND_JUMP_TO") end
		if env.setclipboard then context:AddRegistered("COPY_PATH") end
		context:AddRegistered("INSERT_OBJECT")
		context:AddRegistered("ADD_PROPERTY")
		context:AddRegistered("SAVE_INST")
		context:AddRegistered("COPY_API_PAGE")
		-- context:AddRegistered("CALL_FUNCTION")
                -- context:AddRegistered("VIEW_CONNECTIONS")
                -- context:AddRegistered("GET_REFERENCES")
                -- context:AddRegistered("VIEW_API")
		-- to be implemented soon
		
		if type(cache) == "table" then
			if cache.invalidate then context:AddRegistered("INVALIDATE_CACHE") end
		end

		context:QueueDivider()

		if presentClasses["BasePart"] or presentClasses["Model"] then
			context:AddRegistered("TELEPORT_TO")
			context:AddRegistered("VIEW_OBJECT")
			context:AddRegistered("3DVIEW_MODEL")
			
			local isHighlighted = false
			if sList[1] and sList[1].Obj then
				if sList[1].Obj:FindFirstChild("DexHighlight") then
					isHighlighted = true
				end
			end
			context.Registered["HIGHLIGHT_PART"].Name = isHighlighted and "Unhighlight Part" or "Highlight Part"
			context:AddRegistered("HIGHLIGHT_PART")
		end
				if presentClasses["Tween"] then context:AddRegistered("PLAY_TWEEN") end
				if presentClasses["Animation"] then
					context:AddRegistered("LOAD_ANIMATION")
				
					context:AddRegistered("STOP_ANIMATION")
				end

				if presentClasses["TouchTransmitter"] then context:AddRegistered("FIRE_TOUCHTRANSMITTER", firetouchinterest == nil) end
				if presentClasses["ClickDetector"] then context:AddRegistered("FIRE_CLICKDETECTOR", fireclickdetector == nil) end
				if presentClasses["ProximityPrompt"] then context:AddRegistered("FIRE_PROXIMITYPROMPT", fireproximityprompt == nil) end
				if presentClasses["RemoteEvent"] or presentClasses["UnreliableRemoteEvent"] or presentClasses["BindableEvent"] then 
					context:AddRegistered("BLOCK_REMOTE", env.hookmetamethod == nil)
					context:AddRegistered("UNBLOCK_REMOTE", env.hookmetamethod == nil) 
				end
				if presentClasses["RemoteFunction"] or presentClasses["BindableFunction"] then 
					context:AddRegistered("BLOCK_REMOTE", env.hookmetamethod == nil)
					context:AddRegistered("UNBLOCK_REMOTE", env.hookmetamethod == nil) 
				end

				if presentClasses["Player"] then context:AddRegistered("SELECT_CHARACTER")context:AddRegistered("VIEW_PLAYER") end
				if presentClasses["Players"] then
					context:AddRegistered("SELECT_LOCAL_PLAYER")
					context:AddRegistered("SELECT_ALL_CHARACTERS")
				end

				if presentClasses["LuaSourceContainer"] then
					
					context:AddRegistered("VIEW_SCRIPT", not presentClasses.isViableDecompileScript or env.decompile == nil)
					context:AddRegistered("VIEW_ENV")
					context:AddRegistered("DUMP_FUNCTIONS", not presentClasses.isViableDecompileScript or env.getupvalues == nil or env.getconstants == nil)
					context:AddRegistered("SAVE_SCRIPT", not presentClasses.isViableDecompileScript or env.decompile == nil or env.writefile == nil)
					context:AddRegistered("SAVE_BYTECODE", not presentClasses.isViableDecompileScript or env.getscriptbytecode == nil or env.writefile == nil)
				end

				if sMap[nilNode] then
					context:AddRegistered("REFRESH_NIL")
					context:AddRegistered("HIDE_NIL")
				end

				Explorer.LastRightClickX, Explorer.LastRightClickY = Mouse.X, Mouse.Y
				context:Show(Mouse.X, Mouse.Y)
			end

			Explorer.InitRightClick = function()
				local context = Lib.ContextMenu.new()

				context:Register("CUT",{Name = "Cut", IconMap = Explorer.MiscIcons, Icon = "Cut", DisabledIcon = "Cut_Disabled", Shortcut = "Ctrl+Z", OnClick = function()
					local destroy,clone = game.Destroy,game.Clone
					local sList,newClipboard = selection.List,{}
					local count = 1
					for i = 1,#sList do
						local inst = sList[i].Obj
						local s,cloned = pcall(clone,inst)
						if s and cloned then
							newClipboard[count] = cloned
							count = count + 1
						end
						pcall(destroy,inst)
					end
					clipboard = newClipboard
					selection:Clear()
				end})

				context:Register("COPY",{Name = "Copy", IconMap = Explorer.MiscIcons, Icon = "Copy", DisabledIcon = "Copy_Disabled", Shortcut = "Ctrl+C", OnClick = function()
					local clone = game.Clone
					local sList,newClipboard = selection.List,{}
					local count = 1
					for i = 1,#sList do
						local inst = sList[i].Obj
						local s,cloned = pcall(clone,inst)
						if s and cloned then
							newClipboard[count] = cloned
							count = count + 1
						end
					end
					clipboard = newClipboard
				end})

				context:Register("PASTE",{Name = "Paste Into", IconMap = Explorer.MiscIcons, Icon = "Paste", DisabledIcon = "Paste_Disabled", Shortcut = "Ctrl+Shift+V", OnClick = function()
					local sList = selection.List
					local newSelection = {}
					local count = 1
					for i = 1,#sList do
						local node = sList[i]
						local inst = node.Obj
						Explorer.MakeNodeVisible(node,true)
						for c = 1,#clipboard do
							local cloned = clipboard[c]:Clone()
							if cloned then
								cloned.Parent = inst
								local clonedNode = nodes[cloned]
								if clonedNode then newSelection[count] = clonedNode count = count + 1 end
							end
						end
					end
					selection:SetTable(newSelection)

					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					end
				end})

				context:Register("DUPLICATE",{Name = "Duplicate", IconMap = Explorer.MiscIcons, Icon = "Copy", DisabledIcon = "Copy_Disabled", Shortcut = "Ctrl+D", OnClick = function()
					local clone = game.Clone
					local sList = selection.List
					local newSelection = {}
					local count = 1
					for i = 1,#sList do
						local node = sList[i]
						local inst = node.Obj
						local instPar = node.Parent and node.Parent.Obj
						Explorer.MakeNodeVisible(node)
						local s,cloned = pcall(clone,inst)
						if s and cloned then
							cloned.Parent = instPar
							local clonedNode = nodes[cloned]
							if clonedNode then newSelection[count] = clonedNode count = count + 1 end
						end
					end

					selection:SetTable(newSelection)
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					end
				end})

				context:Register("DELETE",{Name = "Delete", IconMap = Explorer.MiscIcons, Icon = "Delete", DisabledIcon = "Delete_Disabled", Shortcut = "Del", OnClick = function()
					local destroy = game.Destroy
					local sList = selection.List
					for i = 1,#sList do
						pcall(destroy,sList[i].Obj)
					end
					selection:Clear()
				end})

				context:Register("DELETE_CHILDREN",{Name = "Delete Children", IconMap = Explorer.MiscIcons, Icon = "Delete", DisabledIcon = "Delete_Disabled", Shortcut = "Shift+Del", OnClick = function()
			local sList = selection.List
			for i = 1,#sList do pcall(sList[i].Obj.ClearAllChildren,sList[i].Obj) end
			selection:Clear()
		end})

		context:Register("COPY_API_PAGE",{Name = "Copy Roblox API Page URL", IconMap = Explorer.MiscIcons, Icon = "Reference", OnClick = function()
			local sList = selection.List
			if #sList == 1 then env.setclipboard("https://create.roblox.com/docs/reference/engine/classes/"..sList[1].Obj.ClassName) end
		end})
		
		context:Register("DUMP_FUNCTIONS",{Name = "Dump Functions", IconMap = Explorer.MiscIcons, Icon = "SelectChildren", DisabledIcon = "Empty", OnClick = function()
			local scr = selection.List[1] and selection.List[1].Obj
			if scr then ScriptViewer.DumpFunctions(scr) end
		end})

				context:Register("RENAME",{Name = "Rename", IconMap = Explorer.MiscIcons, Icon = "Rename", DisabledIcon = "Rename_Disabled", Shortcut = "F2", OnClick = function()
					local sList = selection.List
					if sList[1] then
						Explorer.SetRenamingNode(sList[1])
					end
				end})

				context:Register("GROUP",{Name = "Group", IconMap = Explorer.MiscIcons, Icon = "Group", DisabledIcon = "Group_Disabled", Shortcut = "Ctrl+G", OnClick = function()
					local sList = selection.List
					if #sList == 0 then return end

					local model = Instance.new("Model",sList[#sList].Obj.Parent)
					for i = 1,#sList do
						pcall(function() sList[i].Obj.Parent = model end)
					end

					if nodes[model] then
						selection:Set(nodes[model])
						Explorer.ViewNode(nodes[model])
					end
				end})

				context:Register("UNGROUP",{Name = "Ungroup", IconMap = Explorer.MiscIcons, Icon = "Ungroup", DisabledIcon = "Ungroup_Disabled", Shortcut = "Ctrl+U", OnClick = function()
					local newSelection = {}
					local count = 1
					local isa = game.IsA

					local function ungroup(node)
						local par = node.Parent.Obj
						local ch = {}
						local chCount = 1

						for i = 1,#node do
							local n = node[i]
							newSelection[count] = n
							ch[chCount] = n
							count = count + 1
							chCount = chCount + 1
						end

						for i = 1,#ch do
							pcall(function() ch[i].Obj.Parent = par end)
						end

						node.Obj:Destroy()
					end

					for i,v in next,selection.List do
						if isa(v.Obj,"Model") then
							ungroup(v)
						end
					end

					selection:SetTable(newSelection)
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					end
				end})

				context:Register("SELECT_CHILDREN",{Name = "Select Children", IconMap = Explorer.MiscIcons, Icon = "SelectChildren", DisabledIcon = "SelectChildren_Disabled", OnClick = function()
					local newSelection = {}
					local count = 1
					local sList = selection.List

					for i = 1,#sList do
						local node = sList[i]
						for ind = 1,#node do
							local cNode = node[ind]
							if ind == 1 then Explorer.MakeNodeVisible(cNode) end

							newSelection[count] = cNode
							count = count + 1
						end
					end

					selection:SetTable(newSelection)
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					else
						Explorer.Refresh()
					end
				end})

				context:Register("JUMP_TO_PARENT",{Name = "Jump to Parent", IconMap = Explorer.MiscIcons, Icon = "JumpToParent", OnClick = function()
					local newSelection = {}
					local count = 1
					local sList = selection.List

					for i = 1,#sList do
						local node = sList[i]
						if node.Parent then
							newSelection[count] = node.Parent
							count = count + 1
						end
					end

					selection:SetTable(newSelection)
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					else
						Explorer.Refresh()
					end
				end})

				context:Register("TELEPORT_TO",{Name = "Teleport To", IconMap = Explorer.MiscIcons, Icon = "TeleportTo", OnClick = function()
					local sList = selection.List
					local plrRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

					if not plrRP then return end

					for _,node in next, sList do
						local Obj = node.Obj

						if Obj:IsA("BasePart") then
							if Obj.CanCollide then
								plr.Character:MoveTo(Obj.Position)
							else
								plrRP.CFrame = CFrame.new(Obj.Position + Settings.Explorer.TeleportToOffset)
							end
							break
						elseif Obj:IsA("Model") then
							if Obj.PrimaryPart then
								if Obj.PrimaryPart.CanCollide then
									plr.Character:MoveTo(Obj.PrimaryPart.Position)
								else
									plrRP.CFrame = CFrame.new(Obj.PrimaryPart.Position + Settings.Explorer.TeleportToOffset)
								end
								break
							else
								local part = Obj:FindFirstChildWhichIsA("BasePart", true)
								if part and nodes[part] then
									if part.CanCollide then
										plr.Character:MoveTo(part.Position)
									else
										plrRP.CFrame = CFrame.new(part.Position + Settings.Explorer.TeleportToOffset)
									end
									break
								elseif Obj.WorldPivot then
									plrRP.CFrame = Obj.WorldPivot
								end
							end
						end
					end
				end})

				local OldAnimation
				context:Register("PLAY_TWEEN",{Name = "Play Tween", IconMap = Explorer.MiscIcons, Icon = "Play", OnClick = function()
					local sList = selection.List

					for i = 1, #sList do
						local node = sList[i]
						local Obj = node.Obj

						if Obj:IsA("Tween") then Obj:Play() end
					end
				end})

				local OldAnimation
				context:Register("LOAD_ANIMATION",{Name = "Load Animation", IconMap = Explorer.MiscIcons, Icon = "Play", OnClick = function()
					local sList = selection.List

					local Humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
					if not Humanoid then return end

					for i = 1, #sList do
						local node = sList[i]
						local Obj = node.Obj

						if Obj:IsA("Animation") then
							if OldAnimation then OldAnimation:Stop() end
							OldAnimation = Humanoid:LoadAnimation(Obj)
							OldAnimation:Play()
							break
						end
					end
				end})

				context:Register("STOP_ANIMATION",{Name = "Stop Animation", IconMap = Explorer.MiscIcons, Icon = "Pause", OnClick = function()
					local sList = selection.List

					local Humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
					if not Humanoid then return end

					for i = 1, #sList do
						local node = sList[i]
						local Obj = node.Obj

						if Obj:IsA("Animation") then
							if OldAnimation then OldAnimation:Stop() end
							Humanoid:LoadAnimation(Obj):Stop()
							break
						end
					end
				end})

				context:Register("EXPAND_ALL",{Name = "Expand All", OnClick = function()
					local sList = selection.List

					local function expand(node)
						expanded[node] = true
						for i = 1,#node do
							if #node[i] > 0 then
								expand(node[i])
							end
						end
					end

					for i = 1,#sList do
						expand(sList[i])
					end

					Explorer.ForceUpdate()
				end})

				context:Register("COLLAPSE_ALL",{Name = "Collapse All", OnClick = function()
					local sList = selection.List

					local function expand(node)
						expanded[node] = nil
						for i = 1,#node do
							if #node[i] > 0 then
								expand(node[i])
							end
						end
					end

					for i = 1,#sList do
						expand(sList[i])
					end

					Explorer.ForceUpdate()
				end})

				context:Register("CLEAR_SEARCH_AND_JUMP_TO",{Name = "Clear Search and Jump to", OnClick = function()
					local newSelection = {}
					local count = 1
					local sList = selection.List

					for i = 1,#sList do
						newSelection[count] = sList[i]
						count = count + 1
					end

					selection:SetTable(newSelection)
					Explorer.ClearSearch()
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					end
				end})

				-- this code is very bad but im lazy and it works so cope
				local clth = function(str)
					if str:sub(1, 28) == "game:GetService(\"Workspace\")" then str = str:gsub("game:GetService%(\"Workspace\"%)", "workspace", 1) end
					if str:sub(1, 27 + #plr.Name) == "game:GetService(\"Players\")." .. plr.Name then str = str:gsub("game:GetService%(\"Players\"%)." .. plr.Name, "game:GetService(\"Players\").LocalPlayer", 1) end
					return str
				end

				local copypathiconmapyay = {
			Display = function(self, obj, index)
				obj.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/icondraft.png")) and getcustomasset("DEX_REContinued/Images/icondraft.png") or "rbxassetid://483448923"
				obj.ImageRectSize = Vector2.new(16, 16)
				obj.ImageRectOffset = Vector2.new(145, 55)
			end
		}

				context:Register("COPY_PATH",{Name = "Copy Path", IconMap = copypathiconmapyay, Icon = 50, OnClick = function()
					local sList = selection.List
					if #sList == 1 then
						env.setclipboard(clth(Explorer.GetInstancePath(sList[1].Obj)))
					elseif #sList > 1 then
						local resList = {"{"}
						local count = 2
						for i = 1,#sList do
							local path = "\t"..clth(Explorer.GetInstancePath(sList[i].Obj))..","
							if #path > 0 then
								resList[count] = path
								count = count+1
							end
						end
						resList[count] = "}"
						env.setclipboard(table.concat(resList,"\n"))
					end
				end})

				context:Register("INSERT_OBJECT",{Name = "Insert Object", IconMap = Explorer.MiscIcons, Icon = "InsertObject", OnClick = function()
					local mouse = Main.Mouse
					local x,y = Explorer.LastRightClickX or mouse.X, Explorer.LastRightClickY or mouse.Y
					Explorer.InsertObjectContext:Show(x,y)
				end})

				--[[context:Register("CALL_FUNCTION",{Name = "Call Function", IconMap = Explorer.ClassIcons, Icon = 66, OnClick = function()

				end})

				context:Register("GET_REFERENCES",{Name = "Get Lua References", IconMap = Explorer.ClassIcons, Icon = 34, OnClick = function()

				end})]]

				context:Register("SAVE_INST",{Name = "Save to File", IconMap = Explorer.MiscIcons, Icon = "Save", OnClick = function()
					local sList = selection.List
					if #sList == 0 then return end
					
					local objectsToSave = {}
					for i=1, #sList do
						table.insert(objectsToSave, sList[i].Obj)
					end
					
					local defaultName = "Place_"..game.PlaceId.."_"..sList[1].Obj.ClassName.."_"..sList[1].Obj.Name.."_"..os.time()
					if #sList > 1 then defaultName = "Place_"..game.PlaceId.."_MultipleObjects_"..os.time() end
					
					Lib.SaveAsPrompt(defaultName, function(filename)
						if env.saveinstance then
							env.saveinstance(objectsToSave, env.parsefile(filename), {
								Decompile = true,
								Mode = "scripts",
								ShowStatus = true
							})
						else
							warn("saveinstance not supported.")
						end
					end)
				end})
--[[
                context:Register("VIEW_CONNECTIONS",{Name = "View Connections", OnClick = function()
                    
                end})

				context:Register("VIEW_API",{Name = "View API Page", IconMap = Explorer.MiscIcons, Icon = "Reference", OnClick = function()

				end})]]

		context:Register("3DVIEW_MODEL",{Name = "3D Preview Object", IconMap = Explorer.LegacyClassIcons, Icon = 54, OnClick = function()
			local sList = selection.List
			local isa = game.IsA
			if #sList == 1 then
				if isa(sList[1].Obj,"BasePart") or isa(sList[1].Obj,"Model") then
					ModelViewer.ViewModel(sList[1].Obj)
					return
				end
			end
		end})

		context:Register("INVALIDATE_CACHE",{Name = "Invalidate From Cache", IconMap = Explorer.MiscIcons, Icon = "Delete", OnClick = function()
			local sList = selection.List
			for i = 1, #sList do
				if type(cache) == "table" and cache.invalidate then
					pcall(cache.invalidate, sList[i].Obj)
				end
			end
		end})

		context:Register("HIGHLIGHT_PART",{Name = "Highlight", IconMap = Explorer.MiscIcons, Icon = "Play", OnClick = function()
			local sList = selection.List
			for i = 1, #sList do
				local obj = sList[i].Obj
				if obj:IsA("BasePart") or obj:IsA("Model") then
					local existing = obj:FindFirstChild("DexHighlight")
					if existing then
						existing:Destroy()
					else
						local hl = Instance.new("Highlight")
						hl.Name = "DexHighlight"
						hl.FillColor = Color3.new(1, 1, 1)
						hl.OutlineColor = Color3.new(1, 1, 1)
						hl.Parent = obj
					end
				end
			end
		end})

			context:Register("ADD_PROPERTY",{Name = "Add Property", IconMap = Explorer.MiscIcons, Icon = "InsertObject", OnClick = function()
			local sList = selection.List
			if #sList == 0 then return end
			
			local PromptWin = Lib.Window.new()
			PromptWin.Alignable = false
			PromptWin.Resizable = false
			PromptWin:SetTitle("Add Property")
			PromptWin:SetSize(300, 130)
			
			local Lbl = Lib.Label.new()
			Lbl.Text = "Property Name:"
			Lbl.Position = UDim2.new(0, 10, 0, 10)
			Lbl.Size = UDim2.new(0, 100, 0, 20)
			PromptWin:Add(Lbl)
			
			local Box = Lib.ViewportTextBox.new()
			Box.Position = UDim2.new(0, 110, 0, 10)
			Box.Size = UDim2.new(0, 175, 0, 20)
			PromptWin:Add(Box, "InputBox")
			
			local TypeLbl = Lib.Label.new()
			TypeLbl.Text = "Type:"
			TypeLbl.Position = UDim2.new(0, 10, 0, 40)
			TypeLbl.Size = UDim2.new(0, 100, 0, 20)
			PromptWin:Add(TypeLbl)
			
			local TypeDropdown = Lib.DropDown.new()
			TypeDropdown.CanBeEmpty = false
			TypeDropdown.Size = UDim2.new(0, 175, 0, 20)
			TypeDropdown.Position = UDim2.new(0, 110, 0, 40)
			
			-- Shifted string to index 1 so it defaults safely
			local typeOptions = {
				"string", "boolean", "number", "Axes", "BrickColor", "CFrame", "Color3", 
				"ColorSequence", "ColorSequenceKeypoint", "EnumItem", "Instance", 
				"NumberRange", "NumberSequence", "NumberSequenceKeypoint", "PathWaypoint", 
				"PhysicalProperties", "Random", "Ray", "Rect", "Region3", "Region3int16", 
				"TweenInfo", "UDim", "UDim2", "Vector2", "Vector2int16", "Vector3", "Vector3int16"
			}
			TypeDropdown:SetOptions(typeOptions)
			TypeDropdown:SetSelected("string")
			PromptWin:Add(TypeDropdown, "TypeDropdown")
			
			local DefaultValues = {
				["boolean"] = false, ["number"] = 0, ["string"] = "Value",
				["Axes"] = Axes.new(), ["BrickColor"] = BrickColor.new("Medium stone grey"),
				["CFrame"] = CFrame.new(), ["Color3"] = Color3.new(),
				["ColorSequence"] = ColorSequence.new(Color3.new()),
				["ColorSequenceKeypoint"] = ColorSequenceKeypoint.new(0, Color3.new()),
				["EnumItem"] = Enum.Material.Plastic, ["Instance"] = game,
				["NumberRange"] = NumberRange.new(0), ["NumberSequence"] = NumberSequence.new(0),
				["NumberSequenceKeypoint"] = NumberSequenceKeypoint.new(0, 0),
				["PathWaypoint"] = PathWaypoint.new(Vector3.new(), Enum.PathWaypointAction.Walk),
				["PhysicalProperties"] = PhysicalProperties.new(0.5, 0.3, 0.5),
				["Random"] = Random.new(), ["Ray"] = Ray.new(Vector3.new(), Vector3.new()),
				["Rect"] = Rect.new(), ["Region3"] = Region3.new(Vector3.new(), Vector3.new()),
				["Region3int16"] = Region3int16.new(Vector3int16.new(), Vector3int16.new()),
				["TweenInfo"] = TweenInfo.new(), ["UDim"] = UDim.new(), ["UDim2"] = UDim2.new(),
				["Vector2"] = Vector2.new(), ["Vector2int16"] = Vector2int16.new(),
				["Vector3"] = Vector3.new(), ["Vector3int16"] = Vector3int16.new()
			}
			
			local Btn = Lib.Button.new()
			Btn.Text = "Add"
			Btn.Position = UDim2.new(0, 5, 1, -25)
			Btn.Size = UDim2.new(1, -10, 0, 20)
			Btn.OnClick:Connect(function()
				local propName = Box:GetText()
				local propType = TypeDropdown.Selected or "string"
				if propName and propName ~= "" then
					local defaultVal = DefaultValues[propType]
					if defaultVal == nil and propType == "string" then defaultVal = "Value" end
					if not Properties.CustomPropsHooked then
						Properties.CustomPropsHooked = true
						local newccl = env.newcclosure or newcclosure or function(f) return f end
						
						local function HandleIndex(self, key, oldIdx)
							if typeof(self) == "Instance" and type(key) == "string" then
								for tObj, state in pairs(Properties.CustomPropertyStates) do
									if tObj == self and Properties.CustomAddedProps[tObj] and Properties.CustomAddedProps[tObj][key] then
										return state[key]
									end
								end
							end
							return oldIdx(self, key)
						end
						
						local function HandleNewIndex(self, key, val, oldNewIdx)
							if typeof(self) == "Instance" and type(key) == "string" then
								for tObj, state in pairs(Properties.CustomPropertyStates) do
									if tObj == self and Properties.CustomAddedProps[tObj] and Properties.CustomAddedProps[tObj][key] then
										state[key] = val
										return
									end
								end
							end
							return oldNewIdx(self, key, val)
						end
						
						if env.hookmetamethod then
							local old; old = env.hookfunction(getrawmetatable(game).__index, newccl(function(self, key)
								return HandleIndex(self, key, old)
							end))
							
							local oldn; oldn = env.hookfunction(getrawmetatable(game).__newindex, newccl(function(self, key, val)
								return HandleNewIndex(self, key, val, oldn)
							end))
							end
					end

					for i = 1, #sList do
						local targetObj = sList[i].Obj
						
						local foundObj = targetObj
						for tObj, _ in pairs(Properties.CustomAddedProps) do
							if tObj == targetObj then
								foundObj = tObj
								break
							end
						end
						
						if not Properties.CustomAddedProps[foundObj] then Properties.CustomAddedProps[foundObj] = {} end
						Properties.CustomAddedProps[foundObj][propName] = propType
						
						if not Properties.CustomPropertyStates[foundObj] then Properties.CustomPropertyStates[foundObj] = {} end
						Properties.CustomPropertyStates[foundObj][propName] = defaultVal
					end
				end
				PromptWin:Close()
				Properties.ShowExplorerProps()
			end)
			PromptWin:Add(Btn)
			PromptWin:Show()
		end})

				context:Register("VIEW_OBJECT",{Name = "View Object (Right click to reset)", IconMap = Explorer.LegacyClassIcons, Icon = 5, OnClick = function()
			local sList = selection.List
			local isa = game.IsA
			for i = 1,#sList do
				local node = sList[i]
				if isa(node.Obj,"BasePart") or isa(node.Obj,"Model") then
					workspace.CurrentCamera.CameraSubject = node.Obj
					break
				end
			end
		end, OnRightClick = function()
			workspace.CurrentCamera.CameraSubject = plr.Character
		end})

				context:Register("FIRE_TOUCHTRANSMITTER",{Name = "Fire TouchTransmitter", IconMap = Explorer.ClassIcons, Icon = 37, OnClick = function()
					local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if not hrp then return end
					for _, v in next, selection.List do if v.Obj and v.Obj:IsA("TouchTransmitter") then firetouchinterest(hrp, v.Obj.Parent, 0) end end
				end})

				context:Register("FIRE_CLICKDETECTOR",{Name = "Fire ClickDetector", IconMap = Explorer.ClassIcons, Icon = 41, OnClick = function()
					local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if not hrp then return end
					for _, v in next, selection.List do if v.Obj and v.Obj:IsA("ClickDetector") then fireclickdetector(v.Obj) end end
				end})

				context:Register("FIRE_PROXIMITYPROMPT",{Name = "Fire ProximityPrompt", IconMap = Explorer.ClassIcons, Icon = 124, OnClick = function()
					local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
					if not hrp then return end
					for _, v in next, selection.List do if v.Obj and v.Obj:IsA("ProximityPrompt") then fireproximityprompt(v.Obj) end end
				end})

				context:Register("VIEW_SCRIPT",{Name = "View Script", IconMap = Explorer.MiscIcons, Icon = "ViewScript", OnClick = function()
					local scr = selection.List[1] and selection.List[1].Obj
					if scr then ScriptViewer.ViewScript(scr) end
				end})

				context:Register("VIEW_ENV", {Name = "View Environment", IconMap = Explorer.MiscIcons, Icon = "ExploreData", DisabledIcon = "Empty", OnClick = function()
				local scr = selection.List[1] and selection.List[1].Obj
				if scr then EnvExplorer.ViewEnvironment(scr) end
				end})

				context:Register("SAVE_SCRIPT",{Name = "Save Script", IconMap = Explorer.MiscIcons, Icon = "Save", DisabledIcon = "Empty", OnClick = function()
			for _, v in next, selection.List do
				if v.Obj:IsA("LuaSourceContainer") and env.isViableDecompileScript(v.Obj) then
					local success, source = pcall(env.decompile, v.Obj)
					if not success or not source then source = ("-- DEX - %s failed to decompile %s"):format(env.executor, v.Obj.ClassName) end
					local fileName = ("%s_%s_%i_Source.txt"):format(env.parsefile(v.Obj.Name), v.Obj.ClassName, game.PlaceId)
					Lib.SaveAsPrompt(fileName, source)
					task.wait(0.2)
				end
			end
		end})

		context:Register("SAVE_BYTECODE",{Name = "Save Script Bytecode", IconMap = Explorer.MiscIcons, Icon = "Save", DisabledIcon = "Empty", OnClick = function()
			for _, v in next, selection.List do
				if v.Obj:IsA("LuaSourceContainer") and env.isViableDecompileScript(v.Obj) then
					local success, bytecode = pcall(env.getscriptbytecode, v.Obj)
					if success and type(bytecode) == "string" then
						local fileName = ("%s_%s_%i_Bytecode.txt"):format(env.parsefile(v.Obj.Name), v.Obj.ClassName, game.PlaceId)
						Lib.SaveAsPrompt(fileName, bytecode)
						task.wait(0.2)
					end
				end
			end
		end})

				context:Register("SELECT_CHARACTER",{Name = "Select Character", IconMap = Explorer.LegacyClassIcons, Icon = 9, OnClick = function()
					local newSelection = {}
					local count = 1
					local sList = selection.List
					local isa = game.IsA

					for i = 1,#sList do
						local node = sList[i]
						if isa(node.Obj,"Player") and nodes[node.Obj.Character] then
							newSelection[count] = nodes[node.Obj.Character]
							count = count + 1
						end
					end

					selection:SetTable(newSelection)
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					else
						Explorer.Refresh()
					end
				end})

				context:Register("VIEW_PLAYER",{Name = "View Player", IconMap = Explorer.LegacyClassIcons, Icon = 5, OnClick = function()
					local newSelection = {}
					local count = 1
					local sList = selection.List
					local isa = game.IsA

					for i = 1,#sList do
						local node = sList[i]
						local Obj = node.Obj
						if Obj:IsA("Player") and Obj.Character then
							workspace.CurrentCamera.CameraSubject = Obj.Character
							break
						end
					end
				end})

				context:Register("SELECT_LOCAL_PLAYER",{Name = "Select Local Player", IconMap = Explorer.LegacyClassIcons, Icon = 9, OnClick = function()
					pcall(function() if nodes[plr] then selection:Set(nodes[plr]) Explorer.ViewNode(nodes[plr]) end end)
				end})

				context:Register("SELECT_ALL_CHARACTERS",{Name = "Select All Characters", IconMap = Explorer.LegacyClassIcons, Icon = 2, OnClick = function()
					local newSelection = {}
					local sList = selection.List

					for i,v in next, service.Players:GetPlayers() do
						if v.Character and nodes[v.Character] then
							if i == 1 then Explorer.MakeNodeVisible(v.Character) end
							table.insert(newSelection, nodes[v.Character])
						end
					end

					selection:SetTable(newSelection)
					if #newSelection > 0 then
						Explorer.ViewNode(newSelection[1])
					else
						Explorer.Refresh()
					end
				end})

				context:Register("REFRESH_NIL",{Name = "Refresh Nil Instances", OnClick = function()
					Explorer.RefreshNilInstances()
				end})

				context:Register("HIDE_NIL",{Name = "Hide Nil Instances", OnClick = function()
					Explorer.HideNilInstances()
				end})

				local ClassFire = {
					RemoteEvent = "FireServer",
					RemoteFunction = "InvokeServer",
					UnreliableRemoteEvent = "FireServer",
					BindableEvent = "Fire",
					BindableFunction = "Invoke",
				}


				-- TODO: block the .Func itself
				context:Register("BLOCK_REMOTE",{Name = "Block From Firing", IconMap = Explorer.MiscIcons, Icon = "Delete", DisabledIcon = "Empty", OnClick = function()
					local sList = selection.List
					for i, list in pairs(sList) do
						local obj = list.Obj
						if not remote_blocklist[obj] then
							local functionToHook = ClassFire[obj.ClassName]
							remote_blocklist[obj] = true
							local old; old = env.hookfunction(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
								if remote_blocklist[obj] and self == obj and getnamecallmethod() == functionToHook then
									return nil
								end
								return old(self, ...)
							end))
						end
					end
				end})
				
				context:Register("UNBLOCK_REMOTE",{Name = "Unblock", IconMap = Explorer.MiscIcons, Icon = "Play", DisabledIcon = "Empty", OnClick = function()
					local sList = selection.List
					for i, list in pairs(sList) do
						local obj = list.Obj
						if remote_blocklist[obj] then
							remote_blocklist[obj] = nil
						end
					end
				end})

				Explorer.RightClickContext = context
			end

			Explorer.HideNilInstances = function()
				table.clear(nilMap)

				local disconnectCon = Instance.new("Folder").ChildAdded:Connect(function() end).Disconnect
				for i,v in next,nilCons do
					disconnectCon(v[1])
					disconnectCon(v[2])
				end
				table.clear(nilCons)

				for i = 1,#nilNode do
					coroutine.wrap(removeObject)(nilNode[i].Obj)
				end

				Explorer.Update()
				Explorer.Refresh()
			end

			Explorer.RefreshNilInstances = function()
				if not env.getnilinstances then return end

				local nilInsts = env.getnilinstances()
				local game = game

				for i = 1,#nilInsts do
					local obj = nilInsts[i]
					if obj ~= game then
						local refObj = cloneref(obj)
						nilMap[refObj] = true
						local descs = getDescendants(refObj)
						for j = 1,#descs do
							nilMap[descs[j]] = true
						end
					end
				end

				for i = 1,#nilInsts do
					local obj = cloneref(nilInsts[i])
					local node = nodes[obj]
					if not node then coroutine.wrap(addObject)(obj) end
				end

				Explorer.Update()
				Explorer.Refresh()
			end

			Explorer.GetInstancePath = function(obj)
				local ffc = game.FindFirstChild
				local ggc = game.GetChildren
				local getCh = function(obj)
    				local ok, raw = pcall(ggc, obj)
    				raw = if not ok or type(raw) ~= "table" then setmetatable({}, {__mode = "v"}) else setmetatable(raw, {__mode = "v"})
   				local out = {}
   				for i = 1, #raw do
        			out[i] = cloneref(raw[i])
    				end
    				return out
				end
				local path = ""
				local curObj = obj
				local ts = tostring
				local match = string.match
				local gsub = string.gsub
				local tableFind = table.find
				local useGetCh = Settings.Explorer.CopyPathUseGetChildren
				local formatLuaString = Lib.FormatLuaString

				while curObj do
			if (compareinstances and compareinstances(curObj, game)) or (typeof(curObj) == "Instance" and curObj.ClassName == "DataModel") then
				path = "game"..path
				break
			end

			local className = curObj.ClassName
			local curName = ts(curObj)
			local indexName
			if match(curName,"^[%a_][%w_]*$") then
				indexName = "."..curName
			else
				local cleanName = formatLuaString(curName)
				indexName = '["'..cleanName..'"]'
			end

			local parObj = curObj.Parent
			parObj = parObj and cloneref(parObj) or nil

			if parObj then
				local fc = ffc(parObj,curName)
				if useGetCh and fc and fc ~= curObj then
					local parCh = getCh(parObj)
					local fcInd = tableFind(parCh,curObj)
					indexName = ":GetChildren()["..fcInd.."]"
				elseif (parObj == game or parObj == oldgame or parObj.ClassName == "DataModel") and API.Classes[className] and API.Classes[className].Tags.Service then
					indexName = ':GetService("'..className..'")'
				end
			elseif parObj == nil then
				local getnil = "local getNil = function(name, class) for _, v in next, getnilinstances() do if v.ClassName == class and v.Name == name then return v end end end"
				local gotnil = "\n\ngetNil(\"%s\", \"%s\")"
				indexName = getnil .. gotnil:format(curObj.Name, className)
			end

			path = indexName..path
			curObj = parObj
		end

		return path
	end

			Explorer.DefaultProps = {
				["BasePart"] = {
					Position = function(Obj)
						local Player = service.Players.LocalPlayer
						if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
							Obj.Position = (Player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)).p
						end
						return Obj.Position
					end,
					Anchored = true
				},
				["GuiObject"] = {
					Position = function(Obj) return (Obj.Parent:IsA("ScreenGui") and UDim2.new(0.5, 0, 0.5, 0)) or Obj.Position end,
					Active = true
				}
			}

			Explorer.InitInsertObject = function()
				local context = Lib.ContextMenu.new()
				context.SearchEnabled = true
				context.MaxHeight = 400
				context:ApplyTheme({
					ContentColor = Settings.Theme.Main2,
					OutlineColor = Settings.Theme.Outline1,
					DividerColor = Settings.Theme.Outline1,
					TextColor = Settings.Theme.Text,
					HighlightColor = Settings.Theme.ButtonHover
				})

				local classes = {}
				for i,class in next,API.Classes do
					local tags = class.Tags
					if not tags.NotCreatable and not tags.Service then
						local rmdEntry = RMD.Classes[class.Name]
						classes[#classes+1] = {class,rmdEntry and rmdEntry.ClassCategory or "Uncategorized"}
					end
				end
				table.sort(classes,function(a,b)
					if a[2] ~= b[2] then
						return a[2] < b[2]
					else
						return a[1].Name < b[1].Name
					end
				end)

				local function defaultProps(obj)
					for class, props in pairs(Explorer.DefaultProps) do
						if obj:IsA(class) then
							for prop, value in pairs(props) do
								obj[prop] = (type(value) == "function" and value(obj)) or value
							end
						end
					end
				end

				local function onClick(className)
					local sList = selection.List
					local instNew = Instance.new
					for i = 1,#sList do
						local node = sList[i]
						local obj = node.Obj
						Explorer.MakeNodeVisible(node, true)
						local success, obj = pcall(instNew, className, obj)
						if success and obj then defaultProps(obj) end
					end
				end

				local lastCategory = ""
				for i = 1,#classes do
					local class = classes[i][1]
					local rmdEntry = RMD.Classes[class.Name]
					local iconInd = rmdEntry and tonumber(rmdEntry.ExplorerImageIndex) or 0
					local category = classes[i][2]

					if lastCategory ~= category then
						context:AddDivider(category)
						lastCategory = category
					end
					
					local icon
					if iconData then
						icon = iconData.Icons[class.Name] or iconData.Icons.Placeholder
					else
						icon = iconInd
					end
					context:Add({Name = class.Name, IconMap = Explorer.ClassIcons, Icon = icon, OnClick = onClick})
				end

				Explorer.InsertObjectContext = context
			end

	Explorer.SearchFilters = {
		Comparison = {
			["isa"] = function(argString)
				local lower = string.lower
				local find = string.find
				local classQuery = string.split(argString)[1]
				if not classQuery then return end
				classQuery = lower(classQuery)

				local className
				for class,_ in pairs(API.Classes) do
					local cName = lower(class)
					if cName == classQuery then
						className = class
						break
					elseif find(cName,classQuery,1,true) then
						className = class
					end
				end
				if not className then return end

				return {
					Headers = {"local isa = game.IsA"},
					Predicate = "isa(obj,'"..className.."')"
				}
			end,
			["is"] = function(argString)
			    -- Alias for isa (matches "is:Part")
			    return Explorer.SearchFilters.Comparison["isa"](argString)
			end,
			["tag"] = function(argString)
			    return {
			        Headers = {"local CollectionService = game:GetService('CollectionService')"},
			        Predicate = "CollectionService:HasTag(obj, '" .. argString:gsub("'", "\\'") .. "')"
			    }
			end,
			["remotes"] = function(argString)
				return {
					Headers = {"local isa = game.IsA"},
					Predicate = "(isa(obj,'RemoteEvent') or isa(obj,'RemoteFunction') or isa(obj,'UnreliableRemoteEvent'))"
				}
			end,
			["bindables"] = function(argString)
				return {
					Headers = {"local isa = game.IsA"},
					Predicate = "(isa(obj,'BindableEvent') or isa(obj,'BindableFunction'))"
				}
			end,
			["rad"] = function(argString)
				local num = tonumber(argString)
				if not num then return end
				if not service.Players.LocalPlayer.Character or not service.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or not service.Players.LocalPlayer.Character.HumanoidRootPart:IsA("BasePart") then return end

				return {
					Headers = {"local isa = game.IsA", "local hrp = service.Players.LocalPlayer.Character.HumanoidRootPart"},
					Setups = {"local hrpPos = hrp.Position"},
					ObjectDefs = {"local isBasePart = isa(obj,'BasePart')"},
					Predicate = "(isBasePart and (obj.Position-hrpPos).Magnitude <= "..num..")"
				}
			end,
		},
		Specific = {
			["players"] = function()
				return function() return service.Players:GetPlayers() end
			end,
			["loadedmodules"] = function()
				return env.getloadedmodules
			end,
		},
		Default = function(argString,caseSensitive)
			local cleanString = argString:gsub("\"","\\\""):gsub("\n","\\n")
			if caseSensitive then
				return {
					Headers = {"local find = string.find"},
					ObjectDefs = {"local objName = tostring(obj)"},
					Predicate = "find(objName,\"" .. cleanString .. "\",1,true)"
				}
			else
				return {
					Headers = {"local lower = string.lower","local find = string.find","local tostring = tostring"},
					ObjectDefs = {"local lowerName = lower(tostring(obj))"},
					Predicate = "find(lowerName,\"" .. cleanString:lower() .. "\",1,true)"
				}
			end
		end,
		SpecificDefault = function(n)
			return {
				Headers = {},
				ObjectDefs = {"local isSpec"..n.." = specResults["..n.."][node]"},
				Predicate = "isSpec"..n
			}
		end,
	}

	Explorer.BuildSearchFunc = function(query)
		local specFilterList,specMap = {},{}
		local finalPredicate = ""
		local rep = string.rep
		
		-- spaces to 'and'
		local formattedQuery = query:gsub("([^%s%|&%(%)])%s+([^%s%|&%(%)])", "%1 && %2")
		formattedQuery = formattedQuery:gsub("\\.","  "):gsub('".-"',function(str) return rep(" ",#str) end)
		
		local headers = {
		    [ [[
local function cmpProp(obj, propPath, op, valStr)
    local s, v = pcall(function()
        local c = obj
        for _, p in ipairs(string.split(propPath, ".")) do c = c[p] end
        return c
    end)
    if not s or v == nil then return false end
    
    local valNum = tonumber(valStr)
    local vType = typeof(v)
    
    if vType == "boolean" then
        local b = valStr:lower() == "true"
        if op == "==" then return v == b elseif op == "~=" then return v ~= b end
    elseif vType == "string" then
        if op == "==" then return string.lower(v) == string.lower(valStr)
        elseif op == "~=" then return string.lower(v) ~= string.lower(valStr) end
    elseif vType == "EnumItem" then
        if op == "==" then return string.lower(v.Name) == string.lower(valStr)
        elseif op == "~=" then return string.lower(v.Name) ~= string.lower(valStr) end
    end
    
    if valNum and type(v) == "number" then
        if op == "==" then return v == valNum elseif op == "~=" then return v ~= valNum
        elseif op == ">" then return v > valNum elseif op == "<" then return v < valNum
        elseif op == ">=" then return v >= valNum elseif op == "<=" then return v <= valNum end
    end
    
    local coords = {}
    for x in valStr:gmatch("[%d%.]+") do table.insert(coords, tonumber(x)) end
    if vType == "Vector3" and #coords >= 3 then
        local target = Vector3.new(coords[1], coords[2], coords[3])
        if op == "==" then return v == target
        elseif op == ">" then return v.X > target.X and v.Y > target.Y and v.Z > target.Z
        elseif op == "<" then return v.X < target.X and v.Y < target.Y and v.Z < target.Z end
    elseif vType == "Color3" and #coords >= 3 then
        local target = valStr:find("%.") and Color3.new(coords[1], coords[2], coords[3]) or Color3.fromRGB(coords[1], coords[2], coords[3])
        if op == "==" then return v == target end
    end
    return false
end

local function matchAncestry(obj, path)
    local parts = string.split(path, ".")
    local curr = obj
    for i = #parts, 1, -1 do
        local p = parts[i]
        if p == "**" then return true end
        if not curr then return false end
        if p ~= "*" and string.lower(curr.Name) ~= string.lower(p) then return false end
        curr = curr.Parent
    end
    return true
end
]] ] = true
		}
		local objectDefs = {}
		local setups = {}
		local find = string.find
		local sub = string.sub
		local lower = string.lower
		local match = string.match
		
		-- 'and' / 'or'
		local ops = { ["("] = "(", [")"] = ")", ["||"] = " or ",["&&"] = " and ",["or"] = " or ", ["and"] = " and " }
		local compFilters = Explorer.SearchFilters.Comparison
		local specFilters = Explorer.SearchFilters.Specific
		local init = 1
		local lastOp = nil

		local function processFilter(dat)
			if dat.Headers then for i = 1,#dat.Headers do headers[dat.Headers[i]] = true end end
			if dat.ObjectDefs then for i = 1,#dat.ObjectDefs do objectDefs[dat.ObjectDefs[i]] = true end end
			if dat.Setups then for i = 1,#dat.Setups do setups[dat.Setups[i]] = true end end
			finalPredicate = finalPredicate..dat.Predicate
		end

		local found = {}
		local foundData = {}

		local function findAll(str,pattern)
			local count = #found+1
			local init = 1
			local sz = #pattern
			local x,y,extra = find(str,pattern,init,true)
			while x do
				found[count] = x
				foundData[x] = {sz,pattern}
				count = count+1
				init = y+1
				x,y,extra = find(str,pattern,init,true)
			end
		end
		
		findAll(formattedQuery,'&&'); findAll(formattedQuery,"||"); 
		findAll(formattedQuery," and "); findAll(formattedQuery," or ");
		findAll(formattedQuery,"("); findAll(formattedQuery,")")
		table.sort(found)
		table.insert(found,#formattedQuery+1)

		local function inQuotes(str)
			local len = #str
			if sub(str,1,1) == '"' and sub(str,len,len) == '"' then return sub(str,2,len-1) end
		end

		for i = 1,#found do
			local nextInd = found[i]
			local nextData = foundData[nextInd] or {1}
			local op = ops[nextData[2]]

			local term = sub(query:gsub("([^%s%|&%(%)])%s+([^%s%|&%(%)])", "%1 && %2"),init,nextInd-1)
			term = match(term,"^%s*(.-)%s*$") or ""

			if #term > 0 then
				if sub(term,1,1) == "!" then
					term = sub(term,2)
					finalPredicate = finalPredicate.."not "
				end

				local qTerm = inQuotes(term)
				if qTerm then
					processFilter(Explorer.SearchFilters.Default(qTerm,true))
				else
				    local propName, propOp, propVal = match(term, "^([%w_%.]+)%s*([=!~<>]+)%s*(.*)$")
				    if propName and propOp and propVal and #propVal > 0 then
				        if propOp == "=" then propOp = "==" end
				        processFilter({
				            Predicate = string.format("cmpProp(obj, '%s', '%s', '%s')", propName, propOp, propVal:gsub("'", "\\'"):gsub('"', ""))
				        })
				    elseif term:find("%.") or term:find("%*") then
				        -- Ancestry
				        processFilter({
				            Predicate = string.format("matchAncestry(obj, '%s')", term:gsub("'", "\\'"))
				        })
				    else
    					local x,y = find(term,"%S+")
    					if x then
    						local first = sub(term,x,y)
    						local specifier = sub(first,1,1) == "/" and lower(sub(first,2)) 
    						    or sub(first, #first) == ":" and lower(sub(first, 1, #first-1))
    						
    						local compFunc = specifier and compFilters[specifier]
    						local specFunc = specifier and specFilters[specifier]
    
    						if compFunc then
    							local argStr = sub(term,y+1)
    							if sub(first, #first) == ":" then argStr = sub(term, y+1) else argStr = sub(term, y+2) end
    							local ret = compFunc(inQuotes(argStr) or argStr)
    							if ret then processFilter(ret) else finalPredicate = finalPredicate.."false" end
    						elseif specFunc then
    							local argStr = sub(term,y+1)
    							if sub(first, #first) == ":" then argStr = sub(term, y+1) else argStr = sub(term, y+2) end
    							local ret = specFunc(inQuotes(argStr) or argStr)
    							if ret then
    								if not specMap[term] then
    									specFilterList[#specFilterList + 1] = ret
    									specMap[term] = #specFilterList
    								end
    								processFilter(Explorer.SearchFilters.SpecificDefault(specMap[term]))
    							else
    								finalPredicate = finalPredicate.."false"
    							end
    						else
    							processFilter(Explorer.SearchFilters.Default(term))
    						end
    					end
    				end
				end				
			end

			if op then
				finalPredicate = finalPredicate..op
				if op == "(" and (#term > 0 or lastOp == ")") then return else lastOp = op end
			end
			init = nextInd+nextData[1]
		end

		local finalSetups, finalHeaders, finalObjectDefs = "", "", ""
		for header,_ in next,headers do 
		    if type(header) == "string" then finalHeaders = finalHeaders..header.."\n" end 
		end
		for setup,_ in next,setups do finalSetups = finalSetups..setup.."\n" end
		for oDef,_ in next,objectDefs do finalObjectDefs = finalObjectDefs..oDef.."\n" end

		local template = [[
local searchResults = searchResults
local nodes = nodes
local expandTable = Explorer.SearchExpanded
local specResults = specResults
local service = service
local typeof = typeof
local tonumber = tonumber

%s
local function search(root)	
%s
	
	local expandedpar = false
	for i = 1,#root do
		local node = root[i]
		local obj = node.Obj
		
%s
		
		if %s then
			expandTable[node] = 0
			searchResults[node] = true
			if not expandedpar then
				local parnode = node.Parent
				while parnode and (not searchResults[parnode] or expandTable[parnode] == 0) do
					expandTable[parnode] = true
					searchResults[parnode] = true
					parnode = parnode.Parent
				end
				expandedpar = true
			end
		end
		
		if #node > 0 then search(node) end
	end
end
return search]]

		local funcStr = template:format(finalHeaders,finalSetups,finalObjectDefs,finalPredicate)
		local s,func = pcall(loadstring,funcStr)
		if not s or not func then return nil,specFilterList end

		local env = setmetatable({["searchResults"] = searchResults, ["nodes"] = nodes, ["Explorer"] = Explorer, ["specResults"] = specResults,["service"] = service, ["typeof"] = typeof, ["tonumber"] = tonumber},{__index = getfenv()})
		setfenv(func,env)

		return func(),specFilterList
	end

	Explorer.DoSearch = function(query)
		table.clear(Explorer.SearchExpanded)
		table.clear(searchResults)
		expanded = (#query == 0 and Explorer.Expanded or Explorer.SearchExpanded)
		searchFunc = nil

		if #query > 0 then	
			local expandTable = Explorer.SearchExpanded
			local specFilters

			local lower = string.lower
			local find = string.find
			local tostring = tostring

			local lowerQuery = lower(query)

			local function defaultSearch(root)
				local expandedpar = false
				for i = 1,#root do
					local node = root[i]
					local obj = node.Obj

					if find(lower(tostring(obj)),lowerQuery,1,true) then
						expandTable[node] = 0
						searchResults[node] = true
						if not expandedpar then
							local parnode = node.Parent
							while parnode and (not searchResults[parnode] or expandTable[parnode] == 0) do
								expanded[parnode] = true
								searchResults[parnode] = true
								parnode = parnode.Parent
							end
							expandedpar = true
						end
					end

					if #node > 0 then defaultSearch(node) end
				end
			end

			if Main.Elevated then
				searchFunc,specFilters = Explorer.BuildSearchFunc(query)
			else
				searchFunc = defaultSearch
			end

			if specFilters then
				table.clear(specResults)
				for i = 1,#specFilters do
					local resMap = {}
					specResults[i] = resMap
					local objs = specFilters[i]()
					for c = 1,#objs do
						local node = nodes[objs[c]]
						if node then
							resMap[node] = true
						end
					end
				end
			end

			if searchFunc then
				searchFunc(nodes[game])
				searchFunc(nilNode)
			end
		end

		Explorer.ForceUpdate()
	end


			Explorer.ClearSearch = function()
				Explorer.GuiElems.SearchBar.Text = ""
				expanded = Explorer.Expanded
				searchFunc = nil
			end

			Explorer.InitSearch = function()
		local searchBox = Explorer.GuiElems.ToolBar.SearchFrame.SearchBox
		Explorer.GuiElems.SearchBar = searchBox

		Lib.ViewportTextBox.convert(searchBox)

		local ghostLabel = Instance.new("TextLabel")
		ghostLabel.Name = "GhostBox"
		ghostLabel.BackgroundTransparency = 1
		ghostLabel.Size = UDim2.new(1,0,1,0)
		ghostLabel.Position = searchBox.Position
		ghostLabel.Font = searchBox.Font
		ghostLabel.TextSize = searchBox.TextSize
		ghostLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
		ghostLabel.TextXAlignment = Enum.TextXAlignment.Left
		ghostLabel.Text = ""
		ghostLabel.Parent = searchBox.Parent

		searchBox:GetPropertyChangedSignal("Position"):Connect(function()
			ghostLabel.Position = searchBox.Position
		end)
		local dropdownFrame = Instance.new("ScrollingFrame")
		dropdownFrame.Name = "AutocompleteDropdown"
		dropdownFrame.Size = UDim2.new(1, -6, 0, 100)
		dropdownFrame.Position = UDim2.new(0, 3, 0, 22)
		dropdownFrame.BackgroundColor3 = Settings.Theme.Main2
		dropdownFrame.BorderColor3 = Settings.Theme.Outline1
		dropdownFrame.ZIndex = 50
		dropdownFrame.Visible = false
		dropdownFrame.ScrollBarThickness = 4
		dropdownFrame.Parent = Explorer.GuiElems.ToolBar

		local listLayout = Instance.new("UIListLayout", dropdownFrame)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
		end)

		local function clearDropdown()
			for _, child in pairs(dropdownFrame:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			dropdownFrame.Visible = false
		end

		local function addDropdownItem(text, fullReplaceText)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 20)
			btn.BackgroundColor3 = Settings.Theme.Main1
			btn.BorderSizePixel = 0
			btn.TextColor3 = Settings.Theme.Text
			btn.Text = "  " .. text
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Font = Enum.Font.SourceSans
			btn.TextSize = 14
			btn.ZIndex = 51
			
			btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Settings.Theme.Main1 end)
			
			btn.MouseButton1Click:Connect(function()
				searchBox.Text = fullReplaceText
				clearDropdown()
				task.defer(function()
					searchBox:CaptureFocus()
					searchBox.CursorPosition = #searchBox.Text + 1
				end)
			end)
			
			btn.Parent = dropdownFrame
			dropdownFrame.Visible = true
		end

		local function getExpectedValues(propName)
			local lowerProp = propName:lower()
			for _, classData in pairs(API.Classes) do
				for _, propData in pairs(classData.Properties) do
					if propData.Name:lower() == lowerProp then
						if propData.ValueType.Name == "bool" then
							return {"true", "false"}
						elseif propData.ValueType.Category == "Enum" then
							local enumData = API.Enums[propData.ValueType.Name]
							local results = {}
							if enumData then
								for _, item in pairs(enumData.Items) do
									table.insert(results, item.Name)
								end
								return results
							end
						elseif propData.ValueType.Name == "Color3" then
						    return {'"255, 255, 255"', '"0, 0, 0"', '"255, 0, 0"', '"0, 255, 0"', '"0, 0, 255"'}
						end
					end
				end
			end
			return nil
		end

		local function getPrediction(txt)
			if txt == "" then return "" end
			
			local tokens = txt:split(" ")
			local currentToken = tokens[#tokens]
			if not currentToken or currentToken == "" then return "" end
			
			local lowerTxt = currentToken:lower()
			local txtLen = #lowerTxt
			local baseTxt = txt:sub(1, #txt - #currentToken)

			local prop, op, val = currentToken:match("^([%w_%.]+)%s*([=!~<>]+)%s*(.*)$")
			if prop and op then
				local expected = getExpectedValues(prop)
				if expected then
					clearDropdown()
					local valLower = val:lower()
					for _, v in pairs(expected) do
						if v:lower():sub(1, #valLower) == valLower then
							addDropdownItem(v, baseTxt .. prop .. op .. v)
						end
					end
					return ""
				end
			else
				clearDropdown()
			end

			for filterName, _ in pairs(Explorer.SearchFilters.Comparison) do
				if filterName:sub(1, txtLen) == lowerTxt then
					return baseTxt .. currentToken .. filterName:sub(txtLen + 1) .. ":"
				end
			end

			local filterPrefix, rest = currentToken:match("^([%w_]+:)(.*)$")
			if filterPrefix and rest then
				local lowerRest = rest:lower()
				local restLen = #lowerRest
				if restLen > 0 then
					for className, _ in pairs(API.Classes) do
						if className:lower():sub(1, restLen) == lowerRest then
							return baseTxt .. filterPrefix .. rest .. className:sub(restLen + 1)
						end
					end
				end
				return ""
			end

			for obj, _ in pairs(nodes) do
				if typeof(obj) == "Instance" then
					local name = obj.Name
					if name:lower():sub(1, txtLen) == lowerTxt then
						return baseTxt .. currentToken .. name:sub(txtLen + 1)
					end
				end
			end

			return ""
		end

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if searchBox.Text == "" then
				ghostLabel.Text = ""
				clearDropdown()
			else
				ghostLabel.Text = getPrediction(searchBox.Text)
			end
		end)

		-- TAB
        service.UserInputService.InputBegan:Connect(function(input, gamep)
            if input.KeyCode == Enum.KeyCode.Tab then
                if ghostLabel.Text ~= "" and ghostLabel.Text ~= searchBox.Text then
                    searchBox.Text = ghostLabel.Text
                    
                    task.defer(function()
                        searchBox:CaptureFocus()
                        searchBox.CursorPosition = #searchBox.Text + 1
                    end)
                    return
                end
                end
            end)

		searchBox.FocusLost:Connect(function(enterPressed)
			task.delay(0.2, function() clearDropdown() end)
			Explorer.DoSearch(searchBox.Text)
		end)
	end

			Explorer.InitEntryTemplate = function()
				entryTemplate = create({
					{1,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderColor3=Color3.new(0,0,0),Font=3,Name="Entry",Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,250,0,20),Text="",TextSize=14,}},
					{2,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Name="Indent",Parent={1},Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-20,1,0),}},
					{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="EntryName",Parent={2},Position=UDim2.new(0,26,0,0),Size=UDim2.new(1,-26,1,0),Text="Workspace",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
					{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Font=3,Name="Expand",Parent={2},Position=UDim2.new(0,-20,0,0),Size=UDim2.new(0,20,0,20),Text="",TextSize=14,}},
					{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/Test_Icons.png")) and getcustomasset("DEX_REContinued/Images/Test_Icons.png") or "rbxassetid://5642383285",ImageRectOffset=Vector2.new(144,16),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={4},Position=UDim2.new(0,2,0,2),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
					{6,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ImageRectOffset=Vector2.new(304,0),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={2},Position=UDim2.new(0,4,0,2),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
				})
				

				local sys = Lib.ClickSystem.new()
				sys.AllowedButtons = {1,2}
				sys.OnDown:Connect(function(item,combo,button)
					local ind = table.find(listEntries,item)
					if not ind then return end
					local node = tree[ind + Explorer.Index]
					if not node then return end

					local entry = listEntries[ind]

					if button == 1 then
						if combo == 2 then
							if node.Obj:IsA("LuaSourceContainer") then
								ScriptViewer.ViewScript(node.Obj)
							elseif #node > 0 and expanded[node] ~= 0 then
								expanded[node] = not expanded[node]
								Explorer.Update()
							end
						end

						if Properties.SelectObject(node.Obj) then
							sys.IsRenaming = false
							return
						end

						sys.IsRenaming = selection.Map[node]

						if Lib.IsShiftDown() then
							if not selection.Piviot then return end

							local fromIndex = table.find(tree,selection.Piviot)
							local toIndex = table.find(tree,node)
							if not fromIndex or not toIndex then return end
							fromIndex,toIndex = math.min(fromIndex,toIndex),math.max(fromIndex,toIndex)

							local sList = selection.List
							for i = #sList,1,-1 do
								local elem = sList[i]
								if selection.ShiftSet[elem] then
									selection.Map[elem] = nil
									table.remove(sList,i)
								end
							end
							selection.ShiftSet = {}
							for i = fromIndex,toIndex do
								local elem = tree[i]
								if not selection.Map[elem] then
									selection.ShiftSet[elem] = true
									selection.Map[elem] = true
									sList[#sList+1] = elem
								end
							end
							selection.Changed:Fire()
						elseif Lib.IsCtrlDown() then
							selection.ShiftSet = {}
							if selection.Map[node] then selection:Remove(node) else selection:Add(node) end
							selection.Piviot = node
							sys.IsRenaming = false
						elseif not selection.Map[node] then
							selection.ShiftSet = {}
							selection:Set(node)
							selection.Piviot = node
						end
					elseif button == 2 then
						if Properties.SelectObject(node.Obj) then
							return
						end

						if not Lib.IsCtrlDown() and not selection.Map[node] then
							selection.ShiftSet = {}
							selection:Set(node)
							selection.Piviot = node
							Explorer.Refresh()
						end
					end

					Explorer.Refresh()
				end)

				sys.OnRelease:Connect(function(item,combo,button,position)
					local ind = table.find(listEntries,item)
					if not ind then return end
					local node = tree[ind + Explorer.Index]
					if not node then return end

					if button == 1 then
						if selection.Map[node] and not Lib.IsShiftDown() and not Lib.IsCtrlDown() then
							selection.ShiftSet = {}
							selection:Set(node)
							selection.Piviot = node
							Explorer.Refresh()
						end

						local id = sys.ClickId
						Lib.FastWait(sys.ComboTime)
						if combo == 1 and id == sys.ClickId and sys.IsRenaming and selection.Map[node] then
							Explorer.SetRenamingNode(node)
						end
					elseif button == 2 then
						Explorer.ShowRightClick(position)
					end
				end)
				Explorer.ClickSystem = sys
			end

			Explorer.InitDelCleaner = function()
			end

			Explorer.UpdateSelectionVisuals = function()
				local holder = Explorer.SelectionVisualsHolder
				local isa = game.IsA
				local clone = game.Clone
				if not holder then
					holder = Instance.new("ScreenGui")
					holder.Name = "ExplorerSelections"
					holder.DisplayOrder = Main.DisplayOrders.Core
					Lib.ShowGui(holder)
					Explorer.SelectionVisualsHolder = holder
					Explorer.SelectionVisualCons = {}

					local guiTemplate = create({
						{1,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Size=UDim2.new(0,100,0,100),}},
						{2,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,-1,0,-1),Size=UDim2.new(1,2,0,1),}},
						{3,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,-1,1,0),Size=UDim2.new(1,2,0,1),}},
						{4,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,-1,0,0),Size=UDim2.new(0,1,1,0),}},
						{5,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BorderSizePixel=0,Parent={1},Position=UDim2.new(1,0,0,0),Size=UDim2.new(0,1,1,0),}},
					})
					Explorer.SelectionVisualGui = guiTemplate

					local boxTemplate = Instance.new("SelectionBox")
					boxTemplate.LineThickness = 0.03
					boxTemplate.Color3 = Color3.fromRGB(0, 170, 255)
					Explorer.SelectionVisualBox = boxTemplate
				end
				holder:ClearAllChildren()

				-- Updates theme
				for i,v in pairs(Explorer.SelectionVisualGui:GetChildren()) do
					v.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
				end

				local attachCons = Explorer.SelectionVisualCons
				for i = 1,#attachCons do
					attachCons[i].Destroy()
				end
				table.clear(attachCons)

				local partEnabled = Settings.Explorer.PartSelectionBox
				local guiEnabled = Settings.Explorer.GuiSelectionBox
				if not partEnabled and not guiEnabled then return end

				local svg = Explorer.SelectionVisualGui
				local svb = Explorer.SelectionVisualBox
				local attachTo = Lib.AttachTo
				local sList = selection.List
				local count = 1
				local boxCount = 0
				local workspaceNode = nodes[workspace]
				for i = 1,#sList do
					if boxCount > 1000 then break end
					local node = sList[i]
					local obj = node.Obj

					if node ~= workspaceNode then
						if isa(obj,"GuiObject") and guiEnabled then
							local newVisual = clone(svg)
							attachCons[count] = attachTo(newVisual,{Target = obj, Resize = true})
							count = count + 1
							newVisual.Parent = holder
							boxCount = boxCount + 1
						elseif isa(obj,"PVInstance") and partEnabled then
							local newBox = clone(svb)
							newBox.Adornee = obj
							newBox.Parent = holder
							boxCount = boxCount + 1
						end
					end
				end
			end

			Explorer.InitClassIcons = function()
				if Settings.ClassIcon ~= nil and Settings.ClassIcon ~= "Old" then
					local iconData = Lib.IconMap.getIconDataFromName(Settings.ClassIcon)
					
					local MapIdStr = tostring(iconData.MapId)
					local Final = string.find(MapIdStr, "://") and MapIdStr or ("rbxassetid://" .. MapIdStr)
					
					Explorer.ClassIcons = Lib.IconMap.new(Final, iconData.IconSize * iconData.Witdh, iconData.IconSize * iconData.Height,iconData.IconSize,iconData.IconSize)
					local fixed = {}
					for i,v in pairs(iconData.Icons) do
						fixed[i] = v - 1
					end
					
					Explorer.ClassIcons:SetDict(fixed)
				else
					Explorer.ClassIcons = Lib.IconMap.newLinear("rbxasset://textures/ClassImages.PNG", 16,16)
				end
			end

			Explorer.Init = function()
				Explorer.LegacyClassIcons = Lib.IconMap.newLinear("rbxasset://textures/ClassImages.PNG", 16,16)
				Explorer.InitClassIcons()
				
				Explorer.MiscIcons = Main.MiscIcons

				clipboard = {}

				selection = Lib.Set.new()
				selection.ShiftSet = {}
				selection.Changed:Connect(Properties.ShowExplorerProps)
				Explorer.Selection = selection

				Explorer.InitRightClick()
				Explorer.InitInsertObject()
				Explorer.SetSortingEnabled(Settings.Explorer.Sorting)
				Explorer.Expanded = setmetatable({},{__mode = "k"})
				Explorer.SearchExpanded = setmetatable({},{__mode = "k"})
				expanded = Explorer.Expanded

				nilNode.Obj.Name = "Nil Instances"
				nilNode.Locked = true

				local explorerItems = create({
					{1,"Folder",{Name="ExplorerItems",}},
					{2,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ToolBar",Parent={1},Size=UDim2.new(1,0,0,22),}},
					{3,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.1176470592618,0.1176470592618,0.1176470592618),BorderSizePixel=0,Name="SearchFrame",Parent={2},Position=UDim2.new(0,3,0,1),Size=UDim2.new(1,-6,0,18),}},
					{4,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Name="SearchBox",Parent={3},PlaceholderColor3=Color3.new(0.39215689897537,0.39215689897537,0.39215689897537),PlaceholderText="Search workspace",Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-24,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
					{5,"UICorner",{CornerRadius=UDim.new(0,2),Parent={3},}},
					{6,"UIStroke",{Thickness=1.4,Parent={3},Color=Color3.fromRGB(42,42,42)}},
					{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Reset",Parent={3},Position=UDim2.new(1,-17,0,1),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
					{8,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/search2.png")) and getcustomasset("DEX_REContinued/Images/search2.png") or "rbxassetid://5034718129",ImageColor3=Color3.new(0.39215686917305,0.39215686917305,0.39215686917305),Parent={7},Size=UDim2.new(0,16,0,16),}},
					{9,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Refresh",Parent={2},Position=UDim2.new(1,-20,0,1),Size=UDim2.new(0,18,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
					{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344",Parent={9},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,12,0,12),}},
					{11,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="ScrollCorner",Parent={1},Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,16,0,16),Visible=false,}},
					{12,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Name="List",Parent={1},Position=UDim2.new(0,0,0,23),Size=UDim2.new(1,0,1,-23),}}
				})

				toolBar = explorerItems.ToolBar
				treeFrame = explorerItems.List

				Explorer.GuiElems.ToolBar = toolBar
				Explorer.GuiElems.TreeFrame = treeFrame

				scrollV = Lib.ScrollBar.new()		
				scrollV.WheelIncrement = 3
				scrollV.Gui.Position = UDim2.new(1,-16,0,23)
				scrollV:SetScrollFrame(treeFrame)
				scrollV.Scrolled:Connect(function()
					Explorer.Index = scrollV.Index
					Explorer.Refresh()
				end)

				scrollH = Lib.ScrollBar.new(true)
				scrollH.Increment = 5
				scrollH.WheelIncrement = Explorer.EntryIndent
				scrollH.Gui.Position = UDim2.new(0,0,1,-16)
				scrollH.Scrolled:Connect(function()
					Explorer.Refresh()
				end)

				local window = Lib.Window.new()
				Explorer.Window = window
				window:SetTitle("Explorer")
				window.GuiElems.Line.Position = UDim2.new(0,0,0,22)

				Explorer.InitEntryTemplate()
				toolBar.Parent = window.GuiElems.Content
				treeFrame.Parent = window.GuiElems.Content
				explorerItems.ScrollCorner.Parent = window.GuiElems.Content
				scrollV.Gui.Parent = window.GuiElems.Content
				scrollH.Gui.Parent = window.GuiElems.Content

				-- Init stuff that requires the window
				Explorer.InitRenameBox()
				Explorer.InitSearch()
				Explorer.InitDelCleaner()
				selection.Changed:Connect(Explorer.UpdateSelectionVisuals)

				-- Window events
				window.GuiElems.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					if Explorer.Active then
						Explorer.UpdateView()
						Explorer.Refresh()
					end
				end)
				window.OnActivate:Connect(function()
					Explorer.Active = true
					Explorer.UpdateView()
					Explorer.Update()
					Explorer.Refresh()
				end)
				window.OnRestore:Connect(function()
					Explorer.Active = true
					Explorer.UpdateView()
					Explorer.Update()
					Explorer.Refresh()
				end)
				window.OnDeactivate:Connect(function() Explorer.Active = false end)
				window.OnMinimize:Connect(function() Explorer.Active = false end)

				-- Settings
				autoUpdateSearch = Settings.Explorer.AutoUpdateSearch

				-- Fill in nodes
				nodes[game] = {Obj = game}
				expanded[nodes[game]] = true

				-- Nil Instances
				if env.getnilinstances then
					nodes[nilNode.Obj] = nilNode
				end

				Explorer.SetupConnections()

				local succ, tbl = pcall(ggc, game)
				if not succ or type(tbl) ~= "table" then tbl = {} end
				setmetatable(tbl, {__mode = "v"})
				local Out = {}
				for i = 1, #tbl do
					Out[i] = cloneref(tbl[i])
					tbl[i] = nil
				end

		local TopLevelServices = Out
		local ValidServices = {}

		for _, svc in next, TopLevelServices do
			if svc then
				local s, name = pcall(function() return svc.Name end)
				local s3, class = pcall(function() return svc.ClassName end)
				if s and s3 and not (badsvcs[name] or badsvcs[class]) then
					table.insert(ValidServices, svc)
				end
			end
		end

		ValidServices = sortsss(ValidServices)

		for _, svc in next, ValidServices do
			local NewNode = { Obj = svc, Parent = nodes[game] }
			nodes[svc] = NewNode
			nodes[game][#nodes[game]+1] = NewNode

				local succ2, tbl2 = pcall(ggd, svc)
				if not succ2 or type(tbl2) ~= "table" then tbl2 = {} end

				setmetatable(tbl2, {__mode = "v"})
				local output = {}
				for idx = 1, #tbl2 do
					output[idx] = cloneref(tbl2[idx])
					tbl2[idx] = nil
				end
			
			local descs = output
			for _, obj in next, descs do
				if obj then
					local s, name = pcall(function() return obj.Name end)
					local s3, class = pcall(function() return obj.ClassName end)
					if s and s3 and not (badsvcs[name] or badsvcs[class]) then
						
						local par
						if Main.Elevated then
							par = nodes[ffa(obj,"Instance")]
						else
							local ok, pObj = pcall(ffa, obj, "Instance")
							par = nodes[pObj]
						end
						
						if par then
							local nnode = { Obj = obj, Parent = par }
							nodes[obj] = nnode
							par[#par+1] = nnode
						end
					end
				end
			end
		end
	end

			return Explorer
		end

		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,
	Properties = function()
--[[
	Properties App Module
	
	The main properties interface
]]

		-- Common Locals
		local Main,Lib,Apps,Settings -- Main Containers
		local Explorer, Properties, ScriptViewer, ModelViewer, Notebook, EnvExplorer, DataExplorer, Saveinstance -- Major Apps
		local API,RMD,env,service,plr,create,createSimple -- Main Locals

		local function initDeps(data)
			Main = data.Main
			Lib = data.Lib
			Apps = data.Apps
			Settings = data.Settings

			API = data.API
			RMD = data.RMD
			env = data.env
			service = data.service
			plr = data.plr
			create = data.create
			createSimple = data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			ModelViewer = Apps.ModelViewer
			SettingsWindow = Apps.SettingsWindow
			Notebook = Apps.Notebook
		end

		local function main()
			local Properties = {}

			local window, toolBar, propsFrame
			local scrollV, scrollH
			local categoryOrder
			local props,viewList,expanded,indexableProps,propEntries = {},{},{},{},{}
			local autoUpdateObjs = setmetatable({}, {__mode = "v"})
			local inputBox,inputTextBox,inputProp
			Properties.CustomAddedProps = setmetatable({}, {__mode = "k"})
			Properties.CustomPropertyStates = setmetatable({}, {__mode = "k"})
			Properties.CustomPropsHooked = false
			local checkboxes,propCons = {},{}
			local table,string = table,string
			local getPropChangedSignal = game.GetPropertyChangedSignal
			local getAttributeChangedSignal = game.GetAttributeChangedSignal
			local isa = game.IsA
			local getAttribute = game.GetAttribute
			local setAttribute = game.SetAttribute

			Properties.GuiElems = {}
			Properties.Index = 0
			Properties.ViewWidth = 0
			Properties.MinInputWidth = 100
			Properties.EntryIndent = 16
			Properties.EntryOffset = 4
			Properties.NameWidthCache = {}
			Properties.SubPropCache = {}
			Properties.ClassLists = {}
			Properties.SearchText = ""

			Properties.AddAttributeProp = {Category = "Attributes", Class = "Instance", Name = "zzzz_AddAttribute", SpecialRow = "AddAttribute", Tags = {}}
			Properties.SoundPreviewProp = {Category = "Data", ValueType = {Name = "SoundPlayer"}, Class = "Sound", Name = "Preview", Tags = {}}
			Properties.AddTagProp = {Category = "Tags", Class = "Instance", Name = "zzzz_AddTag", SpecialRow = "AddTag", ValueType = {Name = "string"}, Tags = {}}

			Properties.IgnoreProps = {
				["DataModel"] = {
					["PrivateServerId"] = true,
					["PrivateServerOwnerId"] = true,
					["VIPServerId"] = true,
					["VIPServerOwnerId"] = true
				}
			}

			Properties.ExpandableTypes = {
				["Vector2"] = true,
				["Vector3"] = true,
				["UDim"] = true,
				["UDim2"] = true,
				["CFrame"] = true,
				["Rect"] = true,
				["PhysicalProperties"] = true,
				["Ray"] = true,
				["NumberRange"] = true,
				["Faces"] = true,
				["Axes"] = true
			}

			Properties.ExpandableProps = {
				["Sound.SoundId"] = true
			}

			Properties.CollapsedCategories = {
				["Surface Inputs"] = true,
				["Surface"] = true
			}

			Properties.ConflictSubProps = {
				["Vector2"] = {"X","Y"},
				["Vector3"] = {"X","Y","Z"},
				["UDim"] = {"Scale","Offset"},
				["UDim2"] = {"X","X.Scale","X.Offset","Y","Y.Scale","Y.Offset"},
				["CFrame"] = {"Position","Position.X","Position.Y","Position.Z",
					"RightVector","RightVector.X","RightVector.Y","RightVector.Z",
					"UpVector","UpVector.X","UpVector.Y","UpVector.Z",
					"LookVector","LookVector.X","LookVector.Y","LookVector.Z"},
				["Rect"] = {"Min.X","Min.Y","Max.X","Max.Y"},
				["PhysicalProperties"] = {"Density","Elasticity","ElasticityWeight","Friction","FrictionWeight"},
				["Ray"] = {"Origin","Origin.X","Origin.Y","Origin.Z","Direction","Direction.X","Direction.Y","Direction.Z"},
				["NumberRange"] = {"Min","Max"},
				["Faces"] = {"Back","Bottom","Front","Left","Right","Top"},
				["Axes"] = {"X","Y","Z"}
			}

			Properties.ConflictIgnore = {
				["BasePart"] = {
					["ResizableFaces"] = true
				}
			}

			Properties.RoundableTypes = {
				["float"] = true,
				["double"] = true,
				["Color3"] = true,
				["UDim"] = true,
				["UDim2"] = true,
				["Vector2"] = true,
				["Vector3"] = true,
				["NumberRange"] = true,
				["Rect"] = true,
				["NumberSequence"] = true,
				["ColorSequence"] = true,
				["Ray"] = true,
				["CFrame"] = true
			}

			Properties.TypeNameConvert = {
				["number"] = "double",
				["boolean"] = "bool"
			}

			Properties.ToNumberTypes = {
				["int"] = true,
				["int64"] = true,
				["float"] = true,
				["double"] = true
			}

			Properties.DefaultPropValue = {
				string = "",
				bool = false,
				double = 0,
				UDim = UDim.new(0,0),
				UDim2 = UDim2.new(0,0,0,0),
				BrickColor = BrickColor.new("Medium stone grey"),
				Color3 = Color3.new(1,1,1),
				Vector2 = Vector2.new(0,0),
				Vector3 = Vector3.new(0,0,0),
				NumberSequence = NumberSequence.new(1),
				ColorSequence = ColorSequence.new(Color3.new(1,1,1)),
				NumberRange = NumberRange.new(0),
				Rect = Rect.new(0,0,0,0)
			}

			Properties.AllowedAttributeTypes = {"string","boolean","number","UDim","UDim2","BrickColor","Color3","Vector2","Vector3","NumberSequence","ColorSequence","NumberRange","Rect"}

			Properties.StringToValue = function(prop,str)
				local typeData = prop.ValueType
				local typeName = typeData.Name

				if typeName == "string" or typeName == "Content" then
					return str
				elseif Properties.ToNumberTypes[typeName] then
					return tonumber(str)
				elseif typeName == "Vector2" then
					local vals = str:split(",")
					local x,y = tonumber(vals[1]),tonumber(vals[2])
					if x and y and #vals >= 2 then return Vector2.new(x,y) end
				elseif typeName == "Vector3" then
					local vals = str:split(",")
					local x,y,z = tonumber(vals[1]),tonumber(vals[2]),tonumber(vals[3])
					if x and y and z and #vals >= 3 then return Vector3.new(x,y,z) end
				elseif typeName == "UDim" then
					local vals = str:split(",")
					local scale,offset = tonumber(vals[1]),tonumber(vals[2])
					if scale and offset and #vals >= 2 then return UDim.new(scale,offset) end
				elseif typeName == "UDim2" then
					local vals = str:gsub("[{}]",""):split(",")
					local xScale,xOffset,yScale,yOffset = tonumber(vals[1]),tonumber(vals[2]),tonumber(vals[3]),tonumber(vals[4])
					if xScale and xOffset and yScale and yOffset and #vals >= 4 then return UDim2.new(xScale,xOffset,yScale,yOffset) end
				elseif typeName == "CFrame" then
					local vals = str:split(",")
					local s,result = pcall(CFrame.new, unpack(vals))
					if s and #vals >= 12 then return result end
				elseif typeName == "Rect" then
					local vals = str:split(",")
					local s,result = pcall(Rect.new,unpack(vals))
					if s and #vals >= 4 then return result end
				elseif typeName == "Ray" then
					local vals = str:gsub("[{}]",""):split(",")
					local s,origin = pcall(Vector3.new,unpack(vals,1,3))
					local s2,direction = pcall(Vector3.new,unpack(vals,4,6))
					if s and s2 and #vals >= 6 then return Ray.new(origin,direction) end
				elseif typeName == "NumberRange" then
					local vals = str:split(",")
					local s,result = pcall(NumberRange.new,unpack(vals))
					if s and #vals >= 1 then return result end
				elseif typeName == "Color3" then
					local vals = str:gsub("[{}]",""):split(",")
					local s,result = pcall(Color3.fromRGB,unpack(vals))
					if s and #vals >= 3 then return result end
				end

				return nil
			end

			Properties.ValueToString = function(prop,val)
				local typeData = prop.ValueType
				local typeName = typeData.Name

				if typeName == "Color3" then
					return Lib.ColorToBytes(val)
				elseif typeName == "NumberRange" then
					return val.Min..", "..val.Max
				end

				return tostring(val)
			end

			Properties.GetIndexableProps = function(obj,classData)
				if not Main.Elevated then
					if not pcall(function() return obj.ClassName end) then return nil end
				end

				local ignoreProps = Properties.IgnoreProps[classData.Name] or {}

				local result = {}
				local count = 1
				local props = classData.Properties
				for i = 1,#props do
					local prop = props[i]
					if not ignoreProps[prop.Name] then
						result[count] = prop
						count = count + 1
					end
				end

				return result
			end

			Properties.FindFirstObjWhichIsA = function(class)
				local classList = Properties.ClassLists[class] or {}
				if classList and #classList > 0 then
					return classList[1]
				end

				return nil
			end

			Properties.ComputeConflicts = function(p)
				local maxConflictCheck = Settings.Properties.MaxConflictCheck
				local sList = Explorer.Selection.List
				local classLists = Properties.ClassLists
				local stringSplit = string.split
				local t_clear = table.clear
				local conflictIgnore = Properties.ConflictIgnore
				local conflictMap = {}
				local propList = p and {p} or props

				if p then
					local gName = p.Class.."."..p.Name
					autoUpdateObjs[gName] = nil
					local subProps = Properties.ConflictSubProps[p.ValueType.Name] or {}
					for i = 1,#subProps do
						autoUpdateObjs[gName.."."..subProps[i]] = nil
					end
				else
					table.clear(autoUpdateObjs)
				end

				if #sList > 0 then
					for i = 1,#propList do
						local prop = propList[i]
						if prop.SpecialRow then continue end
						
						local propName,propClass = prop.Name,prop.Class
						local typeData = prop.RootType or prop.ValueType
						local typeName = typeData.Name
						local attributeName = prop.AttributeName
						local gName = propClass.."."..propName

						local checked = 0
						local subProps = Properties.ConflictSubProps[typeName] or {}
						local subPropCount = #subProps
						local toCheck = subPropCount + 1
						local conflictsFound = 0
						local indexNames = {}
						local ignored = conflictIgnore[propClass] and conflictIgnore[propClass][propName]
						local truthyCheck = (typeName == "PhysicalProperties")
						local isAttribute = prop.IsAttribute
						local isMultiType = prop.MultiType

						t_clear(conflictMap)

						if not isMultiType then
							local firstVal,firstObj,firstSet
							local classList = classLists[prop.Class] or {}
							for c = 1,#classList do
								local obj = classList[c]
								if not firstSet then
									if isAttribute then
										firstVal = getAttribute(obj,attributeName)
										if firstVal ~= nil then
											firstObj = obj
											firstSet = true
										end
									elseif prop.IsTag then
										local hasTag = cloneref(game:GetService("CollectionService")):HasTag(obj, prop.TagName)
										if hasTag then
											firstVal = prop.TagName
											firstObj = obj
											firstSet = true
										end
									else
										local hasSpecialTag = prop.IsHidden or (prop.Tags and prop.Tags.NotScriptable)
										local v = nil
										if hasSpecialTag and env.gethiddenproperty then
											local hs, hval = pcall(env.gethiddenproperty, obj, propName)
											if hs and hval ~= nil then v = hval end
										end
										if v == nil then
											local s1, val = pcall(function() return obj[propName] end)
											if s1 and val ~= nil then v = val end
										end
										if v == nil and not hasSpecialTag and env.gethiddenproperty then
											local hs, hval = pcall(env.gethiddenproperty, obj, propName)
											if hs and hval ~= nil then v = hval end
										end
										if v == nil and env.isscriptable and env.setscriptable then
											local is_s, is_script = pcall(env.isscriptable, obj, propName)
											if is_s and not is_script then
												local was_s = env.setscriptable(obj, propName, true)
												pcall(function() v = obj[propName] end)
												pcall(env.setscriptable, obj, propName, was_s)
											end
										end

										if v ~= nil then
										    firstVal = v
										    firstObj = obj
										    firstSet = true
										end
									end
									if ignored then break end
								else
									local propVal,skip
									if isAttribute then
										propVal = getAttribute(obj,attributeName)
										if propVal == nil then skip = true end
									elseif prop.IsTag then
										local hasTag = cloneref(game:GetService("CollectionService")):HasTag(obj, prop.TagName)
										if hasTag then propVal = prop.TagName else skip = true end
									else
										local hasSpecialTag = prop.IsHidden or (prop.Tags and prop.Tags.NotScriptable)
										local v = nil
										if hasSpecialTag and env.gethiddenproperty then
											local hs, hval = pcall(env.gethiddenproperty, obj, propName)
											if hs and hval ~= nil then v = hval end
										end
										if v == nil then
											local s1, val = pcall(function() return obj[propName] end)
											if s1 and val ~= nil then v = val end
										end
										if v == nil and not hasSpecialTag and env.gethiddenproperty then
											local hs, hval = pcall(env.gethiddenproperty, obj, propName)
											if hs and hval ~= nil then v = hval end
										end
										if v == nil and env.isscriptable and env.setscriptable then
											local is_s, is_script = pcall(env.isscriptable, obj, propName)
											if is_s and not is_script then
												local was_s = env.setscriptable(obj, propName, true)
												pcall(function() v = obj[propName] end)
												pcall(env.setscriptable, obj, propName, was_s)
											end
										end
										
										if v ~= nil then propVal = v else skip = true end
									end

									if not skip then
										if not conflictMap[1] then
											if truthyCheck then
												if (firstVal and true or false) ~= (propVal and true or false) then
													conflictMap[1] = true
													conflictsFound = conflictsFound + 1
												end
											elseif firstVal ~= propVal then
												conflictMap[1] = true
												conflictsFound = conflictsFound + 1
											end
										end

										if subPropCount > 0 then
											for sPropInd = 1,subPropCount do
												local indexes = indexNames[sPropInd]
												if not indexes then indexes = stringSplit(subProps[sPropInd],".") indexNames[sPropInd] = indexes end

												local firstValSub = firstVal
												local propValSub = propVal

												for j = 1,#indexes do
													if not firstValSub or not propValSub then break end -- PhysicalProperties
													local indexName = indexes[j]
													local s1, v1 = pcall(function() return firstValSub[indexName] end)
													local s2, v2 = pcall(function() return propValSub[indexName] end)
													firstValSub = s1 and v1 or nil
													propValSub = s2 and v2 or nil
												end

												local mapInd = sPropInd + 1
												if not conflictMap[mapInd] and firstValSub ~= propValSub then
													conflictMap[mapInd] = true
													conflictsFound = conflictsFound + 1
												end
											end
										end

										if conflictsFound == toCheck then break end
									end
								end

								checked = checked + 1
								if checked == maxConflictCheck then break end
							end

							if not conflictMap[1] then autoUpdateObjs[gName] = firstObj end
							for sPropInd = 1,subPropCount do
								if not conflictMap[sPropInd+1] then
									autoUpdateObjs[gName.."."..subProps[sPropInd]] = firstObj
								end
							end
						end
					end
				end

				if p then
					Properties.Refresh()
				end
			end

			-- Fetches the properties to be displayed based on the explorer selection
			Settings.Properties.ShowAttributes = true -- im making it true anyway since its useful by default and people complain
			Properties.ShowExplorerProps = function()
				local maxConflictCheck = Settings.Properties.MaxConflictCheck
				local sList = Explorer.Selection.List
				local foundClasses = {}
				local foundCustomProps = {}
				local propCount = 1
				local elevated = Main.Elevated
				local showDeprecated,showHidden = Settings.Properties.ShowDeprecated,Settings.Properties.ShowHidden
				local showAllProps = Settings.Properties.ShowAllProperties
				local Classes = API.Classes
				local classLists = {}
				local lower = string.lower
				local RMDCustomOrders = RMD.PropertyOrders
				local getAttributes = game.GetAttributes
				local maxAttrs = Settings.Properties.MaxAttributes
				local showingAttrs = Settings.Properties.ShowAttributes
				local foundAttrs = {}
				local attrCount = 0
				local typeof = typeof
				local typeNameConvert = Properties.TypeNameConvert

				table.clear(props)

				local showingTags = Settings.Properties.ShowTags
				local foundTags = {}

				for i = 1,#sList do
					local node = sList[i]
					local obj = node.Obj
					local class = node.Class
					if not class then class = obj.ClassName node.Class = class end

					local hiddenProps = {}
					if env.gethiddenproperties then
						pcall(function()
							for k, v in pairs(env.gethiddenproperties(obj)) do
								hiddenProps[k] = true
							end
						end)
					end
					
					local allProps = {}
					if showAllProps and env.getproperties then
						pcall(function()
							for k, v in pairs(env.getproperties(obj)) do
								allProps[k] = true
							end
						end)
					end

					local apiClass = Classes[class]
					while apiClass do
						local APIClassName = apiClass.Name
						if not foundClasses[APIClassName] then
							local apiProps = indexableProps[APIClassName]
							if not apiProps then apiProps = Properties.GetIndexableProps(obj,apiClass) indexableProps[APIClassName] = apiProps end

							for _, prop in pairs(apiProps) do
								local tags = prop.Tags
								local isHidden = tags.Hidden or hiddenProps[prop.Name]

								if (not tags.Deprecated or showDeprecated) and (not isHidden or showHidden) then
									props[propCount] = prop
									propCount = propCount + 1
								end
								hiddenProps[prop.Name] = nil
								allProps[prop.Name] = nil
							end
							foundClasses[APIClassName] = true
						end

						local classList = classLists[APIClassName]
						if not classList then classList = {} classLists[APIClassName] = classList end
						classList[#classList+1] = obj

						apiClass = apiClass.Superclass
					end

					if showHidden then
						for propName, _ in pairs(hiddenProps) do
							local val = nil
							pcall(function() 
								if env.gethiddenproperty then 
									local hs, hval = pcall(env.gethiddenproperty, obj, propName)
									if hs then val = hval end
								end 
							end)
							local vType = typeof(val)
							props[propCount] = {
								Name = propName,
								Class = class,
								Category = "Hidden",
								ValueType = {Name = typeNameConvert[vType] or vType, Category = "DataType"},
								Tags = {Hidden = true},
								IsHidden = true
							}
							propCount = propCount + 1
							allProps[propName] = nil
						end
					end
					
					if showAllProps then
						for propName, _ in pairs(allProps) do
							local val = nil
							pcall(function() val = obj[propName] end)
							local vType = typeof(val)
							props[propCount] = {
								Name = propName,
								Class = class,
								Category = "Uncategorized",
								ValueType = {Name = typeNameConvert[vType] or vType, Category = "DataType"},
								Tags = {}
							}
							propCount = propCount + 1
						end
					end

					if showingTags then
						local tags = cloneref(game:GetService("CollectionService")):GetTags(obj)
						for _, tag in pairs(tags) do
							if not foundTags[tag] then
								local tagProp = {
									IsTag = true, 
									Name = "TAG_"..tag, 
									TagName = tag, 
									DisplayName = tag, 
									Class = "Instance", 
									ValueType = {Name = "string", Category = "DataType"}, 
									Category = "Tags", 
									Tags = {ReadOnly = true}
								}
								props[propCount] = tagProp
								propCount = propCount + 1
								foundTags[tag] = true
							end
						end
					end
					
					local CustomAdded = Properties.CustomAddedProps[obj]
					if CustomAdded then
						for PropName, PropType in pairs(CustomAdded) do
							if not foundCustomProps[PropName] then
								local category = (PropType == "Instance" and "Class") or (PropType == "EnumItem" and "Enum") or "DataType"
								local valType = {Name = typeNameConvert[PropType] or PropType, Category = category}
								
								local CustomProp = {
									IsCustom = true, 
									Name = PropName, 
									DisplayName = PropName, 
									Class = "Instance",
									ValueType = valType, 
									Category = "Custom Added", 
									Tags = {}
								}
								
								props[propCount] = CustomProp
								propCount = propCount + 1
								foundCustomProps[PropName] = true
							end
						end
					end

					if showingAttrs and attrCount < maxAttrs then
						local attrs = getAttributes(obj)
						for name,val in pairs(attrs) do
							local typ = typeof(val)
							if not foundAttrs[name] then
								local category = (typ == "Instance" and "Class") or (typ == "EnumItem" and "Enum") or "Other"
								local valType = {Name = typeNameConvert[typ] or typ, Category = category}
								local attrProp = {IsAttribute = true, Name = "ATTR_"..name, AttributeName = name, DisplayName = name, Class = "Instance", ValueType = valType, Category = "Attributes", Tags = {}}
								props[propCount] = attrProp
								propCount = propCount + 1
								attrCount = attrCount + 1
								foundAttrs[name] = {typ,attrProp}
								if attrCount == maxAttrs then break end
							elseif foundAttrs[name][1] ~= typ then
								foundAttrs[name][2].MultiType = true
								foundAttrs[name][2].Tags.ReadOnly = true
								foundAttrs[name][2].ValueType = {Name = "string"}
							end
						end
					end
				end

				if #props > 0 then
					props[#props+1] = Properties.AddAttributeProp
					props[#props+1] = Properties.AddTagProp
				end

				if not categoryOrder["Custom Added"] then categoryOrder["Custom Added"] = 9998 end
				if not categoryOrder["Attributes"] then categoryOrder["Attributes"] = 9999 end
				if not categoryOrder["Tags"] then categoryOrder["Tags"] = 10000 end

				table.sort(props,function(a,b)
					if a.Category ~= b.Category then
						local aCat = categoryOrder[a.Category] or 9999
						local bCat = categoryOrder[b.Category] or 9999
						if aCat ~= bCat then
							return aCat < bCat
						else
							return lower(a.Category) < lower(b.Category)
						end
					else
						local aOrder = (RMDCustomOrders[a.Class] and RMDCustomOrders[a.Class][a.Name]) or 9999999
						local bOrder = (RMDCustomOrders[b.Class] and RMDCustomOrders[b.Class][b.Name]) or 9999999
						if aOrder ~= bOrder then
							return aOrder < bOrder
						else
							return lower(a.Name) < lower(b.Name)
						end
					end
				end)

				Properties.ClassLists = classLists
				Properties.ComputeConflicts()

				Properties.Update()
				Properties.Refresh()
			end

			Properties.UpdateView = function()
				local maxEntries = math.ceil(propsFrame.AbsoluteSize.Y / 23)
				local maxX = propsFrame.AbsoluteSize.X
				local totalWidth = Properties.ViewWidth + Properties.MinInputWidth

				scrollV.VisibleSpace = maxEntries
				scrollV.TotalSpace = #viewList + 1
				scrollH.VisibleSpace = maxX
				scrollH.TotalSpace = totalWidth

				scrollV.Gui.Visible = #viewList + 1 > maxEntries
				scrollH.Gui.Visible = Settings.Properties.ScaleType == 0 and totalWidth > maxX

				local oldSize = propsFrame.Size
				propsFrame.Size = UDim2.new(1,(scrollV.Gui.Visible and -16 or 0),1,(scrollH.Gui.Visible and -39 or -23))
				if oldSize ~= propsFrame.Size then
					Properties.UpdateView()
				else
					scrollV:Update()
					scrollH:Update()

					if scrollV.Gui.Visible and scrollH.Gui.Visible then
						scrollV.Gui.Size = UDim2.new(0,16,1,-39)
						scrollH.Gui.Size = UDim2.new(1,-16,0,16)
						Properties.Window.GuiElems.Content.ScrollCorner.Visible = true
					else
						scrollV.Gui.Size = UDim2.new(0,16,1,-23)
						scrollH.Gui.Size = UDim2.new(1,0,0,16)
						Properties.Window.GuiElems.Content.ScrollCorner.Visible = false
					end

					Properties.Index = scrollV.Index
				end
			end

			Properties.MakeSubProp = function(prop,subName,valueType,displayName)
				local subProp = {}
				for i,v in pairs(prop) do
					subProp[i] = v
				end
				subProp.RootType = subProp.RootType or subProp.ValueType
				subProp.ValueType = valueType
				subProp.SubName = subProp.SubName and (subProp.SubName..subName) or subName
				subProp.DisplayName = displayName

				return subProp
			end

			Properties.GetExpandedProps = function(prop) -- TODO: Optimize using table
				local result = {}
				local typeData = prop.ValueType
				local typeName = typeData.Name
				local makeSubProp = Properties.MakeSubProp

				if typeName == "Vector2" then
					result[1] = makeSubProp(prop,".X",{Name = "float"})
					result[2] = makeSubProp(prop,".Y",{Name = "float"})
				elseif typeName == "Vector3" then
					result[1] = makeSubProp(prop,".X",{Name = "float"})
					result[2] = makeSubProp(prop,".Y",{Name = "float"})
					result[3] = makeSubProp(prop,".Z",{Name = "float"})
				elseif typeName == "CFrame" then
					result[1] = makeSubProp(prop,".Position",{Name = "Vector3"})
					result[2] = makeSubProp(prop,".RightVector",{Name = "Vector3"})
					result[3] = makeSubProp(prop,".UpVector",{Name = "Vector3"})
					result[4] = makeSubProp(prop,".LookVector",{Name = "Vector3"})
				elseif typeName == "UDim" then
					result[1] = makeSubProp(prop,".Scale",{Name = "float"})
					result[2] = makeSubProp(prop,".Offset",{Name = "int"})
				elseif typeName == "UDim2" then
					result[1] = makeSubProp(prop,".X",{Name = "UDim"})
					result[2] = makeSubProp(prop,".Y",{Name = "UDim"})
				elseif typeName == "Rect" then
					result[1] = makeSubProp(prop,".Min.X",{Name = "float"},"X0")
					result[2] = makeSubProp(prop,".Min.Y",{Name = "float"},"Y0")
					result[3] = makeSubProp(prop,".Max.X",{Name = "float"},"X1")
					result[4] = makeSubProp(prop,".Max.Y",{Name = "float"},"Y1")
				elseif typeName == "PhysicalProperties" then
					result[1] = makeSubProp(prop,".Density",{Name = "float"})
					result[2] = makeSubProp(prop,".Elasticity",{Name = "float"})
					result[3] = makeSubProp(prop,".ElasticityWeight",{Name = "float"})
					result[4] = makeSubProp(prop,".Friction",{Name = "float"})
					result[5] = makeSubProp(prop,".FrictionWeight",{Name = "float"})
				elseif typeName == "Ray" then
					result[1] = makeSubProp(prop,".Origin",{Name = "Vector3"})
					result[2] = makeSubProp(prop,".Direction",{Name = "Vector3"})
				elseif typeName == "NumberRange" then
					result[1] = makeSubProp(prop,".Min",{Name = "float"})
					result[2] = makeSubProp(prop,".Max",{Name = "float"})
				elseif typeName == "Faces" then
					result[1] = makeSubProp(prop,".Back",{Name = "bool"})
					result[2] = makeSubProp(prop,".Bottom",{Name = "bool"})
					result[3] = makeSubProp(prop,".Front",{Name = "bool"})
					result[4] = makeSubProp(prop,".Left",{Name = "bool"})
					result[5] = makeSubProp(prop,".Right",{Name = "bool"})
					result[6] = makeSubProp(prop,".Top",{Name = "bool"})
				elseif typeName == "Axes" then
					result[1] = makeSubProp(prop,".X",{Name = "bool"})
					result[2] = makeSubProp(prop,".Y",{Name = "bool"})
					result[3] = makeSubProp(prop,".Z",{Name = "bool"})
				end

				if prop.Name == "SoundId" and prop.Class == "Sound" then
					result[1] = Properties.SoundPreviewProp
				end

				return result
			end

			Properties.Update = function()
				table.clear(viewList)

				local nameWidthCache = Properties.NameWidthCache
				local lastCategory
				local count = 1
				local maxWidth,maxDepth = 0,1

				local textServ = service.TextService
				local getTextSize = textServ.GetTextSize
				local font = Enum.Font.SourceSans
				local size = Vector2.new(math.huge,20)
				local stringSplit = string.split
				local entryIndent = Properties.EntryIndent
				local isFirstScaleType = Settings.Properties.ScaleType == 0
				local find,lower = string.find,string.lower
				local searchText = (#Properties.SearchText > 0 and lower(Properties.SearchText))

				local function recur(props,depth)
					for i = 1,#props do
						local prop = props[i]
						local propName = prop.Name
						local subName = prop.SubName
						local category = prop.Category

						local visible
						if searchText and depth == 1 then
							if find(lower(propName),searchText,1,true) then
								visible = true
							end
						else
							visible = true
						end

						if visible and lastCategory ~= category then
							viewList[count] = {CategoryName = category}
							count = count + 1
							lastCategory = category
						end

						if (expanded["CAT_"..category] and visible) or prop.SpecialRow then
							if depth > 1 then prop.Depth = depth if depth > maxDepth then maxDepth = depth end end

							if isFirstScaleType then
								local nameArr = subName and stringSplit(subName,".")
								local displayName = prop.DisplayName or (nameArr and nameArr[#nameArr]) or propName

								local nameWidth = nameWidthCache[displayName]
								if not nameWidth then nameWidth = getTextSize(textServ,displayName,14,font,size).X nameWidthCache[displayName] = nameWidth end

								local totalWidth = nameWidth + entryIndent*depth
								if totalWidth > maxWidth then
									maxWidth = totalWidth
								end
							end

							viewList[count] = prop
							count = count + 1

							local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
							if expanded[fullName] then
								local nextDepth = depth+1
								local expandedProps = Properties.GetExpandedProps(prop)
								if #expandedProps > 0 then
									recur(expandedProps,nextDepth)
								end
							end
						end
					end
				end
				recur(props,1)

				inputProp = nil
				Properties.ViewWidth = maxWidth + 9 + Properties.EntryOffset
				Properties.UpdateView()
			end

			Properties.NewPropEntry = function(index)
				local newEntry = Properties.EntryTemplate:Clone()
				local nameFrame = newEntry.NameFrame
				local valueFrame = newEntry.ValueFrame
				local newCheckbox = Lib.Checkbox.new(1)
				newCheckbox.Gui.Position = UDim2.new(0,3,0,3)
				newCheckbox.Gui.Parent = valueFrame
				newCheckbox.OnInput:Connect(function()
					local prop = viewList[index + Properties.Index]
					if not prop then return end

					if prop.ValueType.Name == "PhysicalProperties" then
						Properties.SetProp(prop,newCheckbox.Toggled and true or nil)
					else
						Properties.SetProp(prop,newCheckbox.Toggled)
					end
				end)
				checkboxes[index] = newCheckbox

				local iconFrame = Main.MiscIcons:GetLabel()
				iconFrame.Position = UDim2.new(0,2,0,3)
				iconFrame.Parent = newEntry.ValueFrame.RightButton

				newEntry.Position = UDim2.new(0,0,0,23*(index-1))

				nameFrame.Expand.InputBegan:Connect(function(input)
					local prop = viewList[index + Properties.Index]
					if not prop or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

					local fullName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")

					Main.MiscIcons:DisplayByKey(newEntry.NameFrame.Expand.Icon, expanded[fullName] and "Collapse_Over" or "Expand_Over")
				end)

				nameFrame.Expand.InputEnded:Connect(function(input)
					local prop = viewList[index + Properties.Index]
					if not prop or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end

					local fullName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")

					Main.MiscIcons:DisplayByKey(newEntry.NameFrame.Expand.Icon, expanded[fullName] and "Collapse" or "Expand")
				end)

				nameFrame.Expand.MouseButton1Down:Connect(function()
					local prop = viewList[index + Properties.Index]
					if not prop then return end

					local fullName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")
					if not prop.CategoryName and not Properties.ExpandableTypes[prop.ValueType and prop.ValueType.Name] and not Properties.ExpandableProps[fullName] then return end

					expanded[fullName] = not expanded[fullName]
					Properties.Update()
					Properties.Refresh()
				end)

				nameFrame.PropName.InputBegan:Connect(function(input)
					local prop = viewList[index + Properties.Index]
					if not prop then return end
					if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and not nameFrame.PropName.TextFits then
						local fullNameFrame = Properties.FullNameFrame	
						local nameArr = string.split(prop.Class.."."..prop.Name..(prop.SubName or ""), ".")
						local dispName = prop.DisplayName or nameArr[#nameArr]
						local sizeX = service.TextService:GetTextSize(dispName, 14, Enum.Font.SourceSans, Vector2.new(math.huge, 20)).X

						fullNameFrame.TextLabel.Text = dispName
						fullNameFrame.Size = UDim2.new(0, sizeX + 4, 0, 22)
						fullNameFrame.Visible = true
						Properties.FullNameFrameIndex = index
						Properties.FullNameFrameAttach.SetData(fullNameFrame, {Target = nameFrame})
						Properties.FullNameFrameAttach.Enable()
					end
				end)

				nameFrame.PropName.InputEnded:Connect(function(input)
					if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and Properties.FullNameFrameIndex == index then
						Properties.FullNameFrame.Visible = false
						Properties.FullNameFrameAttach.Disable()
					end
				end)


				valueFrame.ValueBox.MouseButton1Down:Connect(function()
					local prop = viewList[index + Properties.Index]
					if not prop then return end

					Properties.SetInputProp(prop,index)
				end)

				valueFrame.ColorButton.MouseButton1Down:Connect(function()
					local prop = viewList[index + Properties.Index]
					if not prop then return end

					Properties.SetInputProp(prop,index,"color")
				end)

				valueFrame.RightButton.MouseButton1Click:Connect(function()
					local prop = viewList[index + Properties.Index]
					if not prop then return end

					local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
					local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))

					if fullName == inputFullName and inputProp.ValueType.Category == "Class" then
						inputProp = nil
						Properties.SetProp(prop,nil)
					else
						Properties.SetInputProp(prop,index,"right")
					end
				end)

				nameFrame.ToggleAttributes.MouseButton1Click:Connect(function()
		    local prop = viewList[index + Properties.Index]
		    if prop.CategoryName == "Attributes" then
			    Settings.Properties.ShowAttributes = not Settings.Properties.ShowAttributes
			elseif prop.CategoryName == "Tags" then
			    Settings.Properties.ShowTags = not Settings.Properties.ShowTags
			end
			Properties.ShowExplorerProps()
		end)

		newEntry.RowButton.MouseButton1Click:Connect(function()
		    local prop = viewList[index + Properties.Index]
		    if prop.SpecialRow == "AddAttribute" then
			    Properties.DisplayAddAttributeWindow()
			elseif prop.SpecialRow == "AddTag" then
			    Properties.DisplayAddTagWindow()
			end
		end)

		newEntry.EditAttributeButton.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then return end

            if prop.IsAttribute then
			    Properties.DisplayAttributeContext(prop)
			elseif prop.IsTag then
			    Properties.DisplayTagContext(prop)
			end
		end)

				valueFrame.SoundPreview.ControlButton.MouseButton1Click:Connect(function()
					if Properties.PreviewSound and Properties.PreviewSound.Playing then
						Properties.SetSoundPreview(false)
					else
						local soundObj = Properties.FindFirstObjWhichIsA("Sound")
						if soundObj then Properties.SetSoundPreview(soundObj) end
					end
				end)

				valueFrame.SoundPreview.InputBegan:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

					local releaseEvent, inputEvent
					releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							releaseEvent:Disconnect()
							if inputEvent then
								inputEvent:Disconnect()
							end
						end
					end)

					local timeLine = newEntry.ValueFrame.SoundPreview.TimeLine
					local soundObj = Properties.FindFirstObjWhichIsA("Sound")
					if soundObj then Properties.SetSoundPreview(soundObj, true) end

					local function update(input)
						local sound = Properties.PreviewSound
						if not sound or sound.TimeLength == 0 then return end

						local inputX = (input.UserInputType == Enum.UserInputType.Touch) and input.Position.X or input.Position.X
						local timeLineSize = timeLine.AbsoluteSize
						local relaX = inputX - timeLine.AbsolutePosition.X

						if timeLineSize.X <= 1 then return end
						if relaX < 0 then relaX = 0 elseif relaX >= timeLineSize.X then relaX = timeLineSize.X - 1 end

						local perc = (relaX / (timeLineSize.X - 1))
						sound.TimePosition = perc * sound.TimeLength
						timeLine.Slider.Position = UDim2.new(perc, -4, 0, -8)
					end

					update(input)

					inputEvent = service.UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							update(input)
						end
					end)
				end)

					valueFrame.CopyButton.MouseButton1Click:Connect(function()
					local prop = viewList[index + Properties.Index]
					if not prop or not env.setclipboard then return end
					
					local gName = prop.Class.."."..prop.Name..(prop.SubName or "")
					local propObj = autoUpdateObjs[gName]
					if not propObj then return end

					local path = Explorer.GetInstancePath(propObj)
					local val = Properties.GetPropVal(prop, propObj)
					local luaVal = Properties.GetLuaValue(prop.ValueType.Name, val)
					
					local str = ""
					if prop.IsAttribute then
						str = string.format('%s:SetAttribute("%s", %s)', path, prop.AttributeName, luaVal)
					elseif prop.IsTag then
						str = string.format('game:GetService("CollectionService"):AddTag(%s, "%s")', path, prop.TagName)
					else
						local RequiresHidden = prop.IsHidden or (prop.Tags and prop.Tags.NotScriptable)
						if not requiresHidden then
							local s = pcall(function() return propObj[prop.Name] end)
							if not s then RequiresHidden = true end
						end
						
						if RequiresHidden then
							if prop.SubName then
								local rootVal = Properties.GetPropVal({Name = prop.Name, IsHidden = prop.IsHidden, Tags = prop.Tags}, propObj)
								local rootLuaVal = Properties.GetLuaValue(prop.RootType and prop.RootType.Name or prop.ValueType.Name, rootVal)
								str = string.format('-- Cannot copy isolated sub-property for a hidden property.\n-- Use the full root value instead:\nsethiddenproperty(%s, "%s", %s)', path, prop.Name, rootLuaVal)
							else
								str = string.format('sethiddenproperty(%s, "%s", %s)', path, prop.Name, luaVal)
							end
						else
							str = string.format('%s.%s%s = %s', path, prop.Name, prop.SubName or "", luaVal)
						end
					end
					
					env.setclipboard(str)
				end)

				newEntry.Parent = propsFrame

				return {
					Gui = newEntry,
					GuiElems = {
						NameFrame = nameFrame,
						ValueFrame = valueFrame,
						PropName = nameFrame.PropName,
						ValueBox = valueFrame.ValueBox,
						Expand = nameFrame.Expand,
						ColorButton = valueFrame.ColorButton,
						ColorPreview = valueFrame.ColorButton.ColorPreview,
						Gradient = valueFrame.ColorButton.ColorPreview.UIGradient,
						EnumArrow = valueFrame.EnumArrow,
						Checkbox = valueFrame.Checkbox,
						RightButton = valueFrame.RightButton,
						RightButtonIcon = iconFrame,
						CopyButton = valueFrame.CopyButton,
						RowButton = newEntry.RowButton,
						EditAttributeButton = newEntry.EditAttributeButton,
						ToggleAttributes = nameFrame.ToggleAttributes,
						SoundPreview = valueFrame.SoundPreview,
						SoundPreviewSlider = valueFrame.SoundPreview.TimeLine.Slider
					}
				}
			end

			Properties.GetSoundPreviewEntry = function()
				for i = 1,#viewList do
					if viewList[i] == Properties.SoundPreviewProp then
						return propEntries[i - Properties.Index]
					end
				end
			end

			Properties.SetSoundPreview = function(soundObj,noplay)
				local sound = Properties.PreviewSound
				if not sound then
					sound = Instance.new("Sound")
					sound.Name = "Preview"
					sound.Paused:Connect(function()
						local entry = Properties.GetSoundPreviewEntry()
						if entry then Main.MiscIcons:DisplayByKey(entry.GuiElems.SoundPreview.ControlButton.Icon, "Play") end
					end)
					sound.Resumed:Connect(function() Properties.Refresh() end)
					sound.Ended:Connect(function()
						local entry = Properties.GetSoundPreviewEntry()
						if entry then entry.GuiElems.SoundPreviewSlider.Position = UDim2.new(0,-4,0,-8) end
						Properties.Refresh()
					end)
					sound.Parent = window.Gui
					Properties.PreviewSound = sound
				end

				if not soundObj then
					sound:Pause()
				else
					local newId = sound.SoundId ~= soundObj.SoundId
					sound.SoundId = soundObj.SoundId
					sound.PlaybackSpeed = soundObj.PlaybackSpeed
					sound.Volume = soundObj.Volume
					if newId then sound.TimePosition = 0 end
					if not noplay then sound:Resume() end

					coroutine.wrap(function()
						local previewTime = tick()
						Properties.SoundPreviewTime = previewTime
						while previewTime == Properties.SoundPreviewTime and sound.Playing do
							local entry = Properties.GetSoundPreviewEntry()
							if entry then
								local tl = sound.TimeLength
								local perc = sound.TimePosition/(tl == 0 and 1 or tl)
								entry.GuiElems.SoundPreviewSlider.Position = UDim2.new(perc,-4,0,-8)
							end
							Lib.FastWait()
						end
					end)()
					Properties.Refresh()
				end
			end

			Properties.DisplayTagContext = function(prop)
		local context = Properties.TagContext
		if not context then
			context = Lib.ContextMenu.new()
			context.Iconless = true
			context.Width = 80
			Properties.TagContext = context
		end
		context:Clear()

		context:Add({Name = "Edit", OnClick = function()
			Properties.DisplayAddTagWindow(prop)
		end})
		context:Add({Name = "Delete", OnClick = function()
		    local sList = Explorer.Selection.List
			for i = 1, #sList do
				service.CollectionService:RemoveTag(sList[i].Obj, prop.TagName)
			end
			Properties.ShowExplorerProps()
		end})

		context:Show()
	end

	Properties.DisplayAddTagWindow = function(editTag)
		local win = Properties.AddTagWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Add Tag")
			win:SetSize(200,80)

			local saveButton = Lib.Button.new()
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "Tag Name"
			nameLabel.Position = UDim2.new(0,30,0,10)
			nameLabel.Size = UDim2.new(0,40,0,20)
			win:Add(nameLabel)

			local nameBox = Lib.ViewportTextBox.new()
			nameBox.Position = UDim2.new(0,85,0,10)
			nameBox.Size = UDim2.new(0,110,0,20)
			win:Add(nameBox,"NameBox")
			nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				saveButton:SetDisabled(#nameBox:GetText() == 0)
			end)

			local errorLabel = Lib.Label.new()
			errorLabel.Text = ""
			errorLabel.Position = UDim2.new(0,5,1,-45)
			errorLabel.Size = UDim2.new(1,-10,0,20)
			errorLabel.TextColor3 = Settings.Theme.Important
			win.ErrorLabel = errorLabel
			win:Add(errorLabel,"Error")

			local cancelButton = Lib.Button.new()
			cancelButton.Text = "Cancel"
			cancelButton.Position = UDim2.new(1,-97,1,-25)
			cancelButton.Size = UDim2.new(0,92,0,20)
			cancelButton.OnClick:Connect(function()
				win:Close()
			end)
			win:Add(cancelButton)

			saveButton.Text = "Save"
			saveButton.Position = UDim2.new(0,5,1,-25)
			saveButton.Size = UDim2.new(0,92,0,20)
			saveButton.OnClick:Connect(function()
				local name = nameBox:GetText()
				if #name > 100 then
					errorLabel.Text = "Error: Tag over 100 chars"
					return
				end

				local sList = Explorer.Selection.List
				for i = 1, #sList do
					local obj = sList[i].Obj
					if Properties.EditingTag then
						pcall(function() cloneref(game:GetService("CollectionService")):RemoveTag(obj, Properties.EditingTag.TagName) end)
					end
					pcall(function() cloneref(game:GetService("CollectionService")):AddTag(obj, name) end)
				end

				Settings.Properties.ShowTags = true
				pcall(Properties.ShowExplorerProps)
				win:Close()
			end)
			win:Add(saveButton,"SaveButton")

			Properties.AddTagWindow = win
		end

		Properties.EditingTag = editTag
		win:SetTitle(editTag and "Edit Tag" or "Add Tag")
		win.Elements.Error.Text = ""
		win.Elements.NameBox:SetText(editTag and editTag.TagName or "")
		win.Elements.SaveButton:SetDisabled(not editTag)
		win:Show()
	end

			Properties.DisplayAttributeContext = function(prop)
				local context = Properties.AttributeContext
				if not context then
					context = Lib.ContextMenu.new()
					context.Iconless = true
					context.Width = 80
				end
				context:Clear()

				context:Add({Name = "Edit", OnClick = function()
					Properties.DisplayAddAttributeWindow(prop)
				end})
				context:Add({Name = "Delete", OnClick = function()
					Properties.SetProp(prop,nil,true)
					Properties.ShowExplorerProps()
				end})

				context:Show()
			end

			Properties.DisplayAddAttributeWindow = function(editAttr)
				local win = Properties.AddAttributeWindow
				if not win then
					win = Lib.Window.new()
					win.Alignable = false
					win.Resizable = false
					win:SetTitle("Add Attribute")
					win:SetSize(200,130)

					local saveButton = Lib.Button.new()
					local nameLabel = Lib.Label.new()
					nameLabel.Text = "Name"
					nameLabel.Position = UDim2.new(0,30,0,10)
					nameLabel.Size = UDim2.new(0,40,0,20)
					win:Add(nameLabel)

					local nameBox = Lib.ViewportTextBox.new()
					nameBox.Position = UDim2.new(0,75,0,10)
					nameBox.Size = UDim2.new(0,120,0,20)
					win:Add(nameBox,"NameBox")
					nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
						saveButton:SetDisabled(#nameBox:GetText() == 0)
					end)

					local typeLabel = Lib.Label.new()
					typeLabel.Text = "Type"
					typeLabel.Position = UDim2.new(0,30,0,40)
					typeLabel.Size = UDim2.new(0,40,0,20)
					win:Add(typeLabel)

					local typeChooser = Lib.DropDown.new()
					typeChooser.CanBeEmpty = false
					typeChooser.Position = UDim2.new(0,75,0,40)
					typeChooser.Size = UDim2.new(0,120,0,20)
					typeChooser:SetOptions(Properties.AllowedAttributeTypes)
					win:Add(typeChooser,"TypeChooser")

					local errorLabel = Lib.Label.new()
					errorLabel.Text = ""
					errorLabel.Position = UDim2.new(0,5,1,-45)
					errorLabel.Size = UDim2.new(1,-10,0,20)
					errorLabel.TextColor3 = Settings.Theme.Important
					win.ErrorLabel = errorLabel
					win:Add(errorLabel,"Error")

					local cancelButton = Lib.Button.new()
					cancelButton.Text = "Cancel"
					cancelButton.Position = UDim2.new(1,-97,1,-25)
					cancelButton.Size = UDim2.new(0,92,0,20)
					cancelButton.OnClick:Connect(function()
						win:Close()
					end)
					win:Add(cancelButton)

					saveButton.Text = "Save"
					saveButton.Position = UDim2.new(0,5,1,-25)
					saveButton.Size = UDim2.new(0,92,0,20)
					saveButton.OnClick:Connect(function()
						local name = nameBox:GetText()
						if #name > 100 then
							errorLabel.Text = "Error: Name over 100 chars"
							return
						elseif name:sub(1,3) == "RBX" then
							errorLabel.Text = "Error: Name begins with 'RBX'"
							return
						end

						local typ = typeChooser.Selected
						local valType = {Name = Properties.TypeNameConvert[typ] or typ, Category = "DataType"}
						local attrProp = {IsAttribute = true, Name = "ATTR_"..name, AttributeName = name, DisplayName = name, Class = "Instance", ValueType = valType, Category = "Attributes", Tags = {}}

						Settings.Properties.ShowAttributes = true
						Properties.SetProp(attrProp,Properties.DefaultPropValue[valType.Name],true,Properties.EditingAttribute)
						Properties.ShowExplorerProps()
						win:Close()
					end)
					win:Add(saveButton,"SaveButton")

					Properties.AddAttributeWindow = win
				end

				Properties.EditingAttribute = editAttr
				win:SetTitle(editAttr and "Edit Attribute "..editAttr.AttributeName or "Add Attribute")
				win.Elements.Error.Text = ""
				win.Elements.NameBox:SetText("")
				win.Elements.SaveButton:SetDisabled(true)
				win.Elements.TypeChooser:SetSelected(1)
				win:Show()
			end

			Properties.IsTextEditable = function(prop)
				local typeData = prop.ValueType
				local typeName = typeData.Name

				return typeName ~= "bool" and typeData.Category ~= "Enum" and typeData.Category ~= "Class" and typeName ~= "BrickColor"
			end

			Properties.DisplayEnumDropdown = function(entryIndex)
				local context = Properties.EnumContext
				if not context then
					context = Lib.ContextMenu.new()
					context.Iconless = true
					context.MaxHeight = 200
					context.ReverseYOffset = 22
					Properties.EnumDropdown = context
				end

				if not inputProp or inputProp.ValueType.Category ~= "Enum" then return end
				local prop = inputProp

				local entry = propEntries[entryIndex]
				local valueFrame = entry.GuiElems.ValueFrame

				local enum = Enum[prop.ValueType.Name]
				if not enum then return end

				local sorted = {}
				for name,enum in next,enum:GetEnumItems() do
					sorted[#sorted+1] = enum
				end
				table.sort(sorted,function(a,b) return a.Name < b.Name end)

				context:Clear()

				local function onClick(name)
					if prop ~= inputProp then return end

					local enumItem = enum[name]
					inputProp = nil
					Properties.SetProp(prop,enumItem)
				end

				for i = 1,#sorted do
					local enumItem = sorted[i]
					context:Add({Name = enumItem.Name, OnClick = onClick})
				end

				context.Width = valueFrame.AbsoluteSize.X
				context:Show(valueFrame.AbsolutePosition.X, valueFrame.AbsolutePosition.Y + 22)
			end

			Properties.DisplayBrickColorEditor = function(prop,entryIndex,col)
				local editor = Properties.BrickColorEditor
				if not editor then
					editor = Lib.BrickColorPicker.new()
					editor.Gui.DisplayOrder = Main.DisplayOrders.Menu
					editor.ReverseYOffset = 22

					editor.OnSelect:Connect(function(col)
						if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "BrickColor" then return end

						if editor.CurrentProp == inputProp then inputProp = nil end
						Properties.SetProp(editor.CurrentProp,BrickColor.new(col))
					end)

					editor.OnMoreColors:Connect(function() -- TODO: Special Case BasePart.BrickColor to BasePart.Color
						editor:Close()
						local colProp
						for i,v in pairs(API.Classes.BasePart.Properties) do
							if v.Name == "Color" then
								colProp = v
								break
							end
						end
						Properties.DisplayColorEditor(colProp,editor.SavedColor.Color)
					end)

					Properties.BrickColorEditor = editor
				end

				local entry = propEntries[entryIndex]
				local valueFrame = entry.GuiElems.ValueFrame

				editor.CurrentProp = prop
				editor.SavedColor = col
				if prop and prop.Class == "BasePart" and prop.Name == "BrickColor" then
					editor:SetMoreColorsVisible(true)
				else
					editor:SetMoreColorsVisible(false)
				end
				editor:Show(valueFrame.AbsolutePosition.X, valueFrame.AbsolutePosition.Y + 22)
			end

			Properties.DisplayColorEditor = function(prop,col)
				local editor = Properties.ColorEditor
				if not editor then
					editor = Lib.ColorPicker.new()

					editor.OnSelect:Connect(function(col)
						if not editor.CurrentProp then return end
						local typeName = editor.CurrentProp.ValueType.Name
						if typeName ~= "Color3" and typeName ~= "BrickColor" then return end

						local colVal = (typeName == "Color3" and col or BrickColor.new(col))

						if editor.CurrentProp == inputProp then inputProp = nil end
						Properties.SetProp(editor.CurrentProp,colVal)
					end)

					Properties.ColorEditor = editor
				end

				editor.CurrentProp = prop
				if col then
					editor:SetColor(col)
				else
					local firstVal = Properties.GetFirstPropVal(prop)
					if firstVal then editor:SetColor(firstVal) end
				end
				editor:Show()
			end

			Properties.DisplayNumberSequenceEditor = function(prop,seq)
				local editor = Properties.NumberSequenceEditor
				if not editor then
					editor = Lib.NumberSequenceEditor.new()

					editor.OnSelect:Connect(function(val)
						if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "NumberSequence" then return end

						if editor.CurrentProp == inputProp then inputProp = nil end
						Properties.SetProp(editor.CurrentProp,val)
					end)

					Properties.NumberSequenceEditor = editor
				end

				editor.CurrentProp = prop
				if seq then
					editor:SetSequence(seq)
				else
					local firstVal = Properties.GetFirstPropVal(prop)
					if firstVal then editor:SetSequence(firstVal) end
				end
				editor:Show()
			end

			Properties.DisplayColorSequenceEditor = function(prop,seq)
				local editor = Properties.ColorSequenceEditor
				if not editor then
					editor = Lib.ColorSequenceEditor.new()

					editor.OnSelect:Connect(function(val)
						if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "ColorSequence" then return end

						if editor.CurrentProp == inputProp then inputProp = nil end
						Properties.SetProp(editor.CurrentProp,val)
					end)

					Properties.ColorSequenceEditor = editor
				end

				editor.CurrentProp = prop
				if seq then
					editor:SetSequence(seq)
				else
					local firstVal = Properties.GetFirstPropVal(prop)
					if firstVal then editor:SetSequence(firstVal) end
				end
				editor:Show()
			end

			Properties.GetLuaValue = function(propType, val)
		if val == nil then return "nil" end
		local t = typeof(val)
		if t == "string" then
			return string.format("%q", val)
		elseif t == "number" or t == "boolean" then
			return tostring(val)
		elseif t == "EnumItem" then
			return tostring(val)
		elseif t == "Vector3" then
			return string.format("Vector3.new(%f, %f, %f)", val.X, val.Y, val.Z)
		elseif t == "Vector2" then
			return string.format("Vector2.new(%f, %f)", val.X, val.Y)
		elseif t == "CFrame" then
			return "CFrame.new(" .. table.concat({val:GetComponents()}, ", ") .. ")"
		elseif t == "Color3" then
			return string.format("Color3.new(%f, %f, %f)", val.R, val.G, val.B)
		elseif t == "UDim2" then
			return string.format("UDim2.new(%f, %d, %f, %d)", val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset)
		elseif t == "UDim" then
			return string.format("UDim.new(%f, %d)", val.Scale, val.Offset)
		elseif t == "Ray" then
			return string.format("Ray.new(Vector3.new(%f, %f, %f), Vector3.new(%f, %f, %f))", val.Origin.X, val.Origin.Y, val.Origin.Z, val.Direction.X, val.Direction.Y, val.Direction.Z)
		elseif t == "Rect" then
			return string.format("Rect.new(%f, %f, %f, %f)", val.Min.X, val.Min.Y, val.Max.X, val.Max.Y)
		elseif t == "NumberRange" then
			return string.format("NumberRange.new(%f, %f)", val.Min, val.Max)
		elseif t == "PhysicalProperties" then
			return string.format("PhysicalProperties.new(%f, %f, %f, %f, %f)", val.Density, val.Friction, val.Elasticity, val.FrictionWeight, val.ElasticityWeight)
		elseif t == "Instance" then
			return Explorer.GetInstancePath(val)
		else
			return tostring(val)
		end
	end

			Properties.GetFirstPropVal = function(prop)
				local first = Properties.FindFirstObjWhichIsA(prop.Class)
				if first then
					return Properties.GetPropVal(prop,first)
				end
			end

			Properties.GetPropVal = function(prop,obj)
				if prop.MultiType then return "<Multiple Types>" end
				if not obj then return end

				local propVal
				if prop.IsAttribute then
					propVal = getAttribute(obj,prop.AttributeName)
					if propVal == nil then return nil end

					local typ = typeof(propVal)
					local currentType = Properties.TypeNameConvert[typ] or typ
					if prop.RootType then
						if prop.RootType.Name ~= currentType then return nil end
					elseif prop.ValueType.Name ~= currentType then
						return nil
					end
				elseif prop.IsTag then
					return ""
				else
					local s, val = pcall(function() return obj[prop.Name] end)
					if s then
						propVal = val
					else
						if env.gethiddenproperty then
							local hs, hval = pcall(env.gethiddenproperty, obj, prop.Name)
							if hs then propVal = hval end
						elseif env.isscriptable and env.setscriptable then
							local is_s, is_scriptable = pcall(env.isscriptable, obj, prop.Name)
							if is_s and not is_scriptable then
								local was_scriptable = env.setscriptable(obj, prop.Name, true)
								pcall(function() propVal = obj[prop.Name] end)
								pcall(env.setscriptable, obj, prop.Name, was_scriptable)
							end
						end
					end
				end

				if prop.SubName then
					local indexes = string.split(prop.SubName,".")
					for i = 1,#indexes do
						local indexName = indexes[i]
						if #indexName > 0 and propVal then
							propVal = propVal[indexName]
						end
					end
				end

				return propVal
			end

			Properties.SelectObject = function(obj)
				if inputProp and inputProp.ValueType.Category == "Class" then
					local prop = inputProp
					inputProp = nil

					if isa(obj,prop.ValueType.Name) then
						Properties.SetProp(prop,obj)
					else
						Properties.Refresh()
					end

					return true
				end

				return false
			end

			Properties.DisplayProp = function(prop,entryIndex)
				local propName = prop.Name
				local typeData = prop.ValueType
				local typeName = typeData.Name
				local tags = prop.Tags
				local gName = prop.Class.."."..prop.Name..(prop.SubName or "")
				local propObj = autoUpdateObjs[gName]
				local entryData = propEntries[entryIndex]
				local UDim2 = UDim2

				local guiElems = entryData.GuiElems
				local valueFrame = guiElems.ValueFrame
				local valueBox = guiElems.ValueBox
				local colorButton = guiElems.ColorButton
				local colorPreview = guiElems.ColorPreview
				local gradient = guiElems.Gradient
				local enumArrow = guiElems.EnumArrow
				local checkbox = guiElems.Checkbox
				local rightButton = guiElems.RightButton
				local soundPreview = guiElems.SoundPreview

				local propVal = Properties.GetPropVal(prop,propObj)
				local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))

				local offset = 4
				local endOffset = 6

				-- Offsetting the ValueBox for ValueType specific buttons
				if (typeName == "Color3" or typeName == "BrickColor" or typeName == "ColorSequence") then
					colorButton.Visible = true
					enumArrow.Visible = false
					if propVal then
						gradient.Color = (typeName == "Color3" and ColorSequence.new(propVal)) or (typeName == "BrickColor" and ColorSequence.new(propVal.Color)) or propVal
					else
						gradient.Color = ColorSequence.new(Color3.new(1,1,1))
					end
					colorPreview.BorderColor3 = (typeName == "ColorSequence" and Color3.new(1,1,1) or Color3.new(0,0,0))
					offset = 22
					endOffset = 24 + (typeName == "ColorSequence" and 20 or 0)
				elseif typeData.Category == "Enum" then
					colorButton.Visible = false
					enumArrow.Visible = not prop.Tags.ReadOnly
					endOffset = 22
				elseif (gName == inputFullName and typeData.Category == "Class") or typeName == "NumberSequence" then
					colorButton.Visible = false
					enumArrow.Visible = false
					endOffset = 26
				else
					colorButton.Visible = false
					enumArrow.Visible = false
				end

				valueBox.Position = UDim2.new(0,offset,0,0)
				valueBox.Size = UDim2.new(1,-endOffset,1,0)

				-- Right button
				if inputFullName == gName and typeData.Category == "Class" then
					Main.MiscIcons:DisplayByKey(guiElems.RightButtonIcon, "Delete")
					guiElems.RightButtonIcon.Visible = true
					rightButton.Text = ""
					rightButton.Visible = true
				elseif typeName == "NumberSequence" or typeName == "ColorSequence" then
					guiElems.RightButtonIcon.Visible = false
					rightButton.Text = "..."
					rightButton.Visible = true
				else
					rightButton.Visible = false
				end
			
				local CopyBtn = guiElems.CopyButton
		if CopyBtn then
			if Settings.Properties.ShowCopyButton then
				CopyBtn.Visible = true
CopyBtn.Icon.Image = (getcustomasset and isfile and isfile("DEX_REContinued/content_copy_1000dp_FFFFFF_FILL0_wght400_GRAD0_op.png")) and getcustomasset("DEX_REContinued/content_copy_1000dp_FFFFFF_FILL0_wght400_GRAD0_op.png") or 'rbxassetid://82111472977628'
			CopyBtn.Icon.ImageTransparency = 0.01
				CopyBtn.Position = UDim2.new(1, -endOffset - 20, 0, 0)
				endOffset = endOffset + 20
			else
				CopyBtn.Visible = false
			end
		end

		valueBox.Position = UDim2.new(0,offset,0,0)
		valueBox.Size = UDim2.new(1,-endOffset,1,0)

				if typeName == "bool" or typeName == "PhysicalProperties" then
					valueBox.Visible = false
					checkbox.Visible = true
					soundPreview.Visible = false
					checkboxes[entryIndex].Disabled = tags.ReadOnly
					if typeName == "PhysicalProperties" and autoUpdateObjs[gName] then
						checkboxes[entryIndex]:SetState(propVal and true or false)
					else
						checkboxes[entryIndex]:SetState(propVal)
					end
				elseif typeName == "SoundPlayer" then
					valueBox.Visible = false
					checkbox.Visible = false
					soundPreview.Visible = true
					local playing = Properties.PreviewSound and Properties.PreviewSound.Playing
					Main.MiscIcons:DisplayByKey(soundPreview.ControlButton.Icon, playing and "Pause" or "Play")
				else
					valueBox.Visible = true
					checkbox.Visible = false
					soundPreview.Visible = false

					if propVal ~= nil then
						if typeName == "Color3" then
							valueBox.Text = "["..Lib.ColorToBytes(propVal).."]"
						elseif typeData.Category == "Enum" then
							if typeof(propVal) == "EnumItem" then
								valueBox.Text = propVal.Name
							else
								local s, enumData = pcall(function() return Enum[typeName] end)
								if s and enumData then
									local found = false
									for _, item in pairs(enumData:GetEnumItems()) do
										if item.Value == propVal or item.Name == propVal then
											valueBox.Text = item.Name
											found = true
											break
										end
									end
									if not found then valueBox.Text = tostring(propVal) end
								else
									valueBox.Text = tostring(propVal)
								end
							end
						elseif Properties.RoundableTypes[typeName] and Settings.Properties.NumberRounding then
							local rawStr = Properties.ValueToString(prop,propVal)
							valueBox.Text = rawStr:gsub("-?%d+%.%d+",function(num)
								return tostring(tonumber(("%."..Settings.Properties.NumberRounding.."f"):format(num)))
							end)
						else
							valueBox.Text = Properties.ValueToString(prop,propVal)
						end
					else
						valueBox.Text = ""
					end

					valueBox.TextColor3 = tags.ReadOnly and Settings.Theme.PlaceholderText or Settings.Theme.Text
				end
			end

			Properties.Refresh = function()
				local maxEntries = math.max(math.ceil((propsFrame.AbsoluteSize.Y) / 23),0)	
				local maxX = propsFrame.AbsoluteSize.X
				local valueWidth = math.max(Properties.MinInputWidth,maxX-Properties.ViewWidth)
				local inputPropVisible = false
				local isa = game.IsA
				local UDim2 = UDim2
				local stringSplit = string.split
				local scaleType = Settings.Properties.ScaleType

				-- Clear connections
				for i = 1,#propCons do
					propCons[i]:Disconnect()
				end
				table.clear(propCons)

				-- Hide full name viewer
				Properties.FullNameFrame.Visible = false
				Properties.FullNameFrameAttach.Disable()

				for i = 1,maxEntries do
					local entryData = propEntries[i]
					if not propEntries[i] then entryData = Properties.NewPropEntry(i) propEntries[i] = entryData end

					local entry = entryData.Gui
					local guiElems = entryData.GuiElems
					local nameFrame = guiElems.NameFrame
					local propNameLabel = guiElems.PropName
					local valueFrame = guiElems.ValueFrame
					local expand = guiElems.Expand
					local valueBox = guiElems.ValueBox
					local propNameBox = guiElems.PropName
					local rightButton = guiElems.RightButton
					local editAttributeButton = guiElems.EditAttributeButton
					local toggleAttributes = guiElems.ToggleAttributes

					local prop = viewList[i + Properties.Index]
					if prop then
						local entryXOffset = (scaleType == 0 and scrollH.Index or 0)
						entry.Visible = true
						entry.Position = UDim2.new(0,-entryXOffset,0,entry.Position.Y.Offset)
						entry.Size = UDim2.new(scaleType == 0 and 0 or 1, scaleType == 0 and Properties.ViewWidth + valueWidth or 0,0,22)

						if prop.SpecialRow then
							if prop.SpecialRow == "AddAttribute" then
							nameFrame.Visible = false
							valueFrame.Visible = false
							guiElems.RowButton.Visible = true
							guiElems.RowButton.Text = "Add Attribute"
						elseif prop.SpecialRow == "AddTag" then
							nameFrame.Visible = false
							valueFrame.Visible = false
							guiElems.RowButton.Visible = true
							guiElems.RowButton.Text = "Add Tag"
						end
						else
							-- Revert special row stuff
							nameFrame.Visible = true
							guiElems.RowButton.Visible = false

							local depth = Properties.EntryIndent*(prop.Depth or 1)
							local leftOffset = depth + Properties.EntryOffset
							nameFrame.Position = UDim2.new(0,leftOffset,0,0)
							propNameLabel.Size = UDim2.new(1,-2 - (scaleType == 0 and 0 or 6),1,0)

							local gName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")

							if prop.CategoryName then
						entry.BackgroundColor3 = Settings.Theme.Main1
						entry.BackgroundTransparency = (Settings.Window.Transparency and Settings.Window.Transparency > 0) and 0.75 or 0
						valueFrame.Visible = false

						propNameBox.Text = prop.CategoryName
						propNameBox.Font = Enum.Font.SourceSansBold
						expand.Visible = true
						propNameBox.TextColor3 = Settings.Theme.Text
						nameFrame.BackgroundTransparency = 1
						nameFrame.Size = UDim2.new(1,0,1,0)
						editAttributeButton.Visible = false

						local showingAttrs = Settings.Properties.ShowAttributes
						toggleAttributes.Position = UDim2.new(1,-85-leftOffset,0,0)
						toggleAttributes.Text = (showingAttrs and "[Setting: ON]" or "[Setting: OFF]")
						toggleAttributes.TextColor3 = Settings.Theme.Text
						toggleAttributes.Visible = (prop.CategoryName == "Attributes")
					else
						local propName = prop.Name
						local typeData = prop.ValueType
						local typeName = typeData.Name
						local tags = prop.Tags
						local propObj = autoUpdateObjs[gName]

						local attributeOffset = ((prop.IsAttribute or prop.IsTag) and 20 or 0)
						editAttributeButton.Visible = ((prop.IsAttribute or prop.IsTag) and not prop.RootType)
						toggleAttributes.Visible = false

						if scaleType == 0 then
							nameFrame.Size = UDim2.new(0,Properties.ViewWidth - leftOffset - 1,1,0)
							valueFrame.Position = UDim2.new(0,Properties.ViewWidth,0,0)
							valueFrame.Size = UDim2.new(0,valueWidth - attributeOffset,1,0)
						else
							nameFrame.Size = UDim2.new(0.5,-leftOffset - 1,1,0)
							valueFrame.Position = UDim2.new(0.5,0,0,0)
							valueFrame.Size = UDim2.new(0.5,-attributeOffset,1,0)
						end

						local nameArr = stringSplit(gName,".")
						propNameBox.Text = prop.DisplayName or nameArr[#nameArr]
						propNameBox.Font = Enum.Font.SourceSans
						entry.BackgroundColor3 = Settings.Theme.Main2
						entry.BackgroundTransparency = (Settings.Window.Transparency and Settings.Window.Transparency > 0) and 0.75 or 0
						valueFrame.Visible = true

								expand.Visible = typeData.Category == "DataType" and Properties.ExpandableTypes[typeName] or Properties.ExpandableProps[gName]
								propNameBox.TextColor3 = tags.ReadOnly and Settings.Theme.PlaceholderText or Settings.Theme.Text

								Properties.DisplayProp(prop,i)
								if propObj then
									if prop.IsAttribute then
										propCons[#propCons+1] = getAttributeChangedSignal(propObj,prop.AttributeName):Connect(function()
											Properties.DisplayProp(prop,i)
										end)
									elseif prop.IsCustom or prop.IsTag then
									else
										pcall(function()
											propCons[#propCons+1] = getPropChangedSignal(propObj,propName):Connect(function()
												Properties.DisplayProp(prop,i)
											end)
										end)
									end
								end
								local beforeVisible = valueBox.Visible
								local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))
								if gName == inputFullName then
									nameFrame.BackgroundColor3 = Settings.Theme.ListSelection
									nameFrame.BackgroundTransparency = 0
									if typeData.Category == "Class" or typeData.Category == "Enum" or typeName == "BrickColor" then
										valueFrame.BackgroundColor3 = Settings.Theme.TextBox
										valueFrame.BackgroundTransparency = 0
										valueBox.Visible = true
									else
										inputPropVisible = true
										local scale = (scaleType == 0 and 0 or 0.5)
										local offset = (scaleType == 0 and Properties.ViewWidth-scrollH.Index or 0)
										local endOffset = 0

										if typeName == "Color3" or typeName == "ColorSequence" then
											offset = offset + 22
										end

										if typeName == "NumberSequence" or typeName == "ColorSequence" then
											endOffset = 20
										end
										if Settings.Properties.ShowCopyButton then
										endOffset = endOffset + 20 end
										inputBox.Position = UDim2.new(scale,offset,0,entry.Position.Y.Offset)
										inputBox.Size = UDim2.new(1-scale,-offset-endOffset-attributeOffset,0,22)
										inputBox.Visible = true
										valueBox.Visible = false
									end
								else
									nameFrame.BackgroundColor3 = Settings.Theme.Main1
									nameFrame.BackgroundTransparency = 1
									valueFrame.BackgroundColor3 = Settings.Theme.Main1
									valueFrame.BackgroundTransparency = 1
									valueBox.Visible = beforeVisible
								end
							end

							-- Expand
							if prop.CategoryName or Properties.ExpandableTypes[prop.ValueType and prop.ValueType.Name] or Properties.ExpandableProps[gName] then
								if Lib.CheckMouseInGui(expand) then
									Main.MiscIcons:DisplayByKey(expand.Icon, expanded[gName] and "Collapse_Over" or "Expand_Over")
								else
									Main.MiscIcons:DisplayByKey(expand.Icon, expanded[gName] and "Collapse" or "Expand")
								end
								expand.Visible = true
							else
								expand.Visible = false
							end
						end
						entry.Visible = true
					else
						entry.Visible = false
					end
				end

				if not inputPropVisible then
					inputBox.Visible = false
				end

				for i = maxEntries+1,#propEntries do
					propEntries[i].Gui:Destroy()
					propEntries[i] = nil
					checkboxes[i] = nil
				end
			end

			Properties.SetProp = function(prop,val,noupdate,prevAttribute)
				local sList = Explorer.Selection.List
				local propName = prop.Name
				local subName = prop.SubName
				local propClass = prop.Class
				local typeData = prop.ValueType
				local typeName = typeData.Name
				local attributeName = prop.AttributeName
				local rootTypeData = prop.RootType
				local rootTypeName = rootTypeData and rootTypeData.Name
				local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
				local Vector3 = Vector3

				for i = 1,#sList do
					local node = sList[i]
					local obj = node.Obj

					if isa(obj,propClass) then
						pcall(function()
							local setVal = val
							local root
							if prop.IsAttribute then
								root = getAttribute(obj,attributeName)
							else
								local s, val_res = pcall(function() return obj[propName] end)
								if s then
									root = val_res
								else
									if env.gethiddenproperty then
										local hs, hval = pcall(env.gethiddenproperty, obj, propName)
										if hs then root = hval end
									elseif env.isscriptable and env.setscriptable then
										local is_s, is_scriptable = pcall(env.isscriptable, obj, propName)
										if is_s and not is_scriptable then
											local was_scriptable = env.setscriptable(obj, propName, true)
											pcall(function() root = obj[propName] end)
											pcall(env.setscriptable, obj, propName, was_scriptable)
										end
									end
								end
							end

							if prevAttribute then
								if prevAttribute.ValueType.Name == typeName then
									setVal = getAttribute(obj,prevAttribute.AttributeName) or setVal
								end
								setAttribute(obj,prevAttribute.AttributeName,nil)
							end

							if rootTypeName then
								if rootTypeName == "Vector2" then
									setVal = Vector2.new((subName == ".X" and setVal) or root.X, (subName == ".Y" and setVal) or root.Y)
								elseif rootTypeName == "Vector3" then
									setVal = Vector3.new((subName == ".X" and setVal) or root.X, (subName == ".Y" and setVal) or root.Y, (subName == ".Z" and setVal) or root.Z)
								elseif rootTypeName == "UDim" then
									setVal = UDim.new((subName == ".Scale" and setVal) or root.Scale, (subName == ".Offset" and setVal) or root.Offset)
								elseif rootTypeName == "UDim2" then
									local rootX,rootY = root.X,root.Y
									local X_UDim = (subName == ".X" and setVal) or UDim.new((subName == ".X.Scale" and setVal) or rootX.Scale, (subName == ".X.Offset" and setVal) or rootX.Offset)
									local Y_UDim = (subName == ".Y" and setVal) or UDim.new((subName == ".Y.Scale" and setVal) or rootY.Scale, (subName == ".Y.Offset" and setVal) or rootY.Offset)
									setVal = UDim2.new(X_UDim,Y_UDim)
								elseif rootTypeName == "CFrame" then
									local rootPos,rootRight,rootUp,rootLook = root.Position,root.RightVector,root.UpVector,root.LookVector
									local pos = (subName == ".Position" and setVal) or Vector3.new((subName == ".Position.X" and setVal) or rootPos.X, (subName == ".Position.Y" and setVal) or rootPos.Y, (subName == ".Position.Z" and setVal) or rootPos.Z)
									local rightV = (subName == ".RightVector" and setVal) or Vector3.new((subName == ".RightVector.X" and setVal) or rootRight.X, (subName == ".RightVector.Y" and setVal) or rootRight.Y, (subName == ".RightVector.Z" and setVal) or rootRight.Z)
									local upV = (subName == ".UpVector" and setVal) or Vector3.new((subName == ".UpVector.X" and setVal) or rootUp.X, (subName == ".UpVector.Y" and setVal) or rootUp.Y, (subName == ".UpVector.Z" and setVal) or rootUp.Z)
									local lookV = (subName == ".LookVector" and setVal) or Vector3.new((subName == ".LookVector.X" and setVal) or rootLook.X, (subName == ".RightVector.Y" and setVal) or rootLook.Y, (subName == ".RightVector.Z" and setVal) or rootLook.Z)
									setVal = CFrame.fromMatrix(pos,rightV,upV,-lookV)
								elseif rootTypeName == "Rect" then
									local rootMin,rootMax = root.Min,root.Max
									local min = Vector2.new((subName == ".Min.X" and setVal) or rootMin.X, (subName == ".Min.Y" and setVal) or rootMin.Y)
									local max = Vector2.new((subName == ".Max.X" and setVal) or rootMax.X, (subName == ".Max.Y" and setVal) or rootMax.Y)
									setVal = Rect.new(min,max)
								elseif rootTypeName == "PhysicalProperties" then
									local rootProps = PhysicalProperties.new(obj.Material)
									local density = (subName == ".Density" and setVal) or (root and root.Density) or rootProps.Density
									local friction = (subName == ".Friction" and setVal) or (root and root.Friction) or rootProps.Friction
									local elasticity = (subName == ".Elasticity" and setVal) or (root and root.Elasticity) or rootProps.Elasticity
									local frictionWeight = (subName == ".FrictionWeight" and setVal) or (root and root.FrictionWeight) or rootProps.FrictionWeight
									local elasticityWeight = (subName == ".ElasticityWeight" and setVal) or (root and root.ElasticityWeight) or rootProps.ElasticityWeight
									setVal = PhysicalProperties.new(density,friction,elasticity,frictionWeight,elasticityWeight)
								elseif rootTypeName == "Ray" then
									local rootOrigin,rootDirection = root.Origin,root.Direction
									local origin = (subName == ".Origin" and setVal) or Vector3.new((subName == ".Origin.X" and setVal) or rootOrigin.X, (subName == ".Origin.Y" and setVal) or rootOrigin.Y, (subName == ".Origin.Z" and setVal) or rootOrigin.Z)
									local direction = (subName == ".Direction" and setVal) or Vector3.new((subName == ".Direction.X" and setVal) or rootDirection.X, (subName == ".Direction.Y" and setVal) or rootDirection.Y, (subName == ".Direction.Z" and setVal) or rootDirection.Z)
									setVal = Ray.new(origin,direction)
								elseif rootTypeName == "Faces" then
									local faces = {}
									local faceList = {"Back","Bottom","Front","Left","Right","Top"}
									for _,face in pairs(faceList) do
										local val
										if subName == "."..face then
											val = setVal
										else
											val = root[face]
										end
										if val then faces[#faces+1] = Enum.NormalId[face] end
									end
									setVal = Faces.new(unpack(faces))
								elseif rootTypeName == "Axes" then
									local axes = {}
									local axesList = {"X","Y","Z"}
									for _,axe in pairs(axesList) do
										local val
										if subName == "."..axe then
											val = setVal
										else
											val = root[axe]
										end
										if val then axes[#axes+1] = Enum.Axis[axe] end
									end
									setVal = Axes.new(unpack(axes))
								elseif rootTypeName == "NumberRange" then
									setVal = NumberRange.new(subName == ".Min" and setVal or root.Min, subName == ".Max" and setVal or root.Max)
								end
							end

							if typeName == "PhysicalProperties" and setVal then
								setVal = root or PhysicalProperties.new(obj.Material)
							end

							if prop.IsAttribute then
								setAttribute(obj,attributeName,setVal)
							elseif not prop.IsTag then
								local set_s, set_e = false, nil
								
								if env.sethiddenproperty then
									set_s, set_e = pcall(env.sethiddenproperty, obj, propName, setVal)
								end
								
								if not set_s then
									set_s, set_e = pcall(function() obj[propName] = setVal end)
								end
								
								if not set_s and env.isscriptable and env.setscriptable then
									local is_s, is_scriptable = pcall(env.isscriptable, obj, propName)
									if is_s and not is_scriptable then
										local was_scriptable = env.setscriptable(obj, propName, true)
										pcall(function() obj[propName] = setVal end)
										pcall(env.setscriptable, obj, propName, was_scriptable)
									end
								end
							end
						end)
					end
				end

				if not noupdate then
					Properties.ComputeConflicts(prop)
				end
			end

			Properties.InitInputBox = function()
				inputBox = create({
					{1,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderSizePixel=0,Name="InputBox",Size=UDim2.new(0,200,0,22),Visible=false,ZIndex=2,}},
					{2,"TextBox",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BackgroundTransparency=1,BorderColor3=Color3.new(0.062745101749897,0.51764708757401,1),BorderSizePixel=0,ClearTextOnFocus=false,Font=3,Parent={1},PlaceholderColor3=Color3.new(0.69803923368454,0.69803923368454,0.69803923368454),Position=UDim2.new(0,3,0,0),Size=UDim2.new(1,-6,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,ZIndex=2,}},
				})
				inputTextBox = inputBox.TextBox
				inputBox.BackgroundColor3 = Settings.Theme.TextBox
				inputBox.Parent = Properties.Window.GuiElems.Content.List

				inputTextBox.FocusLost:Connect(function()
					if not inputProp then return end

					local prop = inputProp
					inputProp = nil
					local val = Properties.StringToValue(prop,inputTextBox.Text)
					if val then Properties.SetProp(prop,val) else Properties.Refresh() end
				end)

				inputTextBox.Focused:Connect(function()
					inputTextBox.SelectionStart = 1
					inputTextBox.CursorPosition = #inputTextBox.Text + 1
				end)

				Lib.ViewportTextBox.convert(inputTextBox)
			end

			Properties.SetInputProp = function(prop,entryIndex,special)
				local typeData = prop.ValueType
				local typeName = typeData.Name
				local fullName = prop.Class.."."..prop.Name..(prop.SubName or "")
				local propObj = autoUpdateObjs[fullName]
				local propVal = Properties.GetPropVal(prop,propObj)

				if prop.Tags.ReadOnly then return end

				inputProp = prop
				if special then
					if special == "color" then
						if typeName == "Color3" then
							inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
							Properties.DisplayColorEditor(prop,propVal)
						elseif typeName == "BrickColor" then
							Properties.DisplayBrickColorEditor(prop,entryIndex,propVal)
						elseif typeName == "ColorSequence" then
							inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
							Properties.DisplayColorSequenceEditor(prop,propVal)
						end
					elseif special == "right" then
						if typeName == "NumberSequence" then
							inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
							Properties.DisplayNumberSequenceEditor(prop,propVal)
						elseif typeName == "ColorSequence" then
							inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
							Properties.DisplayColorSequenceEditor(prop,propVal)
						end
					end
				else
					if Properties.IsTextEditable(prop) then
						inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
						inputTextBox:CaptureFocus()
					elseif typeData.Category == "Enum" then
						Properties.DisplayEnumDropdown(entryIndex)
					elseif typeName == "BrickColor" then
						Properties.DisplayBrickColorEditor(prop,entryIndex,propVal)
					end
				end
				Properties.Refresh()
			end

			Properties.InitSearch = function()
				local TweenService = service.TweenService
				local SearchFrame = Properties.GuiElems.ToolBar.SearchFrame
				local searchBox = SearchFrame.SearchBox

				local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint)

				local Tweens = {
					Start = TweenService:Create(SearchFrame.UIStroke, TweenInfo, { Color = Color3.fromRGB(0, 120, 215) }),
					End = TweenService:Create(SearchFrame.UIStroke, TweenInfo, { Color = Color3.fromRGB(42, 42, 42) })
				}

				Lib.ViewportTextBox.convert(searchBox)

				searchBox.FocusLost:Connect(function() Tweens.End:Play() end)
				searchBox.Focused:Connect(function() Tweens.Start:Play() end)

				searchBox:GetPropertyChangedSignal("Text"):Connect(function()
					Properties.SearchText = searchBox.Text
					Properties.Update()
					Properties.Refresh()
				end)
			end

			Properties.InitEntryStuff = function()
				Properties.EntryTemplate = create({
					{1,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),Font=3,Name="Entry",Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,250,0,22),Text="",TextSize=14,}},
					{2,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Name="NameFrame",Parent={1},Position=UDim2.new(0,20,0,0),Size=UDim2.new(1,-40,1,0),}},
					{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="PropName",Parent={2},Position=UDim2.new(0,2,0,0),Size=UDim2.new(1,-2,1,0),Text="Anchored",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextXAlignment=0,}},
					{4,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Font=3,Name="Expand",Parent={2},Position=UDim2.new(0,-20,0,1),Size=UDim2.new(0,20,0,20),Text="",TextSize=14,Visible=false,}},
					{5,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image= (getcustomasset and isfile and isfile("DEX_REContinued/Images/Test_Icons.png")) and getcustomasset("DEX_REContinued/Images/Test_Icons.png") or "rbxassetid://5642383285",ImageRectOffset=Vector2.new(144,16),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={4},Position=UDim2.new(0,2,0,2),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
					{6,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=4,Name="ToggleAttributes",Parent={2},Position=UDim2.new(1,-85,0,0),Size=UDim2.new(0,85,0,22),Text="[SETTING: OFF]",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,Visible=false,}},
					{7,"Frame",{BackgroundColor3=Color3.new(0.04313725605607,0.35294118523598,0.68627452850342),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019607901573,0.73725491762161),BorderSizePixel=0,Name="ValueFrame",Parent={1},Position=UDim2.new(1,-100,0,0),Size=UDim2.new(0,80,1,0),}},
					{8,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Name="Line",Parent={7},Position=UDim2.new(0,-1,0,0),Size=UDim2.new(0,1,1,0),}},
					{9,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="ColorButton",Parent={7},Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
					{10,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0,0,0),Name="ColorPreview",Parent={9},Position=UDim2.new(0,5,0,6),Size=UDim2.new(0,10,0,10),}},
					{11,"UIGradient",{Parent={10},}},
					{12,"Frame",{BackgroundTransparency=1,Name="EnumArrow",Parent={7},Position=UDim2.new(1,-16,0,3),Size=UDim2.new(0,16,0,16),Visible=false,}},
					{13,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={12},Position=UDim2.new(0,8,0,9),Size=UDim2.new(0,1,0,1),}},
					{14,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={12},Position=UDim2.new(0,7,0,8),Size=UDim2.new(0,3,0,1),}},
					{15,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={12},Position=UDim2.new(0,6,0,7),Size=UDim2.new(0,5,0,1),}},
					{16,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="ValueBox",Parent={7},Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-8,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextXAlignment=0,}},
					{17,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="RightButton",Parent={7},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,22),Text="...",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
					{18,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="SettingsButton",Parent={7},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
					{19,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="SoundPreview",Parent={7},Size=UDim2.new(1,0,1,0),Visible=false,}},
					{20,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="ControlButton",Parent={19},Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
					{21,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/Test_Icons.png")) and getcustomasset("DEX_REContinued/Images/Test_Icons.png") or "rbxassetid://5642383285",ImageRectOffset=Vector2.new(144,16),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={20},Position=UDim2.new(0,2,0,3),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
					{22,"Frame",{BackgroundColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BorderSizePixel=0,Name="TimeLine",Parent={19},Position=UDim2.new(0,26,0.5,-1),Size=UDim2.new(1,-34,0,2),}},
					{23,"Frame",{BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),Name="Slider",Parent={22},Position=UDim2.new(0,-4,0,-8),Size=UDim2.new(0,8,0,18),}},
					{24,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="EditAttributeButton",Parent={1},Position=UDim2.new(1,-20,0,0),Size=UDim2.new(0,20,0,22),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
					{25,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/settings2.png")) and getcustomasset("DEX_REContinued/Images/settings2.png") or "rbxassetid://5034718180",ImageTransparency=0.20000000298023,Name="Icon",Parent={24},Position=UDim2.new(0,2,0,3),Size=UDim2.new(0,16,0,16),}},
					{26,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderSizePixel=0,Font=3,Name="RowButton",Parent={1},Size=UDim2.new(1,0,1,0),Text="Add Attribute",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,Visible=false,}},
					{27,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="CopyButton",Parent={7},Position=UDim2.new(1,-40,0,0),Size=UDim2.new(0,20,0,22),Text="",TextSize=14,Visible=false,}},
					{28,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Icon",Parent={27},Position=UDim2.new(0,2,0,3),Size=UDim2.new(0,16,0,16),}},
				})

				local fullNameFrame = Lib.Frame.new()
				local label = Lib.Label.new()
				label.Parent = fullNameFrame.Gui
				label.Position = UDim2.new(0,2,0,0)
				label.Size = UDim2.new(1,-4,1,0)
				fullNameFrame.Visible = false
				fullNameFrame.Parent = window.Gui

				Properties.FullNameFrame = fullNameFrame
				Properties.FullNameFrameAttach = Lib.AttachTo(fullNameFrame)
			end

			Properties.Init = function() -- TODO: MAKE BETTER
				local guiItems = create({
					{1,"Folder",{Name="Items",}},
					{2,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ToolBar",Parent={1},Size=UDim2.new(1,0,0,22),}},
					{3,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.1176470592618,0.1176470592618,0.1176470592618),BorderSizePixel=0,Name="SearchFrame",Parent={2},Position=UDim2.new(0,3,0,1),Size=UDim2.new(1,-6,0,18),}},
					{4,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClearTextOnFocus=false,Font=3,Name="SearchBox",Parent={3},PlaceholderColor3=Color3.new(0.39215689897537,0.39215689897537,0.39215689897537),PlaceholderText="Search properties",Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-24,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
					{5,"UICorner",{CornerRadius=UDim.new(0,2),Parent={3},}},
					{6,"UIStroke",{Thickness=1.4,Parent={3},Color=Color3.fromRGB(42,42,42)}},
					{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Reset",Parent={3},Position=UDim2.new(1,-17,0,1),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
					{8,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/search2.png")) and getcustomasset("DEX_REContinued/Images/search2.png") or "rbxassetid://5034718129",ImageColor3=Color3.new(0.39215686917305,0.39215686917305,0.39215686917305),Parent={7},Size=UDim2.new(0,16,0,16),}},
					{9,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Refresh",Parent={2},Position=UDim2.new(1,-20,0,1),Size=UDim2.new(0,18,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,Visible=false,}},
					{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344",Parent={9},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,12,0,12),}},
					{11,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="ScrollCorner",Parent={1},Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,16,0,16),Visible=false,}},
					{12,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ClipsDescendants=true,Name="List",Parent={1},Position=UDim2.new(0,0,0,23),Size=UDim2.new(1,0,1,-23),}},
				})

				-- Vars
				categoryOrder =	API.CategoryOrder
				for category,_ in next,categoryOrder do
					if not Properties.CollapsedCategories[category] then
						expanded["CAT_"..category] = true
					end
				end
				expanded["Sound.SoundId"] = true

				-- Init window
				window = Lib.Window.new()
				Properties.Window = window
				window:SetTitle("Properties")

				toolBar = guiItems.ToolBar
				propsFrame = guiItems.List

				Properties.GuiElems.ToolBar = toolBar
				Properties.GuiElems.PropsFrame = propsFrame

				Properties.InitEntryStuff()

				-- Window events
				window.GuiElems.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					if Properties.Window:IsContentVisible() then
						Properties.UpdateView()
						Properties.Refresh()
					end
				end)
				window.OnActivate:Connect(function()
					Properties.UpdateView()
					Properties.Update()
					Properties.Refresh()
				end)
				window.OnRestore:Connect(function()
					Properties.UpdateView()
					Properties.Update()
					Properties.Refresh()
				end)

				-- Init scrollbars
				scrollV = Lib.ScrollBar.new()		
				scrollV.WheelIncrement = 3
				scrollV.Gui.Position = UDim2.new(1,-16,0,23)
				scrollV:SetScrollFrame(propsFrame)
				scrollV.Scrolled:Connect(function()
					Properties.Index = scrollV.Index
					Properties.Refresh()
				end)

				scrollH = Lib.ScrollBar.new(true)
				scrollH.Increment = 5
				scrollH.WheelIncrement = 20
				scrollH.Gui.Position = UDim2.new(0,0,1,-16)
				scrollH.Scrolled:Connect(function()
					Properties.Refresh()
				end)

				-- Setup Gui
				window.GuiElems.Line.Position = UDim2.new(0,0,0,22)
				toolBar.Parent = window.GuiElems.Content
				propsFrame.Parent = window.GuiElems.Content
				guiItems.ScrollCorner.Parent = window.GuiElems.Content
				scrollV.Gui.Parent = window.GuiElems.Content
				scrollH.Gui.Parent = window.GuiElems.Content
				Properties.InitInputBox()
				Properties.InitSearch()

				-- to see stuff updating
				coroutine.wrap(function()
					while true do
						Lib.FastWait(0.1)
						if Properties.Window and Properties.Window:IsContentVisible() then
							local maxEntries = math.max(math.ceil((propsFrame.AbsoluteSize.Y) / 23),0)
							for i = 1, maxEntries do
								local prop = viewList[i + Properties.Index]
								if prop then
									local gName = (prop.CategoryName and "CAT_"..prop.CategoryName) or prop.Class.."."..prop.Name..(prop.SubName or "")
									local propObj = autoUpdateObjs[gName]
									local inputFullName = inputProp and (inputProp.Class.."."..inputProp.Name..(inputProp.SubName or ""))
									if propObj and inputFullName ~= gName then
										Properties.DisplayProp(prop, i)
									end
								end
							end
						end
					end
				end)()
			end

			return Properties
		end

		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,

["ScriptViewer"] = function()
--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]
-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook, SaveInstance -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
	SaveInstance = Apps.SaveInstance
end

local executorName = "Unknown"
local executorVersion = "???"
if identifyexecutor then
	local name,ver = identifyexecutor()
	executorName = name
	executorVersion = ver
elseif cloneref(game:GetService("RunService")):IsStudio() then
	executorName = "Studio"
	executorVersion = version()
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

local function main()
	local ScriptViewer = {}
	local window, codeFrame
	
	local execute, clear, dumpbtn
	
	local PreviousScr = nil
	
	ScriptViewer.DumpFunctions = function(scr)
		-- thanks King.Kevin#6025 you'll obviously be credited (no discord tag since that can easily be impersonated)
		local getgc = getgc or get_gc_objects
		local getupvalues = (debug and debug.getupvalues) or getupvalues or getupvals
		local getconstants = (debug and debug.getconstants) or getconstants or getconsts
		local getinfo = (debug and (debug.getinfo or debug.info)) or getinfo
		local original = ("\n-- // Function Dumper made by King.Kevin\n-- // Script Path: %s\n\n--[["):format(getPath(scr))
		local dump = original
		local functions, function_count, data_base = {}, 0, {}
		function functions:add_to_dump(str, indentation, new_line)
			local new_line = new_line or true
			dump = dump .. ("%s%s%s"):format(string.rep("		", indentation), tostring(str), new_line and "\n" or "")
		end
		function functions:get_function_name(func)
			local n = getinfo(func).name
			return n ~= "" and n or "Unknown Name"
		end
		function functions:dump_table(input, indent, index)
			local indent = indent < 0 and 0 or indent
			functions:add_to_dump(("%s [%s] %s"):format(tostring(index), tostring(typeof(input)), tostring(input)), indent - 1)
			local count = 0
			for index, value in pairs(input) do
				count = count + 1
				if type(value) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(count, functions:get_function_name(value)), indent)
				elseif type(value) == "table" then
					if not data_base[value] then
						data_base[value] = true
						functions:add_to_dump(("%d [table]:"):format(count), indent)
						functions:dump_table(value, indent + 1, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(count), indent)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(count, tostring(typeof(value)), tostring(value)), indent)
				end
			end
		end
		function functions:dump_function(input, indent)
			functions:add_to_dump(("\nFunction Dump: %s"):format(functions:get_function_name(input)), indent)
			functions:add_to_dump(("\nFunction Upvalues: %s"):format(functions:get_function_name(input)), indent)
			for index, upvalue in pairs(getupvalues(input)) do
				if type(upvalue) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(upvalue)), indent + 1)
				elseif type(upvalue) == "table" then
					if not data_base[upvalue] then
						data_base[upvalue] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(upvalue, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(upvalue)), tostring(upvalue)), indent + 1)
				end
			end
			functions:add_to_dump(("\nFunction Constants: %s"):format(functions:get_function_name(input)), indent)
			for index, constant in pairs(getconstants(input)) do
				if type(constant) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(constant)), indent + 1)
				elseif type(constant) == "table" then
					if not data_base[constant] then
						data_base[constant] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(constant, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(constant)), tostring(constant)), indent + 1)
				end
			end
		end
		for _, _function in pairs(env.getgc(true)) do
			if typeof(_function) == "function" and getfenv(_function).script and getfenv(_function).script == scr then
				functions:dump_function(_function, 0)
				functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
			end
		end
		local source = codeFrame:GetText()

		if dump ~= original then source = source .. dump .. "]]" end
		codeFrame:SetText(source)
		
		window:Show()
	end

ScriptViewer.EditedScriptsCache = setmetatable({}, {__mode = "k"})

	ScriptViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Notepad")
		window:Resize(500,400)
		ScriptViewer.Window = window

		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,20)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-60)
		codeFrame.Frame.Parent = window.GuiElems.Content
		codeFrame.Editable = true
		
		local copy = Instance.new("TextButton",window.GuiElems.Content)
		copy.BackgroundTransparency = 1
		copy.Size = UDim2.new(0.33,0,0,20)
		copy.Position = UDim2.new(0,0,0,0)
		copy.Text = "Copy to Clipboard"
		
		if env.setclipboard then
			copy.TextColor3 = Color3.new(1,1,1)
			copy.Interactable = true
		else
			copy.TextColor3 = Color3.new(0.5,0.5,0.5)
			copy.Interactable = false
		end

		copy.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.setclipboard(source)
		end)

		local save = Instance.new("TextButton",window.GuiElems.Content)
		save.BackgroundTransparency = 1
		save.Size = UDim2.new(0.33,0,0,20)
		save.Position = UDim2.new(0.33,0,0,0)
		save.Text = "Save to File"
		save.TextColor3 = Color3.new(1,1,1)
		
		if env.writefile then
			save.TextColor3 = Color3.new(1,1,1)
			save.Interactable = true
		else
			save.TextColor3 = Color3.new(0.5,0.5,0.5)
		end

		save.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			local filename = "Place_"..game.PlaceId.."_Script_"..os.time()..".txt"

			Lib.SaveAsPrompt(filename,source)
		end)
		
		dumpbtn = Instance.new("TextButton",window.GuiElems.Content)
		dumpbtn.BackgroundTransparency = 1
		dumpbtn.Position = UDim2.new(0.7,0,0,0)
		dumpbtn.Size = UDim2.new(0.3,0,0,20)
		dumpbtn.Text = "Dump Functions"
		dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
		
		if env.getgc then
			dumpbtn.TextColor3 = Color3.new(1,1,1)
			dumpbtn.Interactable = true
		else
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			dumpbtn.Interactable = false
		end

		dumpbtn.MouseButton1Click:Connect(function()
			if PreviousScr ~= nil then
				pcall(ScriptViewer.DumpFunctions, PreviousScr)
			end
		end)

		-- 2nd row starts here
		local ExecuteBtn = Instance.new("TextButton",window.GuiElems.Content)
		ExecuteBtn.BackgroundTransparency = 1
		ExecuteBtn.Size = UDim2.new(0.33,0,0,20)
		ExecuteBtn.Position = UDim2.new(0,0,1,-40)
		ExecuteBtn.Text = "Execute"
		
		if env.loadstring then
			ExecuteBtn.TextColor3 = Color3.new(1,1,1)
			ExecuteBtn.Interactable = true
		else
			ExecuteBtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			ExecuteBtn.Interactable = false
		end

		ExecuteBtn.MouseButton1Click:Connect(function()
			local Source = codeFrame:GetText()
			if env.loadstring then env.loadstring(Source, "DEX")() end
		end)

		local ClearBtn = Instance.new("TextButton",window.GuiElems.Content)
		ClearBtn.BackgroundTransparency = 1
		ClearBtn.Size = UDim2.new(0.33,0,0,20)
		ClearBtn.Position = UDim2.new(0.33,0,1,-40)
		ClearBtn.Text = "Clear"
		ClearBtn.TextColor3 = Color3.new(1,1,1)

		ClearBtn.MouseButton1Click:Connect(function()
			codeFrame:SetText("")
		end)
		
		ScriptViewer.IsEditing = false
		local EditBtn = Instance.new("TextButton",window.GuiElems.Content)
		EditBtn.BackgroundTransparency = 1
		EditBtn.Size = UDim2.new(0.34,0,0,20)
		EditBtn.Position = UDim2.new(0.66,0,1,-40)
		EditBtn.Text = "Edit Script"
		EditBtn.TextColor3 = Color3.new(1,1,1)
		ScriptViewer.EditButton = EditBtn
		
-- 3rd row
		local InfoBar = Instance.new("TextLabel", window.GuiElems.Content)
		InfoBar.BackgroundTransparency = 1
		InfoBar.Size = UDim2.new(1, -10, 0, 20)
		InfoBar.Position = UDim2.new(0, 5, 1,-20)
		InfoBar.Text = " Ln: 1 | Col: 1 | <font color='rgb(0,255,0)'>No Errors Found</font>"
		InfoBar.TextColor3 = Color3.fromRGB(200, 200, 200)
		InfoBar.TextXAlignment = Enum.TextXAlignment.Left
		InfoBar.RichText = true
		InfoBar.Font = Enum.Font.SourceSans
		InfoBar.TextSize = 14
		
		local function UpdateInfoBar()
			local LoadStringFunc = env.loadstring or loadstring
			local Source = codeFrame:GetText()
			local ErrText = "No Errors Found"
			local ErrColor = "rgb(0, 255, 0)"

			if LoadStringFunc then
				local Func, Err = LoadStringFunc(Source, "DEX")
				if not Func then
					ErrText = tostring(Err):gsub('%[string "DEX"%]:', "Line ")
					ErrColor = "rgb(255, 80, 80)"
				end
			else
				ErrText = "loadstring not supported on this executor, what kinda exec r u on"
				ErrColor = "rgb(255, 255, 0)"
			end

			local Row = codeFrame.CursorY + 1
			local Col = codeFrame.CursorX + 1
			local TotalLines = math.max(1, #codeFrame.Lines)
			InfoBar.Text = string.format(" Ln: %d / %d | Col: %d | <font color='%s'>%s</font>", Row, TotalLines, Col, ErrColor, ErrText:gsub("<", "&lt;"):gsub(">", "&gt;"))
		end
		
		codeFrame.OnCursorMoved:Connect(UpdateInfoBar)
		codeFrame.OnTextChanged:Connect(UpdateInfoBar)

		EditBtn.MouseButton1Click:Connect(function()
			if not PreviousScr then return end
			
			if not ScriptViewer.IsEditing then
				ScriptViewer.IsEditing = true
				EditBtn.Text = "Save"
				EditBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
				codeFrame.Editable = true
			else
				ScriptViewer.IsEditing = false
				EditBtn.Text = "Edit Script"
				EditBtn.TextColor3 = Color3.new(1,1,1)
				codeFrame.Editable = false
				
				local Source = codeFrame:GetText()
				local ScriptClass = PreviousScr.ClassName
				local ScriptName = PreviousScr.Name
				local ScriptParent = PreviousScr.Parent
				
				local NewScript = Instance.new(ScriptClass)
				NewScript.Name = ScriptName
				for _, child in pairs(PreviousScr:GetChildren()) do
					pcall(function() child.Parent = NewScript end)
				end
				
				pcall(function() PreviousScr:Destroy() end)
				pcall(function() NewScript.Parent = ScriptParent end)
				local RefNewScript = cloneref(NewScript)
				ScriptViewer.EditedScriptsCache[RefNewScript] = Source
				
				local LoadStringFunc = env.loadstring or loadstring
				if LoadStringFunc then
					local LoadedFunc, Err = LoadStringFunc(Source, "DEX")
					if LoadedFunc then
						local ExecEnv = setmetatable({
							script = RefNewScript
						}, {__index = getfenv(LoadedFunc)})
						
						setfenv(LoadedFunc, ExecEnv)
						coroutine.wrap(LoadedFunc)()
					else
						UpdateInfoBar()
					end
				end
				
				PreviousScr = RefNewScript
			end
		end)

	end
	
	ScriptViewer.ViewScript = function(scr)
		local source = ""
		
		if ScriptViewer.EditedScriptsCache[scr] then
			source = ScriptViewer.EditedScriptsCache[scr]
			PreviousScr = scr
			dumpbtn.TextColor3 = Color3.new(1,1,1)
		else
			local oldtick = tick()
			local s, decompiledSrc = pcall(env.decompile or function() end, scr)

			if not s or not decompiledSrc then
				PreviousScr = nil
				dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
				source = "-- Unable to view source.\n"
				
				if Settings.ScriptViewer.ShowMoreInfo then
					source = source .. "-- Script Path: "..getPath(scr).."\n"
					if (scr.ClassName == "Script" and (scr.RunContext == Enum.RunContext.Legacy or scr.RunContext == Enum.RunContext.Server)) or not scr:IsA("LocalScript") then
						source = source .. "-- Reason: The script is not running on client. (attempt to decompile ServerScript or 'Script' with RunContext Server)\n"
					elseif not env.isdecompile() then
						source = source .. "-- Reason: Your executor does not support decompiler. (missing 'decompile' function and 'getscriptbytecode' function as fallback)\n"
					else
						source = source .. "-- Reason: Unknown Error.\n"
					end
					source = source .. "-- Executor: "..executorName.." ("..executorVersion..")"
				end
			else
				PreviousScr = scr
				dumpbtn.TextColor3 = Color3.new(1,1,1)

				local Header = "-- Script Path: "..getPath(scr).."\n"
				
				if Settings.ScriptViewer.ShowMoreInfo then
					Header = Header .. "-- Took "..tostring(math.floor( (tick() - oldtick) * 100) / 100).."s to decompile.\n"
					Header = Header .. "-- Executor: "..executorName.." ("..executorVersion..")\n\n"
				end
				
				source = Header .. decompiledSrc
			end
		end

		codeFrame.Editable = false
		if ScriptViewer.EditButton then
			ScriptViewer.IsEditing = false
			ScriptViewer.EditButton.Text = "Edit Script"
			ScriptViewer.EditButton.TextColor3 = Color3.new(1,1,1)
		end
		
		codeFrame:SetText(source)
		window:Show()
	end

	return ScriptViewer
end

	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}

end,


	Lib = function()
--[[
	Lib Module
	
	Container for functions and classes
]]

		-- Common Locals
		local Main,Lib,Apps,Settings -- Main Containers
		local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
		local API,RMD,env,service,plr,create,createSimple -- Main Locals

		local function initDeps(data)
			Main = data.Main
			Lib = data.Lib
			Apps = data.Apps
			Settings = data.Settings

			API = data.API
			RMD = data.RMD
			env = data.env
			service = data.service
			plr = data.plr
			create = data.create
			createSimple = data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			ModelViewer = Apps.ModelViewer
			SettingsWindow = Apps.SettingsWindow
			Notebook = Apps.Notebook
		end

		local function main()
			local Lib = {}

			local renderStepped = service.RunService.RenderStepped
			local signalWait = renderStepped.wait
			local PH = newproxy() -- Placeholder, must be replaced in constructor
			local SIGNAL = newproxy()

			-- Usually for classes that work with a Roblox Object
			local function initObj(props,mt)
				local type = type
				local function copy(t)
					local res = {}
					for i,v in pairs(t) do
						if v == SIGNAL then
							res[i] = Lib.Signal.new()
						elseif type(v) == "table" then
							res[i] = copy(v)
						else
							res[i] = v
						end
					end		
					return res
				end

				local newObj = copy(props)
				return setmetatable(newObj,mt)
			end

			local function getGuiMT(props,funcs)
				return {__index = function(self,ind) if not props[ind] then return funcs[ind] or self.Gui[ind] end end,
				__newindex = function(self,ind,val) if not props[ind] then self.Gui[ind] = val else rawset(self,ind,val) end end}
			end

			-- Functions

			Lib.FormatLuaString = (function()
				local string = string
				local gsub = string.gsub
				local format = string.format
				local char = string.char
				local cleanTable = {['"'] = '\\"', ['\\'] = '\\\\'}
				for i = 0,31 do
					cleanTable[char(i)] = "\\"..format("%03d",i)
				end
				for i = 127,255 do
					cleanTable[char(i)] = "\\"..format("%03d",i)
				end

				return function(str)
					return gsub(str,"[\"\\\0-\31\127-\255]",cleanTable)
				end
			end)()

			Lib.CheckMouseInGui = function(gui)
				if gui == nil then return false end
				local mouse = Main.Mouse
				local guiPosition = gui.AbsolutePosition
				local guiSize = gui.AbsoluteSize	

				return mouse.X >= guiPosition.X and mouse.X < guiPosition.X + guiSize.X and mouse.Y >= guiPosition.Y and mouse.Y < guiPosition.Y + guiSize.Y
			end

			Lib.IsShiftDown = function()
				return service.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or service.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			end

			Lib.IsCtrlDown = function()
				return service.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or service.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			end

			Lib.CreateArrow = function(size,num,dir)
				local max = num
				local arrowFrame = createSimple("Frame",{
					BackgroundTransparency = 1,
					Name = "Arrow",
					Size = UDim2.new(0,size,0,size)
				})
				if dir == "up" then
					for i = 1,num do
						local newLine = createSimple("Frame",{
							BackgroundColor3 = Color3.new(220/255,220/255,220/255),
							BorderSizePixel = 0,
							Position = UDim2.new(0,math.floor(size/2)-(i-1),0,math.floor(size/2)+i-math.floor(max/2)-1),
							Size = UDim2.new(0,i+(i-1),0,1),
							Parent = arrowFrame
						})
					end
					return arrowFrame
				elseif dir == "down" then
					for i = 1,num do
						local newLine = createSimple("Frame",{
							BackgroundColor3 = Color3.new(220/255,220/255,220/255),
							BorderSizePixel = 0,
							Position = UDim2.new(0,math.floor(size/2)-(i-1),0,math.floor(size/2)-i+math.floor(max/2)+1),
							Size = UDim2.new(0,i+(i-1),0,1),
							Parent = arrowFrame
						})
					end
					return arrowFrame
				elseif dir == "left" then
					for i = 1,num do
						local newLine = createSimple("Frame",{
							BackgroundColor3 = Color3.new(220/255,220/255,220/255),
							BorderSizePixel = 0,
							Position = UDim2.new(0,math.floor(size/2)+i-math.floor(max/2)-1,0,math.floor(size/2)-(i-1)),
							Size = UDim2.new(0,1,0,i+(i-1)),
							Parent = arrowFrame
						})
					end
					return arrowFrame
				elseif dir == "right" then
					for i = 1,num do
						local newLine = createSimple("Frame",{
							BackgroundColor3 = Color3.new(220/255,220/255,220/255),
							BorderSizePixel = 0,
							Position = UDim2.new(0,math.floor(size/2)-i+math.floor(max/2)+1,0,math.floor(size/2)-(i-1)),
							Size = UDim2.new(0,1,0,i+(i-1)),
							Parent = arrowFrame
						})
					end
					return arrowFrame
				end
				error("r u ok")
			end

			Lib.ParseXML = (function()
				local func = function()
					-- Only exists to parse RMD
					-- from https://github.com/jonathanpoelen/xmlparser

					local string, print, pairs = string, print, pairs

					-- http://lua-users.org/wiki/StringTrim
					local trim = function(s)
						local from = s:match"^%s*()"
						return from > #s and "" or s:match(".*%S", from)
					end

					local gtchar = string.byte('>', 1)
					local slashchar = string.byte('/', 1)
					local D = string.byte('D', 1)
					local E = string.byte('E', 1)

					function parse(s, evalEntities)
						-- remove comments
						s = s:gsub('<!%-%-(.-)%-%->', '')

						local entities, tentities = {}

						if evalEntities then
							local pos = s:find('<[_%w]')
							if pos then
								s:sub(1, pos):gsub('<!ENTITY%s+([_%w]+)%s+(.)(.-)%2', function(name, q, entity)
									entities[#entities+1] = {name=name, value=entity}
								end)
								tentities = createEntityTable(entities)
								s = replaceEntities(s:sub(pos), tentities)
							end
						end

						local t, l = {}, {}

						local addtext = function(txt)
							txt = txt:match'^%s*(.*%S)' or ''
							if #txt ~= 0 then
								t[#t+1] = {text=txt}
							end		
						end

						s:gsub('<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)', function(type, name, closed, txt)
							-- open
							if #type == 0 then
								local a = {}
								if #closed == 0 then
									local len = 0
									for all,aname,_,value,starttxt in string.gmatch(txt, "(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))") do
										len = len + #all
										a[aname] = value
										if #starttxt ~= 0 then
											txt = txt:sub(len+1)
											closed = starttxt
											break
										end
									end
								end
								t[#t+1] = {tag=name, attrs=a, children={}}

								if closed:byte(1) ~= slashchar then
									l[#l+1] = t
									t = t[#t].children
								end

								addtext(txt)
								-- close
							elseif '/' == type then
								t = l[#l]
								l[#l] = nil

								addtext(txt)
								-- ENTITY
							elseif '!' == type then
								if E == name:byte(1) then
									txt:gsub('([_%w]+)%s+(.)(.-)%2', function(name, q, entity)
										entities[#entities+1] = {name=name, value=entity}
									end, 1)
								end
								-- elseif '?' == type then
								--	 print('?	' .. name .. ' // ' .. attrs .. '$$')
								-- elseif '-' == type then
								--	 print('comment	' .. name .. ' // ' .. attrs .. '$$')
								-- else
								--	 print('o	' .. #p .. ' // ' .. name .. ' // ' .. attrs .. '$$')
							end
						end)

						return {children=t, entities=entities, tentities=tentities}
					end

					function parseText(txt)
						return parse(txt)
					end

					function defaultEntityTable()
						return { quot='"', apos='\'', lt='<', gt='>', amp='&', tab='\t', nbsp=' ', }
					end

					function replaceEntities(s, entities)
						return s:gsub('&([^;]+);', entities)
					end

					function createEntityTable(docEntities, resultEntities)
						entities = resultEntities or defaultEntityTable()
						for _,e in pairs(docEntities) do
							e.value = replaceEntities(e.value, entities)
							entities[e.name] = e.value
						end
						return entities
					end

					return parseText
				end
				local newEnv = setmetatable({},{__index = getfenv()})
				setfenv(func,newEnv)
				return func()
			end)()

			Lib.FastWait = function(s)
				if not s then return signalWait(renderStepped) end
				local start = tick()
				while tick() - start < s do signalWait(renderStepped) end
			end

			Lib.ButtonAnim = function(button,data)
				local holding = false
				local disabled = false
				local mode = data and data.Mode or 1
				local control = {}

				if mode == 2 then
					local lerpTo = data.LerpTo or Color3.new(0,0,0)
					local delta = data.LerpDelta or 0.2
					control.StartColor = data.StartColor or button.BackgroundColor3
					control.PressColor = data.PressColor or control.StartColor:lerp(lerpTo,delta)
					control.HoverColor = data.HoverColor or control.StartColor:lerp(control.PressColor,0.6)
					control.OutlineColor = data.OutlineColor
				end

				button.InputBegan:Connect(function(input)
					if disabled then return end

					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if not holding then
							if mode == 1 then
								button.BackgroundTransparency = 0.4
							elseif mode == 2 then
								button.BackgroundColor3 = control.HoverColor
							end
						end
					elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holding = true
						if mode == 1 then
							button.BackgroundTransparency = 0
						elseif mode == 2 then
							button.BackgroundColor3 = control.PressColor
							if control.OutlineColor then button.BorderColor3 = control.PressColor end
						end
					end
				end)

				button.InputEnded:Connect(function(input)
					if disabled then return end

					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if not holding then
							if mode == 1 then
								button.BackgroundTransparency = 1
							elseif mode == 2 then
								button.BackgroundColor3 = control.StartColor
							end
						end
					elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holding = false
						if mode == 1 then
							button.BackgroundTransparency = Lib.CheckMouseInGui(button) and 0.4 or 1
						elseif mode == 2 then
							button.BackgroundColor3 = Lib.CheckMouseInGui(button) and control.HoverColor or control.StartColor
							if control.OutlineColor then button.BorderColor3 = control.OutlineColor end
						end
					end
				end)

				control.Disable = function()
					disabled = true
					holding = false

					if mode == 1 then
						button.BackgroundTransparency = 1
					elseif mode == 2 then
						button.BackgroundColor3 = control.StartColor
					end
				end

				control.Enable = function()
					disabled = false
				end

				return control
			end

			Lib.FindAndRemove = function(t,item)
				local pos = table.find(t,item)
				if pos then table.remove(t,pos) end
			end

			Lib.AttachTo = function(obj,data)
				local target,posOffX,posOffY,sizeOffX,sizeOffY,resize,con
				local disabled = false

				local function update()
					if not obj or not target then return end

					local targetPos = target.AbsolutePosition
					local targetSize = target.AbsoluteSize
					obj.Position = UDim2.new(0,targetPos.X + posOffX,0,targetPos.Y + posOffY)
					if resize then obj.Size = UDim2.new(0,targetSize.X + sizeOffX,0,targetSize.Y + sizeOffY) end
				end

				local function setup(o,data)
					obj = o
					data = data or {}
					target = data.Target
					posOffX = data.PosOffX or 0
					posOffY = data.PosOffY or 0
					sizeOffX = data.SizeOffX or 0
					sizeOffY = data.SizeOffY or 0
					resize = data.Resize or false

					if con then con:Disconnect() con = nil end
					if target then
						con = target.Changed:Connect(function(prop)
							if not disabled and prop == "AbsolutePosition" or prop == "AbsoluteSize" then
								update()
							end
						end)
					end

					update()
				end
				setup(obj,data)

				return {
					SetData = function(obj,data)
						setup(obj,data)
					end,
					Enable = function()
						disabled = false
						update()
					end,
					Disable = function()
						disabled = true
					end,
					Destroy = function()
						con:Disconnect()
						con = nil
					end,
				}
			end

			Lib.ProtectedGuis = {}

			Lib.ShowGui = function(gui)
				if env.gethui then
					gui.Parent = env.gethui()
				elseif env.protectgui then
					env.protectgui(gui)
					gui.Parent = Main.GuiHolder
				else
					gui.Parent = Main.GuiHolder
				end
			end

			Lib.ColorToBytes = function(col)
				local round = math.round
				return string.format("%d, %d, %d",round(col.r*255),round(col.g*255),round(col.b*255))
			end

			Lib.ReadFile = function(filename)
				if not env.readfile then return end

				local s,contents = pcall(env.readfile,filename)
				if s and contents then return contents end
			end

			Lib.DeferFunc = function(f,...)
				signalWait(renderStepped)
				return f(...)
			end

			Lib.LoadCustomAsset = function(filepath)
				if not env.getcustomasset or not env.isfile or not env.isfile(filepath) then return end

				return env.getcustomasset(filepath)
			end

			Lib.FetchCustomAsset = function(url,filepath)
				if not env.writefile then return end

				local s,data = pcall(oldgame.HttpGet,game,url)
				if not s then return end

				env.writefile(filepath,data)
				return Lib.LoadCustomAsset(filepath)
			end

			local currentfilename, currentextension, currentclickhandler
			currentclickhandler = function() end
			Lib.SaveAsPrompt = function(filename, codeToSave, ext)		
				local win = ScriptViewer.SaveAsWindow
				if not win then
					win = Lib.Window.new()
					win.Alignable = false
					win.Resizable = false
					win:SetTitle("Save As")
					win:SetSize(300,95)

					local saveButton = Lib.Button.new()
					local nameLabel = Lib.Label.new()
					nameLabel.Text = "Name"
					nameLabel.Position = UDim2.new(0,30,0,10)
					nameLabel.Size = UDim2.new(0,40,0,20)
					win:Add(nameLabel)

					local nameBox = Lib.ViewportTextBox.new()
					nameBox.Position = UDim2.new(0,75,0,10)
					nameBox.Size = UDim2.new(0,220,0,20)
					win:Add(nameBox,"NameBox")

					nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
						saveButton:SetDisabled(#nameBox:GetText() == 0)
					end)

					local errorLabel = Lib.Label.new()
					errorLabel.Text = ""
					errorLabel.Position = UDim2.new(0,5,1,-45)
					errorLabel.Size = UDim2.new(1,-10,0,20)
					errorLabel.TextColor3 = Settings.Theme.Important
					win.ErrorLabel = errorLabel
					win:Add(errorLabel,"Error")

					local cancelButton = Lib.Button.new()
					cancelButton.AnchorPoint = Vector2.new(1,1)
					cancelButton.Text = "Cancel"
					cancelButton.Position = UDim2.new(1,-5,1,-5)
					cancelButton.Size = UDim2.new(0.5,-10,0,20)
					cancelButton.OnClick:Connect(function()
						win:Close()
					end)
					win:Add(cancelButton)

					saveButton.Text = "Save"
					saveButton.AnchorPoint = Vector2.new(0,1)
					saveButton.Position = UDim2.new(0,5,1,-5)
					saveButton.Size = UDim2.new(0.5,-5,0,20)
					saveButton.OnClick:Connect(function()
						currentclickhandler()
					end)

					win:Add(saveButton,"SaveButton")

					ScriptViewer.SaveAsWindow = win
				end

				currentclickhandler = function()
					local Filename = (win.Elements.NameBox.TextBox.Text ~= "" and win.Elements.NameBox.TextBox.Text) or filename
					local IsInstance = (type(codeToSave) == "function")
					local UserExt = Filename:match("%.([^%.]+)$")
					local FinalExt = ext

					if not FinalExt then
						if IsInstance then
							if UserExt and (UserExt:lower() == "rbxm" or UserExt:lower() == "rbxl" or UserExt:lower() == "rbxlx") then
								Filename = Filename:sub(1, -(#UserExt + 2))
							end
						else
							FinalExt = (UserExt and (UserExt:lower() == "txt" or UserExt:lower() == "lua" or UserExt:lower() == "luau" or UserExt:lower() == "json")) and UserExt or "txt"
						end
					end

					if not IsInstance then
						if UserExt and UserExt:lower() == FinalExt:lower() then
							Filename = Filename:sub(1, -(#UserExt + 2))
						end
						Filename = Filename .. "." .. FinalExt
					end

					if type(codeToSave) == "string" then
						if env.writefile then
							local S, Msg = pcall(env.writefile, Filename, codeToSave)
							if not S then
								win.Elements.Error.Text = "Error: " .. tostring(Msg)
								task.spawn(error, Msg)
								task.wait(1)
							end
						else
							win.Elements.Error.Text = "Your executor does not support 'writefile'"
							task.wait(1)
						end
					elseif IsInstance then
						local S, Msg = pcall(codeToSave, Filename)
						if not S then
							win.Elements.Error.Text = "Error: " .. tostring(Msg)
							task.spawn(error, Msg)
							Lib.FastWait(1)
						end
					end
					win:Close()
				end

				win:SetTitle("Save As")
				win.Elements.Error.Text = ""
				win.Elements.NameBox:SetText(filename or "")
				
				win.Elements.SaveButton:SetDisabled(#win.Elements.NameBox:GetText() == 0)
				
				win:Show()
			end

			Lib.GetHash = function(Func)
				if typeof(Func) == "ProtoProxy" then
					local S, Hash = pcall(function() return tostring(Func.CodeHash) end)
					if S and type(Hash) == "string" and Hash ~= "" then return Hash end
					return tostring(Func)
				end
				if env.iscclosure then
					local S, IsC = pcall(env.iscclosure, Func)
					if S and IsC then
						return tostring(Func)
					end
				end
				if env.getfunctionhash then 
					local S, Hash = pcall(env.getfunctionhash, Func)
					if S and type(Hash) == "string" and Hash ~= "" then return Hash end
				end
				return tostring(Func)
			end

			Lib.GetFuncDisplayName = function(Func)
				local s, n = pcall(debug.info, Func, "n")
				if s and type(n) == "string" and n ~= "" then
					return n .. ": " .. tostring(Func)
				end
				return "Anonymous Function: " .. tostring(Func)
			end

			Lib.ParseToType = function(TypeStr, ValStr)
				if TypeStr == "string" then return ValStr
				elseif TypeStr == "number" then return tonumber(ValStr) or 0
				elseif TypeStr == "boolean" then return ValStr:lower() == "true" end
				
				if env.loadstring then
					local SourceCode
					if TypeStr == "Color3" and not ValStr:find("Color3") then SourceCode = "return Color3.fromRGB(" .. ValStr .. ")"
					elseif (TypeStr == "CFrame" or TypeStr == "Vector3" or TypeStr == "Vector2" or TypeStr == "UDim2" or TypeStr == "UDim" or TypeStr == "Rect" or TypeStr == "Ray" or TypeStr == "NumberRange" or TypeStr == "BrickColor" or TypeStr == "PhysicalProperties" or TypeStr == "TweenInfo" or TypeStr == "Axes" or TypeStr == "Faces" or TypeStr == "ColorSequence" or TypeStr == "NumberSequence") and not ValStr:find(TypeStr) then
						SourceCode = "return " .. TypeStr .. ".new(" .. ValStr .. ")"
					elseif TypeStr == "DateTime" and not ValStr:find("DateTime") then SourceCode = "return DateTime.fromUnixTimestampMillis(" .. ValStr .. ")"
					else SourceCode = "return " .. ValStr end
					
					local S, Func = pcall(env.loadstring, SourceCode)
					if S and Func then
						local S2, Result = pcall(Func)
						if S2 then return Result end
					end
				end

				if TypeStr == "Vector3" then
					local Coords = {}
					for X in ValStr:gmatch("[%d%.%-]+") do table.insert(Coords, tonumber(X) or 0) end
					return Vector3.new(Coords[1] or 0, Coords[2] or 0, Coords[3] or 0)
				elseif TypeStr == "Vector2" then
					local Coords = {}
					for X in ValStr:gmatch("[%d%.%-]+") do table.insert(Coords, tonumber(X) or 0) end
					return Vector2.new(Coords[1] or 0, Coords[2] or 0)
				elseif TypeStr == "Color3" then
					local Coords = {}
					for X in ValStr:gmatch("[%d%.%-]+") do table.insert(Coords, tonumber(X) or 0) end
					return Color3.fromRGB(Coords[1] or 255, Coords[2] or 255, Coords[3] or 255)
				end

				return ValStr
			end

			Lib.ShowInputPrompt = function(Title, DefaultText, Callback)
				local PromptWin = Lib.Window.new()
				PromptWin.Alignable = false
				PromptWin.Resizable = false
				PromptWin:SetTitle(Title)
				PromptWin:SetSize(300, 95)
				local Lbl = Lib.Label.new()
				Lbl.Text = "Input:"
				Lbl.Position = UDim2.new(0, 30, 0, 10)
				Lbl.Size = UDim2.new(0, 40, 0, 20)
				PromptWin:Add(Lbl)
				local Box = Lib.ViewportTextBox.new()
				Box.Position = UDim2.new(0, 75, 0, 10)
				Box.Size = UDim2.new(0, 210, 0, 20)
				Box.TextBox.Text = tostring(DefaultText)
				PromptWin:Add(Box, "InputBox")
				local Btn = Lib.Button.new()
				Btn.Text = "Confirm"
				Btn.Position = UDim2.new(0, 5, 1, -25)
				Btn.Size = UDim2.new(1, -10, 0, 20)
				Btn.OnClick:Connect(function()
					Callback(Box:GetText())
					PromptWin:Close()
				end)
				PromptWin:Add(Btn)
				PromptWin:Show()
			end

			Lib.ShowModifyValueDialog = function(Match, Callback)
				local PromptWin = Lib.Window.new()
				PromptWin.Alignable = false
				PromptWin.Resizable = false
				PromptWin:SetTitle("Modify Value")
				PromptWin:SetSize(320, 160)
				
				local TypeLbl = Lib.Label.new()
				TypeLbl.Text = "Type:"
				TypeLbl.Position = UDim2.new(0, 10, 0, 10)
				TypeLbl.Size = UDim2.new(0, 60, 0, 20)
				PromptWin:Add(TypeLbl)
				
				local TypeDropdown = Lib.DropDown.new()
				TypeDropdown.CanBeEmpty = false
				TypeDropdown.Size = UDim2.new(0, 220, 0, 20)
				TypeDropdown.Position = UDim2.new(0, 80, 0, 10)
				
				local TypeOptions = {
					"string", "number", "boolean", "AdReward", "Axes", "BrickColor", "CatalogSearchParams", "CFrame", "Color3", 
					"ColorSequence", "ColorSequenceKeypoint", "Content", "DateTime", "DockWidgetPluginGuiInfo", "Enum", 
					"EnumItem", "Enums", "Faces", "FloatCurveKey", "Font", "Instance", "NumberRange", "NumberSequence", 
					"NumberSequenceKeypoint", "OverlapParams", "Path2DControlPoint", "PathWaypoint", "PhysicalProperties", 
					"Random", "Ray", "RaycastParams", "RaycastResult", "RBXScriptConnection", "RBXScriptSignal", "Rect", 
					"Region3", "Region3int16", "RotationCurveKey", "Secret", "SecurityCapabilities", "SharedTable", 
					"TweenInfo", "UDim", "UDim2", "User", "ValueCurveKey", "Vector2", "Vector2int16", "Vector3", "Vector3int16"
				}
				TypeDropdown:SetOptions(TypeOptions)
				
				local CurrentType = Match.ValueType or "string"
				if not table.find(TypeOptions, CurrentType) then CurrentType = "string" end
				TypeDropdown:SetSelected(CurrentType)
				PromptWin:Add(TypeDropdown, "TypeDropdown")
				
				local ValLbl = Lib.Label.new()
				ValLbl.Text = "Value:"
				ValLbl.Position = UDim2.new(0, 10, 0, 40)
				ValLbl.Size = UDim2.new(0, 60, 0, 20)
				PromptWin:Add(ValLbl)
				
				local Box = Lib.ViewportTextBox.new()
				Box.Position = UDim2.new(0, 80, 0, 40)
				Box.Size = UDim2.new(0, 220, 0, 20)
				Box.TextBox.Text = tostring(Match.Value)
				PromptWin:Add(Box, "InputBox")
				
				local Btn = Lib.Button.new()
				Btn.Text = "Modify"
				Btn.Position = UDim2.new(0, 5, 1, -25)
				Btn.Size = UDim2.new(1, -10, 0, 20)
				Btn.OnClick:Connect(function()
					Callback(TypeDropdown.Selected or "string", Box:GetText())
					PromptWin:Close()
				end)
				PromptWin:Add(Btn)
				PromptWin:Show()
			end
		
			Lib.SerializeData = (function()
				local SerializeData = {}

local function attempt(func, fallback)
	local succ, res = xpcall(func, function()
		return fallback
	end)
	return succ and res or fallback
end

local function get_fn_info(func)
	local file, line, func_name, params, is_vararg = debug.info(func, 'slna')
	return {
		source = file,
		line = line,
		name = func_name,
		numparams = params,
		vargs = is_vararg,
	}
end

local byte = string.byte
local sub = string.sub

local function lookup(src, list)
	list = list or {}
	local src_type = type(src)

	if src_type == 'string' then
		for i = 1, #src do
			list[byte(src, i)] = true
		end
	elseif src_type == "table" then
		for i = 1, #src do
			list[src[i]] = true
		end
	end

	return list
end

local BASE_IDENT = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
local BASE_DIGITS = "0123456789"
local BASE_OPERATORS = "+-*/^%#"

local CHARS = {
	whitespace = lookup(" \n\t\r"),
	valid_escapes = lookup('abfnrtv"\'\\'),
	ident = lookup(BASE_IDENT .. BASE_DIGITS, {
		start = lookup(BASE_IDENT),
	}),
	digits = lookup(BASE_DIGITS, {
		hex = lookup(BASE_DIGITS .. "abcdefABCDEF"),
	}),
	symbols = lookup(BASE_OPERATORS .. ",{}[]();.:", {
		equality = lookup("~=><"),
		operators = lookup(BASE_OPERATORS),
	}),
}

local KEYWORDS = {
	structure = lookup({
		"and", 'break', "do", 'else', "elseif", 'end', "for", 'function',
		"goto", 'if', "in", 'local', "not", 'or', "repeat", 'return',
		"then", 'until', "while",
	}),
	values = lookup({ 'true', "false", 'nil' }),
}

local CHAR_NEWLINE = 10
local CHAR_DASH = 45
local CHAR_SQUOTE = 39
local CHAR_DQUOTE = 34
local CHAR_BACKSLASH = 92
local CHAR_LBRACKET = 91
local CHAR_RBRACKET = 93
local CHAR_EQUALS = 61
local CHAR_DOT = 46
local CHAR_COLON = 58
local CHAR_ZERO = 48
local CHAR_LOWER_X = 120
local CHAR_LOWER_E = 101
local CHAR_UPPER_E = 69

local function identinuse(str)
	return type(str) == 'string' and string.match(str, "^[%a_][%w_]*$") ~= nil
end

local ESCAPES = {
	[34] = '\\"',
	[92] = "\\\\",
	[7] = '\\a',
	[8] = "\\b",
	[9] = '\\t',
	[10] = "\\n",
	[11] = '\\v',
	[12] = "\\f",
	[13] = '\\r',
}

local function esc(str)
	if type(str) ~= "string" then
		str = tostring(str)
	end
	local len = #str
	local out = table.create(len + 2)
	out[1] = '"'
	local idx = 1
	for i = 1, len do
		local b = byte(str, i)
		local seq = ESCAPES[b]
		if seq then
			idx = idx + 1
			out[idx] = seq
		elseif b >= 32 and b <= 126 then
			idx = idx + 1
			out[idx] = sub(str, i, i)
		else
			idx = idx + 1
			out[idx] = string.format("\\%03d", b)
		end
	end
	out[idx + 1] = '"'
	return table.concat(out)
end

local function num2str(num)
	if type(num) ~= 'number' then
		num = tonumber(num) or 0
	end
	if num ~= num then
		return "0/0"
	elseif num == math.huge then
		return 'math.huge'
	elseif num == -math.huge then
		return "-math.huge"
	elseif num == math.floor(num) and math.abs(num) < 1e15 then
		return string.format('%d', num)
	end
	return string.format("%.14g", num)
end

local function vec3str(v)
	return string.format('Vector3.new(%s, %s, %s)', num2str(v.X), num2str(v.Y), num2str(v.Z))
end

local function color3str(v)
	return string.format(
		'Color3.fromRGB(%d, %d, %d)',
		math.round(v.R * 255),
		math.round(v.G * 255),
		math.round(v.B * 255)
	)
end

local function enum2str(item)
	return 'Enum.' .. tostring(item.EnumType) .. "." .. item.Name
end

local function get_child_segment(name)
	if identinuse(name) then
		return "." .. name
	end
	return "[" .. esc(name) .. "]"
end

local function findpath(obj)
	if obj == game then
		return "game"
	end

	local parts = {}
	local cur = obj
	local depth = 0

	while cur do
		depth = depth + 1
		if depth > 512 then
			return esc('<deep instance>')
		end

		if cur == game then
			table.insert(parts, 1, 'game')
			return table.concat(parts)
		end

		local parent = attempt(function()
			return cur.Parent
		end, nil)
		local name = attempt(function()
			return cur.Name
		end, "Instance")

		if parent == game then
			local is_srv = pcall(function()
				return game:GetService(name)
			end)
			if is_srv then
				table.insert(parts, 1, string.format("game:GetService(%s)", esc(name)))
			else
				table.insert(parts, 1, 'game' .. get_child_segment(name))
			end
			return table.concat(parts)
		end

		if not parent then
			local class = attempt(function()
				return cur.ClassName
			end, 'Instance')
			return esc(string.format('<unparented %s: %s>', class, name))
		end

		table.insert(parts, 1, get_child_segment(name))
		cur = parent
	end

	return esc('<unresolved instance>')
end

local types = {}

local function register(name, func, fallback)
	types[name] = function(val)
		return attempt(function()
			return func(val)
		end, fallback or ('"<' .. name .. '>"'))
	end
end

types.string = function(v)
	return esc(v)
end
types.number = function(v)
	return num2str(v)
end
types.boolean = function(v)
	return v and 'true' or "false"
end

types.Instance = function(v)
	return attempt(function()
		return findpath(v)
	end, '"<instance>"')
end

types.EnumItem = function(v)
	return attempt(function()
		return tostring(v)
	end, '"<EnumItem>"')
end

types.Enum = function(v)
	return attempt(function()
		return "Enum." .. tostring(v)
	end, '"<Enum>"')
end

types.Vector3 = function(v)
	return attempt(function()
		return vec3str(v)
	end, '"<Vector3>"')
end

types.Vector2 = function(v)
	return attempt(function()
		return string.format('Vector2.new(%s, %s)', num2str(v.X), num2str(v.Y))
	end, '"<Vector2>"')
end

types.Color3 = function(v)
	return attempt(function()
		return color3str(v)
	end, '"<Color3>"')
end

types.CFrame = function(v)
	return attempt(function()
		local comps = { v:GetComponents() }
		for i = 1, #comps do
			comps[i] = num2str(comps[i])
		end
		return string.format('CFrame.new(%s)', table.concat(comps, ", "))
	end, '"<CFrame>"')
end

types.UDim2 = function(v)
	return attempt(function()
		return string.format(
			'UDim2.new(%s, %s, %s, %s)',
			num2str(v.X.Scale),
			num2str(v.X.Offset),
			num2str(v.Y.Scale),
			num2str(v.Y.Offset)
		)
	end, '"<UDim2>"')
end

types.UDim = function(v)
	return attempt(function()
		return string.format('UDim.new(%s, %s)', num2str(v.Scale), num2str(v.Offset))
	end, '"<UDim>"')
end

types.BrickColor = function(v)
	return attempt(function()
		return string.format('BrickColor.new(%s)', esc(v.Name))
	end, '"<BrickColor>"')
end

types.RBXScriptConnection = function()
	return '"<RBXScriptConnection>"'
end
types.RBXScriptSignal = function()
	return '"<RBXScriptSignal>"'
end

types['function'] = function(v)
	return attempt(function()
		local name, line = debug.info(v, "nl")
		name = (type(name) == 'string' and name ~= "") and name or '?'
		return esc(string.format('<function %s@%s>', name, tostring(line or "?")))
	end, '"<function>"')
end

types.thread = function()
	return '"<thread>"'
end

register('Vector3int16', function(v)
	return string.format('Vector3int16.new(%s, %s, %s)', num2str(v.X), num2str(v.Y), num2str(v.Z))
end)

register('Vector2int16', function(v)
	return string.format('Vector2int16.new(%s, %s)', num2str(v.X), num2str(v.Y))
end)

register('NumberRange', function(v)
	return string.format('NumberRange.new(%s, %s)', num2str(v.Min), num2str(v.Max))
end)

register('NumberSequenceKeypoint', function(v)
	return string.format(
		'NumberSequenceKeypoint.new(%s, %s, %s)',
		num2str(v.Time),
		num2str(v.Value),
		num2str(v.Envelope)
	)
end)

register('NumberSequence', function(v)
	local list = v.Keypoints
	local segments = table.create(#list)
	for i = 1, #list do
		local kp = list[i]
		segments[i] = string.format(
			'NumberSequenceKeypoint.new(%s, %s, %s)',
			num2str(kp.Time),
			num2str(kp.Value),
			num2str(kp.Envelope)
		)
	end
	return string.format('NumberSequence.new({%s})', table.concat(segments, ', '))
end)

register('ColorSequenceKeypoint', function(v)
	return string.format('ColorSequenceKeypoint.new(%s, %s)', num2str(v.Time), color3str(v.Value))
end)

register('ColorSequence', function(v)
	local list = v.Keypoints
	local segments = table.create(#list)
	for i = 1, #list do
		local kp = list[i]
		segments[i] = string.format('ColorSequenceKeypoint.new(%s, %s)', num2str(kp.Time), color3str(kp.Value))
	end
	return string.format('ColorSequence.new({%s})', table.concat(segments, ', '))
end)

register('Rect', function(v)
	return string.format(
		'Rect.new(%s, %s, %s, %s)',
		num2str(v.Min.X),
		num2str(v.Min.Y),
		num2str(v.Max.X),
		num2str(v.Max.Y)
	)
end)

register('Ray', function(v)
	return string.format('Ray.new(%s, %s)', vec3str(v.Origin), vec3str(v.Direction))
end)

register('Region3', function(v)
	local cf, size = v.CFrame, v.Size
	local pos = cf.Position
	return string.format('Region3.new(%s, %s)', vec3str(pos - size / 2), vec3str(pos + size / 2))
end)

register('Region3int16', function(v)
	return string.format(
		'Region3int16.new(Vector3int16.new(%s, %s, %s), Vector3int16.new(%s, %s, %s))',
		num2str(v.Min.X),
		num2str(v.Min.Y),
		num2str(v.Min.Z),
		num2str(v.Max.X),
		num2str(v.Max.Y),
		num2str(v.Max.Z)
	)
end)

register('Faces', function(v)
	local face_list = {}
	local directions = { "Top", 'Bottom', "Left", 'Right', "Back", 'Front' }
	for i = 1, #directions do
		local d = directions[i]
		if v[d] then
			table.insert(face_list, 'Enum.NormalId.' .. d)
		end
	end
	return string.format('Faces.new(%s)', table.concat(face_list, ', '))
end)

register('Axes', function(v)
	local axis_list = {}
	local directions = { "X", 'Y', "Z" }
	for i = 1, #directions do
		local d = directions[i]
		if v[d] then
			table.insert(axis_list, 'Enum.Axis.' .. d)
		end
	end
	return string.format('Axes.new(%s)', table.concat(axis_list, ', '))
end)

register('PhysicalProperties', function(v)
	return string.format(
		'PhysicalProperties.new(%s, %s, %s, %s, %s)',
		num2str(v.Density),
		num2str(v.Friction),
		num2str(v.Elasticity),
		num2str(v.FrictionWeight),
		num2str(v.ElasticityWeight)
	)
end)

register('Font', function(v)
	return string.format('Font.new(%s, %s, %s)', esc(v.Family), format_enum(v.Weight), format_enum(v.Style))
end)

register('TweenInfo', function(v)
	return string.format(
		'TweenInfo.new(%s, %s, %s, %s, %s, %s)',
		num2str(v.Time),
		format_enum(v.EasingStyle),
		format_enum(v.EasingDirection),
		num2str(v.RepeatCount),
		v.Reverses and 'true' or "false",
		num2str(v.DelayTime)
	)
end)

register('DateTime', function(v)
	return string.format('DateTime.fromUnixTimestampMillis(%s)', num2str(v.UnixTimestampMillis))
end)

register('PathWaypoint', function(v)
	return string.format('PathWaypoint.new(%s, %s)', vec3str(v.Position), format_enum(v.Action))
end)

local function isarray(tbl)
	local count = 0
	local key = next(tbl)
	while key ~= nil do
		count = count + 1
		key = next(tbl, key)
	end
	local len = rawlen(tbl)
	if count ~= len then
		return false, len
	end
	for i = 1, len do
		if rawget(tbl, i) == nil then
			return false, len
		end
	end
	return true, len
end

local function write_scalar(value)
	if value == nil then
		return 'nil'
	end

	local val_type = attempt(function()
		return typeof(value)
	end, 'unknown')

	local handler = types[val_type]
	if handler then
		return handler(value)
	end

	local descriptor = attempt(function()
		return (string.gsub(tostring(value), '[%c]', ' '))
	end, '<' .. tostring(val_type) .. '>')

	if sub(descriptor, 1, #val_type + 1) == val_type .. ':' then
		return esc('<' .. descriptor .. '>')
	end
	return esc(string.format('<%s: %s>', val_type, descriptor))
end

local function getkeys(tbl)
	local items = {}
	local count = 0
	local is_seq, seq_len = attempt(function()
		return isarray(tbl)
	end, false)
	seq_len = seq_len or rawlen(tbl)

	if is_seq then
		for i = 1, seq_len do
			count = count + 1
			items[count] = { key = nil, value = rawget(tbl, i) }
		end
		return items
	end

	local seen = {}
	for i = 1, seq_len do
		if rawget(tbl, i) == nil then
			break
		end
		seen[i] = true
		count = count + 1
		items[count] = { key = nil, value = rawget(tbl, i) }
	end

	local keyed = {}
	local key_count = 0
	local key = next(tbl)
	while key ~= nil do
		if not seen[key] then
			key_count = key_count + 1
			keyed[key_count] = key
		end
		key = next(tbl, key)
	end

	pcall(function()
		table.sort(keyed, function(a, b)
			local ta, tb = typeof(a), typeof(b)
			if ta == 'string' and tb == 'string' then
				return a < b
			end
			return tostring(ta) < tostring(tb)
		end)
	end)

	for i = 1, key_count do
		local k = keyed[i]
		local key_str
		if type(k) == 'string' and identinuse(k) then
			key_str = k
		else
			key_str = '[' .. write_scalar(k) .. ']'
		end
		count = count + 1
		items[count] = { key = key_str, value = rawget(tbl, k) }
	end

	return items
end

local function stringify(root, pretty)
	local function normalize(v)
		if
			attempt(function()
				return typeof(v)
			end, '') == 'function'
		then
			return attempt(function()
				return get_fn_info(v)
			end, '<function>')
		end
		return v
	end

	root = normalize(root)

	if typeof(root) ~= 'table' then
		return write_scalar(root)
	end

	local buffer = {}
	local buf_idx = 0
	local seen_tables = {}

	local function append(str)
		buf_idx = buf_idx + 1
		buffer[buf_idx] = str
	end

	local function safe_collect(tbl)
		return attempt(function()
			return getkeys(tbl)
		end, {})
	end

	local sep = pretty and ',' or ', '
	local pad = '    '

	seen_tables[root] = true
	local stack = {
		{ list = safe_collect(root), ptr = 1, depth = 0, ref = root, tail = '' },
	}
	local top = 1
	append('{')

	local steps = 0
	while top > 0 do
		steps = steps + 1
		if steps > 3000 then -- Enforce cap limit
			append('\n... [truncated as it was too long]')
			break
		end

		if bit32.band(steps, 255) == 0 then
			task.wait()
		end

		local node = stack[top]
		local list = node.list
		local ptr = node.ptr

		if ptr > #list then
			if pretty and #list > 0 then
				append('\n' .. string.rep(pad, node.depth))
			end
			append('}')
			append(node.tail)
			seen_tables[node.ref] = nil
			stack[top] = nil
			top = top - 1
			continue
		end

		local item = list[ptr]
		node.ptr = ptr + 1

		local val = normalize(item.value)
		local next_depth = node.depth + 1

		if pretty then
			if item.key then
				append(string.format('\n%s%s = ', string.rep(pad, next_depth), item.key))
			else
				append('\n' .. string.rep(pad, next_depth))
			end
		elseif item.key then
			append(item.key .. ' = ')
		end

		if
			attempt(function()
				return typeof(val)
			end, '') == 'table'
		then
			if seen_tables[val] then
				append('"<cyclic table>"')
				append(sep)
			else
				seen_tables[val] = true
				append('{')
				top = top + 1
				stack[top] = {
					list = safe_collect(val),
					ptr = 1,
					depth = next_depth,
					ref = val,
					tail = sep,
				}
			end
		else
			append(write_scalar(val))
			append(sep)
		end
	end

	return table.concat(buffer)
end

local function lex(text)
	local pos = 1
	local size = #text
	local current_tok_start = 1
	local line_tokens = {}
	local all_lines = {}
	local line_chars = 0
	local offset = 0

	local function peek(delta)
		delta = delta or 0
		if pos + delta <= size then
			return byte(text, pos + delta)
		end
		return nil
	end

	local function advance()
		if pos <= size then
			local c = byte(text, pos)
			pos = pos + 1
			return c
		end
		return nil
	end

	local function get_data_level()
		local num = 0
		while byte(text, pos + num) == CHAR_EQUALS do
			num = num + 1
		end
		if byte(text, pos + num) == CHAR_LBRACKET then
			pos = pos + num + 1
			return num
		end
	end

	local function capture_token_text()
		return sub(text, current_tok_start, pos - 1)
	end

	local function emit_token(ty)
		local s = current_tok_start
		local e = pos - 1
		local length = e - s + 1

		if length > 0 then
			local last = line_tokens[#line_tokens]

			if not last or last.type ~= ty then
				line_tokens[#line_tokens + 1] = {
					type = ty,
					_s = s,
					_e = e,
					posFirst = s - offset,
					posLast = e - offset,
				}
			else
				last._e = e
				last.posLast = last.posLast + length
			end

			line_chars = line_chars + length
		end

		current_tok_start = pos
	end

	local function emit_newline()
		all_lines[#all_lines + 1] = line_tokens
		line_tokens = {}

		advance()
		emit_token('newline')
		line_tokens[1] = nil

		offset = offset + line_chars
		line_chars = 0
	end

	local function scan_multiline(level, ty)
		while true do
			local char = advance()

			if char == nil then
				return
			elseif char == CHAR_NEWLINE then
				pos = pos - 1
				emit_token(ty)
				emit_newline()
			elseif char == CHAR_RBRACKET then
				local valid = true

				for _ = 1, level do
					if peek() == CHAR_EQUALS then
						pos = pos + 1
					else
						valid = false
						break
					end
				end

				if valid and peek() == CHAR_RBRACKET then
					pos = pos - level - 1
					return
				end
			end
		end
	end

	local function skipspace()
		while true do
			local char = peek()

			if char == CHAR_NEWLINE then
				emit_token('whitespace')
				emit_newline()
			elseif CHARS.whitespace[char] then
				pos = pos + 1
			else
				break
			end
		end

		emit_token('whitespace')
	end

	while true do
		skipspace()

		local char = advance()

		if char == nil then
			break
		elseif char == CHAR_DASH and peek() == CHAR_DASH then
			pos = pos + 1

			if peek() == CHAR_LBRACKET then
				pos = pos + 1

				local level = get_data_level()

				if level then
					scan_multiline(level, 'comment')

					pos = pos + level + 2
					emit_token('comment')
				else
					while true do
						local char2 = advance()

						if char2 == nil or char2 == CHAR_NEWLINE then
							pos = pos - 1
							emit_token('comment')

							if char2 == CHAR_NEWLINE then
								emit_newline()
							end

							break
						end
					end
				end
			else
				while true do
					local char2 = advance()

					if char2 == nil or char2 == CHAR_NEWLINE then
						pos = pos - 1
						emit_token('comment')

						if char2 == CHAR_NEWLINE then
							emit_newline()
						end

						break
					end
				end
			end

			emit_token('comment')
		elseif char == CHAR_SQUOTE or char == CHAR_DQUOTE then
			emit_token('string_start')

			while true do
				local char2 = advance()

				if char2 == CHAR_BACKSLASH then
					pos = pos - 1
					emit_token('string')
					advance()

					local char3 = advance()

					if CHARS.digits[char3] then
						for _ = 1, 2 do
							if CHARS.digits[peek()] then
								pos = pos + 1
							end
						end
					elseif char3 == CHAR_LOWER_X then
						if CHARS.digits.hex[peek()] and CHARS.digits.hex[peek(1)] then
							pos = pos + 2
						else
							emit_token('unidentified')
						end
					elseif char3 == CHAR_NEWLINE then
						pos = pos - 1
						emit_token('escape')
						emit_newline()
					elseif not CHARS.valid_escapes[char3] then
						emit_token('unidentified')
					end

					emit_token('escape')
				elseif char2 == CHAR_NEWLINE then
					pos = pos - 1
					emit_token('string')
					emit_newline()

					break
				elseif char2 == char or char2 == nil then
					pos = pos - 1
					emit_token('string')
					advance()

					break
				end
			end

			emit_token('string_end')
		elseif CHARS.ident.start[char] then
			while CHARS.ident[peek()] do
				pos = pos + 1
			end

			local word = capture_token_text()

			if KEYWORDS.structure[word] then
				emit_token('keyword')
			elseif KEYWORDS.values[word] then
				emit_token('value')
			else
				emit_token('ident')
			end
		elseif CHARS.digits[char] or (char == CHAR_DOT and CHARS.digits[peek()]) then
			if char == CHAR_ZERO and peek() == CHAR_LOWER_X then
				pos = pos + 1

				while CHARS.digits.hex[peek()] do
					pos = pos + 1
				end
			else
				while CHARS.digits[peek()] do
					pos = pos + 1
				end

				if peek() == CHAR_DOT then
					pos = pos + 1

					while CHARS.digits[peek()] do
						pos = pos + 1
					end
				end

				local e = peek()
				if e == CHAR_LOWER_E or e == CHAR_UPPER_E then
					pos = pos + 1

					if peek() == CHAR_DASH then
						pos = pos + 1
					end

					while CHARS.digits[peek()] do
						pos = pos + 1
					end
				end
			end

			emit_token('number')
		elseif char == CHAR_LBRACKET then
			local level = get_data_level()

			if level then
				emit_token('string_start')

				scan_multiline(level, 'string')
				emit_token('string')

				pos = pos + level + 2
				emit_token('string_end')
			else
				emit_token('symbol')
			end
		elseif char == CHAR_DOT then
			if peek() == CHAR_DOT then
				pos = pos + 1

				if peek() == CHAR_DOT then
					pos = pos + 1
				end
			end

			if pos - current_tok_start == 3 then
				emit_token('vararg')
			else
				emit_token('symbol')
			end
		elseif char == CHAR_COLON and peek() == CHAR_COLON then
			advance()

			emit_token('label_start')

			skipspace()

			if CHARS.ident.start[peek()] then
				advance()

				while CHARS.ident[peek()] do
					advance()
				end

				emit_token('label')

				skipspace()

				if peek() == CHAR_COLON and peek(1) == CHAR_COLON then
					advance()
					advance()

					emit_token('label_end')
				end
			end
		elseif CHARS.symbols.equality[char] then
			if peek() == CHAR_EQUALS then
				pos = pos + 1
			end

			emit_token('operator')
		elseif CHARS.symbols[char] then
			if CHARS.symbols.operators[char] then
				emit_token('operator')
			else
				emit_token('symbol')
			end
		else
			emit_token('unidentified')
		end
	end

	all_lines[#all_lines + 1] = line_tokens

	for line_idx = 1, #all_lines do
		local line = all_lines[line_idx]
		for tk_idx = 1, #line do
			local tk = line[tk_idx]
			tk.data = sub(text, tk._s, tk._e)
			tk._s = nil
			tk._e = nil
		end
	end

	return all_lines
end

local function format(code)
	local scanned_lines = lex(code)
	local toks = {}
	local tok_max = 0

	for line_idx = 1, #scanned_lines do
		local current_line = scanned_lines[line_idx]
		for tk_idx = 1, #current_line do
			local tk = current_line[tk_idx]
			local ty = tk.type
			if ty == 'whitespace' or ty == 'newline' then
				continue
			end
			if ty == 'symbol' then
				local raw_data = tk.data
				for char_pos = 1, #raw_data do
					tok_max = tok_max + 1
					toks[tok_max] = { type = 'symbol', data = sub(raw_data, char_pos, char_pos) }
				end
			else
				tok_max = tok_max + 1
				toks[tok_max] = tk
			end
		end
	end

	local lines_out = {}
	local out_size = 0
	local nest_level = 0
	local brackets = {}
	local bp = 0
	local indent_string = '    '

	local function emit(str)
		out_size = out_size + 1
		lines_out[out_size] = str
	end

	local function newline()
		emit('\n' .. string.rep(indent_string, nest_level))
	end

	local i = 1
	while i <= tok_max do
		local tk = toks[i]
		local data_val = tk.data

		if data_val == '{' then
			local next_tk = toks[i + 1]
			if next_tk and next_tk.data == '}' then
				emit('{}')
				i = i + 2
				continue
			end
			emit('{')
			nest_level = nest_level + 1
			bp = bp + 1
			brackets[bp] = '{'
			newline()
		elseif data_val == '}' then
			nest_level = nest_level - 1
			if brackets[bp] == '{' then
				brackets[bp] = nil
				bp = bp - 1
			end
			newline()
			emit('}')
		elseif data_val == '(' then
			emit('(')
			bp = bp + 1
			brackets[bp] = '('
		elseif data_val == ')' then
			if brackets[bp] == '(' then
				brackets[bp] = nil
				bp = bp - 1
			end
			emit(')')
		elseif data_val == ',' then
			local next_tk = toks[i + 1]
			if next_tk and next_tk.data == '}' then
				i = i + 1
				continue
			end
			emit(',')
			if brackets[bp] == '{' then
				newline()
			else
				emit(' ')
			end
		elseif tk.type == 'operator' and data_val == '=' then
			emit(' = ')
		else
			emit(data_val)
		end

		i = i + 1
	end

	return table.concat(lines_out)
end

SerializeData.Format = format

function SerializeData.Convert(value, use_indent)
	local function handle_err(msg)
		return '--[[ Serialization failed: ' .. tostring(msg) .. ' ]] nil'
	end

	local succ, raw = xpcall(stringify, handle_err, value, false)
	if not succ then return raw end

	if not use_indent then return raw end


	local ok, pretty = pcall(format, raw)
	if ok and type(pretty) == 'string' and pretty ~= '' then return pretty end

	local fallback_ok, fallback_out = xpcall(stringify, handle_err, value, true)
	if fallback_ok then
		return fallback_out
	end

	return raw
end
				return SerializeData
			end)()

			-- Classes

			Lib.Haptic = function()
				pcall(function()
					local hs = service.HapticService
					if hs:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small) then
						hs:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.15)
						task.delay(0.04, function()
							hs:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
						end)
					end
				end)
			end

			Lib.ViewTableDetail = function(Tab, Name)
				if not Lib.DetailWindow then
					local win = Lib.Window.new()
					win:SetTitle("Details")
					win:Resize(450, 400)
					
					local copyBtn = Instance.new("TextButton", win.GuiElems.Content)
					copyBtn.Size = UDim2.new(1, 0, 0, 20)
					copyBtn.Position = UDim2.new(0, 0, 0, 0)
					copyBtn.BackgroundTransparency = 1
					copyBtn.Text = "Copy to Clipboard"
					copyBtn.TextColor3 = Color3.new(1,1,1)
					
					local codeFrame = Lib.CodeFrame.new()
					codeFrame.Frame.Position = UDim2.new(0, 0, 0, 20)
					codeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
					codeFrame.Frame.Parent = win.GuiElems.Content
					codeFrame.Editable = false
					
					copyBtn.MouseButton1Click:Connect(function()
						if env.setclipboard then env.setclipboard(codeFrame:GetText()) end
					end)
					
					Lib.DetailWindow = win
					Lib.DetailCodeFrame = codeFrame
				end

				Lib.DetailWindow:SetTitle("Details: " .. Name)
				Lib.DetailCodeFrame:SetText("-- Serializing table, please wait...")
				Lib.DetailWindow:Show()

				task.spawn(function()
					local Ok, Content = pcall(function()
						return Lib.SerializeData.Convert(Tab, true)
					end)
					Lib.DetailCodeFrame:SetText(Ok and Content or ("Error reading table: " .. tostring(Content)))
				end)
			end

			Lib.ViewFunctionDetail = function(Func, Name, Hash)
				if not Lib.DetailWindow then
					local win = Lib.Window.new()
					win:SetTitle("Details")
					win:Resize(450, 400)
					
					local copyBtn = Instance.new("TextButton", win.GuiElems.Content)
					copyBtn.Size = UDim2.new(1, 0, 0, 20)
					copyBtn.Position = UDim2.new(0, 0, 0, 0)
					copyBtn.BackgroundTransparency = 1
					copyBtn.Text = "Copy to Clipboard"
					copyBtn.TextColor3 = Color3.new(1,1,1)
					
					local codeFrame = Lib.CodeFrame.new()
					codeFrame.Frame.Position = UDim2.new(0, 0, 0, 20)
					codeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
					codeFrame.Frame.Parent = win.GuiElems.Content
					codeFrame.Editable = false
					
					copyBtn.MouseButton1Click:Connect(function()
						if env.setclipboard then env.setclipboard(codeFrame:GetText()) end
					end)
					
					Lib.DetailWindow = win
					Lib.DetailCodeFrame = codeFrame
				end

				local function FormatValue(Val)
					local Type = typeof(Val)
					local ValStr = tostring(Val)
					if Type == "Instance" then
						local S, Full = pcall(function() return Val:GetFullName() end)
						if S and Full then ValStr = Full end
					end
					return Type .. " : " .. ValStr
				end

				local function FormatFunctionDetails(Fn, Indent)
					local S_Line, Line = pcall(debug.info, Fn, "l")
					local S_Name, FName = pcall(debug.info, Fn, "n")
					local S_Src, Src = pcall(debug.info, Fn, "s")
					local S_Arity, Arity, IsVararg = pcall(debug.info, Fn, "a")
					local NameStr = (S_Name and type(FName) == "string" and FName ~= "") and FName or "anonymous"
					local LineStr = (S_Line and type(Line) == "number") and tostring(Line) or "nil"
					local SrcStr = (S_Src and type(Src) == "string") and tostring(Src) or "nil"
					local ArityStr = (S_Arity and type(Arity) == "number") and tostring(Arity) or "0"
					local VargsStr = (S_Arity and type(IsVararg) == "boolean") and tostring(IsVararg) or "false"
					local HashStr = Lib.GetHash(Fn)
					local Ind = string.rep(" ", Indent)
					return string.format("{\n%s    line = %s,\n%s    name = %q,\n%s    numparams = %s,\n%s    source = %q,\n%s    vargs = %s,\n%s    hash = %q\n%s}",
						Ind, LineStr, Ind, NameStr, Ind, ArityStr, Ind, SrcStr, Ind, VargsStr, Ind, HashStr, Ind)
				end

				local InfoStr = "-- Generated with DEX Recontinued by Tesker103\n-- https://github.com/Tesker-103/DexRecontinued\n\n"
				local S_Name, NameInfo = pcall(debug.info, Func, "n")
				local S_Src, SourceInfo = pcall(debug.info, Func, "s")
				local S_Line, LineInfo = pcall(debug.info, Func, "l")
				local S_Arity, ArityInfo, IsVarargInfo = pcall(debug.info, Func, "a")
				
				local fNameStr = (S_Name and type(NameInfo) == "string" and NameInfo ~= "") and NameInfo or "Anonymous"
				local fSourceStr = (S_Src and type(SourceInfo) == "string") and SourceInfo or "nil"
				local fLineStr = (S_Line and type(LineInfo) == "number") and tostring(LineInfo) or "nil"
				local fArityStr = (S_Arity and type(ArityInfo) == "number") and tostring(ArityInfo) or "0"
				local fVargsStr = (S_Arity and type(IsVarargInfo) == "boolean") and tostring(IsVarargInfo) or "false"
				
				InfoStr = InfoStr .. "Function Hash: " .. tostring(Hash) .. "\n"
				InfoStr = InfoStr .. "Name: " .. fNameStr .. "\n"
				InfoStr = InfoStr .. "Source: " .. fSourceStr .. "\n"
				InfoStr = InfoStr .. "Current Line: " .. fLineStr .. "\n"
				InfoStr = InfoStr .. "IsVararg, Arity: " .. fVargsStr .. ", " .. fArityStr .. "\n"
				
				local IsCClosure = false
				if typeof(Func) == "ProtoProxy" then
					IsCClosure = false
				elseif env.iscclosure then
					local S, Res = pcall(env.iscclosure, Func)
					IsCClosure = S and Res or false
				end
				InfoStr = InfoStr .. "Type: " .. (IsCClosure and "C Closure" or "Lua Closure") .. "\n\n"
				
				if not IsCClosure then
					local S_Const, Constants = pcall(env.getconstants, Func)
					local constCount = 0
					if S_Const and type(Constants) == "table" then
						for _ in next, Constants do constCount = constCount + 1 end
					end
					InfoStr = InfoStr .. "Constants (" .. constCount .. "):\n"
					if S_Const and type(Constants) == "table" then
						for i, v in next, Constants do
							InfoStr = InfoStr .. "   [" .. i .. "] = " .. FormatValue(v) .. "\n"
						end
					end
					
					local S_Upv, Upvalues = pcall(env.getupvalues, Func)
					local upvCount = 0
					if S_Upv and type(Upvalues) == "table" then
						for _ in next, Upvalues do upvCount = upvCount + 1 end
					end
					InfoStr = InfoStr .. "\nUpvalues (" .. upvCount .. "):\n"
					if S_Upv and type(Upvalues) == "table" then
						for i, v in next, Upvalues do
							local ValDisp = ""
							if type(v) == "function" or typeof(v) == "ProtoProxy" then
								ValDisp = FormatFunctionDetails(v, 3)
							else
								ValDisp = FormatValue(v)
							end
							InfoStr = InfoStr .. "   [" .. i .. "] = " .. ValDisp .. "\n"
						end
					end
					
					local S_Protos, Protos = pcall(env.getprotos, Func)
					local protosCount = 0
					if S_Protos and type(Protos) == "table" then
						for _ in next, Protos do protosCount = protosCount + 1 end
					end
					InfoStr = InfoStr .. "\nProtos (" .. protosCount .. "):\n"
					if S_Protos and type(Protos) == "table" then
						for i, v in next, Protos do
							InfoStr = InfoStr .. "   [" .. i .. "] = " .. FormatFunctionDetails(v, 3) .. "\n"
						end
					end
				end
				
				Lib.DetailWindow:SetTitle("Details: " .. Name)
				Lib.DetailCodeFrame:SetText(InfoStr)
				Lib.DetailWindow:Show()
			end

			Lib.Signal = (function()
				local funcs = {}

				local disconnect = function(con)
					local pos = table.find(con.Signal.Connections,con)
					if pos then table.remove(con.Signal.Connections,pos) end
				end

				funcs.Connect = function(self,func)
					if type(func) ~= "function" then error("Attempt to connect a non-function") end		
					local con = {
						Signal = self,
						Func = func,
						Disconnect = disconnect
					}
					self.Connections[#self.Connections+1] = con
					return con
				end

				funcs.Fire = function(self,...)
					for i,v in next,self.Connections do
						xpcall(coroutine.wrap(v.Func),function(e) warn(e.."\n"..debug.traceback()) end,...)
					end
				end

				local mt = {
					__index = funcs,
					__tostring = function(self)
						return "Signal: " .. tostring(#self.Connections) .. " Connections"
					end
				}

				local function new()
					local obj = {}
					obj.Connections = {}

					return setmetatable(obj,mt)
				end

				return {new = new}
			end)()

			Lib.Set = (function()
				local funcs = {}

				funcs.Add = function(self,obj)
					if self.Map[obj] then return end

					local list = self.List
					list[#list+1] = obj
					self.Map[obj] = true
					self.Changed:Fire()
				end

				funcs.AddTable = function(self,t)
					local changed
					local list,map = self.List,self.Map
					for i = 1,#t do
						local elem = t[i]
						if not map[elem] then
							list[#list+1] = elem
							map[elem] = true
							changed = true
						end
					end
					if changed then self.Changed:Fire() end
				end

				funcs.Remove = function(self,obj)
					if not self.Map[obj] then return end

					local list = self.List
					local pos = table.find(list,obj)
					if pos then table.remove(list,pos) end
					self.Map[obj] = nil
					self.Changed:Fire()
				end

				funcs.RemoveTable = function(self,t)
					local changed
					local list,map = self.List,self.Map
					local removeSet = {}
					for i = 1,#t do
						local elem = t[i]
						map[elem] = nil
						removeSet[elem] = true
					end

					for i = #list,1,-1 do
						local elem = list[i]
						if removeSet[elem] then
							table.remove(list,i)
							changed = true
						end
					end
					if changed then self.Changed:Fire() end
				end

				funcs.Set = function(self,obj)
					if #self.List == 1 and self.List[1] == obj then return end

					self.List = {obj}
					self.Map = {[obj] = true}
					self.Changed:Fire()
				end

				funcs.SetTable = function(self,t)
					local newList,newMap = {},{}
					self.List,self.Map = newList,newMap
					table.move(t,1,#t,1,newList)
					for i = 1,#t do
						newMap[t[i]] = true
					end
					self.Changed:Fire()
				end

				funcs.Clear = function(self)
					if #self.List == 0 then return end
					self.List = {}
					self.Map = {}
					self.Changed:Fire()
				end

				local mt = {__index = funcs}

				local function new()
					local obj = setmetatable({
						List = {},
       						Map = {},
						Changed = Lib.Signal.new()
					},mt)

					return obj
				end

				return {new = new}
			end)()

			Lib.IconMap = (function()
				local funcs = {}
				local IconList = {
					Old = {
						MapId = (getcustomasset and isfile and isfile("DEX_REContinued/Images/icondraft.png")) and getcustomasset("DEX_REContinued/Images/icondraft.png") or 483448923, IconSize = 16, Witdh = 16, Height = 16,
						Icons = {
							["Accessory"] = 32; ["Accoutrement"] = 32; ["AdService"] = 73; ["Animation"] = 60; ["AnimationController"] = 60;
							["AnimationTrack"] = 60; ["Animator"] = 60;["ArcHandles"] = 56; ["AssetService"] = 72; ["Attachment"] = 34;
							["Backpack"] = 20; ["BadgeService"] = 75;["BallSocketConstraint"] = 89; ["BillboardGui"] = 64; ["BinaryStringValue"] = 4;
							["BindableEvent"] = 67; ["BindableFunction"] = 66;["BlockMesh"] = 8; ["BloomEffect"] = 90; ["BlurEffect"] = 90;["BodyAngularVelocity"] = 14; ["BodyForce"] = 14;["BodyGyro"] = 14; ["BodyPosition"] = 14; ["BodyThrust"] = 14;
							["BodyVelocity"] = 14; ["BoolValue"] = 4;["BoxHandleAdornment"] = 54; ["BrickColorValue"] = 4; ["Camera"] = 5;["CFrameValue"] = 4; ["CharacterMesh"] = 60; ["Chat"] = 33; ["ClickDetector"] = 41; ["CollectionService"] = 30;["Color3Value"] = 4; ["ColorCorrectionEffect"] = 90;["ConeHandleAdornment"] = 54; ["Configuration"] = 58;
							["ContentProvider"] = 72;["ContextActionService"] = 41; ["CoreGui"] = 46;["CoreScript"] = 18; ["CornerWedgePart"] = 1;
							["CustomEvent"] = 4;["CustomEventReceiver"] = 4; ["CylinderHandleAdornment"] = 54;["CylinderMesh"] = 8;
							["CylindricalConstraint"] = 89;["Debris"] = 30; ["Decal"] = 7; ["Dialog"] = 62; ["DialogChoice"] = 63;
							["DoubleConstrainedValue"] = 4;["Explosion"] = 36; ["FileMesh"] = 8; ["Fire"] = 61;["Flag"] = 38;
							["FlagStand"] = 39; ["FloorWire"] = 4; ["Folder"] = 70; ["ForceField"] = 37; ["Frame"] = 48;
							["GamePassService"] = 19; ["Glue"] = 34; ["GuiButton"] = 52; ["GuiMain"] = 47; ["GuiService"] = 47;["Handles"] = 53; ["HapticService"] = 84; ["Hat"] = 45; ["HingeConstraint"] = 89; ["Hint"] = 33;["HopperBin"] = 22; ["HttpService"] = 76; ["Humanoid"] = 9; ["ImageButton"] = 52;["ImageLabel"] = 49;
							["InsertService"] = 72; ["IntConstrainedValue"] = 4; ["IntValue"] = 4;["JointInstance"] = 34;["JointsService"] = 34;
							["Keyframe"] = 60; ["KeyframeSequence"] = 60; ["KeyframeSequenceProvider"] = 60; ["Lighting"] = 13;
							["LineHandleAdornment"] = 54;["LocalScript"] = 18; ["LogService"] = 87;["MarketplaceService"] = 46; ["Message"] = 33;
							["Model"] = 2; ["ModuleScript"] = 71; ["Motor"] = 34; ["Motor6D"] = 34;["MoveToConstraint"] = 89;
							["NegateOperation"] = 78;["NetworkClient"] = 16;["NetworkReplicator"] = 29; ["NetworkServer"] = 15;
							["NumberValue"] = 4; ["ObjectValue"] = 4; ["Pants"] = 44; ["ParallelRampPart"] = 1; ["Part"] = 1;["ParticleEmitter"] = 69;["PartPairLasso"] = 57; ["PathfindingService"] = 37; ["Platform"] = 35;
							["Player"] = 12;["PlayerGui"] = 46;["Players"] = 21; ["PlayerScripts"] = 82; ["PointLight"] = 13;
							["PointsService"] = 83; ["Pose"] = 60; ["PrismaticConstraint"] = 89; ["PrismPart"] = 1; ["PyramidPart"] = 1;
							["RayValue"] = 4; ["ReflectionMetadata"] = 86; ["ReflectionMetadataCallbacks"] = 86; ["ReflectionMetadataClass"] = 86;
							["ReflectionMetadataClasses"] = 86; ["ReflectionMetadataEnum"] = 86;["ReflectionMetadataEnumItem"] = 86;
							["ReflectionMetadataEnums"] = 86;["ReflectionMetadataEvents"] = 86;["ReflectionMetadataFunctions"] = 86;["ReflectionMetadataMember"] = 86;["ReflectionMetadataProperties"] = 86; ["ReflectionMetadataYieldFunctions"] = 86;
							["RemoteEvent"] = 80; ["RemoteFunction"] = 79;["ReplicatedFirst"] = 72;["ReplicatedStorage"] = 72;["RightAngleRampPart"] = 1;["RocketPropulsion"] = 14; ["RodConstraint"] = 89; ["RopeConstraint"] = 89;
							["Rotate"] = 34;["RotateP"] = 34;["RotateV"] = 34; ["RunService"] = 66; ["ScreenGui"] = 47;
							["Script"] = 6; ["ScrollingFrame"] = 48; ["Seat"] = 35; ["Selection"] = 55;["SelectionBox"] = 54;["SelectionPartLasso"] = 57; ["SelectionPointLasso"] = 57; ["SelectionSphere"] = 54; ["ServerScriptService"] = 0;
							["ServerStorage"] = 74; ["Shirt"] = 43; ["ShirtGraphic"] = 40; ["SkateboardPlatform"] = 35; ["Sky"] = 28;
							["SlidingBallConstraint"] = 89; ["Smoke"] = 59; ["Snap"] = 34; ["Sound"] = 11; ["SoundService"] = 31;
							["Sparkles"] = 42;["SpawnLocation"] = 25;["SpecialMesh"] = 8; ["SphereHandleAdornment"] = 54;["SpotLight"] = 13; ["SpringConstraint"] = 89;["StarterCharacterScripts"] = 82; ["StarterGear"] = 20;
							["StarterGui"] = 46;["StarterPack"] = 20; ["StarterPlayer"] = 88;["StarterPlayerScripts"] = 82;
							["Status"] = 2; ["StringValue"] = 4; ["SunRaysEffect"] = 90; ["SurfaceGui"] = 64; ["SurfaceLight"] = 13;["SurfaceSelection"] = 55; ["Team"] = 24;["Teams"] = 23; ["TeleportService"] = 81; ["Terrain"] = 65;
							["TerrainRegion"] = 65; ["TestService"] = 68; ["TextBox"] = 51;["TextButton"] = 51; ["TextLabel"] = 50;
							["Texture"] = 10; ["TextureTrail"] = 4; ["Tool"] = 17; ["TouchTransmitter"] = 37; ["TrussPart"] = 1;["UnionOperation"] = 77; ["UserInputService"] = 84; ["Vector3Value"] = 4; ["VehicleSeat"] = 35;
							["VelocityMotor"] = 34;["WedgePart"] = 1;["Weld"] = 34; ["Workspace"] = 19;
						}
					},
					Vanilla3 = {
						MapId = (getcustomasset and isfile and isfile("DEX_REContinued/sprite_sheet (1).png")) and getcustomasset("DEX_REContinued/sprite_sheet (1).png") or 114851699900089, IconSize = 32, Witdh = 25, Height = 25,
						Icons = {
							Accessory = 1, Accoutrement = 2, Actor = 3, AdGui = 4, AdPortal = 5, AdService = 6, AdvancedDragger = 7, AirController = 8, AlignOrientation = 9,
							AlignPosition = 10, AnalysticsService = 11, AnalysticsSettings = 12, AnalyticsService = 13, AngularVelocity = 14, Animation = 15, AnimationClip = 16,
							AnimationClipProvider = 17, AnimationController = 18, AnimationFromVideoCreatorService = 19, AnimationFromVideoCreatorStudioService = 20,
							AnimationRigData = 21, AnimationStreamTrack = 22, AnimationTrack = 23, Animator = 24, AppStorageService = 25, AppUpdateService = 26, ArcHandles = 27,
							AssetCounterService = 28, AssetDeliveryProxy = 29, AssetImportService = 30, AssetImportSession = 31, AssetManagerService = 32, AssetService = 33,
							AssetSoundEffect = 34, Atmosphere = 35, Attachment = 36, AvatarEditorService = 37, AvatarImportService = 38, Backpack = 39, BackpackItem = 40,
							BadgeService = 41, BallSocketConstraint = 42, BasePart = 43, BasePlayerGui = 44, BaseScript = 45, BaseWrap = 46, Beam = 47, BevelMesh = 48,
							BillboardGui = 49, BinaryStringValue = 50, BindableEvent = 51, BindableFunction = 52, BlockMesh = 53, BloomEffect = 54, BlurEffect = 55,
							BodyAngularVelocity = 56, BodyColors = 57, BodyForce = 58, BodyGyro = 59, BodyMover = 60, BodyPosition = 61, BodyThrust = 62, BodyVelocity = 63,
							Bone = 64, BoolValue = 65, BoxHandleAdornment = 66, Breakpoint = 67, BreakpointManager = 68, BrickColorValue = 69, BrowserService = 70,
							BubbleChatConfiguration = 71, BulkImportService = 72, CacheableContentProvider = 73, CalloutService = 74, Camera = 75, CanvasGroup = 76,
							CatalogPages = 77, CFrameValue = 78, ChangeHistoryService = 79, ChannelSelectorSoundEffect = 80, CharacterAppearance = 81, CharacterMesh = 82,
							Chat = 83, ChatInputBarConfiguration = 84, ChatWindowConfiguration = 85, ChorusSoundEffect = 86, ClickDetector = 87, ClientReplicator = 88,
							ClimbController = 89, Clothing = 90, Clouds = 91, ClusterPacketCache = 92, CollectionService = 93, Color3Value = 94, ColorCorrectionEffect = 95,
							CommandInstance = 96, CommandService = 97, CompressorSoundEffect = 98, ConeHandleAdornment = 99, Configuration = 100, ConfigureServerService = 101,
							Constraint = 102, ContentProvider = 103, ContextActionService = 104, Controller = 105, ControllerBase = 106, ControllerManager = 107,
							ControllerService = 108, CookiesService = 109, CoreGui = 110, CorePackages = 111, CoreScript = 112, CoreScriptSyncService = 113, CornerWedgePart = 114,
							CrossDMScriptChangeListener = 115, CSGDictionaryService = 116, CurveAnimation = 117, CustomEvent = 118, CustomEventReceiver = 119,
							CustomSoundEffect = 120, CylinderHandleAdornment = 121, CylinderMesh = 122, CylindricalConstraint = 123, DataModel = 124, DataModelMesh = 125,
							DataModelPatchService = 126, DataModelSession = 127, DataStore = 128, DataStoreIncrementOptions = 129, DataStoreInfo = 130, DataStoreKey = 131,
							DataStoreKeyInfo = 132, DataStoreKeyPages = 133, DataStoreListingPages = 134, DataStoreObjectVersionInfo = 135, DataStoreOptions = 136,
							DataStorePages = 137, DataStoreService = 138, DataStoreSetOptions = 139, DataStoreVersionPages = 140, Debris = 141, DebuggablePluginWatcher = 142,
							DebuggerBreakpoint = 143, DebuggerConnection = 144, DebuggerConnectionManager = 145, DebuggerLuaResponse = 146, DebuggerManager = 147,
							DebuggerUIService = 148, DebuggerVariable = 149, DebuggerWatch = 150, DebugSettings = 151, Decal = 152, DepthOfFieldEffect = 153, DeviceIdService = 154,
							Dialog = 155, DialogChoice = 156, DistortionSoundEffect = 157, DockWidgetPluginGui = 158, DoubleConstrainedValue = 159, DraftsService = 160,
							Dragger = 161, DraggerService = 162, DynamicRotate = 163, EchoSoundEffect = 164, EmotesPages = 165, EqualizerSoundEffect = 166, EulerRotationCurve = 167,
							EventIngestService = 168, Explosion = 169, FaceAnimatorService = 170, FaceControls = 171, FaceInstance = 172, FacialAnimationRecordingService = 173,
							FacialAnimationStreamingService = 174, Feature = 175, File = 176, FileMesh = 177, Fire = 178, Flag = 179, FlagStand = 180, FlagStandService = 181,
							FlangeSoundEffect = 182, FloatCurve = 183, FloorWire = 184, FlyweightService = 185, Folder = 186, ForceField = 187, FormFactorPart = 188, Frame = 189,
							FriendPages = 190, FriendService = 191, FunctionalTest = 192, GamepadService = 193, GamePassService = 194, GameSettings = 195, GenericSettings = 196,
							Geometry = 197, GetTextBoundsParams = 198, GlobalDataStore = 199, GlobalSettings = 200, Glue = 201, GoogleAnalyticsConfiguration = 202,
							GroundController = 203, GroupService = 204, GuiBase = 205, GuiBase2d = 206, GuiBase3d = 207, GuiButton = 208, GuidRegistryService = 209,
							GuiLabel = 210, GuiMain = 211, GuiObject = 212, GuiService = 213, HandleAdornment = 214, Handles = 215, HandlesBase = 216, HapticService = 217,
							Hat = 218, HeightmapImporterService = 219, HiddenSurfaceRemovalAsset = 220, Highlight = 221, HingeConstraint = 222, Hint = 223, Hole = 224, Hopper = 225,
							HopperBin = 226, HSRDataContentProvider = 227, HttpRbxApiService = 228, HttpRequest = 229, HttpService = 230, Humanoid = 231, HumanoidController = 232,
							HumanoidDescription = 233, IKControl = 234, ILegacyStudioBridge = 235, ImageButton = 236, ImageHandleAdornment = 237, ImageLabel = 238,
							ImporterAnimationSettings = 239, ImporterBaseSettings = 240, ImporterFacsSettings = 241, ImporterGroupSettings = 242, ImporterJointSettings = 243,
							ImporterMaterialSettings = 244, ImporterMeshSettings = 245, ImporterRootSettings = 246, IncrementalPatchBuilder = 247, InputObject = 248,
							InsertService = 249, Instance = 250, InstanceAdornment = 251, IntConstrainedValue = 252, IntValue = 253, InventoryPages = 254, IXPService = 255,
							JointInstance = 256, JointsService = 257, KeyboardService = 258, Keyframe = 259, KeyframeMarker = 260, KeyframeSequence = 261,
							KeyframeSequenceProvider = 262, LanguageService = 263, LayerCollector = 264, LegacyStudioBridge = 265, Light = 266, Lighting = 267, LinearVelocity = 268,
							LineForce = 269, LineHandleAdornment = 270, LocalDebuggerConnection = 271, LocalizationService = 272, LocalizationTable = 273, LocalScript = 274,
							LocalStorageService = 275, LodDataEntity = 276, LodDataService = 277, LoginService = 278, LogService = 279, LSPFileSyncService = 280, LuaSettings = 281,
							LuaSourceContainer = 282, LuauScriptAnalyzerService = 283, LuaWebService = 284, ManualGlue = 285, ManualSurfaceJointInstance = 286, ManualWeld = 287,
							MarkerCurve = 288, MarketplaceService = 289, MaterialService = 290, MaterialVariant = 291, MemoryStoreQueue = 292, MemoryStoreService = 293,
							MemoryStoreSortedMap = 294, MemStorageConnection = 295, MemStorageService = 296, MeshContentProvider = 297, MeshPart = 298, Message = 299,
							MessageBusConnection = 300, MessageBusService = 301, MessagingService = 302, MetaBreakpoint = 303, MetaBreakpointContext = 304,
							MetaBreakpointManager = 305, Model = 306, ModuleScript = 307, Motor = 308, Motor6D = 309, MotorFeature = 310, Mouse = 311, MouseService = 312,
							MultipleDocumentInterfaceInstance = 313, NegateOperation = 314, NetworkClient = 315, NetworkMarker = 316, NetworkPeer = 317, NetworkReplicator = 318,
							NetworkServer = 319, NetworkSettings = 320, NoCollisionConstraint = 321, NonReplicatedCSGDictionaryService = 322, NotificationService = 323,
							NumberPose = 324, NumberValue = 325, ObjectValue = 326, OrderedDataStore = 327, OutfitPages = 328, PackageLink = 329, PackageService = 330,
							PackageUIService = 331, Pages = 332, Pants = 333, ParabolaAdornment = 334, Part = 335, PartAdornment = 336, ParticleEmitter = 337, PartOperation = 338,
							PartOperationAsset = 339, PatchMapping = 340, Path = 341, PathfindingLink = 342, PathfindingModifier = 343, PathfindingService = 344, PausedState = 345,
							PausedStateBreakpoint = 346, PausedStateException = 347, PermissionsService = 348, PhysicsService = 349, PhysicsSettings = 350, PitchShiftSoundEffect = 351,
							Plane = 352, PlaneConstraint = 353, Platform = 354, Player = 355, PlayerEmulatorService = 356, PlayerGui = 357, PlayerMouse = 358, Players = 359,
							PlayerScripts = 360, Plugin = 361, PluginAction = 362, PluginDebugService = 363, PluginDragEvent = 364, PluginGui = 365, PluginGuiService = 366,
							PluginManagementService = 367, PluginManager = 368, PluginManagerInterface = 369, PluginMenu = 370, PluginMouse = 371, PluginPolicyService = 372,
							PluginToolbar = 373, PluginToolbarButton = 374, PointLight = 375, PointsService = 376, PolicyService = 377, Pose = 378, PoseBase = 379, PostEffect = 380,
							PrismaticConstraint = 381, ProcessInstancePhysicsService = 382, ProximityPrompt = 383, ProximityPromptService = 384, PublishService = 385,
							PVAdornment = 386, PVInstance = 387, QWidgetPluginGui = 388, RayValue = 389, RbxAnalyticsService = 390, ReflectionMetadata = 391,
							ReflectionMetadataCallbacks = 392, ReflectionMetadataClass = 393, ReflectionMetadataClasses = 394, ReflectionMetadataEnum = 395,
							ReflectionMetadataEnumItem = 396, ReflectionMetadataEnums = 397, ReflectionMetadataEvents = 398, ReflectionMetadataFunctions = 399,
							ReflectionMetadataItem = 400, ReflectionMetadataMember = 401, ReflectionMetadataProperties = 402, ReflectionMetadataYieldFunctions = 403,
							RemoteDebuggerServer = 404, RemoteEvent = 405, RemoteFunction = 406, RenderingTest = 407, RenderSettings = 408, ReplicatedFirst = 409,
							ReplicatedStorage = 410, ReverbSoundEffect = 411, RigidConstraint = 412, RobloxPluginGuiService = 413, RobloxReplicatedStorage = 414,
							RocketPropulsion = 415, RodConstraint = 416, RopeConstraint = 417, Rotate = 418, RotateP = 419, RotateV = 420, RotationCurve = 421,
							RtMessagingService = 422, RunningAverageItemDouble = 423, RunningAverageItemInt = 424, RunningAverageTimeIntervalItem = 425, RunService = 426,
							RuntimeScriptService = 427, ScreenGui = 428, ScreenshotHud = 429, Script = 430, ScriptChangeService = 431, ScriptCloneWatcher = 432,
							ScriptCloneWatcherHelper = 433, ScriptContext = 434, ScriptDebugger = 435, ScriptDocument = 436, ScriptEditorService = 437,
							ScriptRegistrationService = 438, ScriptService = 439, ScrollingFrame = 440, Seat = 441, Selection = 442, SelectionBox = 443, SelectionLasso = 444,
							SelectionPartLasso = 445, SelectionPointLasso = 446, SelectionSphere = 447, ServerReplicator = 448, ServerScriptService = 449, ServerStorage = 450,
							ServiceProvider = 451, SessionService = 452, Shirt = 453, ShirtGraphic = 454, SkateboardController = 455, SkateboardPlatform = 456, Skin = 457,
							Sky = 458, SlidingBallConstraint = 459, Smoke = 460, Snap = 461, SnippetService = 462, SocialService = 463, SolidModelContentProvider = 464,
							Sound = 465, SoundEffect = 466, SoundGroup = 467, SoundService = 468, Sparkles = 469, SpawnerService = 470, SpawnLocation = 471, Speaker = 472,
							SpecialMesh = 473, SphereHandleAdornment = 474, SpotLight = 475, SpringConstraint = 476, StackFrame = 477, StandalonePluginScripts = 478,
							StandardPages = 479, StarterCharacterScripts = 480, StarterGear = 481, StarterGui = 482, StarterPack = 483, StarterPlayer = 484,
							StarterPlayerScripts = 485, Stats = 486, StatsItem = 487, Status = 488, StopWatchReporter = 489, StringValue = 490, Studio = 491,
							StudioAssetService = 492, StudioData = 493, StudioDeviceEmulatorService = 494, StudioHighDpiService = 495, StudioPublishService = 496,
							StudioScriptDebugEventListener = 497, StudioService = 498, StudioTheme = 499, SunRaysEffect = 500, SurfaceAppearance = 501, SurfaceGui = 502,
							SurfaceGuiBase = 503, SurfaceLight = 504, SurfaceSelection = 505, SwimController = 506, TaskScheduler = 507, Team = 508, TeamCreateService = 509,
							Teams = 510, TeleportAsyncResult = 511, TeleportOptions = 512, TeleportService = 513, TemporaryCageMeshProvider = 514, TemporaryScriptService = 515,
							Terrain = 516, TerrainDetail = 517, TerrainRegion = 518, TestService = 519, TextBox = 520, TextBoxService = 521, TextButton = 522, TextChannel = 523,
							TextChatCommand = 524, TextChatConfigurations = 525, TextChatMessage = 526, TextChatMessageProperties = 527, TextChatService = 528, TextFilterResult = 529,
							TextLabel = 530, TextService = 531, TextSource = 532, Texture = 533, ThirdPartyUserService = 534, ThreadState = 535, TimerService = 536,
							ToastNotificationService = 537, Tool = 538, ToolboxService = 539, Torque = 540, TorsionSpringConstraint = 541, TotalCountTimeIntervalItem = 542,
							TouchInputService = 543, TouchTransmitter = 544, TracerService = 545, TrackerStreamAnimation = 546, Trail = 547, Translator = 548,
							TremoloSoundEffect = 549, TriangleMeshPart = 550, TrussPart = 551, Tween = 552, TweenBase = 553, TweenService = 554, UGCValidationService = 555,
							UIAspectRatioConstraint = 556, UIBase = 557, UIComponent = 558, UIConstraint = 559, UICorner = 560, UIGradient = 561, UIGridLayout = 562,
							UIGridStyleLayout = 563, UILayout = 564, UIListLayout = 565, UIPadding = 566, UIPageLayout = 567, UIScale = 568, UISizeConstraint = 569, UIStroke = 570,
							UITableLayout = 571, UITextSizeConstraint = 572, UnionOperation = 573, UniversalConstraint = 574, UnvalidatedAssetService = 575, UserGameSettings = 576,
							UserInputService = 577, UserService = 578, UserSettings = 579, UserStorageService = 580, ValueBase = 581, Vector3Curve = 582, Vector3Value = 583,
							VectorForce = 584, VehicleController = 585, VehicleSeat = 586, VelocityMotor = 587, VersionControlService = 588, VideoCaptureService = 589,
							VideoFrame = 590, ViewportFrame = 591, VirtualInputManager = 592, VirtualUser = 593, VisibilityService = 594, Visit = 595, VoiceChannel = 596,
							VoiceChatInternal = 597, VoiceChatService = 598, VoiceSource = 599, VRService = 600, WedgePart = 601, Weld = 602, WeldConstraint = 603,
							WireframeHandleAdornment = 604, Workspace = 605, WorldModel = 606, WorldRoot = 607, WrapLayer = 608, WrapTarget = 609
						}
					},
					NewDark = {
						MapId = (getcustomasset and isfile and isfile("DEX_REContinued/Texture.png")) and getcustomasset("DEX_REContinued/Texture.png") or 135148380892747, IconSize = 32, Witdh = 18, Height = 18,
						Icons = {
							Accessory = 1, Actor = 2, AdGui = 3, AdPortal = 4, AirController = 5, AlignOrientation = 6, AlignPosition = 7, AngularVelocity = 8,
							Animation = 9, AnimationConstraint = 10, AnimationController = 11, AnimationFromVideoCreatorService = 12, Animator = 13, ArcHandles = 14,
							Atmosphere = 15, Attachment = 16, AudioAnalyzer = 17, AudioChannelMixer = 18, AudioChannelSplitter = 19, AudioChorus = 20, AudioCompressor = 21,
							AudioDeviceInput = 22, AudioDeviceOutput = 23, AudioDistortion = 24, AudioEcho = 25, AudioEmitter = 26, AudioEqualizer = 27, AudioFader = 28,
							AudioFilter = 29, AudioFlanger = 30, AudioGate = 31, AudioLimiter = 32, AudioListener = 33, AudioPitchShifter = 34, AudioPlayer = 35,
							AudioRecorder = 36, AudioReverb = 37, AudioTextToSpeech = 38, AuroraScript = 39, AvatarEditorService = 40, AvatarSettings = 41, Backpack = 42,
							BallSocketConstraint = 43, BasePlate = 44, Beam = 45, BillboardGui = 46, BindableEvent = 47, BindableFunction = 48, BlockMesh = 49, BloomEffect = 50,
							BlurEffect = 51, BodyAngularVelocity = 52, BodyColors = 53, BodyForce = 54, BodyGyro = 55, BodyPosition = 56, BodyThrust = 57, BodyVelocity = 58,
							Bone = 59, BoolValue = 60, BoxHandleAdornment = 61, Breakpoint = 62, BrickColorValue = 63, BubbleChatConfiguration = 64, Buggaroo = 65, Camera = 66,
							CanvasGroup = 67, CFrameValue = 68, ChannelTabsConfiguration = 69, CharacterControllerManager = 70, CharacterMesh = 71, Chat = 72,
							ChatInputBarConfiguration = 73, ChatWindowConfiguration = 74, ChorusSoundEffect = 75, Class = 76, Cleanup = 77, ClickDetector = 78,
							ClientReplicator = 79, ClimbController = 80, Clouds = 81, Color = 82, ColorCorrectionEffect = 83, CompressorSoundEffect = 84, ConeHandleAdornment = 85,
							Configuration = 86, Constant = 87, Constructor = 88, Controller = 89, CoreGui = 90, CornerWedgePart = 91, CylinderHandleAdornment = 92,
							CylindricalConstraint = 93, Decal = 94, DepthOfFieldEffect = 95, Dialog = 96, DialogChoice = 97, DistortionSoundEffect = 98, DragDetector = 99,
							EchoSoundEffect = 100, EditableImage = 101, EditableMesh = 102, Enum = 103, EnumMember = 104, EqualizerSoundEffect = 105, Event = 106,
							Explosion = 107, FaceControls = 108, Field = 109, File = 110, Fire = 111, FlangeSoundEffect = 112, Folder = 113, ForceField = 114, Frame = 115,
							Function = 116, GameSettings = 117, GroundController = 118, Handles = 119, HapticEffect = 120, HapticService = 121, HeightmapImporterService = 122,
							Highlight = 123, HingeConstraint = 124, Humanoid = 125, HumanoidDescription = 126, IKControl = 127, ImageButton = 128, ImageHandleAdornment = 129,
							ImageLabel = 130, InputAction = 131, InputBinding = 132, InputContext = 133, Interface = 134, IntersectOperation = 135, Keyword = 136, Lighting = 137,
							LinearVelocity = 138, LineForce = 139, LineHandleAdornment = 140, LocalFile = 141, LocalizationService = 142, LocalizationTable = 143, LocalScript = 144,
							MaterialService = 145, MaterialVariant = 146, MemoryStoreService = 147, MeshPart = 148, Meshparts = 149, MessagingService = 150, Method = 151,
							Model = 152, Modelgroups = 153, Module = 154, ModuleScript = 155, Motor6D = 156, NegateOperation = 157, NetworkClient = 158, NoCollisionConstraint = 159,
							Operator = 160, PackageLink = 161, Pants = 162, Part = 163, ParticleEmitter = 164, Path2D = 165, PathfindingLink = 166, PathfindingModifier = 167,
							PathfindingService = 168, PitchShiftSoundEffect = 169, Place = 170, Placeholder = 171, Plane = 172, PlaneConstraint = 173, Player = 174, Players = 175,
							PluginGuiService = 176, PointLight = 177, PrismaticConstraint = 178, Property = 179, ProximityPrompt = 180, PublishService = 181, Reference = 182,
							RemoteEvent = 183, RemoteFunction = 184, RenderingTest = 185, ReplicatedFirst = 186, ReplicatedScriptService = 187, ReplicatedStorage = 188,
							ReverbSoundEffect = 189, RigidConstraint = 190, RobloxPluginGuiService = 191, RocketPropulsion = 192, RodConstraint = 193, RopeConstraint = 194,
							Rotate = 195, ScreenGui = 196, Script = 197, ScrollingFrame = 198, Seat = 199, Selected_Workspace = 200, SelectionBox = 201, SelectionSphere = 202,
							ServerScriptService = 203, ServerStorage = 204, Service = 205, Shirt = 206, ShirtGraphic = 207, SkinnedMeshPart = 208, Sky = 209, Smoke = 210,
							Snap = 211, Snippet = 212, SocialService = 213, Sound = 214, SoundEffect = 215, SoundGroup = 216, SoundService = 217, Sparkles = 218,
							SpawnLocation = 219, SpecialMesh = 220, SphereHandleAdornment = 221, SpotLight = 222, SpringConstraint = 223, StandalonePluginScripts = 224,
							StarterCharacterScripts = 225, StarterGui = 226, StarterPack = 227, StarterPlayer = 228, StarterPlayerScripts = 229, Struct = 230, StyleDerive = 231,
							StyleLink = 232, StyleRule = 233, StyleSheet = 234, SunRaysEffect = 235, SurfaceAppearance = 236, SurfaceGui = 237, SurfaceLight = 238,
							SurfaceSelection = 239, SwimController = 240, TaskScheduler = 241, Team = 242, Teams = 243, Terrain = 244, TerrainDetail = 245, TestService = 246,
							TextBox = 247, TextBoxService = 248, TextButton = 249, TextChannel = 250, TextChatCommand = 251, TextChatService = 252, TextLabel = 253, TextString = 254,
							Texture = 255, Tool = 256, Torque = 257, TorsionSpringConstraint = 258, Trail = 259, TremoloSoundEffect = 260, TrussPart = 261, TypeParameter = 262,
							UGCValidationService = 263, UIAspectRatioConstraint = 264, UICorner = 265, UIDragDetector = 266, UIFlexItem = 267, UIGradient = 268, UIGridLayout = 269,
							UIListLayout = 270, UIPadding = 271, UIPageLayout = 272, UIScale = 273, UISizeConstraint = 274, UIStroke = 275, UITableLayout = 276,
							UITextSizeConstraint = 277, UnionOperation = 278, Unit = 279, UniversalConstraint = 280, UnreliableRemoteEvent = 281, UpdateAvailable = 282,
							UserService = 283, Value = 284, Variable = 285, VectorForce = 286, VehicleSeat = 287, VideoDisplay = 288, VideoFrame = 289, VideoPlayer = 290,
							ViewportFrame = 291, VirtualUser = 292, VoiceChannel = 293, Voicechat = 294, VoiceChatService = 295, VRService = 296, WedgePart = 297, Weld = 298,
							WeldConstraint = 299, Wire = 300, WireframeHandleAdornment = 301, Workspace = 302, WorldModel = 303, WrapDeformer = 304, WrapLayer = 305,
							WrapTarget = 306, Color3Value = 284, IntValue = 284, NumberValue = 284, ObjectValue = 284, RayValue = 284, StringValue = 284, Vector3Value = 284
						}
					},
					NewLight = {
						MapId = "", IconSize = 16, Witdh = 18, Height = 18,
						Icons = {
							Class = "rbxasset://studio_svg_textures/Shared/InsertableObjects/Light/Standard/",
						}
					}
				}
				
				if Settings.ClassIcon and IconList[Settings.ClassIcon] then
					funcs.ExplorerIcons = {["MapId"] = IconList[Settings.ClassIcon].MapId,
						["Icons"] = IconList[Settings.ClassIcon].Icons,
						["IconSize"] = IconList[Settings.ClassIcon].IconSize,
						["Witdh"] = IconList[Settings.ClassIcon].Witdh,
						["Height"] = IconList[Settings.ClassIcon].Height}
				else
					funcs.ExplorerIcons = {["MapId"] = IconList.Old.MapId, ["Icons"] = IconList.Old.Icons,["IconSize"] = IconList.Old.IconSize }
				end

				funcs.GetLabel = function(self)
					local label = Instance.new("ImageLabel")
					self:SetupLabel(label)
					return label
				end

				funcs.SetupLabel = function(self,obj)
					obj.BackgroundTransparency = 1
					obj.ImageRectOffset = Vector2.new(0, 0)
					obj.ImageRectSize = Vector2.new(self.IconSizeX, self.IconSizeY)
					obj.ScaleType = Enum.ScaleType.Crop
					obj.Size = UDim2.new(0, self.IconSizeX, 0, self.IconSizeY)
				end

				funcs.Display = function(self,obj,index)
			obj.Image = self.MapId
			obj.ImageRectSize = Vector2.new(self.IconSizeX, self.IconSizeY)
			if not self.NumX then
				obj.ImageRectOffset = Vector2.new(self.IconSizeX*index, 0)
			else
				obj.ImageRectOffset = Vector2.new(self.IconSizeX*(index % self.NumX), self.IconSizeY*math.floor(index / self.NumX))
			end
		end

				funcs.DisplayByKey = function(self, obj, key)
					if self.IndexDict[key] then
						self:Display(obj, self.IndexDict[key])
					else
						local rmdEntry = RMD.Classes[obj.ClassName]
						Explorer.ClassIcons:Display(obj, rmdEntry and rmdEntry.ExplorerImageIndex or 0)
					end
				end

				funcs.IconDehash = function(self, _id)
					return math.floor(_id / 14 % 14), math.floor(_id % 14)
				end
				
				funcs.GetExplorerIcon = function(self, obj, index)
					if Settings.ClassIcon == "Vanilla3" then
						obj.Size = UDim2.fromOffset(16, 16)
						index = (self.ExplorerIcons.Icons[index] or 250) - 1
						obj.ImageRectOffset = Vector2.new(funcs.ExplorerIcons.IconSize * (index % funcs.ExplorerIcons.Witdh), funcs.ExplorerIcons.IconSize * math.floor(index / funcs.ExplorerIcons.Witdh))
						obj.ImageRectSize = Vector2.new(funcs.ExplorerIcons.IconSize, funcs.ExplorerIcons.IconSize)
					elseif Settings.ClassIcon == "Old" then
						index = (self.ExplorerIcons.Icons[index] or 0)
						local row, col = math.floor(index / 14 % 14), math.floor(index % 14)
						local MapSize = Vector2.new(256, 256)
						local pad, border = 2, 1
						obj.Position = UDim2.new(-col - (pad * (col + 1) + border) / funcs.ExplorerIcons.IconSize, 0, -row - (pad * (row + 1) + border) / funcs.ExplorerIcons.IconSize, 0)
						obj.Size = UDim2.new(MapSize.X / funcs.ExplorerIcons.IconSize, 0, MapSize.Y / funcs.ExplorerIcons.IconSize, 0)
					elseif Settings.ClassIcon == "NewLight" or Settings.ClassIcon == "NewDark" then
						local isService = string.find(index, "Service") and cloneref(game:GetService(index))
						obj.Size = UDim2.fromOffset(16, 16)
						index = (self.ExplorerIcons.Icons[index] or (isService and self.ExplorerIcons.Icons.Service) or self.ExplorerIcons.Icons.Placeholder or 1) - 1
						obj.ImageRectOffset = Vector2.new(funcs.ExplorerIcons.IconSize * (index % funcs.ExplorerIcons.Witdh), funcs.ExplorerIcons.IconSize * math.floor(index / funcs.ExplorerIcons.Witdh))
						obj.ImageRectSize = Vector2.new(funcs.ExplorerIcons.IconSize, funcs.ExplorerIcons.IconSize)
					end
				end

				funcs.DisplayExplorerIcons = function(self, Frame, index)
					local mapid = tostring(self.ExplorerIcons.MapId)
					local final = string.find(mapid, "://") and mapid or ("rbxassetid://" .. mapid)
					
					local existing = Frame:FindFirstChild("IconMap")
					if existing then
						if existing.Image ~= final then
							existing:Destroy()
							existing = nil
						end
					end

					if existing then
						self:GetExplorerIcon(existing, index)
					else
						Frame.ClipsDescendants = true

						local obj = Instance.new("ImageLabel", Frame)
						obj.BackgroundTransparency = 1
						obj.Image = final
						obj.Name = "IconMap"
						self:GetExplorerIcon(obj, index)
					end
				end

				funcs.SetDict = function(self,dict)
					self.IndexDict = dict
				end

				local mt = {}
				mt.__index = funcs

				local function new(mapId,mapSizeX,mapSizeY,iconSizeX,iconSizeY)
					local obj = setmetatable({
						MapId = mapId,
						MapSizeX = mapSizeX,
						MapSizeY = mapSizeY,
						IconSizeX = iconSizeX,
						IconSizeY = iconSizeY,
						NumX = mapSizeX/iconSizeX,
						IndexDict = {}
					}, mt)
					return obj
				end

				local function newLinear(mapId,iconSizeX,iconSizeY)
					local obj = setmetatable({
						MapId = mapId,
						IconSizeX = iconSizeX,
						IconSizeY = iconSizeY,
						IndexDict = {}
					},mt)
					return obj
				end
				
				local function getIconDataFromName(name)
			return IconList[name] or error("Name not found")
		end

		local function UpdateExplorerIcons(name)
			if IconList[name] then
				local iconData = IconList[name]
				funcs.ExplorerIcons = {
					["MapId"] = iconData.MapId,
					["Icons"] = iconData.Icons,
					["IconSize"] = iconData.IconSize,
					["Witdh"] = iconData.Witdh,
					["Height"] = iconData.Height
				}
			else
				funcs.ExplorerIcons = { ["MapId"] = IconList.Old.MapId, ["Icons"] = IconList.Old.Icons, ["IconSize"] = IconList.Old.IconSize }
			end
		end

		return {new = new, newLinear = newLinear, getIconDataFromName = getIconDataFromName, UpdateExplorerIcons = UpdateExplorerIcons}
	end)()

			Lib.ScrollBar = (function()
				local funcs = {}
				local user = service.UserInputService
				local mouse = plr:GetMouse()
				local checkMouseInGui = Lib.CheckMouseInGui
				local createArrow = Lib.CreateArrow

				local function drawThumb(self)
					local total = self.TotalSpace
					local visible = self.VisibleSpace
					local index = self.Index
					local scrollThumb = self.GuiElems.ScrollThumb
					local scrollThumbFrame = self.GuiElems.ScrollThumbFrame

					if not (self:CanScrollUp()	or self:CanScrollDown()) then
						scrollThumb.Visible = false
					else
						scrollThumb.Visible = true
					end

					if self.Horizontal then
						scrollThumb.Size = UDim2.new(visible/total,0,1,0)
						if scrollThumb.AbsoluteSize.X < 16 then
							scrollThumb.Size = UDim2.new(0,16,1,0)
						end
						local fs = scrollThumbFrame.AbsoluteSize.X
						local bs = scrollThumb.AbsoluteSize.X
						scrollThumb.Position = UDim2.new(self:GetScrollPercent()*(fs-bs)/fs,0,0,0)
					else
						scrollThumb.Size = UDim2.new(1,0,visible/total,0)
						if scrollThumb.AbsoluteSize.Y < 16 then
							scrollThumb.Size = UDim2.new(1,0,0,16)
						end
						local fs = scrollThumbFrame.AbsoluteSize.Y
						local bs = scrollThumb.AbsoluteSize.Y
						scrollThumb.Position = UDim2.new(0,0,self:GetScrollPercent()*(fs-bs)/fs,0)
					end
				end

				local function createFrame(self)
					local newFrame = createSimple("Frame",{Style=0,Active=true,AnchorPoint=Vector2.new(0,0),BackgroundColor3=Color3.new(0.35294118523598,0.35294118523598,0.35294118523598),BackgroundTransparency=0,BorderColor3=Color3.new(0.10588236153126,0.16470588743687,0.20784315466881),BorderSizePixel=0,ClipsDescendants=false,Draggable=false,Position=UDim2.new(1,-16,0,0),Rotation=0,Selectable=false,Size=UDim2.new(0,16,1,0),SizeConstraint=0,Visible=true,ZIndex=1,Name="ScrollBar",})
					local button1, button2

					if self.Horizontal then
						newFrame.Size = UDim2.new(1,0,0,16)
						button1 = createSimple("ImageButton",{
							Parent = newFrame,
							Name = "Left",
							Size = UDim2.new(0,16,0,16),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							AutoButtonColor = false
						})
						createArrow(16,4,"left").Parent = button1
						button2 = createSimple("ImageButton",{
							Parent = newFrame,
							Name = "Right",
							Position = UDim2.new(1,-16,0,0),
							Size = UDim2.new(0,16,0,16),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							AutoButtonColor = false
						})
						createArrow(16,4,"right").Parent = button2
					else
						newFrame.Size = UDim2.new(0,16,1,0)
						button1 = createSimple("ImageButton",{
							Parent = newFrame,
							Name = "Up",
							Size = UDim2.new(0,16,0,16),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							AutoButtonColor = false
						})
						createArrow(16,4,"up").Parent = button1
						button2 = createSimple("ImageButton",{
							Parent = newFrame,
							Name = "Down",
							Position = UDim2.new(0,0,1,-16),
							Size = UDim2.new(0,16,0,16),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							AutoButtonColor = false
						})
						createArrow(16,4,"down").Parent = button2
					end

					local scrollThumbFrame = createSimple("ImageButton", {
						BackgroundTransparency = 1,
						Parent = newFrame
					})
					if self.Horizontal then
						scrollThumbFrame.Position = UDim2.new(0,16,0,0)
						scrollThumbFrame.Size = UDim2.new(1,-32,1,0)
					else
						scrollThumbFrame.Position = UDim2.new(0,0,0,16)
						scrollThumbFrame.Size = UDim2.new(1,0,1,-32)
					end

					local scrollThumb = createSimple("Frame", {
						BackgroundColor3 = Color3.new(120/255, 120/255, 120/255),
						BorderSizePixel = 0,
						Parent = scrollThumbFrame
					})

					local markerFrame = createSimple("Frame", {
						BackgroundTransparency = 1,
						Name = "Markers",
						Size = UDim2.new(1, 0, 1, 0),
						Parent = scrollThumbFrame
					})

					local buttonPress = false
					local thumbPress = false
					local thumbFramePress = false

					local function handleButtonPress(button, scrollDirection)
						if self:CanScroll(scrollDirection) then
							button.BackgroundTransparency = 0.5
							self:ScrollToDirection(scrollDirection)
							self.Scrolled:Fire()
							local buttonTick = tick()
							local releaseEvent
							releaseEvent = user.InputEnded:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
									releaseEvent:Disconnect()
									button.BackgroundTransparency = checkMouseInGui(button) and 0.8 or 1
									buttonPress = false
								end
							end)
							while buttonPress do
								if tick() - buttonTick >= 0.25 and self:CanScroll(scrollDirection) then
									self:ScrollToDirection(scrollDirection)
									self.Scrolled:Fire()
								end
								task.wait()
							end
						end
					end

					button1.MouseButton1Down:Connect(function(input)
						buttonPress = true
						handleButtonPress(button1, "Up")
					end)

					button1.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							button1.BackgroundTransparency = 1
						end
					end)

					button2.MouseButton1Down:Connect(function(input)
						buttonPress = true
						handleButtonPress(button2, "Down")
					end)

					button2.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							button2.BackgroundTransparency = 1
						end
					end)

					scrollThumb.InputBegan:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
							local dir = self.Horizontal and "X" or "Y"
							local lastThumbPos = nil
							thumbPress = true
							scrollThumb.BackgroundTransparency = 0
							local mouseOffset = mouse[dir] - scrollThumb.AbsolutePosition[dir]
							local releaseEvent
							local mouseEvent

							releaseEvent = user.InputEnded:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
									releaseEvent:Disconnect()
									if mouseEvent then mouseEvent:Disconnect() end
									scrollThumb.BackgroundTransparency = 0.2
									thumbPress = false
								end
							end)

							mouseEvent = user.InputChanged:Connect(function(input)
								if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and thumbPress then
									local thumbFrameSize = scrollThumbFrame.AbsoluteSize[dir] - scrollThumb.AbsoluteSize[dir]
									local pos = mouse[dir] - scrollThumbFrame.AbsolutePosition[dir] - mouseOffset
									if pos > thumbFrameSize then pos = thumbFrameSize
									elseif pos < 0 then pos = 0 end
									if lastThumbPos ~= pos then
										lastThumbPos = pos
										self:ScrollTo(math.floor(0.5 + pos / thumbFrameSize * (self.TotalSpace - self.VisibleSpace)))
									end
								end
							end)
						end
					end)

					scrollThumb.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							scrollThumb.BackgroundTransparency = 0
						end
					end)

					scrollThumbFrame.InputBegan:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not checkMouseInGui(scrollThumb) then
							local dir = self.Horizontal and "X" or "Y"
							local scrollDir = (mouse[dir] >= scrollThumb.AbsolutePosition[dir] + scrollThumb.AbsoluteSize[dir]) and 1 or 0
							local function doTick()
								local scrollSize = self.VisibleSpace - 1
								if scrollDir == 0 and mouse[dir] < scrollThumb.AbsolutePosition[dir] then
									self:ScrollTo(self.Index - scrollSize)
								elseif scrollDir == 1 and mouse[dir] >= scrollThumb.AbsolutePosition[dir] + scrollThumb.AbsoluteSize[dir] then
									self:ScrollTo(self.Index + scrollSize)
								end
							end

							thumbPress = false
							thumbFramePress = true
							doTick()
							local thumbFrameTick = tick()
							local releaseEvent
							releaseEvent = user.InputEnded:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
									releaseEvent:Disconnect()
									thumbFramePress = false
								end
							end)

							while thumbFramePress do
								if tick() - thumbFrameTick >= 0.3 and checkMouseInGui(scrollThumbFrame) then
									doTick()
								end
								task.wait()
							end
						end
					end)

					newFrame.MouseWheelForward:Connect(function()
						self:ScrollTo(self.Index - self.WheelIncrement)
					end)

					newFrame.MouseWheelBackward:Connect(function()
						self:ScrollTo(self.Index + self.WheelIncrement)
					end)

					self.GuiElems.ScrollThumb = scrollThumb
					self.GuiElems.ScrollThumbFrame = scrollThumbFrame
					self.GuiElems.Button1 = button1
					self.GuiElems.Button2 = button2
					self.GuiElems.MarkerFrame = markerFrame

					return newFrame
				end

				funcs.Update = function(self,nocallback)
					local total = self.TotalSpace
					local visible = self.VisibleSpace
					local index = self.Index
					local button1 = self.GuiElems.Button1
					local button2 = self.GuiElems.Button2

					self.Index = math.clamp(self.Index, 0, math.max(0, total - visible))

					if self.LastTotalSpace ~= self.TotalSpace then
						self.LastTotalSpace = self.TotalSpace
						self:UpdateMarkers()
					end

					if self:CanScrollUp() then
						for i,v in pairs(button1.Arrow:GetChildren()) do
							v.BackgroundTransparency = 0
						end
					else
						button1.BackgroundTransparency = 1
						for i,v in pairs(button1.Arrow:GetChildren()) do
							v.BackgroundTransparency = 0.5
						end
					end
					if self:CanScrollDown() then
						for i,v in pairs(button2.Arrow:GetChildren()) do
							v.BackgroundTransparency = 0
						end
					else
						button2.BackgroundTransparency = 1
						for i,v in pairs(button2.Arrow:GetChildren()) do
							v.BackgroundTransparency = 0.5
						end
					end

					drawThumb(self)
				end

				funcs.UpdateMarkers = function(self)
					local markerFrame = self.GuiElems.MarkerFrame
					markerFrame:ClearAllChildren()

					for i,v in pairs(self.Markers) do
						if i < self.TotalSpace then
							createSimple("Frame", {
								BackgroundTransparency = 0,
								BackgroundColor3 = v,
								BorderSizePixel = 0,
								Position = self.Horizontal and UDim2.new(i/self.TotalSpace,0,1,-6) or UDim2.new(1,-6,i/self.TotalSpace,0),
								Size = self.Horizontal and UDim2.new(0,1,0,6) or UDim2.new(0,6,0,1),
								Name = "Marker"..tostring(i),
								Parent = markerFrame
							})
						end
					end
				end

				funcs.AddMarker = function(self,ind,color)
					self.Markers[ind] = color or Color3.new(0,0,0)
				end
				funcs.ScrollTo = function(self, ind, nocallback)
					self.Index = ind
					self:Update()
					if not nocallback then
						self.Scrolled:Fire()
					end
				end
				funcs.ScrollUp = function(self)
					self.Index = self.Index - self.Increment
					self:Update()
				end
				funcs.CanScroll = function(self, direction)
					if direction == "Up" then
						return self:CanScrollUp()
					elseif direction == "Down" then
						return self:CanScrollDown()
					end
					return false
				end
				funcs.ScrollDown = function(self)
					self.Index = self.Index + self.Increment
					self:Update()
				end
				funcs.CanScrollUp = function(self)
					return self.Index > 0
				end
				funcs.CanScrollDown = function(self)
					return self.Index + self.VisibleSpace < self.TotalSpace
				end
				funcs.GetScrollPercent = function(self)
					return self.Index/(self.TotalSpace-self.VisibleSpace)
				end
				funcs.SetScrollPercent = function(self,perc)
					self.Index = math.floor(perc*(self.TotalSpace-self.VisibleSpace))
					self:Update()
				end
				funcs.ScrollToDirection = function(self, Direaction)
					if Direaction == "Up" then
						self:ScrollUp()
					elseif Direaction == "Down" then
						self:ScrollDown()
					end
				end

				funcs.Texture = function(self,data)
					self.ThumbColor = data.ThumbColor or Color3.new(0,0,0)
					self.ThumbSelectColor = data.ThumbSelectColor or Color3.new(0,0,0)
					self.GuiElems.ScrollThumb.BackgroundColor3 = data.ThumbColor or Color3.new(0,0,0)
					self.Gui.BackgroundColor3 = data.FrameColor or Color3.new(0,0,0)
					self.GuiElems.Button1.BackgroundColor3 = data.ButtonColor or Color3.new(0,0,0)
					self.GuiElems.Button2.BackgroundColor3 = data.ButtonColor or Color3.new(0,0,0)
					for i,v in pairs(self.GuiElems.Button1.Arrow:GetChildren()) do
						v.BackgroundColor3 = data.ArrowColor or Color3.new(0,0,0)
					end
					for i,v in pairs(self.GuiElems.Button2.Arrow:GetChildren()) do
						v.BackgroundColor3 = data.ArrowColor or Color3.new(0,0,0)
					end
				end

				funcs.SetScrollFrame = function(self,frame)
					if self.ScrollUpEvent then self.ScrollUpEvent:Disconnect() self.ScrollUpEvent = nil end
					if self.ScrollDownEvent then self.ScrollDownEvent:Disconnect() self.ScrollDownEvent = nil end
					self.ScrollUpEvent = frame.MouseWheelForward:Connect(function() self:ScrollTo(self.Index - self.WheelIncrement) end)
					self.ScrollDownEvent = frame.MouseWheelBackward:Connect(function() self:ScrollTo(self.Index + self.WheelIncrement) end)
				end

				local mt = {}
				mt.__index = funcs

				local function new(hor)
					local obj = setmetatable({
						Index = 0,
						VisibleSpace = 0,
						TotalSpace = 0,
						Increment = 1,
						WheelIncrement = 1,
						Markers = {},
						GuiElems = {},
						Horizontal = hor,
						LastTotalSpace = 0,
						Scrolled = Lib.Signal.new()
					},mt)
					obj.Gui = createFrame(obj)
					obj:Texture({
						ThumbColor = Color3.fromRGB(60,60,60),
						ThumbSelectColor = Color3.fromRGB(75,75,75),
						ArrowColor = Color3.new(1,1,1),
						FrameColor = Color3.fromRGB(40,40,40),
						ButtonColor = Color3.fromRGB(75,75,75)
					})
					return obj
				end

				return {new = new}
			end)()

			Lib.Window = (function()
				local funcs = {}
				local static = {MinWidth = 200, FreeWidth = 200, CreatedWindows = {}}
				local mouse = plr:GetMouse()
				local sidesGui, alignIndicator
				local visibleWindows = {}
				local leftSide = {Width = 300, Windows = {}, ResizeCons = {}, Hidden = true}
				local rightSide = {Width = 300, Windows = {}, ResizeCons = {}, Hidden = true}

				local displayOrderStart
				local sideDisplayOrder
				local sideTweenInfo = TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
				local tweens = {}
				local isA = game.IsA

				local theme = {
					MainColor1 = Color3.fromRGB(52,52,52),
					MainColor2 = Color3.fromRGB(45,45,45),
					Button = Color3.fromRGB(60,60,60)
				}

				local function stopTweens()
					for i = 1,#tweens do
						tweens[i]:Cancel()
					end
					tweens = {}
				end

				local function resizeHook(self,resizer,dir)
			local pressing = false
			
			local guiMain = self.GuiElems.Main
			
			resizer.MouseEnter:Connect(function() resizer.BackgroundTransparency = 0.5 end)
			resizer.MouseButton1Down:Connect(function() pressing = true resizer.BackgroundTransparency = 0.5 end)
			resizer.MouseButton1Up:Connect(function() pressing = false resizer.BackgroundTransparency = 1 end)
			
			resizer.InputBegan:Connect(function(input)
				if not self.Dragging and not self.Resizing and self.Resizable and self.ResizableInternal and pressing then
					local isH = dir:find("[WE]") and true
					local isV = dir:find("[NS]") and true
					local signX = dir:find("W",1,true) and -1 or 1
					local signY = dir:find("N",1,true) and -1 or 1

					if self.Minimized and isV then return end
					
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent, mouseEvent

						local offX = input.Position.X - resizer.AbsolutePosition.X
						local offY = input.Position.Y - resizer.AbsolutePosition.Y

						self.Resizing = resizer
						
						releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								if mouseEvent then mouseEvent:Disconnect() end
								self.Resizing = false
								resizer.BackgroundTransparency = 1
							end
						end)

						mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
							if self.Resizable and self.ResizableInternal and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
								self:StopTweens()
								local deltaX = input.Position.X - resizer.AbsolutePosition.X - offX
								local deltaY = input.Position.Y - resizer.AbsolutePosition.Y - offY

								if guiMain.AbsoluteSize.X + deltaX * signX < self.MinX then deltaX = signX * (self.MinX - guiMain.AbsoluteSize.X) end
								if guiMain.AbsoluteSize.Y + deltaY * signY < self.MinY then deltaY = signY * (self.MinY - guiMain.AbsoluteSize.Y) end
								if signY < 0 and guiMain.AbsolutePosition.Y + deltaY < 0 then deltaY = -guiMain.AbsolutePosition.Y end

								guiMain.Position = guiMain.Position + UDim2.new(0, (signX < 0 and deltaX or 0), 0, (signY < 0 and deltaY or 0))
								self.SizeX = self.SizeX + (isH and deltaX * signX or 0)
								self.SizeY = self.SizeY + (isV and deltaY * signY or 0)
								guiMain.Size = UDim2.new(0, self.SizeX, 0, self.Minimized and 20 or self.SizeY)
							end
						end)
					end
				end
			end)

			resizer.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and self.Resizing ~= resizer then
					resizer.BackgroundTransparency = 1
				end
			end)
		end

				local updateWindows

				local function moveToTop(window)
					local found = table.find(visibleWindows,window)
					if found then
						table.remove(visibleWindows,found)
						table.insert(visibleWindows,1,window)
						updateWindows()
					end
				end

				local function sideHasRoom(side,neededSize)
					local maxY = sidesGui.AbsoluteSize.Y - (math.max(0,#side.Windows - 1) * 4)
					local inc = 0
					for i,v in pairs(side.Windows) do
						inc = inc + (v.MinY or 100)
						if inc > maxY - neededSize then return false end
					end

					return true
				end

				local function getSideInsertPos(side,curY)
					local pos = #side.Windows + 1
					local range = {0,sidesGui.AbsoluteSize.Y}

					for i,v in pairs(side.Windows) do
						local midPos = v.PosY + v.SizeY/2
						if curY <= midPos then
							pos = i
							range[2] = midPos
							break
						else
							range[1] = midPos
						end
					end

					return pos,range
				end

				local function focusInput(self,obj)
					if isA(obj,"GuiButton") then
						obj.MouseButton1Down:Connect(function()
							moveToTop(self)
						end)
					elseif isA(obj,"TextBox") then
						obj.Focused:Connect(function()
							moveToTop(self)
						end)
					end
				end

				local createGui = function(self)
					local gui = create({
						{1,"ScreenGui",{Name="Window",}},
						{2,"Frame",{Active=true,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Main",Parent={1},Position=UDim2.new(0.40000000596046,0,0.40000000596046,0),Size=UDim2.new(0,300,0,300),}},
						{3,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,Name="Content",Parent={2},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),ClipsDescendants=true}},
						{4,"Frame",{BackgroundColor3=Color3.fromRGB(33,33,33),BorderSizePixel=0,Name="Line",Parent={3},Size=UDim2.new(1,0,0,1),}},
						{5,"TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="TopBar",Parent={2},Size=UDim2.new(1,0,0,20),}},
						{6,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={5},Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-10,0,20),Text="Window",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
						{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Close",Parent={5},Position=UDim2.new(1,-18,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
						{8,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/close3.png")) and getcustomasset("DEX_REContinued/Images/close3.png") or "rbxassetid://5054663650",Parent={7},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,10,0,10),}},
						{9,"UICorner",{CornerRadius=UDim.new(0,4),Parent={7},}},
						{10,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Minimize",Parent={5},Position=UDim2.new(1,-36,0,2),Size=UDim2.new(0,16,0,16),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
						{11,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/minimize2.png")) and getcustomasset("DEX_REContinued/Images/minimize2.png") or "rbxassetid://5034768003",Parent={10},Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,10,0,10),}},
						{12,"UICorner",{CornerRadius=UDim.new(0,4),Parent={10},}},
						{13,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image=(getcustomasset and isfile and isfile("DEX_REContinued/borders.png")) and getcustomasset("DEX_REContinued/borders.png") or "rbxassetid://1427967925",Name="Outlines",Parent={2},Position=UDim2.new(0,-5,0,-5),ScaleType=1,Size=UDim2.new(1,10,1,10),SliceCenter=Rect.new(6,6,25,25),TileSize=UDim2.new(0,20,0,20),}},
						{14,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="ResizeControls",Parent={2},Position=UDim2.new(0,-5,0,-5),Size=UDim2.new(1,10,1,10),}},
						{15,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="North",Parent={14},Position=UDim2.new(0,5,0,0),Size=UDim2.new(1,-10,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{16,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="South",Parent={14},Position=UDim2.new(0,5,1,-5),Size=UDim2.new(1,-10,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{17,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="NorthEast",Parent={14},Position=UDim2.new(1,-5,0,0),Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{18,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="East",Parent={14},Position=UDim2.new(1,-5,0,5),Size=UDim2.new(0,5,1,-10),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{19,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="West",Parent={14},Position=UDim2.new(0,0,0,5),Size=UDim2.new(0,5,1,-10),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{20,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="SouthEast",Parent={14},Position=UDim2.new(1,-5,1,-5),Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{21,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="NorthWest",Parent={14},Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{22,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.27450981736183,0.27450981736183,0.27450981736183),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="SouthWest",Parent={14},Position=UDim2.new(0,0,1,-5),Size=UDim2.new(0,5,0,5),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
					})

					local guiMain = gui.Main
					local guiTopBar = guiMain.TopBar
					local guiResizeControls = guiMain.ResizeControls

					self.GuiElems.Main = guiMain
					self.GuiElems.TopBar = guiMain.TopBar
					self.GuiElems.Content = guiMain.Content
					self.GuiElems.Line = guiMain.Content.Line
					self.GuiElems.Outlines = guiMain.Outlines
					self.GuiElems.Title = guiTopBar.Title
					self.GuiElems.Close = guiTopBar.Close
					self.GuiElems.Minimize = guiTopBar.Minimize
					self.GuiElems.ResizeControls = guiResizeControls
					self.ContentPane = guiMain.Content

					local ButtonDown = false
					guiTopBar.MouseButton1Down:Connect(function() ButtonDown = true end)
					guiTopBar.MouseButton1Up:Connect(function() ButtonDown = false end)

					guiTopBar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							if self.Draggable then
								local releaseEvent, mouseEvent

								local maxX = sidesGui.AbsoluteSize.X
								local initX = guiMain.AbsolutePosition.X
								local initY = guiMain.AbsolutePosition.Y
								local offX = input.Position.X - initX
								local offY = input.Position.Y - initY

								local alignInsertPos, alignInsertSide

								guiDragging = true

								releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
										releaseEvent:Disconnect()
										if mouseEvent then mouseEvent:Disconnect() end
										guiDragging = false
										alignIndicator.Parent = nil
										if alignInsertSide then
											local targetSide = (alignInsertSide == "left" and leftSide) or (alignInsertSide == "right" and rightSide)
											self:AlignTo(targetSide, alignInsertPos)
										end
									end
								end)

								mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
									if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and self.Draggable and not self.Closed and ButtonDown then
										if self.Aligned then
											if leftSide.Resizing or rightSide.Resizing then return end
											local posX, posY = input.Position.X - offX, input.Position.Y - offY
											local delta = math.sqrt((posX - initX)^2 + (posY - initY)^2)
											if delta >= 5 then
												self:SetAligned(false)
											end
										else
											local inputX, inputY = input.Position.X, input.Position.Y
											local posX, posY = inputX - offX, inputY - offY
											if posY < 0 then posY = 0 end
											guiMain.Position = UDim2.new(0, posX, 0, posY)

											if self.Resizable and self.Alignable then
												if inputX < 25 then
													if sideHasRoom(leftSide, self.MinY or 100) then
														local insertPos, range = getSideInsertPos(leftSide, inputY)
														alignIndicator.Indicator.Position = UDim2.new(0, -15, 0, range[1])
														alignIndicator.Indicator.Size = UDim2.new(0, 40, 0, range[2] - range[1])
														Lib.ShowGui(alignIndicator)
														alignInsertPos = insertPos
														alignInsertSide = "left"
														return
													end
												elseif inputX >= maxX - 25 then
													if sideHasRoom(rightSide, self.MinY or 100) then
														local insertPos, range = getSideInsertPos(rightSide, inputY)
														alignIndicator.Indicator.Position = UDim2.new(0, maxX - 25, 0, range[1])
														alignIndicator.Indicator.Size = UDim2.new(0, 40, 0, range[2] - range[1])
														Lib.ShowGui(alignIndicator)
														alignInsertPos = insertPos
														alignInsertSide = "right"
														return
													end
												end
											end
											alignIndicator.Parent = nil
											alignInsertPos = nil
											alignInsertSide = nil
										end
									end
								end)
							end
						end
					end)

					guiTopBar.Close.MouseButton1Click:Connect(function()
						if self.Closed then return end
						self:Close()
					end)

					guiTopBar.Minimize.MouseButton1Click:Connect(function()
						if self.Closed then return end
						if self.Aligned then
							self:SetAligned(false)
						else
							self:SetMinimized()
						end
					end)

					guiTopBar.Minimize.MouseButton2Click:Connect(function()
						if self.Closed then return end
						if not self.Aligned then
							self:SetMinimized(nil,2)
							guiTopBar.Minimize.BackgroundTransparency = 1
						end
					end)

					guiMain.InputBegan:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not self.Aligned and not self.Closed then
							moveToTop(self)
						end
					end)

					guiMain:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
						local absPos = guiMain.AbsolutePosition
						self.PosX = absPos.X
						self.PosY = absPos.Y
					end)

					resizeHook(self,guiResizeControls.North,"N")
					resizeHook(self,guiResizeControls.NorthEast,"NE")
					resizeHook(self,guiResizeControls.East,"E")
					resizeHook(self,guiResizeControls.SouthEast,"SE")
					resizeHook(self,guiResizeControls.South,"S")
					resizeHook(self,guiResizeControls.SouthWest,"SW")
					resizeHook(self,guiResizeControls.West,"W")
					resizeHook(self,guiResizeControls.NorthWest,"NW")

					guiMain.Size = UDim2.new(0,self.SizeX,0,self.SizeY)

					if Settings.Window.Transparency then
						self.GuiElems.Content.BackgroundTransparency = Settings.Window.Transparency
					end

					gui.DescendantAdded:Connect(function(obj) focusInput(self,obj) end)
					local descs = gui:GetDescendants()
					for i = 1,#descs do
						focusInput(self,descs[i])
					end

					self.MinimizeAnim = Lib.ButtonAnim(guiTopBar.Minimize)
					self.CloseAnim = Lib.ButtonAnim(guiTopBar.Close)

					return gui
				end

				local function updateSideFrames(noTween)
					stopTweens()
					leftSide.Frame.Size = UDim2.new(0,leftSide.Width,1,0)
					rightSide.Frame.Size = UDim2.new(0,rightSide.Width,1,0)
					leftSide.Frame.Resizer.Position = UDim2.new(0,leftSide.Width,0,0)
					rightSide.Frame.Resizer.Position = UDim2.new(0,-5,0,0)

					--leftSide.Frame.Visible = (#leftSide.Windows > 0)
					--rightSide.Frame.Visible = (#rightSide.Windows > 0)

			--[[if #leftSide.Windows > 0 and leftSide.Frame.Position == UDim2.new(0,-leftSide.Width-5,0,0) then
				leftSide.Frame:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
			elseif #leftSide.Windows == 0 and leftSide.Frame.Position == UDim2.new(0,0,0,0) then
				leftSide.Frame:TweenPosition(UDim2.new(0,-leftSide.Width-5,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
			end
			local rightTweenPos = (#rightSide.Windows == 0 and UDim2.new(1,5,0,0) or UDim2.new(1,-rightSide.Width,0,0))
			rightSide.Frame:TweenPosition(rightTweenPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)]]
					local leftHidden = #leftSide.Windows == 0 or leftSide.Hidden
					local rightHidden = #rightSide.Windows == 0 or rightSide.Hidden
					local leftPos = (leftHidden and UDim2.new(0,-leftSide.Width-10,0,0) or UDim2.new(0,0,0,0))
					local rightPos = (rightHidden and UDim2.new(1,10,0,0) or UDim2.new(1,-rightSide.Width,0,0))

					sidesGui.LeftToggle.Text = leftHidden and ">" or "<"
					sidesGui.RightToggle.Text = rightHidden and "<" or ">"

					if not noTween then
						local function insertTween(...)
							local tween = service.TweenService:Create(...)
							tweens[#tweens+1] = tween
							tween:Play()
						end
						insertTween(leftSide.Frame,sideTweenInfo,{Position = leftPos})
						insertTween(rightSide.Frame,sideTweenInfo,{Position = rightPos})
						insertTween(sidesGui.LeftToggle,sideTweenInfo,{Position = UDim2.new(0,#leftSide.Windows == 0 and -16 or 0,0,-36)})
						insertTween(sidesGui.RightToggle,sideTweenInfo,{Position = UDim2.new(1,#rightSide.Windows == 0 and 0 or -16,0,-36)})
					else
						leftSide.Frame.Position = leftPos
						rightSide.Frame.Position = rightPos
						sidesGui.LeftToggle.Position = UDim2.new(0,#leftSide.Windows == 0 and -16 or 0,0,-36)
						sidesGui.RightToggle.Position = UDim2.new(1,#rightSide.Windows == 0 and 0 or -16,0,-36)
					end
				end

				local function getSideFramePos(side)
					local leftHidden = #leftSide.Windows == 0 or leftSide.Hidden
					local rightHidden = #rightSide.Windows == 0 or rightSide.Hidden
					if side == leftSide then
						return (leftHidden and UDim2.new(0,-leftSide.Width-10,0,0) or UDim2.new(0,0,0,0))
					else
						return (rightHidden and UDim2.new(1,10,0,0) or UDim2.new(1,-rightSide.Width,0,0))
					end
				end

				local function sideResized(side)
					local currentPos = 0
					local sideFramePos = getSideFramePos(side)
					for i,v in pairs(side.Windows) do
						v.SizeX = side.Width
						v.GuiElems.Main.Size = UDim2.new(0,side.Width,0,v.SizeY)
						v.GuiElems.Main.Position = UDim2.new(sideFramePos.X.Scale,sideFramePos.X.Offset,0,currentPos)
						currentPos = currentPos + v.SizeY+4
					end
				end

				local function sideResizerHook(resizer,dir,side,pos)
					local mouse = Main.Mouse
					local windows = side.Windows

					resizer.InputBegan:Connect(function(input)
						if not side.Resizing then
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								resizer.BackgroundColor3 = theme.MainColor2
							elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								local releaseEvent, inputEvent

								local offX = input.Position.X - resizer.AbsolutePosition.X
								local offY = input.Position.Y - resizer.AbsolutePosition.Y

								side.Resizing = resizer
								resizer.BackgroundColor3 = theme.MainColor2

								releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
										releaseEvent:Disconnect()
										if inputEvent then inputEvent:Disconnect() end
										side.Resizing = false
										resizer.BackgroundColor3 = theme.Button
									end
								end)

								inputEvent = service.UserInputService.InputChanged:Connect(function(input)
									if not resizer.Parent then
										releaseEvent:Disconnect()
										if inputEvent then inputEvent:Disconnect() end
										side.Resizing = false
										return
									end

									if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
										if dir == "V" then
											local delta = input.Position.Y - resizer.AbsolutePosition.Y - offY

											if delta > 0 then
												local neededSize = delta
												for i = pos + 1, #windows do
													local window = windows[i]
													local newSize = math.max(window.SizeY - neededSize, (window.MinY or 100))
													neededSize = neededSize - (window.SizeY - newSize)
													window.SizeY = newSize
												end
												windows[pos].SizeY = windows[pos].SizeY + math.max(0, delta - neededSize)
											else
												local neededSize = -delta
												for i = pos, 1, -1 do
													local window = windows[i]
													local newSize = math.max(window.SizeY - neededSize, (window.MinY or 100))
													neededSize = neededSize - (window.SizeY - newSize)
													window.SizeY = newSize
												end
												windows[pos + 1].SizeY = windows[pos + 1].SizeY + math.max(0, -delta - neededSize)
											end

											updateSideFrames()
											sideResized(side)
										elseif dir == "H" then
											local maxWidth = math.max(300, sidesGui.AbsoluteSize.X - static.FreeWidth)
											local otherSide = (side == leftSide and rightSide or leftSide)
											local delta = input.Position.X - resizer.AbsolutePosition.X - offX
											delta = (side == leftSide and delta or -delta)

											local proposedSize = math.max(static.MinWidth, side.Width + delta)
											if proposedSize + otherSide.Width <= maxWidth then
												side.Width = proposedSize
											else
												local newOtherSize = maxWidth - proposedSize
												if newOtherSize >= static.MinWidth then
													side.Width = proposedSize
													otherSide.Width = newOtherSize
												else
													side.Width = maxWidth - static.MinWidth
													otherSide.Width = static.MinWidth
												end
											end

											updateSideFrames(true)
											sideResized(side)
											sideResized(otherSide)
										end
									end
								end)
							end
						end
					end)

					resizer.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							if side.Resizing ~= resizer then
								resizer.BackgroundColor3 = theme.Button
							end
						end
					end)

				end

				local function renderSide(side,noTween) -- TODO: Use existing resizers
					local currentPos = 0
					local sideFramePos = getSideFramePos(side)
					local template = side.WindowResizer:Clone()
					for i,v in pairs(side.ResizeCons) do v:Disconnect() end
					for i,v in pairs(side.Frame:GetChildren()) do if v.Name == "WindowResizer" then v:Destroy() end end
					side.ResizeCons = {}
					side.Resizing = nil

					for i,v in pairs(side.Windows) do
						v.SidePos = i
						local isEnd = i == #side.Windows
						local size = UDim2.new(0,side.Width,0,v.SizeY)
						local pos = UDim2.new(sideFramePos.X.Scale,sideFramePos.X.Offset,0,currentPos)
						Lib.ShowGui(v.Gui)
						--v.GuiElems.Main:TweenSizeAndPosition(size,pos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
						if noTween then
							v.GuiElems.Main.Size = size
							v.GuiElems.Main.Position = pos
						else
							local tween = service.TweenService:Create(v.GuiElems.Main,sideTweenInfo,{Size = size, Position = pos})
							tweens[#tweens+1] = tween
							tween:Play()
						end
						currentPos = currentPos + v.SizeY+4

						if not isEnd then
							local newTemplate = template:Clone()
							newTemplate.Position = UDim2.new(1,-side.Width,0,currentPos-4)
							side.ResizeCons[#side.ResizeCons+1] = v.Gui.Main:GetPropertyChangedSignal("Size"):Connect(function()
								newTemplate.Position = UDim2.new(1,-side.Width,0, v.GuiElems.Main.Position.Y.Offset + v.GuiElems.Main.Size.Y.Offset)
							end)
							side.ResizeCons[#side.ResizeCons+1] = v.Gui.Main:GetPropertyChangedSignal("Position"):Connect(function()
								newTemplate.Position = UDim2.new(1,-side.Width,0, v.GuiElems.Main.Position.Y.Offset + v.GuiElems.Main.Size.Y.Offset)
							end)
							sideResizerHook(newTemplate,"V",side,i)
							newTemplate.Parent = side.Frame
						end
					end

					--side.Frame.Back.Position = UDim2.new(0,0,0,0)
					--side.Frame.Back.Size = UDim2.new(0,side.Width,1,0)
				end

				local function updateSide(side,noTween)
					local oldHeight = 0
					local currentPos = 0
					local neededSize = 0
					local windows = side.Windows
					local height = sidesGui.AbsoluteSize.Y - (math.max(0,#windows - 1) * 4)

					for i,v in pairs(windows) do oldHeight = oldHeight + v.SizeY end
					for i,v in pairs(windows) do
						if i == #windows then
							v.SizeY = height-currentPos
							neededSize = math.max(0,(v.MinY or 100)-v.SizeY)
						else
							v.SizeY = math.max(math.floor(v.SizeY/oldHeight*height),v.MinY or 100)
						end
						currentPos = currentPos + v.SizeY
					end

					if neededSize > 0 then
						for i = #windows-1,1,-1 do
							local window = windows[i]
							local newSize = math.max(window.SizeY-neededSize,(window.MinY or 100))
							neededSize = neededSize - (window.SizeY - newSize)
							window.SizeY = newSize
						end
						local lastWindow = windows[#windows]
						lastWindow.SizeY = (lastWindow.MinY or 100)-neededSize
					end
					renderSide(side,noTween)
				end

				updateWindows = function(noTween)
					updateSideFrames(noTween)
					updateSide(leftSide,noTween)
					updateSide(rightSide,noTween)
					local count = 0
					for i = #visibleWindows,1,-1 do
						visibleWindows[i].Gui.DisplayOrder = displayOrderStart + count
						Lib.ShowGui(visibleWindows[i].Gui)
						count = count + 1
					end

			--[[local leftTweenPos = (#leftSide.Windows == 0 and UDim2.new(0,-leftSide.Width-5,0,0) or UDim2.new(0,0,0,0))
			leftSide.Frame:TweenPosition(leftTweenPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)
			local rightTweenPos = (#rightSide.Windows == 0 and UDim2.new(1,5,0,0) or UDim2.new(1,-rightSide.Width,0,0))
			rightSide.Frame:TweenPosition(rightTweenPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.3,true)]]
				end

				funcs.SetMinimized = function(self,set,mode)
					local oldVal = self.Minimized
					local newVal
					if set == nil then newVal = not self.Minimized else newVal = set end
					self.Minimized = newVal
					if not mode then mode = 1 end

					local resizeControls = self.GuiElems.ResizeControls
					local minimizeControls = {"North","NorthEast","NorthWest","South","SouthEast","SouthWest"}
					for i = 1,#minimizeControls do
						local control = resizeControls:FindFirstChild(minimizeControls[i])
						if control then control.Visible = not newVal end
					end

					if mode == 1 or mode == 2 then
						self:StopTweens()
						if mode == 1 then
							self.GuiElems.Main:TweenSize(UDim2.new(0,self.SizeX,0,newVal and 20 or self.SizeY),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
						else
							local maxY = sidesGui.AbsoluteSize.Y
							local newPos = UDim2.new(0,self.PosX,0,newVal and math.min(maxY-20,self.PosY + self.SizeY - 20) or math.max(0,self.PosY - self.SizeY + 20))

							self.GuiElems.Main:TweenPosition(newPos,Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
							self.GuiElems.Main:TweenSize(UDim2.new(0,self.SizeX,0,newVal and 20 or self.SizeY),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
						end
						self.GuiElems.Minimize.ImageLabel.Image = newVal and ((getcustomasset and isfile and isfile("DEX_REContinued/Images/arrow3.png")) and getcustomasset("DEX_REContinued/Images/arrow3.png") or "rbxassetid://5060023708") or ((getcustomasset and isfile and isfile("DEX_REContinued/Images/minimize2.png")) and getcustomasset("DEX_REContinued/Images/minimize2.png") or "rbxassetid://5034768003")
					end

					if oldVal ~= newVal then
						if newVal then
							self.OnMinimize:Fire()
						else
							self.OnRestore:Fire()
						end
					end
				end

				funcs.Resize = function(self,sizeX,sizeY)
					self.SizeX = sizeX or self.SizeX
					self.SizeY = sizeY or self.SizeY
					self.GuiElems.Main.Size = UDim2.new(0,self.SizeX,0,self.SizeY)
				end

				funcs.SetSize = funcs.Resize

				funcs.SetTitle = function(self,title)
					self.GuiElems.Title.Text = title
				end

				funcs.SetResizable = function(self,val)
					self.Resizable = val
					self.GuiElems.ResizeControls.Visible = self.Resizable and self.ResizableInternal
				end

				funcs.SetResizableInternal = function(self,val)
					self.ResizableInternal = val
					self.GuiElems.ResizeControls.Visible = self.Resizable and self.ResizableInternal
				end

				funcs.SetAligned = function(self,val)
					self.Aligned = val
					self:SetResizableInternal(not val)
					self.GuiElems.Main.Active = not val
					self.GuiElems.Main.Outlines.Visible = not val
					if not val then
						for i,v in pairs(leftSide.Windows) do if v == self then table.remove(leftSide.Windows,i) break end end
						for i,v in pairs(rightSide.Windows) do if v == self then table.remove(rightSide.Windows,i) break end end
						if not table.find(visibleWindows,self) then table.insert(visibleWindows,1,self) end
						self.GuiElems.Minimize.ImageLabel.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/minimize2.png")) and getcustomasset("DEX_REContinued/Images/minimize2.png") or "rbxassetid://5034768003"
						self.Side = nil
						updateWindows()
					else
						self:SetMinimized(false,3)
						for i,v in pairs(visibleWindows) do if v == self then table.remove(visibleWindows,i) break end end
						self.GuiElems.Minimize.ImageLabel.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/squares_icon2.png")) and getcustomasset("DEX_REContinued/Images/squares_icon2.png") or "rbxassetid://5448127505"
					end
				end

				funcs.Add = function(self,obj,name)
					if type(obj) == "table" and obj.Gui and obj.Gui:IsA("GuiObject") then
						obj.Gui.Parent = self.ContentPane
					else
						obj.Parent = self.ContentPane
					end
					if name then self.Elements[name] = obj end
				end

				funcs.GetElement = function(self,obj,name)
					return self.Elements[name]
				end

				funcs.AlignTo = function(self,side,pos,size,silent)
					if table.find(side.Windows,self) or self.Closed then return end

					size = size or self.SizeY
					if size > 0 and size <= 1 then
						local totalSideHeight = 0
						for i,v in pairs(side.Windows) do totalSideHeight = totalSideHeight + v.SizeY end
						self.SizeY = (totalSideHeight > 0 and totalSideHeight * size * 2) or size
					else
						self.SizeY = (size > 0 and size or 100)
					end

					self:SetAligned(true)
					self.Side = side
					self.SizeX = side.Width
					self.Gui.DisplayOrder = sideDisplayOrder + 1
					for i,v in pairs(side.Windows) do v.Gui.DisplayOrder = sideDisplayOrder end
					pos = math.min(#side.Windows+1, pos or 1)
					self.SidePos = pos
					table.insert(side.Windows, pos, self)

					if not silent then
						side.Hidden = false
					end
					updateWindows(silent)
				end

				funcs.Close = function(self)
					self.Closed = true
					self:SetResizableInternal(false)

					Lib.FindAndRemove(leftSide.Windows,self)
					Lib.FindAndRemove(rightSide.Windows,self)
					Lib.FindAndRemove(visibleWindows,self)

					self.MinimizeAnim.Disable()
					self.CloseAnim.Disable()
					self.ClosedSide = self.Side
					self.Side = nil
					self.OnDeactivate:Fire()

					if not self.Aligned then
						self:StopTweens()
						local ti = TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

						local closeTime = tick()
						self.LastClose = closeTime

						self:DoTween(self.GuiElems.Main,ti,{Size = UDim2.new(0,self.SizeX,0,20)})
						self:DoTween(self.GuiElems.Title,ti,{TextTransparency = 1})
						self:DoTween(self.GuiElems.Minimize.ImageLabel,ti,{ImageTransparency = 1})
						self:DoTween(self.GuiElems.Close.ImageLabel,ti,{ImageTransparency = 1})
						Lib.FastWait(0.2)
						if closeTime ~= self.LastClose then return end

						self:DoTween(self.GuiElems.TopBar,ti,{BackgroundTransparency = 1})
						self:DoTween(self.GuiElems.Outlines,ti,{ImageTransparency = 1})
						Lib.FastWait(0.2)
						if closeTime ~= self.LastClose then return end
					end

					self.Aligned = false
					self.Gui.Parent = nil
					updateWindows(true)
				end

				funcs.Hide = funcs.Close

				funcs.IsVisible = function(self)
					return not self.Closed and ((self.Side and not self.Side.Hidden) or not self.Side)
				end

				funcs.IsContentVisible = function(self)
					return self:IsVisible() and not self.Minimized
				end

				funcs.Focus = function(self)
					moveToTop(self)
				end

				funcs.MoveInBoundary = function(self)
					local posX,posY = self.PosX,self.PosY
					local maxX,maxY = sidesGui.AbsoluteSize.X,sidesGui.AbsoluteSize.Y
					posX = math.min(posX,maxX-self.SizeX)
					posY = math.min(posY,maxY-20)
					self.GuiElems.Main.Position = UDim2.new(0,posX,0,posY)
				end

				funcs.DoTween = function(self,...)
					local tween = service.TweenService:Create(...)
					self.Tweens[#self.Tweens+1] = tween
					tween:Play()
				end

				funcs.StopTweens = function(self)
					for i,v in pairs(self.Tweens) do
						v:Cancel()
					end
					self.Tweens = {}
				end

				funcs.Show = function(self,data)
					return static.ShowWindow(self,data)
				end

				funcs.ShowAndFocus = function(self,data)
					static.ShowWindow(self,data)
					service.RunService.RenderStepped:wait()
					self:Focus()
				end

				static.ShowWindow = function(window,data)
					data = data or {}
					local align = data.Align
					local pos = data.Pos
					local size = data.Size
					local targetSide = (align == "left" and leftSide) or (align == "right" and rightSide)

					if not window.Closed then
						if not window.Aligned then
							window:SetMinimized(false)
						elseif window.Side and not data.Silent then
							static.SetSideVisible(window.Side,true)
						end
						return
					end

					window.Closed = false
					window.LastClose = tick()
					window.GuiElems.Title.TextTransparency = 0
					window.GuiElems.Minimize.ImageLabel.ImageTransparency = 0
					window.GuiElems.Close.ImageLabel.ImageTransparency = 0
					window.GuiElems.TopBar.BackgroundTransparency = 0
					window.GuiElems.Outlines.ImageTransparency = 0
					window.GuiElems.Minimize.ImageLabel.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/minimize2.png")) and getcustomasset("DEX_REContinued/Images/minimize2.png") or "rbxassetid://5034768003"
					window.GuiElems.Main.Active = true
					window.GuiElems.Main.Outlines.Visible = true
					window:SetMinimized(false,3)
					window:SetResizableInternal(true)
					window.MinimizeAnim.Enable()
					window.CloseAnim.Enable()

					if align then
						window:AlignTo(targetSide,pos,size,data.Silent)
					else
						if align == nil and window.ClosedSide then -- Regular open
							window:AlignTo(window.ClosedSide,window.SidePos,size,true)
							static.SetSideVisible(window.ClosedSide,true)
						else
							if table.find(visibleWindows,window) then return end

							-- TODO: make better
							window.GuiElems.Main.Size = UDim2.new(0,window.SizeX,0,20)
							local ti = TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
							window:StopTweens()
							window:DoTween(window.GuiElems.Main,ti,{Size = UDim2.new(0,window.SizeX,0,window.SizeY)})

							window.SizeY = size or window.SizeY
							table.insert(visibleWindows,1,window)
							updateWindows()
						end
					end

					window.ClosedSide = nil
					window.OnActivate:Fire()
				end

				static.ToggleSide = function(name)
					local side = (name == "left" and leftSide or rightSide)
					side.Hidden = not side.Hidden
					for i,v in pairs(side.Windows) do
						if side.Hidden then
							v.OnDeactivate:Fire()
						else
							v.OnActivate:Fire()
						end
					end
					updateWindows()
				end

				static.SetSideVisible = function(s,vis)
					local side = (type(s) == "table" and s) or (s == "left" and leftSide or rightSide)
					side.Hidden = not vis
					for i,v in pairs(side.Windows) do
						if side.Hidden then
							v.OnDeactivate:Fire()
						else
							v.OnActivate:Fire()
						end
					end
					updateWindows()
				end

				static.Init = function()
					displayOrderStart = Main.DisplayOrders.Window
					sideDisplayOrder = Main.DisplayOrders.SideWindow

					sidesGui = Instance.new("ScreenGui")
					local leftFrame = create({
						{1,"Frame",{Active=true,Name="LeftSide",BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,}},
						{2,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="Resizer",Parent={1},Size=UDim2.new(0,5,1,0),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{3,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={2},Position=UDim2.new(0,0,0,0),Size=UDim2.new(0,1,1,0),}},
						{4,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="WindowResizer",Parent={1},Position=UDim2.new(1,-300,0,0),Size=UDim2.new(1,0,0,4),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{5,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={4},Size=UDim2.new(1,0,0,1),}},
					})
					leftSide.Frame = leftFrame
					leftFrame.Position = UDim2.new(0,-leftSide.Width-10,0,0)
					leftSide.WindowResizer = leftFrame.WindowResizer
					leftFrame.WindowResizer.Parent = nil
					leftFrame.Parent = sidesGui

					local rightFrame = create({
						{1,"Frame",{Active=true,Name="RightSide",BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,}},
						{2,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="Resizer",Parent={1},Size=UDim2.new(0,5,1,0),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{3,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={2},Position=UDim2.new(0,4,0,0),Size=UDim2.new(0,1,1,0),}},
						{4,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2549019753933,0.2549019753933,0.2549019753933),BorderSizePixel=0,Font=3,Name="WindowResizer",Parent={1},Position=UDim2.new(1,-300,0,0),Size=UDim2.new(1,0,0,4),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
						{5,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={4},Size=UDim2.new(1,0,0,1),}},
					})
					rightSide.Frame = rightFrame
					rightFrame.Position = UDim2.new(1,10,0,0)
					rightSide.WindowResizer = rightFrame.WindowResizer
					rightFrame.WindowResizer.Parent = nil
					rightFrame.Parent = sidesGui

					sideResizerHook(leftFrame.Resizer,"H",leftSide)
					sideResizerHook(rightFrame.Resizer,"H",rightSide)

					alignIndicator = Instance.new("ScreenGui")
					alignIndicator.DisplayOrder = Main.DisplayOrders.Core
					local indicator = Instance.new("Frame",alignIndicator)
					indicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
					indicator.BorderSizePixel = 0
					indicator.BackgroundTransparency = 0.8
					indicator.Name = "Indicator"
					local corner = Instance.new("UICorner",indicator)
					corner.CornerRadius = UDim.new(0,10)

					local leftToggle = create({{1,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderMode=2,Font=10,Name="LeftToggle",Position=UDim2.new(0,0,0,-36),Size=UDim2.new(0,16,0,36),Text="<",TextColor3=Color3.new(1,1,1),TextSize=14,}}})
					local rightToggle = leftToggle:Clone()
					rightToggle.Name = "RightToggle"
					rightToggle.Position = UDim2.new(1,-16,0,-36)
					Lib.ButtonAnim(leftToggle,{Mode = 2,PressColor = Color3.fromRGB(32,32,32)})
					Lib.ButtonAnim(rightToggle,{Mode = 2,PressColor = Color3.fromRGB(32,32,32)})

					leftToggle.MouseButton1Click:Connect(function()
						static.ToggleSide("left")
					end)

					rightToggle.MouseButton1Click:Connect(function()
						static.ToggleSide("right")
					end)

					leftToggle.Parent = sidesGui
					rightToggle.Parent = sidesGui

					sidesGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
						local maxWidth = math.max(300,sidesGui.AbsoluteSize.X-static.FreeWidth)
						leftSide.Width = math.max(static.MinWidth,math.min(leftSide.Width,maxWidth-rightSide.Width))
						rightSide.Width = math.max(static.MinWidth,math.min(rightSide.Width,maxWidth-leftSide.Width))
						for i = 1,#visibleWindows do
							visibleWindows[i]:MoveInBoundary()
						end
						updateWindows(true)
					end)

					sidesGui.DisplayOrder = sideDisplayOrder - 1
					Lib.ShowGui(sidesGui)
					updateSideFrames()
				end

				local mt = {__index = funcs}
				static.new = function()
					local obj = setmetatable({
						Minimized = false,
						Dragging = false,
						Resizing = false,
						Aligned = false,
						Draggable = true,
						Resizable = true,
						ResizableInternal = true,
						Alignable = true,
						Closed = true,
						SizeX = 300,
						SizeY = 300,
						MinX = 200,
						MinY = 200,
						PosX = 0,
						PosY = 0,
						GuiElems = {},
						Tweens = {},
						Elements = {},
						OnActivate = Lib.Signal.new(),
						OnDeactivate = Lib.Signal.new(),
						OnMinimize = Lib.Signal.new(),
						OnRestore = Lib.Signal.new()
					},mt)
					obj.Gui = createGui(obj)
					table.insert(static.CreatedWindows, obj)
					return obj
				end

				static.UpdateTransparency = function()
			local trans = Settings.Window.Transparency or 0
			for _, win in next, static.CreatedWindows do
				if win.GuiElems and win.GuiElems.Content then
					win.GuiElems.Content.BackgroundTransparency = trans
				end
			end
			if leftSide and leftSide.Frame then
				leftSide.Frame.BackgroundTransparency = trans > 0 and 1 or 0
			end
			if rightSide and rightSide.Frame then
				rightSide.Frame.BackgroundTransparency = trans > 0 and 1 or 0
			end
			if Apps.Properties and Apps.Properties.EntryTemplate then
				Apps.Properties.EntryTemplate.BackgroundTransparency = trans > 0 and 0.75 or 0
			end
		end

				return static
			end)()

			Lib.ContextMenu = (function()
				local funcs = {}
				local mouse

				local function createGui(self)
					local contextGui = create({
						{1,"ScreenGui",{DisplayOrder=1000000,Name="Context",ZIndexBehavior=1,}},
						{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),Name="Main",Parent={1},Position=UDim2.new(0.5,-100,0.5,-150),Size=UDim2.new(0,200,0,100),}},
						{3,"UICorner",{CornerRadius=UDim.new(0,4),Parent={2},}},
						{4,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),Name="Container",Parent={2},Position=UDim2.new(0,1,0,1),Size=UDim2.new(1,-2,1,-2),}},
						{5,"UICorner",{CornerRadius=UDim.new(0,4),Parent={4},}},
						{6,"ScrollingFrame",{Active=true,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),Name="List",Parent={4},Position=UDim2.new(0,2,0,2),ScrollBarImageColor3=Color3.new(0,0,0),ScrollBarThickness=4,Size=UDim2.new(1,-4,1,-4),VerticalScrollBarInset=1,}},
						{7,"UIListLayout",{Parent={6},SortOrder=2,}},
						{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="SearchFrame",Parent={4},Size=UDim2.new(1,0,0,24),Visible=false,}},
						{9,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.1176470592618,0.1176470592618,0.1176470592618),BorderSizePixel=0,Name="SearchContainer",Parent={8},Position=UDim2.new(0,3,0,3),Size=UDim2.new(1,-6,0,18),}},
						{10,"TextBox",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="SearchBox",Parent={9},PlaceholderColor3=Color3.new(0.39215689897537,0.39215689897537,0.39215689897537),PlaceholderText="Search",Position=UDim2.new(0,4,0,0),Size=UDim2.new(1,-8,0,18),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=0,}},
						{11,"UICorner",{CornerRadius=UDim.new(0,2),Parent={9},}},
						{12,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="Line",Parent={8},Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),}},
						{13,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BackgroundTransparency=1,BorderColor3=Color3.new(0.33725491166115,0.49019610881805,0.73725491762161),BorderSizePixel=0,Font=3,Name="Entry",Parent={1},Size=UDim2.new(1,0,0,22),Text="",TextSize=14,Visible=false,}},
						{14,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="EntryName",Parent={13},Position=UDim2.new(0,24,0,0),Size=UDim2.new(1,-24,1,0),Text="Duplicate",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
						{15,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Shortcut",Parent={13},Position=UDim2.new(0,24,0,0),Size=UDim2.new(1,-30,1,0),Text="Ctrl+D",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
						{16,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,ImageRectOffset=Vector2.new(304,0),ImageRectSize=Vector2.new(16,16),Name="Icon",Parent={13},Position=UDim2.new(0,2,0,3),ScaleType=4,Size=UDim2.new(0,16,0,16),}},
						{17,"UICorner",{CornerRadius=UDim.new(0,4),Parent={13},}},
						{18,"Frame",{BackgroundColor3=Color3.new(0.21568629145622,0.21568629145622,0.21568629145622),BackgroundTransparency=1,BorderSizePixel=0,Name="Divider",Parent={1},Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,0,7),Visible=false,}},
						{19,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="Line",Parent={18},Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0,1),}},
						{20,"TextLabel",{AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="DividerName",Parent={18},Position=UDim2.new(0,2,0.5,0),Size=UDim2.new(1,-4,1,0),Text="Objects",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.60000002384186,TextXAlignment=0,Visible=false,}}
					})

					self.GuiElems.Main = contextGui.Main
					self.GuiElems.List = contextGui.Main.Container.List
					self.GuiElems.Entry = contextGui.Entry
					self.GuiElems.Divider = contextGui.Divider
					self.GuiElems.SearchFrame = contextGui.Main.Container.SearchFrame
					self.GuiElems.SearchBar = self.GuiElems.SearchFrame.SearchContainer.SearchBox
					Lib.ViewportTextBox.convert(self.GuiElems.SearchBar)

					self.GuiElems.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
						local lower,find = string.lower,string.find
						local searchText = lower(self.GuiElems.SearchBar.Text)
						local items = self.Items
						local map = self.ItemToEntryMap

						if searchText ~= "" then
							local results = {}
							local count = 1
							for i = 1,#items do
								local item = items[i]
								local entry = map[item]
								if entry then
									if not item.Divider and find(lower(item.Name),searchText,1,true) then
										results[count] = item
										count = count + 1
									else
										entry.Visible = false
									end
								end
							end
							table.sort(results,function(a,b) return a.Name < b.Name end)
							for i = 1,#results do
								local entry = map[results[i]]
								entry.LayoutOrder = i
								entry.Visible = true
							end
						else
							for i = 1,#items do
								local entry = map[items[i]]
								if entry then entry.LayoutOrder = i entry.Visible = true end
							end
						end

						local toSize = self.GuiElems.List.UIListLayout.AbsoluteContentSize.Y + 6
						self.GuiElems.List.CanvasSize = UDim2.new(0,0,0,toSize-6)
					end)

					return contextGui
				end

				funcs.Add = function(self,item)
					local newItem = {
						Name = item.Name or "Item",
						Icon = item.Icon or "",
						Shortcut = item.Shortcut or "",
						OnClick = item.OnClick,
						OnHover = item.OnHover,
						Disabled = item.Disabled or false,
						DisabledIcon = item.DisabledIcon or "",
						IconMap = item.IconMap,
						OnRightClick = item.OnRightClick
					}

					if self.QueuedDivider then
						local text = self.QueuedDividerText and #self.QueuedDividerText > 0 and self.QueuedDividerText
						self:AddDivider(text)
					end
					self.Items[#self.Items+1] = newItem
					self.Updated = nil
				end

				funcs.AddRegistered = function(self,name,disabled)
					if not self.Registered[name] then error(name.." is not registered") end

					if self.QueuedDivider then
						local text = self.QueuedDividerText and #self.QueuedDividerText > 0 and self.QueuedDividerText
						self:AddDivider(text)
					end
					self.Registered[name].Disabled = disabled
					self.Items[#self.Items+1] = self.Registered[name]
					self.Updated = nil
				end

				funcs.Register = function(self,name,item)
					self.Registered[name] = {
						Name = item.Name or "Item",
						Icon = item.Icon or "",
						Shortcut = item.Shortcut or "",
						OnClick = item.OnClick,
						OnHover = item.OnHover,
						DisabledIcon = item.DisabledIcon or "",
						IconMap = item.IconMap,
						OnRightClick = item.OnRightClick
					}
				end

				funcs.UnRegister = function(self,name)
					self.Registered[name] = nil
				end

				funcs.AddDivider = function(self,text)
					self.QueuedDivider = false
					local textWidth = text and service.TextService:GetTextSize(text,14,Enum.Font.SourceSans,Vector2.new(999999999,20)).X or nil
					table.insert(self.Items,{Divider = true, Text = text, TextSize = textWidth and textWidth+4})
					self.Updated = nil
				end

				funcs.QueueDivider = function(self,text)
					self.QueuedDivider = true
					self.QueuedDividerText = text or ""
				end

				funcs.Clear = function(self)
					self.Items = {}
					self.Updated = nil
				end

				funcs.Refresh = function(self)
					for i,v in pairs(self.GuiElems.List:GetChildren()) do
						if not v:IsA("UIListLayout") then
							v:Destroy()
						end
					end
					local map = {}
					self.ItemToEntryMap = map

					local dividerFrame = self.GuiElems.Divider
					local contextList = self.GuiElems.List
					local entryFrame = self.GuiElems.Entry
					local items = self.Items

					for i = 1,#items do
						local item = items[i]
						if item.Divider then
							local newDivider = dividerFrame:Clone()
							newDivider.Line.BackgroundColor3 = self.Theme.DividerColor
							if item.Text then
								newDivider.Size = UDim2.new(1,0,0,20)
								newDivider.Line.Position = UDim2.new(0,item.TextSize,0.5,0)
								newDivider.Line.Size = UDim2.new(1,-item.TextSize,0,1)
								newDivider.DividerName.TextColor3 = self.Theme.TextColor
								newDivider.DividerName.Text = item.Text
								newDivider.DividerName.Visible = true
							end
							newDivider.Visible = true
							map[item] = newDivider
							newDivider.Parent = contextList
						else
							local newEntry = entryFrame:Clone()
							newEntry.BackgroundColor3 = self.Theme.HighlightColor
							newEntry.EntryName.TextColor3 = self.Theme.TextColor
							newEntry.EntryName.Text = item.Name
							newEntry.Shortcut.Text = item.Shortcut
							if item.Disabled then
								newEntry.EntryName.TextColor3 = Color3.new(150/255,150/255,150/255)
								newEntry.Shortcut.TextColor3 = Color3.new(150/255,150/255,150/255)
							end

							if self.Iconless then
								newEntry.EntryName.Position = UDim2.new(0,2,0,0)
								newEntry.EntryName.Size = UDim2.new(1,-4,0,20)
								newEntry.Icon.Visible = false
							else
								local iconIndex = item.Disabled and item.DisabledIcon or item.Icon
								-- Explorer.MiscIcons:DisplayExplorerIcons(newEntry.Icon, iconIndex)
								if item.IconMap then
									if type(iconIndex) == "number" then
										item.IconMap:Display(newEntry.Icon, iconIndex)
									elseif type(iconIndex) == "string" then
										item.IconMap:DisplayByKey(newEntry.Icon, iconIndex)
									end
								elseif type(iconIndex) == "string" then
									newEntry.Icon.Image = iconIndex
								end
							end

							if not item.Disabled then
								if item.OnClick then
									newEntry.MouseButton1Click:Connect(function()
										item.OnClick(item.Name)
										if not item.NoHide then
											self:Hide()
										end
									end)
								end

								if item.OnRightClick then
									newEntry.MouseButton2Click:Connect(function()
										item.OnRightClick(item.Name)
										if not item.NoHide then
											self:Hide()
										end
									end)
								end
							end

							newEntry.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
									newEntry.BackgroundTransparency = 0
								end
							end)

							newEntry.InputEnded:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
									newEntry.BackgroundTransparency = 1
								end
							end)

							newEntry.Visible = true
							map[item] = newEntry
							newEntry.Parent = contextList
						end
					end
					self.Updated = true
				end

				funcs.Show = function(self,x,y)
					local elems = self.GuiElems
					elems.SearchFrame.Visible = self.SearchEnabled
					elems.List.Position = UDim2.new(0,2,0,2 + (self.SearchEnabled and 24 or 0))
					elems.List.Size = UDim2.new(1,-4,1,-4 - (self.SearchEnabled and 24 or 0))
					if self.SearchEnabled and self.ClearSearchOnShow then elems.SearchBar.Text = "" end
					self.GuiElems.List.CanvasPosition = Vector2.new(0,0)

					if not self.Updated then
						self:Refresh()
					end

					-- Vars
					local reverseY = false
					local x,y = x or mouse.X, y or mouse.Y
					local maxX,maxY = mouse.ViewSizeX,mouse.ViewSizeY

					-- Position and show
					if x + self.Width > maxX then
						x = self.ReverseX and x - self.Width or maxX - self.Width
					end
					elems.Main.Position = UDim2.new(0,x,0,y)
					elems.Main.Size = UDim2.new(0,self.Width,0,0)
					self.Gui.DisplayOrder = Main.DisplayOrders.Menu
					Lib.ShowGui(self.Gui)

					-- Size adjustment
					local toSize = elems.List.UIListLayout.AbsoluteContentSize.Y + 6 -- Padding
					if self.MaxHeight and toSize > self.MaxHeight then
						elems.List.CanvasSize = UDim2.new(0,0,0,toSize-6)
						toSize = self.MaxHeight
					else
						elems.List.CanvasSize = UDim2.new(0,0,0,0)
					end
					if y + toSize > maxY then reverseY = true end

					-- Close event
					local closable
					if self.CloseEvent then self.CloseEvent:Disconnect() end
					self.CloseEvent = service.UserInputService.InputBegan:Connect(function(input)
						if not closable then return end

						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							if not Lib.CheckMouseInGui(elems.Main) then
								self.CloseEvent:Disconnect()
								self:Hide()
							end
						end
					end)

					-- Resize
					if reverseY then
						elems.Main.Position = UDim2.new(0,x,0,y-(self.ReverseYOffset or 0))
						local newY = y - toSize - (self.ReverseYOffset or 0)
						y = newY >= 0 and newY or 0
						elems.Main:TweenSizeAndPosition(UDim2.new(0,self.Width,0,toSize),UDim2.new(0,x,0,y),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.2,true)
					else
						elems.Main:TweenSize(UDim2.new(0,self.Width,0,toSize),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.2,true)
					end

					-- Close debounce
					Lib.FastWait()
					if self.SearchEnabled and self.FocusSearchOnShow then elems.SearchBar:CaptureFocus() end
					closable = true
				end

				funcs.Hide = function(self)
					self.Gui.Parent = nil
				end

				funcs.ApplyTheme = function(self,data)
					local theme = self.Theme
					theme.ContentColor = data.ContentColor or Settings.Theme.Menu
					theme.OutlineColor = data.OutlineColor or Settings.Theme.Menu
					theme.DividerColor = data.DividerColor or Settings.Theme.Outline2
					theme.TextColor = data.TextColor or Settings.Theme.Text
					theme.HighlightColor = data.HighlightColor or Settings.Theme.Main1

					self.GuiElems.Main.BackgroundColor3 = theme.OutlineColor
					self.GuiElems.Main.Container.BackgroundColor3 = theme.ContentColor
				end

				local mt = {__index = funcs}
				local function new()
					if not mouse then mouse = Main.Mouse or service.Players.LocalPlayer:GetMouse() end

					local obj = setmetatable({
						Width = 200,
						MaxHeight = nil,
						Iconless = false,
						SearchEnabled = false,
						ClearSearchOnShow = true,
						FocusSearchOnShow = true,
						Updated = false,
						QueuedDivider = false,
						QueuedDividerText = "",
						Items = {},
						Registered = {},
						GuiElems = {},
						Theme = {}
					},mt)
					obj.Gui = createGui(obj)
					obj:ApplyTheme({})
					return obj
				end

				return {new = new}
			end)()

			Lib.CodeFrame = (function()
		local funcs = {}

		local typeMap = {
			[1] = "String",
			[2] = "String",
			[3] = "String",
			[4] = "Comment",
			[5] = "Operator",
			[6] = "Number",
			[7] = "Keyword",
			[8] = "BuiltIn",
			[9] = "LocalMethod",
			[10] = "LocalProperty",
			[11] = "Nil",
			[12] = "Bool",
			[13] = "Function",
			[14] = "Local",
			[15] = "Self",
			[16] = "FunctionName",
			[17] = "Bracket"
		}

		local specialKeywordsTypes = {
			["nil"] = 11,
			["true"] = 12,
			["false"] = 12,
			["function"] = 13,
			["local"] = 14,
			["self"] = 15
		}

		local keywords = {
			["and"] = true,
			["break"] = true, 
			["do"] = true,
			["else"] = true,
			["elseif"] = true,
			["end"] = true,
			["false"] = true,
			["for"] = true,
			["function"] = true,
			["if"] = true,
			["in"] = true,
			["local"] = true,
			["nil"] = true,
			["not"] = true,
			["or"] = true,
			["repeat"] = true,
			["return"] = true,
			["then"] = true,
			["true"] = true,
			["until"] = true,
			["while"] = true,
			["plugin"] = true
		}

		local builtIns = {
			["delay"] = true,
			["elapsedTime"] = true,
			["require"] = true,
			["spawn"] = true,
			["tick"] = true,
			["time"] = true,
			["typeof"] = true,
			["UserSettings"] = true,
			["wait"] = true,
			["warn"] = true,
			["game"] = true,
			["shared"] = true,
			["script"] = true,
			["workspace"] = true,
			["assert"] = true,
			["collectgarbage"] = true,
			["error"] = true,
			["getfenv"] = true,
			["getmetatable"] = true,
			["ipairs"] = true,
			["loadstring"] = true,
			["newproxy"] = true,
			["next"] = true,
			["pairs"] = true,
			["pcall"] = true,
			["print"] = true,
			["rawequal"] = true,
			["rawget"] = true,
			["rawset"] = true,
			["select"] = true,
			["setfenv"] = true,
			["setmetatable"] = true,
			["tonumber"] = true,
			["tostring"] = true,
			["type"] = true,
			["unpack"] = true,
			["xpcall"] = true,
			["_G"] = true,
			["_VERSION"] = true,
			["coroutine"] = true,
			["debug"] = true,
			["math"] = true,
			["os"] = true,
			["string"] = true,
			["table"] = true,
			["bit32"] = true,
			["utf8"] = true,
			["Axes"] = true,
			["BrickColor"] = true,
			["CFrame"] = true,
			["Color3"] = true,
			["ColorSequence"] = true,
			["ColorSequenceKeypoint"] = true,
			["DockWidgetPluginGuiInfo"] = true,
			["Enum"] = true,
			["Faces"] = true,
			["Instance"] = true,
			["NumberRange"] = true,
			["NumberSequence"] = true,
			["NumberSequenceKeypoint"] = true,
			["PathWaypoint"] = true,
			["PhysicalProperties"] = true,
			["Random"] = true,
			["Ray"] = true,
			["Rect"] = true,
			["Region3"] = true,
			["Region3int16"] = true,
			["TweenInfo"] = true,
			["UDim"] = true,
			["UDim2"] = true,
			["Vector2"] = true,
			["Vector2int16"] = true,
			["Vector3"] = true,
			["Vector3int16"] = true,

			["getgenv"] = true,
			["getrenv"] = true,
			["getsenv"] = true,
			["getgc"] = true,
			["getreg"] = true,
			["filtergc"] = true,
			["saveinstave"] = true,
			["decompile"] = true,
			["syn"] = true,
			["getupvalue"] = true,
			["getupvalues"] = true,
			["setupvalue"] = true,
			["getstack"] = true,
			["setstack"] = true,
			["getconstants"] = true,
			["getconstant"] = true,
			["setconstant"] = true,
			["getproto"] = true,
			["getprotos"] = true,
			["checkcaller"] = true,
			["clonefunction"] = true,
			["cloneref"] = true,
			["getfunctionhash"] = true,
			["gethwid"] = true,
			["hookfunction"] = true,
			["hookmetamethod"] = true,
			["iscclosure"] = true,
			["islclosure"] = true,
			["newcclosure"] = true,
			["isexecutorclosure"] = true,
			["restorefunction"] = true,
			["crypt"] = true,
			["Drawing"] = true,

		}

		local builtInInited = false

		local richReplace = {
			["'"] = "&apos;",
			["\""] = "&quot;",
			["<"] = "&lt;",
			[">"] = "&gt;",
			["&"] = "&amp;"
		}

		local tabSub = "\205"
		local tabReplacement = (" %s%s "):format(tabSub,tabSub)

		local tabJumps = {
			[("[^%s] %s"):format(tabSub,tabSub)] = 0,
			[(" %s%s"):format(tabSub,tabSub)] = -1,
			[("%s%s "):format(tabSub,tabSub)] = 2,
			[("%s [^%s]"):format(tabSub,tabSub)] = 1,
		}

		local tweenService = service.TweenService
		local lineTweens = {}

		local function initBuiltIn()
			local env = getfenv()
			local type = type
			local tostring = tostring
			for name,_ in next,builtIns do
				local envVal = env[name]
				if type(envVal) == "table" then
					local items = {}
					for i,v in next,envVal do
						items[i] = true
					end
					builtIns[name] = items
				end
			end

			local enumEntries = {}
			local enums = Enum:GetEnums()
			for i = 1,#enums do
				enumEntries[tostring(enums[i])] = true
			end
			builtIns["Enum"] = enumEntries

			builtInInited = true
		end

		local function setupEditBox(obj)
			local editBox = obj.GuiElems.EditBox

			editBox.Focused:Connect(function()
				obj:ConnectEditBoxEvent()
				obj.Editing = true
			end)

			editBox.FocusLost:Connect(function()
				obj:DisconnectEditBoxEvent()
				obj.Editing = false
			end)

			editBox:GetPropertyChangedSignal("Text"):Connect(function()
				local text = editBox.Text
				if #text == 0 or obj.EditBoxCopying then return end
				editBox.Text = ""
				obj:AppendText(text)
			end)
		end

		local function setupMouseSelection(obj)
			local mouse = plr:GetMouse()
			local codeFrame = obj.GuiElems.LinesFrame
			local lines = obj.Lines

			codeFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local fontSizeX,fontSizeY = math.ceil(obj.FontSize/2),obj.FontSize

					local relX = mouse.X - codeFrame.AbsolutePosition.X
					local relY = mouse.Y - codeFrame.AbsolutePosition.Y
					local selX = math.round(relX / fontSizeX) + obj.ViewX
					local selY = math.floor(relY / fontSizeY) + obj.ViewY
					local releaseEvent,mouseEvent,scrollEvent
					local scrollPowerV,scrollPowerH = 0,0
					selY = math.min(#lines-1,selY)
					local relativeLine = lines[selY+1] or ""
					selX = math.min(#relativeLine, selX + obj:TabAdjust(selX,selY))

					obj.SelectionRange = {{-1,-1},{-1,-1}}
					obj:MoveCursor(selX,selY)
					obj.FloatCursorX = selX

					local function updateSelection()
						local relX = mouse.X - codeFrame.AbsolutePosition.X
						local relY = mouse.Y - codeFrame.AbsolutePosition.Y
						local sel2X = math.max(0,math.round(relX / fontSizeX) + obj.ViewX)
						local sel2Y = math.max(0,math.floor(relY / fontSizeY) + obj.ViewY)

						sel2Y = math.min(#lines-1,sel2Y)
						local relativeLine = lines[sel2Y+1] or ""
						sel2X = math.min(#relativeLine, sel2X + obj:TabAdjust(sel2X,sel2Y))

						if sel2Y < selY or (sel2Y == selY and sel2X < selX) then
							obj.SelectionRange = {{sel2X,sel2Y},{selX,selY}}
						else						
							obj.SelectionRange = {{selX,selY},{sel2X,sel2Y}}
						end

						obj:MoveCursor(sel2X,sel2Y)
						obj.FloatCursorX = sel2X
						obj:Refresh()
					end

					releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
							scrollEvent:Disconnect()
							obj:SetCopyableSelection()
							--updateSelection()
						end
					end)

					mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							local upDelta = mouse.Y - codeFrame.AbsolutePosition.Y
							local downDelta = mouse.Y - codeFrame.AbsolutePosition.Y - codeFrame.AbsoluteSize.Y
							local leftDelta = mouse.X - codeFrame.AbsolutePosition.X
							local rightDelta = mouse.X - codeFrame.AbsolutePosition.X - codeFrame.AbsoluteSize.X
							scrollPowerV = 0
							scrollPowerH = 0
							if downDelta > 0 then
								scrollPowerV = math.floor(downDelta*0.05) + 1
							elseif upDelta < 0 then
								scrollPowerV = math.ceil(upDelta*0.05) - 1
							end
							if rightDelta > 0 then
								scrollPowerH = math.floor(rightDelta*0.05) + 1
							elseif leftDelta < 0 then
								scrollPowerH = math.ceil(leftDelta*0.05) - 1
							end
							updateSelection()
						end
					end)

					scrollEvent = cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
						if scrollPowerV ~= 0 or scrollPowerH ~= 0 then
							obj:ScrollDelta(scrollPowerH,scrollPowerV)
							updateSelection()
						end
					end)

					obj:Refresh()
				end
			end)
		end

		local function makeFrame(obj)
			local frame = create({
				{1,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel = 0,Position=UDim2.new(0.5,-300,0.5,-200),Size=UDim2.new(0,600,0,400),}},
			})

			if Settings.Window.Transparency and Settings.Window.Transparency > 0 then
				frame.BackgroundTransparency = 0.5
			end

			local elems = {}

			local linesFrame = Instance.new("Frame")
			linesFrame.Name = "Lines"
			linesFrame.BackgroundTransparency = 1
			linesFrame.Size = UDim2.new(1,0,1,0)
			linesFrame.ClipsDescendants = true
			linesFrame.Parent = frame

			local lineNumbersLabel = Instance.new("TextLabel")
			lineNumbersLabel.Name = "LineNumbers"
			lineNumbersLabel.BackgroundTransparency = 1
			lineNumbersLabel.Font = Enum.Font.Code
			lineNumbersLabel.TextXAlignment = Enum.TextXAlignment.Right
			lineNumbersLabel.TextYAlignment = Enum.TextYAlignment.Top
			lineNumbersLabel.ClipsDescendants = true
			lineNumbersLabel.RichText = true
			lineNumbersLabel.Parent = frame

			local cursor = Instance.new("Frame")
			cursor.Name = "Cursor"
			cursor.BackgroundColor3 = Color3.fromRGB(220,220,220)
			cursor.BorderSizePixel = 0
			cursor.Parent = frame

			local editBox = Instance.new("TextBox")
			editBox.Name = "EditBox"
			editBox.MultiLine = true
			editBox.Visible = false
			editBox.Parent = frame

			lineTweens.Invis = tweenService:Create(cursor,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency = 1})
			lineTweens.Vis = tweenService:Create(cursor,TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency = 0})

			elems.LinesFrame = linesFrame
			elems.LineNumbersLabel = lineNumbersLabel
			elems.Cursor = cursor
			elems.EditBox = editBox
			elems.ScrollCorner = create({{1,"Frame",{BackgroundColor3=Color3.new(0.15686275064945,0.15686275064945,0.15686275064945),BorderSizePixel=0,Name="ScrollCorner",Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,16,0,16),Visible=false,}}})

			elems.ScrollCorner.Parent = frame
			linesFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					obj:SetEditing(true,input)
				end
			end)

			obj.Frame = frame
			obj.Gui = frame
			obj.GuiElems = elems
			setupEditBox(obj)
			setupMouseSelection(obj)

			return frame
		end

		funcs.GetSelectionText = function(self)
			if not self:IsValidRange() then return "" end

			local selectionRange = self.SelectionRange
			local selX,selY = selectionRange[1][1], selectionRange[1][2]
			local sel2X,sel2Y = selectionRange[2][1], selectionRange[2][2]
			local deltaLines = sel2Y-selY
			local lines = self.Lines

			if not lines[selY+1] or not lines[sel2Y+1] then return "" end

			if deltaLines == 0 then
				return self:ConvertText(lines[selY+1]:sub(selX+1,sel2X), false)
			end

			local leftSub = lines[selY+1]:sub(selX+1)
			local rightSub = lines[sel2Y+1]:sub(1,sel2X)

			local result = leftSub.."\n" 
			for i = selY+1,sel2Y-1 do
				result = result..lines[i+1].."\n"
			end
			result = result..rightSub

			return self:ConvertText(result,false)
		end

		funcs.SetCopyableSelection = function(self)
			local text = self:GetSelectionText()
			local editBox = self.GuiElems.EditBox

			self.EditBoxCopying = true
			editBox.Text = text
			editBox.SelectionStart = 1
			editBox.CursorPosition = #editBox.Text + 1
			self.EditBoxCopying = false
		end

		funcs.ConnectEditBoxEvent = function(self)
			if self.EditBoxEvent then
				self.EditBoxEvent:Disconnect()
			end

			self.EditBoxEvent = service.UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

				local keycodes = Enum.KeyCode
				local keycode = input.KeyCode

				local function setupMove(key,func)
					local endCon,finished
					endCon = service.UserInputService.InputEnded:Connect(function(input)
						if input.KeyCode ~= key then return end
						endCon:Disconnect()
						finished = true
					end)
					func()
					Lib.FastWait(0.5)
					while not finished do func() Lib.FastWait(0.03) end
				end

				if keycode == keycodes.Down then
					setupMove(keycodes.Down,function()
						self.CursorX = self.FloatCursorX
						self.CursorY = self.CursorY + 1
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Up then
					setupMove(keycodes.Up,function()
						self.CursorX = self.FloatCursorX
						self.CursorY = self.CursorY - 1
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Left then
					setupMove(keycodes.Left,function()
						local line = self.Lines[self.CursorY+1] or ""
						self.CursorX = self.CursorX - 1 - (line:sub(self.CursorX-3,self.CursorX) == tabReplacement and 3 or 0)
						if self.CursorX < 0 then
							self.CursorY = self.CursorY - 1
							local line2 = self.Lines[self.CursorY+1] or ""
							self.CursorX = #line2
						end
						self.FloatCursorX = self.CursorX
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Right then
					setupMove(keycodes.Right,function()
						local line = self.Lines[self.CursorY+1] or ""
						self.CursorX = self.CursorX + 1 + (line:sub(self.CursorX+1,self.CursorX+4) == tabReplacement and 3 or 0)
						if self.CursorX > #line then
							self.CursorY = self.CursorY + 1
							self.CursorX = 0
						end
						self.FloatCursorX = self.CursorX
						self:UpdateCursor()
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Backspace then
					setupMove(keycodes.Backspace,function()
						local startRange,endRange
						if self:IsValidRange() then
							startRange = self.SelectionRange[1]
							endRange = self.SelectionRange[2]
						else
							endRange = {self.CursorX,self.CursorY}
						end

						if not startRange then
							local line = self.Lines[self.CursorY+1] or ""
							self.CursorX = self.CursorX - 1 - (line:sub(self.CursorX-3,self.CursorX) == tabReplacement and 3 or 0)
							if self.CursorX < 0 then
								self.CursorY = self.CursorY - 1
								local line2 = self.Lines[self.CursorY+1] or ""
								self.CursorX = #line2
							end
							self.FloatCursorX = self.CursorX
							self:UpdateCursor()

							startRange = startRange or {self.CursorX,self.CursorY}
						end

						self:DeleteRange({startRange,endRange},false,true)
						self:ResetSelection(true)
						self:JumpToCursor()
					end)
				elseif keycode == keycodes.Delete then
					setupMove(keycodes.Delete,function()
						local startRange,endRange
						if self:IsValidRange() then
							startRange = self.SelectionRange[1]
							endRange = self.SelectionRange[2]
						else
							startRange = {self.CursorX,self.CursorY}
						end

						if not endRange then
							local line = self.Lines[self.CursorY+1] or ""
							local endCursorX = self.CursorX + 1 + (line:sub(self.CursorX+1,self.CursorX+4) == tabReplacement and 3 or 0)
							local endCursorY = self.CursorY
							if endCursorX > #line then
								endCursorY = endCursorY + 1
								endCursorX = 0
							end
							self:UpdateCursor()

							endRange = endRange or {endCursorX,endCursorY}
						end

						self:DeleteRange({startRange,endRange},false,true)
						self:ResetSelection(true)
						self:JumpToCursor()
					end)
				elseif service.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					if keycode == keycodes.A then
						self.SelectionRange = {{0,0},{#self.Lines[#self.Lines],#self.Lines-1}}
						self:SetCopyableSelection()
						self:Refresh()
					end
				end
			end)
		end

		funcs.DisconnectEditBoxEvent = function(self)
			if self.EditBoxEvent then
				self.EditBoxEvent:Disconnect()
			end
		end

		funcs.ResetSelection = function(self,norefresh)
			self.SelectionRange = {{-1,-1},{-1,-1}}
			if not norefresh then self:Refresh() end
		end

		funcs.IsValidRange = function(self,range)
			local selectionRange = range or self.SelectionRange
			local selX,selY = selectionRange[1][1], selectionRange[1][2]
			local sel2X,sel2Y = selectionRange[2][1], selectionRange[2][2]

			if selX == -1 or (selX == sel2X and selY == sel2Y) then return false end

			return true
		end

		funcs.DeleteRange = function(self,range,noprocess,updatemouse)
			range = range or self.SelectionRange
			if not self:IsValidRange(range) then return end

			local lines = self.Lines
			local selX,selY = range[1][1], range[1][2]
			local sel2X,sel2Y = range[2][1], range[2][2]
			local deltaLines = sel2Y-selY

			if not lines[selY+1] or not lines[sel2Y+1] then return end

			local leftSub = lines[selY+1]:sub(1,selX)
			local rightSub = lines[sel2Y+1]:sub(sel2X+1)
			lines[selY+1] = leftSub..rightSub

			local remove = table.remove
			for i = 1,deltaLines do
				remove(lines,selY+2)
			end

			if range == self.SelectionRange then self.SelectionRange = {{-1,-1},{-1,-1}} end
			if updatemouse then
				self.CursorX = selX
				self.CursorY = selY
				self:UpdateCursor()
			end

			if not noprocess then
				self:ProcessTextChange()
			end
		end

		funcs.AppendText = function(self,text)
			self:DeleteRange(nil,true,true)
			local lines,cursorX,cursorY = self.Lines,self.CursorX,self.CursorY
			local line = lines[cursorY+1]
			local before = line:sub(1,cursorX)
			local after = line:sub(cursorX+1)

			text = text:gsub("\r\n","\n")
			text = self:ConvertText(text,true) -- Tab Convert

			local textLines = text:split("\n")
			local insert = table.insert

			for i = 1,#textLines do
				local linePos = cursorY+i
				if i > 1 then insert(lines,linePos,"") end

				local textLine = textLines[i]
				local newBefore = (i == 1 and before or "")
				local newAfter = (i == #textLines and after or "")

				lines[linePos] = newBefore..textLine..newAfter
			end

			if #textLines > 1 then cursorX = 0 end

			self:ProcessTextChange()
			self.CursorX = cursorX + #textLines[#textLines]
			self.CursorY = cursorY + #textLines-1
			self:UpdateCursor()
		end

		funcs.ScrollDelta = function(self,x,y)
			self.ScrollV:ScrollTo(self.ScrollV.Index + y)
			self.ScrollH:ScrollTo(self.ScrollH.Index + x)
		end

		-- x and y starts at 0
		funcs.TabAdjust = function(self,x,y)
			local lines = self.Lines
			local line = lines[y+1]
			x=x+1

			if line then
				local left = line:sub(x-1,x-1)
				local middle = line:sub(x,x)
				local right = line:sub(x+1,x+1)
				local selRange = (#left > 0 and left or " ") .. (#middle > 0 and middle or " ") .. (#right > 0 and right or " ")

				for i,v in pairs(tabJumps) do
					if selRange:find(i) then
						return v
					end
				end
			end
			return 0
		end

		funcs.SetEditing = function(self,on,input)			
			self:UpdateCursor(input)

			if on then
				if self.Editable then
					self.GuiElems.EditBox.Text = ""
					self.GuiElems.EditBox:CaptureFocus()
				end
			else
				self.GuiElems.EditBox:ReleaseFocus()
			end
		end

		funcs.CursorAnim = function(self,on)
			local cursor = self.GuiElems.Cursor
			local animTime = tick()
			self.LastAnimTime = animTime

			if not on then return end

			lineTweens.Invis:Cancel()
			lineTweens.Vis:Cancel()
			cursor.BackgroundTransparency = 0

			coroutine.wrap(function()
				while self.Editable do
					Lib.FastWait(0.5)
					if self.LastAnimTime ~= animTime then return end
					lineTweens.Invis:Play()
					Lib.FastWait(0.4)
					if self.LastAnimTime ~= animTime then return end
					lineTweens.Vis:Play()
					Lib.FastWait(0.2)
				end
			end)()
		end

		funcs.MoveCursor = function(self,x,y)
			self.CursorX = x
			self.CursorY = y
			self:UpdateCursor()
			self:JumpToCursor()
		end

		funcs.JumpToCursor = function(self)
			self:Refresh()
		end

		funcs.UpdateCursor = function(self,input)
			local linesFrame = self.GuiElems.LinesFrame
			local cursor = self.GuiElems.Cursor			
			local hSize = math.max(0,linesFrame.AbsoluteSize.X)
			local vSize = math.max(0,linesFrame.AbsoluteSize.Y)
			local maxLines = math.ceil(vSize / self.FontSize)
			local maxCols = math.ceil(hSize / math.ceil(self.FontSize/2))
			local viewX,viewY = self.ViewX,self.ViewY
			local totalLinesStr = tostring(#self.Lines)
			local fontWidth = math.ceil(self.FontSize / 2)
			local linesOffset = #totalLinesStr*fontWidth + 4*fontWidth

			if input then
				local linesFrame = self.GuiElems.LinesFrame
				local frameX,frameY = linesFrame.AbsolutePosition.X,linesFrame.AbsolutePosition.Y
				local mouseX,mouseY = input.Position.X,input.Position.Y
				local fontSizeX,fontSizeY = math.ceil(self.FontSize/2),self.FontSize

				self.CursorX = self.ViewX + math.round((mouseX - frameX) / fontSizeX)
				self.CursorY = self.ViewY + math.floor((mouseY - frameY) / fontSizeY)
			end

			local cursorX,cursorY = self.CursorX,self.CursorY

			local line = self.Lines[cursorY+1] or ""
			if cursorX > #line then cursorX = #line
			elseif cursorX < 0 then cursorX = 0 end

			if cursorY >= #self.Lines then
				cursorY = math.max(0,#self.Lines-1)
			elseif cursorY < 0 then
				cursorY = 0
			end

			cursorX = cursorX + self:TabAdjust(cursorX,cursorY)

			-- Update modified
			self.CursorX = cursorX
			self.CursorY = cursorY

			local cursorVisible = (cursorX >= viewX) and (cursorY >= viewY) and (cursorX <= viewX + maxCols) and (cursorY <= viewY + maxLines)
			if cursorVisible then
				local offX = (cursorX - viewX)
				local offY = (cursorY - viewY)
				cursor.Position = UDim2.new(0,linesOffset + offX*math.ceil(self.FontSize/2) - 1,0,offY*self.FontSize)
				cursor.Size = UDim2.new(0,1,0,self.FontSize+2)
				cursor.Visible = true
				self:CursorAnim(true)
			else
				cursor.Visible = false
			end
			self.OnCursorMoved:Fire(self.CursorY + 1, self.CursorX + 1)
		end

		funcs.MapNewLines = function(self)
			local newLines = {}
			local count = 1
			local text = self.Text
			local find = string.find
			local init = 1

			local pos = find(text,"\n",init,true)
			while pos do
				newLines[count] = pos
				count = count + 1
				init = pos + 1
				pos = find(text,"\n",init,true)
			end

			self.NewLines = newLines
		end

		funcs.PreHighlight = function(self)
			local start = tick()
			local text = self.Text:gsub("\\\\","  ")
			--print("BACKSLASH SUB",tick()-start)
			local textLen = #text
			local found = {}
			local foundMap = {}
			local extras = {}
			local find = string.find
			local sub = string.sub
			self.ColoredLines = {}

			local function findAll(str,pattern,typ,raw)
				local count = #found+1
				local init = 1
				local x,y,extra = find(str,pattern,init,raw)
				while x do
					found[count] = x
					foundMap[x] = typ
					if extra then
						extras[x] = extra
					end

					count = count+1
					init = y+1
					x,y,extra = find(str,pattern,init,raw)
				end
			end
			local start = tick()
			findAll(text,'"',1,true)
			findAll(text,"'",2,true)
			findAll(text,"%[(=*)%[",3)
			findAll(text,"--",4,true)
			table.sort(found)

			local newLines = self.NewLines
			local curLine = 0
			local lineTableCount = 1
			local lineStart = 0
			local lineEnd = 0
			local lastEnding = 0
			local foundHighlights = {}

			for i = 1,#found do
				local pos = found[i]
				if pos <= lastEnding then continue end

				local ending = pos
				local typ = foundMap[pos]
				if typ == 1 then
					ending = find(text,'"',pos+1,true)
					while ending and sub(text,ending-1,ending-1) == "\\" do
						ending = find(text,'"',ending+1,true)
					end
					if not ending then ending = textLen end
				elseif typ == 2 then
					ending = find(text,"'",pos+1,true)
					while ending and sub(text,ending-1,ending-1) == "\\" do
						ending = find(text,"'",ending+1,true)
					end
					if not ending then ending = textLen end
				elseif typ == 3 then
					_,ending = find(text,"]"..extras[pos].."]",pos+1,true)
					if not ending then ending = textLen end
				elseif typ == 4 then
					local ahead = foundMap[pos+2]

					if ahead == 3 then
						_,ending = find(text,"]"..extras[pos+2].."]",pos+1,true)
						if not ending then ending = textLen end
					else
						ending = find(text,"\n",pos+1,true) or textLen
					end
				end

				while pos > lineEnd do
					curLine = curLine + 1
					--lineTableCount = 1
					lineEnd = newLines[curLine] or textLen+1
				end
				while true do
					local lineTable = foundHighlights[curLine]
					if not lineTable then lineTable = {} foundHighlights[curLine] = lineTable end
					lineTable[pos] = {typ,ending}
					--lineTableCount = lineTableCount + 1

					if ending > lineEnd then
						curLine = curLine + 1
						lineEnd = newLines[curLine] or textLen+1
					else
						break
					end
				end

				lastEnding = ending
				--if i < 200 then print(curLine) end
			end
			self.PreHighlights = foundHighlights
			--print(tick()-start)
			--print(#found,curLine)
		end

		funcs.HighlightLine = function(self,line)
			local cached = self.ColoredLines[line]
			if cached then return cached end

			local sub = string.sub
			local find = string.find
			local match = string.match
			local highlights = {}
			local preHighlights = self.PreHighlights[line] or {}
			local lineText = self.Lines[line] or ""
			local lineLen = #lineText
			local lastEnding = 0
			local currentType = 0
			local lastWord = nil
			local wordBeginsDotted = false
			local funcStatus = 0
			local lineStart = self.NewLines[line-1] or 0

			local preHighlightMap = {}
			for pos,data in next,preHighlights do
				local relativePos = pos-lineStart
				if relativePos < 1 then
					currentType = data[1]
					lastEnding = data[2] - lineStart
					--warn(pos,data[2])
				else
					preHighlightMap[relativePos] = {data[1],data[2]-lineStart}
				end
			end

			for col = 1,#lineText do
				if col <= lastEnding then highlights[col] = currentType continue end

				local pre = preHighlightMap[col]
				if pre then
					currentType = pre[1]
					lastEnding = pre[2]
					highlights[col] = currentType
					wordBeginsDotted = false
					lastWord = nil
					funcStatus = 0
				else
					local char = sub(lineText,col,col)
					if find(char,"[%a_]") then
						local word = match(lineText,"[%a%d_]+",col)
						local wordType = (keywords[word] and 7) or (builtIns[word] and 8)

						lastEnding = col+#word-1

						if wordType ~= 7 then
							if wordBeginsDotted then
								local prevBuiltIn = lastWord and builtIns[lastWord]
								wordType = (prevBuiltIn and type(prevBuiltIn) == "table" and prevBuiltIn[word] and 8) or 10
							end

							if wordType ~= 8 then
								local x,y,br = find(lineText,"^%s*([%({\"'])",lastEnding+1)
								if x then
									wordType = (funcStatus > 0 and br == "(" and 16) or 9
									funcStatus = 0
								end
							end
						else
							wordType = specialKeywordsTypes[word] or wordType
							funcStatus = (word == "function" and 1 or 0)
						end

						lastWord = word
						wordBeginsDotted = false
						if funcStatus > 0 then funcStatus = 1 end

						if wordType then
							currentType = wordType
							highlights[col] = currentType
						else
							currentType = nil
						end
					elseif find(char,"%p") then
						local isDot = (char == ".")
						local isNum = isDot and find(sub(lineText,col+1,col+1),"%d")
						highlights[col] = (isNum and 6 or 5)

						if not isNum then
							local dotStr = isDot and match(lineText,"%.%.?%.?",col)
							if dotStr and #dotStr > 1 then
								currentType = 5
								lastEnding = col+#dotStr-1
								wordBeginsDotted = false
								lastWord = nil
								funcStatus = 0
							else
								if isDot then
									if wordBeginsDotted then
										lastWord = nil
									else
										wordBeginsDotted = true
									end
								else
									wordBeginsDotted = false
									lastWord = nil
								end

								funcStatus = ((isDot or char == ":") and funcStatus == 1 and 2) or 0
							end
						end
					elseif find(char,"%d") then
						local _,endPos = find(lineText,"%x+",col)
						local endPart = sub(lineText,endPos,endPos+1)
						if (endPart == "e+" or endPart == "e-") and find(sub(lineText,endPos+2,endPos+2),"%d") then
							endPos = endPos + 1
						end
						currentType = 6
						lastEnding = endPos
						highlights[col] = 6
						wordBeginsDotted = false
						lastWord = nil
						funcStatus = 0
					else
						highlights[col] = currentType
						local _,endPos = find(lineText,"%s+",col)
						if endPos then
							lastEnding = endPos
						end
					end
				end
			end

			self.ColoredLines[line] = highlights
			return highlights
		end

		funcs.Refresh = function(self)
			local start = tick()

			local linesFrame = self.Frame.Lines
			local hSize = math.max(0,linesFrame.AbsoluteSize.X)
			local vSize = math.max(0,linesFrame.AbsoluteSize.Y)
			local maxLines = math.ceil(vSize / self.FontSize)
			local maxCols = math.ceil(hSize / math.ceil(self.FontSize/2))
			local gsub = string.gsub
			local sub = string.sub

			local viewX,viewY = self.ViewX,self.ViewY

			local lineNumberStr = ""

			for row = 1,maxLines do
				local lineFrame = self.LineFrames[row]
				if not lineFrame then
					lineFrame = Instance.new("Frame")
					lineFrame.Name = "Line"
					lineFrame.Position = UDim2.new(0,0,0,(row-1)*self.FontSize)
					lineFrame.Size = UDim2.new(1,0,0,self.FontSize)
					lineFrame.BorderSizePixel = 0
					lineFrame.BackgroundTransparency = 1

					local selectionHighlight = Instance.new("Frame")
					selectionHighlight.Name = "SelectionHighlight"
					selectionHighlight.BorderSizePixel = 0
					selectionHighlight.BackgroundColor3 = Settings.Theme.Syntax.SelectionBack
					selectionHighlight.Parent = lineFrame

					local label = Instance.new("TextLabel")
					label.Name = "Label"
					label.BackgroundTransparency = 1
					label.Font = Enum.Font.Code
					label.TextSize = self.FontSize
					label.Size = UDim2.new(1,0,0,self.FontSize)
					label.RichText = true
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextColor3 = self.Colors.Text
					label.ZIndex = 2
					label.Parent = lineFrame

					lineFrame.Parent = linesFrame
					self.LineFrames[row] = lineFrame
				end

				local relaY = viewY + row
				local lineText = self.Lines[relaY] or ""
				local resText = ""
				local highlights = self:HighlightLine(relaY)
				local colStart = viewX + 1

				local richTemplates = self.RichTemplates
				local textTemplate = richTemplates.Text
				local selectionTemplate = richTemplates.Selection
				local curType = highlights[colStart]
				local curTemplate = richTemplates[typeMap[curType]] or textTemplate

				-- Selection Highlight
				local selectionRange = self.SelectionRange
				local selPos1 = selectionRange[1]
				local selPos2 = selectionRange[2]
				local selRow,selColumn = selPos1[2],selPos1[1]
				local sel2Row,sel2Column = selPos2[2],selPos2[1]
				local selRelaX,selRelaY = viewX,relaY-1

				if selRelaY >= selPos1[2] and selRelaY <= selPos2[2] then
					local fontSizeX = math.ceil(self.FontSize/2)
					local posX = (selRelaY == selPos1[2] and selPos1[1] or 0) - viewX
					local sizeX = (selRelaY == selPos2[2] and selPos2[1]-posX-viewX or maxCols+viewX)

					lineFrame.SelectionHighlight.Position = UDim2.new(0,posX*fontSizeX,0,0)
					lineFrame.SelectionHighlight.Size = UDim2.new(0,sizeX*fontSizeX,1,0)
					lineFrame.SelectionHighlight.Visible = true
				else
					lineFrame.SelectionHighlight.Visible = false
				end

				-- Selection Text Color for first char
				local inSelection = selRelaY >= selRow and selRelaY <= sel2Row and (selRelaY == selRow and viewX >= selColumn or selRelaY ~= selRow) and (selRelaY == sel2Row and viewX < sel2Column or selRelaY ~= sel2Row)
				if inSelection then
					curType = -999
					curTemplate = selectionTemplate
				end

				for col = 2,maxCols do
					local relaX = viewX + col
					local selRelaX = relaX-1
					local posType = highlights[relaX]

					-- Selection Text Color
					local inSelection = selRelaY >= selRow and selRelaY <= sel2Row and (selRelaY == selRow and selRelaX >= selColumn or selRelaY ~= selRow) and (selRelaY == sel2Row and selRelaX < sel2Column or selRelaY ~= sel2Row)
					if inSelection then
						posType = -999
					end

					if posType ~= curType then
						local template = (inSelection and selectionTemplate) or richTemplates[typeMap[posType]] or textTemplate

						if template ~= curTemplate then
							local nextText = gsub(sub(lineText,colStart,relaX-1),"['\"<>&]",richReplace)
							resText = resText .. (curTemplate ~= textTemplate and (curTemplate .. nextText .. "</font>") or nextText)
							colStart = relaX
							curTemplate = template
						end
						curType = posType
					end
				end

				local lastText = gsub(sub(lineText,colStart,viewX+maxCols),"['\"<>&]",richReplace)
				--warn("SUB",colStart,viewX+maxCols-1)
				if #lastText > 0 then
					resText = resText .. (curTemplate ~= textTemplate and (curTemplate .. lastText .. "</font>") or lastText)
				end

				if self.Lines[relaY] then

					-- REMOVED LINE HIGHLIGHT DUE TO BUG OFFSET
					lineNumberStr = lineNumberStr .. (relaY == self.CursorY and ("<b>"..relaY.."</b>\n") or relaY .. "\n")
					--lineNumberStr = lineNumberStr .. (relaY == self.CursorY and (relaY.."\n") or relaY .. "\n")
				end

				lineFrame.Label.Text = resText
			end

			for i = maxLines+1,#self.LineFrames do
				self.LineFrames[i]:Destroy()
				self.LineFrames[i] = nil
			end

			self.Frame.LineNumbers.Text = lineNumberStr
			self:UpdateCursor()

			--print("REFRESH TIME",tick()-start)
		end

		funcs.UpdateView = function(self)
			local totalLinesStr = tostring(#self.Lines)
			local fontWidth = math.ceil(self.FontSize / 2)
			local linesOffset = #totalLinesStr*fontWidth + 4*fontWidth

			local linesFrame = self.Frame.Lines
			local hSize = linesFrame.AbsoluteSize.X
			local vSize = linesFrame.AbsoluteSize.Y
			local maxLines = math.ceil(vSize / self.FontSize)
			local totalWidth = self.MaxTextCols*fontWidth
			local scrollV = self.ScrollV
			local scrollH = self.ScrollH

			scrollV.VisibleSpace = maxLines
			scrollV.TotalSpace = #self.Lines + 1
			scrollH.VisibleSpace = math.ceil(hSize/fontWidth)
			scrollH.TotalSpace = self.MaxTextCols + 1

			scrollV.Gui.Visible = #self.Lines + 1 > maxLines
			scrollH.Gui.Visible = totalWidth > hSize

			local oldOffsets = self.FrameOffsets
			self.FrameOffsets = Vector2.new(scrollV.Gui.Visible and -16 or 0, scrollH.Gui.Visible and -16 or 0)
			if oldOffsets ~= self.FrameOffsets then
				self:UpdateView()
			else
				scrollV:ScrollTo(self.ViewY,true)
				scrollH:ScrollTo(self.ViewX,true)

				if scrollV.Gui.Visible and scrollH.Gui.Visible then
					scrollV.Gui.Size = UDim2.new(0,16,1,-16)
					scrollH.Gui.Size = UDim2.new(1,-16,0,16)
					self.GuiElems.ScrollCorner.Visible = true
				else
					scrollV.Gui.Size = UDim2.new(0,16,1,0)
					scrollH.Gui.Size = UDim2.new(1,0,0,16)
					self.GuiElems.ScrollCorner.Visible = false
				end

				self.ViewY = scrollV.Index
				self.ViewX = scrollH.Index
				self.Frame.Lines.Position = UDim2.new(0,linesOffset,0,0)
				self.Frame.Lines.Size = UDim2.new(1,-linesOffset+oldOffsets.X,1,oldOffsets.Y)
				self.Frame.LineNumbers.Position = UDim2.new(0,fontWidth,0,0)
				self.Frame.LineNumbers.Size = UDim2.new(0,#totalLinesStr*fontWidth,1,oldOffsets.Y)
				self.Frame.LineNumbers.TextSize = self.FontSize
			end
		end

		funcs.ProcessTextChange = function(self)
			local maxCols = 0
			local lines = self.Lines

			for i = 1,#lines do
				local lineLen = #lines[i]
				if lineLen > maxCols then
					maxCols = lineLen
				end
			end

			self.MaxTextCols = maxCols
			self:UpdateView()	
			self.Text = table.concat(self.Lines,"\n")
			self:MapNewLines()
			self:PreHighlight()
			self:Refresh()
			self.OnTextChanged:Fire(#self.Lines)
		end

		funcs.ConvertText = function(self,text,toEditor)
			if toEditor then
				--return text:gsub("\t",(" %s%s "):format(tabSub,tabSub))
				return text:gsub("\t","    ") -- Fixed unknown unicode showing when pressing TAB
			else
				return text:gsub((" %s%s "):format(tabSub,tabSub),"\t")
			end
		end

		funcs.GetText = function(self) -- TODO: better (use new tab format)
			local source = table.concat(self.Lines,"\n")
			return self:ConvertText(source,false) -- Tab Convert
		end

		funcs.SetText = function(self,txt)
			txt = self:ConvertText(txt,true) -- Tab Convert
			local lines = self.Lines
			table.clear(lines)
			local count = 1

			for line in txt:gmatch("([^\n\r]*)[\n\r]?") do
				local len = #line
				lines[count] = line
				count = count + 1
			end

			self:ProcessTextChange()
		end

		funcs.MakeRichTemplates = function(self)
			local floor = math.floor
			local templates = {}

			for name,color in pairs(self.Colors) do
				templates[name] = ('<font color="rgb(%s,%s,%s)">'):format(floor(color.r*255),floor(color.g*255),floor(color.b*255))
			end

			self.RichTemplates = templates
		end

		funcs.ApplyTheme = function(self)
			local colors = Settings.Theme.Syntax
			self.Colors = colors
			self.Frame.LineNumbers.TextColor3 = colors.Text
			self.Frame.BackgroundColor3 = colors.Background
		end

		local mt = {__index = funcs}

		local function new()
			if not builtInInited then initBuiltIn() end

			local scrollV = Lib.ScrollBar.new()
			local scrollH = Lib.ScrollBar.new(true)
			scrollH.Gui.Position = UDim2.new(0,0,1,-16)
			local obj = setmetatable({
				FontSize = 16,
				ViewX = 0,
				ViewY = 0,
				Colors = Settings.Theme.Syntax,
				ColoredLines = {},
				Lines = {""},
				LineFrames = {},
				Editable = true,
				Editing = false,
				CursorX = 0,
				CursorY = 0,
				FloatCursorX = 0,
				Text = "",
				PreHighlights = {},
				SelectionRange = {{-1,-1},{-1,-1}},
				NewLines = {},
				FrameOffsets = Vector2.new(0,0),
				MaxTextCols = 0,
				ScrollV = scrollV,
				ScrollH = scrollH,
				OnCursorMoved = Lib.Signal.new(),
				OnTextChanged = Lib.Signal.new()
			},mt)

			scrollV.WheelIncrement = 3
			scrollH.Increment = 2
			scrollH.WheelIncrement = 7

			scrollV.Scrolled:Connect(function()
				obj.ViewY = scrollV.Index
				obj:Refresh()
			end)

			scrollH.Scrolled:Connect(function()
				obj.ViewX = scrollH.Index
				obj:Refresh()
			end)

			makeFrame(obj)
			obj:MakeRichTemplates()
			obj:ApplyTheme()
			scrollV:SetScrollFrame(obj.Frame.Lines)
			scrollV.Gui.Parent = obj.Frame
			scrollH.Gui.Parent = obj.Frame

			obj:UpdateView()
			obj.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				obj:UpdateView()
				obj:Refresh()
			end)

			return obj
		end

		return {new = new}
	end)()

	Lib.Checkbox = (function()
		local funcs = {}
		local c3 = Color3.fromRGB
		local v2 = Vector2.new
		local ud2s = UDim2.fromScale
		local ud2o = UDim2.fromOffset
		local ud = UDim.new
		local max = math.max
		local new = Instance.new
		local TweenSize = new("Frame").TweenSize
		local ti = TweenInfo.new
		local delay = delay

		local function ripple(object, color)
			local circle = new('Frame')
			circle.BackgroundColor3 = color
			circle.BackgroundTransparency = 0.75
			circle.BorderSizePixel = 0
			circle.AnchorPoint = v2(0.5, 0.5)
			circle.Size = ud2o()
			circle.Position = ud2s(0.5, 0.5)
			circle.Parent = object
			local rounding = new('UICorner')
			rounding.CornerRadius = ud(1)
			rounding.Parent = circle

			local abssz = object.AbsoluteSize
			local size = max(abssz.X, abssz.Y) * 5/3

			TweenSize(circle, ud2o(size, size), "Out", "Quart", 0.4)
			service.TweenService:Create(circle, ti(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()

			service.Debris:AddItem(circle, 0.4)
		end

		local function initGui(self,frame)
			local checkbox = frame or create({
				{1,"ImageButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Checkbox",Position=UDim2.new(0,3,0,3),Size=UDim2.new(0,16,0,16),}},
				{2,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ripples",Parent={1},Size=UDim2.new(1,0,1,0),}},
				{3,"Frame",{BackgroundColor3=Color3.new(0.10196078568697,0.10196078568697,0.10196078568697),BorderSizePixel=0,Name="outline",Parent={1},Size=UDim2.new(0,16,0,16),}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.14117647707462,0.14117647707462,0.14117647707462),BorderSizePixel=0,Name="filler",Parent={3},Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,14,0,14),}},
				{5,"Frame",{BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="top",Parent={4},Size=UDim2.new(0,16,0,0),}},
				{6,"Frame",{AnchorPoint=Vector2.new(0,1),BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="bottom",Parent={4},Position=UDim2.new(0,0,0,14),Size=UDim2.new(0,16,0,0),}},
				{7,"Frame",{BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="left",Parent={4},Size=UDim2.new(0,0,0,16),}},
				{8,"Frame",{AnchorPoint=Vector2.new(1,0),BackgroundColor3=Color3.new(0.90196084976196,0.90196084976196,0.90196084976196),BorderSizePixel=0,Name="right",Parent={4},Position=UDim2.new(0,14,0,0),Size=UDim2.new(0,0,0,16),}},
				{9,"Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Name="checkmark",Parent={4},Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,0,0,20),}},
				{10,"ImageLabel",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/checkmark.png")) and getcustomasset("DEX_REContinued/Images/checkmark.png") or "rbxassetid://6234266378",Parent={9},Position=UDim2.new(0.5,0,0.5,0),ScaleType=3,Size=UDim2.new(0,15,0,11),}},
				{11,"ImageLabel",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/checkmark (2).png")) and getcustomasset("DEX_REContinued/Images/checkmark (2).png") or "rbxassetid://6401617475",ImageColor3=Color3.new(0.20784313976765,0.69803923368454,0.98431372642517),Name="checkmark2",Parent={4},Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,12,0,12),Visible=false,}},
				{12,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/luvlies.png")) and getcustomasset("DEX_REContinued/luvlies.png") or "rbxassetid://6425281788",ImageTransparency=0.20000000298023,Name="middle",Parent={4},ScaleType=2,Size=UDim2.new(1,0,1,0),TileSize=UDim2.new(0,2,0,2),Visible=false,}},
				{13,"UICorner",{CornerRadius=UDim.new(0,2),Parent={3},}},
			})
			local outline = checkbox.outline
			local filler = outline.filler
			local checkmark = filler.checkmark
			local ripples_container = checkbox.ripples

			-- walls
			local top, bottom, left, right = filler.top, filler.bottom, filler.left, filler.right

			self.Gui = checkbox
			self.GuiElems = {
				Top = top,
				Bottom = bottom,
				Left = left,
				Right = right,
				Outline = outline,
				Filler = filler,
				Checkmark = checkmark,
				Checkmark2 = filler.checkmark2,
				Middle = filler.middle
			}
	
			-- New:
			--[[checkbox.Activated:Connect(function()
				if Lib.CheckMouseInGui(checkbox) then
					if self.Style == 0 then
						ripple(ripples_container, self.Disabled and self.Colors.Disabled or self.Colors.Primary)
					end

					if not self.Disabled then
						self:SetState(not self.Toggled,true)
					else
						self:Paint()
					end

					self.OnInput:Fire()
				end
			end)]]
			
			-- Best input compatibility:
			checkbox.MouseButton1Up:Connect(function()
				if Lib.CheckMouseInGui(checkbox) then
					if self.Style == 0 then
						ripple(ripples_container, self.Disabled and self.Colors.Disabled or self.Colors.Primary)
					end

					if not self.Disabled then
						self:SetState(not self.Toggled,true)
					else
						self:Paint()
					end

					self.OnInput:Fire()
				end
			end)

			-- Old:
			--[[checkbox.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					local release
					release = service.UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							release:Disconnect()

							if Lib.CheckMouseInGui(checkbox) then
								if self.Style == 0 then
									ripple(ripples_container, self.Disabled and self.Colors.Disabled or self.Colors.Primary)
								end

								if not self.Disabled then
									self:SetState(not self.Toggled,true)
								else
									self:Paint()
								end
								
								self.OnInput:Fire()
							end
						end
					end)
				end
			end)]]

			self:Paint()
		end

		funcs.Collapse = function(self,anim)
			local guiElems = self.GuiElems
			if anim then
				TweenSize(guiElems.Top, ud2o(14, 14), "In", "Quart", 4/15, true)
				TweenSize(guiElems.Bottom, ud2o(14, 14), "In", "Quart", 4/15, true)
				TweenSize(guiElems.Left, ud2o(14, 14), "In", "Quart", 4/15, true)
				TweenSize(guiElems.Right, ud2o(14, 14), "In", "Quart", 4/15, true)
			else
				guiElems.Top.Size = ud2o(14, 14)
				guiElems.Bottom.Size = ud2o(14, 14)
				guiElems.Left.Size = ud2o(14, 14)
				guiElems.Right.Size = ud2o(14, 14)
			end
		end

		funcs.Expand = function(self,anim)
			local guiElems = self.GuiElems
			if anim then
				TweenSize(guiElems.Top, ud2o(14, 0), "InOut", "Quart", 4/15, true)
				TweenSize(guiElems.Bottom, ud2o(14, 0), "InOut", "Quart", 4/15, true)
				TweenSize(guiElems.Left, ud2o(0, 14), "InOut", "Quart", 4/15, true)
				TweenSize(guiElems.Right, ud2o(0, 14), "InOut", "Quart", 4/15, true)
			else
				guiElems.Top.Size = ud2o(14, 0)
				guiElems.Bottom.Size = ud2o(14, 0)
				guiElems.Left.Size = ud2o(0, 14)
				guiElems.Right.Size = ud2o(0, 14)
			end
		end

		funcs.Paint = function(self)
			local guiElems = self.GuiElems

			if self.Style == 0 then
				local color_base = self.Disabled and self.Colors.Disabled
				guiElems.Outline.BackgroundColor3 = color_base or (self.Toggled and self.Colors.Primary) or self.Colors.Secondary
				local walls_color = color_base or self.Colors.Primary
				guiElems.Top.BackgroundColor3 = walls_color
				guiElems.Bottom.BackgroundColor3 = walls_color
				guiElems.Left.BackgroundColor3 = walls_color
				guiElems.Right.BackgroundColor3 = walls_color
			else
				guiElems.Outline.BackgroundColor3 = self.Disabled and self.Colors.Disabled or self.Colors.Secondary
				guiElems.Filler.BackgroundColor3 = self.Disabled and self.Colors.DisabledBackground or self.Colors.Background
				guiElems.Checkmark2.ImageColor3 = self.Disabled and self.Colors.DisabledCheck or self.Colors.Primary
			end
		end

		funcs.SetState = function(self,val,anim)
			self.Toggled = val

			if self.OutlineColorTween then self.OutlineColorTween:Cancel() end
			local setStateTime = tick()
			self.LastSetStateTime = setStateTime

			if self.Toggled then
				if self.Style == 0 then
					if anim then
						self.OutlineColorTween = service.TweenService:Create(self.GuiElems.Outline, ti(4/15, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {BackgroundColor3 = self.Colors.Primary})
						self.OutlineColorTween:Play()
						delay(0.15, function()
							if setStateTime ~= self.LastSetStateTime then return end
							self:Paint()
							TweenSize(self.GuiElems.Checkmark, ud2o(14, 20), "Out", "Bounce", 2/15, true)
						end)
					else
						self.GuiElems.Outline.BackgroundColor3 = self.Colors.Primary
						self:Paint()
						self.GuiElems.Checkmark.Size = ud2o(14, 20)
					end
					self:Collapse(anim)
				else
					self:Paint()
					self.GuiElems.Checkmark2.Visible = true
					self.GuiElems.Middle.Visible = false
				end
			else
				if self.Style == 0 then
					if anim then
						self.OutlineColorTween = service.TweenService:Create(self.GuiElems.Outline, ti(4/15, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {BackgroundColor3 = self.Colors.Secondary})
						self.OutlineColorTween:Play()
						delay(0.15, function()
							if setStateTime ~= self.LastSetStateTime then return end
							self:Paint()
							TweenSize(self.GuiElems.Checkmark, ud2o(0, 20), "Out", "Quad", 1/15, true)
						end)
					else
						self.GuiElems.Outline.BackgroundColor3 = self.Colors.Secondary
						self:Paint()
						self.GuiElems.Checkmark.Size = ud2o(0, 20)
					end
					self:Expand(anim)
				else
					self:Paint()
					self.GuiElems.Checkmark2.Visible = false
					self.GuiElems.Middle.Visible = self.Toggled == nil
				end
			end
		end

		local mt = {__index = funcs}

		local function new(style)
			local obj = setmetatable({
				Toggled = false,
				Disabled = false,
				OnInput = Lib.Signal.new(),
				Style = style or 0,
				Colors = {
					Background = c3(36,36,36),
					Primary = c3(49,176,230),
					Secondary = c3(25,25,25),
					Disabled = c3(64,64,64),
					DisabledBackground = c3(52,52,52),
					DisabledCheck = c3(80,80,80)
				}
			},mt)
			initGui(obj)
			return obj
		end

		local function fromFrame(frame)
			local obj = setmetatable({
				Toggled = false,
				Disabled = false,
				Colors = {
					Background = c3(36,36,36),
					Primary = c3(49,176,230),
					Secondary = c3(25,25,25),
					Disabled = c3(64,64,64),
					DisabledBackground = c3(52,52,52)
				}
			},mt)
			initGui(obj,frame)
			return obj
		end

		return {new = new, fromFrame}
	end)()

			Lib.BrickColorPicker = (function()
				local funcs = {}
				local paletteCount = 0
				local mouse = service.Players.LocalPlayer:GetMouse()
				local hexStartX = 4
				local hexSizeX = 27
				local hexTriangleStart = 1
				local hexTriangleSize = 8

				local bottomColors = {
					Color3.fromRGB(17,17,17),
					Color3.fromRGB(99,95,98),
					Color3.fromRGB(163,162,165),
					Color3.fromRGB(205,205,205),
					Color3.fromRGB(223,223,222),
					Color3.fromRGB(237,234,234),
					Color3.fromRGB(27,42,53),
					Color3.fromRGB(91,93,105),
					Color3.fromRGB(159,161,172),
					Color3.fromRGB(202,203,209),
					Color3.fromRGB(231,231,236),
					Color3.fromRGB(248,248,248)
				}

				local function isMouseInHexagon(hex, touchPos)
					local relativeX = touchPos.X - hex.AbsolutePosition.X
					local relativeY = touchPos.Y - hex.AbsolutePosition.Y
					if relativeX >= hexStartX and relativeX < hexStartX + hexSizeX then
						relativeX = relativeX - 4
						local relativeWidth = (13 - math.min(relativeX, 26 - relativeX)) / 13
						if relativeY >= hexTriangleStart + hexTriangleSize * relativeWidth and relativeY < hex.AbsoluteSize.Y - hexTriangleStart - hexTriangleSize * relativeWidth then
							return true
						end
					end
					return false
				end

				local function hexInput(self, hex, color)
					hex.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							if isMouseInHexagon(hex, input.Position) then
								self.OnSelect:Fire(color)
								self:Close()
							end
						end
					end)

					hex.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							if isMouseInHexagon(hex, input.Position) then
								self.OnPreview:Fire(color)
							end
						end
					end)
				end

				local function createGui(self)
					local gui = create({
						{1,"ScreenGui",{Name="BrickColor",}},
						{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),Parent={1},Position=UDim2.new(0.40000000596046,0,0.40000000596046,0),Size=UDim2.new(0,337,0,380),}},
						{3,"TextButton",{BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="MoreColors",Parent={2},Position=UDim2.new(0,5,1,-30),Size=UDim2.new(1,-10,0,25),Text="More Colors",TextColor3=Color3.new(1,1,1),TextSize=14,}},
						{4,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image=(getcustomasset and isfile and isfile("DEX_REContinued/honey icon.png")) and getcustomasset("DEX_REContinued/honey icon.png") or "rbxassetid://1281023007",ImageColor3=Color3.new(0.33333334326744,0.33333334326744,0.49803924560547),Name="Hex",Parent={2},Size=UDim2.new(0,35,0,35),Visible=false,}},
					})
					local colorFrame = gui.Frame
					local hex = colorFrame.Hex

					for row = 1,13 do
						local columns = math.min(row,14-row)+6
						for column = 1,columns do
							local nextColor = BrickColor.palette(paletteCount).Color
							local newHex = hex:Clone()
							newHex.Position = UDim2.new(0, (column-1)*25-(columns-7)*13+3*26 + 1, 0, (row-1)*23 + 4)
							newHex.ImageColor3 = nextColor
							newHex.Visible = true
							hexInput(self,newHex,nextColor)
							newHex.Parent = colorFrame
							paletteCount = paletteCount + 1
						end
					end

					for column = 1,12 do
						local nextColor = bottomColors[column]
						local newHex = hex:Clone()
						newHex.Position = UDim2.new(0, (column-1)*25-(12-7)*13+3*26 + 3, 0, 308)
						newHex.ImageColor3 = nextColor
						newHex.Visible = true
						hexInput(self,newHex,nextColor)
						newHex.Parent = colorFrame
						paletteCount = paletteCount + 1
					end

					colorFrame.MoreColors.MouseButton1Click:Connect(function()
						self.OnMoreColors:Fire()
						self:Close()
					end)

					self.Gui = gui
				end

				funcs.SetMoreColorsVisible = function(self,vis)
					local colorFrame = self.Gui.Frame
					colorFrame.Size = UDim2.new(0,337,0,380 - (not vis and 33 or 0))
					colorFrame.MoreColors.Visible = vis
				end

				funcs.Show = function(self,x,y,prevColor)
					self.PrevColor = prevColor or self.PrevColor

					local reverseY = false

					local x,y = x or mouse.X, y or mouse.Y
					local maxX,maxY = mouse.ViewSizeX,mouse.ViewSizeY
					Lib.ShowGui(self.Gui)
					local sizeX,sizeY = self.Gui.Frame.AbsoluteSize.X,self.Gui.Frame.AbsoluteSize.Y

					if x + sizeX > maxX then x = self.ReverseX and x - sizeX or maxX - sizeX end
					if y + sizeY > maxY then reverseY = true end

					local closable = false
					if self.CloseEvent then self.CloseEvent:Disconnect() end

					self.CloseEvent = service.UserInputService.InputBegan:Connect(function(input)
						if not closable or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) then
							return
						end

						if not Lib.CheckMouseInGui(self.Gui.Frame) then
							self.CloseEvent:Disconnect()
							self:Close()
						end
					end)


					if reverseY then
						local newY = y - sizeY - (self.ReverseYOffset or 0)
						y = newY >= 0 and newY or 0
					end

					self.Gui.Frame.Position = UDim2.new(0,x,0,y)

					Lib.FastWait()
					closable = true
				end

				funcs.Close = function(self)
					self.Gui.Parent = nil
					self.OnCancel:Fire()
				end

				local mt = {__index = funcs}

				local function new()
					local obj = setmetatable({
						OnPreview = Lib.Signal.new(),
						OnSelect = Lib.Signal.new(),
						OnCancel = Lib.Signal.new(),
						OnMoreColors = Lib.Signal.new(),
						PrevColor = Color3.new(0,0,0)
					}, mt)
					createGui(obj)
					return obj
				end

				return {new = new}
			end)()

	Lib.ColorPicker = (function() -- TODO: Convert to newer class model
		local funcs = {}

		local function new()
			local newMt = setmetatable({},{})

			newMt.OnSelect = Lib.Signal.new()
			newMt.OnCancel = Lib.Signal.new()
			newMt.OnPreview = Lib.Signal.new()

			local guiContents = create({
				{1,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Content",Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),}},
				{2,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="BasicColors",Parent={1},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,180,0,200),}},
				{3,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Position=UDim2.new(0,0,0,-5),Size=UDim2.new(1,0,0,26),Text="Basic Colors",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{4,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Blue",Parent={1},Position=UDim2.new(1,-63,0,255),Size=UDim2.new(0,52,0,16),}},
				{5,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={4},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{6,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={5},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={6},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{8,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={7},Size=UDim2.new(0,16,0,8),}},
				{9,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={8},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{10,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={8},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{11,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={8},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{12,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={6},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{13,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={12},Size=UDim2.new(0,16,0,8),}},
				{14,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={13},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{15,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={13},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{16,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={13},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{17,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={4},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Blue:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{18,"Frame",{BackgroundColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,ClipsDescendants=true,Name="ColorSpaceFrame",Parent={1},Position=UDim2.new(1,-261,0,4),Size=UDim2.new(0,222,0,202),}},
				{19,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),BorderSizePixel=0,Image=(getcustomasset and isfile and isfile("DEX_REContinued/colors.png")) and getcustomasset("DEX_REContinued/colors.png") or "rbxassetid://1072518406",Name="ColorSpace",Parent={18},Position=UDim2.new(0,1,0,1),Size=UDim2.new(0,220,0,200),}},
				{20,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Scope",Parent={19},Position=UDim2.new(0,210,0,190),Size=UDim2.new(0,20,0,20),}},
				{21,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Name="Line",Parent={20},Position=UDim2.new(0,9,0,0),Size=UDim2.new(0,2,0,20),}},
				{22,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Name="Line",Parent={20},Position=UDim2.new(0,0,0,9),Size=UDim2.new(0,20,0,2),}},
				{23,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="CustomColors",Parent={1},Position=UDim2.new(0,5,0,210),Size=UDim2.new(0,180,0,90),}},
				{24,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={23},Size=UDim2.new(1,0,0,20),Text="Custom Colors (RC = Set)",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{25,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Green",Parent={1},Position=UDim2.new(1,-63,0,233),Size=UDim2.new(0,52,0,16),}},
				{26,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={25},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{27,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={26},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{28,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={27},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{29,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={28},Size=UDim2.new(0,16,0,8),}},
				{30,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={29},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{31,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={29},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{32,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={29},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{33,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={27},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{34,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={33},Size=UDim2.new(0,16,0,8),}},
				{35,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={34},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{36,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={34},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{37,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={34},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{38,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={25},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Green:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{39,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Hue",Parent={1},Position=UDim2.new(1,-180,0,211),Size=UDim2.new(0,52,0,16),}},
				{40,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={39},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{41,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={40},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{42,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={41},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{43,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={42},Size=UDim2.new(0,16,0,8),}},
				{44,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={43},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{45,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={43},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{46,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={43},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{47,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={41},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{48,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={47},Size=UDim2.new(0,16,0,8),}},
				{49,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={48},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{50,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={48},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{51,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={48},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{52,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={39},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Hue:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{53,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="Preview",Parent={1},Position=UDim2.new(1,-260,0,211),Size=UDim2.new(0,35,1,-245),}},
				{54,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Red",Parent={1},Position=UDim2.new(1,-63,0,211),Size=UDim2.new(0,52,0,16),}},
				{55,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={54},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{56,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={55},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{57,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={56},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{58,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={57},Size=UDim2.new(0,16,0,8),}},
				{59,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={58},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{60,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={58},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{61,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={58},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{62,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={56},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{63,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={62},Size=UDim2.new(0,16,0,8),}},
				{64,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={63},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{65,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={63},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{66,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={63},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{67,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={54},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Red:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{68,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Sat",Parent={1},Position=UDim2.new(1,-180,0,233),Size=UDim2.new(0,52,0,16),}},
				{69,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={68},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{70,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={69},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{71,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={70},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{72,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={71},Size=UDim2.new(0,16,0,8),}},
				{73,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={72},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{74,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={72},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{75,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={72},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{76,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={70},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{77,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={76},Size=UDim2.new(0,16,0,8),}},
				{78,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={77},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{79,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={77},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{80,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={77},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{81,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={68},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Sat:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{82,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Val",Parent={1},Position=UDim2.new(1,-180,0,255),Size=UDim2.new(0,52,0,16),}},
				{83,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Font=3,Name="Input",Parent={82},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,50,0,16),Text="255",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
				{84,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={83},Position=UDim2.new(1,-16,0,0),Size=UDim2.new(0,16,1,0),}},
				{85,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Up",Parent={84},Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{86,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={85},Size=UDim2.new(0,16,0,8),}},
				{87,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={86},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,1),}},
				{88,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={86},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{89,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={86},Position=UDim2.new(0,6,0,5),Size=UDim2.new(0,5,0,1),}},
				{90,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="Down",Parent={84},Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,0,8),Text="",TextSize=14,}},
				{91,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={90},Size=UDim2.new(0,16,0,8),}},
				{92,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={91},Position=UDim2.new(0,8,0,5),Size=UDim2.new(0,1,0,1),}},
				{93,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={91},Position=UDim2.new(0,7,0,4),Size=UDim2.new(0,3,0,1),}},
				{94,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={91},Position=UDim2.new(0,6,0,3),Size=UDim2.new(0,5,0,1),}},
				{95,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={82},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Val:",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
				{96,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Cancel",Parent={1},Position=UDim2.new(1,-105,1,-28),Size=UDim2.new(0,100,0,25),Text="Cancel",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{97,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Ok",Parent={1},Position=UDim2.new(1,-210,1,-28),Size=UDim2.new(0,100,0,25),Text="OK",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
				{98,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Image=(getcustomasset and isfile and isfile("DEX_REContinued/colorstrip.png")) and getcustomasset("DEX_REContinued/colorstrip.png") or "rbxassetid://1072518502",Name="ColorStrip",Parent={1},Position=UDim2.new(1,-30,0,5),Size=UDim2.new(0,13,0,200),}},
				{99,"Frame",{BackgroundColor3=Color3.new(0.3137255012989,0.3137255012989,0.3137255012989),BackgroundTransparency=1,BorderSizePixel=0,Name="ArrowFrame",Parent={1},Position=UDim2.new(1,-16,0,1),Size=UDim2.new(0,5,0,208),}},
				{100,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={99},Position=UDim2.new(0,-2,0,-4),Size=UDim2.new(0,8,0,16),}},
				{101,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,2,0,8),Size=UDim2.new(0,1,0,1),}},
				{102,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,3,0,7),Size=UDim2.new(0,1,0,3),}},
				{103,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,4,0,6),Size=UDim2.new(0,1,0,5),}},
				{104,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,5,0,5),Size=UDim2.new(0,1,0,7),}},
				{105,"Frame",{BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Parent={100},Position=UDim2.new(0,6,0,4),Size=UDim2.new(0,1,0,9),}},
			})
			local window = Lib.Window.new()
			window.Resizable = false
			window.Alignable = false
			window:SetTitle("Color Picker")
			window:Resize(450,330)
			for i,v in pairs(guiContents:GetChildren()) do
				v.Parent = window.GuiElems.Content
			end
			newMt.Window = window
			newMt.Gui = window.Gui
			local pickerGui = window.Gui.Main
			local pickerTopBar = pickerGui.TopBar
			local pickerFrame = pickerGui.Content
			local colorSpace = pickerFrame.ColorSpaceFrame.ColorSpace
			local colorStrip = pickerFrame.ColorStrip
			local previewFrame = pickerFrame.Preview
			local basicColorsFrame = pickerFrame.BasicColors
			local customColorsFrame = pickerFrame.CustomColors
			local okButton = pickerFrame.Ok
			local cancelButton = pickerFrame.Cancel
			local closeButton = pickerTopBar.Close

			local colorScope = colorSpace.Scope
			local colorArrow = pickerFrame.ArrowFrame.Arrow

			local hueInput = pickerFrame.Hue.Input
			local satInput = pickerFrame.Sat.Input
			local valInput = pickerFrame.Val.Input

			local redInput = pickerFrame.Red.Input
			local greenInput = pickerFrame.Green.Input
			local blueInput = pickerFrame.Blue.Input

			local user = service.UserInputService
			local mouse = service.Players.LocalPlayer:GetMouse()

			local hue,sat,val = 0,0,1
			local red,green,blue = 1,1,1
			local chosenColor = Color3.new(0,0,0)

			local basicColors = {Color3.new(0,0,0),Color3.new(0.66666668653488,0,0),Color3.new(0,0.33333334326744,0),Color3.new(0.66666668653488,0.33333334326744,0),Color3.new(0,0.66666668653488,0),Color3.new(0.66666668653488,0.66666668653488,0),Color3.new(0,1,0),Color3.new(0.66666668653488,1,0),Color3.new(0,0,0.49803924560547),Color3.new(0.66666668653488,0,0.49803924560547),Color3.new(0,0.33333334326744,0.49803924560547),Color3.new(0.66666668653488,0.33333334326744,0.49803924560547),Color3.new(0,0.66666668653488,0.49803924560547),Color3.new(0.66666668653488,0.66666668653488,0.49803924560547),Color3.new(0,1,0.49803924560547),Color3.new(0.66666668653488,1,0.49803924560547),Color3.new(0,0,1),Color3.new(0.66666668653488,0,1),Color3.new(0,0.33333334326744,1),Color3.new(0.66666668653488,0.33333334326744,1),Color3.new(0,0.66666668653488,1),Color3.new(0.66666668653488,0.66666668653488,1),Color3.new(0,1,1),Color3.new(0.66666668653488,1,1),Color3.new(0.33333334326744,0,0),Color3.new(1,0,0),Color3.new(0.33333334326744,0.33333334326744,0),Color3.new(1,0.33333334326744,0),Color3.new(0.33333334326744,0.66666668653488,0),Color3.new(1,0.66666668653488,0),Color3.new(0.33333334326744,1,0),Color3.new(1,1,0),Color3.new(0.33333334326744,0,0.49803924560547),Color3.new(1,0,0.49803924560547),Color3.new(0.33333334326744,0.33333334326744,0.49803924560547),Color3.new(1,0.33333334326744,0.49803924560547),Color3.new(0.33333334326744,0.66666668653488,0.49803924560547),Color3.new(1,0.66666668653488,0.49803924560547),Color3.new(0.33333334326744,1,0.49803924560547),Color3.new(1,1,0.49803924560547),Color3.new(0.33333334326744,0,1),Color3.new(1,0,1),Color3.new(0.33333334326744,0.33333334326744,1),Color3.new(1,0.33333334326744,1),Color3.new(0.33333334326744,0.66666668653488,1),Color3.new(1,0.66666668653488,1),Color3.new(0.33333334326744,1,1),Color3.new(1,1,1)}
			local customColors = {}

			local function updateColor(noupdate)
				local relativeX, relativeY, relativeStripY = 219 - hue * 219, 199 - sat * 199, 199 - val * 199
				local hsvColor = Color3.fromHSV(hue, sat, val)

				if noupdate == 2 or not noupdate then
					hueInput.Text = tostring(math.ceil(359 * hue))
					satInput.Text = tostring(math.ceil(255 * sat))
					valInput.Text = tostring(math.floor(255 * val))
				end
				if noupdate == 1 or not noupdate then
					redInput.Text = tostring(math.floor(255 * red))
					greenInput.Text = tostring(math.floor(255 * green))
					blueInput.Text = tostring(math.floor(255 * blue))
				end

				chosenColor = Color3.new(red, green, blue)
				colorScope.Position = UDim2.new(0, (relativeX - 9), 0, (relativeY - 9))
				colorStrip.ImageColor3 = Color3.fromHSV(hue, sat, 1)
				colorArrow.Position = UDim2.new(0, -2, 0, (relativeStripY - 4))
				previewFrame.BackgroundColor3 = chosenColor

				newMt.Color = chosenColor
				newMt.OnPreview:Fire(chosenColor)
			end

			local function handleInputBegan(input, updateFunc)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					while user:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						updateFunc()task.wait()
					end
				end
			end

			local function colorSpaceInput()
				local relativeX = mouse.X - colorSpace.AbsolutePosition.X
				local relativeY = mouse.Y - colorSpace.AbsolutePosition.Y

				if relativeX < 0 then relativeX = 0 elseif relativeX > 219 then relativeX = 219 end
				if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end

				hue = (219 - relativeX) / 219
				sat = (199 - relativeY) / 199

				local hsvColor = Color3.fromHSV(hue, sat, val)
				red, green, blue = hsvColor.R, hsvColor.G, hsvColor.B
				updateColor()
			end

			local function colorStripInput()
				local relativeY = mouse.Y - colorStrip.AbsolutePosition.Y

				if relativeY < 0 then relativeY = 0 elseif relativeY > 199 then relativeY = 199 end	

				val = (199 - relativeY) / 199

				local hsvColor = Color3.fromHSV(hue, sat, val)
				red, green, blue = hsvColor.R, hsvColor.G, hsvColor.B
				updateColor()
			end

			colorSpace.InputBegan:Connect(function(input) handleInputBegan(input, colorSpaceInput) end)
			colorStrip.InputBegan:Connect(function(input) handleInputBegan(input, colorStripInput) end)

			local function hookButtons(frame, func)
				frame.ArrowFrame.Up.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent, runEvent
						local startTime = tick()
						local pressing = true
						local startNum = tonumber(frame.Text)

						if not startNum then return end

						releaseEvent = user.InputEnded:Connect(function(endInput)
							if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								pressing = false
							end
						end)

						startNum = startNum + 1
						func(startNum)
						while pressing do
							if tick() - startTime > 0.3 then
								startNum = startNum + 1
								func(startNum)
								startTime = tick()
							end
							task.wait(0.1)
						end
					end
				end)

				frame.ArrowFrame.Down.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						local releaseEvent, runEvent
						local startTime = tick()
						local pressing = true
						local startNum = tonumber(frame.Text)

						if not startNum then return end

						releaseEvent = user.InputEnded:Connect(function(endInput)
							if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
								releaseEvent:Disconnect()
								pressing = false
							end
						end)

						startNum = startNum - 1
						func(startNum)
						while pressing do
							if tick() - startTime > 0.3 then
								startNum = startNum - 1
								func(startNum)
								startTime = tick()
							end
							task.wait(0.1)
						end
					end
				end)
			end

			--[[local function UpdateBox(TextBox, Value, IsHSV, ...)
				local number = tonumber(TextBox.Text)
				if number then
					number = math.clamp(math.floor(number), 0, Value) / Value
					local HSV = Color3.fromHSV(func(number))
					red, green, blue = HSV.R, HSV.G, HSV.B
					
					TextBox.Text = tostring(number):sub(4)
					updateColor(IsHSV)
				end
			end]]

			local function updateHue(str)
				local num = tonumber(str)
				if num then
					hue = math.clamp(math.floor(num),0,359)/359
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b

					hueInput.Text = tostring(hue*359)
					updateColor(1)
				end
			end
			hueInput.FocusLost:Connect(function() updateHue(hueInput.Text) end) hookButtons(hueInput, hueInput)

			local function updateSat(str)
				local num = tonumber(str)
				if num then
					sat = math.clamp(math.floor(num),0,255)/255
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
					satInput.Text = tostring(sat*255)
					updateColor(1)
				end
			end
			satInput.FocusLost:Connect(function() updateSat(satInput.Text) end) hookButtons(satInput,updateSat)

			local function updateVal(str)
				local num = tonumber(str)
				if num then
					val = math.clamp(math.floor(num),0,255)/255
					local hsvColor = Color3.fromHSV(hue,sat,val)
					red,green,blue = hsvColor.r,hsvColor.g,hsvColor.b
					valInput.Text = tostring(val*255)
					updateColor(1)
				end
			end
			valInput.FocusLost:Connect(function() updateVal(valInput.Text) end) hookButtons(valInput,updateVal)

			local function updateRed(str)
				local num = tonumber(str)
				if num then
					red = math.clamp(math.floor(num),0,255)/255
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					redInput.Text = tostring(red*255)
					updateColor(2)
				end
			end
			redInput.FocusLost:Connect(function() updateRed(redInput.Text) end) hookButtons(redInput,updateRed)

			local function updateGreen(str)
				local num = tonumber(str)
				if num then
					green = math.clamp(math.floor(num),0,255)/255
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					greenInput.Text = tostring(green*255)
					updateColor(2)
				end
			end
			greenInput.FocusLost:Connect(function() updateGreen(greenInput.Text) end) hookButtons(greenInput,updateGreen)

			local function updateBlue(str)
				local num = tonumber(str)
				if num then
					blue = math.clamp(math.floor(num),0,255)/255
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					blueInput.Text = tostring(blue*255)
					updateColor(2)
				end
			end
			blueInput.FocusLost:Connect(function() updateBlue(blueInput.Text) end) hookButtons(blueInput,updateBlue)

			local colorChoice = Instance.new("TextButton")
			colorChoice.Name = "Choice"
			colorChoice.Size = UDim2.new(0,25,0,18)
			colorChoice.BorderColor3 = Color3.fromRGB(55,55,55)
			colorChoice.Text = ""
			colorChoice.AutoButtonColor = false

			local row = 0
			local column = 0
			for i,v in pairs(basicColors) do
				local newColor = colorChoice:Clone()
				newColor.BackgroundColor3 = v
				newColor.Position = UDim2.new(0,1 + 30*column,0,21 + 23*row)

				newColor.MouseButton1Click:Connect(function()
					red,green,blue = v.r,v.g,v.b
					local newColor = Color3.new(red,green,blue)
					hue,sat,val = Color3.toHSV(newColor)
					updateColor()
				end)

				newColor.Parent = basicColorsFrame
				column = column + 1
				if column == 6 then row = row + 1 column = 0 end
			end

			row = 0
			column = 0
			for i = 1,12 do
				local color = customColors[i] or Color3.new(0,0,0)
				local newColor = colorChoice:Clone()
				newColor.BackgroundColor3 = color
				newColor.Position = UDim2.new(0,1 + 30*column,0,20 + 23*row)

				newColor.MouseButton1Click:Connect(function()
					local curColor = customColors[i] or Color3.new(0,0,0)
					red,green,blue = curColor.r,curColor.g,curColor.b
					hue,sat,val = Color3.toHSV(curColor)
					updateColor()
				end)

				newColor.MouseButton2Click:Connect(function()
					customColors[i] = chosenColor
					newColor.BackgroundColor3 = chosenColor
				end)

				newColor.Parent = customColorsFrame
				column = column + 1
				if column == 6 then row = row + 1 column = 0 end
			end

			okButton.MouseButton1Click:Connect(function() newMt.OnSelect:Fire(chosenColor) window:Close() end)
			okButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then okButton.BackgroundTransparency = 0.4 end end)
			okButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then okButton.BackgroundTransparency = 0 end end)


			cancelButton.MouseButton1Click:Connect(function() newMt.OnCancel:Fire() window:Close() end)
			cancelButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then cancelButton.BackgroundTransparency = 0.4 end end)
			cancelButton.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then cancelButton.BackgroundTransparency = 0 end end)

			updateColor()

			newMt.SetColor = function(self,color)
				red,green,blue = color.r,color.g,color.b
				hue,sat,val = Color3.toHSV(color)
				updateColor()
			end

			newMt.Show = function(self)
				self.Window:Show()
			end

			return newMt
		end

		return {new = new}
	end)()

			Lib.NumberSequenceEditor = (function()
				local function new() -- TODO: Convert to newer class model
					local newMt = setmetatable({},{})
					newMt.OnSelect = Lib.Signal.new()
					newMt.OnCancel = Lib.Signal.new()
					newMt.OnPreview = Lib.Signal.new()

					local guiContents = create({
						{1,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Content",Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),}},
						{2,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Time",Parent={1},Position=UDim2.new(0,40,0,210),Size=UDim2.new(0,60,0,20),}},
						{3,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={2},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,58,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
						{4,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={2},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Time",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
						{5,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Close",Parent={1},Position=UDim2.new(1,-90,0,210),Size=UDim2.new(0,80,0,20),Text="Close",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
						{6,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Reset",Parent={1},Position=UDim2.new(1,-180,0,210),Size=UDim2.new(0,80,0,20),Text="Reset",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
						{7,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Font=3,Name="Delete",Parent={1},Position=UDim2.new(0,380,0,210),Size=UDim2.new(0,80,0,20),Text="Delete",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
						{8,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="NumberLineOutlines",Parent={1},Position=UDim2.new(0,10,0,20),Size=UDim2.new(1,-20,0,170),}},
						{9,"Frame",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),Name="NumberLine",Parent={1},Position=UDim2.new(0,10,0,20),Size=UDim2.new(1,-20,0,170),}},
						{10,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Value",Parent={1},Position=UDim2.new(0,170,0,210),Size=UDim2.new(0,60,0,20),}},
						{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={10},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Value",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
						{12,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={10},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,58,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
						{13,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Envelope",Parent={1},Position=UDim2.new(0,300,0,210),Size=UDim2.new(0,60,0,20),}},
						{14,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={13},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,58,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
						{15,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={13},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Envelope",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
					})
					local window = Lib.Window.new()
					window.Resizable = false
					window:Resize(680,265)
					window:SetTitle("NumberSequence Editor")
					newMt.Window = window
					newMt.Gui = window.Gui
					for i,v in pairs(guiContents:GetChildren()) do
						v.Parent = window.GuiElems.Content
					end
					local gui = window.Gui
					local pickerGui = gui.Main
					local pickerTopBar = pickerGui.TopBar
					local pickerFrame = pickerGui.Content
					local numberLine = pickerFrame.NumberLine
					local numberLineOutlines = pickerFrame.NumberLineOutlines
					local timeBox = pickerFrame.Time.Input
					local valueBox = pickerFrame.Value.Input
					local envelopeBox = pickerFrame.Envelope.Input
					local deleteButton = pickerFrame.Delete
					local resetButton = pickerFrame.Reset
					local closeButton = pickerFrame.Close
					local topClose = pickerTopBar.Close

					local points = {{1,0,3},{8,0.05,1},{5,0.6,2},{4,0.7,4},{6,1,4}}
					local lines = {}
					local eLines = {}
					local beginPoint = points[1]
					local endPoint = points[#points]
					local currentlySelected = nil
					local currentPoint = nil
					local resetSequence = nil

					local user = service.UserInputService
					local mouse = service.Players.LocalPlayer:GetMouse()

					for i = 2,10 do
						local newLine = Instance.new("Frame")
						newLine.BackgroundTransparency = 0.5
						newLine.BackgroundColor3 = Color3.new(96/255,96/255,96/255)
						newLine.BorderSizePixel = 0
						newLine.Size = UDim2.new(0,1,1,0)
						newLine.Position = UDim2.new((i-1)/(11-1),0,0,0)
						newLine.Parent = numberLineOutlines
					end

					for i = 2,4 do
						local newLine = Instance.new("Frame")
						newLine.BackgroundTransparency = 0.5
						newLine.BackgroundColor3 = Color3.new(96/255,96/255,96/255)
						newLine.BorderSizePixel = 0
						newLine.Size = UDim2.new(1,0,0,1)
						newLine.Position = UDim2.new(0,0,(i-1)/(5-1),0)
						newLine.Parent = numberLineOutlines
					end

					local lineTemp = Instance.new("Frame")
					lineTemp.BackgroundColor3 = Color3.new(0,0,0)
					lineTemp.BorderSizePixel = 0
					lineTemp.Size = UDim2.new(0,1,0,1)

					local sequenceLine = Instance.new("Frame")
					sequenceLine.BackgroundColor3 = Color3.new(0,0,0)
					sequenceLine.BorderSizePixel = 0
					sequenceLine.Size = UDim2.new(0,1,0,0)

					for i = 1,numberLine.AbsoluteSize.X do
						local line = sequenceLine:Clone()
						eLines[i] = line
						line.Name = "E"..tostring(i)
						line.BackgroundTransparency = 0.5
						line.BackgroundColor3 = Color3.new(199/255,44/255,28/255)
						line.Position = UDim2.new(0,i-1,0,0)
						line.Parent = numberLine
					end

					for i = 1,numberLine.AbsoluteSize.X do
						local line = sequenceLine:Clone()
						lines[i] = line
						line.Name = tostring(i)
						line.Position = UDim2.new(0,i-1,0,0)
						line.Parent = numberLine
					end

					local envelopeDrag = Instance.new("Frame")
					envelopeDrag.BackgroundTransparency = 1
					envelopeDrag.BackgroundColor3 = Color3.new(0,0,0)
					envelopeDrag.BorderSizePixel = 0
					envelopeDrag.Size = UDim2.new(0,7,0,20)
					envelopeDrag.Visible = false
					envelopeDrag.ZIndex = 2
					local envelopeDragLine = Instance.new("Frame",envelopeDrag)
					envelopeDragLine.Name = "Line"
					envelopeDragLine.BackgroundColor3 = Color3.new(0,0,0)
					envelopeDragLine.BorderSizePixel = 0
					envelopeDragLine.Position = UDim2.new(0,3,0,0)
					envelopeDragLine.Size = UDim2.new(0,1,0,20)
					envelopeDragLine.ZIndex = 2

					local envelopeDragTop,envelopeDragBottom = envelopeDrag:Clone(),envelopeDrag:Clone()
					envelopeDragTop.Parent = numberLine
					envelopeDragBottom.Parent = numberLine

					local function buildSequence()
						local newPoints = {}
						for i,v in pairs(points) do
							table.insert(newPoints,NumberSequenceKeypoint.new(v[2],v[1],v[3]))
						end
						newMt.Sequence = NumberSequence.new(newPoints)
						newMt.OnSelect:Fire(newMt.Sequence)
					end

					local function round(num,places)
						local multi = 10^places
						return math.floor(num*multi + 0.5)/multi
					end

					local function updateInputs(point)
						if point then
							currentPoint = point
							local rawT,rawV,rawE = point[2],point[1],point[3]
							timeBox.Text = round(rawT,(rawT < 0.01 and 5) or (rawT < 0.1 and 4) or 3)
							valueBox.Text = round(rawV,(rawV < 0.01 and 5) or (rawV < 0.1 and 4) or (rawV < 1 and 3) or 2)
							envelopeBox.Text = round(rawE,(rawE < 0.01 and 5) or (rawE < 0.1 and 4) or (rawV < 1 and 3) or 2)

							local envelopeDistance = numberLine.AbsoluteSize.Y*(point[3]/10)
							envelopeDragTop.Position = UDim2.new(0,point[4].Position.X.Offset-1,0,point[4].Position.Y.Offset-envelopeDistance-17)
							envelopeDragTop.Visible = true
							envelopeDragBottom.Position = UDim2.new(0,point[4].Position.X.Offset-1,0,point[4].Position.Y.Offset+envelopeDistance+2)
							envelopeDragBottom.Visible = true
						end
					end

					envelopeDragTop.InputBegan:Connect(function(input)
						if (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) or not currentPoint or Lib.CheckMouseInGui(currentPoint[4].Select) then return end

						local mouseEvent, releaseEvent
						local maxSize = numberLine.AbsoluteSize.Y
						local mouseDelta = math.abs(envelopeDragTop.AbsolutePosition.Y - mouse.Y)

						envelopeDragTop.Line.Position = UDim2.new(0, 2, 0, 0)
						envelopeDragTop.Line.Size = UDim2.new(0, 3, 0, 20)

						releaseEvent = user.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
							mouseEvent:Disconnect()
							releaseEvent:Disconnect()
							envelopeDragTop.Line.Position = UDim2.new(0, 3, 0, 0)
							envelopeDragTop.Line.Size = UDim2.new(0, 1, 0, 20)
						end)

						mouseEvent = user.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								local topDiff = (currentPoint[4].AbsolutePosition.Y + 2) - (mouse.Y - mouseDelta) - 19
								local newEnvelope = 10 * (math.max(topDiff, 0) / maxSize)
								local maxEnvelope = math.min(currentPoint[1], 10 - currentPoint[1])
								currentPoint[3] = math.min(newEnvelope, maxEnvelope)
								newMt:Redraw()
								buildSequence()
								updateInputs(currentPoint)
							end
						end)
					end)

					envelopeDragBottom.InputBegan:Connect(function(input)
						if (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) or not currentPoint or Lib.CheckMouseInGui(currentPoint[4].Select) then return end

						local mouseEvent, releaseEvent
						local maxSize = numberLine.AbsoluteSize.Y
						local mouseDelta = math.abs(envelopeDragBottom.AbsolutePosition.Y - mouse.Y)

						envelopeDragBottom.Line.Position = UDim2.new(0, 2, 0, 0)
						envelopeDragBottom.Line.Size = UDim2.new(0, 3, 0, 20)

						releaseEvent = user.InputEnded:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
							mouseEvent:Disconnect()
							releaseEvent:Disconnect()
							envelopeDragBottom.Line.Position = UDim2.new(0, 3, 0, 0)
							envelopeDragBottom.Line.Size = UDim2.new(0, 1, 0, 20)
						end)

						mouseEvent = user.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								local bottomDiff = (mouse.Y + (20 - mouseDelta)) - (currentPoint[4].AbsolutePosition.Y + 2) - 19
								local newEnvelope = 10 * (math.max(bottomDiff, 0) / maxSize)
								local maxEnvelope = math.min(currentPoint[1], 10 - currentPoint[1])
								currentPoint[3] = math.min(newEnvelope, maxEnvelope)
								newMt:Redraw()
								buildSequence()
								updateInputs(currentPoint)
							end
						end)
					end)

					local function placePoint(point)
						local newPoint = Instance.new("Frame")
						newPoint.Name = "Point"
						newPoint.BorderSizePixel = 0
						newPoint.Size = UDim2.new(0,5,0,5)
						newPoint.Position = UDim2.new(0,math.floor((numberLine.AbsoluteSize.X-1) * point[2])-2,0,numberLine.AbsoluteSize.Y*(10-point[1])/10-2)
						newPoint.BackgroundColor3 = Color3.new(0,0,0)

						local newSelect = Instance.new("Frame")
						newSelect.Name = "Select"
						newSelect.BackgroundTransparency = 1
						newSelect.BackgroundColor3 = Color3.new(199/255,44/255,28/255)
						newSelect.Position = UDim2.new(0,-2,0,-2)
						newSelect.Size = UDim2.new(0,9,0,9)
						newSelect.Parent = newPoint

						newPoint.Parent = numberLine


						newSelect.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								for i, v in pairs(points) do 
									v[4].Select.BackgroundTransparency = 1 
								end

								newSelect.BackgroundTransparency = 0
								updateInputs(point)
							end

							if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not currentlySelected then
								currentPoint = point
								local mouseEvent, releaseEvent
								currentlySelected = true
								newSelect.BackgroundColor3 = Color3.new(249/255, 191/255, 59/255)

								local oldEnvelope = point[3]

								releaseEvent = user.InputEnded:Connect(function(input)
									if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then	return end

									mouseEvent:Disconnect()
									releaseEvent:Disconnect()
									currentlySelected = nil
									newSelect.BackgroundColor3 = Color3.new(199/255, 44/255, 28/255)
								end)

								mouseEvent = user.InputChanged:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
										local maxX = numberLine.AbsoluteSize.X - 1
										local relativeX = (input.Position.X - numberLine.AbsolutePosition.X)
										if relativeX < 0 then relativeX = 0 end
										if relativeX > maxX then relativeX = maxX end

										local maxY = numberLine.AbsoluteSize.Y - 1
										local relativeY = (input.Position.Y - numberLine.AbsolutePosition.Y)
										if relativeY < 0 then relativeY = 0 end
										if relativeY > maxY then relativeY = maxY end

										if point ~= beginPoint and point ~= endPoint then
											point[2] = relativeX / maxX
										end

										point[1] = 10 - (relativeY / maxY) * 10
										local maxEnvelope = math.min(point[1], 10 - point[1])
										point[3] = math.min(oldEnvelope, maxEnvelope)
										newMt:Redraw()
										updateInputs(point)

										for i, v in pairs(points) do 
											v[4].Select.BackgroundTransparency = 1 
										end

										newSelect.BackgroundTransparency = 0
										buildSequence()
									end
								end)
							end
						end)

						return newPoint
					end

					local function placePoints()
						for i,v in pairs(points) do
							v[4] = placePoint(v)
						end
					end

					local function redraw(self)
						local numberLineSize = numberLine.AbsoluteSize
						table.sort(points,function(a,b) return a[2] < b[2] end)
						for i,v in pairs(points) do
							v[4].Position = UDim2.new(0,math.floor((numberLineSize.X-1) * v[2])-2,0,(numberLineSize.Y-1)*(10-v[1])/10-2)
						end
						lines[1].Size = UDim2.new(0,1,0,0)
						for i = 1,#points-1 do
							local fromPoint = points[i]
							local toPoint = points[i+1]
							local deltaY = toPoint[4].Position.Y.Offset-fromPoint[4].Position.Y.Offset
							local deltaX = toPoint[4].Position.X.Offset-fromPoint[4].Position.X.Offset
							local slope = deltaY/deltaX

							local fromEnvelope = fromPoint[3]
							local nextEnvelope = toPoint[3]

							local currentRise = math.abs(slope)
							local totalRise = 0
							local maxRise = math.abs(toPoint[4].Position.Y.Offset-fromPoint[4].Position.Y.Offset)

							for lineCount = math.min(fromPoint[4].Position.X.Offset+1,toPoint[4].Position.X.Offset),toPoint[4].Position.X.Offset do
								if deltaX == 0 and deltaY == 0 then return end
								local riseNow = math.floor(currentRise)
								local line = lines[lineCount+3]
								if line then
									if totalRise+riseNow > maxRise then riseNow = maxRise-totalRise end
									if math.sign(slope) == -1 then
										line.Position = UDim2.new(0,lineCount+2,0,fromPoint[4].Position.Y.Offset + -(totalRise+riseNow)+2)
									else
										line.Position = UDim2.new(0,lineCount+2,0,fromPoint[4].Position.Y.Offset + totalRise+2)
									end
									line.Size = UDim2.new(0,1,0,math.max(riseNow,1))
								end
								totalRise = totalRise + riseNow
								currentRise = currentRise - riseNow + math.abs(slope)

								local envPercent = (lineCount-fromPoint[4].Position.X.Offset)/(toPoint[4].Position.X.Offset-fromPoint[4].Position.X.Offset)
								local envLerp = fromEnvelope+(nextEnvelope-fromEnvelope)*envPercent
								local relativeSize = (envLerp/10)*numberLineSize.Y						

								local line = eLines[lineCount + 3]
								if line then
									line.Position = UDim2.new(0,lineCount+2,0,lines[lineCount+3].Position.Y.Offset-math.floor(relativeSize))
									line.Size = UDim2.new(0,1,0,math.floor(relativeSize*2))
								end
							end
						end
					end
					newMt.Redraw = redraw



					local function loadSequence(self,seq)
						resetSequence = seq
						for i,v in pairs(points) do if v[4] then v[4]:Destroy() end end
						points = {}
						for i,v in pairs(seq.Keypoints) do
							local maxEnvelope = math.min(v.Value,10-v.Value)
							local newPoint = {v.Value,v.Time,math.min(v.Envelope,maxEnvelope)}
							newPoint[4] = placePoint(newPoint)
							table.insert(points,newPoint)
						end
						beginPoint = points[1]
						endPoint = points[#points]
						currentlySelected = nil
						redraw()
						envelopeDragTop.Visible = false
						envelopeDragBottom.Visible = false
					end
					newMt.SetSequence = loadSequence

					timeBox.FocusLost:Connect(function()
						local point = currentPoint
						local num = tonumber(timeBox.Text)
						if point and num and point ~= beginPoint and point ~= endPoint then
							num = math.clamp(num,0,1)
							point[2] = num
							redraw()
							buildSequence()
							updateInputs(point)
						end
					end)

					valueBox.FocusLost:Connect(function()
						local point = currentPoint
						local num = tonumber(valueBox.Text)
						if point and num then
							local oldEnvelope = point[3]
							num = math.clamp(num,0,10)
							point[1] = num
							local maxEnvelope = math.min(point[1],10-point[1])
							point[3] = math.min(oldEnvelope,maxEnvelope)
							redraw()
							buildSequence()
							updateInputs(point)
						end
					end)

					envelopeBox.FocusLost:Connect(function()
						local point = currentPoint
						local num = tonumber(envelopeBox.Text)
						if point and num then
							num = math.clamp(num,0,5)
							local maxEnvelope = math.min(point[1],10-point[1])
							point[3] = math.min(num,maxEnvelope)
							redraw()
							buildSequence()
							updateInputs(point)
						end
					end)

					local function buttonAnimations(button,inverse)
						button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 0.5 or 0.4) end end)
						button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 1 or 0) end end)
					end

					numberLine.InputBegan:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and #points < 20 then

							if Lib.CheckMouseInGui(envelopeDragTop) or Lib.CheckMouseInGui(envelopeDragBottom) then return end

							for i, v in pairs(points) do
								if Lib.CheckMouseInGui(v[4].Select) then
									return
								end
							end

							local maxX = numberLine.AbsoluteSize.X - 1
							local relativeX = (input.Position.X - numberLine.AbsolutePosition.X)
							if relativeX < 0 then relativeX = 0 end
							if relativeX > maxX then relativeX = maxX end

							local maxY = numberLine.AbsoluteSize.Y - 1
							local relativeY = (input.Position.Y - numberLine.AbsolutePosition.Y)
							if relativeY < 0 then relativeY = 0 end
							if relativeY > maxY then relativeY = maxY end

							local raw = relativeX / maxX
							local newPoint = {10 - (relativeY / maxY) * 10, raw, 0}
							newPoint[4] = placePoint(newPoint)
							table.insert(points, newPoint)
							redraw()
							buildSequence()
						end
					end)

					deleteButton.MouseButton1Click:Connect(function()
						if currentPoint and currentPoint ~= beginPoint and currentPoint ~= endPoint then
							for i,v in pairs(points) do
								if v == currentPoint then
									v[4]:Destroy()
									table.remove(points,i)
									break
								end
							end
							currentlySelected = nil
							redraw()
							buildSequence()
							updateInputs(points[1])
						end
					end)

					resetButton.MouseButton1Click:Connect(function()
						if resetSequence then
							newMt:SetSequence(resetSequence)
							buildSequence()
						end
					end)

					closeButton.MouseButton1Click:Connect(function()
						window:Close()
					end)

					buttonAnimations(deleteButton)
					buttonAnimations(resetButton)
					buttonAnimations(closeButton)

					placePoints()
					redraw()

					newMt.Show = function(self)
						window:Show()
					end

					return newMt
				end

				return {new = new}
			end)()

			Lib.ColorSequenceEditor = (function() -- TODO: Convert to newer class model
				local function new()
					local newMt = setmetatable({},{})
					newMt.OnSelect = Lib.Signal.new()
					newMt.OnCancel = Lib.Signal.new()
					newMt.OnPreview = Lib.Signal.new()
					newMt.OnPickColor = Lib.Signal.new()

					local guiContents = create({
						{1,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Content",Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),}},
						{2,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="ColorLine",Parent={1},Position=UDim2.new(0,10,0,5),Size=UDim2.new(1,-20,0,70),}},
						{3,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Name="Gradient",Parent={2},Size=UDim2.new(1,0,1,0),}},
						{4,"UIGradient",{Parent={3},}},
						{5,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Name="Arrows",Parent={1},Position=UDim2.new(0,1,0,73),Size=UDim2.new(1,-2,0,16),}},
						{6,"Frame",{BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,Name="Cursor",Parent={1},Position=UDim2.new(0,10,0,0),Size=UDim2.new(0,1,0,80),}},
						{7,"Frame",{BackgroundColor3=Color3.new(0.14901961386204,0.14901961386204,0.14901961386204),BorderColor3=Color3.new(0.12549020349979,0.12549020349979,0.12549020349979),Name="Time",Parent={1},Position=UDim2.new(0,40,0,95),Size=UDim2.new(0,100,0,20),}},
						{8,"TextBox",{BackgroundColor3=Color3.new(0.25098040699959,0.25098040699959,0.25098040699959),BackgroundTransparency=1,BorderColor3=Color3.new(0.37647062540054,0.37647062540054,0.37647062540054),ClipsDescendants=true,Font=3,Name="Input",Parent={7},Position=UDim2.new(0,2,0,0),Size=UDim2.new(0,98,0,20),Text="0",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=0,}},
						{9,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={7},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Time",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
						{10,"Frame",{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),Name="ColorBox",Parent={1},Position=UDim2.new(0,220,0,95),Size=UDim2.new(0,20,0,20),}},
						{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Title",Parent={10},Position=UDim2.new(0,-40,0,0),Size=UDim2.new(0,34,1,0),Text="Color",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,TextXAlignment=1,}},
						{12,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="Close",Parent={1},Position=UDim2.new(1,-90,0,95),Size=UDim2.new(0,80,0,20),Text="Close",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
						{13,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="Reset",Parent={1},Position=UDim2.new(1,-180,0,95),Size=UDim2.new(0,80,0,20),Text="Reset",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
						{14,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderColor3=Color3.new(0.21568627655506,0.21568627655506,0.21568627655506),BorderSizePixel=0,Font=3,Name="Delete",Parent={1},Position=UDim2.new(0,280,0,95),Size=UDim2.new(0,80,0,20),Text="Delete",TextColor3=Color3.new(0.86274516582489,0.86274516582489,0.86274516582489),TextSize=14,}},
						{15,"Frame",{BackgroundTransparency=1,Name="Arrow",Parent={1},Size=UDim2.new(0,16,0,16),Visible=false,}},
						{16,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,8,0,3),Size=UDim2.new(0,1,0,2),}},
						{17,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,7,0,5),Size=UDim2.new(0,3,0,2),}},
						{18,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,6,0,7),Size=UDim2.new(0,5,0,2),}},
						{19,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,5,0,9),Size=UDim2.new(0,7,0,2),}},
						{20,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={15},Position=UDim2.new(0,4,0,11),Size=UDim2.new(0,9,0,2),}},
					})
					local window = Lib.Window.new()
					window.Resizable = false
					window:Resize(650,150)
					window:SetTitle("ColorSequence Editor")
					newMt.Window = window
					newMt.Gui = window.Gui
					for i,v in pairs(guiContents:GetChildren()) do
						v.Parent = window.GuiElems.Content
					end
					local gui = window.Gui
					local pickerGui = gui.Main
					local pickerTopBar = pickerGui.TopBar
					local pickerFrame = pickerGui.Content
					local colorLine = pickerFrame.ColorLine
					local gradient = colorLine.Gradient.UIGradient
					local arrowFrame = pickerFrame.Arrows
					local arrow = pickerFrame.Arrow
					local cursor = pickerFrame.Cursor
					local timeBox = pickerFrame.Time.Input
					local colorBox = pickerFrame.ColorBox
					local deleteButton = pickerFrame.Delete
					local resetButton = pickerFrame.Reset
					local closeButton = pickerFrame.Close
					local topClose = pickerTopBar.Close

					local user = service.UserInputService
					local mouse = service.Players.LocalPlayer:GetMouse()

					local colors = {{Color3.new(1,0,1),0},{Color3.new(0.2,0.9,0.2),0.2},{Color3.new(0.4,0.5,0.9),0.7},{Color3.new(0.6,1,1),1}}
					local resetSequence = nil

					local beginPoint = colors[1]
					local endPoint = colors[#colors]

					local currentlySelected = nil
					local currentPoint = nil

					local sequenceLine = Instance.new("Frame")
					sequenceLine.BorderSizePixel = 0
					sequenceLine.Size = UDim2.new(0,1,1,0)

					newMt.Sequence = ColorSequence.new(Color3.new(1,1,1))
					local function buildSequence(noupdate)
						local newPoints = {}
						table.sort(colors,function(a,b) return a[2] < b[2] end)
						for i,v in pairs(colors) do
							table.insert(newPoints,ColorSequenceKeypoint.new(v[2],v[1]))
						end
						newMt.Sequence = ColorSequence.new(newPoints)
						if not noupdate then newMt.OnSelect:Fire(newMt.Sequence) end
					end

					local function round(num,places)
						local multi = 10^places
						return math.floor(num*multi + 0.5)/multi
					end

					local function updateInputs(point)
						if point then
							currentPoint = point
							local raw = point[2]
							timeBox.Text = round(raw,(raw < 0.01 and 5) or (raw < 0.1 and 4) or 3)
							colorBox.BackgroundColor3 = point[1]
						end
					end

					local function placeArrow(ind,point)
						local newArrow = arrow:Clone()
						newArrow.Position = UDim2.new(0,ind-1,0,0)
						newArrow.Visible = true
						newArrow.Parent = arrowFrame

						newArrow.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								cursor.Visible = true
								cursor.Position = UDim2.new(0, 9 + newArrow.Position.X.Offset, 0, 0)
							end

							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								updateInputs(point)
								if point == beginPoint or point == endPoint or currentlySelected then return end

								local mouseEvent, releaseEvent
								currentlySelected = true

								releaseEvent = user.InputEnded:Connect(function(input)
									if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
									mouseEvent:Disconnect()
									releaseEvent:Disconnect()
									currentlySelected = nil
									cursor.Visible = false
								end)

								mouseEvent = user.InputChanged:Connect(function(input)
									if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
										local maxSize = colorLine.AbsoluteSize.X - 1
										local relativeX = (input.Position.X - colorLine.AbsolutePosition.X)
										if relativeX < 0 then relativeX = 0 end
										if relativeX > maxSize then relativeX = maxSize end
										local raw = relativeX / maxSize
										point[2] = relativeX / maxSize
										updateInputs(point)
										cursor.Visible = true
										cursor.Position = UDim2.new(0, 9 + newArrow.Position.X.Offset, 0, 0)
										buildSequence()
										newMt:Redraw()
									end
								end)
							end
						end)

						newArrow.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
								cursor.Visible = false
							end
						end)



						return newArrow
					end

					local function placeArrows()
						for i,v in pairs(colors) do
							v[3] = placeArrow(math.floor((colorLine.AbsoluteSize.X-1) * v[2]) + 1,v)
						end
					end

					local function redraw(self)
						gradient.Color = newMt.Sequence or ColorSequence.new(Color3.new(1,1,1))

						for i = 2,#colors do
							local nextColor = colors[i]
							local endPos = math.floor((colorLine.AbsoluteSize.X-1) * nextColor[2]) + 1
							nextColor[3].Position = UDim2.new(0,endPos,0,0)
						end		
					end
					newMt.Redraw = redraw

					local function loadSequence(self,seq)
						resetSequence = seq
						for i,v in pairs(colors) do if v[3] then v[3]:Destroy() end end
						colors = {}
						currentlySelected = nil
						for i,v in pairs(seq.Keypoints) do
							local newPoint = {v.Value,v.Time}
							newPoint[3] = placeArrow(v.Time,newPoint)
							table.insert(colors,newPoint)
						end
						beginPoint = colors[1]
						endPoint = colors[#colors]
						currentlySelected = nil
						updateInputs(colors[1])
						buildSequence(true)
						redraw()
					end
					newMt.SetSequence = loadSequence

					local function buttonAnimations(button,inverse)
						button.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 0.5 or 0.4) end end)
						button.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then button.BackgroundTransparency = (inverse and 1 or 0) end end)
					end

					colorLine.InputBegan:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and #colors < 20 then
							local maxSize = colorLine.AbsoluteSize.X - 1
							local relativeX = (input.Position.X - colorLine.AbsolutePosition.X)
							if relativeX < 0 then relativeX = 0 end
							if relativeX > maxSize then relativeX = maxSize end

							local raw = relativeX / maxSize
							local fromColor = nil
							local toColor = nil
							for i, col in pairs(colors) do
								if col[2] >= raw then
									fromColor = colors[math.max(i - 1, 1)]
									toColor = colors[i]
									break
								end
							end
							local lerpColor = fromColor[1]:lerp(toColor[1], (raw - fromColor[2]) / (toColor[2] - fromColor[2]))
							local newPoint = {lerpColor, raw}
							newPoint[3] = placeArrow(newPoint[2], newPoint)
							table.insert(colors, newPoint)
							updateInputs(newPoint)
							buildSequence()
							redraw()
						end
					end)

					colorLine.InputChanged:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							local maxSize = colorLine.AbsoluteSize.X - 1
							local relativeX = (input.Position.X - colorLine.AbsolutePosition.X)
							if relativeX < 0 then relativeX = 0 end
							if relativeX > maxSize then relativeX = maxSize end
							cursor.Visible = true
							cursor.Position = UDim2.new(0, 10 + relativeX, 0, 0)
						end
					end)

					colorLine.InputEnded:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							local inArrow = false
							for i, v in pairs(colors) do
								if Lib.CheckMouseInGui(v[3]) then
									inArrow = v[3]
								end
							end
							cursor.Visible = inArrow and true or false
							if inArrow then cursor.Position = UDim2.new(0, 9 + inArrow.Position.X.Offset, 0, 0) end
						end
					end)

					timeBox:GetPropertyChangedSignal("Text"):Connect(function()
						local point = currentPoint
						local num = tonumber(timeBox.Text)
						if point and num and point ~= beginPoint and point ~= endPoint then
							num = math.clamp(num,0,1)
							point[2] = num
							buildSequence()
							redraw()
						end
					end)

					colorBox.InputBegan:Connect(function(input)
						if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
							local editor = newMt.ColorPicker
							if not editor then
								editor = Lib.ColorPicker.new()
								editor.Window:SetTitle("ColorSequence Color Picker")

								editor.OnSelect:Connect(function(col)
									if currentPoint then
										currentPoint[1] = col
									end
									buildSequence()
									redraw()
								end)

								newMt.ColorPicker = editor
							end

							editor.Window:ShowAndFocus()
						end
					end)

					deleteButton.MouseButton1Click:Connect(function()
						if currentPoint and currentPoint ~= beginPoint and currentPoint ~= endPoint then
							for i,v in pairs(colors) do
								if v == currentPoint then
									v[3]:Destroy()
									table.remove(colors,i)
									break
								end
							end
							currentlySelected = nil
							updateInputs(colors[1])
							buildSequence()
							redraw()
						end
					end)

					resetButton.MouseButton1Click:Connect(function()
						if resetSequence then
							newMt:SetSequence(resetSequence)
						end
					end)

					closeButton.MouseButton1Click:Connect(function()
						window:Close()
					end)

					topClose.MouseButton1Click:Connect(function()
						window:Close()
					end)

					buttonAnimations(deleteButton)
					buttonAnimations(resetButton)
					buttonAnimations(closeButton)

					placeArrows()
					redraw()

					newMt.Show = function(self)
						window:Show()
					end

					return newMt
				end

				return {new = new}
			end)()

			Lib.ViewportTextBox = (function()
				local textService = service.TextService

				local props = {
					OffsetX = 0,
					TextBox = PH,
					CursorPos = -1,
					Gui = PH,
					View = PH
				}
				local funcs = {}
				funcs.Update = function(self)
					local cursorPos = self.CursorPos or -1
					local text = self.TextBox.Text
					if text == "" then self.TextBox.Position = UDim2.new(0,0,0,0) return end
					if cursorPos == -1 then return end

					local cursorText = text:sub(1,cursorPos-1)
					local pos = nil
					local leftEnd = -self.TextBox.Position.X.Offset
					local rightEnd = leftEnd + self.View.AbsoluteSize.X

					local totalTextSize = textService:GetTextSize(text,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X
					local cursorTextSize = textService:GetTextSize(cursorText,self.TextBox.TextSize,self.TextBox.Font,Vector2.new(999999999,100)).X

					if cursorTextSize > rightEnd then
						pos = math.max(-1,cursorTextSize - self.View.AbsoluteSize.X + 2)
					elseif cursorTextSize < leftEnd then
						pos = math.max(-1,cursorTextSize-2)
					elseif totalTextSize < rightEnd then
						pos = math.max(-1,totalTextSize - self.View.AbsoluteSize.X + 2)
					end

					if pos then
						self.TextBox.Position = UDim2.new(0,-pos,0,0)
						self.TextBox.Size = UDim2.new(1,pos,1,0)
					end
				end

				funcs.GetText = function(self)
					return self.TextBox.Text
				end

				funcs.SetText = function(self,text)
					self.TextBox.Text = text
				end

				local mt = getGuiMT(props,funcs)

				local function convert(textbox)
					local obj = initObj(props,mt)

					local view = Instance.new("Frame")
					view.BackgroundTransparency = textbox.BackgroundTransparency
					view.BackgroundColor3 = textbox.BackgroundColor3
					view.BorderSizePixel = textbox.BorderSizePixel
					view.BorderColor3 = textbox.BorderColor3
					view.Position = textbox.Position
					view.Size = textbox.Size
					view.ClipsDescendants = true
					view.Name = textbox.Name
					textbox.BackgroundTransparency = 1
					textbox.Position = UDim2.new(0,0,0,0)
					textbox.Size = UDim2.new(1,0,1,0)
					textbox.TextXAlignment = Enum.TextXAlignment.Left
					textbox.Name = "Input"

					obj.TextBox = textbox
					obj.View = view
					obj.Gui = view

					textbox.Changed:Connect(function(prop)
						if prop == "Text" or prop == "CursorPosition" or prop == "AbsoluteSize" then
							local cursorPos = obj.TextBox.CursorPosition
							if cursorPos ~= -1 then obj.CursorPos = cursorPos end
							obj:Update()
						end
					end)

					obj:Update()

					view.Parent = textbox.Parent
					textbox.Parent = view

					return obj
				end

				local function new()
					local textBox = Instance.new("TextBox")
					textBox.Size = UDim2.new(0,100,0,20)
					textBox.BackgroundColor3 = Settings.Theme.TextBox
					textBox.BorderColor3 = Settings.Theme.Outline3
					textBox.ClearTextOnFocus = false
					textBox.TextColor3 = Settings.Theme.Text
					textBox.Font = Enum.Font.SourceSans
					textBox.TextSize = 14
					textBox.Text = ""
					return convert(textBox)
				end

				return {new = new, convert = convert}
			end)()

			Lib.Label = (function()
				local props,funcs = {},{}

				local mt = getGuiMT(props,funcs)

				local function new()
					local label = Instance.new("TextLabel")
					label.BackgroundTransparency = 1
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.TextColor3 = Settings.Theme.Text
					label.TextTransparency = 0.1
					label.Size = UDim2.new(0,100,0,20)
					label.Font = Enum.Font.SourceSans
					label.TextSize = 14

					local obj = setmetatable({
						Gui = label
					},mt)
					return obj
				end

				return {new = new}
			end)()

			Lib.Frame = (function()
				local props,funcs = {},{}

				local mt = getGuiMT(props,funcs)

				local function new()
					local fr = Instance.new("Frame")
					fr.BackgroundColor3 = Settings.Theme.Main1
					fr.BorderColor3 = Settings.Theme.Outline1
					fr.Size = UDim2.new(0,50,0,50)

					local obj = setmetatable({
						Gui = fr
					},mt)
					return obj
				end

				return {new = new}
			end)()

			Lib.Button = (function()
				local props = {
					Gui = PH,
					Anim = PH,
					Disabled = false,
					OnClick = SIGNAL,
					OnDown = SIGNAL,
					OnUp = SIGNAL,
					AllowedButtons = {1}
				}
				local funcs = {}
				local tableFind = table.find

				funcs.Trigger = function(self,event,button)
					if not self.Disabled and tableFind(self.AllowedButtons,button) then
						self["On"..event]:Fire(button)
					end
				end

				funcs.SetDisabled = function(self,dis)
					self.Disabled = dis

					if dis then
						self.Anim:Disable()
						self.Gui.TextTransparency = 0.5
					else
						self.Anim.Enable()
						self.Gui.TextTransparency = 0
					end
				end

				local mt = getGuiMT(props,funcs)

				local function new()
					local b = Instance.new("TextButton")
					b.AutoButtonColor = false
					b.TextColor3 = Settings.Theme.Text
					b.TextTransparency = 0.1
					b.Size = UDim2.new(0,100,0,20)
					b.Font = Enum.Font.SourceSans
					b.TextSize = 14
					b.BackgroundColor3 = Settings.Theme.Button
					b.BorderColor3 = Settings.Theme.Outline2

					local obj = initObj(props,mt)
					obj.Gui = b
					obj.Anim = Lib.ButtonAnim(b,{Mode = 2, StartColor = Settings.Theme.Button, HoverColor = Settings.Theme.ButtonHover, PressColor = Settings.Theme.ButtonPress, OutlineColor = Settings.Theme.Outline2})

					b.MouseButton1Click:Connect(function() obj:Trigger("Click",1) end)
					b.MouseButton1Down:Connect(function() obj:Trigger("Down",1) end)
					b.MouseButton1Up:Connect(function() obj:Trigger("Up",1) end)

					b.MouseButton2Click:Connect(function() obj:Trigger("Click",2) end)
					b.MouseButton2Down:Connect(function() obj:Trigger("Down",2) end)
					b.MouseButton2Up:Connect(function() obj:Trigger("Up",2) end)

					return obj
				end

				return {new = new}
			end)()

			Lib.DropDown = (function()
				local props = {
					Gui = PH,
					Anim = PH,
					Context = PH,
					Selected = PH,
					Disabled = false,
					CanBeEmpty = true,
					Options = {},
					GuiElems = {},
					OnSelect = SIGNAL
				}
				local funcs = {}

				funcs.Update = function(self)
					local options = self.Options

					if #options > 0 then
						if not self.Selected then
							if not self.CanBeEmpty then
								self.Selected = options[1]
								self.GuiElems.Label.Text = options[1]
							else
								self.GuiElems.Label.Text = "- Select -"
							end
						else
							self.GuiElems.Label.Text = self.Selected
						end
					else
						self.GuiElems.Label.Text = "- Select -"
					end
				end

				funcs.ShowOptions = function(self)
					local context = self.Context

					context.Width = self.Gui.AbsoluteSize.X
					context.ReverseYOffset = self.Gui.AbsoluteSize.Y
					context:Show(self.Gui.AbsolutePosition.X, self.Gui.AbsolutePosition.Y + context.ReverseYOffset)
				end

				funcs.SetOptions = function(self,opts)
					self.Options = opts

					local context = self.Context
					local options = self.Options
					context:Clear()

					local onClick = function(option) self.Selected = option self.OnSelect:Fire(option) self:Update() end

					if self.CanBeEmpty then
						context:Add({Name = "- Select -", function() self.Selected = nil self.OnSelect:Fire(nil) self:Update() end})
					end

					for i = 1,#options do
						context:Add({Name = options[i], OnClick = onClick})
					end

					self:Update()
				end

				funcs.SetSelected = function(self,opt)
					self.Selected = type(opt) == "number" and self.Options[opt] or opt
					self:Update()
				end

				local mt = getGuiMT(props,funcs)

				local function new()
					local f = Instance.new("TextButton")
					f.AutoButtonColor = false
					f.Text = ""
					f.Size = UDim2.new(0,100,0,20)
					f.BackgroundColor3 = Settings.Theme.TextBox
					f.BorderColor3 = Settings.Theme.Outline3

					local label = Lib.Label.new()
					label.Position = UDim2.new(0,2,0,0)
					label.Size = UDim2.new(1,-22,1,0)
					label.TextTruncate = Enum.TextTruncate.AtEnd
					label.Parent = f
					local arrow = create({
						{1,"Frame",{BackgroundTransparency=1,Name="EnumArrow",Position=UDim2.new(1,-16,0,2),Size=UDim2.new(0,16,0,16),}},
						{2,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,8,0,9),Size=UDim2.new(0,1,0,1),}},
						{3,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,7,0,8),Size=UDim2.new(0,3,0,1),}},
						{4,"Frame",{BackgroundColor3=Color3.new(0.86274510622025,0.86274510622025,0.86274510622025),BorderSizePixel=0,Parent={1},Position=UDim2.new(0,6,0,7),Size=UDim2.new(0,5,0,1),}},
					})
					arrow.Parent = f

					local obj = initObj(props,mt)
					obj.Gui = f
					obj.Anim = Lib.ButtonAnim(f,{Mode = 2, StartColor = Settings.Theme.TextBox, LerpTo = Settings.Theme.Button, LerpDelta = 0.15})
					obj.Context = Lib.ContextMenu.new()
					obj.Context.Iconless = true
					obj.Context.MaxHeight = 200
					obj.Selected = nil
					obj.GuiElems = {Label = label}
					f.MouseButton1Down:Connect(function() obj:ShowOptions() end)
					obj:Update()
					return obj
				end

				return {new = new}
			end)()

			Lib.ClickSystem = (function()
				local props = {
					LastItem = PH,
					OnDown = SIGNAL,
					OnRelease = SIGNAL,
					AllowedButtons = {1},
					Combo = 0,
					MaxCombo = 2,
					ComboTime = 0.5,
					Items = {},
					ItemCons = {},
					ClickId = -1,
					LastButton = ""
				}
				local funcs = {}
				local tostring = tostring

				local disconnect = function(con)
					local pos = table.find(con.Signal.Connections,con)
					if pos then table.remove(con.Signal.Connections,pos) end
				end

				funcs.Trigger = function(self, item, button, X, Y)
					if table.find(self.AllowedButtons, button) then
						if self.LastButton ~= button or self.LastItem ~= item or self.Combo == self.MaxCombo or tick() - self.ClickId > self.ComboTime then
							self.Combo = 0
							self.LastButton = button
							self.LastItem = item
						end

						self.Combo = self.Combo + 1
						self.ClickId = tick()

						task.spawn(function()
							if self.InputDown then
								self.InputDown = false
							else
								self.InputDown = tick()

								local Connection = item.MouseButton1Up:Once(function()
									self.InputDown = false
								end)

								while self.InputDown and not Explorer.Dragging do
									if (tick() - self.InputDown) >= 0.4 then
										self.InputDown = false
										self["OnRelease"]:Fire(item, self.Combo, 2, Vector2.new(X, Y))
										break
									end;task.wait()
								end
							end
						end)

						local release
						release = service.UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType["MouseButton" .. button] then
								release:Disconnect()
								if Lib.CheckMouseInGui(item) and self.LastButton == button and self.LastItem == item then
									self.InputDown = false
									self["OnRelease"]:Fire(item,self.Combo,button)
								end
							end
						end)

						self["OnDown"]:Fire(item,self.Combo,button)
					end
				end

				funcs.Add = function(self,item)
					if table.find(self.Items,item) then return end

					local cons = {}
					cons[1] = item.MouseButton1Down:Connect(function(X, Y) self:Trigger(item, 1, X, Y) end)
					cons[2] = item.MouseButton2Down:Connect(function(X, Y) self:Trigger(item, 2, X, Y) end)

					self.ItemCons[item] = cons
					self.Items[#self.Items+1] = item
				end

				funcs.Remove = function(self,item)
					local ind = table.find(self.Items,item)
					if not ind then return end

					for i,v in pairs(self.ItemCons[item]) do
						v:Disconnect()
					end
					self.ItemCons[item] = nil
					table.remove(self.Items,ind)
				end

				local mt = {__index = funcs}

				local function new()
					local obj = initObj(props,mt)

					return obj
				end

				return {new = new}
			end)()

			return Lib
		end

		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,
	Console = function()
--[[
	Console Module
]]
		-- Common Locals
		local Main,Lib,Apps,Settings -- Main Containers
		local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
		local API,RMD,env,service,plr,create,createSimple -- Main Locals

		local function initDeps(data)
			Main = data.Main
			Lib = data.Lib
			Apps = data.Apps
			Settings = data.Settings

			API = data.API
			RMD = data.RMD
			env = data.env
			service = data.service
			plr = data.plr
			create = data.create
			createSimple = data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			ModelViewer = Apps.ModelViewer
			SettingsWindow = Apps.SettingsWindow
			Notebook = Apps.Notebook
		end

		local function main()
			local Console = {}

			local window,ConsoleFrame

			local OutputLimit = 500 -- Same as Roblox Console.


			-- Instances: 29 | Scripts: 1 | Modules: 1 | Tags: 0
			local G2L = {};

			-- StarterGui.ScreenGui
			window = Lib.Window.new()
			window:SetTitle("Console")
			window:Resize(500,400)
			Console.Window = window

			-- StarterGui.ScreenGui.Console
			ConsoleFrame = Instance.new("ImageButton", window.GuiElems.Content);
			ConsoleFrame["BorderSizePixel"] = 0;
			ConsoleFrame["AutoButtonColor"] = false;
			ConsoleFrame["BackgroundTransparency"] = 1;
			ConsoleFrame["BackgroundColor3"] = Color3.fromRGB(47, 47, 47);
			ConsoleFrame["Selectable"] = false;
			ConsoleFrame["Size"] = UDim2.new(1,0,1,0);
			ConsoleFrame["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			ConsoleFrame["Name"] = [[Console]];
			ConsoleFrame["Position"] = UDim2.new(0,0,0,0);


			-- StarterGui.ScreenGui.Console.CommandLine
			G2L["3"] = Lib.Frame.new().Gui--Instance.new("Frame", ConsoleFrame);
			G2L["3"].Parent = ConsoleFrame
			G2L["3"]["BorderSizePixel"] = 0;
			G2L["3"]["BackgroundColor3"] = Color3.fromRGB(37, 37, 37);
			G2L["3"]["AnchorPoint"] = Vector2.new(0.5, 1);
			G2L["3"]["ClipsDescendants"] = true;
			G2L["3"]["Size"] = UDim2.new(1, -8, 0, 22);
			G2L["3"]["Position"] = UDim2.new(0.5, 0, 1, -5);
			G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["3"]["Name"] = [[CommandLine]];


			-- StarterGui.ScreenGui.Console.CommandLine.UIStroke
			G2L["4"] = Instance.new("UIStroke", G2L["3"]);
			G2L["4"]["Transparency"] = 0.65;
			G2L["4"]["Thickness"] = 1.25;


			-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame
			G2L["5"] = Instance.new("ScrollingFrame", G2L["3"]);
			G2L["5"]["Active"] = true;
			G2L["5"]["ScrollingDirection"] = Enum.ScrollingDirection.X;
			G2L["5"]["BorderSizePixel"] = 0;
			G2L["5"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
			G2L["5"]["ElasticBehavior"] = Enum.ElasticBehavior.Never;
			G2L["5"]["TopImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]];
			G2L["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["5"]["HorizontalScrollBarInset"] = Enum.ScrollBarInset.Always;
			G2L["5"]["BottomImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]];
			G2L["5"]["AutomaticCanvasSize"] = Enum.AutomaticSize.X;
			G2L["5"]["Size"] = UDim2.new(1, 0, 1, 0);
			G2L["5"]["ScrollBarImageColor3"] = Color3.fromRGB(57, 57, 57);
			G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["5"]["ScrollBarThickness"] = 2;
			G2L["5"]["BackgroundTransparency"] = 1;

			-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.TextBox
			G2L["6"] = Instance.new("TextBox", G2L["5"]);
			G2L["6"]["CursorPosition"] = -1;
			G2L["6"]["TextXAlignment"] = Enum.TextXAlignment.Left;
			G2L["6"]["PlaceholderColor3"] = Color3.fromRGB(211, 211, 211);
			G2L["6"]["BorderSizePixel"] = 0;
			G2L["6"]["TextSize"] = 13;
			G2L["6"]["TextColor3"] = Color3.fromRGB(211, 211, 211);
			G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["6"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["6"]["AutomaticSize"] = Enum.AutomaticSize.X;
			G2L["6"]["ClearTextOnFocus"] = false;
			G2L["6"]["PlaceholderText"] = [[Run a command]];
			G2L["6"]["Size"] = UDim2.new(0, 246, 0, 22);
			G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["6"]["Text"] = [[]];
			G2L["6"]["BackgroundTransparency"] = 1;


			-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.TextBox.UIPadding
			G2L["7"] = Instance.new("UIPadding", G2L["6"]);
			G2L["7"]["PaddingLeft"] = UDim.new(0, 7);


			-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.Highlight
			G2L["8"] = Instance.new("TextLabel", G2L["5"]);
			G2L["8"]["Interactable"] = false;
			G2L["8"]["ZIndex"] = 2;
			G2L["8"]["BorderSizePixel"] = 0;
			G2L["8"]["TextSize"] = 13;
			G2L["8"]["TextXAlignment"] = Enum.TextXAlignment.Left;
			G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["8"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["8"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["8"]["BackgroundTransparency"] = 1;
			G2L["8"]["RichText"] = true;
			G2L["8"]["Size"] = UDim2.new(0, 246, 0, 22);
			G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["8"]["Text"] = [[]];
			G2L["8"]["Selectable"] = true;
			G2L["8"]["AutomaticSize"] = Enum.AutomaticSize.X;
			G2L["8"]["Name"] = [[Highlight]];


			-- StarterGui.ScreenGui.Console.CommandLine.ScrollingFrame.Highlight.UIPadding
			G2L["9"] = Instance.new("UIPadding", G2L["8"]);
			G2L["9"]["PaddingLeft"] = UDim.new(0, 7);

			G2L["backgroundOutput"] = Instance.new("Frame", ConsoleFrame);
			G2L["backgroundOutput"]["BorderSizePixel"] = 0;
			G2L["backgroundOutput"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36);
			G2L["backgroundOutput"]["Name"] = [[BackgroundOutput]];
			G2L["backgroundOutput"]["AnchorPoint"] = Vector2.new(0, 0);
			G2L["backgroundOutput"]["Size"] = UDim2.new(1, -8, 1, -55);
			G2L["backgroundOutput"]["Position"] = UDim2.new(0, 4, 0, 23);
			G2L["backgroundOutput"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["backgroundOutput"]["ZIndex"] = 1;

			local scrollbar = Lib.ScrollBar.new()
			scrollbar.Gui.Parent = ConsoleFrame
			scrollbar.Gui.Size = UDim2.new(0, 16, 1, -55);
			scrollbar.Gui.Position = UDim2.new(1, -20,0, 23);
			scrollbar.Gui.Up.ZIndex = 3
			scrollbar.Gui.Down.ZIndex = 3

			-- StarterGui.ScreenGui.Console.Output
			G2L["a"] = Instance.new("ScrollingFrame", ConsoleFrame);
			G2L["a"]["Active"] = true;
			G2L["a"]["BorderSizePixel"] = 0;
			G2L["a"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
			G2L["a"]["TopImage"] = '';
			G2L["a"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36);
			G2L["a"].BackgroundTransparency = 1
			G2L["a"]["Name"] = [[Output]];
			G2L["a"]["ScrollBarImageTransparency"] = 0;
			G2L["a"]["BottomImage"] = '';
			G2L["a"]["AnchorPoint"] = Vector2.new(0, 0);
			G2L["a"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
			G2L["a"]["Size"] = UDim2.new(1, -8, 1, -55);
			G2L["a"]["Position"] = UDim2.new(0, 4, 0, 23);
			G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["a"].ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
			G2L["a"]["ScrollBarThickness"] = 16;
			G2L["a"]["ZIndex"] = 1;

			G2L["a"]:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
				if G2L["a"].AbsoluteCanvasSize ~= G2L["a"].AbsoluteWindowSize then
					scrollbar.Gui.Visible = true
				else
					scrollbar.Gui.Visible = false
				end
			end)

			-- StarterGui.ScreenGui.Console.Output.UIListLayout
			G2L["b"] = Instance.new("UIListLayout", G2L["a"]);
			G2L["b"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


			-- StarterGui.ScreenGui.Console.Output.UIStroke
			G2L["c"] = Instance.new("UIStroke", G2L["a"]);
			G2L["c"]["Transparency"] = 0.7;
			G2L["c"]["Thickness"] = 1.25;
			G2L["c"]["Color"] = Color3.fromRGB(12, 12, 12);


			-- StarterGui.ScreenGui.Console.Output.OutputTextSize
			G2L["d"] = Instance.new("NumberValue", G2L["a"]);
			G2L["d"]["Name"] = [[OutputTextSize]];
			G2L["d"]["Value"] = 15;


			-- StarterGui.ScreenGui.Console.Output.OutputLimit
			G2L["e"] = Instance.new("NumberValue", G2L["a"]);
			G2L["e"]["Name"] = [[OutputLimit]];
			G2L["e"]["Value"] = OutputLimit;


			-- StarterGui.ScreenGui.Console.Output.UIPadding
			G2L["f"] = Instance.new("UIPadding", G2L["a"]);
			G2L["f"]["PaddingTop"] = UDim.new(0, 2);


			-- StarterGui.ScreenGui.Console.TextSizeBox
			G2L["10"] = Instance.new("Frame", ConsoleFrame);
			G2L["10"]["BorderSizePixel"] = 0;
			G2L["10"]["BackgroundColor3"] = Color3.fromRGB(37, 37, 37);
			G2L["10"]["ClipsDescendants"] = true;
			G2L["10"]["Size"] = UDim2.new(0, 37, 0, 15);
			G2L["10"]["Position"] = UDim2.new(0, 4, 0, 4);
			G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["10"]["Name"] = [[TextSizeBox]];


			-- StarterGui.ScreenGui.Console.TextSizeBox.TextBox
			G2L["11"] = Instance.new("TextBox", G2L["10"]);
			G2L["11"]["PlaceholderColor3"] = Color3.fromRGB(108, 108, 108);
			G2L["11"]["BorderSizePixel"] = 0;
			G2L["11"]["TextWrapped"] = true;
			G2L["11"]["TextSize"] = 15;
			G2L["11"]["TextColor3"] = Color3.fromRGB(211, 211, 211);
			G2L["11"]["TextScaled"] = true;
			G2L["11"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["11"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["11"]["PlaceholderText"] = [[Size]];
			G2L["11"]["Size"] = UDim2.new(1, 0, 1, 0);
			G2L["11"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["11"]["Text"] = [[]];
			G2L["11"]["BackgroundTransparency"] = 1;


			-- StarterGui.ScreenGui.Console.TextSizeBox.TextBox.UIPadding
			G2L["12"] = Instance.new("UIPadding", G2L["11"]);
			G2L["12"]["PaddingTop"] = UDim.new(0, 2);
			G2L["12"]["PaddingRight"] = UDim.new(0, 5);
			G2L["12"]["PaddingLeft"] = UDim.new(0, 5);
			G2L["12"]["PaddingBottom"] = UDim.new(0, 2);


			-- StarterGui.ScreenGui.Console.TextSizeBox.UIStroke
			G2L["13"] = Instance.new("UIStroke", G2L["10"]);
			G2L["13"]["Transparency"] = 0.65;
			G2L["13"]["Thickness"] = 1.25;


			-- StarterGui.ScreenGui.Console.Clear
			G2L["14"] = Instance.new("ImageButton", ConsoleFrame);
			G2L["14"]["BorderSizePixel"] = 0;
			G2L["14"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
			G2L["14"]["Size"] = UDim2.new(0, 37, 0, 15);
			G2L["14"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["14"]["Name"] = [[Clear]];
			G2L["14"]["Position"] = UDim2.new(1, -42, 0, 4);


			-- StarterGui.ScreenGui.Console.Clear.TextLabel
			G2L["15"] = Instance.new("TextLabel", G2L["14"]);
			G2L["15"]["TextWrapped"] = true;
			G2L["15"]["Interactable"] = false;
			G2L["15"]["BorderSizePixel"] = 0;
			G2L["15"]["TextSize"] = 20;
			G2L["15"]["TextScaled"] = true;
			G2L["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["15"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["15"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["15"]["BackgroundTransparency"] = 1;
			G2L["15"]["Size"] = UDim2.new(1, 0, 1, 0);
			G2L["15"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["15"]["Text"] = [[Clear]];


			-- StarterGui.ScreenGui.Console.Clear.UIPadding
			G2L["16"] = Instance.new("UIPadding", G2L["14"]);
			G2L["16"]["PaddingTop"] = UDim.new(0, 1);
			G2L["16"]["PaddingBottom"] = UDim.new(0, 1);


			-- StarterGui.ScreenGui.Console.OutputTemplate
			G2L["17"] = Instance.new("TextBox", ConsoleFrame);
			G2L["17"]["Visible"] = false;
			G2L["17"]["Active"] = false;
			G2L["17"]["Name"] = [[OutputTemplate]];
			G2L["17"]["TextXAlignment"] = Enum.TextXAlignment.Left;
			G2L["17"]["BorderSizePixel"] = 0;
			G2L["17"]["TextEditable"] = false;
			G2L["17"]["TextWrapped"] = true;
			G2L["17"]["TextSize"] = 15;
			G2L["17"]["TextColor3"] = Color3.fromRGB(171, 171, 171);
			G2L["17"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["17"]["RichText"] = true;
			G2L["17"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["17"]["AutomaticSize"] = Enum.AutomaticSize.Y;
			G2L["17"]["Selectable"] = false;
			G2L["17"]["ClearTextOnFocus"] = false;
			G2L["17"]["Size"] = UDim2.new(1, 0, 0, 1);
			G2L["17"]["Position"] = UDim2.new(0, 20, 0, 0);
			G2L["17"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["17"]["Text"] = [[(timestamp) <font color="rgb(255, 255, 255)">Output</font>]];
			G2L["17"]["BackgroundTransparency"] = 1;


			-- StarterGui.ScreenGui.Console.OutputTemplate.UIPadding
			G2L["18"] = Instance.new("UIPadding", G2L["17"]);
			G2L["18"]["PaddingRight"] = UDim.new(0, 6);
			G2L["18"]["PaddingLeft"] = UDim.new(0, 6);


			-- StarterGui.ScreenGui.Console.CtrlScroll
			G2L["19"] = Instance.new("ImageButton", ConsoleFrame);
			G2L["19"]["BorderSizePixel"] = 0;
			G2L["19"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
			G2L["19"]["Size"] = UDim2.new(0, 60, 0, 15);
			G2L["19"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["19"]["Name"] = [[CtrlScroll]];
			G2L["19"]["Position"] = UDim2.new(0, 46, 0, 4);


			-- StarterGui.ScreenGui.Console.CtrlScroll.TextLabel
			G2L["1a"] = Instance.new("TextLabel", G2L["19"]);
			G2L["1a"]["TextWrapped"] = true;
			G2L["1a"]["Interactable"] = false;
			G2L["1a"]["BorderSizePixel"] = 0;
			G2L["1a"]["TextSize"] = 20;
			G2L["1a"]["TextScaled"] = true;
			G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["1a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["1a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["1a"]["BackgroundTransparency"] = 1;
			G2L["1a"]["Size"] = UDim2.new(1, 0, 1, 0);
			G2L["1a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["1a"]["Text"] = [[Ctrl Scroll]];


			-- StarterGui.ScreenGui.Console.CtrlScroll.UIPadding
			G2L["1b"] = Instance.new("UIPadding", G2L["19"]);
			G2L["1b"]["PaddingTop"] = UDim.new(0, 1);
			G2L["1b"]["PaddingBottom"] = UDim.new(0, 1);

			-- StarterGui.ScreenGui.Console.AutoScroll
			G2L["20"] = Instance.new("ImageButton", ConsoleFrame);
			G2L["20"]["BorderSizePixel"] = 0;
			G2L["20"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
			G2L["20"]["Size"] = UDim2.new(0, 60, 0, 15);
			G2L["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["20"]["Name"] = [[AutoScroll]];
			G2L["20"]["Position"] = UDim2.new(0, 110, 0, 4);

			-- StarterGui.ScreenGui.Console.AutoScroll.TextLabel
			G2L["1e"] = Instance.new("TextLabel", G2L["20"]);
			G2L["1e"]["TextWrapped"] = true;
			G2L["1e"]["Interactable"] = false;
			G2L["1e"]["BorderSizePixel"] = 0;
			G2L["1e"]["TextSize"] = 20;
			G2L["1e"]["TextScaled"] = true;
			G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["1e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["1e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["1e"]["BackgroundTransparency"] = 1;
			G2L["1e"]["Size"] = UDim2.new(1, 0, 1, 0);
			G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["1e"]["Text"] = [[Auto Scroll]];

			-- StarterGui.ScreenGui.Console.AutoScroll.UIPadding
			G2L["1f"] = Instance.new("UIPadding", G2L["20"]);
			G2L["1f"]["PaddingTop"] = UDim.new(0, 1);
			G2L["1f"]["PaddingBottom"] = UDim.new(0, 1);

			-- StarterGui.ScreenGui.Console.AutoScroll
			G2L["20"] = Instance.new("ImageButton", ConsoleFrame);
			G2L["20"]["BorderSizePixel"] = 0;
			G2L["20"]["BackgroundColor3"] = Color3.fromRGB(57, 57, 57);
			G2L["20"]["Size"] = UDim2.new(0, 60, 0, 15);
			G2L["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["20"]["Name"] = [[AutoScroll]];
			G2L["20"]["Position"] = UDim2.new(0, 110, 0, 4);


			-- StarterGui.ScreenGui.Console.AutoScroll.TextLabel
			G2L["1e"] = Instance.new("TextLabel", G2L["20"]);
			G2L["1e"]["TextWrapped"] = true;
			G2L["1e"]["Interactable"] = false;
			G2L["1e"]["BorderSizePixel"] = 0;
			G2L["1e"]["TextSize"] = 20;
			G2L["1e"]["TextScaled"] = true;
			G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["1e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			G2L["1e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			G2L["1e"]["BackgroundTransparency"] = 1;
			G2L["1e"]["Size"] = UDim2.new(1, 0, 1, 0);
			G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			G2L["1e"]["Text"] = [[Auto Scroll]];


			-- StarterGui.ScreenGui.Console.AutoScroll.UIPadding
			G2L["1f"] = Instance.new("UIPadding", G2L["20"]);
			G2L["1f"]["PaddingTop"] = UDim.new(0, 1);
			G2L["1f"]["PaddingBottom"] = UDim.new(0, 1);


			-- StarterGui.ScreenGui.ConsoleHandler
			G2L["1c"] = Instance.new("LocalScript", G2L["1"]);
			G2L["1c"]["Name"] = [[ConsoleHandler]];


			-- StarterGui.ScreenGui.ConsoleHandler.SyntaxHighlighter
			G2L["1d"] = Instance.new("ModuleScript", G2L["1c"]);
			G2L["1d"]["Name"] = [[SyntaxHighlighter]];


			-- Require G2L wrapper
			local G2L_REQUIRE = require;
			local G2L_MODULES = {};
			local function require(Module)
				local ModuleState = G2L_MODULES[Module];
				if ModuleState then
					if not ModuleState.Required then
						ModuleState.Required = true;
						ModuleState.Value = ModuleState.Closure();
					end
					return ModuleState.Value;
				end;
				return G2L_REQUIRE(Module);
			end

			G2L_MODULES[G2L["1d"]] = {
				Closure = function()
					local script = G2L["1d"];local highlighter = {}
					local keywords = {
						lua = {
							"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
							"local", "return", "function", "export"
						},
						rbx = {
							"game", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
							"error", "warn", "tick", "assert", "shared", "loadstring", "tonumber", "tostring", "type",
							"typeof", "unpack", "print", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
							"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo",
							"collectgarbage", "not", "utf8", "pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs"
						},
						exploit = {
							"hookmetamethod", "hookfunction", "getgc", "filtergc", "Drawing", "getgenv", "getsenv", "getrenv", "getfenv", "setfenv",
							"decompile", "saveinstance", "getrawmetatable", "setrawmetatable", "checkcaller", "cloneref", "clonefunction",
							"iscclosure", "islclosure", "isexecutorclosure", "newcclosure", "getfunctionhash", "crypt", "writefile", "appendfile", "loadfile", "readfile", "listfiles",
							"makefolder", "isfolder", "isfile", "delfile", "delfolder", "getcustomasset", "fireclickdetector", "firetouchinterest", "fireproximityprompt"
						},
						operators = {
							"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">", ",", ".", "(", ")", "{", "}", "[", "]", ";", ":"
						}
					}

					local colors = {
						numbers = Color3.fromRGB(255, 198, 0),
						boolean = Color3.fromRGB(255, 198, 0),
						operator = Color3.fromRGB(204, 204, 204),
						lua = Color3.fromRGB(132, 214, 247),
						exploit = Color3.fromRGB(171, 84, 247),
						rbx = Color3.fromRGB(248, 109, 124),
						str = Color3.fromRGB(173, 241, 132),
						comment = Color3.fromRGB(102, 102, 102),
						null = Color3.fromRGB(255, 198, 0),
						call = Color3.fromRGB(253, 251, 172),
						self_call = Color3.fromRGB(253, 251, 172),
						local_color = Color3.fromRGB(248, 109, 115),
						function_color = Color3.fromRGB(248, 109, 115),
						self_color = Color3.fromRGB(248, 109, 115),
						local_property = Color3.fromRGB(97, 161, 241),
					}

					local function createKeywordSet(keywords)
						local keywordSet = {}
						for _, keyword in pairs(keywords) do
							keywordSet[keyword] = true
						end
						return keywordSet
					end

					local luaSet = createKeywordSet(keywords.lua)
					local exploitSet = createKeywordSet(keywords.exploit)
					local rbxSet = createKeywordSet(keywords.rbx)
					local operatorsSet = createKeywordSet(keywords.operators)

					local function getHighlight(tokens, index)
						local token = tokens[index]

						if colors[token .. "_color"] then
							return colors[token .. "_color"]
						end

						if tonumber(token) then
							return colors.numbers
						elseif token == "nil" then
							return colors.null
						elseif token:sub(1, 2) == "--" then
							return colors.comment
						elseif operatorsSet[token] then
							return colors.operator
						elseif luaSet[token] then
							return colors.rbx
						elseif rbxSet[token] then
							return colors.lua
						elseif exploitSet[token] then
							return colors.exploit
						elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
							return colors.str
						elseif token == "true" or token == "false" then
							return colors.boolean
						end

						if tokens[index + 1] == "(" then
							if tokens[index - 1] == ":" then
								return colors.self_call
							end

							return colors.call
						end

						if tokens[index - 1] == "." then
							if tokens[index - 2] == "Enum" then
								return colors.rbx
							end

							return colors.local_property
						end
					end

					function highlighter.run(source)
						local tokens = {}
						local currentToken = ""

						local inString = false
						local inComment = false
						local commentPersist = false

						for i = 1, #source do
							local character = source:sub(i, i)

							if inComment then
								if character == "\n" and not commentPersist then
									table.insert(tokens, currentToken)
									table.insert(tokens, character)
									currentToken = ""

									inComment = false
								elseif source:sub(i - 1, i) == "]]" and commentPersist then
									currentToken ..= "]"

									table.insert(tokens, currentToken)
									currentToken = ""

									inComment = false
									commentPersist = false
								else
									currentToken = currentToken .. character
								end
							elseif inString then
								if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
									currentToken = currentToken .. character
									inString = false
								else
									currentToken = currentToken .. character
								end
							else
								if source:sub(i, i + 1) == "--" then
									table.insert(tokens, currentToken)
									currentToken = "-"
									inComment = true
									commentPersist = source:sub(i + 2, i + 3) == "[["
								elseif character == "\"" or character == "\'" then
									table.insert(tokens, currentToken)
									currentToken = character
									inString = character
								elseif operatorsSet[character] then
									table.insert(tokens, currentToken)
									table.insert(tokens, character)
									currentToken = ""
								elseif character:match("[%w_]") then
									currentToken = currentToken .. character
								else
									table.insert(tokens, currentToken)
									table.insert(tokens, character)
									currentToken = ""
								end
							end
						end

						table.insert(tokens, currentToken)

						local highlighted = {}

						for i, token in pairs(tokens) do
							local highlight = getHighlight(tokens, i)

							if highlight then
								local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

								table.insert(highlighted, syntax)
							else
								table.insert(highlighted, token)
							end
						end

						return table.concat(highlighted)
					end

					return highlighter
				end;
			};

			Console.Init = function()
				-- StarterGui.ScreenGui.ConsoleHandler

				local CtrlScroll = false
				local AutoScroll = false

				local LogService = cloneref(game:GetService("LogService"))
				local Players = cloneref(game:GetService("Players"))
				local LocalPlayer = Players.LocalPlayer
				local Mouse = LocalPlayer:GetMouse()
				local UserInputService = cloneref(game:GetService("UserInputService"))
				local RunService = cloneref(game:GetService("RunService"))

				local Console = ConsoleFrame
				local SyntaxHighlightingModule = require(G2L["1c"].SyntaxHighlighter)
				local OutputTextSize = Console.Output.OutputTextSize

				local function Tween(obj, info, prop)
					local tween = cloneref(game:GetService("TweenService")):Create(obj, info, prop)
					tween:Play()
					return tween
				end



				-- MOUSE STUFFS

				if CtrlScroll == true then
					Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
				elseif CtrlScroll == false then
					Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
				end
				Console.CtrlScroll.MouseButton1Click:Connect(function()
					CtrlScroll = not CtrlScroll
					if CtrlScroll == true then
						Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
					elseif CtrlScroll == false then
						Console.CtrlScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
					end
				end)

				if AutoScroll == true then
				Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
			elseif AutoScroll == false then
				Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
			end
			Console.AutoScroll.MouseButton1Click:Connect(function()
				AutoScroll = not AutoScroll
				if AutoScroll == true then
					Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
					Console.Output.CanvasPosition = Vector2.new(0, 9e9)
				elseif AutoScroll == false then
					Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
				end
			end)

				local IsHoldingCTRL = false
				UserInputService.InputBegan:Connect(function(input, gameproc)
					if not gameproc then
						if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
							IsHoldingCTRL = true
						end
					end
				end)
				UserInputService.InputEnded:Connect(function(input, gameproc)
					if not gameproc then
						if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
							IsHoldingCTRL = false
						end
					end
				end)

				if AutoScroll == true then
					Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
				elseif AutoScroll == false then
					Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
				end
				Console.AutoScroll.MouseButton1Click:Connect(function()
					AutoScroll = not AutoScroll
					if AutoScroll == true then
						Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
						Console.Output.CanvasPosition = Vector2.new(0, 9e9)
					elseif AutoScroll == false then
						Console.AutoScroll.BackgroundColor3 = Color3.fromRGB(56, 56, 56)
					end
				end)

				-- Console part
				local displayedOutput = {}
				local OutputLimit = Console.Output.OutputLimit

				Console.TextSizeBox.TextBox.Text = tostring(OutputTextSize.Value)

				Console.TextSizeBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
					local tonum = tonumber(Console.TextSizeBox.TextBox.Text)
					if tonum then
						OutputTextSize.Value = tonum
					end
				end)
				OutputTextSize:GetPropertyChangedSignal("Value"):Connect(function()
					Console.TextSizeBox.TextBox.Text = tostring(OutputTextSize.Value)
				end)

				local scrollConsoleInput
				Console.Output.MouseEnter:Connect(function()
					scrollConsoleInput = UserInputService.InputChanged:Connect(function(input)
						if CtrlScroll and input.UserInputType == Enum.UserInputType.MouseWheel and IsHoldingCTRL == true then
							Console.Output.ScrollingEnabled = false
							local newTextSize = OutputTextSize.Value + input.Position.Z
							if newTextSize >= 1 then
								OutputTextSize.Value = newTextSize
							end
						else
							Console.Output.ScrollingEnabled = true
						end
					end)
				end)
				Console.Output.MouseLeave:Connect(function()
					if scrollConsoleInput then
						scrollConsoleInput:Disconnect()
						scrollConsoleInput = nil
					end
				end)


				Console.Clear.MouseButton1Click:Connect(function()
					for _, log in pairs(Console.Output:GetChildren()) do
						if log:IsA("TextBox") then
							log:Destroy()
						end
					end
				end)

				local focussedOutput

				LogService.MessageOut:Connect(function(msg, msgtype)
					local formattedText = ""
					local unformattedText = ""
					local newOutputText = Console.OutputTemplate:Clone()
					table.insert(displayedOutput, newOutputText)

					if #displayedOutput > OutputLimit.Value then
						local oldest = table.remove(displayedOutput, 1)
						if oldest and typeof(oldest) == "Instance" then
							oldest:Destroy()
						end
					end

					unformattedText = os.date("%H:%M:%S")..'   '..msg
					if msgtype == Enum.MessageType.MessageOutput then
						formattedText = os.date("%H:%M:%S")..'   <font color="rgb(204, 204, 204)">'..msg..'</font>'
						newOutputText.Text = formattedText
					elseif msgtype == Enum.MessageType.MessageWarning then
						formattedText = os.date("%H:%M:%S")..'   <b><font color="rgb(255, 142, 60)">'..msg..'</font></b>'
						newOutputText.Text = formattedText
					elseif msgtype == Enum.MessageType.MessageError then
						formattedText = os.date("%H:%M:%S")..'   <b><font color="rgb(255, 68, 68)">'..msg..'</font></b>'
						newOutputText.Text = formattedText
					elseif msgtype == Enum.MessageType.MessageInfo then
						formattedText = os.date("%H:%M:%S")..'   <font color="rgb(128, 215, 255)">'..msg..'</font>'
						newOutputText.Text = formattedText
					end

					newOutputText.TextSize = OutputTextSize.Value
					OutputTextSize:GetPropertyChangedSignal("Value"):Connect(function()
						newOutputText.TextSize = OutputTextSize.Value
					end)

					newOutputText.Focused:Connect(function()
						focussedOutput = newOutputText
						newOutputText.Text = unformattedText
					end)
					newOutputText.FocusLost:Connect(function()
						focussedOutput = nil
						newOutputText.Text = formattedText
					end)

					newOutputText.Parent = Console.Output
					newOutputText.Visible = true

					if AutoScroll then
						Console.Output.CanvasPosition = Vector2.new(0, 9e9)
					end
				end)

				Console.Output.MouseLeave:Connect(function()
					if focussedOutput then
						focussedOutput:ReleaseFocus()
					end
				end)

				Console.CommandLine.ScrollingFrame.TextBox:GetPropertyChangedSignal("Text"):Connect(function()

					local oneliner = string.gsub(Console.CommandLine.ScrollingFrame.TextBox.Text, "\n", "    ")
					Console.CommandLine.ScrollingFrame.TextBox.Text = oneliner

					Console.CommandLine.ScrollingFrame.Highlight.Text = SyntaxHighlightingModule.run(Console.CommandLine.ScrollingFrame.TextBox.Text)
				end)



				Console.CommandLine.ScrollingFrame.TextBox.FocusLost:Connect(function(enterPressed)
					if enterPressed and Console.CommandLine.ScrollingFrame.TextBox.Text ~= "" then
						print("> "..Console.CommandLine.ScrollingFrame.TextBox.Text)
						loadstring(Console.CommandLine.ScrollingFrame.TextBox.Text)()
					end
				end)
			end

			return Console
		end

		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,

	SaveInstance = function()
--[[
	Save Instance App Module
]]
		local Main,Lib,Apps,Settings
		local Explorer, Properties, ScriptViewer, SaveInstance, Notebook
		local API,RMD,env,service,plr,create,createSimple

		local function initDeps(data)
			Main, Lib, Apps, Settings = data.Main, data.Lib, data.Apps, data.Settings
			API, RMD, env, service, plr = data.API, data.RMD, data.env, data.service, data.plr
			create, createSimple = data.create, data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			SaveInstance = Apps.SaveInstance
			Notebook = Apps.Notebook
		end

		local function main()
			local SaveInstance = {}
			local window, ListFrame
			local fileName = "Place_"..game.PlaceId.."_"..service.MarketplaceService:GetProductInfo(game.PlaceId).Name.."_{TIMESTAMP}"

			local function AddCheckbox(title, default)
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local listlayout = Instance.new("UIListLayout", frame.Gui)
				listlayout.FillDirection = Enum.FillDirection.Horizontal
				listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listlayout.Padding = UDim.new(0, 10)
				local checkbox = Lib.Checkbox.new()
				checkbox.Gui.Parent = frame.Gui
				checkbox.Gui.Size = UDim2.new(0,15,0,15)
				local label = Lib.Label.new()
				label.Gui.Parent = frame.Gui
				label.Gui.Size = UDim2.new(1, 0,1, -15)
				label.Gui.Text = title
				label.TextTruncate = Enum.TextTruncate.AtEnd
				checkbox:SetState(default)
				return checkbox
			end

			local function AddTextbox(title, default, sizeX)
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local listlayout = Instance.new("UIListLayout", frame.Gui)
				listlayout.FillDirection = Enum.FillDirection.Horizontal
				listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listlayout.Padding = UDim.new(0, 10)
				local textbox = Lib.ViewportTextBox.new()
				textbox.Gui.Parent = frame.Gui
				textbox.Gui.Size = UDim2.new(0, sizeX or 45, 0, 15)
				textbox.Gui.AutomaticSize = Enum.AutomaticSize.X
				textbox.TextBox.AutomaticSize = Enum.AutomaticSize.X
				local label = Lib.Label.new()
				label.Gui.Parent = frame.Gui
				label.Gui.Size = UDim2.new(1, 0,1, -15)
				label.Gui.Text = title
				label.TextTruncate = Enum.TextTruncate.AtEnd
				textbox:SetText(tostring(default))
				return textbox
			end

			local function AddDropdown(title, options, default, allowEmpty, sizeX)
				if allowEmpty == nil then allowEmpty = true end
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local listlayout = Instance.new("UIListLayout", frame.Gui)
				listlayout.FillDirection = Enum.FillDirection.Horizontal
				listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listlayout.Padding = UDim.new(0, 10)
				local dropdown = Lib.DropDown.new()
				dropdown.CanBeEmpty = allowEmpty
				dropdown.Gui.Size = UDim2.new(0, sizeX or 80, 0, 15)
				dropdown:SetOptions(options)
				if default then dropdown:SetSelected(default) end
				dropdown.Gui.Parent = frame.Gui
				local label = Lib.Label.new()
				label.Gui.Parent = frame.Gui
				label.Gui.Size = UDim2.new(1, 0, 1, -15)
				label.Gui.Text = title
				label.TextTruncate = Enum.TextTruncate.AtEnd
				return dropdown
			end

			local function AddHeader(title)
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1, 0, 0, 25)
				local label = Lib.Label.new()
				label.Gui.Parent = frame.Gui
				label.Gui.Size = UDim2.new(1, 0, 1, 0)
				label.Gui.Text = "<b>" .. title:upper() .. "</b>"
				label.Gui.RichText = true
				label.Gui.TextColor3 = Color3.fromRGB(255,255,255)
			end

			SaveInstance.BuildUI = function()
				for _, child in next, ListFrame:GetChildren() do
					if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
						child:Destroy()
					end
				end
				if SaveInstance.BottomContainer then
					SaveInstance.BottomContainer:Destroy()
				end

				local Method = Settings.SaveInstance and Settings.SaveInstance.Method or "DexRESerializer"
				local ExecuteSaveFunction = nil

				if Method == "UniversalSynSaveInstance" then
					-- old one
					local SaveInstanceArgs = {
						Decompile = true, DecompileTimeout = 10, DecompileIgnore = {"Chat", "CoreGui", "CorePackages"},
						NilInstances = false, RemovePlayerCharacters = true, SavePlayers = false,
						MaxThreads = 3, ShowStatus = true, IgnoreDefaultProps = true, IsolateStarterPlayer = true
					}
					
					local OptDecompile = AddCheckbox("Decompile Scripts", SaveInstanceArgs.Decompile)
					local OptDecTimeout = AddTextbox("Decompile Timeout (s)", SaveInstanceArgs.DecompileTimeout, 25)
					local OptThreads = AddTextbox("Decompiler Max Threads", SaveInstanceArgs.MaxThreads, 25)
					local OptIgnore = AddTextbox("Decompile Ignore", table.concat(SaveInstanceArgs.DecompileIgnore, ","), 80)
					local OptNil = AddCheckbox("Save Nil Instances", SaveInstanceArgs.NilInstances)
					local OptRemChar = AddCheckbox("Remove Player Characters", SaveInstanceArgs.RemovePlayerCharacters)
					local OptSavePlr = AddCheckbox("Save Player Instance", SaveInstanceArgs.SavePlayers)
					local OptIsolate = AddCheckbox("Isolate StarterPlayer", SaveInstanceArgs.IsolateStarterPlayer)
					local OptIgnoreDef = AddCheckbox("Ignore Default Properties", SaveInstanceArgs.IgnoreDefaultProps)
					local OptShowStat = AddCheckbox("Show Status", SaveInstanceArgs.ShowStatus)

					ExecuteSaveFunction = function(finalName)
						local rawList = string.split(OptIgnore.TextBox.Text, ",")
						local finalList = {}
						for _, text in next, rawList do table.insert(finalList, text:match("^%s*(.-)%s*$")) end

						local options = {
							Decompile = OptDecompile.Toggled,
							DecompileTimeout = tonumber(OptDecTimeout.TextBox.Text) or 10,
							MaxThreads = tonumber(OptThreads.TextBox.Text) or 3,
							DecompileIgnore = finalList,
							NilInstances = OptNil.Toggled,
							RemovePlayerCharacters = OptRemChar.Toggled,
							SavePlayers = OptSavePlr.Toggled,
							IsolateStarterPlayer = OptIsolate.Toggled,
							IgnoreDefaultProps = OptIgnoreDef.Toggled,
							ShowStatus = OptShowStat.Toggled
						}
						window:SetTitle("Save Instance - Saving")
						local s, result = pcall(env.saveinstance, game, env.parsefile(finalName), options)
						if s then window:SetTitle("Save Instance - Saved") else window:SetTitle("Save Instance - didnt work") task.spawn(error, result) end
					end
				else
					-- this is dexre's serializer
					AddHeader("Decompilation")
					local OptDecompile = AddCheckbox("Decompile Scripts", true)
					local OptSaveBytecode = AddCheckbox("Include Bytecode", false)
					local OptScriptCache = AddCheckbox("Use Script Cache", false)
					local OptDecTimeout = AddTextbox("Timeout (s)", "10", 35)
					local OptThreads = AddTextbox("Max Threads", "3", 35)
					local OptIgnoreList = AddTextbox("Ignore Services (split by ,)", "Chat,CoreGui,CorePackages", 120)

					AddHeader("Instance Selection")
					local OptMode = AddDropdown("Mode", {"full", "scripts", "models"}, "full", false, 80)
					local OptNil = AddCheckbox("Include Nil Instances", false)
					local OptRemovePlrChar = AddCheckbox("Remove Player Characters", true)
					local OptSavePlayers = AddCheckbox("Save Player Instances", false)
					local OptSaveChar = AddCheckbox("Save Character Models", false)
					local OptIsolateStarter = AddCheckbox("Isolate StarterPlayer", true)
					local OptIsolateLocal = AddCheckbox("Isolate LocalPlayer", false)

					AddHeader("Filtering")
					local OptIgnoreDef = AddCheckbox("Ignore Default Properties", true)
					local OptIgnoreArch = AddCheckbox("Ignore Non-Archivable", true)
					local OptAnonymous = AddCheckbox("Anonymous (Remove Names/IDs)", false)

					AddHeader("Safety & Performance")
					local OptSafeMode = AddCheckbox("Safe Mode (Kick before save)", false)
					local OptBoostFPS = AddCheckbox("Boost FPS (Stop Rendering)", false)
					local OptKillScripts = AddCheckbox("Kill All Scripts", false)
					local OptAntiIdle = AddCheckbox("Anti-Idle (Prevent Timeout)", false)

					AddHeader("Output")
					local OptBinary = AddCheckbox("Binary Format (.rbxl/.rbxm)", true)
					local OptShowStatus = AddCheckbox("Show Status Overlay", true)
					local OptReadMe = AddCheckbox("Include README", true)
					local OptClipboard = AddCheckbox("Copy to Clipboard", false)
					local OptOverwrite = AddCheckbox("Avoid File Overwrite", false)

					ExecuteSaveFunction = function(finalName)
						local options = {
							Decompile = OptDecompile.Toggled, DecompileTimeout = tonumber(OptDecTimeout.TextBox.Text) or 10,
							MaxThreads = tonumber(OptThreads.TextBox.Text) or 3, DecompileIgnore = string.split(OptIgnoreList.TextBox.Text, ","),
							SaveBytecode = OptSaveBytecode.Toggled, SaveScriptCache = OptScriptCache.Toggled,
							NilInstances = OptNil.Toggled, RemovePlayerCharacters = OptRemovePlrChar.Toggled, SavePlayers = OptSavePlayers.Toggled,
							SavePlayerCharacters = OptSaveChar.Toggled, IsolateStarterPlayer = OptIsolateStarter.Toggled, IsolateLocalPlayer = OptIsolateLocal.Toggled,
							IgnoreDefaultProps = OptIgnoreDef.Toggled, IgnoreNotArchivable = OptIgnoreArch.Toggled,
							Binary = OptBinary.Toggled, ShowStatus = OptShowStatus.Toggled, ReadMe = OptReadMe.Toggled,
							Mode = OptMode.Selected, Clipboard = OptClipboard.Toggled, AvoidFileOverwrite = OptOverwrite.Toggled,
							SafeMode = OptSafeMode.Toggled, BoostFPS = OptBoostFPS.Toggled, KillAllScripts = OptKillScripts.Toggled,
							AntiIdle = OptAntiIdle.Toggled, Anonymous = OptAnonymous.Toggled
						}
						window:SetTitle("Save Instance - Saving")
						local s, result = pcall(env.saveinstance, workspace.Parent, env.parsefile(finalName), options)
						if s then window:SetTitle("Save Instance - Success") else window:SetTitle("Save Instance - didnt work") task.spawn(error, "Dex Save Error: " .. tostring(result)) end
					end
				end

				SaveInstance.BottomContainer = Instance.new("Frame", window.GuiElems.Content)
				SaveInstance.BottomContainer.BackgroundTransparency = 1
				SaveInstance.BottomContainer.Size = UDim2.new(1, 0, 0, 40)
				SaveInstance.BottomContainer.Position = UDim2.new(0, 0, 1, -40)

				local FilenameTextBox = Lib.ViewportTextBox.new()
				FilenameTextBox.Gui.Parent = SaveInstance.BottomContainer
				FilenameTextBox.Size = UDim2.new(1, 0, 0, 20)
				FilenameTextBox.Position = UDim2.new(0, 0, 0, 0)
				FilenameTextBox.TextBox.Text = fileName
				local textpadding = Instance.new("UIPadding", FilenameTextBox.Gui)
				textpadding.PaddingLeft = UDim.new(0, 5) textpadding.PaddingRight = UDim.new(0, 5)

				local BackgroundButton = Lib.Frame.new()
				BackgroundButton.Gui.Parent = SaveInstance.BottomContainer
				BackgroundButton.Size = UDim2.new(1, 0, 0, 20)
				BackgroundButton.Position = UDim2.new(0, 0, 0, 20)

				local LabelButton = Lib.Label.new()
				LabelButton.Gui.Parent = SaveInstance.BottomContainer
				LabelButton.Size = UDim2.new(1, 0, 0, 20)
				LabelButton.Position = UDim2.new(0, 0, 0, 20)
				LabelButton.Gui.Text = "Save"
				LabelButton.Gui.TextXAlignment = Enum.TextXAlignment.Center

				local Button = Instance.new("TextButton", BackgroundButton.Gui)
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.Transparency = 1

				Button.MouseButton1Click:Connect(function()
					local finalName = FilenameTextBox.TextBox.Text:gsub("{TIMESTAMP}", os.date("%d-%m-%Y_%H-%M-%S"))
					ExecuteSaveFunction(finalName)
				end)
			end

			SaveInstance.Init = function()
				window = Lib.Window.new()
				window:SetTitle("Save Instance")
				window:Resize(400, 500)
				SaveInstance.Window = window

				ListFrame = Instance.new("ScrollingFrame")
				ListFrame.Parent = window.GuiElems.Content
				ListFrame.Size = UDim2.new(1, 0, 1, -40)
				ListFrame.Position = UDim2.new(0, 0, 0, 0)
				ListFrame.Transparency = 1
				ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
				ListFrame.ScrollBarThickness = 12
				ListFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
				ListFrame.BorderSizePixel = 0

				local ListLayout = Instance.new("UIListLayout", ListFrame)
				ListLayout.Padding = UDim.new(0, 4)
				local Padding = Instance.new("UIPadding", ListFrame)
				Padding.PaddingBottom = UDim.new(0, 5) Padding.PaddingLeft = UDim.new(0, 10) Padding.PaddingRight = UDim.new(0, 10) Padding.PaddingTop = UDim.new(0, 5)

				ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
				end)

				SaveInstance.BuildUI()
			end

			return SaveInstance
		end

		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,

	ModelViewer = function()
		local Main,Lib,Apps,Settings
		local Explorer, Properties, ScriptViewer, ModelViewer, Notebook
		local API,RMD,env,service,plr,create,createSimple

		local function initDeps(data)
			Main, Lib, Apps, Settings = data.Main, data.Lib, data.Apps, data.Settings
			API, RMD, env, service, plr = data.API, data.RMD, data.env, data.service, data.plr
			create, createSimple = data.create, data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			ModelViewer = Apps.ModelViewer
			SettingsWindow = Apps.SettingsWindow
			Notebook = Apps.Notebook
		end

		local function getPath(obj)
			if obj.Parent == nil then return "Nil parented" else return Explorer.GetInstancePath(obj) end
		end

		local function main()
			local RunService = cloneref(game:GetService("RunService"))
			local UserInputService = cloneref(game:GetService("UserInputService"))
			
			local ModelViewer = {
				EnableInputCamera = true, IsViewing = false, AutoRefresh = false,
				ZoomMultiplier = 2, AutoRotate = true, RotationSpeed = 0.01, RefreshRate = 30
			}
			
			local window, viewportFrame, pathLabel, settingsButton
			local model, camera, originalModel
			
			ModelViewer.StopViewModel = function(updating)
				if updating then
					local m = viewportFrame:FindFirstChildOfClass("Model")
					if m then m:Destroy() end
				else
					camera, model = nil, nil
					viewportFrame:ClearAllChildren()
					ModelViewer.IsViewing = false
					window:SetTitle("3D Preview")
					pathLabel.Gui.Text = ""
				end
			end

			ModelViewer.ViewModel = function(item, updating)
				if not item then return end
				ModelViewer.StopViewModel(updating)
				
				if item ~= workspace and not item:IsA("Terrain") then
					if item:IsA("BasePart") and not item:IsA("Model") then			
						model = Instance.new("Model")
						model.Parent = viewportFrame
						local clone = item:Clone()
						clone.Parent = model
						model.PrimaryPart = clone
						model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
					elseif item:IsA("Model") then
						item.Archivable = true
						if #item:GetChildren() == 0 then return end
						model = item:Clone()
						model.Parent = viewportFrame

						if not model.PrimaryPart then
							local found = false
							for _, child in next, model:GetDescendants() do
								if child:IsA("BasePart") then
									model.PrimaryPart = child
									model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
									found = true
									break
								end
							end
							if not found then
								model:Destroy()
								model = nil
								return
							end
						end
					else return end
				end
				
				originalModel = item
				
				if ModelViewer.AutoRefresh and not updating then
					task.spawn(function()
						while model and ModelViewer.AutoRefresh do
							ModelViewer.ViewModel(originalModel, true)
							task.wait(1 / ModelViewer.RefreshRate)
						end
					end)
				end
				
				if not updating then
					camera = Instance.new("Camera")
					viewportFrame.CurrentCamera = camera
					camera.Parent = viewportFrame
					camera.FieldOfView = 60
					window:SetTitle(item.Name.." - 3D Preview")
					pathLabel.Gui.Text = "path: " .. getPath(originalModel)
					window:Show()
					ModelViewer.IsViewing = true
				end
			end

			ModelViewer.Init = function()
				window = Lib.Window.new()
				window:SetTitle("3D Preview")
				window:Resize(350,200)
				ModelViewer.Window = window
				
				viewportFrame = Instance.new("ViewportFrame")
				viewportFrame.Parent = window.GuiElems.Content
				viewportFrame.BackgroundTransparency = 1
				viewportFrame.Size = UDim2.new(1,0,1,0)
				
				pathLabel = Lib.Label.new()
				pathLabel.Gui.Parent = window.GuiElems.Content
				pathLabel.Gui.AnchorPoint = Vector2.new(0,1)
				pathLabel.Gui.Text = ""
				pathLabel.Gui.TextSize = 12
				pathLabel.Gui.TextTransparency = 0.8
				pathLabel.Gui.Position = UDim2.new(0,1,1,0)
				pathLabel.Gui.Size = UDim2.new(1,-1,0,15)
				pathLabel.Gui.BackgroundTransparency = 1

				local rotationX, rotationY, distance = -15, 0, 10
				local dragging, hovering, lastpos = false, false, Vector2.zero

				viewportFrame.InputBegan:Connect(function(input)
					if not ModelViewer.EnableInputCamera then return end
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						lastpos = input.Position
					elseif input.KeyCode == Enum.KeyCode.LeftShift then
						ModelViewer.ZoomMultiplier = 10
					end
				end)

				viewportFrame.MouseEnter:Connect(function() hovering = true end)
				viewportFrame.MouseLeave:Connect(function() hovering = false end)

				viewportFrame.InputEnded:Connect(function(input)
					if not ModelViewer.EnableInputCamera then return end
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					elseif input.KeyCode == Enum.KeyCode.LeftShift then
						ModelViewer.ZoomMultiplier = 2
					end
				end)

				viewportFrame.InputChanged:Connect(function(input)
					if not ModelViewer.EnableInputCamera then return end
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local delta = input.Position - lastpos
						lastpos = input.Position
						rotationY -= delta.X * 0.01
						rotationX -= delta.Y * 0.01
						rotationX = math.clamp(rotationX, -math.pi/2 + 0.1, math.pi/2 - 0.1)
					end
					if input.UserInputType == Enum.UserInputType.MouseWheel and hovering then
						distance = math.clamp(distance - (input.Position.Z * ModelViewer.ZoomMultiplier), 0.1, math.huge)
					end
				end)

				RunService.RenderStepped:Connect(function(dt)
					if camera and model then
						if not dragging and ModelViewer.AutoRotate then
							rotationY += ModelViewer.RotationSpeed * dt * 60
						end
						local center = model.PrimaryPart.Position
						local offset = CFrame.new(0, 0, distance)
						local rotation = CFrame.Angles(0, rotationY, 0) * CFrame.Angles(rotationX, 0, 0)
						local camCF = CFrame.new(center) * rotation * offset
						camera.CFrame = CFrame.lookAt(camCF.Position, center)
					end
				end)
			end

			return ModelViewer
		end
		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,

	SettingsWindow = function()
		local Main,Lib,Apps,Settings
		local Explorer, Properties, ScriptViewer, SettingsWindow, Notebook
		local API,RMD,env,service,plr,create,createSimple

		local function initDeps(data)
			Main,Lib,Apps,Settings = data.Main,data.Lib,data.Apps,data.Settings
			API,RMD,env,service,plr = data.API,data.RMD,data.env,data.service,data.plr
			create,createSimple = data.create,data.createSimple
		end

		local function initAfterMain()
			Explorer = Apps.Explorer
			Properties = Apps.Properties
			ScriptViewer = Apps.ScriptViewer
			SettingsWindow = Apps.SettingsWindow
		end

		local function main()
			local SettingsWindow = {}
			local window, ListFrame
			
			local function AddCheckbox(title, default)
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local listlayout = Instance.new("UIListLayout")
				listlayout.Parent = frame.Gui
				listlayout.FillDirection = Enum.FillDirection.Horizontal
				listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listlayout.Padding = UDim.new(0, 10)
				
				local checkbox = Lib.Checkbox.new()
				checkbox.Gui.Parent = frame.Gui
				checkbox.Gui.Size = UDim2.new(0,15,0,15)
				local label = Lib.Label.new()
				label.Gui.Parent = frame.Gui
				label.Gui.Size = UDim2.new(1, 0,1, -15)
				label.Gui.Text = title
				label.TextTruncate = Enum.TextTruncate.AtEnd
				checkbox:SetState(default or false)
				return checkbox
			end
			
			local function AddTextbox(title, default, sizeX)
				default = default and tostring(default) or ""
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local listlayout = Instance.new("UIListLayout")
				listlayout.Parent = frame.Gui
				listlayout.FillDirection = Enum.FillDirection.Horizontal
				listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listlayout.Padding = UDim.new(0, 10)

				local textbox = Instance.new("TextBox")
				textbox.BackgroundColor3 = Settings.Theme.TextBox
				textbox.BorderColor3 = Settings.Theme.Outline3
				textbox.ClearTextOnFocus = false
				textbox.TextColor3 = Settings.Theme.Text
				textbox.Font = Enum.Font.SourceSans
				textbox.TextSize = 14
				textbox.ZIndex = 2
				textbox.Parent = frame.Gui
				textbox.Size = UDim2.new(0,sizeX or 45,0,15)
				
				frame.Gui.AutomaticSize = Enum.AutomaticSize.X
				textbox.AutomaticSize = Enum.AutomaticSize.X
				local label = Lib.Label.new()
				label.Parent = frame.Gui
				label.Size = UDim2.new(1, 0,1, -15)
				label.Text = title
				label.TextTruncate = Enum.TextTruncate.AtEnd
				textbox.Text = default
				return textbox
			end
			
			local function AddDropdown(title, options, default, allowEmpty, sizeX)
				if allowEmpty == nil then allowEmpty = true end
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local listlayout = Instance.new("UIListLayout")
				listlayout.Parent = frame.Gui
				listlayout.FillDirection = Enum.FillDirection.Horizontal
				listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
				listlayout.Padding = UDim.new(0, 10)

				local dropdown = Lib.DropDown.new()
				dropdown.CanBeEmpty = allowEmpty
				dropdown.Size = UDim2.new(0,sizeX or 75,0,15)
				dropdown:SetOptions(options)
				if default then dropdown:SetSelected(default) end
				dropdown.Gui.Parent = frame.Gui
				frame.Gui.AutomaticSize = Enum.AutomaticSize.X

				local label = Lib.Label.new()
				label.Parent = frame.Gui
				label.Size = UDim2.new(1, 0,1, -15)
				label.Text = title
				label.TextTruncate = Enum.TextTruncate.AtEnd
				return dropdown
			end
			
			local function AddSeperator(title)
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,20)
				local label = Lib.Label.new()
				label.Parent = frame.Gui
				label.Size = UDim2.new(1, 0,1, 0)
				label.Text = title
				label.TextSize = 16
				label.TextTruncate = Enum.TextTruncate.AtEnd
				return label
			end
			
			local function AddText(text)
				local frame = Lib.Frame.new()
				frame.Gui.Parent = ListFrame
				frame.Gui.Transparency = 1
				frame.Gui.Size = UDim2.new(1,0,0,15)
				local label = Lib.Label.new()
				label.Parent = frame.Gui
				label.Size = UDim2.new(1, 0,1, 0)
				label.TextColor3 = Color3.fromRGB(185,185,185)
				label.Text = text
				label.TextSize = 14
				label.TextTruncate = Enum.TextTruncate.AtEnd
				return label
			end
			
			SettingsWindow.ReloadPrompt = function()		
				local win = ScriptViewer.ReloadPromptWindow
				if not win then
					win = Lib.Window.new()
					win.Alignable = false
					win.Resizable = false
					win:SetTitle("Apply Current Settings")
					win:SetSize(300,115)

					local reloadButton = Lib.Button.new()
					local nameLabel = Lib.Label.new()
					nameLabel.Text = "Applying current settings requires reload.\nAny unsaved progress will be lost.\nAre you sure?"
					nameLabel.Position = UDim2.new(0,30,0,20)
					nameLabel.Size = UDim2.new(0,40,0,20)
					win:Add(nameLabel)

					local cancelButton = Lib.Button.new()
					cancelButton.AnchorPoint = Vector2.new(1,1)
					cancelButton.Text = "Apply Later"
					cancelButton.Position = UDim2.new(1,-5,1,-5)
					cancelButton.Size = UDim2.new(0.5,-10,0,20)
					cancelButton.OnClick:Connect(function() win:Close() end)
					win:Add(cancelButton)

					reloadButton.Text = "Apply Now"
					reloadButton.AnchorPoint = Vector2.new(0,1)
					reloadButton.Position = UDim2.new(0,5,1,-5)
					reloadButton.Size = UDim2.new(0.5,-5,0,20)
					reloadButton.OnClick:Connect(function()
						Main.Reinit()
					end)
					win:Add(reloadButton,"reloadButton")

					ScriptViewer.ReloadPromptWindow = win
				end
				win:Show()
			end
			
			SettingsWindow.Init = function()
				window = Lib.Window.new()
				window:SetTitle("Settings")
				window:Resize(250,375)
				SettingsWindow.Window = window
				
				ListFrame = Instance.new("ScrollingFrame")
				ListFrame.Parent = window.GuiElems.Content
				ListFrame.Size = UDim2.new(1, 0, 1, -20)
				ListFrame.Position = UDim2.new(0, 0, 0, 0)
				ListFrame.Transparency = 1
				ListFrame.CanvasSize = UDim2.new(0,0,0,0)
				ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
				ListFrame.ScrollBarThickness = 16
				ListFrame.BottomImage = ""
				ListFrame.TopImage = ""
				ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
				ListFrame.ScrollBarImageTransparency = 0
				ListFrame.ZIndex = 2
				ListFrame.BorderSizePixel = 0
				
				local scrollbar = Lib.ScrollBar.new()
				scrollbar.Gui.Parent = window.GuiElems.Content
				scrollbar.Gui.Size = UDim2.new(1, 0, 1, -40)
				scrollbar.Gui.Up.ZIndex = 3
				scrollbar.Gui.Down.ZIndex = 3
				
				ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
					scrollbar.Gui.Visible = (ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize)
				end)
				
				local ListLayout = Instance.new("UIListLayout")
				ListLayout.Parent = ListFrame
				ListLayout.Padding = UDim.new(0, 5)
				
				local Padding = Instance.new("UIPadding")
				Padding.Parent = ListFrame
				Padding.PaddingBottom = UDim.new(0, 5)
				Padding.PaddingLeft = UDim.new(0, 10)
				Padding.PaddingRight = UDim.new(0, 10)
				Padding.PaddingTop = UDim.new(0, 5)

				local function ApplyWindowSettings()
					for _, win in pairs(Lib.Window.CreatedWindows) do
						win.GuiElems.Content.BackgroundTransparency = Settings.Window.Transparency or 0
						if Settings.Window.TitleOnMiddle then
							win.GuiElems.Title.TextXAlignment = Enum.TextXAlignment.Center
							win.GuiElems.Title.Size = UDim2.new(1, -20, 0, 20)
						else
							win.GuiElems.Title.TextXAlignment = Enum.TextXAlignment.Left
							win.GuiElems.Title.Size = UDim2.new(1, -10, 0, 20)
						end
					end
					if Properties.EntryTemplate then
						Properties.EntryTemplate.BackgroundTransparency = (Settings.Window.Transparency and Settings.Window.Transparency > 0) and 0.75 or 1
					end
				end
				
				AddSeperator("UI")
				local titleonmiddle = AddCheckbox("Window Title On Middle", Settings.Window and Settings.Window.TitleOnMiddle)
				titleonmiddle.OnInput:Connect(function() 
					Settings.Window.TitleOnMiddle = titleonmiddle.Toggled 
					ApplyWindowSettings()
				end)

				Lib.Window.UpdateTransparency()
				if Properties.EntryTemplate then
					Properties.EntryTemplate.BackgroundTransparency = Settings.Window.Transparency > 0 and 0.75 or 1
				end
				if Properties.Refresh then Properties.Refresh() end
				
				local bgTransparency = AddTextbox("Background Transparency", tostring(Settings.Window.Transparency), 25)
		bgTransparency.FocusLost:Connect(function()
			local val = tonumber(bgTransparency.Text)
			if val then
				Settings.Window.Transparency = math.clamp(val, 0, 1)
				Lib.Window.UpdateTransparency()
				if Properties.EntryTemplate then
					Properties.EntryTemplate.BackgroundTransparency = Settings.Window.Transparency > 0 and 0.75 or 1
				end
				if Properties.Refresh then Properties.Refresh() end
			else
				bgTransparency.Text = tostring(Settings.Window.Transparency)
			end
		end)
				
				local classIcon = AddDropdown("Class Icons", {"Old", "NewDark", "Vanilla3"}, Settings.ClassIcon, false, 100)
		classIcon.OnSelect:Connect(function()
			Settings.ClassIcon = classIcon.Selected
			if Lib.IconMap and Lib.IconMap.UpdateExplorerIcons then
				Lib.IconMap.UpdateExplorerIcons(classIcon.Selected)
			end
			if Explorer and Explorer.InitClassIcons then
				Explorer.InitClassIcons()
			end
			if Explorer and Explorer.Refresh then
				Explorer.Refresh()
			end
		end)
				
				AddSeperator("Explorer")
				local clickRename = AddCheckbox("Click to Rename", Settings.Explorer.ClickToRename)
				clickRename.OnInput:Connect(function() Settings.Explorer.ClickToRename = clickRename.Toggled end)
				
				local partSelectionBox = AddCheckbox("Part Selection Box", Settings.Explorer.PartSelectionBox)
				partSelectionBox.OnInput:Connect(function() 
					Settings.Explorer.PartSelectionBox = partSelectionBox.Toggled 
					Explorer.UpdateSelectionVisuals()
				end)
				
				local copypathUseChildren = AddCheckbox("Use GetChildren to Copy Path", Settings.Explorer.CopyPathUseGetChildren)
				copypathUseChildren.OnInput:Connect(function() Settings.Explorer.CopyPathUseGetChildren = copypathUseChildren.Toggled end)

				local stopAutoScroll = AddCheckbox("Stop Auto Scroll", Settings.Explorer.StopAutoScroll)
		stopAutoScroll.OnInput:Connect(function()
			Settings.Explorer.StopAutoScroll = stopAutoScroll.Toggled
		end)
				
				AddSeperator("Properties")
				local showDeprecated = AddCheckbox("Show Deprecated", Settings.Properties.ShowDeprecated)
				showDeprecated.OnInput:Connect(function() 
					Settings.Properties.ShowDeprecated = showDeprecated.Toggled 
					Properties.ShowExplorerProps()
				end)
				
				local showHidden = AddCheckbox("Show Hidden", Settings.Properties.ShowHidden)
				showHidden.OnInput:Connect(function() 
					Settings.Properties.ShowHidden = showHidden.Toggled 
					Properties.ShowExplorerProps()
				end)

				local showAllProps = AddCheckbox("Show All Properties", Settings.Properties.ShowAllProperties)
				showAllProps.OnInput:Connect(function() 
					Settings.Properties.ShowAllProperties = showAllProps.Toggled 
					Properties.ShowExplorerProps()
				end)
				
				local showAttributes = AddCheckbox("Show Attributes", Settings.Properties.ShowAttributes)
				showAttributes.OnInput:Connect(function() 
					Settings.Properties.ShowAttributes = showAttributes.Toggled 
					Properties.ShowExplorerProps()
				end)

				local showTags = AddCheckbox("Show Tags", Settings.Properties.ShowTags)
				showTags.OnInput:Connect(function()
				Settings.Properties.ShowTags = showTags.Toggled
				Properties.ShowExplorerProps()
				end)
				
				local clearOnFocus = AddCheckbox("Clear On Focus", Settings.Properties.ClearOnFocus)
				clearOnFocus.OnInput:Connect(function() Settings.Properties.ClearOnFocus = clearOnFocus.Toggled end)
				local showCopyButton = AddCheckbox("Show Property Copy Button", Settings.Properties.ShowCopyButton)
		showCopyButton.OnInput:Connect(function()
			Settings.Properties.ShowCopyButton = showCopyButton.Toggled
			Properties.ShowExplorerProps()
		end)
				
				AddSeperator("Script Viewer")
				local showMoreInfo = AddCheckbox("Show Decompiled Script Info", Settings.ScriptViewer and Settings.ScriptViewer.ShowMoreInfo)
				showMoreInfo.OnInput:Connect(function() Settings.ScriptViewer.ShowMoreInfo = showMoreInfo.Toggled end)
				
				AddSeperator("Decompiler")
				AddText("If executor does not support decompile, it will use the fallback option.")
				AddText("'getscriptbytecode' is mandatory to use fallback decompilers.")
				local decompiler = AddDropdown("Decompiler Fallback", {"Konstant", "AdvancedDecompiler", "Shiny", "LuaExpert", "Sabre", "x2125", "Bytefall", "Disassembly"}, Settings.Decompiler and Settings.Decompiler.DecompilerFallback, false, 125)
				decompiler.OnSelect:Connect(function() Settings.Decompiler.DecompilerFallback = decompiler.Selected end)
				
				local ShinyPort = AddTextbox("Shiny Decompiler Port", Settings.Decompiler and tostring(Settings.Decompiler.ShinyDecompilerPort), 50)
				ShinyPort.FocusLost:Connect(function()
					local portinput = tonumber(ShinyPort.Text)
					if portinput and portinput > 0 and portinput <= 65535 then
						Settings.Decompiler.ShinyDecompilerPort = portinput
					else
						ShinyPort.Text = Settings.Decompiler.ShinyDecompilerPort
					end
				end)
				
				local preferFallback = AddCheckbox("Prefer Fallback Decompiler", Settings.Decompiler and Settings.Decompiler.PreferDecompilerFallback)
				preferFallback.OnInput:Connect(function() Settings.Decompiler.PreferDecompilerFallback = preferFallback.Toggled end)
				
				AddSeperator("Save Instance")
				local save = AddDropdown("Serializer Module", {"DexRESerializer", "UniversalSynSaveInstance"}, Settings.SaveInstance and Settings.SaveInstance.Method or "DexRESerializer", false, 150)
				save.OnSelect:Connect(function() 
					if not Settings.SaveInstance then Settings.SaveInstance = {} end
					Settings.SaveInstance.Method = save.Selected 
					if Apps.SaveInstance and Apps.SaveInstance.BuildUI then
						Apps.SaveInstance.BuildUI()
					end
				end)

				SettingsWindow.ThemeColorBtns = SettingsWindow.ThemeColorBtns or {}
				local function AddColorPicker(title, themeKey)
					local frame = Lib.Frame.new()
					frame.Gui.Parent = ListFrame
					frame.Gui.Transparency = 1
					frame.Gui.Size = UDim2.new(1,0,0,20)
					local listlayout = Instance.new("UIListLayout")
					listlayout.Parent = frame.Gui
					listlayout.FillDirection = Enum.FillDirection.Horizontal
					listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
					listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
					listlayout.Padding = UDim.new(0, 10)
					
					local colorBtn = Instance.new("TextButton")
					colorBtn.Size = UDim2.new(0, 45, 0, 15)
					colorBtn.BackgroundColor3 = Settings.Theme[themeKey] or Color3.new(1,1,1)
					colorBtn.Text = ""
					colorBtn.Parent = frame.Gui
					colorBtn.BorderSizePixel = 0
					
					SettingsWindow.ThemeColorBtns[themeKey] = colorBtn
					
					local label = Lib.Label.new()
					label.Gui.Parent = frame.Gui
					label.Size = UDim2.new(1, -65, 1, 0)
					label.Text = title
					label.TextTruncate = Enum.TextTruncate.AtEnd

					colorBtn.MouseButton1Click:Connect(function()
						local picker = Lib.ColorPicker.new()
						picker.Window:SetTitle("Color: " .. title)
						picker:SetColor(Settings.Theme[themeKey])
						picker.OnSelect:Connect(function(col)
							local oldColor = Settings.Theme[themeKey]
							colorBtn.BackgroundColor3 = col
							Settings.Theme[themeKey] = col
							if Main.UpdateThemeColor then
								Main.UpdateThemeColor(oldColor, col)
							end
						end)
						picker:Show()
					end)
				end

				AddSeperator("Theme Colors")
				AddColorPicker("Accent Color", "ListSelection")
				AddColorPicker("Main 1", "Main1")
				AddColorPicker("Main 2", "Main2")
				AddColorPicker("Outline 1", "Outline1")
				AddColorPicker("Outline 2", "Outline2")
				AddColorPicker("TextBox", "TextBox")
				AddColorPicker("Menu", "Menu")
				AddColorPicker("Button", "Button")
				AddColorPicker("Button Hover", "ButtonHover")
				AddColorPicker("Button Press", "ButtonPress")
				AddColorPicker("Highlight", "Highlight")
				AddColorPicker("Text", "Text")
				AddColorPicker("Placeholder Text", "PlaceholderText")
				AddColorPicker("Important", "Important")
				
				local ResetThemeFrame = Lib.Frame.new()
				ResetThemeFrame.Gui.Parent = ListFrame
				ResetThemeFrame.Gui.Transparency = 1
				ResetThemeFrame.Gui.Size = UDim2.new(1, 0, 0, 25)
				
				local ResetThemeBtn = Lib.Button.new()
				ResetThemeBtn.Text = "Reset Theme to Default"
				ResetThemeBtn.Position = UDim2.new(0, 5, 0, 2)
				ResetThemeBtn.Size = UDim2.new(1, -10, 0, 20)
				ResetThemeBtn.Gui.Parent = ResetThemeFrame.Gui
				
				ResetThemeBtn.OnClick:Connect(function()
					local rgb = Color3.fromRGB
					local defaultThemeColors = {
						Main1 = rgb(52,52,52),
						Main2 = rgb(45,45,45),
						Outline1 = rgb(33,33,33),
						Outline2 = rgb(55,55,55),
						Outline3 = rgb(30,30,30),
						TextBox = rgb(38,38,38),
						Menu = rgb(32,32,32),
						ListSelection = rgb(11,90,175),
						Button = rgb(60,60,60),
						ButtonHover = rgb(68,68,68),
						ButtonPress = rgb(40,40,40),
						Highlight = rgb(75,75,75),
						Text = rgb(255,255,255),
						PlaceholderText = rgb(100,100,100),
						Important = rgb(255,0,0)
					}
					
					local function cmp(c1, c2)
						if not c1 or not c2 then return false end
						return math.abs(c1.R - c2.R) < 0.01 and math.abs(c1.G - c2.G) < 0.01 and math.abs(c1.B - c2.B) < 0.01
					end
					
					local ThemeColorBtns = SettingsWindow.ThemeColorBtns or {}
					
					for key, btn in next, ThemeColorBtns do
						local defaultColor = defaultThemeColors[key]
						if defaultColor then
							local oldColor = Settings.Theme[key]
							if not cmp(oldColor, defaultColor) then
								btn.BackgroundColor3 = defaultColor
								Settings.Theme[key] = defaultColor
								if Main.UpdateThemeColor then 
									Main.UpdateThemeColor(oldColor, defaultColor) 
								end
							end
						end
					end
				end)
				
				local BackgroundreloadButton = Lib.Frame.new()
				BackgroundreloadButton.Gui.Parent = window.GuiElems.Content
				BackgroundreloadButton.Size = UDim2.new(1,0, 0,20)
				BackgroundreloadButton.Position = UDim2.new(0,0, 1,-20)
				
				local LabelreloadButton = Lib.Label.new()
				LabelreloadButton.Gui.Parent = window.GuiElems.Content
				LabelreloadButton.Size = UDim2.new(1,0, 0,20)
				LabelreloadButton.Position = UDim2.new(0,0, 1,-20)
				LabelreloadButton.Gui.Text = "Save Settings"
				LabelreloadButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
				
				local reloadButton = Instance.new("TextButton")
				reloadButton.Parent = BackgroundreloadButton.Gui
				reloadButton.Size = UDim2.new(1,0, 1,0)
				reloadButton.Position = UDim2.new(0,0, 0,0)
				reloadButton.Transparency = 1
				
				reloadButton.MouseButton1Click:Connect(function()
					Main.SaveCurrentSettings()
					LabelreloadButton.Gui.Text = "Saved!"
					task.wait(1.5)
					LabelreloadButton.Gui.Text = "Save Settings"
				end)
			end

			return SettingsWindow
		end

		return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
	end,

["ThreadExplorer"] = function()
--[[
	Thread Explorer App Module
	
	Actor scripts dont show up?? ALso shitsploits wont work, use ANYTHING except for xeno and solara
]]

local Main,Lib,Apps,Settings
local Explorer, Properties, ScriptViewer, ThreadExplorer, Notebook
local API,RMD,env,service,plr,create,createSimple

local function initDeps(data)
	Main, Lib, Apps, Settings = data.Main, data.Lib, data.Apps, data.Settings
	API, RMD, env, service, plr = data.API, data.RMD, data.env, data.service, data.plr
	create, createSimple = data.create, data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	ThreadExplorer = Apps.ThreadExplorer
	EnvExplorer = Apps.EnvExplorer
end

local function main()
	local ThreadExplorer = {}
	local Window, ListFrame, SearchBox, FilterBtn
	local ListItems = {}
	local ContextMenu, FilterMenu
	local CurrentRefreshId = 0
	
	ThreadExplorer.ShowNilThreads = false
	
	ThreadExplorer.Refresh = function()
		CurrentRefreshId = CurrentRefreshId + 1
		local ThisRefreshId = CurrentRefreshId

		for _, v in pairs(ListItems) do
			v.Gui:Destroy()
		end
		table.clear(ListItems)
		
		local GetReg = env.getreg or getreg or (debug and debug.getregistry)
		if not GetReg then return end
		
		local Threads = {}
		for _, v in pairs(GetReg()) do
			if type(v) == "thread" then
				table.insert(Threads, v)
			end
		end
		
		local GetScript = env.getscriptfromthread or getscriptfromthread
		
		for i, thread in next, Threads do
			if ThisRefreshId ~= CurrentRefreshId then return end
			if i % 50 == 0 then task.wait() end
			if ThisRefreshId ~= CurrentRefreshId then return end
			
			local s_scr, scr = false, nil
			if GetScript then s_scr, scr = pcall(GetScript, thread) end
			
			if not ThreadExplorer.ShowNilThreads then
				if not s_scr or typeof(scr) ~= "Instance" or not scr:IsA("LuaSourceContainer") then 
					continue 
				end
			end
			
			local s_src, src_name = pcall(debug.info, thread, 1, "s")
			local s_trc, trc = pcall(debug.traceback, thread)
			local ok, name
			if scr then ok, name = pcall(scr.GetFullName, scr) end
			local SourceName = (s_src and type(src_name) == "string" and src_name ~= "") and src_name or (ok and name ~= "" and name) or 'Nil'
			local TraceNum = (s_trc and type(trc) == "string") and trc:match(":(%d+)") or "No Traceback"
			
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 25)
			Btn.BackgroundColor3 = Settings.Theme.Main1
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false
			
			local NameLabel = Instance.new("TextLabel", Btn)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Position = UDim2.new(0, 5, 0, 0)
			NameLabel.Size = UDim2.new(0.7, -10, 1, 0)
			NameLabel.Font = Enum.Font.SourceSans
			NameLabel.TextSize = 14
			NameLabel.TextColor3 = Settings.Theme.Text
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			NameLabel.Text = SourceName
			
			local TraceLabel = Instance.new("TextLabel", Btn)
			TraceLabel.BackgroundTransparency = 1
			TraceLabel.Position = UDim2.new(0.7, 0, 0, 0)
			TraceLabel.Size = UDim2.new(0.3, -25, 1, 0)
			TraceLabel.Font = Enum.Font.SourceSans
			TraceLabel.TextSize = 13
			TraceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			TraceLabel.TextXAlignment = Enum.TextXAlignment.Right
			TraceLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TraceLabel.Text = (TraceNum ~= "No Traceback Available") and (":" .. TraceNum) or TraceNum
			
			local DotsBtn = Instance.new("ImageButton", Btn)
			DotsBtn.BackgroundTransparency = 1
			DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
			DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
			DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'
			
			Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)
			
			Btn.MouseButton1Click:Connect(function()
				if s_scr and typeof(scr) == "Instance" and scr:IsA("LuaSourceContainer") then
					ScriptViewer.ViewScript(scr)
				end
			end)
			
			DotsBtn.MouseButton1Click:Connect(function()
				local MouseX, MouseY = Main.Mouse.X, Main.Mouse.Y
				ContextMenu:Clear()
				
				local SF, F = pcall(debug.info, thread, 1, "f")

				ContextMenu:Add({Name = "Copy Full Traceback", OnClick = function() if env.setclipboard then env.setclipboard(tostring(trc)) end end})
				
				if SF and type(F) == "function" then
					ContextMenu:Add({Name = "Copy Function As Script", OnClick = function() 

-- can be improved? (eg using filtergc or getfunctionhash)

-- local hash = env.getfunctionhash(f)

env.setclipboard([[local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if tostring(v):find(str) then
                return v
            end
        end
    end
end

local func = findfunc("]] .. tostring(F) .. [[")]])

end})
				end

				if s_scr and typeof(scr) == "Instance" then
					ContextMenu:Add({Name = "Copy Script Path", OnClick = function() if env.setclipboard then env.setclipboard(Explorer.GetInstancePath(scr)) end end})
				end
				
				ContextMenu:AddDivider()
				ContextMenu:Add({Name = "Kill Thread", OnClick = function() 
					pcall(task.cancel, thread)
					ThreadExplorer.Refresh() 
				end})
				
				ContextMenu:Show(MouseX, MouseY)
			end)
			
			Btn.Parent = ListFrame
			table.insert(ListItems, {Gui = Btn, Source = SourceName, Trace = TraceNum})
		end

		if SearchBox.TextBox.Text ~= "" then
			SearchBox.TextBox.Text = SearchBox.TextBox.Text
		end
	end
	
	ThreadExplorer.Init = function()
		Window = Lib.Window.new()
		Window:SetTitle("Thread Explorer")
		Window:Resize(400, 350)
		ThreadExplorer.Window = Window
		
		ContextMenu = Lib.ContextMenu.new()
		ContextMenu.Iconless = true
		ContextMenu.Width = 200
		
		FilterMenu = Lib.ContextMenu.new()
		FilterMenu.Iconless = true
		FilterMenu.Width = 150
		
		local function BuildFilterMenu()
			FilterMenu:Clear()
			FilterMenu:Add({
				Name = ThreadExplorer.ShowNilThreads and "Hide Nil Threads" or "Show Nil Threads", 
				OnClick = function()
					ThreadExplorer.ShowNilThreads = not ThreadExplorer.ShowNilThreads
					BuildFilterMenu()
					ThreadExplorer.Refresh()
				end
			})
		end
		BuildFilterMenu()
		
		local TopBar = Instance.new("Frame", Window.GuiElems.Content)
		TopBar.Size = UDim2.new(1, 0, 0, 24)
		TopBar.BackgroundColor3 = Settings.Theme.Main2
		TopBar.BorderSizePixel = 0
		
		SearchBox = Lib.ViewportTextBox.new()
		SearchBox.Gui.Parent = TopBar
		SearchBox.Size = UDim2.new(1, -75, 1, -4)
		SearchBox.Position = UDim2.new(0, 4, 0, 2)
		SearchBox.TextBox.PlaceholderText = "Search Threads..."
		
		local RefreshBtn = Instance.new("ImageButton", TopBar)
		RefreshBtn.Size = UDim2.new(0, 18, 0, 18)
		RefreshBtn.Position = UDim2.new(1, -22, 0, 3)
		RefreshBtn.BackgroundTransparency = 1
		RefreshBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344"
		RefreshBtn.MouseButton1Click:Connect(function()
			ThreadExplorer.Refresh()
		end)
		
		FilterBtn = Instance.new("TextButton", TopBar)
		FilterBtn.Size = UDim2.new(0, 42, 0, 18)
		FilterBtn.Position = UDim2.new(1, -67, 0, 3)
		FilterBtn.BackgroundColor3 = Settings.Theme.Button
		FilterBtn.BorderSizePixel = 0
		FilterBtn.TextColor3 = Settings.Theme.Text
		FilterBtn.Font = Enum.Font.SourceSans
		FilterBtn.TextSize = 14
		FilterBtn.Text = "Filter"
		
		FilterBtn.MouseButton1Click:Connect(function()
			local MouseX, MouseY = Main.Mouse.X, Main.Mouse.Y
			FilterMenu:Show(MouseX, MouseY)
		end)
		
		ListFrame = Instance.new("ScrollingFrame", Window.GuiElems.Content)
		ListFrame.Size = UDim2.new(1, 0, 1, -24)
		ListFrame.Position = UDim2.new(0, 0, 0, 24)
		ListFrame.BackgroundTransparency = 1
		ListFrame.BorderSizePixel = 0
		ListFrame.ScrollBarThickness = 6
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		
		local ListLayout = Instance.new("UIListLayout", ListFrame)
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
		end)
		
		SearchBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local Txt = SearchBox.TextBox.Text:lower()
			for _, item in pairs(ListItems) do
				if Txt == "" or item.Source:lower():find(Txt, 1, true) or item.Trace:lower():find(Txt, 1, true) then
					item.Gui.Visible = true
				else
					item.Gui.Visible = false
				end
			end
		end)
		
		Window.OnActivate:Connect(function()
			ThreadExplorer.Refresh()
		end)
	end
	
	return ThreadExplorer
end
return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end,

["EnvExplorer"] = function()
--[[
	Environment Explorer
]]
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, EnvExplorer

local function InitDeps(Data)
	Main, Lib, Apps, Settings = Data.Main, Data.Lib, Data.Apps, Data.Settings
	env, service, plr = Data.env, Data.service, Data.plr
end

local function InitAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	EnvExplorer = Apps.EnvExplorer
end

local function MainFunc()
	local EnvExplorer = {}
	local Window, ListFrame, SearchBox, FilterBtn
	local ListItems = {}
	local ContextMenu, FilterMenu
	
	EnvExplorer.ShowTables = true
	EnvExplorer.MaxDepth = 3
	EnvExplorer.CurrentScript = nil
	
	local CurrentRefreshId = 0
	local BlockedFuncs = {}
	
	local HookWindow, HookCodeFrame
	local DepthWindow

	local function SerializeData(Data, Depth, Seen)
		Depth = Depth or 1
		Seen = Seen or {}
		local Indent = string.rep("    ", Depth)
		local PrevIndent = string.rep("    ", Depth - 1)
		
		local DataType = typeof(Data)
		
		if DataType == "string" then
			return string.format("%q", Data)
		elseif DataType == "number" or DataType == "boolean" then
			return tostring(Data)
		elseif DataType == "nil" then
			return "nil"
		elseif DataType == "Instance" then
			local Success, Path = pcall(function() return Explorer.GetInstancePath(Data) end)
			return Success and Path or "Instance"
		elseif DataType == "function" then
			local InfoSrc = pcall(debug.info, Data, "s") and debug.info(Data, "s") or ""
			local InfoLine = pcall(debug.info, Data, "l") and debug.info(Data, "l") or -1
			local InfoWhat = (InfoLine == -1) and "C" or "Lua"
			local InfoName = pcall(debug.info, Data, "n") and debug.info(Data, "n") or ""
			local InfoArity, InfoVargs = pcall(debug.info, Data, "a")
			if not InfoArity then InfoArity = 0; InfoVargs = false end
			
			return string.format("function()\n%s--[[\n%s    info = {\n%s        source = %q,\n%s        line = %d,\n%s        what = %q,\n%s        name = %q,\n%s        numparams = %d,\n%s        vargs = %s\n%s    }\n%s]]\n%send",
				Indent, Indent, Indent, InfoSrc, Indent, InfoLine, Indent, InfoWhat, Indent, InfoName, Indent, InfoArity, Indent, tostring(InfoVargs), Indent, PrevIndent)
		elseif DataType == "table" then
			if Seen[Data] then return '"*** cycle table reference detected ***"' end
			if Depth > EnvExplorer.MaxDepth then return '"<Max Depth Reached>"' end
			Seen[Data] = true
			
			local Str = "{\n"
			local Count = 0
			for k, v in pairs(Data) do
				Count = Count + 1
				local KeyStr
				if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
					KeyStr = k
				else
					KeyStr = "[" .. SerializeData(k, Depth + 1, Seen) .. "]"
				end
				Str = Str .. Indent .. KeyStr .. " = " .. SerializeData(v, Depth + 1, Seen) .. ",\n"
			end
			Seen[Data] = nil
			if Count == 0 then return "{}" end
			return Str .. PrevIndent .. "}"
		elseif DataType == "RBXScriptConnection" then
			return "(nil --[[ RBXScriptConnection | IsConnected: " .. tostring(Data.Connected) .. " ]])"
		else
			return DataType .. ".new(" .. tostring(Data) .. ")"
		end
	end
	
	EnvExplorer.Refresh = function()
		CurrentRefreshId = CurrentRefreshId + 1
		local ThisRefreshId = CurrentRefreshId
		
		for _, v in pairs(ListItems) do
			v.Gui:Destroy()
		end
		table.clear(ListItems)
		
		if not EnvExplorer.CurrentScript then return end
		local Scr = EnvExplorer.CurrentScript
		
		local FoundFuncs = {}
		local FoundTables = {}
		local Seen = {}
		local lys = os.clock()
		local frb = 0.012
		local ItemsCreated = 0

		local CurrentSearch = SearchBox.TextBox.Text:lower()

		local function CreateItem(Name, TypeNote, ObjRef, IsTable)
			if ThisRefreshId ~= CurrentRefreshId then return end

			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 25)
			Btn.BackgroundColor3 = Settings.Theme.Main1
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false
			
			local NameLabel = Instance.new("TextLabel", Btn)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Position = UDim2.new(0, 5, 0, 0)
			NameLabel.Size = UDim2.new(0.6, -10, 1, 0)
			NameLabel.Font = Enum.Font.SourceSans
			NameLabel.TextSize = 14
			NameLabel.TextColor3 = Settings.Theme.Text
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			NameLabel.Text = (Name == "" and "Anonymous") or Name
			
			local NoteLabel = Instance.new("TextLabel", Btn)
			NoteLabel.BackgroundTransparency = 1
			NoteLabel.Position = UDim2.new(0.6, 0, 0, 0)
			NoteLabel.Size = UDim2.new(0.4, -25, 1, 0)
			NoteLabel.Font = Enum.Font.SourceSans
			NoteLabel.TextSize = 13
			NoteLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			NoteLabel.TextXAlignment = Enum.TextXAlignment.Right
			NoteLabel.Text = TypeNote
			
			local DotsBtn = Instance.new("ImageButton", Btn)
			DotsBtn.BackgroundTransparency = 1
			DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
			DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
			DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'
			
			Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)
			
			Btn.MouseButton1Click:Connect(function()
				if IsTable then Lib.ViewTableDetail(ObjRef, Name) else ViewFunctionDetail(ObjRef, Name, Lib.GetHash(ObjRef)) end
			end)
			
			DotsBtn.MouseButton1Click:Connect(function()
				local MouseX, MouseY = Main.Mouse.X, Main.Mouse.Y
				ContextMenu:Clear()
				if IsTable then
					ContextMenu:Add({Name = "View Table Contents", OnClick = function() 
						Lib.ViewTableDetail(ObjRef, Name)
					end})
				else
					ContextMenu:Add({Name = "Copy Function Hash", OnClick = function()
						if env.setclipboard then env.setclipboard(Lib.GetHash(ObjRef)) end
					end})
					
					ContextMenu:Add({Name = "Copy Function as Script", OnClick = function()
						if not env.setclipboard then return end
						if string.find(TypeNote, "Global") then
							local ScrPath = Explorer.GetInstancePath(Scr)
							env.setclipboard("local func = getsenv(" .. ScrPath .. ")[\"" .. Name .. "\"]")
						else
							local Template = [[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if tostring(v):find(str) then
                return v
            end
        end
    end
end

local func = findfunc("]] .. tostring(ObjRef) .. [[")]]
							env.setclipboard(Template)
						end
					end})
					
					ContextMenu:AddDivider()
				
					ContextMenu:Add({Name = BlockedFuncs[ObjRef] and "Unblock Function" or "Block Function", OnClick = function() 
						if not BlockedFuncs[ObjRef] then
							if env.hookfunction then
								BlockedFuncs[ObjRef] = true
								env.hookfunction(ObjRef, function() return end)
							end
						else
							if env.restorefunction then
								env.restorefunction(ObjRef)
							end
							BlockedFuncs[ObjRef] = nil
						end
					end})
					
					ContextMenu:Add({Name = "Hook Function", OnClick = function() 
						local TargetPath = ""
						if string.find(TypeNote, "Global") then
							local ScrPath = Explorer.GetInstancePath(Scr)
							TargetPath = "getsenv(" .. ScrPath .. ")[\"" .. Name .. "\"]"
						else
							TargetPath = [[(function()
    for i,v in next, getgc() do
        if type(v) == 'function' and getfunctionhash(v) == ']] .. Lib.GetHash(ObjRef) .. [[' then
            return v
        end
    end
end)()]]
						end
						
						local HookTemplate = string.format([[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local TargetFunc = %s

local old; old = hookfunction(TargetFunc, function(...)
    -- Your hook logic here
    return old(...)
end)
]], TargetPath)
						HookCodeFrame:SetText(HookTemplate)
						HookWindow:Show()
					end})
					
					ContextMenu:Add({Name = "Call with Args", OnClick = function() 
						Lib.SaveAsPrompt("Arguments (e.g. 1, 'String')", function(StrArgs)
							local Success, CallFunc = pcall(loadstring, "return {" .. StrArgs .. "}")
							if Success and CallFunc then
								local Args = CallFunc()
								local Res = {pcall(ObjRef, unpack(Args))}
								local S = table.remove(Res, 1)
								
								local ResStr = ""
								for i, val in pairs(Res) do
									ResStr = ResStr .. tostring(val) .. (i < #Res and ", " or "")
								end
								if ResStr == "" then ResStr = "nil" end
								
								DetailWindow:SetTitle("Returns: " .. Name)
								DetailCodeFrame:SetText(S and "Returns:\n" .. ResStr or "Error:\n" .. tostring(Res[1]))
								DetailWindow:Show()
							end
						end)
					end})
					
					ContextMenu:Add({Name = "Get Return Values", OnClick = function() 
						local Res = {pcall(ObjRef)}
						local S = table.remove(Res, 1)
						
						local ResStr = ""
						for i, val in pairs(Res) do
							ResStr = ResStr .. tostring(val) .. (i < #Res and ", " or "")
						end
						if ResStr == "" then ResStr = "nil" end
						
						DetailWindow:SetTitle("Returns: " .. Name)
						DetailCodeFrame:SetText(S and "Returns:\n" .. ResStr or "Error:\n" .. tostring(Res[1]))
						DetailWindow:Show()
					end})
				end
				ContextMenu:Show(MouseX, MouseY)
			end)
			
			if CurrentSearch ~= "" then
				if not (Name:lower():find(CurrentSearch, 1, true) or TypeNote:lower():find(CurrentSearch, 1, true)) then
					Btn.Visible = false
				end
			end

			Btn.Parent = ListFrame
			table.insert(ListItems, {Gui = Btn, Name = Name, Note = TypeNote})

			ItemsCreated = ItemsCreated + 1
			if ItemsCreated % 30 == 0 and (os.clock() - lys) > frb then
				task.wait()
				lys = os.clock()
			end
		end
		
		if env.getsenv then
			local Success, SEnv = pcall(env.getsenv, Scr)
			if Success and type(SEnv) == "table" then
			    local Iter = 0
				for k, v in pairs(SEnv) do
				    Iter = Iter + 1
				    if Iter % 10000 == 0 then task.wait() end
				    if ThisRefreshId ~= CurrentRefreshId then return end
				    
					if type(v) == "function" and not Seen[v] then
						Seen[v] = true
						CreateItem(tostring(k), "Global Func | " .. tostring(v), v, false)
					elseif type(v) == "table" and EnvExplorer.ShowTables and not Seen[v] then
						Seen[v] = true
						CreateItem(tostring(k), "Global Table | " .. tostring(v), v, true)
					end
				end
			end
		end
		
		if env.getgc then
			local SuccessClos, Clos = pcall(getscriptclosure, Scr)
			if SuccessClos and type(Clos) == "function" and not Seen[Clos] then
			    Seen[Clos] = true
			    CreateItem(Scr.Name, "Main Closure | " .. tostring(Clos), Clos, false)
			end
			
			local ScrConstants = {}
			if SuccessClos and type(Clos) == "function" and env.getconstants then
				local SuccessConst, Consts = pcall(env.getconstants, Clos)
				if SuccessConst and Consts then
					for _, c in pairs(Consts) do
						if type(c) == "string" then ScrConstants[c] = true end
					end
				end
			end
			
			local Gc = env.getgc(true)
			for Iter, v in pairs(Gc) do
			   	Iter = Iter + 1
				if Iter % 2000 == 0 and (os.clock() - lys) > frb then
					task.wait()
					lys = os.clock()
				end
				if ThisRefreshId ~= CurrentRefreshId then return end
			    
				if type(v) == "function" and not Seen[v] and not env.isourclosure(v) then
					local SuccessInfo, Src = pcall(debug.info, v, "s")
					if SuccessInfo and Src and (Src:find(Scr.Name, 1, true) or Src:find(Scr.ClassName, 1, true)) then
						Seen[v] = true
						CreateItem(debug.info(v, "n"), "Local Func | " .. tostring(v), v, false)
					end
				elseif type(v) == "table" and EnvExplorer.ShowTables and not Seen[v] then
					local MatchesScript = false
					for CStr, _ in pairs(ScrConstants) do
						local SuccessRaw, Res = pcall(rawget, v, CStr)
						if SuccessRaw and Res ~= nil then
							MatchesScript = true
							break
						end
					end
					
					if MatchesScript then
						Seen[v] = true
						CreateItem("Table", "Local Table | " .. tostring(v), v, true)
					end
				end
			end
		end
	end
	
	EnvExplorer.ViewEnvironment = function(Scr)
		EnvExplorer.CurrentScript = Scr
		Window:SetTitle("Environment: " .. Scr.Name)
		EnvExplorer.Refresh()
		Window:Show()
	end
	
	EnvExplorer.Init = function()
		Window = Lib.Window.new()
		Window:SetTitle("Environment Explorer")
		Window:Resize(450, 400)
		EnvExplorer.Window = Window
		
		ContextMenu = Lib.ContextMenu.new()
		ContextMenu.Iconless = true
		ContextMenu.Width = 200
		
		FilterMenu = Lib.ContextMenu.new()
		FilterMenu.Iconless = true
		FilterMenu.Width = 150
		
		local function BuildFilterMenu()
			FilterMenu:Clear()
			FilterMenu:Add({
				Name = EnvExplorer.ShowTables and "Hide Tables" or "Show Tables", 
				OnClick = function()
					EnvExplorer.ShowTables = not EnvExplorer.ShowTables
					BuildFilterMenu()
					EnvExplorer.Refresh()
				end
			})
			FilterMenu:Add({
				Name = "Set Depth Limit ("..EnvExplorer.MaxDepth..")", 
				OnClick = function()
				    DepthWindow.Elements.DepthInput:SetText(tostring(EnvExplorer.MaxDepth))
				    DepthWindow:Show()
				end
			})
		end
		BuildFilterMenu()
		
		DepthWindow = Lib.Window.new()
		DepthWindow.Alignable = false
		DepthWindow.Resizable = false
		DepthWindow:SetTitle("Set Max Depth")
		DepthWindow:SetSize(250, 95)
		
		local DepthLabel = Lib.Label.new()
		DepthLabel.Text = "Depth:"
		DepthLabel.Position = UDim2.new(0, 10, 0, 10)
		DepthLabel.Size = UDim2.new(0, 50, 0, 20)
		DepthWindow:Add(DepthLabel)
		
		local DepthInput = Lib.ViewportTextBox.new()
		DepthInput.Position = UDim2.new(0, 60, 0, 10)
		DepthInput.Size = UDim2.new(1, -70, 0, 20)
		DepthWindow:Add(DepthInput, "DepthInput")
		
		local DepthSave = Lib.Button.new()
		DepthSave.Text = "Set"
		DepthSave.Position = UDim2.new(0, 5, 1, -25)
		DepthSave.Size = UDim2.new(1, -10, 0, 20)
		DepthSave.OnClick:Connect(function()
			local Num = tonumber(DepthInput:GetText())
			if Num then 
			    EnvExplorer.MaxDepth = Num 
			    BuildFilterMenu()
			    DepthWindow:Hide()
			end
		end)
		DepthWindow:Add(DepthSave)
		
		HookWindow = Lib.Window.new()
		HookWindow:SetTitle("Hook Editor")
		HookWindow:Resize(450, 400)
		
		HookCodeFrame = Lib.CodeFrame.new()
		HookCodeFrame.Frame.Position = UDim2.new(0, 0, 0, 0)
		HookCodeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
		HookCodeFrame.Frame.Parent = HookWindow.GuiElems.Content
		HookCodeFrame.Editable = true

		local HookCopyBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookCopyBtn.Size = UDim2.new(0.5, 0, 0, 20)
		HookCopyBtn.Position = UDim2.new(0, 0, 1, -20)
		HookCopyBtn.BackgroundColor3 = Settings.Theme.Main2
		HookCopyBtn.BorderSizePixel = 0
		HookCopyBtn.Text = "Copy to Clipboard"
		HookCopyBtn.TextColor3 = Color3.new(1, 1, 1)

		HookCopyBtn.MouseButton1Click:Connect(function()
			if env.setclipboard then env.setclipboard(HookCodeFrame:GetText()) end
		end)
		
		local HookExecuteBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookExecuteBtn.Size = UDim2.new(1, 0, 0, 20)
		HookExecuteBtn.Position = UDim2.new(0, 0, 1, -20)
		HookExecuteBtn.BackgroundColor3 = Settings.Theme.Button
		HookExecuteBtn.BorderSizePixel = 0
		HookExecuteBtn.Text = "Execute"
		HookExecuteBtn.TextColor3 = Color3.new(1, 1, 1)
		HookExecuteBtn.MouseButton1Click:Connect(function()
			if env.loadstring then env.loadstring(HookCodeFrame:GetText(), "DEX")() end
		end)
		
		local TopBar = Instance.new("Frame", Window.GuiElems.Content)
		TopBar.Size = UDim2.new(1, 0, 0, 24)
		TopBar.BackgroundColor3 = Settings.Theme.Main2
		TopBar.BorderSizePixel = 0
		
		SearchBox = Lib.ViewportTextBox.new()
		SearchBox.Gui.Parent = TopBar
		SearchBox.Size = UDim2.new(1, -75, 1, -4)
		SearchBox.Position = UDim2.new(0, 4, 0, 2)
		SearchBox.TextBox.PlaceholderText = "Search Functions & Tables..."
		
		local RefreshBtn = Instance.new("ImageButton", TopBar)
		RefreshBtn.Size = UDim2.new(0, 18, 0, 18)
		RefreshBtn.Position = UDim2.new(1, -22, 0, 3)
		RefreshBtn.BackgroundTransparency = 1
		RefreshBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344"
		RefreshBtn.MouseButton1Click:Connect(function()
			EnvExplorer.Refresh()
		end)
		
		FilterBtn = Instance.new("TextButton", TopBar)
		FilterBtn.Size = UDim2.new(0, 42, 0, 18)
		FilterBtn.Position = UDim2.new(1, -67, 0, 3)
		FilterBtn.BackgroundColor3 = Settings.Theme.Button
		FilterBtn.BorderSizePixel = 0
		FilterBtn.TextColor3 = Settings.Theme.Text
		FilterBtn.Font = Enum.Font.SourceSans
		FilterBtn.TextSize = 14
		FilterBtn.Text = "Filter"
		
		FilterBtn.MouseButton1Click:Connect(function()
			local MouseX, MouseY = Main.Mouse.X, Main.Mouse.Y
			FilterMenu:Show(MouseX, MouseY)
		end)
		
		ListFrame = Instance.new("ScrollingFrame", Window.GuiElems.Content)
		ListFrame.Size = UDim2.new(1, 0, 1, -24)
		ListFrame.Position = UDim2.new(0, 0, 0, 24)
		ListFrame.BackgroundTransparency = 1
		ListFrame.BorderSizePixel = 0
		ListFrame.ScrollBarThickness = 6
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
		
		local ListLayout = Instance.new("UIListLayout", ListFrame)
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
		end)
		
		SearchBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local Txt = SearchBox.TextBox.Text:lower()
			for _, Item in pairs(ListItems) do
				if Txt == "" or Item.Name:lower():find(Txt, 1, true) or Item.Note:lower():find(Txt, 1, true) then
					Item.Gui.Visible = true
				else
					Item.Gui.Visible = false
				end
			end
		end)
	end
	
	return EnvExplorer
end
return {InitDeps = InitDeps, InitAfterMain = InitAfterMain, Main = MainFunc}
end,

["DataExplorer"] = function()
--[[
	Data Explorer App Module
]]
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, EnvExplorer, DataExplorer

local function InitDeps(Data)
	Main, Lib, Apps, Settings = Data.Main, Data.Lib, Data.Apps, Data.Settings
	env, service, plr = Data.env, Data.service, Data.plr
end

local function InitAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	EnvExplorer = Apps.EnvExplorer
	DataExplorer = Apps.DataExplorer
	DebugExplorer = Apps.DebugExplorer
end

local function SafeGetScriptFromClosure(Fn)
	local Ok, EnvVal = pcall(env.getsenv or getsenv, Fn)
	if not Ok or type(EnvVal) ~= "table" then return nil end

	local Script = rawget(EnvVal, "script")
	if typeof(Script) == "Instance" and Script:IsA("LuaSourceContainer") then
		return Script
	end
	return nil
end

local function MainFunc()
	local DataExplorer = {}
	local Window, ListFrame, SearchBox, FilterBtn
	local FuncContextMenu, TableContextMenu, ValueContextMenu
	
	DataExplorer.Filters = {
		Constants = true,
		Upvalues = true,
		Protos = true,
		Functions = true,
		Tables = true,
		Globals = false
	}
	DataExplorer.MaxDepth = 3
	DataExplorer.CurrentResults = {}
	DataExplorer.SelectedResult = nil
	DataExplorer.SelectedMatch = nil

	local BlockedFuncs = {}

	local function RenderResults()
		for _, Child in next, ListFrame:GetChildren() do
			if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
				Child:Destroy()
			end
		end

		local function SetupLongPress(Btn, Callback)
			Btn.MouseButton2Click:Connect(Callback)
			local Holding = false
			local PressPos = nil
			Btn.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
					Holding = true
					PressPos = Input.Position
					task.delay(0.5, function()
						if Holding then
							Holding = false
							Callback()
						end
					end)
				end
			end)
			Btn.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
					Holding = false
				end
			end)
			Btn.InputChanged:Connect(function(Input)
				if Holding and (Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseMovement) then
					if PressPos and (Input.Position - PressPos).Magnitude > 10 then
						Holding = false
					end
				end
			end)
		end

		local function GetScriptFromFunction(Func)
			if type(Func) ~= "function" then return nil end

			local Ok, EnvVal = pcall(getfenv, Func)
			if Ok and type(EnvVal) == "table" then
				local S = rawget(EnvVal, "script")
				if typeof(S) == "Instance" and S:IsA("LuaSourceContainer") then
					return S
				end
				
				local FoundScript = nil
				pcall(function()
					local Count = 0
					for K, V in next, EnvVal do
						if typeof(V) == "Instance" and V:IsA("LuaSourceContainer") then
							FoundScript = V
							break
						end
						Count = Count + 1
						if Count >= 64 then break end
					end
				end)
				if FoundScript then return FoundScript end
			end
			
			local Ok2, Source = pcall(debug.info, Func, "s")
			if Ok2 and type(Source) == "string" and Source ~= "" then
				local CleanSource = Source:gsub("^[=@]", "")
				if nodes and env.getscripts then
					for Inst, _ in next, env.getscripts() do
						if typeof(Inst) == "Instance" and Inst:IsA("LuaSourceContainer") then
							local SName = Inst.Name
							if SName ~= "" and string.find(CleanSource, SName, 1, true) then
								return Inst
							end
						end
					end
				end
			end
			
			return nil
		end

		for _, Result in next, DataExplorer.CurrentResults do
			local MainBox = Instance.new("Frame")
			MainBox.BackgroundColor3 = Settings.Theme.Main1
			MainBox.BorderSizePixel = 0
			MainBox.Size = UDim2.new(1, 0, 0, 0)
			MainBox.AutomaticSize = Enum.AutomaticSize.Y
			MainBox.Parent = ListFrame

			local MainLayout = Instance.new("UIListLayout", MainBox)
			MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
			MainLayout.Padding = UDim.new(0, 2)

			local HeaderBtn = Instance.new("TextButton", MainBox)
			HeaderBtn.Size = UDim2.new(1, 0, 0, 25)
			HeaderBtn.BackgroundColor3 = Settings.Theme.Main2
			HeaderBtn.BorderSizePixel = 0
			HeaderBtn.Text = "  " .. tostring(Result.Name) .. " [" .. Result.Type .. "]"
			HeaderBtn.TextColor3 = Settings.Theme.Text
			HeaderBtn.Font = Enum.Font.SourceSansBold
			HeaderBtn.TextSize = 14
			HeaderBtn.TextXAlignment = Enum.TextXAlignment.Left
			HeaderBtn.AutoButtonColor = false

			HeaderBtn.MouseButton1Click:Connect(function()
				if Result.Type == "Function" then
					Lib.ViewFunctionDetail(Result.Ref, Result.Name, Lib.GetHash(Result.Ref))
				else
					Lib.ViewTableDetail(Result.Ref, Result.Name)
				end
			end)

			SetupLongPress(HeaderBtn, function()
				DataExplorer.SelectedResult = Result
				if Result.Type == "Function" then
					FuncContextMenu:Clear()
					
					FuncContextMenu:Add({Name = "Copy Function as Script", OnClick = function()
						if not env.setclipboard then return end
						local Target = DataExplorer.SelectedResult.Ref
						local Template = [[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if tostring(v):find(str) then
                return v
            end
        end
    end
end

local func = findfunc("]] .. tostring(Target) .. [[")]]
						env.setclipboard(Template)
					end})
					
					FuncContextMenu:Add({Name = "Copy Function Hash", OnClick = function()
						if env.setclipboard then env.setclipboard(Lib.GetHash(DataExplorer.SelectedResult.Ref)) end
					end})
					
					FuncContextMenu:Add({Name = "View Script", OnClick = function()
						local Scr = DataExplorer.SelectedResult.Script or GetScriptFromFunction(DataExplorer.SelectedResult.Ref)
						if Scr then 
							ScriptViewer.ViewScript(Scr) 
						else 
							if not Lib.DetailWindow then
								Lib.ViewTableDetail({}, "Notice")
							end
							Lib.DetailWindow:SetTitle("Notice")
							Lib.DetailCodeFrame:SetText("-- Couldn't find script.")
							Lib.DetailWindow:Show()
						end
					end})
					
					local IsBlocked = BlockedFuncs[Result.Ref]
					FuncContextMenu:Add({Name = IsBlocked and "Unblock" or "Block", OnClick = function()
						local Target = DataExplorer.SelectedResult.Ref
						if BlockedFuncs[Target] then
							if env.restorefunction then env.restorefunction(Target) end
							BlockedFuncs[Target] = nil
						else
							if env.hookfunction then
								BlockedFuncs[Target] = true
								env.hookfunction(Target, function() end)
							end
						end
					end})

					if env.getfunctionbytecode then
						FuncContextMenu:AddDivider()
						
						FuncContextMenu:Add({Name = "View Decompiled Function", OnClick = function()
							local Target = DataExplorer.SelectedResult.Ref
							task.spawn(function()
								local Success, Bytecode = pcall(env.getfunctionbytecode, Target)
								if not Success or not Bytecode then
									warn("Failed to get function bytecode: " .. tostring(Bytecode))
									return
								end
								
								local DecompileSuccess, Decompiled = pcall(env.decompile, Bytecode)
								if not DecompileSuccess or not Decompiled then
									Decompiled = "-- Decompilation failed: " .. tostring(Decompiled)
								end

								local d = Instance.new("LocalScript")
								d.Name = "Decompiled_" .. (Result.Name ~= "" and Result.Name or "Anonymous")
								ScriptViewer.EditedScriptsCache[d] = Decompiled
								ScriptViewer.ViewScript(d)
							end)
						end})
						
						FuncContextMenu:Add({Name = "Save Function Bytecode", OnClick = function()
							local Target = DataExplorer.SelectedResult.Ref
							task.spawn(function()
								local Success, Bytecode = pcall(env.getfunctionbytecode, Target)
								if Success and Bytecode then
									local Hash = Lib.GetHash(Target)
									local FileName = "func_" .. Hash .. "_bytecode.txt"
									Lib.SaveAsPrompt(FileName, Bytecode)
								else
									warn("Failed to get function bytecode: " .. tostring(Bytecode))
								end
							end)
						end})
					end
					
					FuncContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				else
					TableContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end
			end)

			local MatchesContainer = Instance.new("Frame", MainBox)
			MatchesContainer.BackgroundTransparency = 1
			MatchesContainer.Size = UDim2.new(1.0355, -20, 0, 0)
			MatchesContainer.Position = UDim2.new(0, 20, 0, 0)
			MatchesContainer.AutomaticSize = Enum.AutomaticSize.Y

			local Jj = Instance.new("UIPadding", MatchesContainer)
			Jj.PaddingLeft = UDim.new(0, 2)

			local MatchLayout = Instance.new("UIListLayout", MatchesContainer)
			MatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
			MatchLayout.Padding = UDim.new(0, 2)

			for _, Match in next, Result.Matches do
				local MatchBtn = Instance.new("TextButton", MatchesContainer)
				MatchBtn.Size = UDim2.new(1, 0, 0, 22)
				MatchBtn.BackgroundColor3 = Settings.Theme.Button
				MatchBtn.BorderSizePixel = 0
				MatchBtn.TextColor3 = Settings.Theme.Text
				MatchBtn.Font = Enum.Font.SourceSans
				MatchBtn.TextSize = 13
				MatchBtn.TextXAlignment = Enum.TextXAlignment.Left
				MatchBtn.AutoButtonColor = false
				MatchBtn.TextTruncate = Enum.TextTruncate.AtEnd
				MatchBtn.ClipsDescendants = true
				
				local DisplayVal = tostring(Match.Value)
				if #DisplayVal > 10000 then
					DisplayVal = string.sub(DisplayVal, 1, 10000) .. "..."
				end
				DisplayVal = string.gsub(DisplayVal, "[\n\r]", "\\n")
				
				local DisplayName = Match.ValueName and ("[" .. tostring(Match.ValueName) .. "] ") or ""
				pcall(function()
					MatchBtn.Text = "    " .. DisplayVal .. " " .. DisplayName .. "(" .. Match.ValueType .. ") - " .. Match.LocationType .. " " .. tostring(Match.Index)
				end)

				MatchBtn.MouseEnter:Connect(function() MatchBtn.BackgroundColor3 = Settings.Theme.ButtonHover end)
				MatchBtn.MouseLeave:Connect(function() MatchBtn.BackgroundColor3 = Settings.Theme.Button end)
				
				MatchBtn.MouseButton1Click:Connect(function()
					if Match.ValueType == "function" then
						Lib.ViewFunctionDetail(Match.Value, Match.ValueName or "Match", Lib.GetHash(Match.Value))
					elseif Match.ValueType == "table" then
						Lib.ViewTableDetail(Match.Value, Match.ValueName or "Match")
					elseif Match.ValueType == "number" or Match.ValueType == "string" or Match.ValueType == "boolean" or Match.ValueType == "CFrame" or Match.ValueType == "Vector3" then
						if Result.Type == "Function" then
							Lib.ViewFunctionDetail(Result.Ref, Result.Name, Lib.GetHash(Result.Ref))
						else
							Lib.ViewTableDetail(Result.Ref, Result.Name)
						end
					else
						DetailWindow:SetTitle("Notice")
						DetailCodeFrame:SetText("-- Unsupported Type for Detailed View: " .. Match.ValueType .. "\n-- Please view the parent container instead.")
						DetailWindow:Show()
					end
				end)

				SetupLongPress(MatchBtn, function()
					DataExplorer.SelectedResult = Result
					DataExplorer.SelectedMatch = Match
					ValueContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end)
			end
			
			local Pad = Instance.new("Frame", MainBox)
			Pad.BackgroundTransparency = 1
			Pad.Size = UDim2.new(1, 0, 0, 2)
		end
	end

	local CurrentRefreshId = 0
	DataExplorer.Refresh = function()
		local QueryStr = SearchBox.TextBox.Text
		local QueryNum = tonumber(QueryStr)
		local F = DataExplorer.Filters
		
		CurrentRefreshId = CurrentRefreshId + 1
		local ThisRefreshId = CurrentRefreshId
		
		DataExplorer.CurrentResults = {}
		
		for _, Child in next, ListFrame:GetChildren() do
			if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
				Child:Destroy()
			end
		end
		
		local function CompareValue(Val)
			local ValType = typeof(Val)
			if ValType == "string" then
				return string.find(string.lower(Val), string.lower(QueryStr), 1, true) ~= nil
			elseif ValType == "number" and QueryNum then
				return Val == QueryNum
			elseif ValType == "boolean" then
				return tostring(Val) == string.lower(QueryStr)
			end
			return false
		end

		local function ScanTable(Tbl, Depth, Seen, Matches, IgnoreSearch)
			if Depth > DataExplorer.MaxDepth then return end
			if Seen[Tbl] then return end
			Seen[Tbl] = true

			for k, v in next, Tbl do
				if ThisRefreshId ~= CurrentRefreshId then return end
				
				if IgnoreSearch or CompareValue(v) or CompareValue(k) then
					table.insert(Matches, {
						LocationType = "Table Index", Index = tostring(k), ValueName = tostring(k), Value = v, ValueType = typeof(v)
					})
				end
				
				if type(v) == "table" then
					ScanTable(v, Depth + 1, Seen, Matches, IgnoreSearch)
				end
			end
		end

		task.spawn(function()
			if F.Globals then
				local Renv = env.getrenv and env.getrenv() or _G
				local GlobalSources = {
					{Name = "_G", Ref = Renv._G or _G},
					{Name = "shared", Ref = Renv.shared or shared}
				}
				
				for _, Source in next, GlobalSources do
					if type(Source.Ref) == "table" then
						local PrimitiveMatches = {}
						
						for k, v in next, Source.Ref do
							if ThisRefreshId ~= CurrentRefreshId then return end
							
							local vType = type(v)
							if vType == "function" then
								table.insert(DataExplorer.CurrentResults, {
									Type = "Function",
									Name = Source.Name .. "." .. tostring(k),
									Ref = v,
									Script = nil,
									Matches = {}
								})
							elseif vType == "table" then
								local TblMatches = {}
								ScanTable(v, 1, {}, TblMatches, true)
								table.insert(DataExplorer.CurrentResults, {
									Type = "Table",
									Name = Source.Name .. "." .. tostring(k),
									Ref = v,
									Script = nil,
									Matches = TblMatches
								})
							else
								table.insert(PrimitiveMatches, {
									LocationType = "Table Index",
									Index = tostring(k),
									ValueName = tostring(k),
									Value = v,
									ValueType = typeof(v)
								})
							end
						end
						
						if #PrimitiveMatches > 0 then
							table.insert(DataExplorer.CurrentResults, {
								Type = "Table",
								Name = Source.Name .. " (Primitives)",
								Ref = Source.Ref,
								Script = nil,
								Matches = PrimitiveMatches
							})
						end
					end
				end
			else
				if QueryStr == "" then return end
				
				local Gc = env.getgc and env.getgc(true) or {}
				local SeenTables = {}
				
				local SkipTables = {
					[Main] = true, [Lib] = true, [Apps] = true, [Settings] = true,
					[Explorer] = true, [Properties] = true, [ScriptViewer] = true, [DataExplorer] = true,
					[_G] = true, [shared] = true
				}
				if env.getgenv then pcall(function() SkipTables[env.getgenv()] = true end) end
				if env.getrenv then pcall(function() SkipTables[env.getrenv()] = true end) end

				local function ISDexTable(T)
					if SkipTables[T] then return true end
					local S, Res = pcall(function()
						if rawget(T, "InsertObjectContext") or rawget(T, "GuiElems") or rawget(T, "InitAfterMain") or rawget(T, "AppControls") then return true end
						return false
					end)
					return S and Res
				end

				local HexMatch = QueryStr:lower():match("0x%x+")
				local QueryHash = QueryStr
				
				for Iter, Obj in next, Gc do
					if Iter % 900000 == 0 then task.wait() end
					if ThisRefreshId ~= CurrentRefreshId then return end
					
					local ObjType = type(Obj)
					if ObjType == "table" and ISDexTable(Obj) then continue end
					if ObjType == "function" then
						local Matches = {}
						local HasMatch = false
						local IsCClos = env.iscclosure and env.iscclosure(Obj)
local Isour = env.isourclosure and env.isourclosure(Obj)

local ObjStr = tostring(Obj):lower()
local ObjHash = ""

if env.getfunctionhash and not IsCClos then
	local S, Hash = pcall(env.getfunctionhash, Obj)
	if S and type(Hash) == "string" then
		ObjHash = Hash
	end
end

if HexMatch and ObjStr:find(HexMatch, 1, true) then
    HasMatch = true
    table.insert(Matches, {LocationType = "Function Address", Index = 0, ValueName = "Address", Value = tostring(Obj), ValueType = "string"})
elseif QueryHash ~= "" and (ObjHash == QueryHash or ObjHash:lower() == QueryHash:lower()) then
    HasMatch = true
    table.insert(Matches, {LocationType = "Function Hash", Index = 0, ValueName = "Hash", Value = ObjHash, ValueType = "string"})
end

if F.Functions and not HasMatch then
    local S, NInfo = pcall(debug.info, Obj, "n")
    if S and NInfo and NInfo ~= "" and CompareValue(NInfo) then
        HasMatch = true
        table.insert(Matches, {LocationType = "Function Name", Index = 0, ValueName = "Name", Value = NInfo, ValueType = "string"})
    end
end
						
						if F.Constants and env.getconstants and not IsCClos and not Isour then
							local S, Consts = pcall(env.getconstants, Obj)
							if S and Consts then
								for Idx, Val in next, Consts do
									if CompareValue(Val) then
										HasMatch = true
										table.insert(Matches, {LocationType = "Constant", Index = Idx, ValueName = "Const_" .. Idx, Value = Val, ValueType = typeof(Val)})
									end
								end
							end
						end
						
						if F.Upvalues and env.getupvalues and not IsCClos and not Isour then
							local S, Upvals = pcall(env.getupvalues, Obj)
							if S and Upvals then
								for Idx, Val in next, Upvals do
									if CompareValue(Val) then
										HasMatch = true
										table.insert(Matches, {LocationType = "Upvalue", Index = Idx, ValueName = "Upv_" .. Idx, Value = Val, ValueType = typeof(Val)})
									end
									if F.Tables and type(Val) == "table" then
										local TblMatches = {}
										ScanTable(Val, 1, SeenTables, TblMatches, false)
										for _, Tm in next, TblMatches do
											HasMatch = true
											table.insert(Matches, {
												LocationType = "Upvalue Table ["..Idx.."] -> " .. Tm.LocationType, 
												Index = Tm.Index, 
												ValueName = Tm.ValueName, 
												Value = Tm.Value, 
												ValueType = Tm.ValueType, 
												RootIndex = Idx,
												TableRef = Val
											})
										end
									end
								end
							end
						end
						
						if F.Protos and env.getprotos and not IsCClos and not Isour then
							local S, Protos = pcall(env.getprotos, Obj)
							if S and Protos then
								for Idx, Proto in next, Protos do
									local S2, PName = pcall(debug.info, Proto, "n")
									if S2 and PName and PName ~= "" and CompareValue(PName) then
										HasMatch = true
										table.insert(Matches, {LocationType = "Proto", Index = Idx, ValueName = "Proto_" .. Idx, Value = PName, ValueType = "function"})
									end
								end
							end
						end
						
						if HasMatch then
							local S_scr, Scr = pcall(SafeGetScriptFromClosure, Obj)
							local S_n, N = pcall(debug.info, Obj, "n")
							table.insert(DataExplorer.CurrentResults, {Type = "Function", Name = ((S_n and N ~= "") and N or "Anonymous"), Ref = Obj, Script = S_scr and Scr or nil, Matches = Matches})
						end
						
					elseif ObjType == "table" and F.Tables then
						local Matches = {}
						ScanTable(Obj, 1, SeenTables, Matches, false)
						if #Matches > 0 then
							table.insert(DataExplorer.CurrentResults, {Type = "Table", Name = tostring(Obj), Ref = Obj, Script = nil, Matches = Matches})
						end
					end
				end
			end
			
			if ThisRefreshId == CurrentRefreshId then
				RenderResults()
			end
		end)
	end

	DataExplorer.Init = function()
		Window = Lib.Window.new()
		Window:SetTitle("Data Explorer")
		Window:Resize(500, 450)
		DataExplorer.Window = Window

		FuncContextMenu = Lib.ContextMenu.new()
		FuncContextMenu.Iconless = true
		FuncContextMenu.Width = 200
		
		TableContextMenu = Lib.ContextMenu.new()
		TableContextMenu.Iconless = true
		TableContextMenu.Width = 200
		
		ValueContextMenu = Lib.ContextMenu.new()
		ValueContextMenu.Iconless = true
		ValueContextMenu.Width = 200

		FuncContextMenu:Add({Name = "Copy Function as Script", OnClick = function() 
			if not env.setclipboard then return end
			local Target = DataExplorer.SelectedResult.Ref
			local Template = [[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if tostring(v):find(str) then
                return v
            end
        end
    end
end

local func = findfunc("]] .. tostring(Target) .. [[")]]
			env.setclipboard(Template)
		end})
		
		FuncContextMenu:Add({Name = "Copy Function Hash", OnClick = function() 
			if env.setclipboard then env.setclipboard(Lib.GetHash(DataExplorer.SelectedResult.Ref)) end
		end})
		
		local function GetScriptFromFunction(Func)
			if type(Func) ~= "function" then return nil end

			local Ok, EnvVal = pcall(getfenv, Func)
			if Ok and type(EnvVal) == "table" then
				local S = rawget(EnvVal, "script")
				if typeof(S) == "Instance" and S:IsA("LuaSourceContainer") then
					return S
				end
				
				local FoundScript = nil
				pcall(function()
					local Count = 0
					for K, V in next, EnvVal do
						if typeof(V) == "Instance" and V:IsA("LuaSourceContainer") then
							FoundScript = V
							break
						end
						Count = Count + 1
						if Count >= 64 then break end
					end
				end)
				if FoundScript then return FoundScript end
			end
			
			local Ok2, Source = pcall(debug.info, Func, "s")
			if Ok2 and type(Source) == "string" and Source ~= "" then
				local CleanSource = Source:gsub("^[=@]", "")
				if nodes and env.getscripts then
					for Inst, _ in next, env.getscripts() do
						if typeof(Inst) == "Instance" and Inst:IsA("LuaSourceContainer") then
							local SName = Inst.Name
							if SName ~= "" and string.find(CleanSource, SName, 1, true) then
								return Inst
							end
						end
					end
				end
			end
			
			return nil
		end

		FuncContextMenu:Add({Name = "View Script", OnClick = function()
						local Scr = DataExplorer.SelectedResult.Script or GetScriptFromFunction(DataExplorer.SelectedResult.Ref)
						if Scr then 
							ScriptViewer.ViewScript(Scr) 
						else 
							if not Lib.DetailWindow then
								Lib.ViewTableDetail({}, "Notice")
							end
							Lib.DetailWindow:SetTitle("Notice")
							Lib.DetailCodeFrame:SetText("-- Couldn't find script.")
							Lib.DetailWindow:Show()
						end
					end})
		
		FuncContextMenu:Add({Name = "Block", OnClick = function() 
			local Target = DataExplorer.SelectedResult.Ref
			if BlockedFuncs[Target] then
				if env.restorefunction then env.restorefunction(Target) end
				BlockedFuncs[Target] = nil
			else
				if env.hookfunction then
					BlockedFuncs[Target] = true
					env.hookfunction(Target, function() end)
				end
			end
		end})

		TableContextMenu:Add({Name = "Copy Table as Script", OnClick = function() 
			if not env.setclipboard then return end
			local Target = DataExplorer.SelectedResult.Ref
			local Template = [[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local function findtable()
    for i,v in next, getgc() do
        if type(v) == 'table' and tostring(v) == ']] .. tostring(Target) .. [[' then
            return v
        end
    end
end

local tbl = findtable()]]
			env.setclipboard(Template)
		end})

		ValueContextMenu:Add({Name = "Modify Value", OnClick = function() 
			local Match = DataExplorer.SelectedMatch
			local Result = DataExplorer.SelectedResult
			
			Lib.ShowModifyValueDialog(Match, function(SelectedType, RawInput)
				local ParsedVal = Lib.ParseToType(SelectedType, RawInput)
				
				if Match.LocationType == "Constant" then
					if env.setconstant then pcall(env.setconstant, Result.Ref, tonumber(Match.Index), ParsedVal) end
				elseif Match.LocationType == "Upvalue" then
					if env.setupvalue then pcall(env.setupvalue, Result.Ref, tonumber(Match.Index), ParsedVal) end
				elseif string.find(Match.LocationType, "Upvalue Table") or Match.LocationType == "Table Index" then
					local Idx = Match.Index
					if tonumber(Idx) then Idx = tonumber(Idx) end
					if env.getgc then
						local Gc = env.getgc(true)
						for _, V in next, Gc do
							if type(V) == "table" and rawget(V, Idx) ~= nil then
								pcall(rawset, V, Idx, ParsedVal)
							end
						end
					else
						local TargetTbl = Match.TableRef or Result.Ref
						if type(TargetTbl) == "table" then
							pcall(rawset, TargetTbl, Idx, ParsedVal)
						end
					end
				end
				DataExplorer.Refresh()
			end)
		end})
		
		ValueContextMenu:Add({Name = "Generate Script", OnClick = function() 
			if not env.setclipboard then return end
			local Match = DataExplorer.SelectedMatch
			local Result = DataExplorer.SelectedResult
			local Template = ""
			
			if Match.LocationType == "Table Index" or string.find(Match.LocationType, "Upvalue Table") then
				local IdxStr = tonumber(Match.Index) and Match.Index or "'" .. Match.Index .. "'"
				Template = [[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local function modifytable()
    for i,v in next, getgc(true) do
        if type(v) == 'table' and rawget(v, ]] .. IdxStr .. [[) ~= nil then
            rawset(v, ]] .. IdxStr .. [[, NEW_VALUE_HERE)
        end
    end
end

modifytable()]]
			elseif Result.Type == "Function" then
				Template = [[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' and getfunctionhash(v) == str then
            return v
        end
    end
end

local func = findfunc("]] .. env.getfunctionhash(Result.Ref) .. [[")
]]
				if Match.LocationType == "Constant" then
					Template = Template .. "debug.setconstant(func, " .. Match.Index .. ", NEW_VALUE_HERE)"
				elseif Match.LocationType == "Upvalue" then
					Template = Template .. "debug.setupvalue(func, " .. Match.Index .. ", NEW_VALUE_HERE)"
				end
			end
			env.setclipboard(Template)
		end})

		local FilterMenu = Lib.ContextMenu.new()
		FilterMenu.Iconless = true
		FilterMenu.Width = 190

		local function BuildFilterMenu()
			FilterMenu:Clear()
			local F = DataExplorer.Filters
			local GlobalsActive = F.Globals

			FilterMenu:Add({
				Name = (GlobalsActive and "[X] " or "[ ] ") .. "Show _G / Shared",
				OnClick = function()
					F.Globals = not F.Globals
					BuildFilterMenu()
					if F.Globals then DataExplorer.Refresh() end
				end
			})
			FilterMenu:AddDivider()
			FilterMenu:Add({
				Name = (F.Constants and "[X] " or "[ ] ") .. "Scan Constants",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Constants = not F.Constants; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Upvalues and "[X] " or "[ ] ") .. "Scan Upvalues",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Upvalues = not F.Upvalues; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Protos and "[X] " or "[ ] ") .. "Scan Protos",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Protos = not F.Protos; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Functions and "[X] " or "[ ] ") .. "Functions / Name",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Functions = not F.Functions; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Tables and "[X] " or "[ ] ") .. "Tables",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Tables = not F.Tables; BuildFilterMenu() end end
			})
			FilterMenu:AddDivider()
			FilterMenu:Add({
				Name = "Set Depth Limit (" .. DataExplorer.MaxDepth .. ")",
				OnClick = function()
					Lib.ShowInputPrompt("Set Depth Limit", DataExplorer.MaxDepth, function(StrVal)
						local Num = tonumber(StrVal)
						if Num then 
							DataExplorer.MaxDepth = Num 
							BuildFilterMenu()
						end
					end)
				end
			})
		end
		BuildFilterMenu()

		local TopBar = Instance.new("Frame", Window.GuiElems.Content)
		TopBar.Size = UDim2.new(1, 0, 0, 24)
		TopBar.BackgroundColor3 = Settings.Theme.Main2
		TopBar.BorderSizePixel = 0

		SearchBox = Lib.ViewportTextBox.new()
		SearchBox.Gui.Parent = TopBar
		SearchBox.Size = UDim2.new(1, -75, 1, -4)
		SearchBox.Position = UDim2.new(0, 4, 0, 2)
		SearchBox.TextBox.PlaceholderText = "Search for something... (or function hash/adress/name)"

		local RefreshBtn = Instance.new("ImageButton", TopBar)
		RefreshBtn.Size = UDim2.new(0, 18, 0, 18)
		RefreshBtn.Position = UDim2.new(1, -22, 0, 3)
		RefreshBtn.BackgroundTransparency = 1
		RefreshBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344"
		RefreshBtn.MouseButton1Click:Connect(DataExplorer.Refresh)

		FilterBtn = Instance.new("TextButton", TopBar)
		FilterBtn.Size = UDim2.new(0, 42, 0, 18)
		FilterBtn.Position = UDim2.new(1, -67, 0, 3)
		FilterBtn.BackgroundColor3 = Settings.Theme.Button
		FilterBtn.BorderSizePixel = 0
		FilterBtn.TextColor3 = Settings.Theme.Text
		FilterBtn.Font = Enum.Font.SourceSans
		FilterBtn.TextSize = 14
		FilterBtn.Text = "Filter"
		FilterBtn.MouseButton1Click:Connect(function()
			FilterMenu:Show(Main.Mouse.X, Main.Mouse.Y)
		end)

		ListFrame = Instance.new("ScrollingFrame", Window.GuiElems.Content)
		ListFrame.Size = UDim2.new(1, 0, 1, -24)
		ListFrame.Position = UDim2.new(0, 0, 0, 24)
		ListFrame.BackgroundTransparency = 1
		ListFrame.BorderSizePixel = 0
		ListFrame.ScrollBarThickness = 6
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)

		local ListLayout = Instance.new("UIListLayout", ListFrame)
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
		end)
		
		local Padding = Instance.new("UIPadding", ListFrame)
		Padding.PaddingTop = UDim.new(0, 4)
		Padding.PaddingBottom = UDim.new(0, 4)
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.PaddingRight = UDim.new(0, 4)

		SearchBox.TextBox.FocusLost:Connect(function(Enter)
			if Enter then DataExplorer.Refresh() end
		end)
	end

	return DataExplorer
end
return {InitDeps = InitDeps, InitAfterMain = InitAfterMain, Main = MainFunc}
end,

["DebugExplorer"] = function()
--[[
	Debug Explorer App Module
]]
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, EnvExplorer, DebugExplorer
local API, RMD, env, service, plr, create, createSimple

local function InitDeps(Data)
	Main, Lib, Apps, Settings = Data.Main, Data.Lib, Data.Apps, Data.Settings
	API, RMD, env, service, plr = Data.API, Data.RMD, Data.env, Data.service, Data.plr
	create, createSimple = Data.create, Data.createSimple
end

local function InitAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	EnvExplorer = Apps.EnvExplorer
	DebugExplorer = Apps.DebugExplorer
end

local function MainFunc()
local DebugExplorer = {}
	local Window
	local TopFrame, LeftPane, RightPane, WaitingLabel
	local NameLabel, IconImage, PathLabel
	local LeftList, RightList
	
	local FuncContextMenu, PropContextMenu, EventContextMenu
	local LeftContextMenu, ConnContextMenu
	
	local HookWindow, HookCodeFrame
	local ConnWindow, ConnList
	local SpoofWindow, SpoofDrop, SpoofBox

	DebugExplorer.CurrentInstance = nil
	DebugExplorer.SelectedMember = nil
	DebugExplorer.SelectedHookIndex = nil
	DebugExplorer.SelectedConnection = nil
	
	DebugExplorer.ActiveHooks = {} 
	DebugExplorer.BlockedConnections = {} 
	DebugExplorer.BlockedMembers = {}

	local function ApplyInstantHook(ActionName, Code, TargetFunc)
		if env.loadstring then
			local func, syntaxErr = env.loadstring(Code, "DEX")
			if not func then
				warn("Hook Syntax Error: " .. tostring(syntaxErr))
				return false
			end
			
			local S, Err = pcall(func)
			if not S then
				warn("Hook Execution Error: " .. tostring(Err))
				return false
			end
			
			if TargetFunc then
				DebugExplorer.HookedFunctions[Lib.GetHash(TargetFunc)] = Code
			else
				local HookData = {
					Inst = DebugExplorer.SelectedMember.Target,
					Type = DebugExplorer.SelectedMember.Type,
					Name = DebugExplorer.SelectedMember.Name,
					Action = ActionName,
					ScriptSource = Code
				}
				table.insert(DebugExplorer.ActiveHooks, HookData)
				DebugExplorer.RefreshLeftPane()
			end
			return true
		else
			warn("Executor does not support loadstring")
			return false
		end
	end

	local function GetHookIndex(Target, Name)
		for Idx, Hook in pairs(DebugExplorer.ActiveHooks) do
			if Hook.Inst == Target and Hook.Name == Name then
				return Idx, Hook
			end
		end
		return nil
	end

	local function UnhookMember(Target, Name)
		local Idx, Hook = GetHookIndex(Target, Name)
		if not Idx then return end
		
		if env.restorefunction then
			if Hook.Type == "Function" then 
				pcall(env.restorefunction, getrawmetatable(game).__namecall)
				pcall(env.restorefunction, Target[Name])
			end
			if Hook.Type == "Property" then 
				pcall(env.restorefunction, getrawmetatable(game).__index) 
			end
		end
		
		table.remove(DebugExplorer.ActiveHooks, Idx)
		DebugExplorer.RefreshLeftPane()
	end

	local function CreateTreeItem(ParentGui, IndentLevel, Prefix, Text, Color, HasChildren, OnClick, OnRightClick, NodeID)
		DebugExplorer.ExpandedNodes = DebugExplorer.ExpandedNodes or {}
		
		local ItemContainer = Instance.new("Frame")
		ItemContainer.BackgroundTransparency = 1
		ItemContainer.Size = UDim2.new(1, 0, 0, 0)
		ItemContainer.AutomaticSize = Enum.AutomaticSize.Y
		
		local NodeLayout = Instance.new("UIListLayout", ItemContainer)
		NodeLayout.SortOrder = Enum.SortOrder.LayoutOrder
		
		local BtnWrapper = Instance.new("Frame", ItemContainer)
		BtnWrapper.BackgroundTransparency = 1
		BtnWrapper.Size = UDim2.new(1, 0, 0, 22)
		BtnWrapper.LayoutOrder = 1
		
		local Btn = Instance.new("TextButton", BtnWrapper)
		Btn.Size = UDim2.new(1, -(IndentLevel * 16), 1, 0)
		Btn.Position = UDim2.new(0, IndentLevel * 16, 0, 0)
		Btn.BackgroundColor3 = Settings.Theme.Main1
		Btn.BorderSizePixel = 0
		Btn.Text = ""
		Btn.AutoButtonColor = false
		
		local ExpandIcon = nil
		if HasChildren then
			ExpandIcon = Instance.new("TextLabel", Btn)
			ExpandIcon.Size = UDim2.new(0, 16, 1, 0)
			ExpandIcon.Position = UDim2.new(0, 0, 0, 0)
			ExpandIcon.BackgroundTransparency = 1
			ExpandIcon.Text = "▶"
			ExpandIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
			ExpandIcon.Font = Enum.Font.SourceSansBold
			ExpandIcon.TextSize = 12
		end
		
		local Lbl = Instance.new("TextLabel", Btn)
		Lbl.BackgroundTransparency = 1
		Lbl.Position = UDim2.new(0, 16, 0, 0)
		Lbl.Size = UDim2.new(1, -25, 1, 0)
		Lbl.Font = Enum.Font.SourceSans
		Lbl.TextSize = 14
		Lbl.TextColor3 = Color
		Lbl.TextXAlignment = Enum.TextXAlignment.Left
		Lbl.TextTruncate = Enum.TextTruncate.AtEnd
		Lbl.RichText = true
		Lbl.Text = (Prefix and ("<font color='rgb(100,100,100)'>"..Prefix.." </font>") or "") .. Text
		
		Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
		Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)
		
		local ChildrenFrame = Instance.new("Frame")
		ChildrenFrame.BackgroundTransparency = 1
		ChildrenFrame.Size = UDim2.new(1, 0, 0, 0)
		ChildrenFrame.AutomaticSize = Enum.AutomaticSize.Y
		ChildrenFrame.Visible = false
		ChildrenFrame.LayoutOrder = 2
		
		local ChildLayout = Instance.new("UIListLayout", ChildrenFrame)
		ChildLayout.SortOrder = Enum.SortOrder.LayoutOrder
		
		if HasChildren then
			if NodeID and DebugExplorer.ExpandedNodes[NodeID] then
				ChildrenFrame.Visible = true
				ExpandIcon.Text = "▼"
			end
			
			Btn.MouseButton1Click:Connect(function()
				ChildrenFrame.Visible = not ChildrenFrame.Visible
				ExpandIcon.Text = ChildrenFrame.Visible and "▼" or "▶"
				if NodeID then DebugExplorer.ExpandedNodes[NodeID] = ChildrenFrame.Visible end
				if OnClick then OnClick(ChildrenFrame.Visible) end
			end)
		elseif OnClick then
			Btn.MouseButton1Click:Connect(OnClick)
		end
		
		if OnRightClick then
			Btn.MouseButton2Click:Connect(OnRightClick)
			local Holding = false
			local PressPos = nil
			Btn.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.Touch then
					Holding = true
					PressPos = Input.Position
					task.delay(0.5, function()
						if Holding then Holding = false OnRightClick() end
					end)
				end
			end)
			Btn.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.Touch then Holding = false end
			end)
			Btn.InputChanged:Connect(function(Input)
				if Holding and Input.UserInputType == Enum.UserInputType.Touch then
					if PressPos and (Input.Position - PressPos).Magnitude > 10 then Holding = false end
				end
			end)
		end
		
		ItemContainer.Parent = ParentGui
		ChildrenFrame.Parent = ItemContainer
		
		return ChildrenFrame, Lbl
	end

	DebugExplorer.RefreshLeftPane = function()
		for _, Child in pairs(LeftList:GetChildren()) do
			if Child:IsA("TextButton") or Child:IsA("Frame") then Child:Destroy() end
		end
		
		for Idx, Hook in pairs(DebugExplorer.ActiveHooks) do
			if Hook.Inst == DebugExplorer.CurrentInstance then
				local Btn = Instance.new("TextButton")
				Btn.Size = UDim2.new(1, 0, 0, 25)
				Btn.BackgroundColor3 = Settings.Theme.Main1
				Btn.BorderSizePixel = 0
				Btn.Text = ""
				Btn.AutoButtonColor = false
				
				local Lbl = Instance.new("TextLabel", Btn)
				Lbl.BackgroundTransparency = 1
				Lbl.Position = UDim2.new(0, 5, 0, 0)
				Lbl.Size = UDim2.new(1, -10, 1, 0)
				Lbl.Font = Enum.Font.SourceSans
				Lbl.TextSize = 14
				Lbl.TextColor3 = Settings.Theme.Text
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.TextTruncate = Enum.TextTruncate.AtEnd
				
				local TypeColor = (Hook.Type == "Function") and "rgb(132,214,247)" or "rgb(173,241,149)"
				Lbl.RichText = true
				Lbl.Text = string.format("<b><font color='%s'>[%s]</font></b> %s <font color='rgb(150,150,150)'>- %s</font>", TypeColor, Hook.Type, Hook.Name, Hook.Action)
				
				Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
				Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)
				
				Btn.MouseButton2Click:Connect(function()
					DebugExplorer.SelectedHookIndex = Idx
					LeftContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end)
				
				Btn.Parent = LeftList
			end
		end
	end

	DebugExplorer.RefreshConnections = function()
		for _, Child in pairs(ConnList:GetChildren()) do
			if Child:IsA("TextButton") or Child:IsA("Frame") or Child:IsA("TextLabel") then Child:Destroy() end
		end
		
		local Mem = DebugExplorer.SelectedMember
		if not Mem or Mem.Type ~= "Event" then return end
		
		local S, Conns = pcall(env.getconnections, Mem.Target[Mem.Name])
		if not S or type(Conns) ~= "table" or #Conns == 0 then 
			local NoConnLbl = Instance.new("TextLabel", ConnList)
			NoConnLbl.BackgroundTransparency = 1
			NoConnLbl.Size = UDim2.new(1, 0, 1, 0)
			NoConnLbl.Font = Enum.Font.SourceSans
			NoConnLbl.TextSize = 16
			NoConnLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
			NoConnLbl.Text = "No Connections Found"
			return 
		end
		
		for Idx, Conn in pairs(Conns) do
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 25)
			Btn.BackgroundColor3 = Settings.Theme.Main1
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false
			
			local Lbl = Instance.new("TextLabel", Btn)
			Lbl.BackgroundTransparency = 1
			Lbl.Position = UDim2.new(0, 5, 0, 0)
			Lbl.Size = UDim2.new(1, -30, 1, 0)
			Lbl.Font = Enum.Font.SourceSans
			Lbl.TextSize = 14
			Lbl.TextColor3 = Settings.Theme.Text
			Lbl.TextXAlignment = Enum.TextXAlignment.Left
			Lbl.RichText = true
			
			local StateStr = Conn.Enabled and "<font color='rgb(0,255,0)'>Enabled</font>" or "<font color='rgb(255,0,0)'>Disabled</font>"
			local BlockStr = DebugExplorer.BlockedConnections[tostring(Conn.Function)] and " | <font color='rgb(255,100,100)'>[Blocked]</font>" or ""
			local TypeStr = Conn.ForeignState and "(Foreign/C)" or "(Lua)"
			
			Lbl.Text = string.format("Conn %d %s - State: %s%s", Idx, TypeStr, StateStr, BlockStr)
			
			local DotsBtn = Instance.new("ImageButton", Btn)
			DotsBtn.BackgroundTransparency = 1
			DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
			DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
			DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'
			
			Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)
			
			Btn.MouseButton2Click:Connect(function()
				DebugExplorer.SelectedConnection = Conn
				ConnContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
			end)

			DotsBtn.MouseButton1Click:Connect(function()
				DebugExplorer.SelectedConnection = Conn
				ConnContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
			end)
			
			Btn.Parent = ConnList
		end
	end

	DebugExplorer.Refresh = function()
		if not DebugExplorer.CurrentInstance then
			TopFrame.Visible = false
			LeftPane.Visible = false
			RightPane.Visible = false
			WaitingLabel.Visible = true
			return
		end
		
		WaitingLabel.Visible = false
		TopFrame.Visible = true
		LeftPane.Visible = true
		RightPane.Visible = true
		
		local Target = DebugExplorer.CurrentInstance
		NameLabel.Text = Target.Name
		PathLabel.Text = Explorer.GetInstancePath(Target)
		
		-- Icon
		if Settings.ClassIcon == "Vanilla3" then
			IconImage.Size = UDim2.fromOffset(16, 16)
			IconImage.Position = UDim2.new(0.5, -8, 0, 32)
		else
			IconImage.Size = UDim2.fromOffset(32, 32)
			IconImage.Position = UDim2.new(0.5, -16, 0, 25)
		end
		Explorer.ClassIcons:DisplayByKey(IconImage, Target.ClassName)
		
		for _, Child in pairs(RightList:GetChildren()) do
			if Child:IsA("TextButton") or Child:IsA("Frame") then Child:Destroy() end
		end
		
		DebugExplorer.RefreshLeftPane()

		local ClassName = Target.ClassName
		local Funcs = API.GetMember(ClassName, "Functions") or {}
		local Props = API.GetMember(ClassName, "Properties") or {}
		local Events = API.GetMember(ClassName, "Events") or {}

		local RuntimeHiddenProps = {}
		if env.gethiddenproperties then
			local S, Hidden = pcall(env.gethiddenproperties, Target)
			if S and type(Hidden) == "table" then
				for k, v in next, Hidden do RuntimeHiddenProps[k] = typeof(v) end
			end
		end

		local RuntimeWhitelisted = {}
		if env.getsignalwhitelist then
			local S, WL = pcall(env.getsignalwhitelist)
			if S and type(WL) == "table" then
				for _, data in next, WL do
					if tostring(data.Parent) == ClassName then
						RuntimeWhitelisted[tostring(data.Event)] = true
					end
				end
			end
		end

		local KnownProps = {}
		for _, p in next, Props do 
			if RuntimeHiddenProps[p.Name] then p.IsHidden = true end
			KnownProps[p.Name] = true 
		end
		for k, vType in next, RuntimeHiddenProps do
			if not KnownProps[k] then 
				table.insert(Props, {Name = k, ValueType = {Name = vType}, IsHidden = true}) 
			end
		end

		local KnownEvents = {}
		for _, e in next, Events do 
			if RuntimeWhitelisted[e.Name] then e.IsHidden = true end
			KnownEvents[e.Name] = true 
		end
		for k, _ in next, RuntimeWhitelisted do
			if not KnownEvents[k] then
				table.insert(Events, {Name = k, IsHidden = true})
			end
		end

		local DetailWindow, DetailCodeFrame

		local function HandleMemberClick(Type, Name, Target, ApiData)
			DebugExplorer.SelectedMember = {Type = Type, Name = Name, Target = Target, ApiData = ApiData}
			local HookIdx, ExistingHook = GetHookIndex(Target, Name)
			local IsBlocked = (HookIdx ~= nil and ExistingHook.Action == "Blocked")

			if Type == "Function" then
				FuncContextMenu:Clear()
				FuncContextMenu:Add({Name = "Hook Method", OnClick = function() 
					local TargetPath = Explorer.GetInstancePath(Target)
					local Template = string.format([[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local Inst = %s
local compare = compareinstances or rawequal

local o; o = hookfunction(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if not checkcaller() and compare(self, Inst) and method == '%s' then
        -- Your logic here
        return o(self, ...)
    end

    return o(self, ...)
end))]], TargetPath, Name)
					HookCodeFrame:SetText(Template)
					HookWindow:SetTitle("Hooking Method: " .. Name)
					HookWindow:Show()
				end})
				
				FuncContextMenu:Add({Name = IsBlocked and "Unblock Function" or "Block Function", OnClick = function() 
					if IsBlocked then
						UnhookMember(Target, Name)
					else
						local TargetPath = Explorer.GetInstancePath(Target)
						local Code = string.format([[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local Inst = %s
local compare = compareinstances or rawequal
local o; o = hookfunction(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and compare(self, Inst) and method == '%s' then
        return nil
    end
    return o(self, ...)
end))
local o2; o2 = hookfunction(Inst.%s, newcclosure(function(self, ...)
    if not checkcaller() and compare(self, Inst) then
        return nil
    end
    return o2(self, ...)
end))]], TargetPath, Name, Name)
						ApplyInstantHook("Blocked", Code)
					end
					DebugExplorer.Refresh()
				end})

				if Name == "GetPropertyChangedSignal" then
					FuncContextMenu:AddDivider()
					FuncContextMenu:Add({Name = "Disable all Property Connections", OnClick = function()
						local Props = API.GetMember(Target.ClassName, "Properties") or {}
						for _, P in next, Props do
							local S, Signal = pcall(function() return Target:GetPropertyChangedSignal(P.Name) end)
							if S and Signal then
								local S2, Conns = pcall(env.getconnections, Signal)
								if S2 and type(Conns) == "table" then
									for _, C in next, Conns do pcall(function() C:Disable() end) end
								end
							end
						end
					end})
				end
				
				FuncContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				
			elseif Type == "Property" then
				PropContextMenu:Clear()
				PropContextMenu:Add({Name = "Hook Access", OnClick = function() 
					local TargetPath = Explorer.GetInstancePath(Target)
					local Template = string.format([[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local Inst = %s
local compare = compareinstances or rawequal

local o; o = hookfunction(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        -- Your logic here
        return o(...)
    end

    return o(...)
end))]], TargetPath, Name)
					HookCodeFrame:SetText(Template)
					HookWindow:SetTitle("Hooking Property: " .. Name)
					HookWindow:Show()
				end})
				
				PropContextMenu:Add({Name = IsBlocked and "Unblock Access" or "Block Access", OnClick = function() 
					if IsBlocked then
						UnhookMember(Target, Name)
					else
						local TargetPath = Explorer.GetInstancePath(Target)
						local Code = string.format([[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local Inst = %s
local compare = compareinstances or rawequal
local o; o = hookfunction(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return nil
    end
    return o(...)
end))]], TargetPath, Name)
						ApplyInstantHook("Blocked", Code)
					end
					DebugExplorer.Refresh()
				end})
				
				PropContextMenu:Add({Name = "Spoof Value", OnClick = function() 
					SpoofWindow:SetTitle("Spoof: " .. Name)
					SpoofWindow:Show()
				end})

				if ApiData and ApiData.Tags and ApiData.Tags.NotScriptable and env.isscriptable and env.setscriptable then
					local s, isScript = pcall(env.isscriptable, Target, Name)
					if s then
						PropContextMenu:AddDivider()
						PropContextMenu:Add({Name = isScript and "Revert Scriptability" or "Make Scriptable", OnClick = function()
							pcall(env.setscriptable, Target, Name, not isScript)
							DebugExplorer.Refresh()
						end})
					end
				end
				
				PropContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				
			elseif Type == "Event" then
				EventContextMenu:Clear()

				local Sig
				pcall(function() Sig = Target[Name] end)

				EventContextMenu:Add({Name = "Fire Signal", OnClick = function()
					if not Sig then return end
					Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
						local loadFunc, err = env.loadstring("return {" .. StrArgs .. "}")
						if type(loadFunc) == "function" then
							local S, Args = pcall(loadFunc)
							if S and type(Args) == "table" then
								if env.firesignal then pcall(env.firesignal, Sig, unpack(Args)) end
							end
						else
							warn("Invalid arguments syntax: " .. tostring(err))
						end
					end)
				end})

				local canRep = false
				if Sig and env.cansignalreplicate then
					pcall(function()
						canRep = env.cansignalreplicate(Sig) == true
					end)
				end
				
				EventContextMenu:Add({Name = "Replicate Signal", Disabled = not canRep, OnClick = function()
					if canRep and Sig then
						Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
							local loadFunc, err = env.loadstring("return {" .. StrArgs .. "}")
							if type(loadFunc) == "function" then
								local S, Args = pcall(loadFunc)
								if S and type(Args) == "table" then
									if env.replicatesignal then pcall(env.replicatesignal, Sig, unpack(Args)) end
								end
							else
								warn("Invalid arguments syntax: " .. tostring(err))
							end
						end)
					else
						warn("Signal cannot be replicated!")
					end
				end})

				EventContextMenu:Add({Name = "Fire All Connections", OnClick = function() 
					if not Sig then return end
					local S, Conns = pcall(env.getconnections, Sig)
					if S and type(Conns) == "table" then
						for _, C in next, Conns do pcall(function() C:Fire() end) end
					end
				end})

				EventContextMenu:Add({Name = "Manage Connections", OnClick = function() 
					ConnWindow:SetTitle("Connections: " .. Name)
					DebugExplorer.RefreshConnections()
					ConnWindow:Show()
				end})
				
				EventContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
			end
		end

		if DebugExplorer.TreeViewEnabled then
			local BaseNodeID = ""
			local S_Id, Id = pcall(function() return Target:GetDebugId() end)
			if S_Id and type(Id) == "string" then BaseNodeID = Id else BaseNodeID = tostring(Target) end
			
			local function RenderClosureDetails(Closure, ParentNode, CurrentDepth, BaseIndent, ParentID)
				local maxDepthLimit = DebugExplorer.MaxDepth or 3
				if CurrentDepth > maxDepthLimit then return end

				-- Constants
				if env.getconstants then
					local sC, Constants = pcall(env.getconstants, Closure)
					if sC and type(Constants) == "table" then
						local cCount = 0
						for _ in next, Constants do cCount = cCount + 1 end
						
						if cCount > 0 then
							local ConstID = ParentID .. "_Consts"
							local ConstNode = CreateTreeItem(ParentNode, BaseIndent + 1, "├──", "Constants ["..cCount.."]", Color3.fromRGB(200, 180, 255), true, nil, nil, ConstID)
							
							local cIter = 0
							for cIdx, cVal in next, Constants do
								cIter = cIter + 1
								local cType = typeof(cVal)
								local cPrefix = (cIter == cCount) and "└──" or "├──"
								local cDisp = ""
								local isFunc = (cType == "function")
								
								if isFunc then
									cDisp = Lib.GetFuncDisplayName(cVal)
								else
									cDisp = tostring(cVal)
									if cType == "string" then cDisp = '"'..cDisp..'"' end
									if #cDisp > 50 then cDisp = string.sub(cDisp, 1, 50).."..." end
								end
								
								local CNodeID = ConstID .. "_" .. tostring(cIdx)
								local CNode = CreateTreeItem(ConstNode, BaseIndent + 2, cPrefix, string.format("[%d] = %s <font color='rgb(130,130,130)'>(%s)</font>", cIdx, cDisp:gsub("<","&lt;"):gsub(">","&gt;"), cType), Color3.fromRGB(180, 180, 180), isFunc, nil, function()
									ConnConstContextMenu:Clear()
									ConnConstContextMenu:Add({Name = "Modify Value", OnClick = function() 
										Lib.ShowModifyValueDialog({Index = cIdx, Value = cVal, ValueType = cType}, function(SelectedType, RawInput)
											local ParsedVal = Lib.ParseToType(SelectedType, RawInput)
											if env.setconstant then pcall(env.setconstant, Closure, cIdx, ParsedVal) end
											DebugExplorer.Refresh()
										end)
									end})
									if isFunc then
										ConnConstContextMenu:Add({Name = "Detailed View", OnClick = function()
											if Lib.ViewFunctionDetail then Lib.ViewFunctionDetail(cVal, "Constant ["..cIdx.."]", Lib.GetHash(cVal)) end
										end})
									end
									ConnConstContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
								end, CNodeID)

								if isFunc then
									RenderClosureDetails(cVal, CNode, CurrentDepth + 1, BaseIndent + 2, CNodeID)
								end
							end
						else
							CreateTreeItem(ParentNode, BaseIndent + 1, "├──", "No Constants", Color3.fromRGB(100, 100, 100), false, nil, nil, ParentID .. "_NoConsts")
						end
					else
						CreateTreeItem(ParentNode, BaseIndent + 1, "├──", "No Constants", Color3.fromRGB(100, 100, 100), false, nil, nil, ParentID .. "_NoConsts")
					end
				end

				-- Upvalues
				if env.getupvalues then
					local sU, Upvs = pcall(env.getupvalues, Closure)
					if sU and type(Upvs) == "table" then
						local uCount = 0
						for _ in next, Upvs do uCount = uCount + 1 end
						
						if uCount > 0 then
							local UpvID = ParentID .. "_Upvs"
							local UpvNode = CreateTreeItem(ParentNode, BaseIndent + 1, "└──", "Upvalues ["..uCount.."]", Color3.fromRGB(200, 180, 255), true, nil, nil, UpvID)
							
							local uIter = 0
							for uIdx, uVal in next, Upvs do
								uIter = uIter + 1
								local uType = typeof(uVal)
								local uPrefix = (uIter == uCount) and "└──" or "├──"
								local uDisp = ""
								local isFunc = (uType == "function")
								
								if isFunc then
									uDisp = Lib.GetFuncDisplayName(uVal)
								else
									uDisp = tostring(uVal)
									if uType == "string" then uDisp = '"'..uDisp..'"' end
									if #uDisp > 50 then uDisp = string.sub(uDisp, 1, 50).."..." end
								end
								
								local UNodeID = UpvID .. "_" .. tostring(uIdx)
								local UNode = CreateTreeItem(UpvNode, BaseIndent + 2, uPrefix, string.format("[%d] = %s <font color='rgb(130,130,130)'>(%s)</font>", uIdx, uDisp:gsub("<","&lt;"):gsub(">","&gt;"), uType), Color3.fromRGB(180, 180, 180), isFunc, nil, function()
									ConnUpvalContextMenu:Clear()
									ConnUpvalContextMenu:Add({Name = "Modify Value", OnClick = function() 
										Lib.ShowModifyValueDialog({Index = uIdx, Value = uVal, ValueType = uType}, function(SelectedType, RawInput)
											local ParsedVal = Lib.ParseToType(SelectedType, RawInput)
											if env.setupvalue then pcall(env.setupvalue, Closure, uIdx, ParsedVal) end
											DebugExplorer.Refresh()
										end)
									end})
									if isFunc then
										ConnUpvalContextMenu:Add({Name = "Detailed View", OnClick = function()
											if Lib.ViewFunctionDetail then Lib.ViewFunctionDetail(uVal, "Upvalue ["..uIdx.."]", Lib.GetHash(uVal)) end
										end})
									end
									ConnUpvalContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
								end, UNodeID)

								if isFunc then
									RenderClosureDetails(uVal, UNode, CurrentDepth + 1, BaseIndent + 2, UNodeID)
								end
							end
						else
							CreateTreeItem(ParentNode, BaseIndent + 1, "└──", "No Upvalues", Color3.fromRGB(100, 100, 100), false, nil, nil, ParentID .. "_NoUpvs")
						end
					else
						CreateTreeItem(ParentNode, BaseIndent + 1, "└──", "No Upvalues", Color3.fromRGB(100, 100, 100), false, nil, nil, ParentID .. "_NoUpvs")
					end
				end
			end

			local FuncsNode, FuncsLbl = CreateTreeItem(RightList, 0, nil, "<b>Functions (" .. #Funcs .. ")</b>", Color3.fromRGB(132, 214, 247), true, nil, nil, BaseNodeID .. "_Main_Funcs")
			for i, f in next, Funcs do
				local Prefix = (i == #Funcs) and "└──" or "├──"
				local Params = {}
				if f.Parameters then
					for _, p in next, f.Parameters do table.insert(Params, (p.Type and p.Type.Name or "any") .. " " .. p.Name) end
				end
				local Ret = (f.ReturnType and f.ReturnType.Name) or "void"
				
				local HookIdx, Hook = GetHookIndex(Target, f.Name)
				local TagStr = ""
				if Hook then
					if Hook.Action == "Blocked" then
						TagStr = " <font color='rgb(255,100,100)'>[Blocked]</font>"
					else
						TagStr = " <font color='rgb(200,150,255)'>[Hooked]</font>"
					end
				end
				
				CreateTreeItem(FuncsNode, 1, Prefix, f.Name .. " (" .. table.concat(Params, ", ") .. ") : " .. Ret .. TagStr, Color3.fromRGB(200, 200, 200), false, nil, function()
					HandleMemberClick("Function", f.Name, Target, f)
				end, BaseNodeID .. "_Func_" .. f.Name)
			end

			-- Properties
			local PropsNode, PropsLbl = CreateTreeItem(RightList, 0, nil, "<b>Properties (" .. #Props .. ")</b>", Color3.fromRGB(173, 241, 149), true, nil, nil, BaseNodeID .. "_Main_Props")
			for i, p in next, Props do
				local Prefix = (i == #Props) and "└──" or "├──"
				local VType = p.ValueType and p.ValueType.Name or "Unknown"
				
				local HookIdx, Hook = GetHookIndex(Target, p.Name)
				local TagStr = ""
				if Hook then
					if Hook.Action == "Blocked" then
						TagStr = " <font color='rgb(255,100,100)'>[Blocked]</font>"
					elseif string.find(Hook.Action, "Spoofed") then
						TagStr = " <font color='rgb(100,200,255)'>[Spoofed]</font>"
					else
						TagStr = " <font color='rgb(200,150,255)'>[Hooked]</font>"
					end
				end

				local ScriptableStr = ""
				if p.Tags and p.Tags.NotScriptable then
					local s, isScript = false, false
					if env.isscriptable then s, isScript = pcall(env.isscriptable, Target, p.Name) end
					if not s or not isScript then
						ScriptableStr = " <i><font color='rgb(255,100,100)'>(Not Scriptable)</font></i>"
					end
				end
				
				local Text = p.Name .. " : " .. VType .. (p.IsHidden and " <i><font color='rgb(150,150,150)'>(Hidden)</font></i>" or "") .. ScriptableStr .. TagStr
				
				CreateTreeItem(PropsNode, 1, Prefix, Text, Color3.fromRGB(200, 200, 200), false, nil, function()
					HandleMemberClick("Property", p.Name, Target, p)
				end, BaseNodeID .. "_Prop_" .. p.Name)
			end

			-- Events
			local EventsNode, EventsLbl = CreateTreeItem(RightList, 0, nil, "<b>Events (" .. #Events .. ")</b>", Color3.fromRGB(255, 198, 0), true, nil, nil, BaseNodeID .. "_Main_Events")
			for i, e in next, Events do
				local Prefix = (i == #Events) and "└──" or "├──"
				local S, Conns = pcall(env.getconnections, Target[e.Name])
				local ConnCount = (S and type(Conns) == "table") and #Conns or 0
				local CountStr = (ConnCount > 0) and (" <font color='rgb(100,255,100)'>[" .. ConnCount .. "]</font>") or ""
				local Text = e.Name .. CountStr .. (e.IsHidden and " <i><font color='rgb(150,150,150)'>(Whitelisted)</font></i>" or "")
				
				local EventID = BaseNodeID .. "_Event_" .. e.Name
				local EventNode = CreateTreeItem(EventsNode, 1, Prefix, Text, Color3.fromRGB(200, 200, 200), ConnCount > 0, nil, function()
					HandleMemberClick("Event", e.Name, Target, e)
				end, EventID)

				if ConnCount > 0 then
					for Idx, C in next, Conns do
						local S_Func, C_Func = pcall(function() return C.Function end)
						if not S_Func then C_Func = nil end

						local ConnPrefix = (Idx == ConnCount) and "└──" or "├──"
						local ForeignStr = C.ForeignState and "(Foreign/C)" or "(Lua)"
						local StateStr = C.Enabled and "<font color='rgb(0,255,0)'>Enabled</font>" or "<font color='rgb(255,0,0)'>Disabled</font>"
						
						local BlockStr = ""
						if type(C_Func) == "function" then
							local Hash = Lib.GetHash(C_Func)
							DebugExplorer.BlockedConnections = DebugExplorer.BlockedConnections or {}
							BlockStr = DebugExplorer.BlockedConnections[Hash] and " | <font color='rgb(255,100,100)'>[Blocked]</font>" or ""
						end
						
						local ConnID = EventID .. "_Conn_" .. Idx
						local ConnNode = CreateTreeItem(EventNode, 2, ConnPrefix, string.format("Connection #%d %s - %s%s", Idx, ForeignStr, StateStr, BlockStr), Color3.fromRGB(180, 180, 180), true, nil, function()
							ConnContextMenu:Clear()
							ConnContextMenu:Add({Name = C.Enabled and "Disable Connection" or "Enable Connection", OnClick = function()
								if C.Enabled then pcall(function() C:Disable() end) else pcall(function() C:Enable() end) end
								DebugExplorer.Refresh()
							end})
							ConnContextMenu:Add({Name = "Disconnect Connection", OnClick = function()
								pcall(function() C:Disconnect() end)
								DebugExplorer.Refresh()
							end})
							ConnContextMenu:Add({Name = "Fire", OnClick = function()
								Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
									local loadFunc, err = env.loadstring("return {" .. StrArgs .. "}")
									if type(loadFunc) == "function" then
										local S2, Args = pcall(loadFunc)
										if S2 and type(Args) == "table" then pcall(function() C:Fire(unpack(Args)) end) end
									else
										warn("Invalid arguments syntax: " .. tostring(err))
									end
								end)
							end})
							ConnContextMenu:Add({Name = "Deferred Fire", OnClick = function()
								Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
									local loadFunc, err = env.loadstring("return {" .. StrArgs .. "}")
									if type(loadFunc) == "function" then
										local S2, Args = pcall(loadFunc)
										if S2 and type(Args) == "table" then pcall(function() C:Defer(unpack(Args)) end) end
									else
										warn("Invalid arguments syntax: " .. tostring(err))
									end
								end)
							end})
							ConnContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
						end, ConnID)
						
						local Scr = nil
						if type(C_Func) == "function" then
							local S_Env, FEnv = pcall(getfenv, C_Func)
							if S_Env and type(FEnv) == "table" and typeof(rawget(FEnv, "script")) == "Instance" then
								Scr = rawget(FEnv, "script")
							end
						end
						
						local ScrText = "Script: No Bytecode Available"
						if Scr then
							if Scr.Parent == nil and env.getscriptbytecode then
								local BcSuccess, Bc = pcall(env.getscriptbytecode, Scr)
								if BcSuccess and type(Bc) == "string" and #Bc > 0 then
									ScrText = "Script: " .. Explorer.GetInstancePath(Scr)
								end
							else
								ScrText = "Script: " .. Explorer.GetInstancePath(Scr)
							end
						end
						
						CreateTreeItem(ConnNode, 3, "├──", ScrText, Color3.fromRGB(220, 200, 150), false, nil, function()
							if ScrText ~= "Script: No Bytecode Available" and Scr then
								DebugExplorer.SelectedConnectionScript = Scr
								ConnScriptContextMenu:Clear()
								ConnScriptContextMenu:Add({Name = "View Script", OnClick = function() ScriptViewer.ViewScript(Scr) end})
								ConnScriptContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
							end
						end, ConnID .. "_Script")
						
						if type(C_Func) == "function" then
							local FuncId = tostring(C_Func)
							local FuncHash = Lib.GetHash(C_Func)
							
							DebugExplorer.BlockedConnections = DebugExplorer.BlockedConnections or {}
							DebugExplorer.HookedFunctions = DebugExplorer.HookedFunctions or {}
							
							local BlockTag = DebugExplorer.BlockedConnections[FuncId] and " <font color='rgb(255,100,100)'>[Blocked]</font>" or ""
							local HookTag = DebugExplorer.HookedFunctions[FuncId] and " <font color='rgb(200,150,255)'>[Hooked]</font>" or ""
							
							local FuncStr = "Function: " .. Lib.GetFuncDisplayName(C_Func) .. BlockTag .. HookTag
							
							local HasProps = false
							local TestC, TestU
							if env.getconstants then pcall(function() TestC = env.getconstants(C_Func) end) end
							if env.getupvalues then pcall(function() TestU = env.getupvalues(C_Func) end) end
							
							if (TestC and type(TestC) == "table" and #TestC > 0) or (TestU and type(TestU) == "table" and #TestU > 0) then
								HasProps = true
							end
							
							local FuncID = ConnID .. "_Func"
							local FnNode = CreateTreeItem(ConnNode, 3, "└──", FuncStr, Color3.fromRGB(150, 200, 255), HasProps, nil, function()
								DebugExplorer.SelectedConnectionFunc = C_Func
								ConnFuncContextMenu:Clear()
								ConnFuncContextMenu:Add({Name = "Detailed View", OnClick = function() 
									if Lib.ViewFunctionDetail then Lib.ViewFunctionDetail(C_Func, "ConnectedFunction", Lib.GetHash(C_Func)) end
								end})
								ConnFuncContextMenu:Add({Name = "Copy Func As Script", OnClick = function() 
									if env.setclipboard then env.setclipboard("-- Generated with DEX Recontinued\nlocal function findfunc(str)\n    for i,v in next, getgc() do\n        if type(v) == 'function' and tostring(v) == str then return v end\n    end\nend\nlocal func = findfunc(\"" .. tostring(C_Func) .. "\")") end
								end})
								
								local IsHookedFunc = DebugExplorer.HookedFunctions[FuncId]
								ConnFuncContextMenu:Add({Name = IsHookedFunc and "Unhook Function" or "Hook Function", OnClick = function()
									if IsHookedFunc then
										if env.restorefunction then pcall(env.restorefunction, C_Func) end
										DebugExplorer.HookedFunctions[FuncId] = nil
										
										for idx, hk in pairs(DebugExplorer.ActiveHooks) do
											if hk.TargetFunc == C_Func then
												table.remove(DebugExplorer.ActiveHooks, idx)
												break
											end
										end
										DebugExplorer.RefreshLeftPane()
										DebugExplorer.Refresh()
									else
										local FuncStrCode = tostring(C_Func)
										local Template = string.format([[local function findfunc(str, addr)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if not iscclosure(v) and getfunctionhash(v) == str then
		return v
            end
    end
    for i,v in next, getgc() do
        if type(v) == 'function' and tostring(v) == addr then return v end
    end
end
local target = findfunc('%s', '%s')

local o; o = hookfunction(target, function(...)
    -- Logic here
    return o(...)
end)]], FuncHash, FuncStrCode)
										HookCodeFrame:SetText(Template)
										HookWindow:SetTitle("Hooking Connected Function")
										HookWindow:Show()
									end
								end})
								
								local IsBlockedFunc = DebugExplorer.BlockedConnections[FuncId]
								ConnFuncContextMenu:Add({Name = IsBlockedFunc and "Unblock Function" or "Block Function", OnClick = function()
									if IsBlockedFunc then
										if env.restorefunction then pcall(env.restorefunction, C_Func) end
										DebugExplorer.BlockedConnections[FuncId] = nil
									else
										if env.hookfunction then
											DebugExplorer.BlockedConnections[FuncId] = true
											pcall(env.hookfunction, C_Func, function() end)
										end
									end
									DebugExplorer.Refresh()
								end})
								ConnFuncContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
							end, FuncID)
							
							if HasProps then
								RenderClosureDetails(C_Func, FnNode, 1, 3, FuncID)
							end
						else
							CreateTreeItem(ConnNode, 3, "└──", "Function: C Closure", Color3.fromRGB(255, 150, 150), false, nil, nil, ConnID .. "_CClose")
						end
					end
				end
			end
		else
			local function CreateMemberItem(Type, Name, DetailStr, ApiData)
				local Btn = Instance.new("TextButton")
				Btn.Size = UDim2.new(1, 0, 0, 25)
				Btn.BackgroundColor3 = Settings.Theme.Main1
				Btn.BorderSizePixel = 0
				Btn.Text = ""
				Btn.AutoButtonColor = false
				
				local ItemLabel = Instance.new("TextLabel", Btn)
				ItemLabel.BackgroundTransparency = 1
				ItemLabel.Position = UDim2.new(0, 5, 0, 0)
				ItemLabel.Size = UDim2.new(1, -30, 1, 0)
				ItemLabel.Font = Enum.Font.SourceSans
				ItemLabel.TextSize = 14
				ItemLabel.TextColor3 = Settings.Theme.Text
				ItemLabel.TextXAlignment = Enum.TextXAlignment.Left
				ItemLabel.TextTruncate = Enum.TextTruncate.AtEnd
				ItemLabel.RichText = true
				
				local TypeColor = "rgb(200, 200, 200)"
				if Type == "Function" then TypeColor = "rgb(132, 214, 247)"
				elseif Type == "Event" then TypeColor = "rgb(255, 198, 0)"
				elseif Type == "Property" then TypeColor = "rgb(173, 241, 149)" end
				
				local HookIdx, Hook = GetHookIndex(Target, Name)
				local TagStr = ""
				if Hook then
					if Hook.Action == "Blocked" then
						TagStr = " <font color='rgb(255,100,100)'>[Blocked]</font>"
					elseif string.find(Hook.Action, "Spoofed") then
						TagStr = " <font color='rgb(100,200,255)'>[Spoofed]</font>"
					else
						TagStr = " <font color='rgb(200,150,255)'>[Hooked]</font>"
					end
				end
				
				ItemLabel.Text = string.format("<b><font color='%s'>[%s]</font></b> %s<font color='rgb(150,150,150)'>%s</font>%s", TypeColor, Type, Name, DetailStr:gsub("<", "&lt;"):gsub(">", "&gt;"), TagStr)
				
				local DotsBtn = Instance.new("ImageButton", Btn)
				DotsBtn.BackgroundTransparency = 1
				DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
				DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
				DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'
				
				Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
				Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)

				local function HandleClick()
					HandleMemberClick(Type, Name, Target, ApiData)
				end

				DotsBtn.MouseButton1Click:Connect(HandleClick)
				Btn.MouseButton2Click:Connect(HandleClick)
				Btn.Parent = RightList
			end

			for i, f in next, Funcs do
				local Params = {}
				if f.Parameters then
					for _, p in next, f.Parameters do table.insert(Params, (p.Type and p.Type.Name or "any") .. " " .. p.Name) end
				end
				local Ret = (f.ReturnType and f.ReturnType.Name) or "void"
				CreateMemberItem("Function", f.Name, "(" .. table.concat(Params, ", ") .. ") : " .. Ret, f)
			end

			for i, e in next, Events do
				local Params = {}
				if e.Parameters then
					for _, p in next, e.Parameters do table.insert(Params, (p.Type and p.Type.Name or "any") .. " " .. p.Name) end
				end
				CreateMemberItem("Event", e.Name, "(" .. table.concat(Params, ", ") .. ") " .. (e.IsHidden and "(Whitelisted)" or ""), e)
			end

			for i, p in next, Props do
				local VType = p.ValueType and p.ValueType.Name or "Unknown"
				local ScriptableStr = ""
				if p.Tags and p.Tags.NotScriptable then
					local s, isScript = false, false
					if env.isscriptable then s, isScript = pcall(env.isscriptable, Target, p.Name) end
					if not s or not isScript then
						ScriptableStr = " <i><font color='rgb(255,100,100)'>(Not Scriptable)</font></i>"
					end
				end

				CreateMemberItem("Property", p.Name, " : " .. VType .. (p.IsHidden and " <i><font color='rgb(150,150,150)'>(Hidden)</font></i>" or "") .. ScriptableStr, p)
			end
		end
	end

	DebugExplorer.Init = function()
		Window = Lib.Window.new()
		Window:SetTitle("Debugging Interface")
		Window:Resize(700, 550)
		DebugExplorer.Window = Window
		
		local Content = Window.GuiElems.Content
		
		WaitingLabel = Instance.new("TextLabel", Content)
		WaitingLabel.Size = UDim2.new(1, 0, 1, 0)
		WaitingLabel.BackgroundTransparency = 1
		WaitingLabel.Text = "Select an instance in the Explorer"
		WaitingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		WaitingLabel.Font = Enum.Font.SourceSans
		WaitingLabel.TextSize = 18
		WaitingLabel.ZIndex = 5
		
		TopFrame = Instance.new("Frame", Content)
		TopFrame.Size = UDim2.new(1, 0, 0, 80)
		TopFrame.BackgroundColor3 = Settings.Theme.Main2
		TopFrame.BorderSizePixel = 0
		TopFrame.Visible = false
		
		NameLabel = Instance.new("TextLabel", TopFrame)
		NameLabel.Size = UDim2.new(1, 0, 0, 20)
		NameLabel.Position = UDim2.new(0, 0, 0, 5)
		NameLabel.BackgroundTransparency = 1
		NameLabel.TextColor3 = Settings.Theme.Text
		NameLabel.Font = Enum.Font.SourceSansBold
		NameLabel.TextSize = 16
		
		IconImage = Instance.new("ImageLabel", TopFrame)
		IconImage.BackgroundTransparency = 1
		
		PathLabel = Instance.new("TextLabel", TopFrame)
		PathLabel.Size = UDim2.new(1, 0, 0, 20)
		PathLabel.Position = UDim2.new(0, 0, 0, 55)
		PathLabel.BackgroundTransparency = 1
		PathLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
		PathLabel.Font = Enum.Font.SourceSans
		PathLabel.TextSize = 14
		
		LeftPane = Instance.new("Frame", Content)
		LeftPane.Size = UDim2.new(0.35, 0, 1, -80)
		LeftPane.Position = UDim2.new(0, 0, 0, 80)
		LeftPane.BackgroundColor3 = Settings.Theme.Main1
		LeftPane.BorderColor3 = Settings.Theme.Outline1
		LeftPane.BorderSizePixel = 0
		LeftPane.Visible = false

		DebugExplorer.TreeViewEnabled = false

		DebugExplorer.MaxDepth = 3

		local ViewToggleBtn = Instance.new("TextButton", TopFrame)
		ViewToggleBtn.Size = UDim2.new(0, 80, 0, 22)
		ViewToggleBtn.Position = UDim2.new(1, -90, 0, 10)
		ViewToggleBtn.BackgroundColor3 = Settings.Theme.Button
		ViewToggleBtn.BorderSizePixel = 0
		ViewToggleBtn.TextColor3 = Settings.Theme.Text
		ViewToggleBtn.Font = Enum.Font.SourceSans
		ViewToggleBtn.TextSize = 14
		ViewToggleBtn.Text = "View: Flat"
		
		ViewToggleBtn.MouseButton1Click:Connect(function()
			DebugExplorer.TreeViewEnabled = not DebugExplorer.TreeViewEnabled
			ViewToggleBtn.Text = DebugExplorer.TreeViewEnabled and "View: Tree" or "View: Flat"
			DebugExplorer.Refresh()
		end)
		DebugExplorer.ViewToggleBtn = ViewToggleBtn

		local DepthToggleBtn = Instance.new("TextButton", TopFrame)
		DepthToggleBtn.Size = UDim2.new(0, 80, 0, 22)
		DepthToggleBtn.Position = UDim2.new(1, -90, 0, 36)
		DepthToggleBtn.BackgroundColor3 = Settings.Theme.Button
		DepthToggleBtn.BorderSizePixel = 0
		DepthToggleBtn.TextColor3 = Settings.Theme.Text
		DepthToggleBtn.Font = Enum.Font.SourceSans
		DepthToggleBtn.TextSize = 14
		DepthToggleBtn.Text = "Depth: 3"
		
		DepthToggleBtn.MouseButton1Click:Connect(function()
			Lib.ShowInputPrompt("Set Tree Depth Limit", DebugExplorer.MaxDepth, function(StrVal)
				local Num = tonumber(StrVal)
				if Num then 
					DebugExplorer.MaxDepth = Num 
					DepthToggleBtn.Text = "Depth: " .. Num
					if DebugExplorer.TreeViewEnabled then 
						DebugExplorer.Refresh() 
					end
				end
			end)
		end)
		DebugExplorer.DepthToggleBtn = DepthToggleBtn
		
		local LeftTitle = Instance.new("TextLabel", LeftPane)
		LeftTitle.Size = UDim2.new(1, 0, 0, 25)
		LeftTitle.BackgroundColor3 = Settings.Theme.Main2
		LeftTitle.BorderSizePixel = 0
		LeftTitle.Text = " Active Hooks"
		LeftTitle.TextColor3 = Settings.Theme.Text
		LeftTitle.Font = Enum.Font.SourceSansBold
		LeftTitle.TextSize = 14
		LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
		
		LeftList = Instance.new("ScrollingFrame", LeftPane)
		LeftList.Size = UDim2.new(1, 0, 1, -25)
		LeftList.Position = UDim2.new(0, 0, 0, 25)
		LeftList.BackgroundTransparency = 1
		LeftList.BorderSizePixel = 0
		LeftList.ScrollBarThickness = 4
		
		local LeftLayout = Instance.new("UIListLayout", LeftList)
		LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			LeftList.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y)
		end)
		
		RightPane = Instance.new("Frame", Content)
		RightPane.Size = UDim2.new(0.65, 0, 1, -80)
		RightPane.Position = UDim2.new(0.35, 0, 0, 80)
		RightPane.BackgroundColor3 = Settings.Theme.Main1
		RightPane.BorderSizePixel = 0
		RightPane.Visible = false
		
		local RightTitle = Instance.new("TextLabel", RightPane)
		RightTitle.Size = UDim2.new(1, 0, 0, 25)
		RightTitle.BackgroundColor3 = Settings.Theme.Main2
		RightTitle.BorderSizePixel = 0
		RightTitle.Text = " Functions / Properties / Events"
		RightTitle.TextColor3 = Settings.Theme.Text
		RightTitle.Font = Enum.Font.SourceSansBold
		RightTitle.TextSize = 14
		RightTitle.TextXAlignment = Enum.TextXAlignment.Left
		
		RightList = Instance.new("ScrollingFrame", RightPane)
		RightList.Size = UDim2.new(1, 0, 1, -25)
		RightList.Position = UDim2.new(0, 0, 0, 25)
		RightList.BackgroundTransparency = 1
		RightList.BorderSizePixel = 0
		RightList.ScrollBarThickness = 6
		
		local RightLayout = Instance.new("UIListLayout", RightList)
		RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			RightList.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y)
		end)
		
		FuncContextMenu = Lib.ContextMenu.new()
		FuncContextMenu.Iconless = true
		FuncContextMenu.Width = 150

		PropContextMenu = Lib.ContextMenu.new()
		PropContextMenu.Iconless = true
		PropContextMenu.Width = 150

		EventContextMenu = Lib.ContextMenu.new()
		EventContextMenu.Iconless = true
		EventContextMenu.Width = 200

		ConnContextMenu = Lib.ContextMenu.new()
		ConnContextMenu.Iconless = true
		ConnContextMenu.Width = 180

		ConnScriptContextMenu = Lib.ContextMenu.new()
		ConnScriptContextMenu.Iconless = true
		ConnScriptContextMenu.Width = 150

		ConnFuncContextMenu = Lib.ContextMenu.new()
		ConnFuncContextMenu.Iconless = true
		ConnFuncContextMenu.Width = 200

		ConnUpvalContextMenu = Lib.ContextMenu.new()
		ConnUpvalContextMenu.Iconless = true
		ConnUpvalContextMenu.Width = 150

		FuncContextMenu:Add({Name = "Hook Method", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Template = string.format([[-- Generated with DEX Recontinued by Tesker103
local Inst = %s
local compare = compareinstances or rawequal

local o; o = hookfunction(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and compare(self, Inst) and method == '%s' then
        -- Your logic here
    end
    return o(self, ...)
end))]], TargetPath, Mem.Name)
			HookCodeFrame:SetText(Template)
			HookWindow:SetTitle("Hooking Method: " .. Mem.Name)
			HookWindow:Show()
		end})
		
		FuncContextMenu:Add({Name = "Block Access", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Code = string.format([[-- Generated with DEX Recontinued by Tesker103
local Inst = %s
local compare = compareinstances or rawequal
local o; o = hookfunction(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and compare(self, Inst) and method == '%s' then
        return nil
    end
    return o(self, ...)
end))
local o2; o2 = hookfunction(Inst.%s, newcclosure(function(self, ...)
    if not checkcaller() and compare(self, Inst) then
        return nil
    end
    return o2(self, ...)
end))]], TargetPath, Mem.Name, Mem.Name)
			ApplyInstantHook("Blocked", Code)
		end})

		PropContextMenu:Add({Name = "Hook Access", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Template = string.format([[-- Generated with DEX Recontinued by Tesker103
local Inst = %s
local compare = compareinstances or rawequal

local o; o = hookfunction(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...
    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        -- Your logic here
    end
    return o(...)
end))]], TargetPath, Mem.Name)
			HookCodeFrame:SetText(Template)
			HookWindow:SetTitle("Hooking Property: " .. Mem.Name)
			HookWindow:Show()
		end})

		PropContextMenu:Add({Name = "Block Access", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Code = string.format([[-- Generated with DEX Recontinued by Tesker103
local Inst = %s
local compare = compareinstances or rawequal
local o; o = hookfunction(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...
    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return nil
    end
    return o(...)
end))]], TargetPath, Mem.Name)
			ApplyInstantHook("Blocked", Code)
		end})
		
		PropContextMenu:Add({Name = "Spoof Value", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			SpoofWindow:SetTitle("Spoof: " .. Mem.Name)
			SpoofWindow:Show()
		end})

		EventContextMenu:Add({Name = "Manage Connections", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			ConnWindow:SetTitle("Connections: " .. Mem.Name)
			DebugExplorer.RefreshConnections()
			ConnWindow:Show()
		end})

		EventContextMenu:Add({Name = "Fire All Connections", OnClick = function() 
			local Mem = DebugExplorer.SelectedMember
			local S, Conns = pcall(env.getconnections, Mem.Target[Mem.Name])
			if S and type(Conns) == "table" then
				for _, C in next, Conns do pcall(function() C:Fire() end) end
			end
		end})

		EventContextMenu:Add({Name = "Fire Signal", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			local Sig = Mem.Target[Mem.Name]
			Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
				local S, CallFunc = pcall(loadstring, "return {" .. StrArgs .. "}")
				if S and CallFunc then
					local Args = CallFunc()
					if env.firesignal then pcall(env.firesignal, Sig, unpack(Args)) end
				end
			end)
		end})

		EventContextMenu:Add({Name = "Replicate Signal", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			local Sig = Mem.Target[Mem.Name]
			if env.cansignalreplicate and env.cansignalreplicate(Sig) then
				Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
					local S, CallFunc = pcall(loadstring, "return {" .. StrArgs .. "}")
					if S and CallFunc then
						local Args = CallFunc()
						if env.replicatesignal then pcall(env.replicatesignal, Sig, unpack(Args)) end
					end
				end)
			else
				warn("Signal cannot be replicated!")
			end
		end})

		ConnContextMenu:Add({Name = "Fire", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
				local S, CallFunc = pcall(loadstring, "return {" .. StrArgs .. "}")
				if S and CallFunc then
					local Args = CallFunc()
					pcall(function() C:Fire(unpack(Args)) end)
				end
			end)
		end})
		
		ConnContextMenu:Add({Name = "Deferred Fire", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			Lib.ShowInputPrompt("Arguments (e.g. 1, 'String')", "", function(StrArgs)
				local S, CallFunc = pcall(loadstring, "return {" .. StrArgs .. "}")
				if S and CallFunc then
					local Args = CallFunc()
					pcall(function() C:Defer(unpack(Args)) end)
				end
			end)
		end})

		ConnContextMenu:Add({Name = "Toggle Enable/Disable", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			if C.Enabled then pcall(function() C:Disable() end) else pcall(function() C:Enable() end) end
			DebugExplorer.RefreshConnections()
			DebugExplorer.Refresh()
		end})

		ConnContextMenu:Add({Name = "Disconnect", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			pcall(function() C:Disconnect() end)
			DebugExplorer.RefreshConnections()
			DebugExplorer.Refresh()
		end})

		ConnContextMenu:Add({Name = "Toggle Block (.Function of conn)", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			local Func = C.Function
			if not Func then return end
			
			local Hash = tostring(Func)
			if DebugExplorer.BlockedConnections[Hash] then
				if env.restorefunction then pcall(env.restorefunction, Func) end
				DebugExplorer.BlockedConnections[Hash] = nil
			else
				if env.hookfunction then
					DebugExplorer.BlockedConnections[Hash] = true
					pcall(env.hookfunction, Func, function() end)
				end
			end
			DebugExplorer.RefreshConnections()
			DebugExplorer.Refresh()
		end})
		
		ConnScriptContextMenu:Add({Name = "View Script", OnClick = function() 
			local Scr = DebugExplorer.SelectedConnectionScript
			if Scr then ScriptViewer.ViewScript(Scr) end
		end})

		ConnFuncContextMenu:Add({Name = "Detailed View", OnClick = function() 
			local Func = DebugExplorer.SelectedConnectionFunc
			if Func and Lib.ViewFunctionDetail then 
				Lib.ViewFunctionDetail(Func, "ConnectedFunction", Lib.GetHash(Func)) 
			end
		end})

		ConnFuncContextMenu:Add({Name = "Copy Func As Script", OnClick = function() 
			if not env.setclipboard then return end
			local Func = DebugExplorer.SelectedConnectionFunc
			local Template = "-- Generated with DEX Recontinued\nlocal function findfunc(str)\n    for i,v in next, getgc() do\n        if type(v) == 'function' and tostring(v) == str then return v end\n    end\nend\nlocal func = findfunc(\"" .. tostring(Func) .. "\")"
			env.setclipboard(Template)
		end})
		
		ConnFuncContextMenu:Add({Name = "Hook Function", OnClick = function()
			local Func = DebugExplorer.SelectedConnectionFunc
			local Hash = Lib.GetHash(Func)
			local Template = string.format([[-- Generated with DEX Recontinued
local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' and getfunctionhash and getfunctionhash(v) == '%s' then return v end
    end
end
local target = findfunc()

local o; o = hookfunction(target, function(...)
    -- Logic here
    return o(...)
end)]], Hash)
			HookCodeFrame:SetText(Template)
			HookWindow:SetTitle("Hooking Connected Function")
			HookWindow:Show()
		end})
		
		ConnFuncContextMenu:Add({Name = "Block Function", OnClick = function()
			local Func = DebugExplorer.SelectedConnectionFunc
			local Hash = tostring(Func)
			if DebugExplorer.BlockedConnections[Hash] then
				if env.restorefunction then pcall(env.restorefunction, Func) end
				DebugExplorer.BlockedConnections[Hash] = nil
			else
				if env.hookfunction then
					DebugExplorer.BlockedConnections[Hash] = true
					pcall(env.hookfunction, Func, function() end)
				end
			end
			DebugExplorer.Refresh()
		end})

		ConnUpvalContextMenu:Add({Name = "Modify Value", OnClick = function() 
			local Upv = DebugExplorer.SelectedUpvalue
			local Func = DebugExplorer.SelectedConnectionFunc
			if not Upv or not Func then return end
			
			Lib.ShowModifyValueDialog(Upv, function(SelectedType, RawInput)
				local ParsedVal = Lib.ParseToType(SelectedType, RawInput)
				if env.setupvalue then
					pcall(env.setupvalue, Func, Upv.Index, ParsedVal)
				end
				DebugExplorer.Refresh()
			end)
		end})

		ConnConstContextMenu = Lib.ContextMenu.new()
		ConnConstContextMenu.Iconless = true
		ConnConstContextMenu.Width = 150
		ConnConstContextMenu:Add({Name = "Modify Value", OnClick = function() 
			local Cst = DebugExplorer.SelectedConstant
			local Func = DebugExplorer.SelectedConnectionFunc
			if not Cst or not Func then return end
			
			Lib.ShowModifyValueDialog(Cst, function(SelectedType, RawInput)
				local ParsedVal = Lib.ParseToType(SelectedType, RawInput)
				if env.setconstant then
					pcall(env.setconstant, Func, Cst.Index, ParsedVal)
				end
				DebugExplorer.Refresh()
			end)
		end})

		LeftContextMenu = Lib.ContextMenu.new()
		LeftContextMenu.Iconless = true
		LeftContextMenu.Width = 150
		LeftContextMenu:Add({Name = "Modify", OnClick = function() 
			local Hook = DebugExplorer.ActiveHooks[DebugExplorer.SelectedHookIndex]
			if Hook then
				HookCodeFrame:SetText(Hook.ScriptSource)
				HookWindow:SetTitle("Modifying Hook: " .. Hook.Name)
				HookWindow:Show()
			end
		end})
		LeftContextMenu:Add({Name = "Unhook", OnClick = function() 
			local Idx = DebugExplorer.SelectedHookIndex
			local Hook = DebugExplorer.ActiveHooks[Idx]
			if not Hook then return end
			
			if env.restorefunction then
				if Hook.Type == "Function" then 
					pcall(env.restorefunction, getrawmetatable(game).__namecall)
					pcall(env.restorefunction, Hook.Inst[Hook.Name])
				elseif Hook.Type == "Property" then 
					pcall(env.restorefunction, getrawmetatable(game).__index) 
				elseif Hook.Type == "Conn Function" and Hook.TargetFunc then
					pcall(env.restorefunction, Hook.TargetFunc)
					local FuncId = tostring(Hook.TargetFunc)
					DebugExplorer.HookedFunctions[FuncId] = nil
				end
			end
			
			table.remove(DebugExplorer.ActiveHooks, Idx)
			DebugExplorer.SelectedHookIndex = nil
			DebugExplorer.RefreshLeftPane()
			if DebugExplorer.TreeViewEnabled then DebugExplorer.Refresh() else DebugExplorer.Refresh() end
		end})

		ConnContextMenu = Lib.ContextMenu.new()
		ConnContextMenu.Iconless = true
		ConnContextMenu.Width = 180
		ConnContextMenu:Add({Name = "Fire", OnClick = function() 
			pcall(function() DebugExplorer.SelectedConnection:Fire() end)
		end})
		ConnContextMenu:Add({Name = "Toggle Enable/Disable", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			if C.Enabled then pcall(function() C:Disable() end) else pcall(function() C:Enable() end) end
			DebugExplorer.RefreshConnections()
		end})
		ConnContextMenu:Add({Name = "Disconnect", OnClick = function() 
			pcall(function() DebugExplorer.SelectedConnection:Disconnect() end)
			DebugExplorer.RefreshConnections()
		end})
		ConnContextMenu:Add({Name = "Toggle Block (.Function of conn)", OnClick = function() 
			local C = DebugExplorer.SelectedConnection
			local Func = C.Function
			if not Func then return end
			
			local FuncId = tostring(Func)
			if DebugExplorer.BlockedConnections[FuncId] then
				if env.restorefunction then pcall(env.restorefunction, Func) end
				DebugExplorer.BlockedConnections[FuncId] = nil
			else
				if env.hookfunction then
					DebugExplorer.BlockedConnections[FuncId] = true
					pcall(env.hookfunction, Func, function() end)
				end
			end
			DebugExplorer.RefreshConnections()
		end})
		
		HookWindow = Lib.Window.new()
		HookWindow:SetTitle("Hook Editor")
		HookWindow:Resize(500, 450)

		HookCodeFrame = Lib.CodeFrame.new()
		HookCodeFrame.Frame.Position = UDim2.new(0, 0, 0, 20)
		HookCodeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
		HookCodeFrame.Frame.Parent = HookWindow.GuiElems.Content
		HookCodeFrame.Editable = true

		local HookCopyBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookCopyBtn.Size = UDim2.new(0.5, 0, 0, 20)
		HookCopyBtn.Position = UDim2.new(0, 0, 0, 0)
		HookCopyBtn.BackgroundColor3 = Settings.Theme.Main2
		HookCopyBtn.BorderSizePixel = 0
		HookCopyBtn.Text = "Copy to Clipboard"
		HookCopyBtn.TextColor3 = Color3.new(1, 1, 1)

		HookCopyBtn.MouseButton1Click:Connect(function()
			if env.setclipboard then env.setclipboard(HookCodeFrame:GetText()) end
		end)
		
		local HookExecuteBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookExecuteBtn.Size = UDim2.new(0.5, 0, 0, 20)
		HookExecuteBtn.Position = UDim2.new(0.5, 0, 0, 0)
		HookExecuteBtn.BackgroundColor3 = Settings.Theme.Button
		HookExecuteBtn.BorderSizePixel = 0
		HookExecuteBtn.Text = "Execute & Save Hook"
		HookExecuteBtn.TextColor3 = Color3.new(1, 1, 1)
		
		HookExecuteBtn.MouseButton1Click:Connect(function()
			local Source = HookCodeFrame:GetText()
			if env.loadstring then 
				local func, syntaxErr = env.loadstring(Source, "DEX")
				if not func then
					warn("Hook Syntax Error: " .. tostring(syntaxErr))
					return
				end

				if DebugExplorer.SelectedHookIndex then
					local Hook = DebugExplorer.ActiveHooks[DebugExplorer.SelectedHookIndex]
					if env.restorefunction then
						if Hook.Type == "Function" then pcall(env.restorefunction, getrawmetatable(game).__namecall) end
						if Hook.Type == "Property" then pcall(env.restorefunction, getrawmetatable(game).__index) end
						if Hook.Type == "Conn Function" and Hook.TargetFunc then 
							pcall(env.restorefunction, Hook.TargetFunc)
							local FuncId = tostring(Hook.TargetFunc)
							DebugExplorer.HookedFunctions[FuncId] = nil
						end
					end
					table.remove(DebugExplorer.ActiveHooks, DebugExplorer.SelectedHookIndex)
					DebugExplorer.SelectedHookIndex = nil
				end

				local S, Err = pcall(func)
				if S then
					DebugExplorer.HookedFunctions = DebugExplorer.HookedFunctions or {}
					
					if HookWindow.GuiElems.Title.Text == "Hooking Connected Function" and DebugExplorer.SelectedConnectionFunc then
						local FuncId = tostring(DebugExplorer.SelectedConnectionFunc)
						DebugExplorer.HookedFunctions[FuncId] = true
						
						table.insert(DebugExplorer.ActiveHooks, {
							Inst = DebugExplorer.CurrentInstance,
							Type = "Conn Function",
							Name = "Func: " .. Lib.GetFuncDisplayName(DebugExplorer.SelectedConnectionFunc),
							Action = "Hooked",
							ScriptSource = Source,
							TargetFunc = DebugExplorer.SelectedConnectionFunc
						})
						DebugExplorer.RefreshLeftPane()
					elseif DebugExplorer.SelectedMember then
						table.insert(DebugExplorer.ActiveHooks, {
							Inst = DebugExplorer.SelectedMember.Target,
							Type = DebugExplorer.SelectedMember.Type,
							Name = DebugExplorer.SelectedMember.Name,
							Action = "Hooked",
							ScriptSource = Source
						})
						DebugExplorer.RefreshLeftPane()
					end
					
					if DebugExplorer.TreeViewEnabled then DebugExplorer.Refresh() else DebugExplorer.Refresh() end
					HookWindow:Close()
				else
					warn("Hook Execution Error: " .. tostring(Err))
				end
			end
		end)
		
		ConnWindow = Lib.Window.new()
		ConnWindow:SetTitle("Connections")
		ConnWindow:Resize(450, 300)
		
		ConnList = Instance.new("ScrollingFrame", ConnWindow.GuiElems.Content)
		ConnList.Size = UDim2.new(1, 0, 1, 0)
		ConnList.BackgroundTransparency = 1
		ConnList.BorderSizePixel = 0
		ConnList.ScrollBarThickness = 6
		
		local ConnLayout = Instance.new("UIListLayout", ConnList)
		ConnLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ConnLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ConnList.CanvasSize = UDim2.new(0, 0, 0, ConnLayout.AbsoluteContentSize.Y)
		end)
		
		SpoofWindow = Lib.Window.new()
		SpoofWindow.Alignable = false
		SpoofWindow.Resizable = false
		SpoofWindow:SetTitle("Spoof Value")
		SpoofWindow:SetSize(300, 130)

		local TypeLbl = Lib.Label.new()
		TypeLbl.Text = "Type:"
		TypeLbl.Position = UDim2.new(0, 10, 0, 10)
		TypeLbl.Size = UDim2.new(0, 50, 0, 20)
		SpoofWindow:Add(TypeLbl)

		SpoofDrop = Lib.DropDown.new()
		SpoofDrop.CanBeEmpty = false
		SpoofDrop.Size = UDim2.new(0, 210, 0, 20)
		SpoofDrop.Position = UDim2.new(0, 70, 0, 10)
		SpoofDrop:SetOptions({"string", "number", "boolean", "Color3", "CFrame", "Vector3"})
		SpoofDrop:SetSelected("string")
		SpoofWindow:Add(SpoofDrop, "TypeDrop")

		local ValLbl = Lib.Label.new()
		ValLbl.Text = "Value:"
		ValLbl.Position = UDim2.new(0, 10, 0, 40)
		ValLbl.Size = UDim2.new(0, 50, 0, 20)
		SpoofWindow:Add(ValLbl)

		SpoofBox = Lib.ViewportTextBox.new()
		SpoofBox.Position = UDim2.new(0, 70, 0, 40)
		SpoofBox.Size = UDim2.new(0, 210, 0, 20)
		SpoofWindow:Add(SpoofBox, "ValBox")

		local ConfirmSpoofBtn = Lib.Button.new()
		ConfirmSpoofBtn.Text = "Confirm Spoof"
		ConfirmSpoofBtn.Position = UDim2.new(0, 5, 1, -25)
		ConfirmSpoofBtn.Size = UDim2.new(1, -10, 0, 20)
		ConfirmSpoofBtn.OnClick:Connect(function()
			local StrType = SpoofDrop.Selected
			local StrVal = SpoofBox:GetText()
			local ValCode = StrVal
			if StrType == "string" then ValCode = '"' .. StrVal .. '"'
			elseif StrType == "boolean" then ValCode = string.lower(StrVal)
			elseif StrType == "Color3" then ValCode = "Color3.new(" .. StrVal .. ")"
			elseif StrType == "CFrame" then ValCode = "CFrame.new(" .. StrVal .. ")"
			elseif StrType == "Vector3" then ValCode = "Vector3.new(" .. StrVal .. ")" end
			
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Code = string.format([[-- Generated with DEX Recontinued by Tesker103
-- https://github.com/Tesker-103/DexRecontinued

local Inst = %s
local compare = compareinstances or rawequal
local o; o = hookfunction(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return %s
    end
    return o(...)
end))]], TargetPath, Mem.Name, ValCode)
			
			ApplyInstantHook("Spoofed: " .. tostring(ValCode), Code)
			SpoofWindow:Close()
			DebugExplorer.Refresh()
		end)
		SpoofWindow:Add(ConfirmSpoofBtn)

		Explorer.Selection.Changed:Connect(function()
			local Selected = Explorer.Selection.List[1]
			if Selected then
				DebugExplorer.CurrentInstance = Selected.Obj
			else
				DebugExplorer.CurrentInstance = nil
			end
			
			if Window:IsVisible() then
				DebugExplorer.Refresh()
			end
		end)
		
		Window.OnActivate:Connect(function()
			DebugExplorer.Refresh()
		end)
	end

	return DebugExplorer
end
return {InitDeps = InitDeps, InitAfterMain = InitAfterMain, Main = MainFunc}
end

}

-- Main vars
local Main, Explorer, Properties, ScriptViewer, DefaultSettings, Notebook, Serializer, Lib, Console, SaveInstance, DefaultSettings, ModelViewer, SettingsWindow, ThreadExplorer, EnvExplorer, DataExplorer, DebugExplorer
local API, RM

-- Default Settings
DefaultSettings = (function()
	local rgb = Color3.fromRGB	
	
	return {
		Explorer = {
			_Recurse = true,
			Sorting = true,
			TeleportToOffset = Vector3.new(0,0,0),
			ClickToRename = true,
			AutoUpdateSearch = true,
			AutoUpdateMode = 0,
			PartSelectionBox = true,
			GuiSelectionBox = true,
			CopyPathUseGetChildren = false,
			StopAutoScroll = false
		},
		Properties = {
			_Recurse = true,
			MaxConflictCheck = 50,
			ShowDeprecated = true,
			ShowHidden = true,
			ShowAllProperties = true,
			ClearOnFocus = false,
			LoadstringInput = true,
			NumberRounding = 3,
			ShowAttributes = true,
			ShowTags = true,
			MaxAttributes = 50,
			ScaleType = 0,
			ShowCopyButton = false
		},
		Theme = {
			_Recurse = true,
			Main1 = rgb(52,52,52),
			Main2 = rgb(45,45,45),
			Outline1 = rgb(33,33,33),
			Outline2 = rgb(55,55,55),
			Outline3 = rgb(30,30,30),
			TextBox = rgb(38,38,38),
			Menu = rgb(32,32,32),
			ListSelection = rgb(11,90,175),
			Button = rgb(60,60,60),
			ButtonHover = rgb(68,68,68),
			ButtonPress = rgb(40,40,40),
			Highlight = rgb(75,75,75),
			Text = rgb(255,255,255),
			PlaceholderText = rgb(100,100,100),
			Important = rgb(255,0,0),
			ExplorerIconMap = "",
			MiscIconMap = "",
			Syntax = {
				Text = rgb(204,204,204),
				Background = rgb(36,36,36),
				Selection = rgb(255,255,255),
				SelectionBack = rgb(11,90,175),
				Operator = rgb(204,204,204),
				Number = rgb(255,198,0),
				String = rgb(173,241,149),
				Comment = rgb(102,102,102),
				Keyword = rgb(248,109,124),
				Error = rgb(255,0,0),
				FindBackground = rgb(141,118,0),
				MatchingWord = rgb(85,85,85),
				BuiltIn = rgb(132,214,247),
				CurrentLine = rgb(45,50,65),
				LocalMethod = rgb(253,251,172),
				LocalProperty = rgb(97,161,241),
				Nil = rgb(255,198,0),
				Bool = rgb(255,198,0),
				Function = rgb(248,109,124),
				Local = rgb(248,109,124),
				Self = rgb(248,109,124),
				FunctionName = rgb(253,251,172),
				Bracket = rgb(204,204,204)
			},
		},
		ScriptViewer = {
			ShowMoreInfo = true;
		},
		Window = {
			TitleOnMiddle = false,
			Transparency = 0
		},
		Decompiler = {
			DecompilerFallback = "Konstant",
			PreferDecompilerFallback = false,
			ShinyDecompilerPort = 3000,
		},

		SaveInstance = {
			Method = "DexRESerializer"
		},
		
		RemoteBlockWriteAttribute = false,
		ClassIcon = "NewDark",
	}
end)()

-- Vars
local Settings = DefaultSettings or {}
local Apps = {}
local env = {}

local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:wait()

local create = function(data)
	local insts = {}
	for i,v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end

	for _,v in pairs(data) do
		for prop,val in pairs(v[3]) do
			if type(val) == "table" then
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end

	return insts[1]
end

local createSimple = function(class,props)
	local inst = Instance.new(class)
	for i,v in next,props do
		inst[i] = v
	end
	return inst
end

Main = (function()
	local Main = {}

	Main.ModuleList = {"Explorer", "Properties", "ScriptViewer", "Console", "SaveInstance", "ModelViewer", "SettingsWindow", "ThreadExplorer", "EnvExplorer", "DataExplorer", "DebugExplorer"}
	Main.Elevated = false
	Main.MissingEnv = {}
	Main.Version = "v1.2.1"
	Main.Mouse = plr:GetMouse()
	Main.AppControls = {}
	Main.Apps = Apps
	Main.MenuApps = {}

	Main.DisplayOrders = {
		SideWindow = 8,
		Window = 10,
		Menu = 100000,
		Core = 101000
	}

	Main.GetInitDeps = function()
		return {
			Main = Main,
			Lib = Lib,
			Apps = Apps,
			Settings = Settings,

			API = API,
			RMD = RMD,
			env = env,
			service = service,
			plr = plr,
			create = create,
			createSimple = createSimple
		}
	end

	Main.Error = function(str)
		if rconsoleprint then
			rconsoleprint("DEX ERROR: "..tostring(str).."\n")
			wait(9e9)
		else
			error(str)
		end
	end

	Main.LoadModule = function(name)
		--[[if Main.Elevated then -- If you don't have filesystem api then ur outta luck tbh
			local control

			if EmbeddedModules then -- Offline Modules
				control = EmbeddedModules[name]()

				if not control then Main.Error("Missing Embedded Module: "..name) end
			end

			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		else
			local module = script:WaitForChild("Modules"):WaitForChild(name, 2)
			if not module then Main.Error("CANNOT FIND MODULE " .. name) end

			local control = require(module)
			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		end]]
		local control

		if EmbeddedModules then -- Offline Modules
			control = EmbeddedModules[name]()

			if not control then Main.Error("Missing Embedded Module: "..name) end
		end

		Main.AppControls[name] = control
		control.InitDeps(Main.GetInitDeps())

		local moduleData = control.Main()
		Apps[name] = moduleData
		return moduleData
	end

	Main.LoadModules = function()
		for i,v in pairs(Main.ModuleList) do
			local s,e = pcall(Main.LoadModule,v)
			if not s then
				Main.Error(("FAILED LOADING %s CAUSE %s"):format(v, e))
			end
		end

		-- Init Major Apps and define them in modules
		Explorer = Apps.Explorer
		Properties = Apps.Properties
		ScriptViewer = Apps.ScriptViewer
		Console = Apps.Console
		SaveInstance = Apps.SaveInstance
		ModelViewer = Apps.ModelViewer
		SettingsWindow = Apps.SettingsWindow
		ThreadExplorer = Apps.ThreadExplorer
		Notebook = Apps.Notebook
		SettingsWindow = Apps.SettingsWindow
		EnvExplorer = Apps.EnvExplorer
		DebugExplorer = Apps.DebugExplorer
		DataExplorer = Apps.DataExplorer
		local appTable = {
			Explorer = Explorer,
			Properties = Properties,
			ScriptViewer = ScriptViewer,
			Console = Console,
			SaveInstance = SaveInstance,
			ModelViewer = ModelViewer,
			Notebook = Notebook,
			SettingsWindow = SettingsWindow,
			ThreadExplorer = ThreadExplorer,
			EnvExplorer = EnvExplorer,
			DataExplorer = DataExplorer,
			DebugExplorer = Apps.DebugExplorer
		}

		Main.AppControls.Lib.InitAfterMain(appTable)
		for i,v in pairs(Main.ModuleList) do
			local control = Main.AppControls[v]
			if control then
				control.InitAfterMain(appTable)
			end
		end
	end

	Main.InitEnv = function()
		setmetatable(env, {__newindex = function(self, name, func)
			if not func then Main.MissingEnv[#Main.MissingEnv + 1] = name return end
			rawset(self, name, func)
		end})

		-- file
		env.readfile = missing("function", readfile)
		env.writefile = missing("function", writefile)
		env.appendfile = missing("function", appendfile)
		env.makefolder = missing("function", makefolder)
		env.listfiles = missing("function", listfiles)
		env.isfile = missing("function", isfile)
		env.isfolder = missing("function", isfolder)
		env.loadfile = missing("function", loadfile)
		env.movefileas = missing("function", movefileas)
		local Serializers = {}
		env.saveinstance = missing("function", saveinstance) or function(obj, name, options)
			local method = Settings.SaveInstance and Settings.SaveInstance.Method or "DexRESerializer"
			
			if method == "UniversalSynSaveInstance" then
				if not Serializers.Syn then
					local success, res = pcall(function()
						return loadstring(oldgame:HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau"))()
					end)
					if success and type(res) == "function" then
						Serializers.Syn = res
					else
						return warn("Failed to load UniversalSynSaveInstance")
					end
				end
				
				options = options or {}
				options.Object = type(obj) == "table" and obj[1] or obj
				if type(name) == "string" then
					options.FilePath = name
				end
				return Serializers.Syn(options)
			else
				if not Serializers.Dex then
					local success, res = pcall(function()
						return loadstring(oldgame:HttpGet("https://raw.githubusercontent.com/Tesker-103/DexRecontinued/refs/heads/main/Serializer.lua"))()
					end)
					if success and type(res) == "table" and res.Save then
						pcall(res.Init)
						Serializers.Dex = res
					else
						return warn("Failed to load DexRESerializer")
					end
				end
				
				return Serializers.Dex.Save(obj, name, options)
			end
		end
		env.parsefile = function(name)
			return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
		end

		-- debug
		env.getupvalues = missing("function", (debug and debug.getupvalues) or getupvalues or getupvals)
		env.setupvalues = missing("function", (debug and debug.setupvalues) or setupvalues or setupvals)
		env.setconstants = missing("function", (debug and debug.setconstants) or setconstants or setconsts)
		env.setconstant = missing("function", (debug and debug.setconstant) or setconstant or setconst)
		env.setupvalue = missing("function", (debug and debug.setupvalue) or setupvalue or setupval)
		env.getconstants = missing("function", (debug and debug.getconstants) or getconstants or getconsts)
		env.getconnections = missing("function", getconnections or get_connections or get_conns)
		env.getinfo = missing("function", (debug and (debug.getinfo or debug.info)) or getinfo)
		env.getfunctionbytecode = missing("function", getfunctionbytecode)
		env.cansignalreplicate = missing("function", cansignalreplicate)
		env.islclosure = missing("function", islclosure or is_l_closure or is_lclosure)
		env.checkcaller = missing("function", checkcaller)
		env.getreg = missing("function", getreg)
		env.getgc = missing("function", getgc or get_gc_objects)
		env.hookmetamethod = missing("function", hookmetamethod)
		env.hookfunction = missing("function", hookfunction)

		local hookfunction = env.hookfunction
if oth and oth.hook then
    local old = hookfunction
    env.hookfunction = function(f1, f2)
        if debug.info(f1, "s") == "[C]" then
            return oth.hook(f1, f2)
        else
            return old(f1, f2)
        end
    end
end
		env.newcclosure = missing("function", newcclosure)
		env.restorefunction = missing("function", restorefunction)
		--env.base64encode = missing("function", crypt and crypt.base64 and crypt.base64.encode)
		env.getscriptbytecode = missing("function", getscriptbytecode)
		env.getscripts = missing("function", getscripts)
		env.gethiddenproperties = missing("function", gethiddenproperties)
		env.gethiddenproperty = missing("function", gethiddenproperty)
		env.sethiddenproperty = missing("function", sethiddenproperty)
		env.isscriptable = missing("function", isscriptable)
		env.setscriptable = missing("function", setscriptable)
		env.getproperties = missing("function", getproperties)
		env.getsignalwhitelist = missing("function", getsignalwhitelist)

		-- other
		--env.setfflag = missing("function", setfflag)
		env.request = missing("function", request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request))
		-- other
		env.request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
		
		env.isdecompile = function()
			return typeof(decompile) == "function" or typeof(getscriptbytecode) == "function" or false
		end
		
		-- DECOMPILERS
		local AdvancedDecompilerCache
		pcall(function()
			AdvancedDecompilerCache = loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/Advanced-Decompiler-V3/refs/heads/main/init.lua"))()
		end)
		
		local function base64Encode(data)
			local encoder = (crypt and crypt.base64encode) or (crypt and crypt.base64 and crypt.base64.encode) or (base64_encode)
			if encoder then
				local s, res = pcall(encoder, data)
				if s and res then return res end
			end
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			return ((data:gsub('.', function(x)
				local r,byte = '',x:byte()
				for i=8,1,-1 do r = r .. (byte % 2^i - byte % 2^(i-1) > 0 and '1' or '0') end
				return r
			end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
				if #x < 6 then return '' end
				local c = 0
				for i=1,6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
				return b:sub(c+1,c+1)
			end)..({ '', '==', '=' })[#data % 3 + 1])
		end

		local konstant_last_call = 0
		local function KonstantDec(...)
			local API = "http://api.plusgiant5.com"
			local request = env.request
			local function call(konstantType, scriptPath)
				local success, bytecode = pcall(env.getscriptbytecode, scriptPath)
				if (not success) then return "-- Failed to get script bytecode\n" end
				local time_elapsed = os.clock() - konstant_last_call
				if time_elapsed <= .5 then task.wait(.5 - time_elapsed) end
				local httpResult = env.request({
					Url = API .. konstantType, Body = bytecode, Method = "POST", Headers = {["Content-Type"] = "text/plain"}
				})
				konstant_last_call = os.clock()
				if (httpResult.StatusCode ~= 200) then return "-- Error occurred while requesting Konstant API\n" else return httpResult.Body end
			end
			return call("/konstant/decompile", ...)
		end

		local ADDec = AdvancedDecompilerCache or function() return "Failed to load Advanced Decompiler" end

		local lua_expert_last = 0
		local function LuaExpertDec(scr)
			if not env.getscriptbytecode then return "-- exploit does not support getscriptbytecode." end
			local ok, bytecode = pcall(env.getscriptbytecode, scr)
			if not ok then return "-- failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]" end

			local elapsed = os.clock() - lua_expert_last
			if elapsed < 0.12 then task.wait(0.12 - elapsed) end

			local res = env.request({
				Url = "https://api.lua.expert/decompile",
				Method = "POST",
				Headers = { ["content-type"] = "application/json" },
				Body = service.HttpService:JSONEncode({ script = base64Encode(bytecode) })
			})
			lua_expert_last = os.clock()

			if not res or res.StatusCode ~= 200 then
				return "-- api request error\n--[[\n" .. (res and res.Body or "no response") .. "\n--]]"
			end
			return res.Body
		end

		local function ShinyDec(script_instance)
			if typeof(crypt) ~= "table" then return "-- 'crypt' library is missing!" end
			local port = Settings.Decompiler and Settings.Decompiler.ShinyDecompilerPort or 3000
			local success, result = pcall(function() return game:HttpGet("http://127.0.0.1:"..tostring(port)) end)
			if not success then return "-- Shiny decompiler is not active or port is wrong!" end
			local bytecode = getscriptbytecode(script_instance)
			local encoded = base64Encode(bytecode)
			return env.request({
				Url = "http://127.0.0.1:"..tostring(port).."/luau/decompile", Method = "POST", Body = encoded
			}).Body
		end

		local function SabreDec(scr, mode)
			if not env.getscriptbytecode then return "-- Sabre: getscriptbytecode is not supported" end
			local ok, bytecode = pcall(env.getscriptbytecode, scr)
			if not ok or not bytecode or bytecode == "" then
				return "-- Sabre: Failed to get script bytecode"
			end

			local body = service.HttpService:JSONEncode({
				target = "luau",
				mode = mode or "decompile", -- Defaults to decompile if not specified
				bytecodeBase64 = base64Encode(bytecode),
			})

			local res = env.request({
				Url = "https://www.decompiler.lol/api/decompile",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
				},
				Body = body,
			})

			if not res or not res.Body then
				return "-- Sabre: No response body from server"
			end

			local ok_json, parsed = pcall(function()
				return service.HttpService:JSONDecode(res.Body)
			end)

			if not ok_json or type(parsed) ~= "table" then
				return "-- Sabre: Invalid JSON response: " .. tostring(res.Body):sub(1, 200)
			end

			if not parsed.ok then
				return "-- Sabre: " .. string.format("[%s] %s", parsed.stage or "?", parsed.error or "unknown error")
			end

			return parsed.output or "-- Sabre: Empty output"
		end

		local function DisassemblyDec(scr)
			return SabreDec(scr, "disasm")
		end

		local function X2125Dec(scr)
			if not env.getscriptbytecode then return "-- x2125: getscriptbytecode is not supported" end
			local ok, bytecode = pcall(env.getscriptbytecode, scr)
			if not ok or not bytecode or bytecode == "" then
				return "-- x2125: Failed to get script bytecode"
			end

			local res = env.request({
				Url = "https://x2125.xyz/decompile",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
				},
				Body = service.HttpService:JSONEncode({
					script = base64Encode(bytecode),
					options = {
						renamingType = "INFER",
						upvalueComment = true,
						lineDefinedComment = true,
					},
				}),
			})

			if not res or not res.Body then
				return "-- x2125: No response body"
			end

			if res.StatusCode == 200 then
				local ok_json, decoded = pcall(function()
					return service.HttpService:JSONDecode(res.Body)
				end)
				if ok_json and type(decoded) == "table" and type(decoded.data) == "string" then
					return decoded.data
				end
				return "-- x2125: Invalid server response structure"
			end

			local errorMsg = "HTTP " .. tostring(res.StatusCode)
			if type(res.Body) == "string" and res.Body ~= "" then
				local ok_json, edec = pcall(function()
					return service.HttpService:JSONDecode(res.Body)
				end)
				if ok_json and type(edec) == "table" and type(edec.error) == "string" then
					errorMsg = edec.error
				else
					errorMsg = res.Body
				end
			end

			return "-- x2125 Error: " .. errorMsg
		end

		local function BytefallDec(scr)
			if not env.getscriptbytecode then return "-- ByteFall: getscriptbytecode is not supported" end
			local ok, bytecode = pcall(env.getscriptbytecode, scr)
			if not ok or not bytecode or bytecode == "" then
				return "-- ByteFall: getscriptbytecode returned empty or failed"
			end

			local body = service.HttpService:JSONEncode({
				script = base64Encode(bytecode)
			})

			local res = env.request({
				Url = "https://beta.bytefall.dev/decompile",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Body = body,
			})

			if not res or not res.Body then
				return "-- ByteFall: No response body"
			end

			local code = res.StatusCode or 0
			if code == 200 then
				return res.Body
			elseif code == 400 then
				return "-- ByteFall (400 bad request): " .. tostring(res.Body)
			elseif code == 500 then
				return "-- ByteFall (500 decompilation failed): " .. tostring(res.Body)
			elseif code == 404 then
				return "-- ByteFall (404 not found): wrong endpoint?"
			else
				return "-- ByteFall (HTTP " .. tostring(code) .. "): " .. tostring(res.Body)
			end
		end

		env.decompile = function(...)
			if typeof(decompile) == "function" and (not Settings.Decompiler or Settings.Decompiler.PreferDecompilerFallback == false) then
				return decompile(...)
			elseif typeof(getscriptbytecode) == "function" then
				local fallbackMode = Settings.Decompiler and Settings.Decompiler.DecompilerFallback or "Konstant"
				if fallbackMode == "Konstant" then return KonstantDec(...)
				elseif fallbackMode == "AdvancedDecompiler" then return ADDec(...)
				elseif fallbackMode == "Shiny" then return ShinyDec(...)
				elseif fallbackMode == "LuaExpert" then return LuaExpertDec(...)
				elseif fallbackMode == "Sabre" then return SabreDec(...)
				elseif fallbackMode == "x2125" then return X2125Dec(...)
				elseif fallbackMode == "Bytefall" then return BytefallDec(...)
				elseif fallbackMode == "Disassembly" then return DisassemblyDec(...) -- New routing mapping
				end
			end
		end

		env.isViableDecompileScript = function(obj)
			if obj:IsA("ModuleScript") then
				return true
			elseif obj:IsA("LocalScript") and (obj.RunContext == Enum.RunContext.Client or obj.RunContext == Enum.RunContext.Legacy) then
				return true
			elseif obj:IsA("Script") and obj.RunContext == Enum.RunContext.Client then
				return true
			end
			return false
		end
		env.protectgui = missing("function", protect_gui or (syn and syn.protect_gui))
		env.gethui = missing("function", gethui or get_hidden_gui)
		env.setclipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
		env.getnilinstances = missing("function", getnilinstances or get_nil_instances)
		env.getprotos = missing("function", debug.getprotos)
		env.getsenv = missing("function", getsenv)
		env.iscclosure = missing("function", iscclosure)
		env.isourclosure = missing("function", isexecutorclosure or isourclosure)
		env.getfunctionhash = missing("function", getfunctionhash)
		env.loadstring = missing("function", loadstring)
		env.getloadedmodules = missing("function", getloadedmodules)

		env.tostring = function(...)
        local args = {...}
        local getrawmetatable = getrawmetatable or debug.getmetatable or getmetatable

        -- since varargs will automatically convert last args that are nil to nothing, we can just make them "nil" (not using table.pack)
        if #args < select("#", ...) then
            for i = #args+1, select("#",...) do
                args[i] = "nil"
            end
        end

        for i, v in pairs(args) do
            if (typeof(v) == "table" or typeof(v) == "userdata") and getrawmetatable(v) and rawget(getrawmetatable(v), "__tostring") then
                local mt = getrawmetatable(v)
                local func = rawget(mt, "__tostring")
                rawset(mt, "__tostring", nil)
                args[i] = tostring(v)
                rawset(mt, "__tostring", func)
            else
                args[i] = tostring(v)
            end
        end

        return unpack(args)
    end

		env.executor = (function()
			local identifyexec = identifyexecutor or getexecutorname or whatexecutor
			local success, name = pcall(function()
				return tostring(identifyexec())
			end)
			return success and name or "Your executor"
		end)()

		Main.GuiHolder = Main.Elevated and service.CoreGui or plr:FindFirstChildWhichIsA("PlayerGui")

		setmetatable(env, nil)
	end

	local function serialize(val)
		if typeof(val) == "Color3" then
			return {R = val.R, G = val.G, B = val.B}
		else
			return val
		end
	end
	
	local function deserialize(val)
		if typeof(val) == "table" and val.R and val.G and val.B then
			return Color3.new(val.R, val.G, val.B)
		else
			return val
		end
	end
	
	Main.ExportSettings = function()
		local rawData = Settings or DefaultSettings
		local function recur(tbl)
			local newTbl = {}
			for i, v in pairs(tbl) do
				if typeof(v) == "table" then
					newTbl[i] = recur(v)
				else
					newTbl[i] = serialize(v)
				end
			end
			return newTbl
		end
		local s, json = pcall(service.HttpService.JSONEncode, service.HttpService, recur(rawData))
		if s and json then return json end
	end

	Main.LoadSettings = function()
		local Success, Data = pcall(env.readfile or error, "DEX_REContinued/DexRESettings.json")
		Main.ResetSettings()
		
		if Success and Data and Data ~= "" then
			local DecodeSuccess, Decoded = pcall(service.HttpService.JSONDecode, service.HttpService, Data)
			if DecodeSuccess and Decoded then
				
				local function Merge(Target, Source)
				for Key, Value in pairs(Source) do
				if typeof(Value) == "table" then
						if Value.R and Value.G and Value.B then
						Target[Key] = Color3.new(Value.R, Value.G, Value.B)
						else
						if type(Target[Key]) ~= "table" then
						Target[Key] = {}
						end
						Merge(Target[Key], Value)
						end
						else
						Target[Key] = Value
						end
					end
				end
				Merge(Settings, Decoded)
			end
		end
	end

	Main.SaveCurrentSettings = function()
		if env.writefile then
			env.writefile("DEX_REContinued/DexRESettings.json", Main.ExportSettings())
		end
	end

	Main.ResetSettings = function()
		local function recur(t,res)
			for set,val in pairs(t) do
				if type(val) == "table" and val._Recurse then
					if type(res[set]) ~= "table" then
						res[set] = {}
					end
					recur(val,res[set])
				else
					res[set] = val
				end
			end
			return res
		end
		recur(DefaultSettings,Settings)
	end

	Main.UpdateThemeColor = function(oldColor, newColor)
		if oldColor == newColor then return end
		
		-- Use math.abs for Color3 comparison due to floating point inaccuracies
		local function cmp(c1, c2)
			return math.abs(c1.R - c2.R) < 0.01 and math.abs(c1.G - c2.G) < 0.01 and math.abs(c1.B - c2.B) < 0.01
		end
		
		local function scan(inst)
			pcall(function()
				if inst:IsA("GuiObject") then
					if cmp(inst.BackgroundColor3, oldColor) then inst.BackgroundColor3 = newColor end
					if cmp(inst.BorderColor3, oldColor) then inst.BorderColor3 = newColor end
					if inst:IsA("TextLabel") or inst:IsA("TextBox") or inst:IsA("TextButton") then
						if cmp(inst.TextColor3, oldColor) then inst.TextColor3 = newColor end
						if inst:IsA("TextBox") and cmp(inst.PlaceholderColor3, oldColor) then inst.PlaceholderColor3 = newColor end
					end
					if inst:IsA("ScrollingFrame") then
						if cmp(inst.ScrollBarImageColor3, oldColor) then inst.ScrollBarImageColor3 = newColor end
					end
				elseif inst:IsA("UIStroke") then
					if cmp(inst.Color, oldColor) then inst.Color = newColor end
				end
			end)
			for _, child in next, inst:GetChildren() do
				scan(child)
			end
		end
		
		if Main.GuiHolder then
			for _, child in next, Main.GuiHolder:GetChildren() do
				scan(child)
			end
		end
	end

	local function jsonDecode(str)
		local suc, res = pcall(service.HttpService.JSONDecode, service.HttpService, str)
		return suc and res or suc
	end

	Main.FetchAPI = function()
		local api,rawAPI
		if Main.Elevated then
			if Main.LocalDepsUpToDate() then
				local localAPI = Lib.ReadFile("DEX_REContinued/rbx_api.dat")
				if localAPI then 
					rawAPI = localAPI
				else
					Main.DepsVersionData[1] = ""
				end
			end
			rawAPI = rawAPI or oldgame:HttpGet("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/Full-API-Dump.json")
		else
			if script:FindFirstChild("API") then
				rawAPI = require(script.API)
			else
				error("NO API EXISTS")
			end
		end
		Main.RawAPI = rawAPI
		api = jsonDecode(rawAPI)

		-- backup for kaboom
		if not api then
			rawAPI = oldgame:HttpGet("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/Full-API-Dump.json")
			Main.RawAPI = rawAPI
			api = jsonDecode(rawAPI)
		end

		local classes,enums = {},{}
		local categoryOrder,seenCategories = {},{}

		local function insertAbove(t,item,aboveItem)
			local findPos = table.find(t,item)
			if not findPos then return end
			table.remove(t,findPos)

			local pos = table.find(t,aboveItem)
			if not pos then return end
			table.insert(t,pos,item)
		end

		for _,class in pairs(api.Classes) do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = class.Superclass
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then 
				for _,tag in pairs(class.Tags) do 
					if type(tag) == "string" then newClass.Tags[tag] = true end 
				end 
			end
			
			for __,member in pairs(class.Members) do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Security = member.Security
				newMember.Tags = {}
				
				if member.Tags then 
					for _,tag in pairs(member.Tags) do 
						if type(tag) == "string" then newMember.Tags[tag] = true end 
					end 
				end

				local mType = member.MemberType
				if mType == "Property" then
					local propCategory = member.Category or "Other"
					propCategory = propCategory:match("^%s*(.-)%s*$")
					if not seenCategories[propCategory] then
						categoryOrder[#categoryOrder+1] = propCategory
						seenCategories[propCategory] = true
					end
					newMember.ValueType = member.ValueType
					newMember.Category = propCategory
					newMember.Serialization = member.Serialization
					table.insert(newClass.Properties,newMember)
				elseif mType == "Function" then
					newMember.Parameters = {}
					newMember.ReturnType = member.ReturnType and member.ReturnType.Name or "void"
					if member.Parameters then
						for c,param in pairs(member.Parameters) do
							table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type and param.Type.Name or "any"})
						end
					end
					table.insert(newClass.Functions,newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					if member.Parameters then
						for c,param in pairs(member.Parameters) do
							table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type and param.Type.Name or "any"})
						end
					end
					table.insert(newClass.Events,newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _,class in pairs(classes) do
			class.Superclass = classes[class.Superclass]
		end

		for _,enum in pairs(api.Enums) do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then for c,tag in pairs(enum.Tags) do newEnum.Tags[tag] = true end end
			for __,item in pairs(enum.Items) do
				local newItem = {}
				newItem.Name = item.Name
				newItem.Value = item.Value
				table.insert(newEnum.Items,newItem)
			end

			enums[enum.Name] = newEnum
		end

		local function getMember(class,member)
			if not classes[class] or not classes[class][member] then return end
			local result = {}

			local currentClass = classes[class]
			while currentClass do
				for _,entry in pairs(currentClass[member]) do
					result[#result+1] = entry
				end
				currentClass = currentClass.Superclass
			end

			table.sort(result,function(a,b) return a.Name < b.Name end)
			return result
		end

		insertAbove(categoryOrder,"Behavior","Tuning")
		insertAbove(categoryOrder,"Appearance","Data")
		insertAbove(categoryOrder,"Attachments","Axes")
		insertAbove(categoryOrder,"Cylinder","Slider")
		insertAbove(categoryOrder,"Localization","Jump Settings")
		insertAbove(categoryOrder,"Surface","Motion")
		insertAbove(categoryOrder,"Surface Inputs","Surface")
		insertAbove(categoryOrder,"Part","Surface Inputs")
		insertAbove(categoryOrder,"Assembly","Surface Inputs")
		insertAbove(categoryOrder,"Character","Controls")
		categoryOrder[#categoryOrder+1] = "Unscriptable"
		categoryOrder[#categoryOrder+1] = "Attributes"
		categoryOrder[#categoryOrder+1] = "Tags"

		local categoryOrderMap = {}
		for i = 1,#categoryOrder do
			categoryOrderMap[categoryOrder[i]] = i
		end

		return {
			Classes = classes,
			Enums = enums,
			CategoryOrder = categoryOrderMap,
			GetMember = getMember
		}
	end

	Main.FetchRMD = function()
		local rawXML
		if Main.Elevated then
			if Main.LocalDepsUpToDate() then
				local localRMD = Lib.ReadFile("DEX_REContinued/rbx_rmd.dat")
				if localRMD then 
					rawXML = localRMD
				else
					Main.DepsVersionData[1] = ""
				end
			end
			rawXML = rawXML or oldgame:HttpGet("https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml")
		else
			if script:FindFirstChild("RMD") then
				rawXML = require(script.RMD)
			else
				error("NO RMD EXISTS")
			end
		end
		Main.RawRMD = rawXML
		local parsed = Lib.ParseXML(rawXML)
		local classList = parsed.children[1].children[1].children
		local enumList = parsed.children[1].children[2].children
		local propertyOrders = {}

		local classes,enums = {},{}
		for _,class in pairs(classList) do
			local className = ""
			for _,child in pairs(class.children) do
				if child.tag == "Properties" then
					local data = {Properties = {}, Functions = {}}
					local props = child.children
					for _,prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					className = data.Name
					classes[className] = data
				elseif child.attrs.class == "ReflectionMetadataProperties" then
					local members = child.children
					for _,member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _,prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								if data.PropertyOrder then
									local orders = propertyOrders[className]
									if not orders then orders = {} propertyOrders[className] = orders end
									orders[data.Name] = tonumber(data.PropertyOrder)
								end
								classes[className].Properties[data.Name] = data
							end
						end
					end
				elseif child.attrs.class == "ReflectionMetadataFunctions" then
					local members = child.children
					for _,member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _,prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								classes[className].Functions[data.Name] = data
							end
						end
					end
				end
			end
		end

		for _,enum in pairs(enumList) do
			local enumName = ""
			for _,child in pairs(enum.children) do
				if child.tag == "Properties" then
					local data = {Items = {}}
					local props = child.children
					for _,prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					enumName = data.Name
					enums[enumName] = data
				elseif child.attrs.class == "ReflectionMetadataEnumItem" then
					local data = {}
					if child.children[1].tag == "Properties" then
						local props = child.children[1].children
						for _,prop in pairs(props) do
							local name = prop.attrs.name
							name = name:sub(1,1):upper()..name:sub(2)
							data[name] = prop.children[1].text
						end
						enums[enumName].Items[data.Name] = data
					end
				end
			end
		end

		return {Classes = classes, Enums = enums, PropertyOrders = propertyOrders}
	end

	Main.ShowGui = function(gui)
		if env.gethui then
			gui.Parent = env.gethui()
			pcall(function() gui.OnTopOfCoreBlur = true end)
		elseif env.protectgui then
			env.protectgui(gui)
			gui.Parent = Main.GuiHolder
		else
			gui.Parent = Main.GuiHolder
		end
	end

	Main.CreateIntro = function(initStatus) -- TODO: Must theme and show errors
		local gui = create({
			{1,"ScreenGui",{Name="Intro",}},
			{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="Main",Parent={1},Position=UDim2.new(0.5,-175,0.5,-100),Size=UDim2.new(0,350,0,200),}},
			{3,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Holder",Parent={2},Size=UDim2.new(1,0,1,0),}},
			{4,"UIGradient",{Parent={3},Rotation=30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{5,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Title",Parent={3},Position=UDim2.new(0,-190,0,15),Size=UDim2.new(0,100,0,50),Text="Dex RE",TextColor3=Color3.new(1,1,1),TextSize=50,TextTransparency=1,}},
			{6,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Desc",Parent={3},Position=UDim2.new(0,-230,0,60),Size=UDim2.new(0,180,0,25),Text="Ultimate Debugging Suite",TextColor3=Color3.new(1,1,1),TextSize=18,TextTransparency=1,}},
			{7,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="StatusText",Parent={3},Position=UDim2.new(0,20,0,110),Size=UDim2.new(0,180,0,25),Text="Fetching API",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=1,}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ProgressBar",Parent={3},Position=UDim2.new(0,110,0,145),Size=UDim2.new(0,0,0,4),}},
			{9,"Frame",{BackgroundColor3=Color3.new(0.2392156869173,0.56078433990479,0.86274510622025),BorderSizePixel=0,Name="Bar",Parent={8},Size=UDim2.new(0,0,1,0),}},
			{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/2.png")) and getcustomasset("DEX_REContinued/2.png") or "rbxassetid://2764171053",ImageColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),Parent={8},ScaleType=1,Size=UDim2.new(1,0,1,0),SliceCenter=Rect.new(2,2,254,254),}},
			{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Creator",Parent={2},Position=UDim2.new(1,-110,1,-20),Size=UDim2.new(0,105,0,20),Text="Developed by Tesker103",TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=1,}},
			{12,"UIGradient",{Parent={11},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{13,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Version",Parent={2},Position=UDim2.new(1,-110,1,-35),Size=UDim2.new(0,105,0,20),Text=Main.Version,TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=1,}},
			{14,"UIGradient",{Parent={13},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{15,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image="",Name="Outlines",Parent={2},Position=UDim2.new(0,-5,0,-5),ScaleType=1,Size=UDim2.new(1,10,1,10),SliceCenter=Rect.new(6,6,25,25),TileSize=UDim2.new(0,20,0,20),}},
			{16,"UIGradient",{Parent={15},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{17,"UIGradient",{Parent={2},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
		})
		Main.ShowGui(gui)
		local backGradient = gui.Main.UIGradient
		local outlinesGradient = gui.Main.Outlines.UIGradient
		local holderGradient = gui.Main.Holder.UIGradient
		local titleText = gui.Main.Holder.Title
		local descText = gui.Main.Holder.Desc
		local versionText = gui.Main.Version
		local versionGradient = versionText.UIGradient
		local creatorText = gui.Main.Creator
		local creatorGradient = creatorText.UIGradient
		local statusText = gui.Main.Holder.StatusText
		local progressBar = gui.Main.Holder.ProgressBar
		local tweenS = service.TweenService

		local renderStepped = service.RunService.RenderStepped
		local signalWait = renderStepped.wait
		local fastwait = function(s)
			if not s then return signalWait(renderStepped) end
			local start = tick()
			while tick() - start < s do signalWait(renderStepped) end
		end

		statusText.Text = initStatus

		local function tweenNumber(n,ti,func)
			local tweenVal = Instance.new("IntValue")
			tweenVal.Value = 0
			tweenVal.Changed:Connect(func)
			local tween = tweenS:Create(tweenVal,ti,{Value = n})
			tween:Play()
			tween.Completed:Connect(function()
				tweenVal:Destroy()
			end)
		end

		local ti = TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		tweenNumber(100,ti,function(val)
			val = val/200
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(math.min(0.5,val+math.min(0.05,val)),1)
			if a1.Time == a2.Time then a2 = a1 end
			local b1 = NumberSequenceKeypoint.new(1-val,0)
			local b2 = NumberSequenceKeypoint.new(math.max(0.5,1-val-math.min(0.05,val)),1)
			if b1.Time == b2.Time then b2 = b1 end
			local goal = NumberSequenceKeypoint.new(1,0)
			backGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
			outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
		end)

		fastwait(0.4)

		tweenNumber(100,ti,function(val)
			val = val/166.66
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(val+0.01,1)
			local goal = NumberSequenceKeypoint.new(1,1)
			holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
		end)

		tweenS:Create(titleText,ti,{Position = UDim2.new(0,60,0,15), TextTransparency = 0}):Play()
		tweenS:Create(descText,ti,{Position = UDim2.new(0,20,0,60), TextTransparency = 0}):Play()

		local function rightTextTransparency(obj)
			tweenNumber(100,ti,function(val)
				val = val/100
				local a1 = NumberSequenceKeypoint.new(1-val,0)
				local a2 = NumberSequenceKeypoint.new(math.max(0,1-val-0.01),1)
				if a1.Time == a2.Time then a2 = a1 end
				local start = NumberSequenceKeypoint.new(0,a1 == a2 and 0 or 1)
				local goal = NumberSequenceKeypoint.new(1,0)
				obj.Transparency = NumberSequence.new({start,a2,a1,goal})
			end)
		end
		rightTextTransparency(versionGradient)
		rightTextTransparency(creatorGradient)

		fastwait(0.9)

		local progressTI = TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

		tweenS:Create(statusText,progressTI,{Position = UDim2.new(0,20,0,120), TextTransparency = 0}):Play()
		tweenS:Create(progressBar,progressTI,{Position = UDim2.new(0,60,0,145), Size = UDim2.new(0,100,0,4)}):Play()

		fastwait(0.25)

		local function setProgress(text,n)
			statusText.Text = text
			tweenS:Create(progressBar.Bar,progressTI,{Size = UDim2.new(n,0,1,0)}):Play()
		end

		local function close()
			tweenS:Create(titleText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(descText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(versionText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(creatorText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(statusText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(progressBar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.Bar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.ImageLabel,progressTI,{ImageTransparency = 1}):Play()

			tweenNumber(100,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),function(val)
				val = val/250
				local start = NumberSequenceKeypoint.new(0,0)
				local a1 = NumberSequenceKeypoint.new(0.6+val,0)
				local a2 = NumberSequenceKeypoint.new(math.min(1,0.601+val),1)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 0 or 1)
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.5)
			gui.Main.BackgroundTransparency = 1
			outlinesGradient.Rotation = 30

			tweenNumber(100,ti,function(val)
				val = val/100
				local start = NumberSequenceKeypoint.new(0,1)
				local a1 = NumberSequenceKeypoint.new(val,1)
				local a2 = NumberSequenceKeypoint.new(math.min(1,val+math.min(0.05,val)),0)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 1 or 0)
				outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.45)
			gui:Destroy()
		end

		return {SetProgress = setProgress, Close = close}
	end

	Main.CreateApp = function(data)
		if Main.MenuApps[data.Name] then return end -- TODO: Handle conflict
		local control = {}

		local app = Main.AppTemplate:Clone()

		local iconIndex = data.Icon
		if data.IconMap and iconIndex then
			if type(iconIndex) == "number" then
				data.IconMap:Display(app.Main.Icon,iconIndex)
			elseif type(iconIndex) == "string" then
				data.IconMap:DisplayByKey(app.Main.Icon,iconIndex)
			end
		elseif type(iconIndex) == "string" then
			app.Main.Icon.Image = iconIndex
		else
			app.Main.Icon.Image = ""
		end

		local function updateState()
			app.Main.BackgroundTransparency = data.Open and 0 or (Lib.CheckMouseInGui(app.Main) and 0 or 1)
			app.Main.Highlight.Visible = data.Open
		end

		local function enable(silent)
			if data.Open then return end
			data.Open = true
			updateState()
			if not silent then
				if data.Window then data.Window:Show() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		local function disable(silent)
			if not data.Open then return end
			data.Open = false
			updateState()
			if not silent then
				if data.Window then data.Window:Hide() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		updateState()

		local ySize = service.TextService:GetTextSize(data.Name,14,Enum.Font.SourceSans,Vector2.new(62,999999)).Y
		app.Main.Size = UDim2.new(1,0,0,math.clamp(46+ySize,60,74))
		app.Main.AppName.Text = data.Name

		app.Main.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				app.Main.BackgroundTransparency = 0
				app.Main.BackgroundColor3 = Settings.Theme.ButtonHover
			end
		end)

		app.Main.InputEnded:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				app.Main.BackgroundTransparency = data.Open and 0 or 1
				app.Main.BackgroundColor3 = Settings.Theme.Button
			end
		end)

		app.Main.MouseButton1Click:Connect(function()
			if data.Open then disable() else enable() end
		end)

		local window = data.Window
		if window then
			window.OnActivate:Connect(function() enable(true) end)
			window.OnDeactivate:Connect(function() disable(true) end)
		end

		app.Visible = true
		app.Parent = Main.AppsContainer
		Main.AppsFrame.CanvasSize = UDim2.new(0,0,0,Main.AppsContainerGrid.AbsoluteCellCount.Y*82 + 8)

		control.Enable = enable
		control.Disable = disable
		Main.MenuApps[data.Name] = control
		return control
	end

	Main.SetMainGuiOpen = function(val)
		Main.MainGuiOpen = val

		Main.MainGui.OpenButton.Text = val and "X" or "DexRE"
		if val then Main.MainGui.OpenButton.MainFrame.Visible = true end
		Main.MainGui.OpenButton.MainFrame:TweenSize(val and UDim2.new(0,224,0,200) or UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true)
		--Main.MainGui.OpenButton.BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(Main.MainGui.OpenButton) and 0 or 0.2)
		service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(Main.MainGui.OpenButton) and 0 or 0.2)}):Play()

		if Main.MainGuiMouseEvent then Main.MainGuiMouseEvent:Disconnect() end

		if not val then
			local startTime = tick()
			Main.MainGuiCloseTime = startTime
			coroutine.wrap(function()
				Lib.FastWait(0.2)
				if not Main.MainGuiOpen and startTime == Main.MainGuiCloseTime then Main.MainGui.OpenButton.MainFrame.Visible = false end
			end)()
		else
			Main.MainGuiMouseEvent = service.UserInputService.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Lib.CheckMouseInGui(Main.MainGui.OpenButton) and not Lib.CheckMouseInGui(Main.MainGui.OpenButton.MainFrame) then

					Main.SetMainGuiOpen(false)
				end
			end)
		end
	end

	Main.CreateMainGui = function()
		local gui = create({
			{1,"ScreenGui",{IgnoreGuiInset=true,Name="MainMenu",}},
			{2,"TextButton",{AnchorPoint=Vector2.new(0.5,0),AutoButtonColor=false,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,Font=4,Name="OpenButton",Parent={1},Position=UDim2.new(0.5,0,0,2),Size=UDim2.new(0,44,0,32),Text="DexRE",TextColor3=Color3.new(1,1,1),TextSize=16,TextTransparency=0.20000000298023,}},
			{3,"UICorner",{CornerRadius=UDim.new(0,4),Parent={2},}},
			{4,"Frame",{AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),ClipsDescendants=true,Name="MainFrame",Parent={2},Position=UDim2.new(0.5,0,1,-4),Size=UDim2.new(0,224,0,200),}},
			{5,"UICorner",{CornerRadius=UDim.new(0,4),Parent={4},}},
			{6,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),Name="BottomFrame",Parent={4},Position=UDim2.new(0,0,1,-24),Size=UDim2.new(1,0,0,24),}},
			{7,"UICorner",{CornerRadius=UDim.new(0,4),Parent={6},}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="CoverFrame",Parent={6},Size=UDim2.new(1,0,0,4),}},
			{9,"Frame",{BackgroundColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),BorderSizePixel=0,Name="Line",Parent={8},Position=UDim2.new(0,0,0,-1),Size=UDim2.new(1,0,0,1),}},
			{10,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Settings",Parent={6},Position=UDim2.new(1,-48,0,0),Size=UDim2.new(0,24,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{11,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/settings.png")) and getcustomasset("DEX_REContinued/Images/settings.png") or "rbxassetid://6578871732",ImageTransparency=0.20000000298023,Name="Icon",Parent={10},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{12,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Information",Parent={6},Position=UDim2.new(1,-24,0,0),Size=UDim2.new(0,24,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{13,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/info.png")) and getcustomasset("DEX_REContinued/Images/info.png") or "rbxassetid://6578933307",ImageTransparency=0.20000000298023,Name="Icon",Parent={12},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{14,"ScrollingFrame",{Active=true,AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),BorderSizePixel=0,Name="AppsFrame",Parent={4},Position=UDim2.new(0.5,0,0,0),ScrollBarImageColor3=Color3.new(0,0,0),ScrollBarThickness=4,Size=UDim2.new(0,222,1,-25),}},
			{15,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Container",Parent={14},Position=UDim2.new(0,7,0,8),Size=UDim2.new(1,-14,0,2),}},
			{16,"UIGridLayout",{CellSize=UDim2.new(0,66,0,74),Parent={15},SortOrder=2,}},
			{17,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="App",Parent={1},Size=UDim2.new(0,100,0,100),Visible=false,}},
			{18,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderSizePixel=0,Font=3,Name="Main",Parent={17},Size=UDim2.new(1,0,0,60),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
			{19,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=(getcustomasset and isfile and isfile("DEX_REContinued/Images/icons.png")) and getcustomasset("DEX_REContinued/Images/icons.png") or "rbxassetid://6579106223",ImageRectSize=Vector2.new(32,32),Name="Icon",Parent={18},Position=UDim2.new(0.5,-16,0,4),ScaleType=4,Size=UDim2.new(0,32,0,32),}},
			{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="AppName",Parent={18},Position=UDim2.new(0,2,0,38),Size=UDim2.new(1,-4,1,-40),Text="Explorer",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextWrapped=true,TextYAlignment=0,}},
			{21,"Frame",{BackgroundColor3=Color3.new(0,0.66666668653488,1),BorderSizePixel=0,Name="Highlight",Parent={18},Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),}},
		})
		Main.MainGui = gui
		Main.AppsFrame = gui.OpenButton.MainFrame.AppsFrame
		Main.AppsContainer = Main.AppsFrame.Container
		Main.AppsContainerGrid = Main.AppsContainer.UIGridLayout
		Main.AppTemplate = gui.App
		Main.MainGuiOpen = false

		local openButton = gui.OpenButton
		openButton.BackgroundTransparency = 0.2
		openButton.MainFrame.Size = UDim2.new(0,0,0,0)
		openButton.MainFrame.Visible = false
		openButton.MouseButton1Click:Connect(function()
			Main.SetMainGuiOpen(not Main.MainGuiOpen)
		end)

		openButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = 0}):Play()
			end
		end)

		openButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = Main.MainGuiOpen and 0 or 0.2}):Play()
			end
		end)

		openButton.MainFrame.BottomFrame.Settings.MouseButton1Click:Connect(function()
			if not SettingsWindow.Window.Closed then
				SettingsWindow.Window:Hide()
			else
				SettingsWindow.Window:Show()
			end		
		end)

		local AboutWindow
		openButton.MainFrame.BottomFrame.Information.MouseButton1Click:Connect(function()
			if AboutWindow then
				if AboutWindow.Closed then
					AboutWindow:Show()
				else
					AboutWindow:Close()
				end
				return
			end
			AboutWindow = Lib.Window.new()
			AboutWindow.Resizable = true
			AboutWindow.Alignable = false
			AboutWindow:SetTitle("About")
			AboutWindow:Resize(320, 220)
			
			local content = AboutWindow.GuiElems.Content
			
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -24, 0, 30)
			title.Position = UDim2.fromOffset(12, 10)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.BuilderSansExtraBold
			title.Text = "DEX REContinued"
			title.TextColor3 = Settings.Theme.Text
			title.TextSize = 28
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = content

			local desc = Instance.new("TextLabel")
			desc.Size = UDim2.new(1, -24, 0, 80)
			desc.Position = UDim2.fromOffset(12, 45)
			desc.BackgroundTransparency = 1
			desc.Font = Enum.Font.SourceSans
			desc.Text = "DEX REContinued is a recontinuation of the old DEX Explorer with many features from the original roadmap\nThis DEX will try to the keep old stuff updated, and it should be less detected, and add new features\n\nJoin the server for help:"
			desc.TextColor3 = Settings.Theme.TextDim or Color3.fromRGB(200, 200, 200)
			desc.TextSize = 13
			desc.TextWrapped = true
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.TextYAlignment = Enum.TextYAlignment.Top
			desc.Parent = content

			local dsg= Instance.new("TextButton")
			dsg.Size = UDim2.new(1, -24, 0, 20)
			dsg.Position = UDim2.fromOffset(12, 125)
			dsg.BackgroundTransparency = 1
			dsg.Font = Enum.Font.SourceSansBold
			dsg.Text = "https://discord.com/invite/xGucmFjGVD"
			dsg.TextColor3 = Color3.fromRGB(0, 170, 255)
			dsg.TextSize = 13
			dsg.TextXAlignment = Enum.TextXAlignment.Left
			dsg.Parent = content
			
			dsg.MouseButton1Click:Connect(function()
				if env.setclipboard then
					env.setclipboard("https://discord.com/invite/xGucmFjGVD")
					pcall(function()
					local Url = 'https://discord.com/invite/xGucmFjGVD'
cloneref(game:GetService("WebViewService")):OpenWindowV2(Url)
task.wait(6.5)
cloneref(game:GetService("WebViewService")):CloseWindow()
				end)
end
			end)

			local a = Instance.new("TextLabel")
			a.Size = UDim2.new(1, -24, 0, 20)
			a.Position = UDim2.fromOffset(12, 155)
			a.BackgroundTransparency = 1
			a.Font = Enum.Font.SourceSans
			a.Text = "- Made by Tesker103"
			a.TextColor3 = Settings.Theme.TextFaded or Color3.fromRGB(150, 150, 150)
			a.TextSize = 13
			a.TextXAlignment = Enum.TextXAlignment.Left
			a.Parent = content
			
			AboutWindow:Show()
		end)

		-- Create Main Apps
		Main.CreateApp({Name = "Explorer", IconMap = Main.LargeIcons, Icon = "Explorer", Open = true, Window = Explorer.Window})

		Main.CreateApp({Name = "Properties", IconMap = Main.LargeIcons, Icon = "Properties", Open = true, Window = Properties.Window})

		Main.CreateApp({Name = "Script Viewer", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = ScriptViewer.Window})

		local cptsOnMouseClick = nil
		Main.CreateApp({Name = "Click part to select", IconMap = Explorer.ClassIcons, Icon = "SelectionBox", OnClick = function(callback)
			if callback then
				local mouse = Main.Mouse
				cptsOnMouseClick = mouse.Button1Down:Connect(function()
					pcall(function()
						local object = mouse.Target
						if nodes[cloneref(object)] then
							selection:Set(nodes[cloneref(object)])
							Explorer.ViewNode(nodes[cloneref(object)])
						end
					end)
				end)
			else if cptsOnMouseClick ~= nil then cptsOnMouseClick:Disconnect() cptsOnMouseClick = nil end end
		end})

		Main.CreateApp({Name = "Console", IconMap = Main.LargeIcons, Icon = "Output", Window = Console.Window})

		Main.CreateApp({Name = "Save Instance", IconMap = Main.LargeIcons, Icon = "Watcher", Window = SaveInstance.Window})

		Main.CreateApp({Name = "3D Viewer", IconMap = Main.LargeIcons, Icon = 8, Window = ModelViewer.Window})
		
		Main.CreateApp({Name = "Thread Explorer", IconMap = Explorer.LegacyClassIcons, Icon = 18, Window = ThreadExplorer.Window})

		Main.CreateApp({Name = "Data Explorer", IconMap = Main.LargeIcons, Icon = "Honey", Window = DataExplorer.Window})

		Main.CreateApp({Name = "Debugging Interface", IconMap = Main.LargeIcons, Icon = "ScriptEdit", Window = DebugExplorer.Window})

		Lib.ShowGui(gui)
	end

	Main.SetupFilesystem = function()
		if not env.writefile or not env.makefolder then return end
		local writefile, makefolder = env.writefile, env.makefolder
		makefolder("DEX_REContinued")
		makefolder("DEX_REContinued/assets")
		makefolder("DEX_REContinued/saved")
		makefolder("DEX_REContinued/plugins")
		makefolder("DEX_REContinued/ModuleCache")
	end

	Main.LocalDepsUpToDate = function()
		return Main.DepsVersionData and Main.ClientVersion == Main.DepsVersionData[1]
	end

	Main.Init = function()
		Main.Elevated = pcall(function() local a = service.CoreGui:GetFullName() end)

		Main.InitEnv()
		Main.SetupFilesystem()
		
		if env.isfile and not env.isfile("DEX_REContinued/DexRESettings.json") then
			Main.SaveCurrentSettings()
		end
		Main.LoadSettings()

		-- Load Lib
		local intro = Main.CreateIntro("Initializing Library")
		Lib = Main.LoadModule("Lib")
		Lib.FastWait()

		-- Download images
		if env.writefile and env.makefolder and env.isfile then
			if not env.isfolder("DEX_REContinued") then env.makefolder("DEX_REContinued") end
			local assets = {
				{Path = "DEX_REContinued/Images/Test_Icons.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_Test_Icons.png"},
				{Path = "DEX_REContinued/Images/search2.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_search2.png"},
				{Path = "DEX_REContinued/Images/refresh-icon3.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_refresh-icon3.png"},
				{Path = "DEX_REContinued/content_copy_1000dp_FFFFFF_FILL0_wght400_GRAD0_op.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/content_copy_1000dp_FFFFFF_FILL0_wght400_GRAD0_op.png"},
				{Path = "DEX_REContinued/Images/settings2.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_settings2.png"},
				{Path = "DEX_REContinued/Images/close3.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_close3.png"},
				{Path = "DEX_REContinued/Images/minimize2.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_minimize2.png"},
				{Path = "DEX_REContinued/borders.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/borders.png"},
				{Path = "DEX_REContinued/Images/arrow3.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_arrow3.png"},
				{Path = "DEX_REContinued/Images/squares_icon2.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_squares_icon2.png"},
				{Path = "DEX_REContinued/Images/checkmark.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_checkmark.png"},
				{Path = "DEX_REContinued/Images/checkmark (2).png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_checkmark%20(2).png"},
				{Path = "DEX_REContinued/luvlies.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/luvlies.png"},
				{Path = "DEX_REContinued/honey icon.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/honey%20icon.png"},
				{Path = "DEX_REContinued/colors.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/colors.png"},
				{Path = "DEX_REContinued/colorstrip.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/colorstrip.png"},
				{Path = "DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png"},
				{Path = "DEX_REContinued/2.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/2.png"},
				{Path = "DEX_REContinued/Images/settings.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_settings.png"},
				{Path = "DEX_REContinued/Images/info.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_info.png"},
				{Path = "DEX_REContinued/Images/icons.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_icons.png"},
				{Path = "DEX_REContinued/Images/NewestIcons.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_NewestIcons.png"},
				{Path = "DEX_REContinued/Images/icondraft.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Images_icondraft.png"},
				{Path = "DEX_REContinued/sprite_sheet (1).png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/sprite_sheet%20(1).png"},
				{Path = "DEX_REContinued/Texture.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/Texture.png"},
				{Path = "DEX_REContinued/Images/NewerTopbarIcons.png", Url = "https://github.com/Tesker-103/DexRecontinued/raw/refs/heads/main/Assets/NewerTopbarIcons.png"},
			}

			local total = #assets
			for i, asset in next, assets do
				intro.SetProgress("Downloading Images... (" .. i .. "/" .. total .. ")", 0.05 + ((i / total) * 0.2))
				
				if not env.isfile(asset.Path) then
					pcall(function()
						local data = oldgame:HttpGet(asset.Url)
						if data then env.writefile(asset.Path, data) end
					end)
					task.wait(0.02)
				end
			end
		end

		-- Init icons
		Main.MiscIcons = Lib.IconMap.new((getcustomasset and isfile and isfile("DEX_REContinued/Images/NewestIcons.png")) and getcustomasset("DEX_REContinued/Images/NewestIcons.png") or "rbxassetid://6511490623",256,256,16,16)

		Main.MiscIcons:SetDict({
			["Reference"] = 0;
			["Cut"] = 1;
			["Cut_Disabled"] = 2;
			["Copy"] = 3;
			["Copy_Disabled"] = 4;
			["Paste"] = 5;
			["Paste_Disabled"] = 6;
			["Delete"] = 7;
			["Delete_Disabled"] = 8;
			["Group"] = 9;
			["Group_Disabled"] = 10;
			["Ungroup"] = 11;
			["Ungroup_Disabled"] = 12;
			["TeleportTo"] = 13;
			["Rename"] = 14;
			["JumpToParent"] = 15;
			["ExploreData"] = 16;
			["Save"] = 17;
			["CallFunction"] = 18;
			["CallRemote"] = 19;
			["Undo"] = 20,
			["Undo_Disabled"] = 21;
			["Redo"] = 22;
			["Redo_Disabled"] = 23;
			["Expand_Over"] = 24;
			["Expand"] = 25;
			["Collapse_Over"] = 26;
			["Collapse"] = 27;
			["SelectChildren"] = 28;
			["SelectChildren_Disabled"] = 29;
			["InsertObject"] = 30;
			["ViewScript"] = 31;
			["AddStar"] = 32;
			["RemoveStar"] = 33;
			["Script_Disabled"] = 34;
			["LocalScript_Disabled"] = 35;
			["Play"] = 36;
			["Pause"] = 37;
			["Rename_Disabled"] = 38;
		})
		Main.LargeIcons = Lib.IconMap.new((getcustomasset and isfile and isfile("DEX_REContinued/Images/NewerTopbarIcons.png")) and getcustomasset("DEX_REContinued/Images/NewerTopbarIcons.png") or "rbxassetid://129589545519436",256,256,32,32)
		Main.LargeIcons:SetDict({
			Explorer = 0, Properties = 1, Script_Viewer = 2, Watcher = 3, Output = 4, ScriptEdit = 5, Book = 6, Executor = 7, Object = 8, Honey = 9
		})

		-- Fetch version if needed
		intro.SetProgress("Fetching Roblox Version",0.2)
		if Main.Elevated then
			local fileVer = Lib.ReadFile("dex/deps_version.dat")
			Main.ClientVersion = Version()

			if fileVer then
				Main.DepsVersionData = string.split(fileVer,"\n")
				if Main.LocalDepsUpToDate() then
					Main.RobloxVersion = Main.DepsVersionData[2]
				end
			end
			local s, result = pcall(function()
				return oldgame:HttpGet("https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE")
			end)
			if s and result then
				Main.RobloxVersion = Main.RobloxVersion or result:match('"(version%-[%w]+)"')
			end

			-- backup for kaboom
			if #Main.RobloxVersion < 1 then
				Main.RobloxVersion = oldgame:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/deps_version.dat"):gsub("%s+", "")
			end
		end

		-- Fetch external deps
		intro.SetProgress("Fetching API",0.35)
		API = Main.FetchAPI()
		Lib.FastWait()
		intro.SetProgress("Fetching RMD",0.5)
		RMD = Main.FetchRMD()
		Lib.FastWait()

		-- Save external deps locally if needed
		if Main.Elevated and env.writefile and not Main.LocalDepsUpToDate() then
			env.writefile("dex/deps_version.dat",Main.ClientVersion.."\n"..Main.RobloxVersion)
			env.writefile("dex/rbx_api.dat",Main.RawAPI)
			env.writefile("dex/rbx_rmd.dat",Main.RawRMD)
		end

		-- Load other modules
		intro.SetProgress("Loading Modules",0.75)
		Main.AppControls.Lib.InitDeps(Main.GetInitDeps()) -- Missing deps now available
		Main.LoadModules()
		Lib.FastWait()

		-- Init other modules
		intro.SetProgress("Initializing Modules",0.9)
		Explorer.Init()
		Properties.Init()
		ScriptViewer.Init()
		Console.Init()
		SaveInstance.Init()
		ModelViewer.Init()
		SettingsWindow.Init()
		ThreadExplorer.Init()
		EnvExplorer.Init()
		DataExplorer.Init()
		DebugExplorer.Init()
		Lib.FastWait()

		-- Done
		intro.SetProgress("Complete",1)
		coroutine.wrap(function()
			Lib.FastWait(1.25)
			intro.Close()
		end)()

		-- Init window system, create main menu, show explorer and properties
		Lib.Window.Init()
		Main.CreateMainGui()
		Explorer.Window:Show({Align = "right", Pos = 1, Size = 0.5, Silent = true})
		Properties.Window:Show({Align = "right", Pos = 2, Size = 0.5, Silent = true})
		Lib.Window.UpdateTransparency()
		Lib.DeferFunc(function() Lib.Window.ToggleSide("right") end)
	end

	return Main
end)()

-- Start
Main.Init()