package {
	import playerio.*
	import flash.display.*;
	import flash.events.*;
 	import flash.ui.*;
	import flash.geom.ColorTransform;
	
	public class MP_Pong extends MovieClip
	{
		var connection:Connection;
		//Player info
		var players:Array;
		var myBoard:Player;
		var myId:int;	
		//Ball
		var ball:Ball;
		//Time at the last frame
		var oldTime:Number = (new Date()).getTime()
		//Time at the last state update
		var oldStateTime:Number = 0
		
		function MP_Pong()
		{
			stop();
			PlayerIO.connect(
				stage,								//Referance to stage
				"multiplayer-pong-jed5uk4mnkx6pgpynxeva",			//Game id (Get your own at playerio.com)
				"public",							//Connection id, default is public
				"GuestUser" + Math.floor(Math.random()*1000).toString(),	//Username
				"",									//User auth. Can be left blank if authentication is disabled on connection
				null,								//Current PartnerPay partner.
				handleConnect,						//Function executed on successful connect
				handleError							//Function executed if we recive an error
			);   
			players = new Array();
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
			
			//In case server tells us that we should go away
			connection.addMessageHandler("disconnect", function(m:Message){
				gotoAndStop(3); 
				trace("Disconnected from server.");			 
			})									
			
			//Add message listener for users leaving the room
			connection.addMessageHandler("UserLeft", userLeft)
			
			//Listen to all messages using a private function
			connection.addMessageHandler("*", handleMessages)
			
			//Add event listeners
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
			stage.addEventListener(Event.ENTER_FRAME, everyFrame);		
		}
		
		private function userLeft( message:Message)
		{
			removeChild(players[message.getInt(0)])
			delete players[message.getInt(0)];
		}
		
		private function handleMessages(message:Message)
		{
			//The time now
			var messageTime:Number = (new Date()).getTime();
			//The time since the last state update
			var timeDiff:Number = messageTime - oldStateTime;
			switch(message.type)
			{
				case "UserJoined":
					players[message.getInt(0)] = new Player();					
					players[message.getInt(0)].x = message.getNumber(2);
					players[message.getInt(0)].y = message.getNumber(3);
					players[message.getInt(0)].rightPressed = false;
					players[message.getInt(0)].leftPressed = false;
					if(  message.getString(1) == 'First' )
					{							
							var colorT:ColorTransform = new ColorTransform();						
							colorT.blueOffset = 0;
							colorT.redOffset = 0;
							colorT.greenOffset = 0;
							players[message.getInt(0)].transform.colorTransform = colorT;
					}
					else if(  message.getString(1) == "Second" )
					{
							var colorT:ColorTransform = new ColorTransform();
							colorT.blueOffset = 100;
							colorT.redOffset = -100;
							colorT.greenOffset = 150;							
							players[message.getInt(0)].transform.colorTransform = colorT;
					}
					addChildAt(players[message.getInt(0)],0)					
					break;
				case "info": //Message with info about the current scene, is sent ot user once when he connects to server
					//Get your ID
					myId = message.getInt(0)
					myBoard = players[myId];
					//Load every existing player's data
					var i:int;
					
					for( i = 0;i<(message.length - 1 - 4)/6;i++)
					{
						players[message.getInt(i*6 + 1)] = new Player();
						players[message.getInt(i*6 + 1)].x = message.getNumber(i*6 + 2);
						players[message.getInt(i*6 + 1)].y = message.getNumber(i*6 + 3);
						players[message.getInt(i*6 + 1)].rightPressed = message.getBoolean(i*6 + 4);
						players[message.getInt(i*6 + 1)].leftPressed = message.getBoolean(i*6 + 5);
						if(  message.getString(i*6 + 6) == 'First' )
						{							
								var colorT:ColorTransform = new ColorTransform();						
								colorT.blueOffset = 0;
								colorT.redOffset = 0;
								colorT.greenOffset = 0;
								players[message.getInt(i*6 + 1)].transform.colorTransform = colorT;
						}
						else if(  message.getString(i*6 + 6) == "Second" )
						{
								var colorT:ColorTransform = new ColorTransform();
								colorT.blueOffset = 100;
								colorT.redOffset = -100;
								colorT.greenOffset = 150;							
								players[message.getInt(i*6 + 1)].transform.colorTransform = colorT;
						}
						addChildAt(players[message.getInt(i*6 + 1)],0)
					}
					//Load ball
					i = i*6+1;
					ball = new Ball();
					ball.x = message.getNumber(i);
					ball.y = message.getNumber(i+1);
					ball.xVelocity = message.getNumber(i+2);
					ball.yVelocity = message.getNumber(i+3);
					addChildAt(ball, 0)
					break;
				case "state":
					var i:int;
					if(oldStateTime == 0)
					{
						oldStateTime = (new Date()).getTime()
						return;
					}
					//This is a very rudementry timestamp correction method
					//It is prone to error sometimes but is better then no correction.
					//Without correction, this line would be just "players[message.getInt(i*3 + 1)].x = message.getNumber(i*3 + 2)"
					for( i = 0;i<(message.length - 3)/2;i++){
						players[message.getInt(i*2 + 1)].x = message.getNumber(i*2 + 2); + 
														(players[message.getInt(i*2 + 1)].rightPressed ? (timeDiff - message.getInt(0))/5 : 0) -
														(players[message.getInt(i*2 + 1)].leftPressed ? (timeDiff - message.getInt(0))/5 : 0);
						
					}
					i = i*2 +1;
					ball.x = message.getNumber(i);
					ball.y = message.getNumber(i+1);
					//expected message time and actual message time to get the old time
					//This average is useful for adapting to systematic variations to latency
					oldStateTime =  oldStateTime + message.getInt(0) + (new Date()).getTime() 
					break;
				case "leftUp":
					players[message.getInt(0)].leftPressed = false;
					break;					
				case "leftDown":
					players[message.getInt(0)].leftPressed = true;
					break;
				case "rightUp":
					players[message.getInt(0)].rightPressed = false;
					break;
				case "rightDown":
					players[message.getInt(0)].rightPressed = true;
					break;
			}
			trace("Recived the message", message)
		}
		
		public function keyPressed(key:KeyboardEvent):void
		{			
			if (key.keyCode == 68||key.keyCode == 39 && !myBoard.rightPressed) 
			{
				connection.send("rightDown");
				myBoard.rightPressed = true;
			}
			if (key.keyCode == 65||key.keyCode == 37 && !myBoard.leftPressed) 
			{
				connection.send("leftDown");
				myBoard.leftPressed = true;
			}
		}
		
		public function keyReleased(key:KeyboardEvent):void
		{			
			if (key.keyCode == 68||key.keyCode == 39 && myBoard.rightPressed) 
			{
				connection.send("rightUp");
				myBoard.rightPressed = false;
			}
			if (key.keyCode == 65||key.keyCode == 37 && myBoard.leftPressed) 
			{
				connection.send("leftUp");
				myBoard.leftPressed = false;
			}
		}
		
		//Main game logic clientside
		public function everyFrame(event:Event):void
		{
			//compute the time since last update
			var nowTime:Number = (new Date()).getTime();
			var timeDiff:Number = nowTime - oldTime;
			oldTime = nowTime;
			
			if( ball.hitTestObject( myBoard ) )
			{
				trace("That's a hit!");
				connection.send("hitBall");
				//yDirection *= -1;
				//hit.play();
				//placing ball on top of player's paddle to avoid derping
				//ball_mc.y = paddle_mc.y - ball_mc.height - paddle_mc.height /2; 
				//checkHitLocation(paddle_mc);
			}
			
			for ( var player:String in players )
			{				
				if(players[player].rightPressed)
				{
					if( players[player].x >= stage.width - players[player].width )
						players[player].x = stage.width - players[player].width;
					else
						players[player].x += timeDiff/5
				}
				if(players[player].leftPressed)
				{
					if( players[player].x <= 0 )
						players[player].x = 0;
					else
						players[player].x -= timeDiff/5
				}
			}
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
