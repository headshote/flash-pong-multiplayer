package {
	import flash.display.MovieClip
	import playerio.*
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	
	public class MP_Pong extends MovieClip
	{
		var connection:Connection;
		
		function MP_Pong()
		{
			stop();
			PlayerIO.connect(
				stage,								//Referance to stage
				"multiplayer-pong-jed5uk4mnkx6pgpynxeva",			//Game id (Get your own at playerio.com)
				"public",							//Connection id, default is public
				"GuestUser",						//Username
				"",									//User auth. Can be left blank if authentication is disabled on connection
				null,								//Current PartnerPay partner.
				handleConnect,						//Function executed on successful connect
				handleError							//Function executed if we recive an error
			);   			
		}
		
		private function handleConnect(client:Client):void
		{
			trace("Sucessfully connected to player.io");
			
			//Set developmentsever (Comment out to connect to your server online)
			client.multiplayer.developmentServer = "localhost:8184";
			
			//Create pr join the room test
			client.multiplayer.createJoinRoom(
				"test",								//Room id. If set to null a random roomid is used
				"MPPongCode",						//The game type started on the server
				true,								//Should the room be visible in the lobby?
				{},									//Room data. This data is returned to lobby list. Variabels can be modifed on the server
				{},									//User join data
				handleJoin,							//Function executed on successful joining of the room
				handleError							//Function executed if we got a join error
			);
		}
		
		
		private function handleJoin(conn:Connection):void
		{
			trace("Sucessfully connected to the multiplayer server");
			gotoAndStop(2);
			
			connection = conn;
			//Add disconnect listener
			connection.addDisconnectHandler(handleDisconnect);
					
			//Add listener for messages of the type "hello"
			connection.addMessageHandler("hello", function(m:Message){
				trace("Recived a message with the type hello from the server");			 
			})
			
			//In case server tells us that we should go away
			connection.addMessageHandler("disconnect", function(m:Message){
				gotoAndStop(3); 
				trace("Disconnected from server.");			 
			})			
			
			//Add message listener for users joining the room
			connection.addMessageHandler("UserJoined", function(m:Message, userid:uint){
				trace("Player with the userid", userid, "just joined the room");
			})
			
			//Add message listener for users leaving the room
			connection.addMessageHandler("UserLeft", function(m:Message, userid:uint){
				trace("Player with the userid", userid, "just left the room");
			})
			
			//Listen to all messages using a private function
			connection.addMessageHandler("*", handleMessages)
			
			//Add event listeners
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
			stage.addEventListener(Event.ENTER_FRAME, everyFrame);		
		}
		
		private function handleMessages(message:Message)
		{
			switch(message.type)
			{
				case "":
					//do something
					break;
				case "a":
					//do something
					break;
			}
			trace("Recived the message", message)
		}
		
		public function keyPressed(event:Event):void
		{
		
		}
		
		public function keyReleased(event:Event):void
		{
			
		}
		
		public function everyFrame(event:Event):void
		{
			
		}
		
		private function handleDisconnect():void
		{
			trace("Disconnected from server")
		}
		
		private function handleError(error:PlayerIOError):void
		{
			trace("got",error)
			gotoAndStop(3);

		}
	}	
}
