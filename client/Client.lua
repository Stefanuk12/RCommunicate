-- // Configuration
local OwnerUserId = 9123944 -- // roblox id of the owner (that controls all of the alts)
local Host = "127.0.0.1" -- // localhost, your machine
local Port = 69420
local WSURLFormat = "ws://%s:%d/"
local CommandHandlerConfig = {
    Prefix = ".",
    ArgSeperator = " "
}

----------- // Setup (you don't really need to change anything below)

-- // Dependencies
local SignalManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Signal/main/Manager.lua"))()
local CommandHandler, CommandClass = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/ROBLOX/master/Universal/Commands/Module.lua"))()

-- // Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- // Vars
local Handler
local Websocket
local LocalPlayer = Players.LocalPlayer
do
    -- // Create our command handler
    Handler = CommandHandler.new(CommandHandlerConfig)

    -- // A websocket wrapper (so it can support many exploits)
    local WebsocketClass = {}
    WebsocketClass.__index = WebsocketClass
    do
        -- // Vars
        local WebsocketConnect
        if (syn) then
            WebsocketConnect = syn.websocket.connect
        end
        if (WebSocket) then
            WebsocketConnect = WebSocket.connect
        end

        -- // Constructor
        function WebsocketClass.new(URL)
            -- // Create object
            local self = setmetatable({}, WebsocketClass)

            -- // Vars
            self.URL = URL

            -- // init
            self:InitialiseSignals()

            -- // Return object
            return self
        end

        -- // Initialise the signals (create them)
        function WebsocketClass.InitialiseSignals(self)
            -- // Create the object
            self.Signals = SignalManager.new()

            -- // Create each signal
            self.Signals:Add("Connection")
            self.Signals:Add("Disconnect")
            self.Signals:Add("Message")
        end

        -- // What happens when we get a message
        function WebsocketClass.OnMessage(self, Payload)
            self.Signals:Fire("Message", Payload)
        end

        -- // What happens when the connection closes
        function WebsocketClass.OnDisconnect(self)
            self.Signals:Fire("Disconnect")
        end

        -- // Connects to the websocket
        function WebsocketClass.Connect(self)
            -- // v3
            if (WebsocketClient) then
                -- // Create the client and connect
                self.Client = WebsocketClient.new(self.URL)
                self.Client:Connect()

                -- // Initialise the signals
                self.Signals:Fire("Connection", self.URL)
                self.Client.DataReceived:Connect(function(Payload, _isBinary)
                    self:OnMessage(Payload)
                end)
                self.Client.ConnectionClosed = function()
                    self:OnDisconnect()
                end
                self.v3 = true

                -- //
                return "SynapseV3"
            end

            -- // others

            -- // Connect to the websocket
            self.Client = WebsocketConnect(self.URL)

            -- // Initialise the signals
            self.Signals:Fire("Connection", self.URL)
            self.Client.OnMessage:Connect(function(Payload)
                self:OnMessage(Payload)
            end)
            self.Client.OnClose:Connect(function()
                self:OnDisconnect()
            end)
        end

        -- // Send a message
        function WebsocketClass.Send(self, Message)
            -- // Convert message if it is a table/other to a string
            if (typeof(Message) == "table") then
                Message = HttpService:JSONEncode(Message)
            else
                Message = tostring(Message)
            end

            -- // Send it
            self.Client:Send(Message)
        end
    end

    -- // Connect to the websocket
    Websocket = WebsocketClass.new(WSURLFormat:format(Host, Port))
    Websocket:Connect()

    -- // See whenever we get a message (from another client)
    Websocket.Signals:Connect("Message", function(Payload)
        -- // Assume the payload is JSON encoded, decode
        local DecodedPayload = HttpService:JSONDecode(Payload)
        local ExecutePlayer = Players:FindFirstChild(DecodedPayload.ExecutePlayer)

        -- // Make sure player exists
        if (not ExecutePlayer) then
            return
        end

        -- // Finding the command
        local Command

        -- // Loop through each command
        for _, _Command in ipairs(Handler.Commands) do
            -- // Find the command
            if (table.find(_Command.Name, Payload.Command) and _Command.Active) then
                -- // Set
                Command = _Command

                -- // Break
                break
            end
        end

        -- // Make sure command exists
        if not (Command) then
            return
        end

        -- // Execute the command
        Command.Callback(ExecutePlayer, DecodedPayload.Arguments)
    end)
end

----------- // Add your commands below

-- // An example command
CommandClass.new({
    Name = {"execute"},
    Description = "Execute code on each alt",
    Handler = Handler,
    Callback = function(ExecutePlayer, Arguments)
        -- // If we are the host, send the command out
        if (ExecutePlayer == LocalPlayer) then
            return Websocket:Send({
                ExecutePlayer = ExecutePlayer,
                Command = "execute",
                Arguments = Arguments,

                -- // not needed but why not
                CommandHandlerConfig = CommandHandlerConfig
            })
        end

        -- // Make sure the person who said the command is the owner
        if (ExecutePlayer ~= OwnerUserId) then
            return
        end

        -- // Execute the text
        local Text = table.concat(Arguments, " ")
        loadstring(Text)()
    end
})